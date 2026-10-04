#!/usr/bin/env python3
"""Offline tests: envelope contract and candidate isolation, no game writes."""
import copy
import json
import math
import unittest
from pathlib import Path

import audit_campaign_frontline as campaign
import progression_closure as closure
import derive_resource_curves as resource
import power_ruler_model as ruler
import check_resource_curve_candidate as checker
from power_scale_v6 import PowerScaleV6
from solve_runtime_clear_lines import input_hashes


class ResourceTests(unittest.TestCase):
    def constant_vector(self, specs, value):
        return [0 if s['name'].endswith('.log_slope') else value for s in specs]

    def test_knots_keep_five_tiers_and_zero_vector_identity(self):
        base = copy.deepcopy(campaign.TABLES)
        specs = resource.parameters(base, {'skill_base_xp_costs':-1, 'sig_skill_xp_costs':1})
        self.assertEqual(len(specs),23)
        tables, changes, _ = resource.candidate(base,specs,[0]*len(specs))
        self.assertEqual(tables,base)
        self.assertEqual(changes,[])

    def test_rejects_reversed_rewards_and_wrong_vector_family(self):
        base = copy.deepcopy(campaign.TABLES)
        specs = resource.parameters(base)
        values = [0]*len(specs)
        values[3] = .4  # Increasing factor reverses authored plateau/decline.
        with self.assertRaises(ValueError):
            resource.candidate(base,specs,values)
        with self.assertRaises(ValueError):
            resource.candidate(base,specs,values[:-1])

    def replay_payload(self):
        baseline = closure.generate(include_recovery=False)
        return {'game_data_written': False, 'frozen_input_sha256': input_hashes(),
                'changes': [], 'curves': [], 'before': baseline, 'after': baseline}

    def test_exact_candidate_replay(self):
        payload = self.replay_payload()
        self.assertEqual(checker.replay(payload), payload['after'])

    def test_replay_rejects_stale_or_enemy_changes(self):
        payload = self.replay_payload()
        payload['frozen_input_sha256'] = {}
        with self.assertRaises(AssertionError):
            checker.replay(payload)
        payload['frozen_input_sha256'] = input_hashes()
        payload['changes'] = [{'file': 'data/levels.json', 'pointer': '/0/difficulty_coef',
                               'old': 1, 'new': 2}]
        with self.assertRaises(AssertionError):
            checker.replay(payload)

    def test_monotone_envelope_is_a_valid_witness(self):
        envelopes = closure.g1_envelopes(campaign.TABLES['levels'])
        previous = 65
        for level in campaign.TABLES['levels']:
            n = resource.campaign.sim.level_number(level)
            envelope = envelopes[n]
            lower, upper = closure.g1_bounds(level, True, envelope)
            rec = level['clear_requirement']['power_contract']['recommended_power']
            self.assertGreaterEqual(envelope, previous)
            self.assertGreaterEqual(envelope / rec, lower)
            self.assertLessEqual(envelope / rec, upper)
            previous = envelope

    def test_chapter_start_high_truthful_R_is_not_automatically_failed(self):
        level = campaign.TABLES['levels'][6]
        lower, upper = closure.g1_bounds(level, True, 76)
        self.assertGreater(upper, 1.1)
        self.assertLessEqual(76 / 53, upper)
        self.assertEqual(lower, 1)

    def test_factor_curves_are_positive_monotone(self):
        for slope in (-3, 0, 3):
            values = resource.smooth_factors(99, .5, slope)
            self.assertTrue(all(x > 0 for x in values))
            self.assertAlmostEqual(values[0], math.exp(.5))
            self.assertAlmostEqual(values[-1], math.exp(.5+slope))
            self.assertTrue(all((b-a)*slope >= -1e-12 for a,b in zip(values, values[1:])))

    def test_zero_vector_reproduces_original_data(self):
        base = copy.deepcopy(campaign.TABLES)
        specs = resource.parameters(base)
        tables, changes, _ = resource.candidate(base, specs, [0]*len(specs))
        self.assertEqual(tables, base)
        self.assertEqual(changes, [])

    def test_candidate_changes_only_authorized_resource_fields(self):
        base = copy.deepcopy(campaign.TABLES)
        specs = resource.parameters(base)
        tables, changes, _ = resource.candidate(base, specs, self.constant_vector(specs,.4))
        self.assertEqual(base, campaign.TABLES)
        for table in ('zombies','bosses','characters','skills'):
            self.assertEqual(tables[table], base[table])
        self.assertEqual(tables['economy']['power_scale_v6'],base['economy']['power_scale_v6'])
        self.assertEqual(tables['economy']['card_offer_pacing'],base['economy']['card_offer_pacing'])
        for table in ('weapons','armors','chips','pets'):
            for key, old in base[table].items():
                if old.get('premium_set') or old.get('premium_entitlement'):
                    self.assertEqual(tables[table][key], old)
        for change in changes:
            self.assertTrue(change['pointer'].endswith(('/gold','/reward_gold_mult','/unlock_cost_star','/cost_base_gold')) or
                            change['pointer'].startswith(('/skill_base_xp_costs/','/sig_skill_xp_costs/')))

    def test_candidate_context_restores_tables_and_frozen_ruler(self):
        original_tables = campaign.TABLES
        original_cache = getattr(ruler, '_POWER_SCALE_V6_CACHE', None)
        model = PowerScaleV6.build_from_fixture()
        ruler._POWER_SCALE_V6_CACHE = model
        frozen = input_hashes()
        tables = copy.deepcopy(original_tables)
        tables['economy']['skill_base_xp_costs'] = [10000]*5
        try:
            with closure.candidate_tables(tables):
                self.assertIs(ruler._POWER_SCALE_V6_CACHE.curves, model.curves)
                payload = closure.generate(include_recovery=False)
                self.assertEqual(len(payload['rows']),99)
            self.assertIs(campaign.TABLES, original_tables)
            self.assertIs(ruler._POWER_SCALE_V6_CACHE, model)
            self.assertEqual(frozen,input_hashes())
        finally:
            ruler._POWER_SCALE_V6_CACHE = original_cache

    def test_exact_cache_matches_uncached_resource_simulation(self):
        original_cache = getattr(ruler, '_POWER_SCALE_V6_CACHE', None)
        base = copy.deepcopy(campaign.TABLES)
        specs = resource.parameters(base)
        tables, _, _ = resource.candidate(base, specs, self.constant_vector(specs,.2))
        try:
            ruler._POWER_SCALE_V6_CACHE = PowerScaleV6.build_from_fixture()
            with closure.candidate_tables(tables):
                uncached = closure.generate(include_recovery=False)
            resource.Search(base, specs, Path('/tmp/zf_linear_cache_test_not_written_2026_10_04.json'))
            with closure.candidate_tables(tables):
                cached = closure.generate(include_recovery=False)
            self.assertEqual(cached, uncached)
        finally:
            ruler._POWER_SCALE_V6_CACHE = original_cache


if __name__=='__main__':
    unittest.main(verbosity=2)
