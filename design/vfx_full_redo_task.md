# 任务书 — 主动技能 / 子弹开枪受击 / 僵尸攻击动画 全量特效重做(给 Codex)

先读 `AGENTS.md`(黄金规则)与本文件全文再动手。**这是强制返工任务**——本文列出的每一项
现状都已经用实际游戏帧核实过(不是猜测),报告完成前必须逐条自查，不能只做一部分就报告"完成"。

只做视觉/素材；**不碰**任何数值/平衡/技能逻辑/命中判定/`data/*.json` 数值字段/存档逻辑。

---

## 0. 质量基准(已经在本项目里做对的例子——参照这个水准，不是自由发挥)

下面这些是**本项目自己已有的、真正合格**的素材，新做的东西必须达到同一水准：

- `assets/production/sprites/vfx_sequences/vfx_active_sig_frost_glacier/`（冰川领域，真实冰雾粒子）
- `assets/production/sprites/vfx_sequences/vfx_skill_cast_venom/`（剧毒，真实气泡/毒液粒子团）
- `assets/production/sprites/vfx_sequences/vfx_enemy_skill_corrosion/`、`vfx_enemy_skill_storm_chain/`（真实粒子/闪电支链）
- `assets/production/sprites/vfx_sequences/vfx_explosion_fire/`、`vfx_freeze/`、`vfx_muzzle_lightning/`、`vfx_hit_poison/`、`vfx_chain_lightning/`、`vfx_boss_phase/`（命中/枪口/爆炸类，这批之前已验收通过）

**判断标准就是：新做的东西和上面这些放在一起，风格/精细度要一致，不能一眼看出"这几个是认真做的、那几个是随手糊的"。**

## 1. 现状核实(逐条列出，不是笼统印象)

### 1.1 主动技能(`vfx_active_sig_*`，5个)——4个不合格
- ✅ `vfx_active_sig_frost_glacier` 合格，保留不动。
- ❌ `vfx_active_sig_blaze_meltdown` — 同心圆+放射线的"太阳"几何图案，重做。
- ❌ `vfx_active_sig_vanguard_overload` — 扇形放射直线，重做。
- ❌ `vfx_active_sig_vanguard_railvolley` — 扇形放射直线(和 overload 是同一套模板换色)，重做。
- ❌ `vfx_active_sig_volt_storm` — 缠绕线条+同心圆，重做。

### 1.2 技能触发特效(`vfx_skill_cast_*`，16个)——15个不合格
- ✅ `vfx_skill_cast_venom` 合格，保留不动。
- ❌ 其余 15 个（barrier / charge_shot / critical / cryo / gold_rush / homing / incendiary /
  multishot / pierce / recycle / ricochet / salvo / slow_field / split_shot / tesla）
  **几乎是同一套"圆圈+弧线弹夹+放射发光点/线"模板反复换色**——`barrier` 和 `cryo` 和
  `slow_field` 三个视觉上几乎一模一样(同一个圆圈+8条放射短线)，`multishot`/`salvo`/`split_shot`
  三个也几乎一样(同一个扇形+末端光点)，`ricochet`/`tesla` 也几乎一样(同一个抖动折线束)。
  全部重做，且**16个技能之间要能一眼区分**，不能再共用同一个模板换色。

### 1.3 僵尸技能特效(`vfx_enemy_skill_*`，27个)——约17个不合格
- ✅ 合格保留：`corrosion`、`regen`、`regenerate`、`ranged_spit`、`toxic_cloud`(这5个是同一套
  真实绿色粒子团，可以保留同源但建议每个加一点独有细节以便区分)、`storm_chain`(真实闪电支链)。
- ⚠️ 勉强及格但**互相无法区分**，建议重做出差异化：`buff_aura`/`spawn_minions`/`summon`/
  `support_strike`/`multi_phase`/`phase`/`phase_shift` — 这 7 个全是同一个"柔光球+外圈弧线"
  模板换色，玩家完全看不出哪个是召唤、哪个是相位、哪个是增益光环。
- ❌ 必须重做：
  - `armor`/`armor_break`/`shield_aura`/`ward` — 同一个"圆角方框+八角星"模板，4个技能完全
    长一样。
  - `blast`/`enrage`/`explode_on_death`/`phase_burn`/`freeze_field` — 同一个"爆裂射线球"
    模板换色，5个技能完全长一样。
  - `charge`/`juggernaut`/`leap_strike`/`runner_dash` — 同一个"平行发光斜线"模板，4个技能
    完全长一样，且这套"平行斜线"motif 也被直接烧进了僵尸攻击动画帧里(见1.4)。

### 1.4 僵尸攻击动画(`assets/production/sprites/animations/zombies/<id>/<id>_attack_NN.png`)
角色本身的绘画质量是好的(不用重画僵尸本体)，**问题是攻击帧上叠加了粗糙的直线发光"动作线"**
(抽查 `zombie_shambler_attack_02.png` 可见手臂周围有橙色/青色的平直光带)，和上面 1.3 里
"平行发光斜线"是同一种廉价处理。**只清理/替换这些叠加的动作线特效，绝不重画僵尸角色本体、
不改僵尸配色主题、不改帧数/时间轴。**

### 1.5 子弹本体(`assets/production/sprites/projectiles/proj_bullet_<element>.png`，5个)
物理/火/雷 三个共用同一个"胶囊+三角箭头"轮廓只换色；冰是菱形；毒是几个重叠圆点。
全部是简单矢量图形，不是能量弹药的质感。5个全部重做。

### 1.6 命中/枪口/爆炸类(`vfx_muzzle_*`/`vfx_hit_*`/`vfx_explosion_fire`/`vfx_freeze`/`vfx_chain_lightning`/`vfx_poison_cloud`/`vfx_boss_phase`/`vfx_crit`/`vfx_levelup_glow`/`vfx_death_dissolve`/`vfx_threat_warning`/`vfx_target_lock`)
**这批已经验收通过，不在本次任务范围内，不要碰。**

---

## 2. 通用技术规范(硬性，所有新做的都要遵守)

```
STYLE: AAA mobile game VFX, volumetric glowing energy with a crisp bright hot core and soft
outer bloom, high-dynamic-range look, additive-friendly (only the bright effect glows).
TECH: isolated single effect CENTERED on a PURE SOLID BLACK background (#000000, no color in
background at all). NO scene, NO ground, NO characters, NO text, NO numbers, NO UI, NO border.
Square composition, effect fills ~65-75% of frame.
```

- 黑底做完之后用亮度键(luminance→alpha，黑变透明、软边保辉光)转 PNG，不要直接背景纯色/棋盘格。
- 每个特效必须是该机制独有的视觉签名（形状、运动方式、色彩语言三者至少两个不同于其它特效），
  **禁止把同一个模板换个颜色就当新特效交付**——这正是这批被打回的原因。
- 序列帧要有清晰的"起势→高潮→消散"运动弧线，不是一张静态图复制成多帧。
- 不画自己以外的东西：技能触发/主动技特效不画角色，僵尸技能特效不画僵尸本体(僵尸攻击动画的
  清理任务除外——那是在已有僵尸帧上去掉叠加线条，不是重画僵尸)。

## 3. 分类 Prompt 模板(按机制视觉语言分组，逐个替换 {} 里的具体描述)

### 3.1 主动技能(高冲击力、专属角色配色)
```
{STYLE通用规范} A character's ultimate/signature ability activation burst: {具体描述}.
The effect must read as a powerful, deliberate cast — not a passive ambient glow.
Color: {角色专属色}.
```
- `blaze_meltdown`(火/橙红 #FF5722)：a violent eruption of magma and fire cracking outward
  from a central molten core, with rising embers and heat distortion — NOT concentric rings.
- `vanguard_overload`(橙/白钢铁调)：an overcharged mechanical power surge, crackling energy
  arcing along mechanical plating with a blinding white-hot core — reads as "machine pushed
  past its limit", not a radial fan of lines.
- `vanguard_railvolley`(金/白)：a rapid volley of glowing kinetic energy trails converging and
  firing outward in a tight barrage pattern, motion-blurred streaks, NOT a static starburst.
- `volt_storm`(紫/黄电)：a violent localized electrical storm — chaotic branching lightning
  bolts converging into a central vortex with crackling arcs, NOT tidy concentric circles.

### 3.2 技能触发特效(16个，瞬间迸发，每个要有独立形状语言)
基础规范：`{STYLE通用规范} A brief skill-activation flash/burst, reads instantly at a glance.`
逐个具体化(避免共用"圆圈+弧线"模板)：
- `barrier`(护盾获得，青蓝)：an expanding hexagonal energy shell snapping into existence,
  faceted like armor plating, NOT a thin circle outline.
- `critical`(暴击，金)：a sharp radiant starburst with a hard-edged flash core and short bright
  spikes, punchy and instant — NOT a soft circle with orbiting arcs.
- `cryo`/`slow_field`(减速，冰蓝)：frost crystals rapidly growing and interlocking outward from
  the center, NOT identical to barrier's circle-with-ticks look.
- `charge_shot`(蓄能，金橙)：energy coiling inward and compressing into a bright point before
  release, a spiral of converging light, not diverging arcs.
- `gold_rush`(经济，金)：a shower of glowing coin-like glints bursting outward.
- `homing`(追踪，青)：a targeting-lock swirl of light tightening onto a point, distinct from cryo.
- `incendiary`(燃烧弹，橙红)：a compact fireball ignition puff with sparks, not a plain ring.
- `multishot`/`salvo`/`split_shot`(三个都是"多弹道"概念，但要互相区分)：
  multishot = a fan of light trails diverging cleanly; salvo = a rapid staggered burst of
  multiple bright pulses (feels like rapid-fire, not a static fan); split_shot = a single trail
  forking into branches like a lightning split, NOT the same fan-with-dots as the other two.
- `pierce`(穿透，金)：a single piercing lance of light punching straight through, NOT a bar
  floating over a circle.
- `recycle`(资源回收，绿)：a converging spiral of light gathering inward (opposite direction of
  charge_shot's compress, use green/teal to distinguish).
- `ricochet`/`tesla`(两个都不能用"抖动折线束")：ricochet = a bouncing zigzag trail of light
  literally deflecting at angles like a ricocheting projectile; tesla = genuine branching
  lightning bolts (reuse chain_lightning's real-lightning technique, not a jittery line bundle).
- `venom` 已合格不用动。

### 3.3 僵尸技能特效(27个，按下面的家族分别处理)
- **护甲/格挡家族**(`armor`/`armor_break`/`shield_aura`/`ward`，4个必须互相区分)：
  armor = a solid metallic plate flash absorbing a hit; armor_break = that same plate visibly
  cracking and shattering outward; shield_aura = a translucent energy dome shimmering around
  the caster (ambient, not a single flash); ward = a protective rune-like glyph glowing
  briefly around the target. **不能再是同一个方框+八角星。**
- **爆裂/自爆家族**(`blast`/`enrage`/`explode_on_death`/`phase_burn`/`freeze_field`)：
  blast = a sharp shockwave ring; enrage = a rising aggressive red aura flare (ambient, not a
  burst); explode_on_death = a genuine chunky explosion with debris-like particles;
  phase_burn = a burning phase-distortion ripple; freeze_field = an expanding ring of frost
  spikes on the ground (reuse the real vfx_freeze technique, not a cyan starburst).
- **冲锋/位移家族**(`charge`/`juggernaut`/`leap_strike`/`runner_dash`)：**禁止再用平行发光斜
  线**——charge = a forward dust/energy trail kicked up by a heavy charging body;
  juggernaut = heavy ground-shaking impact rings with debris; leap_strike = an arcing motion
  trail with a landing impact flash; runner_dash = a sharp speed-line blur trail that reads as
  fast motion (may use directional streaks, but must look like genuine motion blur/speed lines
  with varying opacity/taper, not four identical straight glowing bars).
- **柔光球家族需要差异化**(`buff_aura`/`spawn_minions`/`summon`/`support_strike`/`multi_phase`/
  `phase`/`phase_shift`)：保留"能量球"基本语言但每个要有独特细节 —— buff_aura 加向上飘的粒子；
  spawn_minions 加分裂出的小光点四散；summon 加从下往上的召唤法阵环；support_strike 加一道
  射向队友方向的光带；multi_phase 加多层色彩交替闪烁；phase 加半透明重影效果；phase_shift 加
  扭曲/残影拖尾。
- **毒/腐蚀家族**(`corrosion`/`regen`/`regenerate`/`ranged_spit`/`toxic_cloud`)已合格，可以
  保留同源但建议加一点点独有细节以便区分（可选，不强制）。
- `storm_chain` 已合格不用动。

### 3.4 子弹本体(`proj_bullet_<element>.png`，5个)
```
{STYLE通用规范} A single flying energy projectile bolt viewed from the side, oriented pointing
right, with a bright hot core and a short streaking motion trail. NOT a simple geometric arrow
or capsule shape — must read as genuine energy ammunition.
```
- physical(白/钢)：a dense kinetic slug with a faint metallic glint trail.
- fire(橙红)：a molten fireball bolt with flickering flame licks trailing behind.
- ice(冰蓝)：a crystalline ice shard bolt with frost mist trailing behind.
- lightning(黄白)：a crackling bolt of electricity with jagged micro-arcs along its trail.
- poison(绿)：a bubbling toxic globule bolt with dripping/trailing acidic mist.

### 3.5 僵尸攻击动画清理
在已有的 `assets/production/sprites/animations/zombies/<id>/<id>_attack_NN.png` 帧上，
**去掉或替换**叠加的直线发光"动作线"特效。可以选择：(a) 直接去掉，让攻击动作只靠僵尸本体的
姿势变化传达；或 (b) 换成更精细的抓挠/挥击痕迹(如爪痕弧线、轻微速度模糊)，但**不能再是平直的
彩色发光条**。**僵尸角色本体的绘画、比例、配色一律不动。**

---

## 4. 分阶段执行(必须先验证再铺开，不要一次性全做完才发现方向不对)

1. **先只做 6 个样本**：`vfx_active_sig_blaze_meltdown`、`vfx_skill_cast_critical`、
   `vfx_skill_cast_barrier`、`vfx_enemy_skill_armor`、`vfx_enemy_skill_runner_dash`、
   `proj_bullet_fire`。每个只需峰值帧(不用先出全套帧数)。
2. 我(Claude)会直接检查这 6 个**实际文件**（不是参考图/contact sheet），确认方向对了、
   且这几个技能之间确实能一眼区分，再放行铺开剩余全部条目。
3. 不要跳过第1步。

## 5. 硬约束(违反 = 打回重做)

- 只改本文列出的素材；**不碰**任何 `.gd`/`.tscn` 逻辑代码、数值、`data/*.json`。
- 第0节列出的"已合格"素材一律不动。
- 僵尸/角色/Boss 的角色本体绘画、配色主题一律不动(只清理僵尸攻击帧上叠加的动作线)。
- **交付物是实际会被游戏加载的帧文件本身**（`vfx_sequences/<id>/<id>_NN.png`、
  `projectiles/proj_bullet_<element>.png`），验收只认这些真实文件，不认
  `source_refs/generated/`或`contact_sheets/`里的参考图/展示图。
- 渲染方向仍是 `aspect=expand`，不要改。

## 6. 自测(贴输出)+ 不要 commit

```bash
godot --headless --import
godot --headless --script tools/m1_smoke_test.gd    # 必须看到 "M1 smoke test passed"，且没有 SCRIPT ERROR
python3 tools/validate_data.py && python3 tools/check_res_refs.py
```

## 7. 报告格式

```
Completed: …
Changed files: …
Verification: <每条自测命令> pass/fail
阶段: 仅完成§4的6个样本 / 已铺开全部条目（说明当前处于哪一步）
逐条自查: 对照§1.1-§1.6 每一条，标注 已重做/保留不动/待做
Risks / blockers: …
```
