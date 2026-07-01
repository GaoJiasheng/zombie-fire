# VFX 全面升级托管文档(AAA 特效)

> 本文件是**给 Codex 的权威作业单**,也是 **Claude 的验收清单**。Claude 负责扫描/派活/验收/打回;Codex 负责实现;人形/武器/僵尸/Boss 形象**不动**。

## 0. 背景与判断(必须先读懂,否则又会做成几何图形)

- 现状:角色/武器/僵尸/Boss 的**形象插画已是高质量渲染,保留不动**。
- 需要升级的是**游戏内特效(VFX)**:子弹、枪口闪光、命中/爆裂、技能光效、攻击拖尾/线条、屏幕闪光/冲击环等。
- 现有特效是 `tools/generate_*_visuals.py` 用 **PIL(ImageDraw)画的平面几何图形+渐变**,以及 `battle.gd` 里堆的简单 Sprite——这就是"堆叠几何图形"的根源。
- **禁止**继续用 PIL 画平面几何形状当特效。**必须**改用下面第 2 节的"大厂特效技术栈"。

## 1. 目标与验收基调(什么叫"一线大厂标准")

参考对标:《向僵尸开炮》《Archero》等一线竖版射击手游的打击感与光效。核心特征:
- **发光/HDR 泛光**:能量核 + 柔光晕 + bloom,而不是平涂色块。
- **有生命的运动**:粒子(火星、烟、碎屑、能量流)、拖尾、缓动(punchy-in / soft-out),不是静止贴图。
- **元素识别度**:火=热浪扭曲+飞溅火星;冰=结晶碎片+寒霜+冷雾;雷=分叉电弧+爆闪火花;毒=气泡云+滴落+腐蚀;物理=曳光+火星+冲击波。
- **打击反馈**:命中有爆闪+火星四溅+短促屏震/顿帧(已有 hit_stop,复用)。
- **性能**:移动端 60fps;粒子有上限;特效可被现有 `_can_spawn_projectile_fx` 预算门控复用。

## 2. 必须使用的技术栈(这是成败关键)

Codex **必须**用 Godot 引擎能力实现,而不是 PIL 平面图:

1. **WorldEnvironment + Glow(bloom)**:在 battle 场景加一个开启 glow 的 Environment,让所有高亮特效自然发光(这是"大厂光感"的地基)。
2. **GPUParticles2D / CPUParticles2D**:枪口火星、命中飞溅、拖尾、环境浮尘、技能持续场。用 `ParticleProcessMaterial` 配好发射形状/速度/重力/颜色渐变/缩放曲线。
3. **ShaderMaterial(`.gdshader`)**:能量核发光、扭曲(热浪/冲击波)、电弧、溶解、扫描线。放 `assets/production/shaders/` 或 `gameplay/vfx/shaders/`。
4. **加法混合(CanvasItemMaterial blend_mode = ADD)**:所有光效层用加法叠加,产生亮部叠加发光。
5. **拖尾**:`Line2D` 渐隐拖尾或 trail 粒子,替代现在的直线。
6. **缓动 `Tween`**:缩放/透明度/位移用非线性缓动(EASE_OUT/ELASTIC),给"弹一下"的手感。
7. 少量高质量贴图(核/光晕/火星/电弧笔刷)可保留 PIL 生成,但**只作为粒子/着色器的输入纹理**(柔和 radial glow、noise、streak),不是最终平面特效。

## 3. 作业范围(TODO 清单,按优先级)

> 每项 = 一个可独立交付+验收的批次。Codex 一次做 1 个批次,Claude 验收通过再下一个。

- [ ] **B1 战场光感地基**:加 WorldEnvironment(glow/bloom 调好)+ 基础加法混合规范 + 一套可复用的 VFX 工具(`gameplay/vfx/vfx_lib.gd`:spawn_glow/spawn_particles/spawn_trail/screen_shake 封装)。这是后续所有特效的底座。
- [ ] **B2 子弹/投射物**(5 元素 + plasma/rail/scatter/split/heavy/acid):能量核+光晕(shader/加法)+ 元素化拖尾粒子。替换现在的 PIL 箭头/矩形。
- [ ] **B3 枪口闪光 muzzle**(物理/火/冰/雷/毒):爆闪 + 火星粒子 + 短促光锥,配 `_spawn_muzzle_flash`。
- [ ] **B4 命中/爆裂 hit/impact**(5 元素 + 免疫):爆闪 + 元素飞溅粒子 + 冲击波扭曲 shader,配 `_spawn_impact_flash` / `hit_confirmed`。
- [ ] **B5 技能光效**:穿透扫光、分裂爆发、连锁电弧、减速力场、护盾屏障、蓄能弹、暴击、毒云、火焰喷射等(对应 skill_* 与 `_spawn_*_vfx`)。
- [ ] **B6 屏幕级**:屏闪、冲击环、弱点装填、Boss 登场光效——用 shader/粒子重做 `_show_screen_flash`/`_spawn_attack_ring` 等。
- [ ] **B7 攻击"灰线"**:确认那些直线是 `battle.gd` 代码画的还是烘进了 combo 帧;若是代码画的→换拖尾/曳光;若烘进帧→交由图像侧另行处理(不在本单)。

## 4. 硬约束(不许碰 / 必须守)

- **不许改**:角色/武器/僵尸/Boss 的形象 PNG;游戏逻辑与平衡(`core/`、`gameplay/*/*.gd` 的玩法逻辑、`data/*.json` 数值)——那是 Claude 的域。**只加/改视觉表现层**(vfx 节点、shader、粒子、贴图),不动伤害/命中判定/数值。
- **保持**:所有现有 `res://` 引用、ID、文件名、目录规范(`design/data/naming_convention.md`)。新增文件走 `assets/production/`(纹理)/ `gameplay/vfx/`(vfx 代码/场景/shader)。
- **保持**:渲染方向不动——`stretch=canvas_items, aspect=expand`(占满屏,已由 Claude 定),竖屏 `orientation=1`,ETC2 ASTC 开启。**不要改回 keep。**
- **性能**:粒子数/存活时间设上限;复用对象池;尊重 `_can_spawn_projectile_fx` 预算。

## 5. 验收机制(Claude 每批次执行)

Codex 每交付一个批次,Claude 按下面**逐条打分**,任一"否"→**打回重做**并附具体问题:

1. 是否**用了粒子/着色器/加法发光/bloom**,而不是 PIL 平面几何?(否→打回)
2. 是否有**发光核+光晕**的层次感,而不是平涂色块?
3. 元素识别度够不够(火/冰/雷/毒/物理一眼能分)?
4. 运动是否有生命(粒子/拖尾/缓动),不是静止贴图?
5. 打击反馈(命中爆闪+飞溅+顿帧)是否到位?
6. 透明背景正确、尺寸/锚点对、不糊不溢出?
7. 60fps 不掉、粒子有上限?
8. 未触碰形象/逻辑/数值/渲染方向?
9. 冒烟测试通过:`godot --headless --script tools/m1_smoke_test.gd`;数据/引用校验通过。

**验收产出**:Claude 截图/描述实际效果对照本表,给"通过 / 打回(附问题清单)"。

## 6. Codex 每次交付格式

```
批次: Bx
做了什么: (用了哪些粒子/shader/环境,替换了哪些旧 PIL 特效)
新增/改动文件:
自检: 第5节 1-9 逐条 是/否 + 证据(节点树/shader 片段/参数)
截图或运行说明: 如何在编辑器/真机看到效果
风险/遗留:
```

## 7. 流程

1. Claude 扫描现有 VFX 代码与资源 → 细化 B1 的具体接口清单(交给 Codex)。
2. Codex 做 B1 → Claude 验收 → 通过后 B2 …… 逐批推进,不一次性全做。
3. 每通过一批,Claude 负责(按用户标准流程)commit + push,并在需要时打 TestFlight 供真机验收。
