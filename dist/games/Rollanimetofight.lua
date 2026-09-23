-- SERENITY HUB // ROLL ANIME TO FIGHT GUARDED ENTRY
local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"

if game.PlaceId~=107653945083776 and game.GameId~=10298144467 then
    error("[SERENITY HUB] This route is only for Roll Anime to Fight!",0)
end

local source=game:HttpGet(
    BASE.."dist/access-v2/payload-guard.lua?rollanimetofight="..tostring(os.time())..tostring(math.random(100000,999999)),
    true
)
local fn,err=loadstring(source,"@SerenityHub/PayloadGuard")
source=nil
if not fn then
    error("[SERENITY HUB] Payload guard compile failed: "..tostring(err),0)
end
local run=fn()
return run("dist/runtime/games/Rollanimetofight.lua")
