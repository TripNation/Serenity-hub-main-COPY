"""Offline regression tests; run with python scripts/test-ui-locales.py."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from locale_dictionary import load_dictionary
spec=importlib.util.spec_from_file_location('audit',Path(__file__).with_name('audit-ui-locales.py'))
audit=importlib.util.module_from_spec(spec);spec.loader.exec_module(audit)
class Checks(unittest.TestCase):
    def validate(self, text):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'translations.txt';p.write_text(text,encoding='utf-8');return load_dictionary(p)
    def test_reject_bad_rows(self):
        row='|'.join(['Hello']*10)
        for text in [row+'\n'+row, '|'.join(['Hello']*9), '|'.join(['Hello']*9+['']), '|'.join(['Count {n}']+['Count']*9)]:
            with self.assertRaises(ValueError):self.validate(text)
    def test_valid_placeholders(self):
        self.validate('|'.join(['Count {n} %d']*10))
    def test_scan(self):
        result=audit.audit('-- Text="Ignore"\nlocal x={Title="Known",Text="Missing",Id="Keep",Description="Count: "..n}\nlocal s="Title=oops"',{'Known'})
        self.assertEqual([r['kind'] for r in result],['missing','dynamic-review'])
        self.assertEqual(result[0]['line'],2)
    def test_dictionary(self):
        packs=load_dictionary(Path(__file__).resolve().parents[1]/'src/ui/localization/translations.txt')
        self.assertEqual(len(packs),9)
        self.assertTrue(all(set(p)==set(packs['fil']) for p in packs.values()))
if __name__=='__main__':unittest.main()
