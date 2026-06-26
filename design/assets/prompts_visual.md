# 视觉素材生成 Prompt（GPT / DALL·E 等图像模型）

> 用法：**每条 prompt 前都拼上 §1 的「风格前缀」**，再拼该素材的「具体描述」。
> 动态单位（角色/僵尸/Boss/宝宝）按 §2「分件出图法」分别出件。Prompt 用英文（图像模型对英文更稳），中文注释仅供理解。
> 所有产出必须通过 `11_art_bible.md §9` 验收清单。

---

## 1. 风格前缀（STYLE PREAMBLE，所有 prompt 通用）

```
STYLE: stylized semi-realistic 2.5D mobile game art, looks like a 3D render but as a clean 2D sprite,
bold readable silhouette, soft global illumination with a key light from the upper-right and subtle rim light,
post-apocalyptic but vivid and saturated palette, slight grime/rust/wear detail, high readability for a tower-defense shooter.
TECH: transparent background (PNG), single subject centered, no ground shadow baked in, no text, no UI, no border,
consistent art style across the whole set.
```

## 2. 分件出图法（动态单位必用）

动态单位**不要出整图**。先出一张"姿态参考整图"对齐比例，再逐件出**透明背景分件**：

1. 先生成参考：`<STYLE> + <角色具体描述> + "full body, neutral T-pose-ish standing pose, 3/4 top-down side view facing upward"` → 存为 `{prefix}_portrait.png`。
2. 再逐件出：在描述后追加部位指令，背景透明、关节处留重叠余量：
   ```
   "ONLY the {part} of this character, isolated, transparent background, slight overlap margin at joints for rigging"
   ```
   部位：`head / body(torso+hip) / arm_l / arm_r / hand_l / hand_r / leg_l / leg_r / weapon`。
3. 引擎里骨骼绑定做 idle/walk/attack/hurt/death。

> 若图像模型分件一致性不足，可改为：出"完整角色 + 干净分层"，再人工/工具切件。Prompt 仍以本文为准。

---

## 3. 角色（4）

> 视角统一：3/4 顶视侧角、面向上方（朝战场）。先出 portrait，再分件。

- **char_vanguard 钢铁先锋**
  ```
  <STYLE> A veteran human artillery commander, brawny strongman build, weathered military exo-armor in steel-grey with
  warning-orange accents (#FF7A3D), reinforced shoulder pads, calm determined face, short cropped hair,
  carrying a heavy modular cannon. Physical/balanced fighter vibe. Color accent steel white #D9DEE5.
  ```
- **char_blaze 烈焰技师**
  ```
  <STYLE> A youthful pretty-boy fire engineer, slim and clean-faced, light-to-medium heat-resistant armor with
  glowing orange-red (#FF5722) seams, compact fuel canister, goggles pushed up, confident bright grin,
  fast gadget-user posture. Fire theme, but not a bulky armored man.
  ```
- **char_frost 寒霜术士**
  ```
  <STYLE> A tall aloof mature female cryo-specialist, elegant sharp silhouette, sleek white-and-ice-blue (#46C6FF)
  armored coat and fitted tech suit, calm cold expression, long clean lines, frost-coated gauntlet. Ice theme,
  high-cold queenly presence, not a bulky armored man.
  ```
- **char_volt 电能游侠**
  ```
  <STYLE> A petite energetic young female electro-runner, cute but combat-capable, light armor over dark bodysuit
  with glowing purple-yellow (#C77DFF/#FFE14D) energy lines, compact backpack tesla coils, twin-tail or short lively hair,
  playful focused eyes. Lightning theme, small agile silhouette, not a bulky armored man.
  ```

每个角色再出 8 专属技图标（512×512，方形，无背景或深色圆底）：
```
<STYLE> Square ability icon, centered emblem, glossy, glowing element-colored core, no text.
e.g. sig_blaze_napalm: a napalm canister bursting into a pool of fire, orange-red glow.
```

---

## 4. 普通僵尸（20）

> 统一：病态青绿皮肤基调 (#7E9B6E)、3/4 顶视面向上方、剪影清晰、可读。先 portrait 再分件。

- `zombie_shambler` 蹒跚者：`<STYLE> a basic decayed zombie, ragged civilian clothes, slow hunched posture, sickly green skin, simple and generic, weakest grunt.`
- `zombie_runner` 奔跑者：`<STYLE> a lean fast zombie, torn athletic clothes, sprinting forward aggressively, thin limbs, eyes glowing faintly.`
- `zombie_brute` 壮汉：`<STYLE> a massive muscular tank zombie, bloated heavy body, thick arms, slow and tough, torn worker overalls, intimidating bulk.`
- `zombie_spitter` 喷吐者：`<STYLE> a bloated zombie with a swollen acid sac throat and gaping mouth, dripping green acid, ranged spitter look.`
- `zombie_crawler` 爬行者：`<STYLE> a small low crawling zombie, half-body dragging, fast and creepy, tiny silhouette, swarm unit.`
- `zombie_armored` 装甲僵尸：`<STYLE> a zombie clad in scavenged metal plate armor and helmet, bullet-dented, lightning-weak metal theme.`
- `zombie_bomber` 自爆者：`<STYLE> a zombie strapped with crude explosives and glowing red detonator, swollen unstable body, about to blow up.`
- `zombie_shielder` 持盾者：`<STYLE> a zombie carrying a large makeshift riot shield in front, bullets denting it, slow advancing wall.`
- `zombie_hopper` 跳跃者：`<STYLE> a zombie with grotesquely overgrown powerful legs, crouched ready to leap, agile mutant.`
- `zombie_screamer` 尖啸者：`<STYLE> a zombie with a huge distended screaming mouth and bulging throat, sonic shriek pose, buffs allies.`
- `zombie_juggernaut` 重装兵：`<STYLE> a gigantic armored juggernaut zombie, layered metal plating over enormous bulk, slow unstoppable, poison-weak.`
- `zombie_phantom` 幽影：`<STYLE> a semi-transparent ghostly zombie, phasing/translucent body with faint glow, eerie intangible look.`
- `zombie_necromancer` 死灵法师：`<STYLE> a robed zombie sorcerer holding a glowing necrotic staff, dark hood, summoning aura, high-priority target look.`
- `zombie_toxic` 剧毒体：`<STYLE> a bloated toxic zombie oozing and dripping green poison, leaving toxic puddles, hazmat-corrosion theme.`
- `zombie_charger` 冲锋兵：`<STYLE> a forward-leaning charging zombie, bull-like posture, building momentum, armored shoulder for ramming.`
- `zombie_regenerator` 再生体：`<STYLE> a zombie with visibly regenerating glistening flesh and pulsing tumorous growths, healing theme, fire-weak.`
- `zombie_splitter` 分裂体：`<STYLE> a gelatinous zombie that looks like it could split apart, segmented blob-like body, mitosis vibe.`
- `zombie_warden` 守卫：`<STYLE> a zombie projecting a protective energy shield aura around itself, totem-like, buffs/shields allies.`
- `zombie_mutant` 变异体：`<STYLE> a chaotic mutated zombie with shifting iridescent color-changing skin, unstable adaptive biology.`
- `zombie_berserker` 狂暴体：`<STYLE> a frenzied enraged zombie, veins bulging red, aggressive feral posture, speeds up when hurt.`

精英版不另出图（引擎加发光描边）。

---

## 5. Boss（8）

> Boss 更大更威压；多 phase 的 Boss 可加 `_phase2` 变体件。先 portrait 再分件，外加登场视频（见 §9）。

- `boss_tank_titan` 钢铁泰坦：`<STYLE> a colossal armored zombie titan, immune to physical, massive riveted steel plating, glowing weak points, summons armored minions, lightning-weak energy seams.`
- `boss_inferno_maw` 炼狱巨口：`<STYLE> a hulking fire-immune zombie with a gaping furnace maw breathing flame, molten cracks across charred body, orange-red glow, ice-weak.`
- `boss_frost_warden` 冰封领主：`<STYLE> a towering ice-immune zombie lord encased in jagged ice armor, radiating freezing mist, fire-weak glowing core.`
- `boss_storm_caller` 雷暴使徒：`<STYLE> a lightning-immune zombie apostle crackling with purple-yellow electricity, tesla-coil spine, summons leaping minions, poison-weak.`
- `boss_plague_mother` 瘟疫之母：`<STYLE> a grotesque bloated poison-immune zombie matriarch birthing small zombies, dripping toxic green, surrounded by spore clouds, lightning-weak.`
- `boss_void_phantom` 虚空幽帝：`<STYLE> an eerie all-element-immune phantom overlord, semi-intangible void-purple body phasing in and out, only physical can hurt it, ghostly regal silhouette.`
- `boss_necrotitan` 死灵泰坦：`<STYLE> a giant regenerating necrotic titan, pulsing healing flesh and bone spires, raising dead minions, fire-weak glowing rot.`
- `boss_apex_overlord` 终焉霸主：`<STYLE> the final multi-phase apex zombie overlord, immense and terrifying, cycling elemental auras (fire/ice/lightning/poison shifting), regal crown of bone, ultimate end-boss presence.`

---

## 6. 主炮 / 炮塔（8）

- 图标（512×512 方形深底）：`<STYLE> square weapon icon, a {desc} cannon, glossy, element-colored glow, 3/4 view, no text.`
- 炮塔战斗图（分件 320×320，底部中央，朝上）：`<STYLE> a bottom-mounted defense turret cannon, {desc}, facing upward, mechanical detail, ready to rig (barrel/base/mount separable).`

| ID | desc |
|---|---|
| weapon_autocannon | rapid-fire steel autocannon, physical, balanced starter |
| weapon_railgun | sleek heavy railgun with charge rails, physical, piercing |
| weapon_scattergun | wide-barrel scatter shotgun cannon, physical spread |
| weapon_flamethrower | flamethrower nozzle with fuel tanks, orange-red fire |
| weapon_cryocannon | frost cannon venting cold mist, ice-blue |
| weapon_teslacoil | tesla coil emitter arcing electricity, purple-yellow |
| weapon_venomlauncher | toxic grenade launcher dripping green, poison |
| weapon_plasmacannon | high-tech plasma cannon with heat vents (overheat theme), physical/energy |

---

## 7. 护甲 / 芯片 / 宝宝

- 护甲图标：`<STYLE> square icon of {desc} armor module, defensive tech, no text.`（kevlar=厚装甲板 / reactive=反应装甲块 / thermal=隔热橙 / cryo=防冻蓝 / faraday=法拉第网紫 / hazmat=防化绿）
- 芯片图标：`<STYLE> square sci-fi circuit chip icon glowing in {stat color}, {symbol} engraved (attack=sword, health=heart, crit=target, haste=lightning, pierce=arrow, element=elemental rune, greed=coin, guardian=shield).`
- 宝宝（分件 192×192，可爱但末日风的小机/小灵）：
  - pet_turret_drone：`<STYLE> a small floating machine-gun drone, cute but militaristic.`
  - pet_fire_imp：`<STYLE> a small fire elemental imp, orange-red flame body.`
  - pet_frost_wisp：`<STYLE> a small floating ice wisp spirit, ice-blue glow.`
  - pet_volt_orb：`<STYLE> a small crackling electric orb drone, purple-yellow sparks.`
  - pet_medic_drone：`<STYLE> a small white medic drone with a green cross and repair beam emitter.`
  - pet_collector：`<STYLE> a small scrappy scavenger robot with a coin-magnet and tiny popgun.`

---

## 8. 子弹 / 特效 / 背景 / UI

- **子弹** `proj_*`（64~128px）：`<STYLE> a small {element} projectile, glowing core in element color, motion-ready, transparent bg.`（element 色严格按 art bible）
- **VFX 序列帧**：`<STYLE> a {N}-frame sprite sheet of a {effect} animation, transparent bg, consistent frame size, element-colored.`（如 explosion_fire = fiery burst；freeze = ice crystals forming；chain_lightning = arcing bolt；poison_cloud = bubbling green cloud；levelup_glow = golden radiant ring；target_lock = clean orange targeting reticle pulse；threat_warning = red warning chevron pulse；hit_immune = broken elemental icon spark）
- **背景** `bg_*`（1080×1920 整图，可分 far/mid/near 层）：
  - city_ruins：`<STYLE> vertical battlefield background, ruined city street at dusk, broken skyscrapers, abandoned cars, debris, hazy smoke, dramatic but readable, top spawn area lighter, bottom defense area.`
  - subway：`<STYLE> claustrophobic underground subway tunnel, flickering lights, train wreck, wet floor reflections.`
  - military：`<STYLE> overrun military base, sandbags, barbed wire, watchtowers, harsh industrial lighting.`
  - biolab：`<STYLE> sinister bio lab, containment tubes, green toxic glow, broken machinery, eerie sterile horror.`
- **UI** `ui_* / icon_*`：`<STYLE-UI> sci-fi military HUD UI element, rounded rectangle panel, warning-orange (#FF7A3D) edge glow, post-apocalyptic worn metal, clean and readable.`（货币/元素/星图标按 art bible 配色出方形图标）
- **目标策略图标**：
  - `ui_target_strategy_nearest`: `<STYLE-UI> compact HUD icon, simple crosshair over a dot, nearest target strategy, no text.`
  - `ui_target_strategy_breach`: `<STYLE-UI> compact HUD icon, warning triangle over a base line, breach-threat priority, no text.`
  - `ui_target_strategy_elite`: `<STYLE-UI> compact HUD icon, skull inside crosshair, elite and boss priority, no text.`
  - `ui_target_strategy_low_hp`: `<STYLE-UI> compact HUD icon, cracked heart / low health marker inside crosshair, no text.`
- **卡牌控制图标**：
  - `ui_card_reroll`: `<STYLE-UI> circular arrow icon on a small card, reroll, warning-orange glow, no text.`
  - `ui_card_pin`: `<STYLE-UI> pin icon holding a card corner, card lock, no text.`
  - `ui_card_skip`: `<STYLE-UI> fast-forward / skip icon on a card, no text.`
  - `icon_reroll_charge`: `<STYLE-UI> small glowing token with circular arrows, in-run reroll charge currency, no text.`

> UI 用专门 UI 前缀（与单位前缀略不同）：去掉"single subject/transparent unit"，强调"clean flat-ish game UI, crisp edges"。

---

## 9. 视频（开场 / 章节 / Boss 登场）

竖屏 1080×1920，3~8s，色板/光源同 art bible，喂给 AI 视频工具（如 Sora）：
- `vid_intro_opening`：`Vertical cinematic, post-apocalyptic city overrun by a zombie horde at dusk, camera pushes toward a lone defense turret powering up, stylized 2.5D rendered look, dramatic, 6s.`
- `vid_boss_intro_{boss}`：`Vertical cinematic boss reveal of {boss desc}, ground shaking, the colossal zombie emerges with its signature element aura, menacing, 4s, matches game's stylized 2.5D palette.`

> 玩法中的单位动效一律用骨骼/序列帧，**不用视频**。

---

## 10. 出图工作流建议（给执行者）

1. 先定 1 个角色 + 3 个僵尸 + 1 个 Boss 的"风格样张"，确认基调后再批量（避免风格漂移）。
2. 每批用**同一 STYLE 前缀**，固定随机种子/参考图以保持一致性。
3. 分件产出后统一命名（`naming_convention.md`）入 `res://assets/`，再在 Godot 绑骨骼。
4. 用 `11 §9` 清单逐张验收，不合格重出。
