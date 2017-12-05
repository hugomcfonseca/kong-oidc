local M = {}

local function shouldIgnoreRequest(patterns)
  if (patterns) then
    for _, pattern in ipairs(patterns) do
      local isMatching = not (string.find(ngx.var.uri, pattern) == nil)
      if (isMatching) then 
        return true 
      end
    end
  end

  return false
end

local function isAllowedDomain(domain_from_provider, expected_domain)
  domain_from_provider = domain_from_provider or ""
  expected_domain = expected_domain or ""

  if (domain_from_provider == "") then
    return false
  elseif (domain_from_provider ~= "" and expected_domain ~= "") then
    if (domain_from_provider ~= expected_domain) then
      return false 
    end
  end

  return true
end

function M.shouldProcessRequest(config, hd_from_provider)
  hd_from_provider = hd_from_provider or ""
  condition1 = true
  condition2 = true

  if config.filters ~= "" then
    condition1 = not shouldIgnoreRequest(config.filters)
  end

  if hd_from_provider ~= "" then
    condition2 = isAllowedDomain(hd_from_provider, config.hosted_domain)
  end

  return (condition1 and condition2)
end

return M
