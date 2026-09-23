-- SERENITY HUB // GUARDED GAME ENTRY
local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local source=game:HttpGet(BASE.."dist/access-v2/payload-guard.lua?cb="..tostring(os.time())..tostring(math.random(100000,999999)),true)
local fn,err=loadstring(source,"@SerenityHub/PayloadGuard")
source=nil
if not fn then error("[SERENITY HUB] Payload guard compile failed: "..tostring(err),0) end
local run=fn()
return run("dist/runtime/games/collect-all-the-leaves.lua")
