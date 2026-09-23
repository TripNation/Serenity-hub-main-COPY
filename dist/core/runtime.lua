-- SERENITY HUB // OFFICIAL RUNTIME OWNER V3
local Runtime = {}
Runtime.__index = Runtime

function Runtime.new(globalKey)
    local env = (getgenv and getgenv()) or _G
    globalKey = globalKey or "__SERENITY_OFFICIAL_RUNTIME"

    local old = env[globalKey]
    if old and type(old.Destroy) == "function" then
        pcall(function() old:Destroy("re-execute") end)
    end

    local self = setmetatable({
        GlobalKey = globalKey,
        Environment = env,
        Connections = {},
        Cleanups = {},
        Children = {},
        Destroyed = false,
    }, Runtime)

    env[globalKey] = self
    return self
end

function Runtime:TrackConnection(connection)
    if connection then
        self.Connections[#self.Connections+1] = connection
    end
    return connection
end

function Runtime:TrackCleanup(fn)
    if type(fn) == "function" then
        self.Cleanups[#self.Cleanups+1] = fn
    end
    return fn
end

function Runtime:TrackChild(object)
    if object then
        self.Children[#self.Children+1] = object
    end
    return object
end

function Runtime:Destroy(reason)
    if self.Destroyed then return end
    self.Destroyed = true

    for i = #self.Children, 1, -1 do
        local child = self.Children[i]
        pcall(function()
            if type(child) == "table" and type(child.Destroy) == "function" then
                child:Destroy()
            elseif type(child) == "table" and type(child.Close) == "function" then
                child:Close()
            elseif typeof(child) == "Instance" then
                child:Destroy()
            end
        end)
    end

    for i = #self.Cleanups, 1, -1 do
        pcall(self.Cleanups[i], reason)
    end

    for _, connection in ipairs(self.Connections) do
        pcall(function() connection:Disconnect() end)
    end

    table.clear(self.Children)
    table.clear(self.Cleanups)
    table.clear(self.Connections)

    if self.Environment[self.GlobalKey] == self then
        self.Environment[self.GlobalKey] = nil
    end
end

return Runtime
