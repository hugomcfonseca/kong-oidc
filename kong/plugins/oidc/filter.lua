local M = {}

local function should_ignore_request(patterns)
    if patterns then
        for _, pattern in ipairs(patterns) do
            local isMatching = not (string.find(ngx.var.uri, pattern) == nil)
            if (isMatching) then
                return true
            end
        end
    end

    return false
end

local function is_allowed_domain(provider_domain, allowed_domain)
    if provider_domain == "" or provider_domain == nil then
        err = "No domain was received from provider's info."
        return false, err
    elseif allowed_domain == "" or allowed_domain == nil then
        return true
    else 
        if provider_domain ~= allowed_domain then
            err = "Provider and allowed domains does not match."
            return false, err
        end
    end

    return true
end

function M.should_process_request(filters)
    return (not should_ignore_request(filters))
end

function M.should_unauthorize_request(hd, allowed_domain)
    return (not is_allowed_domain(hd, allowed_domain))
end

return M
