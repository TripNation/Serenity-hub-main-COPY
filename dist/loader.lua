-- SERENITY HUB // ACCESS V2 ENTRY

-- Temporary global switch. Set to true to restore the key system.
local ACCESS_ENABLED=false

-- One-time cleanup: only SerenityHub/.access is used by the current gate.
pcall(function()
    if type(delfile)=="function" and type(isfile)=="function"
        and isfile("SerenityHub/.access-v2.dat") then
        delfile("SerenityHub/.access-v2.dat")
    end
end)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local function marketplaceName()
    local ok,info=pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if ok and type(info)=="table" and type(info.Name)=="string" then
        return string.lower(info.Name)
    end
    return nil
end

local function isCutGrassAdventure()
    if game.PlaceId==90086669327265 or game.GameId==10410945205 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"cut grass",1,true)~=nil and string.find(name,"adventure",1,true)~=nil
end

local function isDrainWater()
    if game.PlaceId==103883942725157 or game.GameId==10561352230 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"drain water",1,true)~=nil
end

local function isSellOres()
    if game.PlaceId==122572082932179 or game.GameId==10336278580 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"sell ores",1,true)~=nil
end

local function isGreedyGrowers()
    if game.PlaceId==74102906764176 or game.GameId==10440833423 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"greedy",1,true)~=nil and string.find(name,"growers",1,true)~=nil
end

local function isChickenFarm()
    if game.PlaceId==137233438285284 or game.GameId==10209534490 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"chicken",1,true)~=nil and string.find(name,"farm",1,true)~=nil
end

local function isMonkeyEvolution()
    if game.PlaceId==91701030914075 or game.GameId==10605939914 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"monkey",1,true)~=nil and string.find(name,"evolution",1,true)~=nil
end

local function isSuperheroEvolution()
    if game.PlaceId==97824450589417 or game.GameId==10577588270 then return true end

    local RS=game:GetService("ReplicatedStorage")
    local Client=RS:FindFirstChild("Client")
    local Shared=RS:FindFirstChild("Shared")
    local Remotes=Shared and Shared:FindFirstChild("Remotes")

    local controllerMatch=Client and Client:FindFirstChild("ItemController") and Client:FindFirstChild("DataController")
    local remoteMatch=Remotes and Remotes:FindFirstChild("RequestRebirth") and Remotes:FindFirstChild("RequestWorldChange") and Remotes:FindFirstChild("EnemyMeleeContact")
    local worldMatch=workspace:FindFirstChild("BossFightStage") and workspace:FindFirstChild("CombatZoneTrigger") and (workspace:FindFirstChild("MapTest") or workspace:FindFirstChild("Map3"))

    if controllerMatch and remoteMatch and worldMatch then return true end

    local name=marketplaceName()
    return name~=nil and string.find(name,"superhero",1,true)~=nil and string.find(name,"evolution",1,true)~=nil
end

local function isHeroesRNG()
    if game.PlaceId==108307565942574 or game.GameId==10153098880 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"heroes",1,true)~=nil and string.find(name,"rng",1,true)~=nil
end

local function isThrowCoin()
    if game.PlaceId==115681808123944 or game.GameId==10131390815 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"throw a coin",1,true)~=nil
end

local function isCheatingDuringTesting()
    if game.PlaceId==98894876188248 or game.GameId==9780429221 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"cheating during testing",1,true)~=nil
end

local function isRollAnimeToFight()
    if game.PlaceId==107653945083776 or game.GameId==10298144467 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"roll anime to fight",1,true)~=nil
end

local function isDinoEvolution()
    if game.PlaceId==103138601755519 or game.GameId==10664667515 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"dino",1,true)~=nil and string.find(name,"evolution",1,true)~=nil
end

local function isPhonkEvolution()
    if game.PlaceId==104809044319701 or game.GameId==10544327471 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"phonk",1,true)~=nil and string.find(name,"evolution",1,true)~=nil
end

local function isUnscathedRNG()
    if game.PlaceId==122951224417794 or game.GameId==8959257868 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"unscathed",1,true)~=nil and string.find(name,"rng",1,true)~=nil
end

local function isMineAMountain()
    if game.PlaceId==125927821145949 or game.GameId==10187294555 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"mine a mountain",1,true)~=nil
end

local function isSearchForTheNeedle()
    if game.GameId==10756011174 then return true end
    if game.PlaceId==77108422251420 or game.PlaceId==108628039999641 or game.PlaceId==83445806734780 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"search for the needle",1,true)~=nil
end

local function isTongueEscape()
    if game.PlaceId==122245938604556 or game.GameId==10681914462 then return true end
    local name=marketplaceName()
    return name~=nil and string.find(name,"tongue escape",1,true)~=nil
end

local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local targetDrain=isDrainWater()
local targetSellOres=not targetDrain and isSellOres()
local targetCutGrass=not targetDrain and not targetSellOres and isCutGrassAdventure()
local targetGreedy=not targetDrain and not targetSellOres and not targetCutGrass and isGreedyGrowers()
local targetChicken=not targetDrain and not targetSellOres and not targetCutGrass and not targetGreedy and isChickenFarm()
local targetMonkey=not targetDrain and not targetSellOres and not targetCutGrass and not targetGreedy and not targetChicken and isMonkeyEvolution()
local targetSuperhero=not targetDrain and not targetSellOres and not targetCutGrass and not targetGreedy and not targetChicken and not targetMonkey and isSuperheroEvolution()
local targetHeroesRNG=not targetDrain and not targetSellOres and not targetCutGrass and not targetGreedy and not targetChicken and not targetMonkey and not targetSuperhero and isHeroesRNG()
local targetThrowCoin=not targetDrain and not targetSellOres and not targetCutGrass and not targetGreedy and not targetChicken and not targetMonkey and not targetSuperhero and not targetHeroesRNG and isThrowCoin()
local targetCDT=not targetDrain and not targetSellOres and not targetCutGrass and not targetGreedy and not targetChicken and not targetMonkey and not targetSuperhero and not targetHeroesRNG and not targetThrowCoin and isCheatingDuringTesting()
local targetRATF=not targetDrain and not targetSellOres and not targetCutGrass and not targetGreedy and not targetChicken and not targetMonkey and not targetSuperhero and not targetHeroesRNG and not targetThrowCoin and not targetCDT and isRollAnimeToFight()
local targetDino=not targetDrain and not targetSellOres and not targetCutGrass and not targetGreedy and not targetChicken and not targetMonkey and not targetSuperhero and not targetHeroesRNG and not targetThrowCoin and not targetCDT and not targetRATF and isDinoEvolution()
local targetPhonk=not targetDrain and not targetSellOres and not targetCutGrass and not targetGreedy and not targetChicken and not targetMonkey and not targetSuperhero and not targetHeroesRNG and not targetThrowCoin and not targetCDT and not targetRATF and not targetDino and isPhonkEvolution()
local targetUnscathed=not targetDrain and not targetSellOres and not targetCutGrass and not targetGreedy and not targetChicken and not targetMonkey and not targetSuperhero and not targetHeroesRNG and not targetThrowCoin and not targetCDT and not targetRATF and not targetDino and not targetPhonk and isUnscathedRNG()
local targetMine=not targetDrain and not targetSellOres and not targetCutGrass and not targetGreedy and not targetChicken and not targetMonkey and not targetSuperhero and not targetHeroesRNG and not targetThrowCoin and not targetCDT and not targetRATF and not targetDino and not targetPhonk and not targetUnscathed and isMineAMountain()
local targetNeedle=not targetDrain and not targetSellOres and not targetCutGrass and not targetGreedy and not targetChicken and not targetMonkey and not targetSuperhero and not targetHeroesRNG and not targetThrowCoin and not targetCDT and not targetRATF and not targetDino and not targetPhonk and not targetUnscathed and not targetMine and isSearchForTheNeedle()
local targetTongue=not targetDrain and not targetSellOres and not targetCutGrass and not targetGreedy and not targetChicken and not targetMonkey and not targetSuperhero and not targetHeroesRNG and not targetThrowCoin and not targetCDT and not targetRATF and not targetDino and not targetPhonk and not targetUnscathed and not targetMine and not targetNeedle and isTongueEscape()

local path
local chunkName
if targetDrain then
    path=ACCESS_ENABLED and "dist/access-v2/core.lua" or "dist/games/drain-water.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2" or "@SerenityHub/Game-DrainWater"
elseif targetSellOres then
    path=ACCESS_ENABLED and "dist/access-v2/sell-ores.lua" or "dist/games/sell_ores.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-SellOres" or "@SerenityHub/Game-SellOres"
elseif targetCutGrass then
    path=ACCESS_ENABLED and "dist/access-v2/cut-grass-v2.lua" or "dist/games/1-Cut-Grass-Adventure.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-CutGrass-V2" or "@SerenityHub/Game-CutGrass"
elseif targetGreedy then
    path=ACCESS_ENABLED and "dist/access-v2/greedy-growers.lua" or "dist/games/GreedyGrowers.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-GreedyGrowers" or "@SerenityHub/Game-GreedyGrowers"
elseif targetChicken then
    path=ACCESS_ENABLED and "dist/access-v2/chicken-farm.lua" or "dist/games/Chickenfarm.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-ChickenFarm" or "@SerenityHub/Game-ChickenFarm"
elseif targetMonkey then
    path=ACCESS_ENABLED and "dist/access-v2/monkey.lua" or "dist/games/plus-1-monkey-evolution.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-Monkey" or "@SerenityHub/Game-Monkey"
elseif targetSuperhero then
    path=ACCESS_ENABLED and "dist/access-v2/superhero.lua" or "dist/games/plus-1-superhero-evolution.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-Superhero" or "@SerenityHub/Game-Superhero"
elseif targetHeroesRNG then
    path=ACCESS_ENABLED and "dist/access-v2/core.lua" or "dist/runtime/games/Heroes_RNG.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-HeroesRNG" or "@SerenityHub/Game-HeroesRNG"
elseif targetThrowCoin then
    path=ACCESS_ENABLED and "dist/access-v2/core.lua" or "dist/games/Throw_a_coin.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-ThrowCoin" or "@SerenityHub/Game-ThrowCoin"
elseif targetCDT then
    path=ACCESS_ENABLED and "dist/access-v2/core.lua" or "dist/games/Cheating_During_Testing.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-CDT" or "@SerenityHub/Game-CDT"
elseif targetRATF then
    path=ACCESS_ENABLED and "dist/access-v2/roll-anime-to-fight.lua" or "dist/games/Rollanimetofight.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-RollAnimeToFight" or "@SerenityHub/Game-RollAnimeToFight"
elseif targetDino then
    path=ACCESS_ENABLED and "dist/access-v2/core.lua" or "dist/runtime/games/DinoEvolution.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-DinoEvolution" or "@SerenityHub/Game-DinoEvolution"
elseif targetPhonk then
    path=ACCESS_ENABLED and "dist/access-v2/phonkevolution.lua" or "dist/games/phonkevolution.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-PhonkEvolution" or "@SerenityHub/Game-PhonkEvolution"
elseif targetUnscathed then
    path=ACCESS_ENABLED and "dist/access-v2/core.lua" or "dist/games/unscathedrng.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-UnscathedRNG" or "@SerenityHub/Game-UnscathedRNG"
elseif targetMine then
    path=ACCESS_ENABLED and "dist/access-v2/core.lua" or "dist/runtime/games/mineamountain.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-MineAMountain" or "@SerenityHub/Game-MineAMountain"
elseif targetNeedle then
    path=ACCESS_ENABLED and "dist/access-v2/core.lua" or "dist/runtime/games/SEARCH FOR THE NEEDLE.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-SearchForTheNeedle" or "@SerenityHub/Game-SearchForTheNeedle"
elseif targetTongue then
    path=ACCESS_ENABLED and "dist/access-v2/core.lua" or "dist/runtime/games/TongueEscape.lua"
    chunkName=ACCESS_ENABLED and "@SerenityHub/AccessV2-TongueEscape" or "@SerenityHub/Game-TongueEscape"
else
    path="dist/access-v2/core.lua"
    chunkName="@SerenityHub/AccessV2"
end

if not ACCESS_ENABLED then
    local supported=targetDrain or targetSellOres or targetCutGrass or targetGreedy
        or targetChicken or targetMonkey or targetSuperhero or targetHeroesRNG or targetThrowCoin or targetCDT or targetRATF or targetDino or targetPhonk or targetUnscathed or targetMine or targetNeedle or targetTongue
    if supported then
        local env=(type(getgenv)=="function" and getgenv()) or _G
        env.__SERENITY_PAYLOAD_AUTHORIZED=true
        _G.__SERENITY_PAYLOAD_AUTHORIZED=true
    end
end

local U=BASE..path
local source=game:HttpGet(
    U.."?v=20260912-tongue-escape-route&cb="..tostring(os.time())..tostring(math.random(100000,999999)),
    true
)
local fn,err=loadstring(source,chunkName)
source=nil
if not fn then
    error("[SERENITY HUB] Access V2 entry compile failed: "..tostring(err),0)
end
return fn()