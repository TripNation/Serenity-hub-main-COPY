-- SERENITY HUB // GENERIC ACCESS V2 PROVIDER FIX
-- Wraps the maintained generic core and forces the shared LootLabs button to the current URL.

local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local SOURCE=BASE.."dist/access-v2/core-provider-base.lua"

if not game:IsLoaded() then game.Loaded:Wait() end

local url=SOURCE.."?provider_v3="..tostring(os.time())..tostring(math.random(100000,999999))
local ok,source=pcall(function() return game:HttpGet(url,true) end)
url=nil
if not ok or type(source)~="string" or source=="" then error("[SERENITY HUB] Generic Access V2 source is unavailable.",0) end

local old='local uiPatch=game:HttpGet(UIPATCH.."?v=dynamic-key-v2-20260824h",true)'
local new=old..[[
local __providerOld="    local u=R(ID_LL)"
local __providerNew="    local u=\"https://loot-link.com/s?jbyyXFuO\""
local __providerPos=string.find(uiPatch,__providerOld,1,true)
if not __providerPos then error("[SERENITY HUB] Shared LootLabs provider marker is missing.",0) end
uiPatch=string.sub(uiPatch,1,__providerPos-1)..__providerNew..string.sub(uiPatch,__providerPos+#__providerOld)
]]
local p=string.find(source,old,1,true)
if not p then error("[SERENITY HUB] Generic Access V2 UI-fetch marker is missing.",0) end
source=string.sub(source,1,p-1)..new..string.sub(source,p+#old)

local fn,err=loadstring(source,"@SerenityHub/AccessV2-Generic-ProviderV3")
source=nil
if not fn then error("[SERENITY HUB] Generic Access V2 provider build failed: "..tostring(err),0) end
return fn()
