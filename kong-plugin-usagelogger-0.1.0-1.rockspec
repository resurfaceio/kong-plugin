package = "kong-plugin-usagelogger"
version = "0.1.0-1"
source = {
   url = "git+ssh://git@github.com/resurfaceio/kong-plugin.git",
   branch = "logger-lua"
}
description = {
   summary= "Capture API requests and responses to your own data lake",
   detailed = [[
      The Resurface.io usagelogger plugin for Kong provides a way to capture entire HTTP transactions.
      It can capture both detailed requests and responses, in order to submit them to a local 
      instance of Resurface, your very own API call data lake.
      
      Resurface can help with failure triage and root cause, threat and risk identification,
      and simply just knowing how your APIs are being used. It identifies what's important
      in your API data, and can send warnings and alerts in real-time for fast action.
   ]],
   homepage = "https://github.com/resurfaceio/kong-plugin",
   license = "Apache-2.0"
}
dependencies = {
   "kong",
   "resurfaceio-logger"
}
build = {
   type = "builtin",
   modules = {
      ["usagelogger.handler"] = "usagelogger/handler.lua",
      ["usagelogger.schema"] = "usagelogger/schema.lua"
   }
}
