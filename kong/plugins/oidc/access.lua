local utils   = require "kong.plugins.kong-oidc.utils"
local filter  = require "kong.plugins.kong-oidc.filter"
local session = require "kong.plugins.kong-oidc.session"

local cjson   = require "cjson"

local _M = {}

function handle(oidcConfig)
  local response
  if oidcConfig.introspection_endpoint then
    response = introspect(oidcConfig)
    if response then
      utils.injectUser(response)
    end
  end

  if response == nil then
    response = make_oidc(oidcConfig)
    if response and response.user then
      if oidcConfig.hosted_domain ~= "" then
        if response.user.hd ~= "" then
          if not filter.shouldProcessRequest(oidcConfig, response.user.hd) then 
            utils.exit(403, err, ngx.HTTP_FORBIDDEN)
          end
        end      
      end

      utils.injectUser(response.user)
      --ngx.header("X-Userinfo"] = cjson.encode(response.user)
    end
  end
end

function make_oidc(oidcConfig)
  ngx.log(ngx.DEBUG, "OidcHandler calling authenticate, requested path: " .. ngx.var.request_uri)
  local res, err = require("resty.openidc").authenticate(oidcConfig)
  if err then
    if oidcConfig.recovery_page_path then
      ngx.log(ngx.DEBUG, "Entering recovery page: " .. oidcConfig.recovery_page_path)
      ngx.redirect(oidcConfig.recovery_page_path)
    end
    utils.exit(500, err, ngx.HTTP_INTERNAL_SERVER_ERROR)
  end
  return res
end

function introspect(oidcConfig)
  if utils.has_bearer_access_token() then
    local res, err = require("resty.openidc").introspect(oidcConfig)
    if err then
      return nil
    end
    ngx.log(ngx.DEBUG, "OidcHandler introspect succeeded, requested path: " .. ngx.var.request_uri)
    return res
  end
  return nil
end


function _M.execute(conf)
  local oidcConfig = utils.get_options(conf, ngx)

  if filter.shouldProcessRequest(oidcConfig) then
    session.configure(oidcConfig)
    handle(oidcConfig)
  else
    ngx.log(ngx.DEBUG, "OidcHandler ignoring request, path: " .. ngx.var.request_uri)
  end

  ngx.log(ngx.DEBUG, "OidcHandler done")
end

return _M
