local resurface = require "resurfaceio-logger"

local kong = kong
local ngx = ngx


local UsageLogHandler = {
  VERSION = "0.1.0",
  PRIORITY = 12,
}

local DEFAULT_CONF = {
    url="http://172.17.0.1:7701/message",
    rules="include debug"
}

local request_body, starttime
local resurface_logger = resurface.HttpLogger:new(DEFAULT_CONF)

local function sendfromtimer (_, req, res, starttime, endtime)
  local now = endtime * 1000

  resurface.HttpMessage.send{
      logger=resurface_logger,
      request=req,
      response=res,
      now=now,
      interval=(starttime and (now - starttime))
  }
end

function UsageLogHandler:access(conf)
  starttime = ngx.now() * 1000
  if pcall(kong.request.get_raw_body) then
    request_body = kong.request.get_raw_body()
  end
  kong.service.request.enable_buffering()
end

function UsageLogHandler:log(conf)

  local req = resurface.HttpRequestImpl:new{}
  local res = resurface.HttpResponseImpl:new{}
  
  local serTable = kong.log.serialize()

  req.method = serTable.request.method
  req.url = serTable.request.url
  req.headers = serTable.request.headers
  req.body = request_body or ""
  request_body = nil

  res.status = kong.service.response.get_status()
  res.headers = kong.service.response.get_headers()
  res.body = pcall(kong.service.response.get_raw_body) and kong.service.response.get_raw_body() or ""
  
  ngx.timer.at(0, sendfromtimer, req, res, starttime, ngx.now())
  starttime = nil
end


return UsageLogHandler
