-- SERENITY HUB // GUARDED PAYLOAD RUNNER
-- Public game entrypoints use this before executing their protected payload.
--
-- V2.1 adds a one-time closure ticket passed into the payload chunk.
-- New payloads may require that ticket so executing the raw runtime file
-- directly routes back through the canonical loader/access system.
-- Existing payloads remain compatible because unused varargs are ignored.

local Players=game:GetService("Players")
local LP=Players.LocalPlayer or Players.PlayerAdded:Wait()

local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local ACCESS_FILE="SerenityHub/.access"
local MOD=4294967291
local KEY_URLS={
    "https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/access_key.txt",
    "https://raw.githubusercontent.com/MUshihara/Serenity-hub/refs/heads/main/access_key.txt",
    "https://github.com/MUshihara/Serenity-hub/raw/refs/heads/main/access_key.txt",
}

local function trim(s)
    s=tostring(s or "")
    if #s>=3 and string.byte(s,1)==239 and string.byte(s,2)==187 and string.byte(s,3)==191 then
        s=string.sub(s,4)
    end
    s=s:gsub("^%s+",""):gsub("%s+$","")
    local line=s:match("([^\r\n]+)")
    if line then s=line:gsub("^%s+",""):gsub("%s+$","") end
    if #s>=2 then
        local a,b=s:sub(1,1),s:sub(-1)
        if (a=='\"' and b=='\"') or (a=="'" and b=="'") then
            s=s:sub(2,-2):gsub("^%s+",""):gsub("%s+$","")
        end
    end
    return s
end

local function hash(s)
    local q=5381
    for i=1,#s do
        q=(q*33+string.byte(s,i)+17)%MOD
    end
    return q
end

local function receiptFor(rawKey,userId)
    rawKey=trim(rawKey)
    local uid=tostring(userId or 0)
    local a=hash("SERENITY|ACCESS|V2|"..uid.."|"..rawKey)
    local b=hash(rawKey.."|"..uid.."|"..tostring(a).."|RECEIPT")
    return string.format("%08x%08x",a,b)
end

local function validRemoteKey(s)
    if type(s)~="string" then return false end
    s=trim(s)
    if s=="" or #s>256 then return false end
    local low=s:lower()
    return not (
        low:find("<html",1,true)
        or low:find("<!doctype",1,true)
        or low:find("not found",1,true)
        or low:find("bad gateway",1,true)
        or low:find("rate limit",1,true)
    )
end

local function fetchCurrentKey()
    local nonce=tostring(os.time())..tostring(math.random(100000,999999))
    for _,url in ipairs(KEY_URLS) do
        local sep=url:find("?",1,true) and "&" or "?"
        local fresh=url..sep.."s2guard="..nonce
        local attempts={
            function() return game:HttpGet(fresh,false) end,
            function() return game:HttpGet(fresh,true) end,
            function() return game:HttpGet(url,false) end,
            function() return game:HttpGet(url,true) end,
            function() return game:HttpGet(url) end,
        }
        for _,call in ipairs(attempts) do
            local ok,body=pcall(call)
            if ok then
                body=trim(body)
                if validRemoteKey(body) then return body end
            end
        end
    end
    return nil
end

local function receiptAuthorized()
    if type(isfile)~="function" or type(readfile)~="function" then return false end
    local ok,exists=pcall(isfile,ACCESS_FILE)
    if not ok or not exists then return false end
    local rok,saved=pcall(readfile,ACCESS_FILE)
    if not rok then return false end
    saved=trim(saved)
    local currentKey=fetchCurrentKey()
    if not currentKey then return false end
    local expected=receiptFor(currentKey,LP.UserId)
    currentKey=nil
    return saved==expected
end

local function trustedAccessCaller()
    if type(debug)~="table" or type(debug.info)~="function" then return false end
    for level=2,9 do
        local ok,source=pcall(debug.info,level,"s")
        if ok and type(source)=="string" then
            local low=source:lower()
            if low:find("serenityshield",1,true)
                or low:find("serenityhub/accessv2",1,true)
                or low:find("accessv2-superhero",1,true)
                or low:find("accessv2-greedygrowers",1,true) then
                return true
            end
        end
    end
    return false
end

local function sessionAuthorized()
    local env=(type(getgenv)=="function" and getgenv()) or _G
    if env.__SERENITY_PAYLOAD_AUTHORIZED==true then
        env.__SERENITY_PAYLOAD_AUTHORIZED=nil
        return true
    end
    -- Access V2 sets this compatibility proof only after successful authorization.
    if type(env.__SERENITY_ACCESS_V2)=="string" and env.__SERENITY_ACCESS_V2~="" then
        return true
    end
    return trustedAccessCaller()
end

local function runMainLoader()
    local url=BASE.."loader.lua?from=payload-guard&cb="..tostring(os.time())..tostring(math.random(100000,999999))
    local ok,source=pcall(function() return game:HttpGet(url,true) end)
    if not ok or type(source)~="string" or source=="" then
        error("[SERENITY HUB] Main loader is unavailable.",0)
    end
    local fn,err=loadstring(source,"@SerenityHub/MainLoader")
    source=nil
    if not fn then
        error("[SERENITY HUB] Main loader compile failed: "..tostring(err),0)
    end
    return fn()
end

local function oneTimeLaunchTicket(payloadPath)
    local secret={}
    local consumed=false

    local function verify(candidate,candidatePath)
        if consumed then return false end
        if candidate~=secret then return false end
        if tostring(candidatePath)~=tostring(payloadPath) then return false end
        consumed=true
        return true
    end

    return secret,verify
end

return function(payloadPath)
    if type(payloadPath)~="string" or payloadPath=="" then
        error("[SERENITY HUB] Invalid payload route.",0)
    end

    local authorized=sessionAuthorized()
    if not authorized then
        authorized=receiptAuthorized()
    end
    if not authorized then
        return runMainLoader()
    end

    local url=BASE..payloadPath.."?s2payload="..tostring(os.time())..tostring(math.random(100000,999999))
    local ok,source=pcall(function() return game:HttpGet(url,true) end)
    if not ok or type(source)~="string" or source=="" then
        error("[SERENITY HUB] Authorized game payload is unavailable.",0)
    end
    local fn,err=loadstring(source,"@SerenityHub/AuthorizedPayload")
    source=nil
    if not fn then
        error("[SERENITY HUB] Authorized payload compile failed: "..tostring(err),0)
    end

    -- The secret never enters getgenv/_G. It exists only in this closure and
    -- is consumed on the first successful verification by a guarded payload.
    -- The protected route is passed too, so new payloads can bind the ticket
    -- to the exact runtime file they were authorized to execute.
    local ticket,verify=oneTimeLaunchTicket(payloadPath)
    local okRun,result=pcall(fn,ticket,verify,payloadPath)
    ticket=nil
    verify=nil

    if not okRun then
        error("[SERENITY HUB] Authorized payload failed: "..tostring(result),0)
    end

    return result
end