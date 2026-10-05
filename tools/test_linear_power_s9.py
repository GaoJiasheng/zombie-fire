import copy
import json
from pathlib import Path
import unittest
from unittest.mock import patch
import challenge_curve as curve
from report_linear_power_acceptance import g3_verdict

class S9Tests(unittest.TestCase):
    def test_information_points_never_fail(self):
        for ratio in (.85,1.15):
            for wins in range(11):
                self.assertEqual(g3_verdict(ratio,wins)['status'],'INFO')
                self.assertIsNone(g3_verdict(ratio,wins)['contract_pass'])
    def test_single_hard_point(self):
        self.assertEqual(g3_verdict(1.,8)['status'],'FAIL')
        self.assertEqual(g3_verdict(1.,9)['status'],'PASS')
        self.assertEqual(g3_verdict(1.,10)['status'],'PASS')
    def test_new_endpoint_preserves_first_sixty(self):
        data=json.loads((Path(__file__).resolve().parents[1]/'data/challenges.json').read_text())
        changed=copy.deepcopy(data)
        changed['curve']['anchors'][-1]['k']=7.0
        self.assertEqual(curve.validate(changed),[])
        for n in range(1,61): self.assertEqual(curve.rule_for_level(n,data),curve.rule_for_level(n,changed))
    def test_ceiling_eight(self):
        data=json.loads((Path(__file__).resolve().parents[1]/'data/challenges.json').read_text())
        data['curve']['anchors'][-1]['k']=8.1
        self.assertTrue(curve.validate(data))
    def test_finale_contract_cannot_relax(self):
        data=json.loads((Path(__file__).resolve().parents[1]/'data/challenges.json').read_text())
        data['curve']['finale_anchor']['win_rate']=[.6,1.]
        self.assertTrue(curve.validate(data))
    def test_free_finale_incomplete_cannot_pass(self):
        from report_linear_power_s9 import complete_seed_set
        import solve_runtime_clear_lines as t1
        runs=[{'seed':seed,'victory':False} for seed in t1.SEEDS]
        self.assertTrue(complete_seed_set(runs))
        runs[0]['timeout']=True
        self.assertFalse(complete_seed_set(runs))
        runs[0]['timeout']=False
        runs[0]['error']='failed process'
        self.assertFalse(complete_seed_set(runs))
        self.assertFalse(complete_seed_set(runs[1:]))
    def test_timeout_is_not_a_defeat(self):
        import run_linear_power_s9 as s9
        import solve_runtime_clear_lines as t1
        class EvidencePath:
            def __init__(self, payload): self.payload=payload
            def read_text(self): return json.dumps(self.payload)
        class Logs:
            def glob(self, pattern): return [EvidencePath({}) for _ in range(10)]
        build={'weapon':'test'}
        payload={'fixture_sha256':'f','combat_input_fingerprint':'c','challenge':True,
                 'fail_fast':False,'simulation_step_seconds':1/60,'profile':'tier_b',
                 'card_policy':'v2','sweep':{'jobs':6},
                 'runs':[{'level':95,'seed':seed,'build':build,'victory':seed!=2207,
                          'timeout':seed==2207,'base_ratio':.5,'elapsed_seconds':540.0167}
                         for seed in t1.SEEDS]}
        fixture=EvidencePath({'rows':[{'level':95,'build':build}]})
        with patch.object(s9.sweep,'collect_run_provenance',return_value={'fixture_sha256':'f','combat_input_fingerprint':'c'}), \
             patch.object(Path,'read_text',return_value=fixture.read_text()):
            result=s9.validate(EvidencePath(payload),[95],'res://fixture.json',True,Logs())
        self.assertEqual(result['integrity'],'INCOMPLETE')
        self.assertEqual(result['timeouts'],1)
        self.assertIsNone(result['rows'][0]['wins'])
        self.assertIsNone(result['rows'][0]['failed_seeds'])
        self.assertEqual(result['rows'][0]['unfinished_seeds'],[2207])

if __name__=='__main__': unittest.main()
