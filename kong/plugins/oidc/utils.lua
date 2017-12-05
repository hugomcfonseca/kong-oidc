local constants   = require "kong.constants"
local singletons  = require "kong.singletons"

local M = {}

local function parseFilters(csvFilters)
  local filters = {}
  if (not (csvFilters == nil)) then
    for pattern in string.gmatch(csvFilters, "[^,]+") do
      table.insert(filters, pattern)
    end
  end
  return filters
end

local function load_consumer_into_memory(username)
  local result, err = singletons.dao.consumers:find_all({username = username})
  
  if err then 
    return nil, err
  end

  return result[1]
end

local function addConsumerHeaders(consumer)
  ngx.header[constants.HEADERS.CONSUMER_ID] = consumer.id
  ngx.header[constants.HEADERS.CONSUMER_CUSTOM_ID] = consumer.custom_id
  ngx.header[constants.HEADERS.CONSUMER_USERNAME] = consumer.username
end

function M.get_redirect_uri_path(ngx)
  local function drop_query()
    local uri = ngx.var.request_uri
    local x = uri:find("?")
    if x then
      return uri:sub(1, x - 1)
    else
      return uri
    end
  end

  local function tackle_slash(path)
    local args = ngx.req.get_uri_args()
    if args and args.code then
      return path
    elseif path == "/" then
      return "/cb"
    elseif path:sub(-1) == "/" then
      return path:sub(1, -2)
    else
      return path .. "/"
    end
  end

  return tackle_slash(drop_query())
end

function M.get_options(config, ngx)
  return {
    client_id = config.client_id,
    client_secret = config.client_secret,
    discovery = config.discovery,
    introspection_endpoint = config.introspection_endpoint,
    redirect_uri_path = M.get_redirect_uri_path(ngx),
    scope = config.scope,
    response_type = config.response_type,
    ssl_verify = config.ssl_verify,
    token_endpoint_auth_method = config.token_endpoint_auth_method,
    recovery_page_path = config.recovery_page_path,
    hosted_domain = config.hosted_domain,
    filters = parseFilters(config.filters)
  }
end

function M.exit(httpStatusCode, message, ngxCode)
  ngx.status = httpStatusCode
  ngx.say(message)
  ngx.exit(ngxCode)
end

function M.injectUser(user)
  local tmp_user = user

  local consumer_cache_key = singletons.dao.consumers:cache_key("")
  local consumer, err      = singletons.cache:get(consumer_cache_key, nil, load_consumer_into_memory, user.email, true)

  if consumer then
    addConsumerHeaders(consumer)
  end

  tmp_user.id = consumer_id
  tmp_user.username = consumer.username
  ngx.ctx.authenticated_consumer = consumer
end

function M.has_bearer_access_token()
  local header = ngx.req.get_headers()['Authorization']
  if header and header:find(" ") then
    local divider = header:find(' ')
    if string.lower(header:sub(0, divider-1)) == string.lower("Bearer") then
      return true
    end
  end
  return false
end

return M
