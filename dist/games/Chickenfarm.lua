-- SERENITY HUB // CHICKEN FARM GUARDED ENTRY
local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"

if game.PlaceId~=137233438285284 and game.GameId~=10209534490 then
    error("[SERENITY HUB] This route is only for Chicken Farm.",0)
end

local source=game:HttpGet(
    BASE.."dist/access-v2/payload-guard.lua?chicken="..tostring(os.time())..tostring(math.random(100000,999999)),
    true
)
local fn,err=loadstring(source,"@SerenityHub/PayloadGuard")
source=nil
if not fn then
    error("[SERENITY HUB] Payload guard compile failed: "..tostring(err),0)
end
local run=fn()
return run("dist/runtime/games/Chickenfarm.lua")
