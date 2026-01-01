local jwt = require("resty.jwt")  -- Corrected to the proper module for OpenResty JWT
local json = require("cjson")     -- Ensure that cjson is required for JSON encoding/decoding

local key = " --- the key --- "   -- Define your secret key here

local jwtToken = "fetch token"    -- Your JWT token goes here

-- Decode the JWT token
local decoded, err = jwt:decode(jwtToken, key, { algorithms = { "HS256" } })

-- Check if the token is decoded successfully
if decoded then
    validate(decoded)  -- Pass the decoded payload to the validate function
    print("Validating the payload: " .. json.encode(decoded))
else
    print("Token validation error: " .. (err or "Unknown error"))
end

-- Function to validate the JWT payload
function validate(decodedPayload)
    local user_id = decodedPayload.sub  -- Extract the user ID (subject)
    local expiration_time = decodedPayload.exp  -- Extract the expiration time
    local current_time = os.time()  -- Get the current timestamp

    print("Subject (User ID): " .. user_id)

    -- Check if the token is expired
    if expiration_time and expiration_time < current_time then
        print("Error: Token has expired.")
    else
        print("Token is valid.")
    end
end

