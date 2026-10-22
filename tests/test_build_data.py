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
    def test_parse_tree_only_pkg_files_in_letter_dirs(self):
        text = "\n".join([
            "100644 blob aaa111\tfmwww.bc.edu/repec/bocode/f/f_able.pkg",
            "100644 blob bbb222\tfmwww.bc.edu/repec/bocode/f/f_able.ado",
            "100644 blob ccc333\tfmwww.bc.edu/repec/bocode/_/_gprod.pkg",
            "100644 blob ddd444\tfmwww.bc.edu/repec/bocode/stata.toc",
            "100644 blob eee555\tfmwww.bc.edu/repec/bocode/f/sub/deep.pkg",
            "100644 blob fff666\tfmwww.bc.edu/repec/bocode/a/a2reg.pkg",
        ])
        self.assertEqual(bd.parse_tree(text),
                         {"f_able": "aaa111", "_gprod": "ccc333", "a2reg": "fff666"})

    def test_contiguous_ranges(self):
        tags = [D(2021, 12, 21), D(2021, 12, 23), D(2021, 12, 24), D(2021, 12, 26)]
        self.assertEqual(bd.contiguous_ranges(tags), [
            ["2021-12-21", "2021-12-21", 1],
            ["2021-12-23", "2021-12-24", 2],
            ["2021-12-26", "2021-12-26", 1]])

    def test_select_snapshots(self):
        tags = [D(2017, 8, 10), D(2021, 4, 15), D(2021, 12, 21), D(2021, 12, 23),
                D(2022, 1, 1), D(2022, 1, 2), D(2022, 2, 3), D(2022, 2, 9)]
        self.assertEqual(bd.select_snapshots(tags), [
            D(2017, 8, 10), D(2021, 4, 15), D(2021, 12, 21),
            D(2022, 1, 1), D(2022, 2, 3), D(2022, 2, 9)])

    def test_errata_gaps_and_reasons(self):
        errata = bd.errata_gaps("\n".join([
            "| Start date | End date   | Reason |",
            "|------------|------------|--------|",
            "| 2021-12-22 | 2021-12-22 | Mirror workflow not automated |",
            "| 2026-03-08 | 2026-03-10 | The mirror workflow failed. |",
        ]))
        ranges = [["2017-08-10", "2017-08-10", 1], ["2021-12-21", "2021-12-21", 1],
                  ["2021-12-23", "2024-08-10", 962], ["2024-08-12", "2026-03-07", 573],
                  ["2026-03-11", "2026-10-21", 225]]
        gaps = bd.gaps_between(ranges, errata)
        self.assertEqual([g[:3] for g in gaps], [
            ["2017-08-11", "2021-12-20", 1593], ["2021-12-22", "2021-12-22", 1],
            ["2024-08-11", "2024-08-11", 1], ["2026-03-08", "2026-03-10", 3]])
        self.assertEqual(gaps[0][3], bd.EARLY_REASON)
        self.assertEqual(gaps[1][3], "Mirror workflow not automated")
        self.assertEqual(gaps[2][3], bd.NO_REASON)
        self.assertEqual(gaps[3][3], "The mirror workflow failed")

    def test_runs(self):
        self.assertEqual(bd.runs([0, 1, 2, 5, 7, 8]), [0, 2, 5, 5, 7, 8])
        self.assertEqual(bd.runs([]), [])


if __name__ == "__main__":
    unittest.main()
