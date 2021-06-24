#!/usr/bin/env python3
import os
import time
import kong_pdk.pdk.kong as kong
from usagelogger import HttpLogger, HttpMessage, HttpRequestImpl, HttpResponseImpl

Schema = (
    { "usage_loggers_url": { "type": "string" } },
    { "usage_loggers_rules": { "type": "string" } },
)

version = '0.1.0'
priority = 5

# This is an example plugin that add a header to the response

class Plugin(object):
    def __init__(self, config):
        self.config = config
        self.logger = HttpLogger(url=config['usage_loggers_url'], rules=config['usage_loggers_rules'])
        self.interval = 0.0

    def access(self, kong):
        self.interval = time.time()

    def response(self, kong):
        self.interval = 1000 * (time.time() - self.interval)
        #with open("/home/kong/hey","w") as f:
        #    print(kong.service.response.get_body(),end='\n',file=f)
        req = HttpRequestImpl(
            method=kong.request.get_method()[0],
            url=''.join((kong.request.get_scheme()[0] + "://", kong.request.get_host()[0], kong.request.get_path_with_query()[0])),
            headers={k: ','.join(v) for k,v in kong.request.get_headers()[0].items()},
            params={k: ','.join(v) for k,v in kong.request.get_query()[0].items()},
            body=kong.request.get_raw_body()[0],
        )
        res = HttpResponseImpl(
            status=kong.response.get_status()[0],
            #body="",
            #body=kong.service.response.get_body()[0],
            body=kong.service.response.get_raw_body()[0],
            #headers={k: ','.join(v) for k,v in kong.response.get_headers()[0].items()},
            headers={k: ','.join(v) for k,v in kong.service.response.get_headers()[0].items()},
        )
        HttpMessage.send(
            self.logger,
            request=req,
            response=res,
            interval=str(self.interval),
        )



# add below section to allow this plugin optionally be running in a dedicated process
#if __name__ == "__main__":
#    from kong_pdk.cli import start_dedicated_server
#    start_dedicated_server("py-hello", Plugin, version, priority)
