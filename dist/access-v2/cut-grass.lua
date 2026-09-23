-- SERENITY HUB // +1 CUT GRASS ADVENTURE ACCESS V2
-- Shared Access V2 receipt/key flow; game-specific payload route only.

local Players=game:GetService("Players")
local CoreGui=game:GetService("CoreGui")
local LP=Players.LocalPlayer or Players.PlayerAdded:Wait()
local ss=string.sub

local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local UI_URL=BASE.."dist/access-v2/ui-mainstyle-keyfix.lua.txt"
local GAME_ENTRY=BASE.."dist/games/1-Cut-Grass-Adventure.lua"
local ACCESS_DIR="SerenityHub"
local ACCESS_FILE=ACCESS_DIR.."/.access"
local MOD=4294967291

local TARGET_PLACE=90086669327265
local TARGET_GAME=10410945205

local function isTargetGame()
    if game.PlaceId==TARGET_PLACE or game.GameId==TARGET_GAME then return true end
    local ok,info=pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if ok and type(info)=="table" and type(info.Name)=="string" then
        local name=string.lower(info.Name)
        return string.find(name,"cut grass",1,true)~=nil and string.find(name,"adventure",1,true)~=nil
    end
    return false
end

if not isTargetGame() then
    error("[SERENITY HUB] This route is only for +1 Cut Grass Adventure.",0)
end

local function trim(s)
    s=tostring(s or "")
    if #s>=3 and string.byte(s,1)==239 and string.byte(s,2)==187 and string.byte(s,3)==191 then s=string.sub(s,4) end
    s=string.gsub(s,"^%s+","")
    s=string.gsub(s,"%s+$","")
    local line=s:match("([^\r\n]+)")
    if line then s=string.gsub(line,"^%s+",""):gsub("%s+$","") end
    if #s>=2 then
        local a,b=string.sub(s,1,1),string.sub(s,#s,#s)
        if (a=='\"' and b=='\"') or (a=="'" and b=="'") then
            s=string.sub(s,2,#s-1):gsub("^%s+",""):gsub("%s+$","")
        end
    end
    return s
end

local function hash(s)
    local q=5381
    for i=1,#s do q=(q*33+string.byte(s,i)+17)%MOD end
    return q
end
local H=hash

local function secureEq(a,b)
    if type(a)~="string" or type(b)~="string" or #a~=#b then return false end
    local diff=0
    for i=1,#a do
        diff=bit32.bor(diff,bit32.bxor(string.byte(a,i),string.byte(b,i)))
    end
    return diff==0
end

local function receiptFor(rawKey,userId)
    rawKey=trim(rawKey)
    local uid=tostring(userId or 0)
    local a=hash("SERENITY|ACCESS|V2|"..uid.."|"..rawKey)
    local b=hash(rawKey.."|"..uid.."|"..tostring(a).."|RECEIPT")
    return string.format("%08x%08x",a,b)
end

local function proofFor(userId)
    return string.format("S2-%08x",hash("SERENITY|ACCESS|PROOF|"..tostring(userId or 0)))
end

local function fsReady()
    return type(isfile)=="function" and type(readfile)=="function" and type(writefile)=="function"
end

local function readReceipt()
    if not fsReady() then return nil end
    local ok,exists=pcall(isfile,ACCESS_FILE)
    if not ok or not exists then return nil end
    local rok,body=pcall(readfile,ACCESS_FILE)
    return rok and trim(body) or nil
end

local function removeReceipt()
    if type(delfile)~="function" or type(isfile)~="function" then return end
    pcall(function()
        if isfile(ACCESS_FILE) then delfile(ACCESS_FILE) end
    end)
end

local function saveReceipt(rawKey)
    local proof=proofFor(LP.UserId)
    if not fsReady() then return false,proof end
    pcall(function()
        if type(makefolder)=="function" then
            if type(isfolder)=="function" then
                if not isfolder(ACCESS_DIR) then makefolder(ACCESS_DIR) end
            else
                makefolder(ACCESS_DIR)
            end
        end
    end)
    local receipt=receiptFor(rawKey,LP.UserId)
    local saved=pcall(writefile,ACCESS_FILE,receipt)
    return saved,proof
end

local function validRemoteKey(s)
    if type(s)~="string" then return false end
    s=trim(s)
    if s=="" or #s>256 then return false end
    local low=string.lower(s)
    return not (
        string.find(low,"<html",1,true)
        or string.find(low,"<!doctype",1,true)
        or string.find(low,"not found",1,true)
        or string.find(low,"bad gateway",1,true)
        or string.find(low,"rate limit",1,true)
    )
end

local KEY_URLS={
    BASE.."access_key.txt",
    "https://raw.githubusercontent.com/MUshihara/Serenity-hub/refs/heads/main/access_key.txt",
    "https://github.com/MUshihara/Serenity-hub/raw/refs/heads/main/access_key.txt"
}

local function fetchCurrentKey()
    local nonce=tostring(os.time())..tostring(math.random(100000,999999))
    for _,url in ipairs(KEY_URLS) do
        local sep=string.find(url,"?",1,true) and "&" or "?"
        local fresh=url..sep.."s2="..nonce
        local attempts={
            function() return game:HttpGet(fresh,false) end,
            function() return game:HttpGet(fresh,true) end,
            function() return game:HttpGet(url,false) end,
            function() return game:HttpGet(url,true) end,
            function() return game:HttpGet(url) end
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

local ID_KEY,ID_LV,ID_LL,ID_DC=1,2,3,4
local VALUES={
    [ID_KEY]=BASE.."access_key.txt",
    [ID_LV]="https://link-center.net/2480209/D0mYrc0M948W",
    [ID_LL]="https://loot-link.com/s?jbyyXFuO",
    [ID_DC]="https://discord.gg/ccsvkN7Pp"
}
local function R(id) return VALUES[id] end

local function copyText(text)
    text=tostring(text or "")
    local env=(type(getgenv)=="function" and getgenv()) or _G
    local candidates={env.setclipboard,env.toclipboard,_G.setclipboard,_G.toclipboard}
    for _,clip in ipairs(candidates) do
        if type(clip)=="function" and pcall(clip,text) then return true end
    end
    return false
end

local function applyCompat(_,proof)
    proof=proof or proofFor(LP.UserId)
    local env=(type(getgenv)=="function" and getgenv()) or _G
    env.__SERENITY_ACCESS_V2=proof
    env.__SERENITY_PAYLOAD_AUTHORIZED=true
    _G.__SERENITY_ACCESS_V2=proof
    _G.__SERENITY_PAYLOAD_AUTHORIZED=true
    return proof
end

local function launch(_,proof)
    applyCompat(nil,proof)
    local url=GAME_ENTRY.."?s2game="..tostring(os.time())..tostring(math.random(100000,999999))
    local ok,source=pcall(function() return game:HttpGet(url,true) end)
    if not ok or type(source)~="string" or source=="" then
        error("[SERENITY HUB] +1 Cut Grass Adventure payload is unavailable.",0)
    end
    local fn,err=loadstring(source,"@Serenity/Games/Plus1CutGrassAdventure")
    source=nil
    if not fn then error("[SERENITY HUB] Game payload compile failed: "..tostring(err),0) end
    return fn()
end

local currentKey=fetchCurrentKey()
if not currentKey then error("[SERENITY HUB] Key service is unavailable. Try again in a moment.",0) end
local saved=readReceipt()
local expected=receiptFor(currentKey,LP.UserId)
if saved and secureEq(saved,expected) then
    return launch(nil,proofFor(LP.UserId))
end
if saved then removeReceipt() end
currentKey=nil
saved=nil
expected=nil

local uiUrl=UI_URL.."?v=cut-grass-direct-v1&cb="..tostring(os.time())..tostring(math.random(100000,999999))
local okUI,uiSource=pcall(function() return game:HttpGet(uiUrl,true) end)
if not okUI or type(uiSource)~="string" or uiSource=="" then
    error("[SERENITY HUB] Access V2 UI is unavailable.",0)
end

local function replacePlain(source,old,new,label)
    local p=string.find(source,old,1,true)
    if not p then error("[SERENITY HUB] "..tostring(label),0) end
    return string.sub(source,1,p-1)..new..string.sub(source,p+#old)
end

local oldFetch=[[        local keyUrl=R(ID_KEY)
        local ok,remote=pcall(function()
            return game:HttpGet(keyUrl,false)
        end)
        if not ok then
            ok,remote=pcall(function()
                return game:HttpGet(keyUrl,true)
            end)
        end
        if not ok then
            ok,remote=pcall(function()
                return game:HttpGet(keyUrl)
            end)
        end
        keyUrl=nil
        remote=ok and trim(remote) or nil
]]
local newFetch=[[        local ok=true
        local remote=fetchCurrentKey()
]]
uiSource=replacePlain(uiSource,oldFetch,newFetch,"Access V2 current-key patch mismatch.")

local oldVerify=[[        local embeddedOk=(H(entered)==((2100000000+2027360581)%4294967291))
        local valid=(remoteUsable and secureEq(entered,remote)) or embeddedOk
        remote=nil
]]
local newVerify=[[        local valid=(remoteUsable and secureEq(entered,remote))
        remote=nil
]]
uiSource=replacePlain(uiSource,oldVerify,newVerify,"Access V2 verifier patch mismatch.")
uiSource=replacePlain(
    uiSource,
    "Key server returned an invalid response. Check the key or try again.",
    "Key service is unavailable. Try again in a moment.",
    "Access V2 status patch mismatch."
)

local fn,err=loadstring(uiSource,"@SerenityHub/AccessV2-CutGrass-Direct")
uiSource=nil
if not fn then error("[SERENITY HUB] Access V2 UI compile failed: "..tostring(err),0) end
if type(setfenv)~="function" then
    error("[SERENITY HUB] This executor does not support the Access V2 UI environment.",0)
end
local baseEnv=(type(getfenv)=="function" and getfenv()) or _G
local uiEnv=setmetatable({
    LP=LP,
    CoreGui=CoreGui,
    ss=ss,
    trim=trim,
    H=H,
    secureEq=secureEq,
    fsReady=fsReady,
    saveReceipt=saveReceipt,
    proofFor=proofFor,
    applyCompat=applyCompat,
    launch=launch,
    fetchCurrentKey=fetchCurrentKey,
    R=R,
    ID_KEY=ID_KEY,
    ID_LV=ID_LV,
    ID_LL=ID_LL,
    ID_DC=ID_DC,
    copyText=copyText
},{__index=baseEnv})
setfenv(fn,uiEnv)
return fn()
