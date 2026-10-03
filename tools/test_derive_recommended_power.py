#!/usr/bin/env python3
"""Table-B deterministic fit/formula/censor regressions; no probe/data writes."""
import math
import unittest
import derive_recommended_power as table


class TableBTests(unittest.TestCase):
    def test_qr_recovers_known_coefficients(self):
        xs = [[1, n / 11, math.sin(n)] for n in range(1, 31)]
        beta = [2.5, .6, .7]
        result = table.least_squares(xs, [sum(a * b for a, b in zip(x, beta)) for x in xs])
        for a, b in zip(result, beta):
            self.assertAlmostEqual(a, b, places=11)

    def test_rank_deficient_fit_refuses_arbitrary_fallback(self):
        with self.assertRaisesRegex(ValueError, "rank-deficient"):
            table.least_squares([[1, 1]] * 20, [1] * 20)

    def test_formula_uses_measured_passing_endpoint_and_floor(self):
        self.assertEqual(table.recommendation({"status": "complete", "p_star": 100}, 144), 120)
        self.assertEqual(table.recommendation({"status": "complete", "p_star": 60}, 40), 60)
        self.assertEqual(table.recommendation({"status": "lower_bound_passes"}, 26), 50)
        self.assertEqual(table.recommendation({"status": "lower_bound_passes"}, 63.2), 63)

    def test_upper_censor_requires_measured_1_8_endpoint(self):
        with self.assertRaises(ValueError):
            table.recommendation({"status": "upper_bound_fails", "level": 15, "steps": []}, 100)
        row = {"status": "upper_bound_fails", "level": 15, "steps": [{"scale": 1.8, "power": 231}], "extension_method": {"scale_bounds": [1, 1.8]}}
        self.assertEqual(table.recommendation(row, 1000), 231)

    def test_gate_B_clamps_headroom_without_lowering_measured_line(self):
        self.assertEqual(table.recommendation({"status": "complete", "p_star": 606}, 1172.141825), 818)
        self.assertEqual(table.recommendation({"status": "complete", "p_star": 147}, 114), 147)
        self.assertEqual(table.recommendation({"status": "complete", "p_star": 100}, 144), 120)
        self.assertEqual(table.recommendation({"status": "complete", "p_star": 101}, 10000), round(1.35 * 101))

    def test_chapter_design_has_ten_distinct_offsets(self):
        self.assertEqual(len(table.features(99, 1e7, .5)), 12)
        self.assertEqual(table.features(1, 1e7, .5)[3:], [0] * 9)
        self.assertEqual(table.features(11, 1e7, .5)[3:], [1] + [0] * 8)
        self.assertEqual(table.features(99, 1e7, .5)[3:], [0] * 8 + [1])

    def test_csv_line_endings_are_stable_under_text_read(self):
        text = table.csv_text({"rows": [{"level": 1, "recommended_power": 50}]})
        self.assertNotIn("\r", text)
        self.assertEqual(text, "level,recommended_power\n1,50\n")


if __name__ == "__main__":
    unittest.main(verbosity=2)
