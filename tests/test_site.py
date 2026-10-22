"""Checks on the Jekyll site configuration and, when it has been built,
on the links in the generated HTML and the data files it loads.

The site is deployed to GitHub *project* Pages at https://ssc-ng.net/archive/,
i.e. under a path prefix. Without `baseurl` every theme link points at the
host root and 404s, which renders the site completely unstyled.

Standard library only. The built-output checks are skipped when
site/_site is absent (it is gitignored).
"""
import json
import re
import unittest
from pathlib import Path
from urllib.parse import urlparse

REPO = Path(__file__).resolve().parent.parent
CONFIG = REPO / "site" / "_config.yml"
BUILT = REPO / "site" / "_site"
BASEURL = "/archive"
_TOP_LEVEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):[ \t]*(.*?)[ \t]*$")
_LINK = re.compile(r'(?:href|src)="([^"]*)"')


def read_config():
    values = {}
    for line in CONFIG.read_text(encoding="utf-8").splitlines():
        m = _TOP_LEVEL.match(line)
        if m:
            values[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    return values


class ConfigTest(unittest.TestCase):
    def test_url_is_origin_and_baseurl_is_prefix(self):
        c = read_config()
        self.assertEqual(urlparse(c["url"]).path.rstrip("/"), "")
        self.assertEqual(c["baseurl"], BASEURL)


@unittest.skipUnless(BUILT.is_dir(), "site not built (run jekyll build in site/)")
class BuiltSiteTest(unittest.TestCase):
    def test_root_absolute_links_carry_baseurl(self):
        bad = []
        for page in BUILT.rglob("*.html"):
            for link in _LINK.findall(page.read_text(encoding="utf-8")):
                if link.startswith("/") and not link.startswith("//") \
                        and not link.startswith(BASEURL + "/") and link != BASEURL:
                    bad.append((page.name, link))
        self.assertEqual(bad, [])

    def test_data_files_consistent(self):
        data = BUILT / "assets" / "data"
        manifest = json.loads((data / "manifest.json").read_text())
        self.assertTrue(manifest["snapshots"])
        for date, count in manifest["snapshots"]:
            snap = json.loads((data / "snap" / f"{date}.json").read_text())
            self.assertEqual(snap["d"], date)
            self.assertEqual(len(snap["p"]), count)
            self.assertEqual(snap["p"], sorted(snap["p"]))
        presence = json.loads((data / "presence.json").read_text())
        self.assertEqual(presence["p"], sorted(presence["p"]))
        self.assertEqual(len(presence["p"]), len(presence["r"]))
        self.assertEqual(manifest["snapshots"][-1][0], manifest["latest"])


if __name__ == "__main__":
    unittest.main()
