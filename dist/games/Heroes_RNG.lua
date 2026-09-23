-- SERENITY HUB // HEROES RNG GUARDED ENTRY
local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"

if game.PlaceId~=108307565942574 and game.GameId~=10153098880 then
    error("[SERENITY HUB] This route is only for Heroes RNG.",0)
end

local source=game:HttpGet(
    BASE.."dist/access-v2/payload-guard.lua?heroesrng="..tostring(os.time())..tostring(math.random(100000,999999)),
    true
)
local fn,err=loadstring(source,"@SerenityHub/PayloadGuard")
source=nil
if not fn then
    error("[SERENITY HUB] Payload guard compile failed: "..tostring(err),0)
end
local run=fn()
return run("dist/runtime/games/Heroes_RNG.lua")
