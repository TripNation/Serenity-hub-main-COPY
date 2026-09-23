-- SERENITY HUB // OFFICIAL GAME MANIFEST VALIDATOR V3
local Validator = {APIVersion = 3}

local SUPPORTED = {
    Action=true, Switch=true, Select=true, MultiSelect=true,
    Slider=true, Input=true, Live=true, Progress=true, Paragraph=true,
}

local function fail(errors, where, message)
    errors[#errors+1] = ("%s: %s"):format(where,message)
end

local function listHas(list, value)
    for _,v in ipairs(list or {}) do
        if tostring(v) == tostring(value) then return true end
    end
    return false
end

function Validator.Validate(manifest)
    local errors, warnings = {}, {}
    if type(manifest) ~= "table" then
        return false,{"Manifest must be a table."},warnings
    end

    if tonumber(manifest.SerenityAPIVersion) ~= Validator.APIVersion then
        fail(errors,"Manifest",("SerenityAPIVersion must be %d."):format(Validator.APIVersion))
    end

    if type(manifest.Pages) ~= "table" or #manifest.Pages == 0 then
        fail(errors,"Manifest","Pages must contain at least one page.")
        return false,errors,warnings
    end

    local ids = {}
    local function unique(id, where)
        if ids[id] then
            fail(errors,where,"Duplicate internal ID: "..id)
        else
            ids[id] = where
        end
    end

    for pi,page in ipairs(manifest.Pages) do
        local pw = "Page["..pi.."]"
        if type(page.Id) ~= "string" or page.Id == "" then fail(errors,pw,"Id is required.") end
        if type(page.Title) ~= "string" or page.Title == "" then fail(errors,pw,"Title is required.") end
        if page.Id then unique(page.Id,pw) end
        if type(page.Features) ~= "table" then
            fail(errors,pw,"Features must be a table.")
        else
            for fi,feature in ipairs(page.Features) do
                local fw = pw.."/Feature["..fi.."]"
                if type(feature.Id) ~= "string" or feature.Id == "" then fail(errors,fw,"Id is required.") end
                if type(feature.Title) ~= "string" or feature.Title == "" then fail(errors,fw,"Title is required.") end
                local featureId = tostring(page.Id).."."..tostring(feature.Id)
                if page.Id and feature.Id then unique(featureId,fw) end
                if type(feature.Controls) ~= "table" then
                    fail(errors,fw,"Controls must be a table.")
                else
                    for ci,control in ipairs(feature.Controls) do
                        local cw = fw.."/Control["..ci.."]"
                        if not SUPPORTED[control.Type] then
                            fail(errors,cw,"Unsupported Type: "..tostring(control.Type))
                        end
                        if control.Type ~= "Paragraph" and (type(control.Id) ~= "string" or control.Id == "") then
                            fail(errors,cw,"Id is required.")
                        end
                        local controlId = featureId.."."..tostring(control.Id or ("Paragraph"..ci))
                        if page.Id and feature.Id and control.Id then unique(controlId,cw) end

                        if control.Type == "Select" then
                            if type(control.Options) ~= "table" or #control.Options == 0 then
                                fail(errors,cw,"Select requires non-empty Options.")
                            elseif control.Default ~= nil and not listHas(control.Options,control.Default) then
                                fail(errors,cw,"Select Default is not present in Options.")
                            end
                        elseif control.Type == "MultiSelect" then
                            if type(control.Options) ~= "table" then fail(errors,cw,"MultiSelect requires Options.") end
                            if type(control.EmptyMeansAll) ~= "boolean" then
                                fail(errors,cw,"MultiSelect must explicitly define EmptyMeansAll=true/false.")
                            end
                            if control.Default ~= nil and type(control.Default) ~= "table" then
                                fail(errors,cw,"MultiSelect Default must be a table.")
                            end
                        elseif control.Type == "Slider" then
                            if type(control.Min) ~= "number" or type(control.Max) ~= "number" or control.Max <= control.Min then
                                fail(errors,cw,"Slider requires numeric Min < Max.")
                            end
                        elseif control.Type == "Progress" then
                            if control.Min ~= nil and control.Max ~= nil and control.Max <= control.Min then
                                fail(errors,cw,"Progress Max must be greater than Min.")
                            end
                        end
                    end
                end
            end
        end
    end

    return #errors == 0, errors, warnings
end

return Validator
