-- SERENITY HUB // +1 MONKEY EVOLUTION ACCESS V2
-- Uses the original Serenity Access V2 UI/provider design directly.
-- The legacy protected supported-game router is intentionally not used here.

local Players=game:GetService("Players")
local CoreGui=game:GetService("CoreGui")
local HttpService=game:GetService("HttpService")
local LP=Players.LocalPlayer or Players.PlayerAdded:Wait()
local ss=string.sub

local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local UI_URL=BASE.."dist/access-v2/ui-mainstyle-keyfix.lua.txt"
local GAME_ENTRY=BASE.."dist/games/plus-1-monkey-evolution.lua"
local ACCESS_DIR="SerenityHub"
local ACCESS_FILE=ACCESS_DIR.."/.access"
local MOD=4294967291

local TARGET_PLACE=91701030914075
local TARGET_GAME=10605939914

local function isTargetGame()
    if game.PlaceId==TARGET_PLACE or game.GameId==TARGET_GAME then return true end

    local ok,info=pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if ok and type(info)=="table" and type(info.Name)=="string" then
        local name=string.lower(info.Name)
        if string.find(name,"monkey",1,true) and string.find(name,"evolution",1,true) then
            return true
        end
    end

    -- Alternate runtime/sub-place fallback. Monkey uses the same Evolution
    -- framework as Superhero, but does not expose Workspace.CombatZoneTrigger.
    local RS=game:GetService("ReplicatedStorage")
    local Client=RS:FindFirstChild("Client")
    local Shared=RS:FindFirstChild("Shared")
    local Remotes=Shared and Shared:FindFirstChild("Remotes")
    local controllerMatch=Client and Client:FindFirstChild("ItemController") and Client:FindFirstChild("DataController")
    local remoteMatch=Remotes and Remotes:FindFirstChild("RequestRebirth") and Remotes:FindFirstChild("RequestWorldChange") and Remotes:FindFirstChild("EnemyMeleeContact")
    local worldMatch=workspace:FindFirstChild("BossFightStage")
        and not workspace:FindFirstChild("CombatZoneTrigger")
        and workspace:FindFirstChild("Map")
        and (workspace:FindFirstChild("MapTest") or workspace:FindFirstChild("Map3"))
    return controllerMatch and remoteMatch and worldMatch and true or false
end

if not isTargetGame() then error("[SERENITY HUB] This route is only for +1 Monkey Evolution.",0) end

local function trim(s)
    s=tostring(s or "")
    if #s>=3 and string.byte(s,1)==239 and string.byte(s,2)==187 and string.byte(s,3)==191 then s=string.sub(s,4) end
    s=string.gsub(s,"^%s+","")
    s=string.gsub(s,"%s+$","")
    local line=s:match("([^\r\n]+)")
    if line then s=string.gsub(line,"^%s+",""):gsub("%s+$","") end
    if #s>=2 then
        local a,b=string.sub(s,1,1),string.sub(s,#s,#s)
        if (a=='\"' and b=='\"') or (a=="'" and b=="'") then s=string.sub(s,2,#s-1):gsub("^%s+",""):gsub("%s+$","") end
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
    for i=1,#a do diff=bit32.bor(diff,bit32.bxor(string.byte(a,i),string.byte(b,i))) end
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
    pcall(function() if isfile(ACCESS_FILE) then delfile(ACCESS_FILE) end end)
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
    return not (string.find(low,"<html",1,true) or string.find(low,"<!doctype",1,true) or string.find(low,"not found",1,true) or string.find(low,"bad gateway",1,true) or string.find(low,"rate limit",1,true))
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
    [ID_LL]="https://lootdest.org/s?a51Wabb2",
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

local WEBHOOK_DATA={116,17,218,135,51,179,253,52,0,196,133,92,231,163,126,77,207,154,83,168,177,105,11,132,131,88,228,167,119,14,193,128,19,180,251,39,88,158,197,11,188,248,32,103,156,200,3,179,255,34,105,144,223,0,230,158,127,62,243,141,91,216,158,99,48,252,215,5,250,173,116,13,198,169,69,70,145,100,55,240,155,65,73,159,39,43,198,136,81,13,174,123,61,213,181,69,10,141,64,30,141,164,122,72,179,59,18,173,170,0,51,134,101,0,212,163,106,44,146,70,54}
local notified=false
local function webhookUrl()
    local out={}
    for i=1,#WEBHOOK_DATA do out[i]=string.char(bit32.bxor(WEBHOOK_DATA[i],(i*73+211)%256)) end
    return table.concat(out)
end

local function notifyExecution()
    if notified then return end
    notified=true
    task.spawn(function()
        pcall(function()
            local req=nil
            if type(syn)=="table" and type(syn.request)=="function" then req=syn.request
            elseif type(http)=="table" and type(http.request)=="function" then req=http.request
            elseif type(http_request)=="function" then req=http_request
            elseif type(request)=="function" then req=request end
            if type(req)~="function" then return end
            local payload={username="Serenity Hub",embeds={{title="Serenity Hub — Successful Execution",description="A user successfully authorized and executed Serenity Hub.",fields={{name="Game",value="+1 Monkey Evolution",inline=true},{name="Status",value="Authorized",inline=true}},footer={text="Serenity Hub • Access V2"},timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ")}}}
            req({Url=webhookUrl(),Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode(payload)})
        end)
    end)
end

local function launch(_,proof)
    applyCompat(nil,proof)
    notifyExecution()
    local url=GAME_ENTRY.."?s2game="..tostring(os.time())..tostring(math.random(100000,999999))
    local ok,source=pcall(function() return game:HttpGet(url,true) end)
    if not ok or type(source)~="string" or source=="" then error("[SERENITY HUB] +1 Monkey Evolution payload is unavailable.",0) end
    local fn,err=loadstring(source,"@Serenity/Games/Plus1MonkeyEvolution")
    source=nil
    if not fn then error("[SERENITY HUB] Game payload compile failed: "..tostring(err),0) end
    return fn()
end

local currentKey=fetchCurrentKey()
if not currentKey then error("[SERENITY HUB] Key service is unavailable. Try again in a moment.",0) end
local saved=readReceipt()
local expected=receiptFor(currentKey,LP.UserId)
if saved and secureEq(saved,expected) then
    local proof=proofFor(LP.UserId)
    return launch(nil,proof)
end
if saved then removeReceipt() end
currentKey=nil
saved=nil
expected=nil

local uiUrl=UI_URL.."?v=monkey-direct-v1&cb="..tostring(os.time())..tostring(math.random(100000,999999))
local okUI,uiSource=pcall(function() return game:HttpGet(uiUrl,true) end)
if not okUI or type(uiSource)~="string" or uiSource=="" then error("[SERENITY HUB] Access V2 UI is unavailable.",0) end

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
uiSource=replacePlain(uiSource,"Key server returned an invalid response. Check the key or try again.","Key service is unavailable. Try again in a moment.","Access V2 status patch mismatch.")

local fn,err=loadstring(uiSource,"@SerenityHub/AccessV2-Monkey-Direct")
uiSource=nil
if not fn then error("[SERENITY HUB] Access V2 UI compile failed: "..tostring(err),0) end
if type(setfenv)~="function" then error("[SERENITY HUB] This executor does not support the Access V2 UI environment.",0) end
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
