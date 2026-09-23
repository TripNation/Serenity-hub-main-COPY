-- SERENITY HUB // V14 MOBILE TRANSPORT
local BASE = "https://raw.githubusercontent.com/MUshihara/Serenity-hub/main/"
local RENDERER_BASE = BASE .. "dist/ui/v14-mobile/"
local RELEASE_TAG = "?serenity=3.0.3"
local names = {
    "head-01.txt",
    "head-02.txt",
    "head-03.txt",
    "part-02.txt",
    "part-03.txt",
    "part-04.txt",
    "part-05.txt",
}
local parts = {}

local function loadRemote(path, chunkName)
    local ok, src = pcall(function()
        return game:HttpGet(path .. RELEASE_TAG)
    end)

    if not ok or type(src) ~= "string" or src == "" then
        error("[SERENITY HUB] Failed to load " .. tostring(chunkName), 0)
    end

    return src
end

for i, path in ipairs(names) do
    parts[i] = loadRemote(
        RENDERER_BASE .. path,
        "V14 mobile part: " .. path
    )
end

local source = table.concat(parts)
local fn, err = loadstring(source, "@Serenity/V14/Mobile")

if not fn then
    error(
        "[SERENITY HUB] Failed to compile V14 mobile renderer: "
            .. tostring(err),
        0
    )
end

local Library = fn()

local iconSource = loadRemote(
    BASE .. "dist/ui/icon-catalog.lua",
    "shared icon catalog"
)
local iconChunk, iconError =
    loadstring(iconSource, "@Serenity/IconCatalog")

if not iconChunk then
    error(
        "[SERENITY HUB] Failed to compile shared icon catalog: "
            .. tostring(iconError),
        0
    )
end

local IconCatalog = iconChunk()
local originalCreate = Library.Create

Library.Version = "14.7-mobile-v3-icons"
Library.IconCatalog = IconCatalog
Library.ResolveIcon = function(value, fallbackTitle)
    return IconCatalog.Resolve(value, fallbackTitle)
end

Library.Create = function(options)
    local window = originalCreate(options)
    local originalAddPage = window.AddPage

    function window:AddPage(name, opts)
        opts = opts or {}

        local page =
            originalAddPage(
                self,
                name,
                opts
            )

        local nav =
            self.Nav
            and self.Nav[name]

        if nav and nav.Icon then
            nav.Icon.Image =
                IconCatalog.Resolve(
                    opts.Icon or name,
                    name
                )
        end

        return page
    end

    return window
end

return Library
