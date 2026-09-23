-- Serenity JTSSP protected compatibility entry
local CORE="https://raw.githubusercontent.com/MUshihara/Serenity-hub/5a3aca8796c55e6e9d2d596bd93b7c6d86da41be/dist/games/jump-to-steal-soccer-players.lua"
local args=table.pack(...)
local src=game:HttpGet(CORE)

local compileMarker="local _0xLppRPSTxJZhsok=loadstring"
local pos=string.find(src,compileMarker,1,true)
if not pos then error("Serenity JTSSP protected core boundary missing",0) end

local injection=[==[
local _0xsrnLoadOld='local _f,_e=loadstring(_s,"@Serenity/JTSSP")'
local _0xsrnLoadNew=[=[local _srnMark='local okUI, UI = runRemote("dist/ui/serenity.lua")'
local _srnPos=string.find(_s,_srnMark,1,true)
if not _srnPos then error("Serenity JTSSP UI scope marker missing",0) end
_s=string.sub(_s,1,_srnPos-1).."local function __srnUIStart()\n"..string.sub(_s,_srnPos).."\nend\nreturn __srnUIStart()"
local _f,_e=loadstring(_s,"@Serenity/JTSSP")]=]
local _0xsrnLoadPos=string.find(_0xjxWDzMOGnvxIVc,_0xsrnLoadOld,1,true)
if not _0xsrnLoadPos then error("Serenity JTSSP final load boundary missing",0) end
_0xjxWDzMOGnvxIVc=string.sub(_0xjxWDzMOGnvxIVc,1,_0xsrnLoadPos-1).._0xsrnLoadNew..string.sub(_0xjxWDzMOGnvxIVc,_0xsrnLoadPos+#_0xsrnLoadOld)
]==]

src=string.sub(src,1,pos-1)..injection..string.sub(src,pos)
local fn,err=loadstring(src,"@Serenity/JTSSP/ProtectedCore")
if not fn then error(err,0) end
return fn(table.unpack(args,1,args.n))
