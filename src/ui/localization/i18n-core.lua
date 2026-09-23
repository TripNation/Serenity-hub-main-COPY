local I18N={}
I18N.Options={'English','Filipino','Bahasa Indonesia','Tiếng Việt','ไทย','Español','Português (Brasil)','Français','Deutsch','Русский'}
local codes={'en','fil','id','vi','th','es','pt','fr','de','ru'}
local supported={en=true,fil=true,id=true,vi=true,th=true,es=true,pt=true,fr=true,de=true,ru=true}
local aliases={tl='fil',['in']='id'}
function I18N.Resolve(locale)
    local code=tostring(locale or ''):lower():gsub('_','-'):match('^([a-z]+)')
    code=aliases[code] or code
    return supported[code] and code or 'en'
end
function I18N.Code(selection)
    for i,name in ipairs(I18N.Options) do if name==selection then return codes[i] end end
    return 'en'
end
function I18N.new(selection,detected)
    local self={Bindings={},Selection=selection,Detected=detected,Destroyed=false}
    function self:Language()
        local chosen=I18N.Code(self.Selection)
        return chosen
    end
    function self:T(source)
        if type(source)~='string' or source=='' then return source end
        local pack=I18N.Packs[self:Language()] or {}
        if pack[source] then return pack[source] end
        -- Only translate dictionary-backed labels with numeric values. Never rewrite names.
        local label,separator,value=source:match('^(.-)(: )([%d][%d,%.]*)$')
        if not label then label,separator,value=source:match('^(.-)( · )([%d][%d,%.]*)$') end
        if label and pack[label] then return pack[label]..separator..value end
        local selected=source:match('^Language changed: (.+)$')
        if selected then return (pack['Language changed'] or 'Language changed')..': '..selected end
        -- Translate only known UI patterns; never edit a user's text or arbitrary values.
        local time=source:match('^Session · (%d+:%d%d:%d%d)$')
        if time then return (pack.Session or 'Session')..' · '..time end
        local count=source:match('^(%d+ / 1800) characters$')
        if count then return count..' '..(pack.characters or 'characters') end
-- BEGIN ANIME DICE DYNAMIC LOCALIZATION
        -- Translate only dictionary-backed Anime Dice status fragments. Unknown names/values stay canonical.
        if source:find(' • ',1,true) then
            local parts={}
            local changed=false
            for part in (source..' • '):gmatch('(.-) • ') do
                local translated=pack[part]
                if not translated then
                    local n,label=part:match('^([%d][%d,%.]*) (.+)$')
                    if n and label and pack[label] then
                        translated=n..' '..pack[label]
                    else
                        local label2,n2=part:match('^(.-) ([%d][%d,%.]*)$')
                        if label2 and n2 and pack[label2] then translated=pack[label2]..' '..n2 end
                    end
                end
                if translated then changed=true;parts[#parts+1]=translated else parts[#parts+1]=part end
            end
            if changed then return table.concat(parts,' • ') end
        end
        local sold=source:match('^Sold (.+)$')
        if sold and pack.Sold then return pack.Sold..' '..sold end
        local floor=source:match('^Floor (%d+)$')
        if floor and pack.Floor then return pack.Floor..' '..floor end
        local number,suffix=source:match('^([%d][%d,%.]*) (.+)$')
        if number and suffix and pack[suffix] then return number..' '..pack[suffix] end
        -- END ANIME DICE DYNAMIC LOCALIZATION
        if source:find(' / ',1,true) then
            local parts={}; for part in (source..' / '):gmatch('(.-) / ') do parts[#parts+1]=pack[part] or part end
            return table.concat(parts,' / ')
        end
        return source
    end
    function self:Refresh()
        for _,binding in pairs(self.Bindings) do binding.Render() end
    end
    function self:Set(selection)
        self.Selection='English'
        for _,name in ipairs(I18N.Options) do if name==selection then self.Selection=name end end
        self:Refresh()
    end
    function self:Detect(locale)
        self.Detected=locale
        -- Explicit user choice; Roblox locale never changes the selected language.
    end
    function self:Bind(object,property)
        local binding={Source=object[property],Last=nil,Font=object.Font,Wrapped=object.TextWrapped,Truncate=object.TextTruncate}
        local id={};self.Bindings[id]=binding
        function binding.Render()
            if self.Destroyed then return end
            -- Roblox may defer property events: capture a pending canonical write before refreshing.
            if binding.Last~=nil and object[property]~=binding.Last then binding.Source=object[property] end
            binding.Last=self:T(binding.Source)
            if object[property]~=binding.Last then object[property]=binding.Last end
            -- SourceSans provides Roblox's fallback glyph handling, including Thai.
            object.Font=self:Language()=='th' and Enum.Font.SourceSans or binding.Font
            if property=='Text' then
                local translated=binding.Last~=binding.Source
                object.TextWrapped=translated or binding.Wrapped
                object.TextTruncate=translated and Enum.TextTruncate.None or binding.Truncate
            end
        end
        binding.Change=object:GetPropertyChangedSignal(property):Connect(function()
            if object[property]==binding.Last then return end
            binding.Source=object[property];binding.Render()
        end)
        binding.Destroy=object.Destroying:Connect(function()
            binding.Change:Disconnect();binding.Destroy:Disconnect();self.Bindings[id]=nil
        end)
        binding.Render()
    end
    function self:Destroy()
        self.Destroyed=true
        for _,b in pairs(self.Bindings) do b.Change:Disconnect();b.Destroy:Disconnect() end
        self.Bindings={}
    end
    self:Set(selection)
    return self
end
return I18N
