import unittest
from unittest.mock import patch
import check_linear_power_s91_runtime as gate
import run_frontline_sweep as sweep
import test_frontline_sweep_metadata as metadata


class S91Tests(unittest.TestCase):
    def runs(self):
        return [dict(seed=s,victory=True,elapsed_seconds=100.,base_ratio=.5,boss_phase_seconds=50.) for s in gate.t1.SEEDS]
    def test_720_nonclear_recount(self):
        rs=self.runs();rs[0].update(victory=False,timeout=True,logic_limit_seconds=720.,elapsed_seconds=720.0167)
        result=gate.recount(rs)
        self.assertEqual(result['wins'],9)
        self.assertEqual(result['horizon_nonclear_seeds'],[1103])
    def test_540_unfinished_not_reused(self):
        rs=self.runs();rs[0].update(victory=False,timeout=True,logic_limit_seconds=540.,elapsed_seconds=540.0167)
        with self.assertRaises(AssertionError):gate.recount(rs)
    def test_process_timeout_not_combat_loss(self):
        rs=self.runs();rs[0]['probe_status']='process_timeout'
        with self.assertRaises(AssertionError):gate.recount(rs)
    def test_missing_seed_not_a_band(self):
        with self.assertRaises(AssertionError):gate.recount(self.runs()[:-1])
    def test_completed_old_horizon_can_reuse(self):
        self.assertEqual(gate.recount(self.runs())['wins'],10)
    def test_logic_metadata_default_and_signed(self):
        options=metadata.sample_options()
        self.assertEqual(sweep.build_payload(options,[],0,[],{})['logic_limit_seconds'],540.)
        options.logic_limit=720.
        self.assertEqual(sweep.build_payload(options,[],0,[],{})['logic_limit_seconds'],720.)


if __name__=='__main__':unittest.main()
