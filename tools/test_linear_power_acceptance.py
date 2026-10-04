#!/usr/bin/env python3
"""Offline audit-fixture tests; does not start native probes."""
import unittest
import prepare_linear_power_acceptance as accept
import solve_runtime_clear_lines as t1


class AcceptanceTests(unittest.TestCase):
    def test_target_uses_pass_side_not_nearest_below(self):
        candidates = [{'power': 80}, {'power': 105}, {'power': 120}]
        self.assertEqual(accept.select_target(candidates, 100), (candidates[1], candidates[0]))
        self.assertEqual(accept.select_target(candidates, 80), (candidates[0], None))
        with self.assertRaises(ValueError):
            accept.select_target(candidates, 121)

    def test_enumeration_covers_caps_and_obeys_t1_scaling(self):
        tables = t1.load_tables()
        reference = {'character': 'vanguard', 'character_level': 4,
                     'weapon': 'weapon_autocannon', 'weapon_level': 6,
                     'armor': '', 'armor_level': 1, 'chip': '', 'chip_level': 1,
                     'pet': '', 'pet_level': 1, 'signature_level': 1,
                     'skill_base_levels': {'skill_multishot': 1}}
        candidates = accept.ray_candidates(reference, tables['levels'][4], tables)
        self.assertEqual(candidates[-1]['build']['weapon_level'], 50)
        self.assertEqual(candidates[-1]['build']['signature_level'], 5)
        self.assertEqual(candidates[-1]['build']['skill_base_levels']['skill_multishot'], 5)
        self.assertTrue(all(r['build'] == t1.scaled_build(reference, r['scale'], tables) for r in candidates))
        self.assertTrue(all(r['build']['armor'] == '' and r['build']['armor_level'] == 1 for r in candidates))


if __name__ == '__main__':
    unittest.main()
