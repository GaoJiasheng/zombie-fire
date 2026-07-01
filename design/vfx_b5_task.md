# VFX 批次 B5 — 技能光效(给 Codex)

先读 `design/vfx_overhaul_brief.md` 与 `gameplay/vfx/vfx_lib.gd`(复用 VfxLib、glow 着色器、加法、screen_shake、B4 的 impact helper 也可复用)。本次**只做 B5**。

## 目标
把**技能触发/持续**的视觉做成大厂级:穿透、分裂、连锁电弧、减速力场、护盾屏障、暴击、蓄能/武器强化、升级等。每种技能有清晰的视觉签名。

## 涉及函数(只改视觉)
- `gameplay/projectile/projectile.gd`:`_spawn_pierce_flash`(穿透扫光)
- `gameplay/battle/battle.gd`:`_spawn_split_burst_vfx`(分裂爆发)、`_spawn_chain_flash` / `_spawn_chain_projectiles` 的视觉(连锁电弧)、减速力场表现(skill_slow_field 相关的场/滤镜)、`_spawn_barrier_gain_vfx` / `_spawn_barrier_break_vfx`(护盾获得/破碎)、`_spawn_crit_shot_vfx`(暴击)、`_spawn_weapon_power_ring`(武器强化环)、`_spawn_levelup_vfx`(升级)、`_spawn_radial_vfx`(通用冲击环)

## 视觉签名(要有辨识度)
- 穿透=贯穿扫光带 + 沿途火星;分裂=向外扇形能量爆 + 小光弹;连锁=分叉电弧链 + 节点爆闪;减速=地面冷色力场 + 缓慢粒子 + 轻微画面冷调;护盾=获得时环形能量壳 + 破碎时碎片四散;暴击=金色/强化爆闪 + 放大冲击环 + 短促抖屏;蓄能/强化=武器周围能量聚拢环;升级=向上光柱 + 上升粒子。

## 技术(硬性)
用 VfxLib(spawn_glow/spawn_burst/spawn_particles/spawn_trail/screen_shake)+ 加法 + WorldEnvironment glow + `Tween` + 可用/扩展 `vfx_glow_core.gdshader`(或新增着色器如力场/电弧,放 `gameplay/vfx/shaders/`)。**禁止** PIL 平面几何。

## 硬约束(违反=打回)
- 只改视觉;**不动**技能逻辑/触发条件/数值/`data/*.json`(skills.json 等)/命中判定。
- 不碰形象 PNG;不改渲染方向(aspect 仍 `expand`)。
- 保留 `res://` 引用/ID/命名;粒子/抖屏有上限,受 fx 预算门控。

## 自测(贴输出)+ 不要 commit
```bash
godot --headless --import
godot --headless --script tools/m1_smoke_test.gd    # "M1 smoke test passed"
python3 tools/validate_data.py && python3 tools/check_res_refs.py
```
报告见 brief §6,含 §5 逐条自检。
