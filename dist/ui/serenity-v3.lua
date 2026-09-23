-- Serenity shared entrypoint: shared V3 rollout; Phonk retains its device-approved adapter.
local BASE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local cache={}
local function module(path)
    if cache[path] then return cache[path] end
    local source=game:HttpGet(BASE..path.."?serenity=3.2.0-layout-restored1",true)
    local fn,err=loadstring(source,"@Serenity/"..path)
    if not fn then error("[SERENITY HUB] UI compile failed: "..tostring(err),0) end
    local result=fn()
    cache[path]=result
    return result
end
-- Account presence: UserId is sent over HTTPS and HMAC-hashed by the Worker; one combined heartbeat.
-- Opt out before execution with getgenv().SerenityPresenceEnabled = false.
local function startPresence(app)
    local runtime=app and app.Runtime
    if not runtime or runtime.Destroyed then return end
    local cleanup=runtime.TrackCleanup or runtime.OnDestroy
    if type(cleanup)~="function" then return end
    local env=(getgenv and getgenv()) or _G
    local previous=env.__SERENITY_PRESENCE
    if previous and type(previous.Stop)=="function" then previous:Stop() end
    if env.SerenityPresenceEnabled==false then return end
    local send=request or http_request or (syn and syn.request)
    if type(send)~="function" then return end
    local player=game:GetService("Players").LocalPlayer
    if not player or player.UserId<=0 then return end
    local account=tostring(player.UserId)
    local http=game:GetService("HttpService")
    local id=env.__SERENITY_PRESENCE_ID or env.SerenityPresenceTestID
    if type(id)~="string" or #id~=36 then id=http:GenerateGUID(false) end
    env.__SERENITY_PRESENCE_ID=id
    local body=http:JSONEncode({session=id})
    local executionBody=http:JSONEncode({session=id,execution=http:GenerateGUID(false)})
    local executionRecorded=false
    local interval=120 -- Keep the old expiry safe until the updated Worker is deployed.
    local window=app.Window or app
    local state={Stopped=false}
    function state:Stop()
        if self.Stopped then return end
        self.Stopped=true
        if self.Thread then pcall(task.cancel,self.Thread) end
        if env.__SERENITY_PRESENCE==self then env.__SERENITY_PRESENCE=nil end
    end
    cleanup(runtime,function() state:Stop() end)
    env.__SERENITY_PRESENCE=state
    state.Thread=task.defer(function()
        while not state.Stopped and not runtime.Destroyed do
            if env.SerenityPresenceEnabled==false then state:Stop();return end
            local beatOK,beatResponse=pcall(send,{
                Url="https://serenity-active.makimnaritn.workers.dev/heartbeat",
                Method="POST",
                Headers={["Content-Type"]="application/json",["X-Serenity-Account"]=account},
                Body=executionRecorded and body or executionBody,
                Timeout=10,
            })
            local value
            if beatOK and type(beatResponse)=="table" and tonumber(beatResponse.StatusCode)==200 then
                local decoded,data=pcall(http.JSONDecode,http,beatResponse.Body or "")
                if decoded and type(data)=="table" then
                    if data.executionRecorded==true then executionRecorded=true end
                    -- Never use a five-minute interval against the old five-minute expiry.
                    if data.interval==300 and data.ttl==600 then interval=300 else interval=120 end
                    if type(data.active)=="number" and data.active>=0 and data.active<math.huge
                        and data.active==math.floor(data.active) then value=data.active end
                end
            end
            if not state.Stopped and not runtime.Destroyed and type(window.SetActiveCount)=="function" then
                pcall(window.SetActiveCount,window,value)
            end
            task.wait(interval)
        end
    end)

end

-- A startup-only invite: at least 30 seconds between notices, shared across games.
local function showDiscord(app)
    local window=app and (app.Window or app)
    if not window or type(window.NotifyDiscord)~="function" then return end
    local env=(type(getgenv)=="function" and getgenv()) or _G
    local now=os.time()
    local last=tonumber(env.__SERENITY_DISCORD_NOTICE_AT) or 0
    local path="SerenityHub/discord-notice-at.txt"
    if type(readfile)=="function" then
        local ok,value=pcall(readfile,path)
        if ok then last=math.max(last,tonumber(value) or 0) end
    end
    if last>now then last=now end
    if now-last<30 then return end
    env.__SERENITY_DISCORD_NOTICE_AT=now
    if type(writefile)=="function" then
        if type(makefolder)=="function" then pcall(makefolder,"SerenityHub") end
        pcall(writefile,path,tostring(now))
    end
    local invite="https://discord.gg/s4yCvv4Uv"
    local providers={setclipboard,toclipboard,type(syn)=="table" and syn.write_clipboard or false}
    for i=1,3 do
        local copy=providers[i]
        if type(copy)=="function" then
            local ok,result=pcall(copy,invite)
            if ok and result~=false then
                env.__SERENITY_DISCORD_COPIED=true
                break
            end
        end
    end
    window:NotifyDiscord()
end

local Serenity={Version="3.2.0",APIVersion=3}
function Serenity.Detect()
    return module("dist/ui/serenity-v3-legacy.lua").Detect()
end
function Serenity.Build(manifest,options)
    local phonk=game.PlaceId==104809044319701 or game.GameId==10544327471
    local app
    if phonk and type(manifest)=="table" and manifest.GameName=="+1 Phonk Evolution" then
        app=module("dist/ui/phonk-v3-1-0.lua").Build(manifest,options)
    elseif type(manifest)=="table" and manifest.SerenityAPIVersion==3 then
        app=module("dist/ui/universal-v3-2-0.lua").Build(manifest,options)
    else
        app=module("dist/ui/serenity-v3-legacy.lua").Build(manifest,options)
    end
    pcall(startPresence,app)
    pcall(showDiscord,app)
    return app
end
return Serenity





