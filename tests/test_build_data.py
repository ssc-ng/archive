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

    def test_raw_line_ignores_temporary_copies_of_packages(self):
        ok = ":100644 100644 aaa bbb M\tfmwww.bc.edu/repec/bocode/f/f_able.pkg"
        bad = ":100644 000000 aaa 000 D\tfmwww.bc.edu/repec/bocode/_disabled/_grprod.pkg"
        self.assertEqual(bd.RAW_LINE.match(ok).groups(), ("aaa", "bbb", "f_able"))
        self.assertIsNone(bd.RAW_LINE.match(bad))

    def test_replay_runs_and_changes(self):
        # commits c1..c5; tags on c1, c3, c5 (c2 and c4 are not snapshots)
        order = ["c1", "c2", "c3", "c4", "c5"]
        changes = {
            "c1": [("a", "a1"), ("b", "b1"), ("c", "c1")],
            "c2": [("a", "a2")],                 # a changes (seen at c3)
            "c3": [("b", "")],                   # b removed
            "c4": [("b", "b2"), ("c", "")],      # b returns, c removed
            "c5": [("d", "d1")],
        }
        snaps = {"c1": [D(2024, 1, 1)], "c3": [D(2024, 1, 3)], "c5": [D(2024, 1, 5)]}
        dates, counts, runs, changed = bd.replay(order, changes, snaps)
        self.assertEqual(dates, [D(2024, 1, 1), D(2024, 1, 3), D(2024, 1, 5)])
        self.assertEqual(counts, [3, 2, 3])
        self.assertEqual(runs, {"a": [0, 2], "b": [0, 0, 2, 2], "c": [0, 1], "d": [2, 2]})
        self.assertEqual(changed, {"a": [1]})

    def test_replay_change_that_is_undone_between_snapshots_is_not_a_change(self):
        order = ["c1", "c2", "c3"]
        changes = {"c1": [("a", "a1")], "c2": [("a", "a2")], "c3": [("a", "a1")]}
        snaps = {"c1": [D(2024, 1, 1)], "c3": [D(2024, 1, 3)]}
        _, _, runs, changed = bd.replay(order, changes, snaps)
        self.assertEqual((runs, changed), ({"a": [0, 1]}, {}))

    def test_replay_offline_tag_is_slotted_in_by_date(self):
        order = ["c1", "c2"]
        changes = {"c1": [("a", "a1"), ("b", "b1")], "c2": [("a", "a2")]}
        snaps = {"c1": [D(2024, 1, 1)], "c2": [D(2024, 1, 9)]}
        offline = {D(2024, 1, 5): {"a": "a1", "x": "x1"}}   # a re-made commit
        dates, counts, runs, changed = bd.replay(order, changes, snaps, offline)
        self.assertEqual(dates, [D(2024, 1, 1), D(2024, 1, 5), D(2024, 1, 9)])
        self.assertEqual(counts, [2, 2, 2])
        self.assertEqual(runs, {"a": [0, 2], "b": [0, 0, 2, 2], "x": [1, 1]})   # b is not in the re-made commit
        self.assertEqual(changed, {"a": [2]})

    def test_replay_rejects_tags_out_of_order(self):
        with self.assertRaises(RuntimeError):
            bd.replay(["c1", "c2"], {}, {"c1": [D(2024, 1, 2)], "c2": [D(2024, 1, 1)]})

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


if __name__ == "__main__":
    unittest.main()
