-- SERENITY HUB // CANONICAL BOOTSTRAP
-- This tiny stable entry always fetches the newest game router with cache-busting.

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local url=BASE.."dist/loader.lua?cb="..tostring(os.time())..tostring(math.random(100000,999999))
local source=game:HttpGet(url,true)
local fn,err=loadstring(source,"@SerenityHub/CurrentLoader")
source=nil
if not fn then
    error("[SERENITY HUB] Loader compile failed: "..tostring(err),0)
end
return fn()
