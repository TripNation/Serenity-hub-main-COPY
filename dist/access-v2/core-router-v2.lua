-- SERENITY HUB // ACCESS V2 CORE ROUTER V2
-- Cache-proof compatibility layer for old public loaders.

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local isCutGrass=(game.PlaceId==90086669327265 or game.GameId==10410945205)
local path=isCutGrass and "dist/access-v2/cut-grass-v2.lua" or "dist/access-v2/core-legacy.lua"
local chunk=isCutGrass and "@SerenityHub/AccessV2-CutGrass-V2-Compat" or "@SerenityHub/AccessV2-Legacy"
local url=BASE..path.."?compat="..tostring(os.time())..tostring(math.random(100000,999999))
local ok,source=pcall(function()
    return game:HttpGet(url,true)
end)
url=nil
if not ok or type(source)~="string" or source=="" then
    error("[SERENITY HUB] Access V2 compatibility route is unavailable.",0)
end
local fn,err=loadstring(source,chunk)
source=nil
if not fn then
    error("[SERENITY HUB] Access V2 compatibility route compile failed: "..tostring(err),0)
end
return fn()
