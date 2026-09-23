--[[
    SERENITY HUB // ACCESS V2 DYNAMIC REMOTE-KEY GATE

    Canonical behavior:
      * The shared remote raw key is the only current-key authority.
      * SerenityHub/.access stores only a derived receipt, never the raw key.
      * Every loader launch re-fetches the CURRENT remote key.
      * Changing the remote key invalidates old receipts and reopens the key UI.
      * Legacy .access-v2.dat and old in-memory shortcuts cannot authorize.
      * No fixed plaintext/transformed fallback key is embedded in this gate.
      * Successful authorized executions emit a best-effort, non-blocking game-only webhook event.
]]

local Players=game:GetService("Players")
local LP=Players.LocalPlayer or Players.PlayerAdded:Wait()

local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local PROTECTED=BASE.."dist/access-v2/core-protected.lua"
local UIPATCH=BASE.."dist/access-v2/ui-mainstyle-keyfix.lua.txt"
local ACCESS_DIR="SerenityHub"
local ACCESS_FILE=ACCESS_DIR.."/.access"
local MOD=4294967291

local function trim(s)
    s=tostring(s or "")
    if #s>=3 and string.byte(s,1)==239 and string.byte(s,2)==187 and string.byte(s,3)==191 then
        s=string.sub(s,4)
    end
    s=string.gsub(s,"^%s+","")
    s=string.gsub(s,"%s+$","")
    local line=s:match("([^\r\n]+)")
    if line then s=string.gsub(line,"^%s+",""):gsub("%s+$","") end
    if #s>=2 then
        local a=string.sub(s,1,1)
        local b=string.sub(s,#s,#s)
        if (a=='\"' and b=='\"') or (a=="'" and b=="'") then
            s=string.sub(s,2,#s-1)
            s=string.gsub(s,"^%s+",""):gsub("%s+$","")
        end
    end
    return s
end

local function accessHash(s)
    local q=5381
    for i=1,#s do
        q=(q*33+string.byte(s,i)+17)%MOD
    end
    return q
end

local function receiptFor(rawKey,userId)
    rawKey=trim(rawKey)
    local uid=tostring(userId or 0)
    local a=accessHash("SERENITY|ACCESS|V2|"..uid.."|"..rawKey)
    local b=accessHash(rawKey.."|"..uid.."|"..tostring(a).."|RECEIPT")
    return string.format("%08x%08x",a,b)
end

local function validRemoteKey(s)
    if type(s)~="string" then return false end
    s=trim(s)
    if s=="" or #s>256 then return false end
    local low=string.lower(s)
    if string.find(low,"<html",1,true)
        or string.find(low,"<!doctype",1,true)
        or string.find(low,"not found",1,true)
        or string.find(low,"bad gateway",1,true)
        or string.find(low,"rate limit",1,true) then
        return false
    end
    return true
end

-- These decode only at runtime. All three point at the same GitHub-controlled
-- access_key.txt through different raw URL forms so the key authority remains
-- one file while avoiding a single URL-form failure.
local KEY_DATA={
    {206,104,130,88,213,166,169,255,164,189,113,38,17,181,98,136,51,62,3,187,227,110,133,255,56,104,67,198,130,242,181,175,75,115,187,253,213,52,47,120,119,238,39,231,37,121,36,133,104,117,2,113,107,52,147,178,57,177,199,65,152,179,247,227,69,249,133,219,121,119,99,169,248,168,254,252},
    {206,104,130,88,213,166,169,255,164,189,113,38,17,181,98,136,51,62,3,187,227,110,133,255,56,104,67,198,130,242,181,175,75,115,187,253,213,52,47,120,119,238,39,231,37,121,36,133,104,117,2,113,107,52,147,178,57,174,195,78,133,179,254,229,71,248,133,135,75,125,111,190,249,189,229,235,19,175,229,191,45,57,15,230,114,228,146},
    {206,104,130,88,213,166,169,255,177,181,114,96,3,190,56,131,41,49,89,133,211,111,142,249,62,125,84,201,217,143,179,178,67,50,159,220,223,113,46,101,116,179,52,169,1,51,36,133,96,111,89,96,35,61,130,163,57,177,199,65,152,179,247,227,69,249,133,219,121,119,99,169,248,168,254,252}
}
local function decodeKeyUrl(row)
    local out={}
    local q=137
    for i=1,#row do
        q=(q*73+41)%256
        out[i]=string.char(bit32.bxor(row[i],q,((i*19+137)%256)))
    end
    return table.concat(out)
end

local function fetchCurrentKey()
    local nonce=tostring(os.time())..tostring(math.random(100000,999999))
    for _,row in ipairs(KEY_DATA) do
        local url=decodeKeyUrl(row)
        local sep=string.find(url,"?",1,true) and "&" or "?"
        local fresh=url..sep.."s2="..nonce
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
                if validRemoteKey(body) then
                    fresh=nil
                    url=nil
                    attempts=nil
                    return body
                end
            end
        end
        fresh=nil
        url=nil
        attempts=nil
    end
    return nil
end

local function fsReady()
    return type(isfile)=="function"
        and type(readfile)=="function"
        and type(writefile)=="function"
end

local function readReceipt()
    if not fsReady() then return nil end
    local ok,exists=pcall(isfile,ACCESS_FILE)
    if not ok or not exists then return nil end
    local rok,body=pcall(readfile,ACCESS_FILE)
    if not rok then return nil end
    return trim(body)
end

local function removeStaleReceipt()
    if type(delfile)~="function" then return end
    pcall(function()
        if isfile(ACCESS_FILE) then delfile(ACCESS_FILE) end
    end)
end

local function replacePlain(source,old,new,label)
    local p=string.find(source,old,1,true)
    if not p then error("[SERENITY HUB] "..tostring(label),0) end
    return string.sub(source,1,p-1)..new..string.sub(source,p+#old)
end

local currentKey=fetchCurrentKey()
local expectedReceipt=currentKey and receiptFor(currentKey,LP.UserId) or nil
local savedReceipt=readReceipt()
local preverified=expectedReceipt~=nil and savedReceipt~=nil and savedReceipt==expectedReceipt

if savedReceipt and expectedReceipt and not preverified then
    removeStaleReceipt()
end
savedReceipt=nil
expectedReceipt=nil

local outer=game:HttpGet(PROTECTED.."?v=dynamic-key-v2-20260824h",true)
local uiPatch=game:HttpGet(UIPATCH.."?v=dynamic-key-v2-20260824h",true)

if type(outer)~="string" or outer=="" then
    error("[SERENITY HUB] Access V2 protected core is unavailable.",0)
end
if type(uiPatch)~="string" or uiPatch=="" then
    error("[SERENITY HUB] Access V2 UI is unavailable.",0)
end

local oldVerify=[[        local embeddedOk=(H(entered)==((2100000000+2027360581)%4294967291))
        local valid=(remoteUsable and secureEq(entered,remote)) or embeddedOk
        remote=nil
]]
local newVerify=[[        local valid=(remoteUsable and secureEq(entered,remote))
        remote=nil
]]
uiPatch=replacePlain(uiPatch,oldVerify,newVerify,"Access V2 verifier patch mismatch.")

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
        local remote=__S2_CURRENT_KEY and trim(__S2_CURRENT_KEY) or nil
]]
uiPatch=replacePlain(uiPatch,oldFetch,newFetch,"Access V2 current-key UI patch mismatch.")

uiPatch=replacePlain(
    uiPatch,
    "Key server returned an invalid response. Check the key or try again.",
    "Key service is unavailable. Try again in a moment.",
    "Access V2 status-message patch mismatch."
)

local oldSave=[[        local saved,proof=saveReceipt(entered)
        proof=proof or proofFor(LP.UserId)
        applyCompat(entered,proof)
]]
local newSave=[[        local saved=false
        if __S2_FS_READY then
            pcall(function()
                if type(makefolder)=="function" then
                    if type(isfolder)=="function" then
                        if not isfolder("SerenityHub") then makefolder("SerenityHub") end
                    else
                        makefolder("SerenityHub")
                    end
                end
            end)
            local receipt=__S2_RECEIPT_FOR(entered,LP.UserId)
            saved=pcall(writefile,"SerenityHub/.access",receipt)
            receipt=nil
        end
        local proof=proofFor(LP.UserId)
        applyCompat(entered,proof)
        __S2_CURRENT_KEY=nil
        __S2_NOTIFY_EXECUTION()
        if game.PlaceId==97824450589417 or game.GameId==10577588270 then
            task.wait(.15)
            if gui then gui:Destroy() end
            return __S2_LAUNCH_SUPERHERO()
        end
]]
uiPatch=replacePlain(uiPatch,oldSave,newSave,"Access V2 receipt-save patch mismatch.")

local uiMarker="local function New(class,props)"
local uiPos=string.find(uiPatch,uiMarker,1,true)
if not uiPos then error("[SERENITY HUB] Access V2 UI marker mismatch.",0) end

local preamble=string.format([[
local __S2_FS_READY=%s
local __S2_PREVERIFIED=%s
local __S2_CURRENT_KEY=%s
local __S2_MOD=4294967291
local function __S2_TRIM(s)
    s=tostring(s or "")
    if #s>=3 and string.byte(s,1)==239 and string.byte(s,2)==187 and string.byte(s,3)==191 then
        s=string.sub(s,4)
    end
    s=string.gsub(s,"^%%s+","")
    s=string.gsub(s,"%%s+$","")
    return s
end
local function __S2_HASH(s)
    local q=5381
    for i=1,#s do q=(q*33+string.byte(s,i)+17)%%__S2_MOD end
    return q
end
local function __S2_RECEIPT_FOR(rawKey,userId)
    rawKey=__S2_TRIM(rawKey)
    local uid=tostring(userId or 0)
    local a=__S2_HASH("SERENITY|ACCESS|V2|"..uid.."|"..rawKey)
    local b=__S2_HASH(rawKey.."|"..uid.."|"..tostring(a).."|RECEIPT")
    return string.format("%%08x%%08x",a,b)
end

local __S2_WEBHOOK_DATA={116,17,218,135,51,179,253,52,0,196,133,92,231,163,126,77,207,154,83,168,177,105,11,132,131,88,228,167,119,14,193,128,19,180,251,39,88,158,197,11,188,248,32,103,156,200,3,179,255,34,105,144,223,0,230,158,127,62,243,141,91,216,158,99,48,252,215,5,250,173,116,13,198,169,69,70,145,100,55,240,155,65,73,159,39,43,198,136,81,13,174,123,61,213,181,69,10,141,64,30,141,164,122,72,179,59,18,173,170,0,51,134,101,0,212,163,106,44,146,70,54}
local __S2_NOTIFIED=false
local function __S2_WEBHOOK_URL()
    local out={}
    for i=1,#__S2_WEBHOOK_DATA do
        local k=(i*73+211)%%256
        out[i]=string.char(bit32.bxor(__S2_WEBHOOK_DATA[i],k))
    end
    return table.concat(out)
end
local function __S2_NOTIFY_EXECUTION()
    if __S2_NOTIFIED then return end
    __S2_NOTIFIED=true
    task.spawn(function()
        pcall(function()
            local req=nil
            if type(syn)=="table" and type(syn.request)=="function" then
                req=syn.request
            elseif type(http)=="table" and type(http.request)=="function" then
                req=http.request
            elseif type(http_request)=="function" then
                req=http_request
            elseif type(request)=="function" then
                req=request
            end
            if type(req)~="function" then return end

            local gameName="Unknown Game"
            local known={
                [10539411000]="Collect All the Leaves",
                [10551595617]="Jump To Steal Soccer Players",
                [10561352230]="+1 Drain Water Per Click",
                [10577588270]="+1 Superhero Evolution"
            }
            if known[game.GameId] then
                gameName=known[game.GameId]
            else
                local MarketplaceService=game:GetService("MarketplaceService")
                local okInfo,info=pcall(function()
                    return MarketplaceService:GetProductInfo(game.PlaceId)
                end)
                if okInfo and type(info)=="table" and info.Name then
                    gameName=tostring(info.Name)
                end
            end

            local HttpService=game:GetService("HttpService")
            local payload={
                username="Serenity Hub",
                embeds={{
                    title="Serenity Hub — Successful Execution",
                    description="A user successfully authorized and executed Serenity Hub.",
                    fields={
                        {name="Game",value=gameName,inline=true},
                        {name="Status",value="Authorized",inline=true}
                    },
                    footer={text="Serenity Hub • Access V2"},
                    timestamp=os.date("!%%Y-%%m-%%dT%%H:%%M:%%SZ")
                }}
            }
            local url=__S2_WEBHOOK_URL()
            local body=HttpService:JSONEncode(payload)
            req({
                Url=url,
                Method="POST",
                Headers={["Content-Type"]="application/json"},
                Body=body
            })
            url=nil
            body=nil
            payload=nil
        end)
    end)
end

local function __S2_LAUNCH_SUPERHERO()
    local url="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/dist/games/plus-1-superhero-evolution.lua"
    local sep=string.find(url,"?",1,true) and "&" or "?"
    local fresh=url..sep.."s2game="..tostring(os.time())..tostring(math.random(100000,999999))
    local ok,source=pcall(function()
        return game:HttpGet(fresh,true)
    end)
    fresh=nil
    url=nil
    if not ok or type(source)~="string" or source=="" then
        error("[SERENITY HUB] +1 Superhero Evolution payload is unavailable.",0)
    end
    local chunk,compileError=loadstring(source,"@Serenity/Games/Plus1SuperheroEvolution")
    source=nil
    if not chunk then
        error("[SERENITY HUB] +1 Superhero Evolution payload compile failed: "..tostring(compileError),0)
    end
    local okRun,result=pcall(chunk)
    if not okRun then
        error("[SERENITY HUB] +1 Superhero Evolution payload failed: "..tostring(result),0)
    end
    return result
end

if __S2_PREVERIFIED and __S2_CURRENT_KEY then
    local proof=proofFor(LP.UserId)
    applyCompat(__S2_CURRENT_KEY,proof)
    local k=__S2_CURRENT_KEY
    __S2_CURRENT_KEY=nil
    __S2_NOTIFY_EXECUTION()
    if game.PlaceId==97824450589417 or game.GameId==10577588270 then
        return __S2_LAUNCH_SUPERHERO()
    end
    return launch(k,proof)
end
]],
    tostring(fsReady()),
    tostring(preverified),
    currentKey and string.format("%q",currentKey) or "nil"
)

uiPatch=string.sub(uiPatch,1,uiPos-1)..preamble..string.sub(uiPatch,uiPos)

local legacySavedShortcut=[[local savedKey,savedProof=readReceipt() if savedKey and savedProof then applyCompat(savedKey,savedProof) return launch(savedKey,savedProof) end]]
local legacyEnvShortcut=[[if type(ENV.__SERENITY_ACCESS_V2)=="string" and ENV.__SERENITY_ACCESS_V2==proofFor(LP.UserId) then return launch(nil,ENV.__SERENITY_ACCESS_V2) end]]
local legacyRouteTail=[[elseif gid==10561352230 or pid==103883942725157 then return ID_DRAIN,"+1 Drain Water Per Click" end return nil,nil end]]
local currentRouteTail=[[elseif gid==10561352230 or pid==103883942725157 then return ID_DRAIN,"+1 Drain Water Per Click" elseif gid==10153098880 or pid==108307565942574 then return "https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/dist/games/Heroes_RNG.lua","Heroes RNG" elseif gid==10131390815 or pid==115681808123944 then return "https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/dist/games/Throw_a_coin.lua","Throw a Coin" elseif gid==9780429221 or pid==98894876188248 then return "https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/dist/games/Cheating_During_Testing.lua","Cheating During Testing" end return nil,nil end]]
local legacyLaunchFetch=[[local u=R(code) local ok,src=pcall(httpGet,u,true)]]
local currentLaunchFetch=[[local u=type(code)=="string" and code or R(code) local ok,src=pcall(httpGet,u,true)]]

local outerMarker='local FN,ER=L(SRC,"@SerenityShield/ACCESSV2-92C8406BEAB4-FINAL2")'
local outerPos=string.find(outer,outerMarker,1,true)
if not outerPos then error("[SERENITY HUB] Access V2 protected-core marker mismatch.",0) end

local inject=string.format([[
local function __s2_replace(old,new,label)
    local p=string.find(SRC,old,1,true)
    if not p then error("[SERENITY HUB] "..label,0) end
    SRC=string.sub(SRC,1,p-1)..new..string.sub(SRC,p+#old)
end
__s2_replace(%q,"","legacy receipt shortcut mismatch")
__s2_replace(%q,"","legacy session shortcut mismatch")
__s2_replace(%q,%q,"supported game route patch mismatch")
__s2_replace(%q,%q,"supported game URL patch mismatch")
local __s2_ui_marker=%q
local __s2_ui_pos=string.find(SRC,__s2_ui_marker,1,true)
if not __s2_ui_pos then error("[SERENITY HUB] Access UI marker mismatch.",0) end
SRC=string.sub(SRC,1,__s2_ui_pos-1)..%q
]],
    legacySavedShortcut,
    legacyEnvShortcut,
    legacyRouteTail,
    currentRouteTail,
    legacyLaunchFetch,
    currentLaunchFetch,
    uiMarker,
    uiPatch
)..outerMarker

outer=string.sub(outer,1,outerPos-1)..inject..string.sub(outer,outerPos+#outerMarker)

currentKey=nil
uiPatch=nil
KEY_DATA=nil

local fn,err=loadstring(outer,"@SerenityShield/AccessV2-DynamicKey-H")
outer=nil
if not fn then
    error("[SERENITY HUB] Access V2 dynamic-key build failed: "..tostring(err),0)
end
return fn()
