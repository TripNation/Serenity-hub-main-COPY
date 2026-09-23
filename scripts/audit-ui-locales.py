"""Offline heuristic audit of readable Lua UI fields; never runs game code."""
import argparse
import json
from pathlib import Path
import re
from locale_dictionary import load_dictionary
ROOT = Path(__file__).resolve().parents[1]
TOKEN = re.compile(r'--\[(=*)\[.*?\]\1\]|--[^\n]*|\[(=*)\[.*?\]\2\]|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[A-Za-z_][A-Za-z_0-9]*|\.\.|\S', re.S)
FIELDS = {'Text', 'Title', 'Description', 'Placeholder', 'PlaceholderText', 'Label'}
def audit(source, keys):
    # Ignore generated dictionaries and comments, but preserve newlines for locations.
    source = re.sub(r'-- BEGIN SERENITY LOCALIZATION.*?-- END SERENITY LOCALIZATION', lambda m: '\n'*m[0].count('\n'), source, flags=re.S)
    tokens = [(m[0], m.start()) for m in TOKEN.finditer(source) if not m[0].startswith('--')]
    found = []
    for i in range(len(tokens)-2):
        field, pos = tokens[i]
        if field not in FIELDS or tokens[i+1][0] != '=':
            continue
        value = tokens[i+2][0]
        line = source.count('\n', 0, pos)+1
        if not value.startswith(('"', "'")):
            found.append({'line': line, 'kind': 'dynamic-review', 'field': field})
            continue
        text = value[1:-1]
        if '\\' in text or (i+3 < len(tokens) and tokens[i+3][0] in ('..', ':')):
            found.append({'line': line, 'kind': 'dynamic-review', 'text': text})
        elif text and re.search('[A-Za-z]', text) and text not in keys:
            found.append({'line': line, 'kind': 'missing', 'text': text})
    return found

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('paths', nargs='*', help='Readable Lua files or directories')
    parser.add_argument('--strict', action='store_true', help='Exit 1 if missing literal phrases are found')
    args = parser.parse_args()
    keys = load_dictionary(ROOT/'src/ui/localization/translations.txt')['fil']
    targets = [Path(p) for p in args.paths] or [ROOT/'dist/ui', ROOT/'dist/runtime/games']
    files = set()
    for target in targets:
        if not target.exists():
            parser.error(f'Path does not exist: {target}')
        files.update(target.rglob('*.lua') if target.is_dir() else [target])
    results = []
    for path in sorted(files):
        source = path.read_text(encoding='utf-8')
        if 'Luraph' in source[:2000]:
            results.append({'file': str(path), 'kind': 'unscannable-obfuscated'})
            continue
        results.extend(dict(file=str(path), **item) for item in audit(source, keys))
    print(json.dumps({'files': len(files), 'findings': results, 'limitations': 'Heuristic UI-field scan. Review proper names, option arrays, notification arguments, dynamic text and custom UI separately. No finding is not proof of full coverage.'}, ensure_ascii=False, indent=2))
    return int(args.strict and any(r['kind']=='missing' for r in results))
if __name__ == '__main__':
    raise SystemExit(main())
