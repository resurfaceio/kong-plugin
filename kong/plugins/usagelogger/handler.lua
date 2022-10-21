local resurface = require "resurfaceio-logger"

local kong = kong
local ngx = ngx


local UsageLogHandler = {
  VERSION = "0.1.1",
  PRIORITY = 12,
}

local request_body
local resurface_logger = resurface.HttpLogger:new{url=""}

local function sendfromtimer (_, req, res, starttime, endtime, custom_fields)
  local now = endtime * 1000

  resurface.HttpMessage.send{
      logger=resurface_logger,
      request=req,
      response=res,
      now=now,
      interval=(starttime and (now - starttime)),
      custom_fields=custom_fields
  }
end

function UsageLogHandler:access(conf)
  if resurface_logger.enabled then
    if (conf.url ~= resurface_logger.url) or (conf.rules ~= resurface_logger.rules:text()) then
      resurface_logger = resurface.HttpLogger:new{url=conf.url, rules=conf.rules}
    end
    if pcall(kong.request.get_raw_body) then
      request_body = kong.request.get_raw_body()
    end
    kong.service.request.enable_buffering()
  end

end

function UsageLogHandler:log(conf)
  if resurface_logger.enabled then
    local req = resurface.HttpRequestImpl:new{}
    local res = resurface.HttpResponseImpl:new{}

    local serialized = kong.log.serialize()

    req.method = serialized.request.method
    req.url = serialized.request.url
    local qs_index = ngx.re.find(req.url,[[\?]])
    if qs_index and qs_index > 0 then
      req.url = string.sub(req.url, 1, qs_index - 1)
    end
    req.params = serialized.request.querystring
    req.headers = serialized.request.headers
    req.headers["X-FORWARDED-FOR"] = serialized.client_ip
    req.body = request_body or ""
    request_body = nil

    res.status = kong.service.response.get_status() or serialized.response.status
    local service_headers = kong.service.response.get_headers()
    res.headers = next(service_headers) and service_headers or serialized.response.headers
    res.body = pcall(kong.service.response.get_raw_body) and kong.service.response.get_raw_body() or ""

    local custom_fields = {
      ["kong-service"] = serialized.service and serialized.service.name or "",
      ["kong-route"] = serialized.route and serialized.route.name or "",
      ["kong-upstream-uri"] = serialized.upstream_uri or ""
    }

    ngx.timer.at(0, sendfromtimer, req, res, serialized.started_at, ngx.now(), custom_fields)
  end
end


return UsageLogHandler
