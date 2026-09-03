# 31 · App Store Listing Draft

Source of truth for facts used below: `data/store_products.json`, `data/levels.json` (99 entries, 10 chapters/zones), `data/challenges.json` (10 fixed-modifier challenge chapters), `data/characters.json` (4 heroes), `data/weapons.json` (8 free weapons + 4 premium "Apocalypse" weapons), `data/elements.json` (5 elements), `data/bosses.json` (8 bosses), `data/environments.json` (10 zone names/titles), `data/localization_zh.json` / `data/localization_en.json` / `data/localization_ui_en.json` (established terminology), `design/21_premium_themes_and_apocalypse_arsenal_plan.md`, `design/m1_implementation_progress.md` (VFX/blood detail), `project.godot` (`config/name="Zombie Fire"`).

Established terminology reused from the game's own localization (do not invent new terms): **Hero** (角色/英雄→Hero, not "Character"), **Armor** (护甲), **Chip** (芯片), **Pet** (宠物), **Zone** (战区→Zone, e.g. "第一战区"→"Zone 01"), **Challenge Mode** (挑战模式), **Endless Horde** (无限尸潮), **Boss** (首领→Boss), **Element** (元素).

Important correction to an older draft: `docs/app_store_metadata_zh.md` (pre-monetization draft) states "no in-app purchases." That is now stale — `data/store_products.json` defines 12 real non-consumable IAP products (cosmetic hero themes + optional "Apocalypse" weapon arsenals). All copy below reflects the current, IAP-enabled build. The **campaign itself (all 99 levels) remains fully free and requires no purchase** — see the App Review notes for why that's structurally guaranteed, not just a promise.

Character counts below use `len()` on the literal string (1 CJK character = 1, matching how Apple's ASC counters treat these fields).

---

## 1. App Name (limit: 30 characters)

### Chinese candidates

| # | Name | Chars |
|---|---|---|
| 1 (recommended) | 僵尸烈火 | 4 |
| 2 | 僵尸烈火：末日防线 | 9 |
| 3 | 僵尸烈火：尸潮塔防 | 9 |

僵尸烈火 is the name specified for this draft and is not contradicted anywhere in the repo (no alternate Chinese title was found in `design/` or `docs/`), so it's kept as the primary. The two longer variants fold in genre words for search weight if the team wants a more descriptive name field instead of a clean brand name.

### English candidates

| # | Name | Chars |
|---|---|---|
| 1 (recommended) | Zombie Fire | 11 |
| 2 | Zombie Fire: Turret Defense | 27 |
| 3 | Zombie Fire: Last Stand | 23 |

"Zombie Fire" is the name already baked into the project (`project.godot: config/name="Zombie Fire"`), so #1/#1 is the safe, already-correct pairing for both languages — keep the name short and brandable, put the descriptive hook in the Subtitle field instead (that's what Subtitle is for, and it avoids redundancy between Name and Subtitle on the store listing).

---

## 2. Subtitle (limit: 30 characters)

### Chinese candidates

| # | Subtitle | Chars |
|---|---|---|
| 1 | 竖屏尸潮防线射击 | 8 |
| 2 (recommended) | 自动炮塔·99关尸潮防线 | 12 |
| 3 | 元素炮塔，局内选卡成长 | 11 |

### English candidates

| # | Subtitle | Chars |
|---|---|---|
| 1 | Auto-Turret Zombie Defense | 26 |
| 2 (recommended) | 99 Levels of Zombie Defense | 27 |
| 3 | Aim, Fire, Survive the Horde | 28 |

Recommendation: pair Chinese #2 and English #2 — both put the "99 levels" number up front, which is a real, verifiable differentiator (`data/levels.json` has exactly 99 entries) and reads as a concrete promise rather than genre filler.

---

## 3. Promotional Text (limit: 170 characters, editable without a new build)

**Chinese** (82 chars):
> 自动开火，手动锁定，局内三选一技能卡构筑打法。99关尸潮防线、4名英雄、8种基础元素主炮，全程离线单机运行。内购仅为可选外观主题与终焉军械，不影响免费通关全部关卡。

**English** (161 chars):
> Auto-fire, aim by hand, pick cards mid-run to build your loadout. 99 levels, 4 heroes, 8 weapons, fully offline. IAP adds only optional cosmetic themes and gear.

---

## 4. Description (limit: 4000 characters)

### English (1655 chars)

Zombie Fire is a vertical turret-defense shooter: an automatic cannon at the bottom of the screen fires on its own, and you aim by dragging your finger or double-tapping a target to lock on. Between waves you pick one of three skill cards to shape your build for that run — chain lightning, fire splash, piercing rounds, extra projectiles, barriers, and more.

The campaign runs 99 levels across 10 story zones, from a burning foundry and a flooded subway to orbital ruins and a void cathedral, each with its own zombie roster and a boss guarding the zone's final gate. Clear a level to unlock the next; how much base HP you protect decides your 1-3 star rating.

Once you've cleared a zone, Challenge Mode replays its zombies under a fixed hard modifier — faster runners, heavier armor, more chain control — and Endless Horde is an open-ended survival mode that tracks your best round.

Between runs, build your loadout: pick 1 of 4 heroes, each with two signature active skills, then equip a main weapon, armor, chip, and pet. Eight base weapons cover five elements — physical, fire, ice, lightning, and poison — and zombies have real elemental weaknesses, so matching your loadout to a zone's threat matters as much as your reflexes.

Zombie Fire is a fully offline single-player game. There is no multiplayer and no online features of any kind — no account, no login, no ads, and no data collection. Optional in-app purchases add cosmetic hero themes and post-campaign "Apocalypse" weapon sets, and each one only unlocks for purchase after you've already cleared the campaign milestone it's tied to — none of the 99 campaign levels require a purchase.

### Chinese (484 chars)

《僵尸烈火》是一款竖屏自动炮塔射击游戏：底部机炮自动开火，你只需要拖动手指瞄准，或双击僵尸锁定集火。每次升级会弹出三选一技能卡，连锁闪电、火焰溅射、穿透弹、多重弹道、护盾屏障——当局的打法由你现场攒出来。

主线关卡共 99 关，横跨 10 个战区场景：从火光冲天的熔岩铸厂、沉没的地铁隧道，到轨道升降遗址与虚空圣堂，每个战区都有专属僵尸配置，最后一关必有首领驻守闸门。通关解锁下一关，基地剩余血量决定 1~3 星评价。

打通战区后还有挑战模式：用固定的高强度词缀重打该战区僵尸群，考验反应与配装；以及无限尸潮，打法自由，只看你能撑到第几轮。

局外养成：4 名英雄各带 2 个专属主动技能，搭配主炮、护甲、芯片和宠物组成完整配装。8 把基础主炮覆盖物理/火/冰/雷/毒 5 种元素，僵尸也有明确的元素弱点，配装和反应同样重要。

《僵尸烈火》完全离线单机，无多人联机、无任何联网功能——不需要注册登录，不含广告，不收集任何数据。内购仅提供可选的英雄外观主题和"终焉军械"武器套装，且必须先通关对应里程碑关卡才会开放购买，99 关主线全部可以免费通关，不受内购影响。

**Note on IAP framing**: the "Apocalypse" weapon sets are not purely cosmetic — per `data/premium_sets.json` they carry a real +25% stage-neutral physical-damage bonus and unique set effects (Overload chains, Combustion spread, Shatter chains, Judgment armor penetration). The copy above deliberately does not claim they're "just cosmetic" — only the four *theme* products (visual-only) are. It also doesn't claim "no pay-to-win," since that would be arguable; it makes the narrower, verifiably true claim that no campaign level requires a purchase (structurally true — see section 8 below).

---

## 5. Keywords (limit: 100 characters, comma-separated, no spaces, no repeats of words already in Name/Subtitle)

Assumes the recommended Name + Subtitle pair from sections 1–2: 僵尸烈火 / 自动炮塔·99关尸潮防线 and Zombie Fire / 99 Levels of Zombie Defense.

**Chinese** (83 chars, excludes 僵尸/烈火/自动/炮塔/关/尸潮/防线):
```
塔防,肉鸽,射击,末日,生存,单机,离线,选卡,构筑,英雄,元素,连锁,冰霜,雷电,火焰,毒液,首领,无尽,挑战,装备,养成,动作,怪物,武器,护甲,芯片,宠物,卡牌
```

**English** (98 chars, excludes zombie/fire/levels/defense):
```
shooter,survival,roguelike,offline,horde,rpg,cards,build,skill,element,boss,endless,challenge,gear
```

---

## 6. What's New — Version 1.0.0 (limit: 4000 characters)

**Chinese** (70 chars):
> 首次上线。99 关主线横跨 10 个战区，4 名英雄，8 把基础主炮，挑战模式与无限尸潮。完全离线单机——无广告、无需账号、不收集任何数据。

**English** (183 chars):
> Initial release. 99 campaign levels across 10 zones, 4 heroes, 8 base weapons, Challenge Mode, and Endless Horde. Fully offline single-player — no ads, no accounts, no data collected.

---

## 7. Age Rating Questionnaire

Checked against the actual VFX/content data, not assumed:

- `design/m1_implementation_progress.md:878` — "enemy death now leaves a short-lived **green** blood / puddle effect that fades out after roughly 2-3 seconds" (`_spawn_zombie_blood_pool`, line 1542). Blood is present but stylized green, not red — consistent with the art bible's explicit "stylized, semi-realistic, 3D-rendered 2D sprite" direction (`design/11_art_bible.md:8-9`), not a realistic/gory style.
- No dismemberment, decapitation, or gore terms appear anywhere in `data/*.json` or `design/*.md` (checked via grep across VFX, zombie, and boss data).
- Enemies are zombies (`data/zombies.json`, `data/bosses.json`) in a cartoon-apocalypse setting — fantasy/undead, not humans, not realistic weapons-on-humans violence.
- No sexual content, nudity, profanity, alcohol/tobacco/drug references, or crude humor anywhere in the localization or narrative data.
- No gambling or loot-box mechanics — all 12 IAP in `data/store_products.json` are fixed-price, direct-entitlement non-consumables (see file 2); no randomized rewards for real or virtual currency.
- No user-generated content, no chat, no unrestricted web access, no third-party social integration (`docs/app_store_metadata_zh.md` privacy summary: no ads, no analytics, no login, no network calls; local-save only).

Apple age-rating questionnaire answers:

| Category | Answer | Why |
|---|---|---|
| Cartoon or Fantasy Violence | **Infrequent/Mild** | Turret-vs-zombie-horde combat with stylized green blood-pool VFX on death; no realistic gore, no human targets, no dismemberment. |
| Realistic Violence | None | No realistic human violence or weapons-on-people depiction. |
| Sexual Content or Nudity | None | Not present anywhere in art or text data. |
| Profanity or Crude Humor | None | Not present in any localization string. |
| Alcohol, Tobacco, or Drug Use | None | Not present. |
| Mature/Suggestive Themes | None | Not present. |
| Horror/Fear Themes | **Infrequent/Mild** | Zombie-apocalypse premise and boss enemies, but rendered in a bright, stylized, non-graphic art style — not a horror game. |
| Gambling/Contests | None | No simulated gambling, no loot boxes; all IAP are fixed-price direct purchases. |
| Unrestricted Web Access | No | Game makes no network calls. |
| User-Generated Content | No | No chat, sharing, or UGC features. |

**Recommended rating: 9+** (the "Infrequent/Mild Cartoon or Fantasy Violence" and "Infrequent/Mild Horror/Fear Themes" answers are what push it past 4+; nothing else in the questionnaire triggers a higher tier than 9+).

---

## 8. App Review Notes (English)

> Zombie Fire is a fully offline, single-player game. There is no account system, no login, and no server backend of any kind — there is nothing to sign in to and no demo account is needed.
>
> **Reaching content**: Tap Start on the title screen to open the level map. Level 1 is unlocked by default; clearing a level unlocks the next one sequentially. All 99 campaign levels are playable and none are held back by IAP — early levels (Zone 1, levels 1-10) run about 30-90 seconds each with the default hero and weapon, so a reviewer can move through the first zone in well under 15 minutes.
>
> **In-app purchases**: There are 12 non-consumable IAP products (4 cosmetic hero-theme skins + 4 "complete arsenal" weapon/armor/chip/pet bundles + 4 "upgrade" bundles for players who already own the matching theme — see the companion products list for the full mapping). Each purchase is a one-time unlock, fully restorable via the "Restore Purchases" button in Settings, and none of them are required to finish the campaign — the campaign is completely playable, and completable, for free.
>
> One thing worth flagging for a fast review pass: each "Apocalypse" arsenal only becomes visible/purchasable in the in-game store **after** the player has cleared the specific campaign level it's tied to (Inferno at level 30, Thunder at level 50, Absolute Zero at level 70, Golden Law at level 90) — this is intentional game design (a reward-reveal, not a paywall gate), but it does mean a reviewer who wants to see every purchase screen in one sitting would need to reach level 90, which takes considerably longer than the first zone. If the review team needs immediate access to every product screen without playing that far, please let us know via Resolution Center and we can provide a review-only build with campaign-progress checks temporarily disabled for the premium store (a build variant we've used for internal QA before); we did not ship that bypass in the production build since it would let players skip content unlocks.
>
> Settings (gear icon, reachable from the map screen) contains independent music/effects/interface volume, a reduced-effects toggle, haptics toggle, save backup/restore, save reset (behind a two-tap confirmation), a public Privacy Policy link, and a public Support link. The app has no ads, no analytics, no push notifications, and no tracking of any kind.
>
> Privacy Policy: `https://blog.gavingao.cn/zombie-fire/privacy.html`
> Support: `https://blog.gavingao.cn/zombie-fire/support.html`

---

## 9. Category Recommendation

**Primary: Games → Action**
**Secondary: Games → Strategy**

Reasoning: the core moment-to-moment loop is real-time and reflex-driven — auto-fire plus manual drag-to-aim and double-tap-to-lock under a rising zombie count is an Action-shooter skill test, which is the stronger, more accurate first impression for App Store browsing and matches how comparable "auto-shooter vs. horde" titles are categorized. Strategy is the right secondary because the between-wave three-card skill draft, the hero/weapon/armor/chip/pet loadout planning, and the elemental-weakness matchup system are genuine build-crafting and tower-defense-style planning layers, not just flavor — but they sit on top of an action core rather than replacing it, so Strategy fits best as secondary rather than primary.
