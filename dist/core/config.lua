-- SERENITY HUB // OFFICIAL SHARED CONFIG V3
local HttpService = game:GetService("HttpService")

local Config = {}
Config.__index = Config

local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k,v in pairs(value) do out[k] = copy(v) end
    return out
end

local function sameType(default, value)
    if default == nil then return true end
    if type(default) == type(value) then return true end
    return false
end

function Config.new(options)
    options = options or {}
    local self = setmetatable({}, Config)
    self.SchemaVersion = tonumber(options.SchemaVersion) or 1
    self.Defaults = copy(options.Defaults or {})
    self.Data = copy(self.Defaults)
    self.Path = options.Path or ("SerenityHub/config-%s.json"):format(tostring(game.GameId))
    self.Migrations = options.Migrations or {}
    self.SaveSerial = 0
    self.Destroyed = false
    self.FileAPI = type(writefile)=="function" and type(readfile)=="function" and type(isfile)=="function"
    self:Load()
    return self
end

function Config:Load()
    if not self.FileAPI or not isfile(self.Path) then
        self.Data.__ConfigVersion = self.SchemaVersion
        return false
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(self.Path))
    end)
    if not ok or type(decoded) ~= "table" then
        self.Data.__ConfigVersion = self.SchemaVersion
        return false
    end

    local version = tonumber(decoded.__ConfigVersion) or 0
    while version < self.SchemaVersion do
        local migrate = self.Migrations[version]
        if type(migrate) ~= "function" then break end
        local good, result = pcall(migrate, decoded)
        if not good or type(result) ~= "table" then break end
        decoded = result
        version += 1
        decoded.__ConfigVersion = version
    end

    for key, default in pairs(self.Defaults) do
        local value = decoded[key]
        if value ~= nil and sameType(default,value) then
            self.Data[key] = copy(value)
        end
    end

    self.Data.__ConfigVersion = self.SchemaVersion
    return true
end

function Config:Get(key, fallback)
    local value = self.Data[key]
    if value == nil then return fallback end
    return copy(value)
end

function Config:Set(key, value, silent)
    self.Data[key] = copy(value)
    if not silent then self:SaveSoon() end
end

function Config:Reset()
    self.Data = copy(self.Defaults)
    self.Data.__ConfigVersion = self.SchemaVersion
    return self:SaveNow()
end

function Config:SaveSoon()
    if not self.FileAPI or self.Destroyed then return false end
    self.SaveSerial += 1
    local serial = self.SaveSerial
    task.delay(.55,function()
        if not self.Destroyed and self.SaveSerial == serial then
            self:SaveNow()
        end
    end)
    return true
end

function Config:SaveNow()
    if not self.FileAPI or self.Destroyed then return false end
    if type(makefolder)=="function" then pcall(makefolder,"SerenityHub") end
    self.Data.__ConfigVersion = self.SchemaVersion
    return pcall(function()
        writefile(self.Path,HttpService:JSONEncode(self.Data))
    end)
end

function Config:Destroy()
    if self.Destroyed then return end
    self:SaveNow()
    self.Destroyed = true
end

return Config
