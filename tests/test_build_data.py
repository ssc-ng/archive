"""Unit tests for the pure functions in site/build_data.py (no network)."""
import datetime as dt
import importlib.util
import unittest
from pathlib import Path

SPEC = importlib.util.spec_from_file_location(
    "build_data", Path(__file__).resolve().parent.parent / "site" / "build_data.py")
bd = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(bd)

D = dt.date


class BuildDataTest(unittest.TestCase):
    def test_package_names_only_pkg_files_in_letter_dirs(self):
        text = "\n".join([
            "fmwww.bc.edu/repec/bocode/f/f_able.pkg",
            "fmwww.bc.edu/repec/bocode/f/f_able.ado",
            "fmwww.bc.edu/repec/bocode/_/_gprod.pkg",
            "fmwww.bc.edu/repec/bocode/stata.toc",
            "fmwww.bc.edu/repec/bocode/f/sub/deep.pkg",
            "fmwww.bc.edu/repec/bocode/a/a2reg.pkg",
        ])
        self.assertEqual(bd.package_names(text), ["_gprod", "a2reg", "f_able"])

    def test_contiguous_ranges(self):
        tags = [D(2021, 12, 21), D(2021, 12, 23), D(2021, 12, 24), D(2021, 12, 26)]
        self.assertEqual(bd.contiguous_ranges(tags), [
            ["2021-12-21", "2021-12-21", 1],
            ["2021-12-23", "2021-12-24", 2],
            ["2021-12-26", "2021-12-26", 1]])

    def test_select_snapshots(self):
        start = bd.FILELIST_START
        tags = [D(2017, 8, 10), start, start + dt.timedelta(1),
                D(2023, 12, 2), D(2023, 12, 3), D(2024, 1, 1), D(2024, 1, 9)]
        self.assertEqual(bd.select_snapshots(tags),
                         [start, D(2023, 12, 2), D(2024, 1, 1), D(2024, 1, 9)])

    def test_runs(self):
        self.assertEqual(bd.runs([0, 1, 2, 5, 7, 8]), [0, 2, 5, 5, 7, 8])
        self.assertEqual(bd.runs([]), [])


if __name__ == "__main__":
    unittest.main()
