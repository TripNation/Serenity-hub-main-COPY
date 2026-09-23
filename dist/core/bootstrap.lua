-- SERENITY HUB // OFFICIAL ARCHITECTURE V3.0.3 BOOTSTRAP
-- Public shared architecture entry used by migrated Serenity game plugins.
--
-- Game plugins own game mechanics/controllers.
-- This bootstrap owns validation, device routing, config, renderer selection,
-- runtime ownership and manifest-to-UI construction.

local BASE = "https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local RELEASE_TAG = "?serenity=3.0.3"

local moduleCache = {}

local function runRemote(path)
    if moduleCache[path] ~= nil then
        return moduleCache[path]
    end

    local okHttp, source = pcall(function()
        return game:HttpGet(BASE .. path .. RELEASE_TAG)
    end)

    if not okHttp or type(source) ~= "string" or source == "" then
        error(
            ("[SERENITY HUB] Failed to download shared module: %s\n%s")
                :format(path, tostring(source)),
            0
        )
    end

    local chunk, compileError = loadstring(
        source,
        "@Serenity/" .. path
    )

    if not chunk then
        error(
            ("[SERENITY HUB] Failed to compile shared module: %s\n%s")
                :format(path, tostring(compileError)),
            0
        )
    end

    local okRun, result = pcall(chunk)

    if not okRun then
        error(
            ("[SERENITY HUB] Failed to initialize shared module: %s\n%s")
                :format(path, tostring(result)),
            0
        )
    end

    moduleCache[path] = result
    return result
end

local function collectDefaults(manifest)
    local defaults = {}

    for _, page in ipairs(manifest.Pages or {}) do
        for _, feature in ipairs(page.Features or {}) do
            for _, control in ipairs(feature.Controls or {}) do
                if control.Id and control.Default ~= nil then
                    defaults[
                        table.concat(
                            {page.Id, feature.Id, control.Id},
                            "."
                        )
                    ] = control.Default
                end
            end
        end
    end

    return defaults
end

return function(manifest, options)
    options = options or {}

    local Validator = runRemote("dist/core/manifest-validator.lua")
    local valid, errors, warnings = Validator.Validate(manifest)

    if not valid then
        error(
            "[SERENITY HUB] Manifest validation failed:\n - "
                .. table.concat(errors, "\n - "),
            0
        )
    end

    for _, warning in ipairs(warnings or {}) do
        warn("[SERENITY HUB] Manifest warning: " .. tostring(warning))
    end

    local DeviceRouter = runRemote("dist/core/device-router.lua")
    local profile = DeviceRouter.Detect()

    local rendererPath =
        profile.Layout == "Mobile"
        and "dist/ui/v14-mobile.lua"
        or "dist/ui/v13-desktop.lua"

    local renderer = runRemote(rendererPath)

    local expectedKind = profile.Layout == "Mobile" and "Mobile" or "Desktop"
    if type(renderer) ~= "table" or renderer.RendererKind ~= expectedKind then
        error(
            ("[SERENITY HUB] Renderer routing mismatch. Detected=%s Expected=%s Loaded=%s Path=%s")
                :format(
                    tostring(profile.Layout),
                    tostring(expectedKind),
                    tostring(type(renderer) == "table" and renderer.RendererKind or type(renderer)),
                    tostring(rendererPath)
                ),
            0
        )
    end

    local Runtime = runRemote("dist/core/runtime.lua")
    local Config = runRemote("dist/core/config.lua")
    local Adapter = runRemote("dist/core/manifest-renderer.lua")

    local runtime = Runtime.new(
        options.RuntimeKey
        or manifest.RuntimeKey
        or "__SERENITY_RUNTIME_V3"
    )

    local config = Config.new({
        SchemaVersion = manifest.ConfigVersion or 1,
        Defaults = collectDefaults(manifest),
        Path = options.ConfigPath
            or manifest.ConfigPath
            or ("SerenityHub/config-%s.json")
                :format(tostring(game.GameId)),
        Migrations = manifest.ConfigMigrations or {},
    })

    runtime:TrackCleanup(function()
        config:Destroy()
    end)

    local adapter = Adapter.new({
        Layout = profile.Layout,
        Library = renderer,
        Config = config,
        Runtime = runtime,
        Manifest = manifest,
    })

    local okBuild, windowOrError = xpcall(
        function()
            return adapter:Build()
        end,
        debug.traceback
    )

    if not okBuild then
        runtime:Destroy("build-failed")
        error(
            "[SERENITY HUB] UI build failed:\n"
                .. tostring(windowOrError),
            0
        )
    end

    local app = {
        Version = "3.0.3",
        APIVersion = Validator.APIVersion,
        Runtime = runtime,
        Profile = profile,
        Config = config,
        Adapter = adapter,
        Window = windowOrError,
        Manifest = manifest,
    }

    function app:Destroy()
        runtime:Destroy("manual")
    end

    print("============================================================")
    print(" SERENITY HUB // OFFICIAL ARCHITECTURE V3.0.3")
    print("============================================================")
    print("Layout      :", profile.Layout)
    print("Renderer    :", profile.Renderer)
    print("Confidence  :", profile.Confidence)
    print("Platform    :", profile.Platform)
    print("Executor    :", profile.Executor)
    print("Router      :", profile.RouterVersion or "legacy")
    print(
        "Viewport    :",
        tostring(profile.Viewport.X) .. "x" .. tostring(profile.Viewport.Y)
    )
    print("Config      :", config.Path)
    print("API Version :", Validator.APIVersion)
    print("Architecture:", app.Version)
    print("============================================================")

    return app
end
