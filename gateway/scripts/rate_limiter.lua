local redis = require "resty.redis" 
local _M = {}

local BUCKET_LOGIC = [[
    local key, intervalPermit, refillTime, burstToken = KEYS[1], tonumber(ARGV[1]), tonumber(ARGV[2]), tonumber(ARGV[3])

    local limit, interval = tonumber(ARGV[4]), tonumber(ARGV[5])

    local bucket = redis.call('hgetall', key)

    local currentTokens

    if #bucket == 0 then

        currentTokens = burstToken
        redis.call('hset', key, 'lastRefillTime', refillTime)

    elseif #bucket == 4 then

        local lastRefillTime, tokenRemaining = tonumber(bucket[2]), tonumber(bucket[4])

        if refillTime > lastRefillTime then 

            local intervalSinceLastFilled = refillTime - lastRefillTime

            if intervalSinceLastFilled > interval then

                currentTokens = burstToken

                redis.call('hset', key, 'lastRefillTime', refillTime)

            else 

                local tokenAvailable = math.floor(intervalSinceLastFilled / intervalPermit)

                if tokenAvailable > 0 then
                    local shift = intervalSinceLastFilled % intervalPermit
                    redis.call('hset', key, 'lastRefillTime', refillTime - shift)
                end

                currentTokens = math.min(tokenAvailable + tokenRemaining, limit)
            end	

        else
            currentTokens = tokenRemaining
        end
    end

    if currentTokens and currentTokens > 0 then

        redis.call('hset', key, 'tokensRemaining', currentTokens - 1)
        return 1

    else 

        return 0

    end
]]


function _M.is_allowed(user_id)
    local red = redis:new()
   
    local ok, err = red:connect("redis", 6379)

	if not ok then 
		return true
	end 
	   
	local res, err = red:eval(BUCKET_LOGIC, 1, user_id, ngx.now(), 1, 10, 10, 10)
    
        return res == 1
    
    
end

return _M

