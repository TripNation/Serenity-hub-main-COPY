from pathlib import Path
import json
repo=Path(__file__).resolve().parents[1]
root=repo/'src/ui/localization'
q=lambda s:json.dumps(s,ensure_ascii=False)
from locale_dictionary import load_dictionary
packs=load_dictionary(root/'translations.txt')
core=(root/'i18n-core.lua').read_text(encoding='utf-8')
table='I18N.Packs={\n'+''.join('['+q(l)+']={\n'+''.join('['+q(k)+']='+q(v)+',\n' for k,v in p.items())+'},\n' for l,p in packs.items())+'}\n'
module=core.replace('return I18N\n',table+'return I18N\n')

for name in ['phonk-v3-1-0','universal-v3-2-0']:
    path=repo/'dist/ui'/(name+'.lua')
    source=path.read_text(encoding='utf-8')
    begin='-- BEGIN SERENITY LOCALIZATION'
    end='-- END SERENITY LOCALIZATION'
    assert source.count(begin)==source.count(end)==1
    prefix,tail=source.split(begin)
    _,suffix=tail.split(end)
    path.write_text(prefix+begin+'\n-- Bundled translations: English default, no translation network requests.\nM.I18N=(function()\n'+module+'\nend)()\n'+end+suffix,encoding='utf-8')
print('Updated both shared UI translation bundles.')

