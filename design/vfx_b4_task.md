# VFX 批次 B4 — 命中/爆裂/死亡(给 Codex)

先读 `design/vfx_overhaul_brief.md` 与 `gameplay/vfx/vfx_lib.gd`(复用 VfxLib、glow 着色器、加法、screen_shake)。本次**只做 B4**。这是打击感最关键的一批。

## 目标
命中瞬间要有**大厂打击感**:爆闪 + 元素飞溅粒子 + 冲击波(可用扭曲着色器)+ 短促屏震/顿帧(复用现有 hit_stop / VfxLib.screen_shake),元素可辨。

## 涉及函数(只改视觉)
- `gameplay/projectile/projectile.gd`:`_spawn_impact_flash`(命中爆闪)
- `gameplay/battle/battle.gd`:`_spawn_element_impact_vfx`、`_spawn_hit_layer_vfx`、`_spawn_rail_impact_vfx`、`_spawn_scatter_impact_vfx`、`_spawn_plasma_impact_vfx`、`_spawn_chain_flash`、`_spawn_radial_vfx`、`_spawn_death_element_vfx`(死亡爆裂)

## 元素识别 + 打击反馈
- physical=白闪+金属火星四溅+小冲击环;fire=橙红爆燃+火花+短暂灼烧余光;ice=青蓝碎裂+霜晶飞溅+短暂冰冻定格;lightning=白蓝爆闪+分叉余电+火花;poison=毒绿飞溅+腐蚀气泡云。
- 命中/暴击/击杀配合 `VfxLib.screen_shake` 与现有 `hit_stop` 给顿挫感(强度按伤害/是否暴击/是否 Boss 分级,别过度)。

## 硬约束(违反=打回)
- 只改视觉;**不动**命中判定、伤害结算、`take_damage`、数值、`data/*.json`。
- 不碰形象 PNG;不改渲染方向(aspect 仍 `expand`)。
- 用 VfxLib+粒子+着色器+加法+glow,**禁止** PIL 平面几何。
- 保留 `res://` 引用/ID/命名;粒子/顿帧有上限,受现有 fx 预算门控;避免高频命中时粒子爆炸卡顿。

## 自测(贴输出)+ 不要 commit
```bash
godot --headless --import
godot --headless --script tools/m1_smoke_test.gd    # "M1 smoke test passed"
python3 tools/validate_data.py && python3 tools/check_res_refs.py
```
报告见 brief §6,含 §5 逐条自检(尤其第 5 条打击反馈)。
