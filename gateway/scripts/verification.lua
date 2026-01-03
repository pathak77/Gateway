local _M ={}

local jwt = require("resty.jwt")
local cjson = require("cjson")

local key = os.getenv("JWT_SECRET")

function _M.check()
	
	local auth_header = ngx.var.http_Authorization
	if not auth_header then
		ngx.
		return nil, "Missing Auth Header"
	end

	local token = auth_header:match("Bearer%s+(.+)")

	if not token then
		return nil, "Invalid Authorization Token format"
	end

	local jwt_obj = jwt:verify(key, token)

	if not jwt_obj.verified then 
		return nil, jwt_obj.reason
	end

	return jwt_obj.payload, nil
end 

return _M