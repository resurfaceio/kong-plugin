import re
import time
from usagelogger import HttpLogger, HttpMessage, HttpRequestImpl, HttpResponseImpl


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
            request.get_scheme()[0] + "://",
            request.get_host()[0],
            request.get_path_with_query()[0],
        )
    )
    if validate_url(build_):
        return build_
    else:
        return ""


def get_pairs(message, isheader):
    pairs_ = message.get_headers() if isheader else message.get_query()
    if pairs_ and isinstance(pairs_[0], dict):
        return {k: ",".join(v) for k, v in pairs_[0].items()}
    return {}

def get_headers(message):
    return get_pairs(message, True)

def get_queries(request):
    return get_pairs(request, False)

Schema = (
    {"usage_loggers_url": {"type": "string"}},
    {"usage_loggers_rules": {"type": "string"}},
)

version = "0.1.0"
priority = -1000


class Plugin:
    def __init__(self, config):
        self.config = config
        self.logger = HttpLogger(
            url=config["usage_loggers_url"], rules=config["usage_loggers_rules"]
        )
        self.interval = 0.0

    def access(self, kong):
        self.interval = time.time()
        kong.service.request.enable_buffering()

    def response(self, kong):
        self.interval = 1000 * (time.time() - self.interval)
        req = HttpRequestImpl(
            method=kong.request.get_method()[0],
            url=build_url(kong.request),
            headers=get_headers(kong.request),
            params=get_queries(kong.request),
            body=kong.request.get_raw_body()[0],
        )
        res = HttpResponseImpl(
            status=kong.response.get_status()[0],
            body=kong.service.response.get_raw_body()[0],
            headers=get_headers(kong.response),
        )
        HttpMessage.send(
            self.logger,
            request=req,
            response=res,
            interval=self.interval,
        )


#if __name__ == "__main__":
#    from kong_pdk.cli import start_dedicated_server
#    start_dedicated_server("kong-logger", Plugin, version, priority)
