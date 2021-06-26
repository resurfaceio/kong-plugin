import time
from usagelogger import HttpLogger, HttpMessage, HttpRequestImpl, HttpResponseImpl
import logging
import re

logging.basicConfig(
    format="%(asctime)s %(message)s",
    level=logging.DEBUG,
    handlers=[logging.FileHandler("debug.log"), logging.StreamHandler()],
)

logger = logging.getLogger()


class safeiter(list):
    def get(self, index, default=None):
        try:
            return self.__getitem__(index)
        except IndexError:
            return default


def validate_url(url_data):
    if not url_data:
        return False
    regex = re.compile(
        r"^(?:http|ftp)s?://"  # http:// or https://
        r"(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|"
        r"localhost|"  # localhost...
        r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})"  # ...or ip
        r"(?::\d+)?"  # optional port
        r"(?:/?|[/?]\S+)$",
        re.IGNORECASE,
    )
    return re.match(regex, url_data) is not None


def build_url(request) -> str:
    build_ = "".join(
        (
            safeiter(request.get_scheme())[0] + "://",
            safeiter(request.get_host())[0],
            safeiter(request.get_path_with_query())[0],
        )
    )
    if validate_url(build_):
        return build_
    else:
        return ""


def get_headers(request):
    headers_ = safeiter(request.get_headers())[0]
    if headers_ and isinstance(headers_, dict):
        return {k: ",".join(v) for k, v in request.get_headers()[0].items()}
    return {}


def get_queries(request):
    headers_ = safeiter(request.get_query())[0]
    if headers_ and isinstance(headers_, dict):
        return {k: ",".join(v) for k, v in request.get_query()[0].items()}
    return {}


Schema = (
    {"usage_loggers_url": {"type": "string"}},
    {"usage_loggers_rules": {"type": "string"}},
)

version = "0.1.0"
priority = 5


class Plugin:
    def __init__(self, config):
        self.config = config
        self.logger = HttpLogger(
            url=config["usage_loggers_url"], rules=config["usage_loggers_rules"]
        )
        self.interval = 0.0

    def access(self, kong, **kwargs):
        self.interval = time.time()

    def response(self, kong):
        self.interval = 1000 * (time.time() - self.interval)
        logger.info(f"Method: {kong.request.get_method()}")
        logger.info(f"Raw request body: {kong.request.get_raw_body()}")
        logger.info(f"Status: {kong.service.response.get_status()}")
        logger.info(f"Raw response body: {kong.service.response.get_body()}")

        req = HttpRequestImpl(
            method=safeiter(kong.request.get_method())[0],
            url=build_url(kong.request),
            headers=get_headers(kong.request),
            params=get_queries(kong.request),
            body=safeiter(kong.request.get_raw_body())[0],
        )
        res = HttpResponseImpl(
            status=safeiter(kong.response.get_status())[0],
            body=safeiter(kong.service.response.get_raw_body())[0],
            headers=get_headers(kong.service.response),
        )
        HttpMessage.send(
            self.logger,
            request=req,
            response=res,
            interval=str(self.interval),
        )


if __name__ == "__main__":
    from kong_pdk.cli import start_dedicated_server

    start_dedicated_server("kong-logger", Plugin, version, priority)
