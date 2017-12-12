local utils = require "kong.plugins.kong-oidc.utils"
local filter = require "kong.plugins.kong-oidc.filter"
local session = require "kong.plugins.kong-oidc.session"

local cjson = require "cjson"

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
                    if filter.should_unauthorize_request(response.user.hd, oidcConfig.hosted_domain) then
                        ngx.log(
                            ngx.DEBUG,
                            "[handle] Drop user request due with does not have an email belonging to allowed domain."
                        )
                        err = "Access denied - user account does not belong to allowed domain."
                        utils.exit(403, err, ngx.exit(ngx.HTTP_FORBIDDEN))
                    end
                end
            end

            consumer, err = utils.search_consumer(response.user)

            if consumer == nil then
                utils.exit(500, err, ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR))
            elseif consumer == false then
                err = "Access denied - user does not have access to this endpoint."
                utils.exit(403, err, ngx.exit(ngx.HTTP_FORBIDDEN))
            else
                utils.inject_consumer_headers(consumer)
                ngx.ctx.authenticated_consumer = consumer
            end
        end
    end
end

function make_oidc(oidcConfig)
    ngx.log(ngx.DEBUG, "[make_oidc] calling authenticate, requested path: " .. ngx.var.request_uri)
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
        ngx.log(ngx.DEBUG, "[introspect] introspect succeeded, requested path: " .. ngx.var.request_uri)
        return res
    end
    return nil
end


function _M.execute(conf)
    local oidcConfig = utils.get_options(conf, ngx)

    if filter.should_process_request(oidcConfig) then
        session.configure(oidcConfig)
        handle(oidcConfig)
    else
        ngx.log(ngx.DEBUG, "[execute] ignoring request, path: " .. ngx.var.request_uri)
    end

    ngx.log(ngx.DEBUG, "OidcHandler done")
end

return _M
