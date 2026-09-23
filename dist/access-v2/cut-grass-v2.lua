-- SERENITY HUB // +1 CUT GRASS ADVENTURE ACCESS V2
-- Provider-fixed route based on the maintained Superhero Access V2 source.

local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local TEMPLATE=BASE.."dist/access-v2/superhero-provider-base.lua"

if not game:IsLoaded() then game.Loaded:Wait() end

local TARGET_PLACE=90086669327265
local TARGET_GAME=10410945205
if game.PlaceId~=TARGET_PLACE and game.GameId~=TARGET_GAME then error("[SERENITY HUB] This route is only for +1 Cut Grass Adventure.",0) end

local url=TEMPLATE.."?cut_grass_provider_v3="..tostring(os.time())..tostring(math.random(100000,999999))
local ok,source=pcall(function() return game:HttpGet(url,true) end)
url=nil
if not ok or type(source)~="string" or source=="" then error("[SERENITY HUB] Access V2 route is unavailable.",0) end

local function replaceExact(old,new,label)
    local p=string.find(source,old,1,true)
    if not p then error("[SERENITY HUB] Cut Grass access template mismatch: "..tostring(label),0) end
    source=string.sub(source,1,p-1)..new..string.sub(source,p+#old)
end

replaceExact('local GAME_ENTRY=BASE.."dist/games/plus-1-superhero-evolution.lua"','local GAME_ENTRY=BASE.."dist/games/1-Cut-Grass-Adventure.lua"',"game entry")
replaceExact('local TARGET_PLACE=97824450589417','local TARGET_PLACE=90086669327265',"place id")
replaceExact('local TARGET_GAME=10577588270','local TARGET_GAME=10410945205',"game id")
replaceExact('[SERENITY HUB] This route is only for +1 Superhero Evolution.','[SERENITY HUB] This route is only for +1 Cut Grass Adventure.',"route message")
replaceExact('{name="Game",value="+1 Superhero Evolution",inline=true}','{name="Game",value="+1 Cut Grass Adventure",inline=true}',"webhook game")
replaceExact('[SERENITY HUB] +1 Superhero Evolution payload is unavailable.','[SERENITY HUB] +1 Cut Grass Adventure payload is unavailable.',"payload message")
replaceExact('"@Serenity/Games/Plus1SuperheroEvolution"','"@Serenity/Games/Plus1CutGrassAdventure"',"payload chunk")
replaceExact('"@SerenityHub/AccessV2-Superhero-Direct"','"@SerenityHub/AccessV2-CutGrass-Direct"',"access chunk")
replaceExact('https://lootdest.org/s?a51Wabb2','https://loot-link.com/s?jbyyXFuO',"LootLabs provider")

local fn,err=loadstring(source,"@SerenityHub/AccessV2-CutGrass-ProviderV3")
source=nil
if not fn then error("[SERENITY HUB] Cut Grass Access V2 compile failed: "..tostring(err),0) end
return fn()
