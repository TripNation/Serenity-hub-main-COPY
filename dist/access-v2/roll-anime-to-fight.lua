-- SERENITY HUB // ROLL ANIME TO FIGHT ACCESS V2
-- Dedicated provider-fixed route based on the maintained Superhero Access V2 source.

local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local TEMPLATE=BASE.."dist/access-v2/superhero-provider-base.lua"

if not game:IsLoaded() then game.Loaded:Wait() end
if game.PlaceId~=107653945083776 and game.GameId~=10298144467 then error("[SERENITY HUB] This route is only for Roll Anime to Fight!",0) end

local url=TEMPLATE.."?roll_anime_to_fight_provider_v1="..tostring(os.time())..tostring(math.random(100000,999999))
local ok,source=pcall(function() return game:HttpGet(url,true) end)
url=nil
if not ok or type(source)~="string" or source=="" then error("[SERENITY HUB] Access V2 route is unavailable.",0) end

local function replaceExact(old,new,label)
    local p=string.find(source,old,1,true)
    if not p then error("[SERENITY HUB] Roll Anime to Fight access template mismatch: "..tostring(label),0) end
    source=string.sub(source,1,p-1)..new..string.sub(source,p+#old)
end

replaceExact('local GAME_ENTRY=BASE.."dist/games/plus-1-superhero-evolution.lua"','local GAME_ENTRY=BASE.."dist/games/Rollanimetofight.lua"',"game entry")
replaceExact('local TARGET_PLACE=97824450589417','local TARGET_PLACE=107653945083776',"place id")
replaceExact('local TARGET_GAME=10577588270','local TARGET_GAME=10298144467',"game id")
replaceExact('[SERENITY HUB] This route is only for +1 Superhero Evolution.','[SERENITY HUB] This route is only for Roll Anime to Fight!',"route message")
replaceExact('{name="Game",value="+1 Superhero Evolution",inline=true}','{name="Game",value="Roll Anime to Fight!",inline=true}',"webhook game")
replaceExact('[SERENITY HUB] +1 Superhero Evolution payload is unavailable.','[SERENITY HUB] Roll Anime to Fight payload is unavailable.',"payload message")
replaceExact('"@Serenity/Games/Plus1SuperheroEvolution"','"@Serenity/Games/RollAnimeToFight"',"payload chunk")
replaceExact('"@SerenityHub/AccessV2-Superhero-Direct"','"@SerenityHub/AccessV2-RollAnimeToFight-Direct"',"access chunk")
replaceExact('https://lootdest.org/s?a51Wabb2','https://loot-link.com/s?jbyyXFuO',"LootLabs provider")

local fn,err=loadstring(source,"@SerenityHub/AccessV2-RollAnimeToFight-ProviderV1")
source=nil
if not fn then error("[SERENITY HUB] Roll Anime to Fight Access V2 compile failed: "..tostring(err),0) end
return fn()
