local resurface = require "resurfaceio-logger"

local kong = kong
local ngx = ngx


local UsageLogHandler = {
  VERSION = "0.1.0",
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
    if (conf.url ~= resurface_logger.url) or (conf.rules ~= resurface_logger.rules.text()) then
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
    req.headers = serialized.request.headers
    req.headers["X-FORWARDED-FOR"] = serialized.client_ip
    req.body = request_body or ""
    request_body = nil

    res.status = kong.service.response.get_status()
    res.headers = kong.service.response.get_headers()
    res.body = pcall(kong.service.response.get_raw_body) and kong.service.response.get_raw_body() or ""

    local custom_fields = {
      ["kong-service"] = serialized.service or "",
      ["kong-route"] = serialized.route or "",
      ["kong-upstream-uri"] = serialized.upstream_uri or ""
    }

    ngx.timer.at(0, sendfromtimer, req, res, serialized.started_at, ngx.now(), custom_fields)
  end
end


return UsageLogHandler
