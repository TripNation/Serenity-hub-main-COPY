-- SERENITY HUB // +1 SUPERHERO EVOLUTION ACCESS V2
-- Provider hotfix wrapper. Preserves the maintained route while forcing the current LootLabs URL.

local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local SOURCE=BASE.."dist/access-v2/superhero-provider-base.lua"
local OLD="https://lootdest.org/s?a51Wabb2"
local NEW="https://loot-link.com/s?jbyyXFuO"

if not game:IsLoaded() then game.Loaded:Wait() end

local url=SOURCE.."?provider_v3="..tostring(os.time())..tostring(math.random(100000,999999))
local ok,source=pcall(function() return game:HttpGet(url,true) end)
url=nil
if not ok or type(source)~="string" or source=="" then error("[SERENITY HUB] Superhero Access V2 source is unavailable.",0) end
local p=string.find(source,OLD,1,true)
if not p then error("[SERENITY HUB] Superhero provider marker is missing.",0) end
source=string.sub(source,1,p-1)..NEW..string.sub(source,p+#OLD)
local fn,err=loadstring(source,"@SerenityHub/AccessV2-Superhero-ProviderV3")
source=nil
if not fn then error("[SERENITY HUB] Superhero Access V2 compile failed: "..tostring(err),0) end
return fn()
