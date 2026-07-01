# 关卡背景 · 10 环境独立出图 Prompt(MiniMax 用)

目标:**每个环境一张独特原图**(不是同一张底图换色)。构图统一、场景各异,适配俯视竖版塔防玩法。

## 统一规范(每条 prompt 已内置,无需额外操作)
- 竖版 9:16 俯视高空视角,输出 ~1080×1920(或 1206×2622)。
- **中间一条纵向可通行车道**(僵尸从上方远处向下推进),保持相对干净、略降饱和,好让敌人和高亮特效叠在上面读得清。
- 两侧堆放**该环境专属**的细节;**画面最底部一道加固防线/路障**(玩家炮塔位)。
- 强烈的上→下纵深;写实偏绘画的 AAA 手游背景质感;戏剧化打光。
- **只要环境,不要角色/怪物/文字/UI**。

## 出图流程
1. **先只出「冰川断桥」这一张**发我 → 我评构图/独特性/中间车道是否够干净/风格是否够大厂 → 不行我改 prompt。
2. 风格标杆定了,再按下面逐张出其余 9 个。
3. 命名对齐:出好的图交给我/Codex 按 `bg_<env>.png` 落位(`assets/production/sprites/backgrounds/`),不改 ID/引用。

---

### 1. 熔岩铸厂 bg_lava_foundry(第 1–10 关)
```
Top-down high-angle aerial view, vertical 9:16, AAA mobile tower-defense background, painterly semi-realistic, highly detailed, cinematic lighting. Scene: a molten METAL FOUNDRY. A central vertical walkway/road lane of blackened steel plating runs top to bottom, kept relatively clear and slightly desaturated for gameplay. Flanking the lane: channels of glowing molten lava between charred steel gantries, broken forging machinery, giant smelting furnaces, hanging chains, ember sparks and heat-haze distortion rising. Bottom: a fortified steel-and-sandbag defensive barricade facing up the lane. Atmosphere: intense heat, orange embers drifting, smoke, dark industrial. Palette: molten orange and amber glow (#F37525) over blackened char and deep red heat. Strong depth, high contrast. No characters, no creatures, no text, no UI, environment plate only. 1080x1920 portrait.
```

### 2. 冰川断桥 bg_glacier_pass(11–20)
```
Top-down high-angle aerial view, vertical 9:16, AAA mobile tower-defense background, painterly semi-realistic, highly detailed, cinematic lighting. Scene: a war-torn FROZEN BRIDGE / icebound highway running vertically top (far) to bottom (near). Center is a clear traversable icy road lane (cracked ice, frost-covered asphalt) kept uncluttered and slightly desaturated for gameplay. Flanking: shattered blue ice cliffs, frozen vehicle wreckage half-buried in snow, broken guardrails hung with icicles, a frozen chasm with jagged ice shards on one side. Bottom: a fortified sandbag-and-steel base barricade facing up the lane. Atmosphere: freezing, drifting snow, low cold fog, overcast twilight with faint teal aurora at the top horizon. Palette: cold cyan and steel blue (#78DFFF), white snow, dark frozen metal. Deep atmospheric perspective. No characters, no creatures, no text, no UI, environment plate only. 1080x1920 portrait.
```

### 3. 废弃工厂 bg_abandoned_factory(21–30)
```
Top-down high-angle aerial view, vertical 9:16, AAA mobile tower-defense background, painterly semi-realistic, highly detailed, cinematic lighting. Scene: a derelict INDUSTRIAL FACTORY floor. A central vertical concrete lane runs top to bottom, relatively clear and slightly desaturated for gameplay. Flanking: rusted conveyor belts, overhead crane arms and hooks, corroded machine presses, hanging chains, broken skylights casting cold light shafts through dust. Bottom: a fortified barricade of stacked crates and steel plate. Atmosphere: abandoned, dusty, shafts of teal daylight vs warm rust. Palette: rust orange (#D88937) with cold teal light (#5AD6E8), grimy industrial grays. Depth top to bottom. No characters, no creatures, no text, no UI, environment plate only. 1080x1920 portrait.
```

### 4. 毒液生化舱 bg_toxic_biolab(31–40)
```
Top-down high-angle aerial view, vertical 9:16, AAA mobile tower-defense background, painterly semi-realistic, highly detailed, cinematic lighting. Scene: a ruined BIOHAZARD LAB. A central vertical grated-floor lane runs top to bottom, kept clear and slightly desaturated for gameplay. Flanking: pools of glowing toxic green sludge, cracked cylindrical containment/culture tanks (some shattered, leaking), ruptured pipes venting toxic mist, biohazard-marked bulkheads, dripping ooze. Bottom: a fortified quarantine barricade of steel and hazard barriers. Atmosphere: eerie toxic glow, green mist, wet surfaces. Palette: radioactive green (#36F26E, #9DFF83) over dark wet lab grays. Ominous depth. No characters, no creatures, no text, no UI, environment plate only. 1080x1920 portrait.
```

### 5. 雷暴变电站 bg_storm_substation(41–50)
```
Top-down high-angle aerial view, vertical 9:16, AAA mobile tower-defense background, painterly semi-realistic, highly detailed, cinematic lighting. Scene: an ELECTRICAL SUBSTATION in a thunderstorm. A central vertical wet-concrete lane runs top to bottom, relatively clear and slightly desaturated for gameplay. Flanking: tesla towers and transformers arcing with electricity, downed high-voltage lines sparking, insulator arrays, wet reflective ground, scattered debris. Bottom: a fortified barricade with warning lights. Atmosphere: dark stormy night, rain, electric-blue arcs illuminating, distant lightning. Palette: electric yellow (#FFE24A) and violet arc glow (#7B64FF) over dark stormy blue. Dramatic depth. No characters, no creatures, no text, no UI, environment plate only. 1080x1920 portrait.
```

### 6. 沉没地铁 bg_flooded_subway(51–60)
```
Top-down high-angle aerial view, vertical 9:16, AAA mobile tower-defense background, painterly semi-realistic, highly detailed, cinematic lighting. Scene: a flooded, sunken METRO STATION. A central vertical lane along waterlogged train tracks / platform edge runs top to bottom, kept clear and slightly desaturated for gameplay. Flanking: half-submerged platforms, tiled pillars, a derelict subway car, reflective standing water, dripping ceiling, floating debris, cold light shafts from broken vents. Bottom: a fortified barricade of sandbags on the platform. Atmosphere: dim, damp, echoing, reflections on water. Palette: cold cyan water (#45D6FF) with warm amber emergency lamps (#E6B569). Reflective depth. No characters, no creatures, no text, no UI, environment plate only. 1080x1920 portrait.
```

### 7. 沙暴炼油区 bg_desert_refinery(61–70)
```
Top-down high-angle aerial view, vertical 9:16, AAA mobile tower-defense background, painterly semi-realistic, highly detailed, cinematic lighting. Scene: an OIL REFINERY in a sandstorm. A central vertical sand-swept road lane runs top to bottom, relatively clear and slightly desaturated for gameplay. Flanking: pipelines and pressure valves, large oil storage tanks, burning flare stacks, machinery half-buried in drifting sand, distant fire glow through haze. Bottom: a fortified barricade of sandbags and barrels. Atmosphere: hot hazy sandstorm, blowing dust, orange sun glow through haze. Palette: warm amber sand (#E8A64A) with teal metal accents (#5AD8D4) and fire glow. Hazy depth. No characters, no creatures, no text, no UI, environment plate only. 1080x1920 portrait.
```

### 8. 虚空圣堂 bg_void_cathedral(71–80)
```
Top-down high-angle aerial view, vertical 9:16, AAA mobile tower-defense background, painterly semi-realistic, highly detailed, cinematic lighting. Scene: a collapsed dark CATHEDRAL corrupted by void energy. A central vertical cracked-stone-slab lane runs top to bottom, kept clear and slightly desaturated for gameplay. Flanking: towering obsidian arches and broken pillars, rift cracks in the ground bleeding glowing violet-magenta void energy, floating shattered debris held by unnatural gravity, eldritch runes faintly glowing. Bottom: a fortified barricade of stone and steel. Atmosphere: ominous, otherworldly, glowing rifts illuminating darkness. Palette: void violet (#9C6DFF) and magenta (#FF6BE7) over black obsidian and deep purple shadow. Surreal depth. No characters, no creatures, no text, no UI, environment plate only. 1080x1920 portrait.
```

### 9. 轨道升降遗址 bg_orbital_ruins(81–90)
```
Top-down high-angle aerial view, vertical 9:16, AAA mobile tower-defense background, painterly semi-realistic, highly detailed, cinematic lighting. Scene: the ruins of a SPACE ELEVATOR / orbital lift facility. A central vertical metal-grate lane runs top to bottom, relatively clear and slightly desaturated for gameplay. Flanking: massive severed tether cables snaking away, crashed spacecraft and rocket wreckage, twisted structural gantries, cold blue beacon lights blinking, scattered hull panels. Bottom: a fortified barricade of hull plating. Atmosphere: cold, high-altitude, twilight sky with faint stars, distant orbital debris. Palette: cold blue-white (#C9E6FF) with warm orange beacon accents (#F6A642) over dark steel. Vast depth. No characters, no creatures, no text, no UI, environment plate only. 1080x1920 portrait.
```

### 10. 终局核心 bg_apex_core(91–99)
```
Top-down high-angle aerial view, vertical 9:16, AAA mobile tower-defense background, painterly semi-realistic, highly detailed, cinematic lighting. Scene: a final REACTOR CORE chamber, high-tech war-machine architecture. A central vertical black-and-gold armored-floor lane runs top to bottom, kept clear and slightly desaturated for gameplay. Flanking: pulsing plasma conduits and energy cabling, a towering glowing reactor core structure at the top, ornate black-gold machinery, floating energy rings, holographic warning glyphs. Bottom: an elite fortified barricade of gold-trimmed armor plating. Atmosphere: powerful, climactic, humming energy, dramatic core glow. Palette: molten gold (#F6B63D) and cyan plasma (#72EAFF) over black armored metal. Epic depth. No characters, no creatures, no text, no UI, environment plate only. 1080x1920 portrait.
```

---

## 备注
- 若 MiniMax 支持负向提示/反向词,可加:`no characters, no monsters, no text, no watermark, no logo, no UI, not cluttered center`。
- 若某张中间车道太乱、导致敌人/特效看不清,我会让你重出并在 prompt 里强调 "clean readable central lane, low clutter in the middle path"。
- 10 张风格要**成套**(同一构图骨架 + 同一打光语言),各自环境独特——出的时候尽量同一批参数,便于一致。
