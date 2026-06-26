# 音频素材生成 Prompt

> 说明：GPT 本身不产高质量音乐/音效。**音乐**喂给 AI 音乐工具（如 Suno / Udio）；**音效**用 AI 音效工具（如 ElevenLabs SFX）或音效库（freesound 等）检索 + 轻处理。
> 本文给每个音频的"生成 prompt / 检索关键词 + 情绪描述"。文件名见 `asset_manifest.md` / `12_audio_design.md`，遵守命名规范。
> 元素音色家族保持统一（火=轰燃、冰=脆裂、雷=噼啪、毒=咕嘟、物理=金属）。

---

## 1. BGM（喂给 AI 音乐工具，输出后剪为无缝循环 → .ogg）

| 文件 | Prompt（英文，给音乐 AI） | 时长 |
|---|---|---|
| `bgm_main_menu` | `Dark suspenseful electronic ambient with a slow building pulse, post-apocalyptic, tense but hopeful, loopable menu theme, no vocals.` | 90s loop |
| `bgm_battle_city` | `Driving hybrid orchestral-electronic battle music, mid tempo ~120bpm, industrial percussion, tense but heroic, loopable, no vocals.` | 120s loop |
| `bgm_battle_subway` | `Claustrophobic dark electronic battle track, echoey industrial percussion, oppressive underground tension, ~115bpm, loopable.` | 120s loop |
| `bgm_battle_military` | `Hard industrial military electronic combat music, aggressive driving beat ~130bpm, metallic hits, urgent, loopable.` | 120s loop |
| `bgm_battle_biolab` | `Eerie unsettling electronic horror battle music, dissonant pads, glitchy percussion, sense of losing control, ~125bpm, loopable.` | 120s loop |
| `bgm_boss` | `Epic intense boss battle music, pounding war drums, heavy brass and synth, high pressure, dramatic, ~140bpm, loopable.` | 120s loop |
| `bgm_boss_final` | `Climactic multi-section final boss epic, escalating intensity, choir + war drums + heavy synth, end-of-world stakes, ~145bpm.` | 150s loop |
| `bgm_victory` | `Short triumphant victory stinger, uplifting brass and synth swell, 4 seconds.` | 4s |
| `bgm_defeat` | `Short somber defeat stinger, descending tones, 4 seconds.` | 4s |

切循环要点：选无明显起止的乐段，首尾 crossfade，确认 loop 无缝。

---

## 2. SFX（AI 音效工具 / 音效库；prompt = 描述 + 关键词）

### 武器开火 `sfx_shot_*`
| 文件 | 描述 / 关键词 |
|---|---|
| `sfx_shot_autocannon` | rapid mechanical machine-gun burst, punchy, short |
| `sfx_shot_railgun` | charged electromagnetic rail shot, deep whoom + crack |
| `sfx_shot_scattergun` | shotgun blast, wide punchy boom |
| `sfx_shot_flamethrower` | continuous whooshing flame jet, loopable |
| `sfx_shot_cryocannon` | icy crystalline projectile launch, frosty shimmer |
| `sfx_shot_teslacoil` | electric arc zap discharge, crackling |
| `sfx_shot_venomlauncher` | wet sludge projectile launch, gloopy thunk |
| `sfx_shot_plasma` | sci-fi plasma charge and fire, energy build + release; + overheat warning beep variant |

### 命中 / 元素 `sfx_hit_*`
| 文件 | 描述 |
|---|---|
| `sfx_hit_physical` | blunt metallic impact thud |
| `sfx_hit_fire` | fiery whoosh ignite |
| `sfx_hit_ice` | sharp ice crack / shatter |
| `sfx_hit_lightning` | electric zap burst |
| `sfx_hit_poison` | corrosive bubbling sizzle |
| `sfx_hit_crit` | extra crisp bright impact with a metallic 'ding' overtone (crit feedback) |

### 敌人 `sfx_zombie_*`
| 文件 | 描述 |
|---|---|
| `sfx_zombie_groan` | low guttural zombie moan (a few variations) |
| `sfx_zombie_death` | wet zombie death collapse |
| `sfx_zombie_breach` | alarm/alert sting when a zombie crosses the base line |
| `sfx_bomber_explode` | big explosion with debris |
| `sfx_screamer_scream` | piercing zombie shriek |
| `sfx_charger_charge` | building rush/charge growl + footsteps |
| `sfx_necromancer_revive` | eerie dark magic revive whoosh |
| `sfx_splitter_split` | gooey squelchy split |

### Boss `sfx_boss_*`
| 文件 | 描述 |
|---|---|
| `sfx_boss_roar` | massive monstrous roar (boss entrance, generic) |
| `sfx_frost_warden_freeze` | deep freezing crystallization sound (turret-freeze warning) |
| `sfx_void_phantom_phase` | ghostly phase-shift whoosh / reverb |
| （其余 Boss 机制音按需补，统一前缀 `sfx_{boss}_{mechanic}`） | |

### 技能 / 系统 / UI `sfx_skill_* / sfx_ui_*`
| 文件 | 描述 |
|---|---|
| `sfx_skill_cast` | generic active-skill activation whoosh-charge |
| `sfx_levelup_card` | bright magical chime when the 3-choice card popup appears |
| `sfx_card_select` | satisfying confirm click for picking a card |
| `sfx_card_reroll` | quick magical shuffle / card whoosh, light and snappy |
| `sfx_card_pin` | small metallic pin-lock click with a soft glow tail |
| `sfx_elite_spawn` | ominous warning sting for elite enemy |
| `sfx_target_lock` | short digital target lock beep, satisfying but subtle |
| `sfx_target_strategy` | tiny HUD mode-switch blip, very short |
| `sfx_hit_immune` | dull rejected impact with broken energy crackle, communicates no effect |
| `sfx_gold_pickup` | crisp coin pickup 'ding' (short, satisfying, pitched up on combo) |
| `sfx_star_earn` | precious shimmering star-earned chime (more 'valuable' than gold) |
| `sfx_upgrade_success` | mechanical/energetic upgrade-success confirm |
| `sfx_ui_click` / `sfx_ui_confirm` / `sfx_ui_cancel` | clean UI clicks |

---

## 3. 制作与混音要点（呼应 `12`）

- 三总线 BGM / SFX / UI，分别可调；目标响度统一（约 -14 LUFS 整体，SFX 峰值留余量）。
- SFX 并发上限 + 同音去重，群战不音爆；高优先级（Boss/越线/暴击/得星）优先。
- 元素音色家族一致性：同元素的 shot/hit/vfx 音色听感统一。
- 得星音 `sfx_star_earn` 刻意做"珍贵"，强化"星 > 金币"的价值层级（呼应 `02`）。
- 所有音频转 `.ogg`（BGM 循环 / SFX 短音），44.1kHz，控制体积（移动端包体）。
