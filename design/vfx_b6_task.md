# VFX 批次 B6 — 屏幕级/环境级(给 Codex)

先读 design/vfx_overhaul_brief.md 与 gameplay/vfx/vfx_lib.gd(复用 VfxLib、glow 着色器、加法、screen_shake、B4/B5 的 helper)。本次只做 B6,是收尾批。

## 目标
把屏幕级/大范围表现做成大厂级:屏幕闪光、冲击环、Boss 登场、敌人攻击预警、破防等。

## 涉及函数(只改视觉)gameplay/battle/battle.gd
- _show_screen_flash(屏闪→用柔和渐变+加法,不要生硬色块)
- _spawn_attack_ring / _spawn_radial_vfx(冲击环→着色器扩散环/加法)
- _show_boss_banner / _spawn_attack_telegraph(Boss 登场光效 + 攻击预警地标)
- _spawn_enemy_entry_vfx(敌人入场)、_spawn_boss_attack_vfx / _spawn_enemy_attack_vfx / _spawn_breach_attack_vfx(敌人攻击/破防)、_spawn_spit_attack_vfx
- _spawn_weapon_power_ring(武器强化环,若未在别批处理)

## 技术(硬性)
VfxLib(spawn_glow/spawn_burst/spawn_particles/screen_shake)+ 加法 + WorldEnvironment glow + Tween + 可扩展着色器(扩散环/冲击波,放 gameplay/vfx/shaders/)。禁止 PIL 平面几何。屏闪要克制(别刺眼)。

## 硬约束(违反=打回)
- 只改视觉;不动敌人攻击逻辑/伤害/破防判定/数值/data。不碰形象 PNG;不改渲染方向(aspect 仍 expand)。
- 保留 res:// 引用/ID/命名;粒子/抖屏有上限受预算门控;屏闪频率克制避免癫痫风险。

## 自测(贴输出)+ 不要 commit
godot --headless --import ; godot --headless --script tools/m1_smoke_test.gd(需 "M1 smoke test passed"); python3 tools/validate_data.py && python3 tools/check_res_refs.py
报告见 brief §6,含 §5 逐条自检。
