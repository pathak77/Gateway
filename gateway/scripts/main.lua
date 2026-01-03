local limiter = require("rate_limiter")
local valid = require("verification")
local cjson = require("cjson")

local payload, err = valid.check()

if err then
	
	ngx.status = 401
	ngx.header.content_type = "application/json"
	ngx.say(cjson.encode({ status = "error", message = "AUTHENTICAITON FAILURE" ..(err or "Unknown error") }))
	return ngx.exit(401)

end

local userId = payload.sub

local allowed, limit_error = limiter.is_allowed(userId)

if not allowed then

	ngx.status = 429
	ngx.header.content_type ="application/json"
	ngx.say(cjson.encode({ status = "error", message = "TOO MANY REQUESTS" ..(limit_error or "Please try again later.")}))
	return ngx.exit(429)
	
end

ngx.log(ngx.INFO, "Request allowed for user: ", userId)
 