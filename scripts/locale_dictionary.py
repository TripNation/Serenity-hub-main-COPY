"""Validated UTF-8 dictionary shared by the builder and offline audit."""
from collections import Counter
from pathlib import Path
import re
LANGUAGES = ('fil', 'id', 'vi', 'th', 'es', 'pt', 'fr', 'de', 'ru')
TOKENS = re.compile(r'%[-+ #0]*\d*(?:\.\d+)?[cdiouxXeEfgGqs]|\{[A-Za-z_][A-Za-z_0-9]*\}')
def placeholders(text):
    return Counter(TOKENS.findall(text.replace('%%', '')))
def load_dictionary(path):
    packs = {language: {} for language in LANGUAGES}
    for number, line in enumerate(Path(path).read_text(encoding='utf-8').splitlines(), 1):
        parts = line.split('|')
        if len(parts) != 10 or any(not part.strip() for part in parts):
            raise ValueError(f'{path}:{number}: expected 10 nonempty columns')
        key = parts[0]
        if any(part != part.strip() for part in parts):
            raise ValueError(f'{path}:{number}: surrounding whitespace')
        if key in packs['fil']:
            raise ValueError(f'{path}:{number}: duplicate key {key!r}')
        for language, value in zip(LANGUAGES, parts[1:]):
            if placeholders(key) != placeholders(value):
                raise ValueError(f'{path}:{number}: placeholder mismatch in {language}: {key!r}')
            packs[language][key] = value
    if not packs['fil']:
        raise ValueError(f'{path}: empty dictionary')
    for pack in packs.values():
        for key in ('Community', 'Updates'):
            if key in pack:
                pack.setdefault(key.upper(), pack[key])
    return packs
