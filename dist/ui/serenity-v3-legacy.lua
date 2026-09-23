-- SERENITY HUB // OFFICIAL PUBLIC UI ARCHITECTURE V3.0.3
--
-- New/finalized game plugins should use:
--
--   local Serenity = runRemote("dist/ui/serenity-v3.lua")
--   local App = Serenity.Build(GameManifest)
--
-- The existing dist/ui/serenity.lua remains the legacy compatibility
-- library until older game payloads are migrated and regression-tested.

local BASE = "https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local RELEASE_TAG = "?serenity=3.0.3"

local cache = {}

local function runRemote(path)
    if cache[path] ~= nil then
        return cache[path]
    end

    local okHttp, source = pcall(function()
        return game:HttpGet(BASE .. path .. RELEASE_TAG)
    end)

    if not okHttp or type(source) ~= "string" or source == "" then
        error(
            ("[SERENITY HUB] Unable to download %s\n%s")
                :format(path, tostring(source)),
            0
        )
    end

    local fn, compileError = loadstring(
        source,
        "@Serenity/" .. path
    )

    if not fn then
        error(
            ("[SERENITY HUB] Unable to compile %s\n%s")
                :format(path, tostring(compileError)),
            0
        )
    end

    local okRun, result = pcall(fn)

    if not okRun then
        error(
            ("[SERENITY HUB] Unable to initialize %s\n%s")
                :format(path, tostring(result)),
            0
        )
    end

    cache[path] = result
    return result
end

local Serenity = {
    Version = "3.0.3",
    APIVersion = 3,
    DesktopRenderer = "V13.5",
    MobileRenderer = "V14.7",
}

function Serenity.Detect()
    local Router = runRemote("dist/core/device-router.lua")
    return Router.Detect()
end

function Serenity.Build(manifest, options)
    local Bootstrap = runRemote("dist/core/bootstrap.lua")
    return Bootstrap(manifest, options)
end

return Serenity

