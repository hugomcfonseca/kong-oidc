local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.kong-oidc.access"

local OidcHandler = BasePlugin:extend()

function OidcHandler:new()
    OidcHandler.super.new(self, "oidc")
end

function OidcHandler:access(conf)
    OidcHandler.super.access(self)
    access.execute(conf)
end

OidcHandler.PRIORITY = 1000
OidcHandler.VERSION = "0.1.0"

return OidcHandler
