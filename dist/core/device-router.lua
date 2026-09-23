-- SERENITY HUB // OFFICIAL DEVICE ROUTER V3.0.3
local UserInputService = game:GetService("UserInputService")

local Router = {Version = 2}

local MOBILE_EXECUTOR_HINTS = {
    ["delta"] = true,
    ["arceus"] = true,
    ["arceus x"] = true,
    ["arceus x neo"] = true,
    ["codex"] = true,
    ["hydrogen"] = true,
}

local DESKTOP_EXECUTOR_HINTS = {
    ["solara"] = true,
    ["xeno"] = true,
    ["wave"] = true,
    ["synapse x"] = true,
}

local function normalize(value)
    return string.lower(tostring(value or ""))
        :gsub("[%[%]%(%){}]", " ")
        :gsub("[_%-]", " ")
        :gsub("%s+", " ")
        :match("^%s*(.-)%s*$")
end

local function getExecutor()
    local env = (getgenv and getgenv()) or _G
    local candidates = {
        {"identifyexecutor", env and env.identifyexecutor or rawget(_G,"identifyexecutor")},
        {"getexecutorname", env and env.getexecutorname or rawget(_G,"getexecutorname")},
        {"getexecutor", env and env.getexecutor or rawget(_G,"getexecutor")},
    }

    for _, candidate in ipairs(candidates) do
        if type(candidate[2]) == "function" then
            local ok, name, version = pcall(candidate[2])
            if ok and name ~= nil then
                return tostring(name), version ~= nil and tostring(version) or "Unknown", candidate[1]
            end
        end
    end

    return "Unknown", "Unknown", "none"
end

local function executorHint(name)
    local n = normalize(name)
    for hint in pairs(MOBILE_EXECUTOR_HINTS) do
        if n == hint or string.find(n,hint,1,true) then
            return "Mobile", hint
        end
    end
    for hint in pairs(DESKTOP_EXECUTOR_HINTS) do
        if n == hint or string.find(n,hint,1,true) then
            return "Desktop", hint
        end
    end
end

local function preferredInput()
    local ok, value = pcall(function()
        return UserInputService.PreferredInput
    end)
    return ok and value or nil
end

local function platform()
    local ok, value = pcall(function()
        return UserInputService:GetPlatform()
    end)
    return ok and tostring(value) or "Unavailable"
end

local function isMobilePlatform(value)
    local p = normalize(value)
    return string.find(p,"android",1,true) ~= nil
        or string.find(p,"ios",1,true) ~= nil
        or string.find(p,"iphone",1,true) ~= nil
        or string.find(p,"ipad",1,true) ~= nil
end

function Router.Detect()
    local touch = UserInputService.TouchEnabled
    local keyboard = UserInputService.KeyboardEnabled
    local mouse = UserInputService.MouseEnabled
    local gamepad = UserInputService.GamepadEnabled
    local preferred = preferredInput()
    local platformName = platform()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(0,0)
    local shortest = math.min(viewport.X, viewport.Y)
    local executorName, executorVersion, executorAPI = getExecutor()
    local hinted, matched = executorHint(executorName)
    local reasons = {}

    local function finish(layout, confidence, reason)
        reasons[#reasons+1] = reason
        return {
            Layout = layout,
            Renderer = layout == "Mobile" and "V14.7" or "V13.5",
            Confidence = confidence,
            Reasons = reasons,
            PreferredInput = preferred and tostring(preferred) or "Unavailable",
            TouchEnabled = touch,
            KeyboardEnabled = keyboard,
            MouseEnabled = mouse,
            GamepadEnabled = gamepad,
            Platform = platformName,
            Viewport = viewport,
            Executor = executorName,
            ExecutorVersion = executorVersion,
            ExecutorAPI = executorAPI,
            RouterVersion = Router.Version,
        }
    end

    if touch and not keyboard and not mouse then
        return finish("Mobile","High","Touch is available while keyboard and mouse are unavailable.")
    end

    if touch and isMobilePlatform(platformName) then
        return finish("Mobile","High","Touch plus the reported mobile platform identifies a mobile client.")
    end

    if touch and shortest > 0 and shortest <= 700 then
        reasons[#reasons+1] = "Touch is enabled with a phone/tablet-sized short edge."
        if preferred == Enum.PreferredInput.Touch then
            return finish("Mobile","High","PreferredInput and form factor both agree with mobile.")
        end
        return finish("Mobile","High","Touch plus form factor strongly identifies mobile even if synthetic desktop input exists.")
    end

    if touch and hinted == "Mobile" then
        reasons[#reasons+1] = "Touch is enabled and mobile executor fallback matched: " .. tostring(matched)
        return finish("Mobile","Medium","Touch and executor evidence agree with mobile.")
    end

    if keyboard and mouse and not touch then
        return finish("Desktop","High","Keyboard and mouse are available while touch is unavailable.")
    end

    if keyboard and mouse and shortest >= 800 and preferred ~= Enum.PreferredInput.Touch then
        return finish("Desktop","High","Keyboard/mouse plus a large viewport strongly suggest desktop.")
    end

    if preferred == Enum.PreferredInput.Touch and touch then
        return finish("Mobile","Medium","Touch is the current preferred input.")
    end

    if preferred == Enum.PreferredInput.KeyboardAndMouse and (keyboard or mouse) then
        return finish("Desktop","Medium","Keyboard/mouse is the current preferred input.")
    end

    if hinted then
        reasons[#reasons+1] = "Executor fallback matched: " .. tostring(matched)
        return finish(hinted,"Low","Executor identity was used only after stronger signals were inconclusive.")
    end

    if touch and shortest > 0 and shortest <= 800 then
        return finish("Mobile","Low","Touch plus viewport size was the remaining fallback.")
    end

    if keyboard or mouse then
        return finish("Desktop","Low","Keyboard/mouse capability was the remaining fallback.")
    end

    return finish("Desktop","Low","Unknown environment; desktop is the safe renderer fallback.")
end

return Router
