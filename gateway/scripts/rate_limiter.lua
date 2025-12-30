
local key, intervalPermit, refillTime, burstToken = KEY[1], tonumber(ARGV[1]), tonumber(ARGV[2]), tonumber(ARGV[3])

local limit, interval = tonumber(ARGV[4]), tonumber(ARGV[5])

local bucket = redis.call('hgetall', key)

local currentTokens

if table.maxn(bucket) == 0 then
	currentTokens = burstToken
	redis.call('hset', key, 'lastRefillTime', refillTime)

elseif table.maxn(bucket) == 4 then
	
	local lastRefillTime, tokenRemaining = tonumber(bucket[2]), tonumber(bucket[4])

	if refillTime > lastRefillTime then 
		local intervalSinceLastFilled = refillTime - lastRefillTime

		if intervalSinceLastFilled > interval then
			currentTokens = burstToken
			redis.call('hset', key, 'lastRefillTime', refillTime)

		else 
			local tokenAvailable = math.floor( intervalSinceLastFilled / intervalPermit)
			if tokenAvailable > 0 then
				local shift = math.fmod( intervalSinceLastFilled, intervalPermit )
				redis.call('hset', key, 'lastRefillTime', refillTime - shift)
			end

			currentTokens = math.min( tokenAvailable + tokenRemaining, limit)
		end
	else

		currentTokens = tokenRemaining
	end
end

assert( currentTokens >=0 )

if currentTokens > 0 then
	redis.call( 'hset', key, 'tokensRemaining', currentTokens - 1 )
	return 1
else 
	redis.call( 'hset', key, 'tokensRemaining', currentTokens )
	return 0

end 

