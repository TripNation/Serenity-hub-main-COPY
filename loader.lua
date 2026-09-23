-- SERENITY HUB // CANONICAL PUBLIC LOADER
-- Keep this root file tiny and stable. It always pulls the newest router
-- with cache-busting so existing public loadstrings never need to change.

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local isStealASeed=game.PlaceId==122216176958450 or game.GameId==10764328008
local isLiftACube=game.PlaceId==109530157755211 or game.GameId==10759860151
local isStealAnAnimeEgg=game.PlaceId==76377501906469 or game.GameId==10747748563
local isRideAPet=game.PlaceId==124216119978534 or game.GameId==10035204815
local isStrengthGrowArm=game.PlaceId==86259628805375 or game.GameId==10310999762
local isAnimeDice=game.PlaceId==113290951185459 or game.GameId==10708913337

if isStealASeed or isLiftACube or isStealAnAnimeEgg or isRideAPet or isStrengthGrowArm or isAnimeDice then
    local env=(type(getgenv)=="function" and getgenv()) or _G
    env.__SERENITY_PAYLOAD_AUTHORIZED=true
    _G.__SERENITY_PAYLOAD_AUTHORIZED=true
end

local target
local chunkName

if isStealASeed then
    target="dist/runtime/games/stealaseed.lua"
    chunkName="@SerenityHub/Game-StealASeed"
elseif isLiftACube then
    target="dist/runtime/games/liftacube.lua"
    chunkName="@SerenityHub/Game-LiftACube"
elseif isStealAnAnimeEgg then
    target="dist/runtime/games/StealAnAnimeEgg.lua"
    chunkName="@SerenityHub/Game-StealAnAnimeEgg"
elseif isRideAPet then
    target="dist/runtime/games/rideapet.lua"
    chunkName="@SerenityHub/Game-RideAPet"
elseif isStrengthGrowArm then
    target="dist/runtime/games/+1strengthgrowarm.lua"
    chunkName="@SerenityHub/Game-StrengthGrowArm"
elseif isAnimeDice then
    target="dist/runtime/games/animedice.lua"
    chunkName="@SerenityHub/Game-AnimeDice"
else
    target="dist/loader.lua"
    chunkName="@SerenityHub/CurrentLoader"
end

local url=BASE..target.."?cb="..tostring(os.time())..tostring(math.random(100000,999999))

local ok,source=pcall(function()
    return game:HttpGet(url,true)
end)

if not ok or type(source)~="string" or source=="" then
    error("[SERENITY HUB] Current loader is unavailable. Try again in a moment.",0)
end

local fn,err=loadstring(source,chunkName)
source=nil

if not fn then
    error("[SERENITY HUB] Loader compile failed: "..tostring(err),0)
end

-- Copy the community invite once after successful loader execution.
-- The marker is shared by games in this executor's filesystem.
local results=table.pack(fn())
-- Shared idle protection: one connection per session, no polling or notifications.
pcall(function()
    local env=(type(getgenv)=="function" and getgenv()) or _G
    local key="__SERENITY_IDLE_CONNECTION"
    local old=env[key]
    if old then pcall(function() old:Disconnect() end) end
    env[key]=nil
    local player=game:GetService("Players").LocalPlayer
    if not player then return end
    local virtualUser=game:GetService("VirtualUser")
    env[key]=player.Idled:Connect(function()
        pcall(function()
            virtualUser:CaptureController()
            virtualUser:ClickButton2(Vector2.new(0,0))
        end)
    end)
end)

pcall(function()
    local invite="https://discord.gg/s4yCvv4Uv"
    local env=(type(getgenv)=="function" and getgenv()) or _G
    local key="__SERENITY_DISCORD_COPIED"
    if env[key] then return end
    local marker="SerenityHub/discord-invite-copied.txt"
    if type(readfile)=="function" then
        local ok,value=pcall(readfile,marker)
        if ok and value==invite then env[key]=true; return end
    end
    local copy=type(setclipboard)=="function" and setclipboard
        or type(toclipboard)=="function" and toclipboard
        or (type(syn)=="table" and type(syn.write_clipboard)=="function" and syn.write_clipboard)
    if not copy then return end
    local ok,result=pcall(copy,invite)
    if not ok or result==false then return end
    env[key]=true
    if type(writefile)=="function" and type(readfile)=="function" then
        if type(makefolder)=="function" then pcall(makefolder,"SerenityHub") end
        pcall(writefile,marker,invite)
    end
end)
return table.unpack(results,1,results.n)
