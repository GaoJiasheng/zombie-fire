# 32 · App Store Connect IAP Metadata

Source: all 12 products come directly from `data/store_products.json` (verified — no more, no fewer). Item names/grants cross-checked against `data/premium_sets.json`, `data/weapons.json`, `data/localization_zh.json`, `data/localization_en.json`.

## 为什么是 12 个商品(Owner 2026-09-03 决定按 12 个首发)

**只有 4 套内容,但每套卖 3 个 SKU,所以 ASC 里是 4 × 3 = 12 个商品。**

| 每套的三个 SKU | 价格(雷霆/烈焰/极光 · 黄金律) | 买到什么 |
|---|---|---|
| 主题 Theme | $1.99 · $1.99 | 仅外观:四名角色战衣、界面皮肤、枪械配色 |
| 完整包 Complete | $6.99 · $8.99 | 主题 **加上** 军械(武器/护甲/芯片/宠物) |
| 升级包 Upgrade | $4.99 · $6.99 | 已买主题的玩家补差价,拿到该套军械 |

**升级包为什么必须单独建一个商品**:Apple 的非消耗型内购没有原生的"补差价升级"机制
(那只存在于订阅的 Subscription Group 里)。要让"先买了 $1.99 主题的玩家"再花差价拿到完整
军械,只能另卖一个 SKU。定价是对齐的,两条路花一样的钱:

- 雷霆/烈焰/极光:$1.99 + $4.99 = $6.98 ≈ 完整包 $6.99
- 黄金律:$1.99 + $6.99 = $8.98 ≈ 完整包 $8.99

**给审核员的一句话解释**(建议原样放进每个 upgrade 商品的 Review Notes):
> This is an upgrade SKU. Players who already bought the theme pay the difference
> to receive the full arsenal for the same series. Buyers who have not bought the
> theme buy the "Complete" product instead. Both paths cost the same in total.

**运行时如何保证不重复收费**:商店只对"已拥有主题、未拥有军械"的玩家展示升级包
(`PurchaseManager.display_offer_ids`),已拥有完整军械的玩家两个都不再展示。

---

## Type verification

Every product in `data/store_products.json` is a **Non-Consumable**:
- `grants` is a fixed, small list of permanent entitlement strings (e.g. `"ent_theme_neon_tempest"`, `"ent_arsenal_thunder"`) — not a quantity, not a currency, not something that gets consumed or re-granted.
- There is no `consumable`, `quantity`, `stack`, or "buy again" field anywhere in the schema.
- `design/21_premium_themes_and_apocalypse_arsenal_plan.md` §13.2 explicitly says to "Create Non-Consumable IAP" and lists "Restore Purchases" as a required client feature.
- Each purchase is a one-time cosmetic/equipment unlock the player keeps forever and can restore on reinstall/new device — the textbook definition of Non-Consumable.

Display Name limit is 30 characters; Description limit is 45 characters (both counted with `len()` below, matching how ASC counts CJK and Latin characters).

---

## Series: Thunder (Neon Tempest) — reveals after clearing campaign level 50

| Field | Value |
|---|---|
| **Product ID** | `com.gaojiasheng.zombiefire.theme.neon_tempest` |
| Reference Name | Theme – Neon Tempest (Thunder series) |
| Type | Non-Consumable |
| Display Name zh-Hans | 霓虹雷暴主题 (6) |
| Display Name en-US | Neon Tempest Theme (18) |
| Description zh-Hans | 4英雄战衣+界面+枪械涂装，纯外观 (17) |
| Description en-US | 4 hero skins, UI theme, gun colorway (36) |
| Price tier suggestion | mock_price $1.99 → ASC Price Point ≈2 (verify against the current USD price schedule in ASC) |
| Grants | Cosmetic only: reskins all 4 heroes, the full UI, combat aura effects, and weapon colorway to the Neon Tempest look; no stat change. |
| Kind | Theme |

| Field | Value |
|---|---|
| **Product ID** | `com.gaojiasheng.zombiefire.arsenal.thunder_complete` |
| Reference Name | Arsenal Complete – Thunder |
| Type | Non-Consumable |
| Display Name zh-Hans | 终焉军械 · 雷霆完整包 (12) |
| Display Name en-US | Thunder Apocalypse Complete (27) |
| Description zh-Hans | 含雷暴主题+终焉雷霆全套武装 (14) |
| Description en-US | Neon Tempest theme + Thunder arsenal (36) |
| Price tier suggestion | mock_price $6.99 → ASC Price Point ≈7 |
| Grants | Everything in the Neon Tempest theme, plus the Apocalypse Thunder weapon, armor, chip, and pet (Sky Conductor Armor, Superconductive Core, Tempest Terminal): +25% stage-neutral physical damage, any-element ammo compatibility, and Overload chain-lightning set effects. |
| Kind | Complete arsenal (theme + full equipment set) |

| Field | Value |
|---|---|
| **Product ID** | `com.gaojiasheng.zombiefire.arsenal.thunder_upgrade` |
| Reference Name | Arsenal Upgrade – Thunder |
| Type | Non-Consumable |
| Display Name zh-Hans | 终焉军械 · 雷霆升级包 (12) |
| Display Name en-US | Thunder Apocalypse Upgrade (26) |
| Description zh-Hans | 已有主题，补齐终焉雷霆全套武装 (15) |
| Description en-US | Adds the Thunder arsenal for theme owners (41) |
| Price tier suggestion | mock_price $4.99 → ASC Price Point ≈5 |
| Grants | For players who already own the Neon Tempest theme: adds the Apocalypse Thunder weapon, armor, chip, and pet only (theme entitlement is not re-granted, since it's already owned). |
| Kind | Upgrade (equipment-only, theme owners) |

---

## Series: Inferno (Infernal Dominion) — reveals after clearing campaign level 30

| Field | Value |
|---|---|
| **Product ID** | `com.gaojiasheng.zombiefire.theme.infernal_dominion` |
| Reference Name | Theme – Infernal Dominion (Inferno series) |
| Type | Non-Consumable |
| Display Name zh-Hans | 炼狱赤焰主题 (6) |
| Display Name en-US | Infernal Dominion Theme (23) |
| Description zh-Hans | 4英雄战衣+熔铜界面+赤焰涂装 (15) |
| Description en-US | 4 hero skins, molten UI, fire colorway (38) |
| Price tier suggestion | mock_price $1.99 → ASC Price Point ≈2 |
| Grants | Cosmetic only: reskins all 4 heroes, the molten-copper UI, weapon skins, and mechanical fire-wing firing signature; no stat change. |
| Kind | Theme |

| Field | Value |
|---|---|
| **Product ID** | `com.gaojiasheng.zombiefire.arsenal.inferno_complete` |
| Reference Name | Arsenal Complete – Inferno |
| Type | Non-Consumable |
| Display Name zh-Hans | 终焉军械 · 炼狱完整包 (12) |
| Display Name en-US | Inferno Apocalypse Complete (27) |
| Description zh-Hans | 含赤焰主题+终焉炼狱全套武装 (14) |
| Description en-US | Infernal Dominion theme + Inferno arsenal (41) |
| Price tier suggestion | mock_price $6.99 → ASC Price Point ≈7 |
| Grants | Everything in the Infernal Dominion theme, plus the Apocalypse Inferno weapon, armor, chip, and pet (Molten Starplate, Stellar Furnace Core, Immortal Mech-Phoenix): +25% stage-neutral physical damage, any-element ammo compatibility, and Combustion burn-spread set effects. |
| Kind | Complete arsenal (theme + full equipment set) |

| Field | Value |
|---|---|
| **Product ID** | `com.gaojiasheng.zombiefire.arsenal.inferno_upgrade` |
| Reference Name | Arsenal Upgrade – Inferno |
| Type | Non-Consumable |
| Display Name zh-Hans | 终焉军械 · 炼狱升级包 (12) |
| Display Name en-US | Inferno Apocalypse Upgrade (26) |
| Description zh-Hans | 已有主题，补齐终焉炼狱全套武装 (15) |
| Description en-US | Adds the Inferno arsenal for theme owners (41) |
| Price tier suggestion | mock_price $4.99 → ASC Price Point ≈5 |
| Grants | For players who already own the Infernal Dominion theme: adds the Apocalypse Inferno weapon, armor, chip, and pet only. |
| Kind | Upgrade (equipment-only, theme owners) |

---

## Series: Absolute Zero (Polar Aurora) — reveals after clearing campaign level 70

| Field | Value |
|---|---|
| **Product ID** | `com.gaojiasheng.zombiefire.theme.polar_aurora` |
| Reference Name | Theme – Polar Aurora (Absolute Zero series) |
| Type | Non-Consumable |
| Display Name zh-Hans | 极地极光主题 (6) |
| Display Name en-US | Polar Aurora Theme (18) |
| Description zh-Hans | 4英雄战衣+冰晶界面+极光冰翼 (15) |
| Description en-US | 4 hero skins, crystal UI, aurora-ice look (41) |
| Price tier suggestion | mock_price $1.99 → ASC Price Point ≈2 |
| Grants | Cosmetic only: reskins all 4 heroes, the crystalline UI, weapon skins, and rear aurora-ice firing signature; no stat change. |
| Kind | Theme |

| Field | Value |
|---|---|
| **Product ID** | `com.gaojiasheng.zombiefire.arsenal.absolute_zero_complete` |
| Reference Name | Arsenal Complete – Absolute Zero |
| Type | Non-Consumable |
| Display Name zh-Hans | 终焉军械 · 绝对零度完整包 (14) |
| Display Name en-US | **Absolute Zero: Complete Set (27)** — shortened for ASC; the in-game name_en "Absolute Zero Apocalypse Complete" is 33 chars and exceeds Apple's 30-char Display Name limit |
| Description zh-Hans | 含极光主题+终焉绝对零度全套武装 (16) |
| Description en-US | Polar Aurora theme + Absolute Zero arsenal (42) |
| Price tier suggestion | mock_price $6.99 → ASC Price Point ≈7 |
| Grants | Everything in the Polar Aurora theme, plus the Apocalypse Absolute Zero weapon, armor, chip, and pet (Permafrost Crystal Wall, Entropy Reduction Core, Aurora Ice Spirit): +25% stage-neutral physical damage, any-element ammo compatibility, and Shatter/Brittle chain set effects. |
| Kind | Complete arsenal (theme + full equipment set) |

| Field | Value |
|---|---|
| **Product ID** | `com.gaojiasheng.zombiefire.arsenal.absolute_zero_upgrade` |
| Reference Name | Arsenal Upgrade – Absolute Zero |
| Type | Non-Consumable |
| Display Name zh-Hans | 终焉军械 · 绝对零度升级包 (14) |
| Display Name en-US | **Absolute Zero: Upgrade (22)** — shortened for ASC; the in-game name_en "Absolute Zero Apocalypse Upgrade" is 32 chars and exceeds the 30-char limit |
| Description zh-Hans | 已有主题，补齐终焉绝对零度全套武装 (17) |
| Description en-US | Adds the Absolute Zero arsenal for owners (41) |
| Price tier suggestion | mock_price $4.99 → ASC Price Point ≈5 |
| Grants | For players who already own the Polar Aurora theme: adds the Apocalypse Absolute Zero weapon, armor, chip, and pet only. |
| Kind | Upgrade (equipment-only, theme owners) |

---

## Series: Golden Law (Gilded Eclipse) — reveals after clearing campaign level 90

| Field | Value |
|---|---|
| **Product ID** | `com.gaojiasheng.zombiefire.theme.gilded_eclipse` |
| Reference Name | Theme – Gilded Eclipse (Golden Law series) |
| Type | Non-Consumable |
| Display Name zh-Hans | 鎏金永夜主题 (6) |
| Display Name en-US | Gilded Eclipse Theme (20) |
| Description zh-Hans | 4英雄战衣+镜黑鎏金界面+流金特效 (17) |
| Description en-US | 4 hero skins, black-gold UI, gilded look (40) |
| Price tier suggestion | mock_price $1.99 → ASC Price Point ≈2 |
| Grants | Cosmetic only: reskins all 4 heroes, the mirror-black-and-gold UI, gilded weapon skins, and rear flowing-gold firing signature; no stat change. |
| Kind | Theme |

| Field | Value |
|---|---|
| **Product ID** | `com.gaojiasheng.zombiefire.arsenal.golden_law_complete` |
| Reference Name | Arsenal Complete – Golden Law |
| Type | Non-Consumable |
| Display Name zh-Hans | 终焉军械 · 黄金律完整包 (13) |
| Display Name en-US | Golden Law Apocalypse Complete (30 — at the limit, OK) |
| Description zh-Hans | 含永夜主题+天衡裁决炮全套武装 (15) |
| Description en-US | Gilded Eclipse theme + Golden Law arsenal (41) |
| Price tier suggestion | mock_price $8.99 → ASC Price Point ≈9 (highest-priced product; this series has the most elaborate set — pierce + armor-penetrating "Judgment" hits) |
| Grants | Everything in the Gilded Eclipse theme, plus the Sovereign Verdict Cannon, Eternal Night Aegis armor, Golden Law Core chip, and Aureate Skyfalcon pet: +25% stage-neutral physical damage, any-element ammo compatibility, and Judgment armor-penetration set effects. |
| Kind | Complete arsenal (theme + full equipment set) |

| Field | Value |
|---|---|
| **Product ID** | `com.gaojiasheng.zombiefire.arsenal.golden_law_upgrade` |
| Reference Name | Arsenal Upgrade – Golden Law |
| Type | Non-Consumable |
| Display Name zh-Hans | 终焉军械 · 黄金律升级包 (13) |
| Display Name en-US | Golden Law Apocalypse Upgrade (29) |
| Description zh-Hans | 已有主题，补齐天衡裁决炮全套武装 (16) |
| Description en-US | Adds the Golden Law arsenal for owners (38) |
| Price tier suggestion | mock_price $6.99 → ASC Price Point ≈7 |
| Grants | For players who already own the Gilded Eclipse theme: adds the Sovereign Verdict Cannon, Eternal Night Aegis armor, Golden Law Core chip, and Aureate Skyfalcon pet only. |
| Kind | Upgrade (equipment-only, theme owners) |

---

## Grouping summary

| Series | Theme (cosmetic) | Complete arsenal | Upgrade (equipment-only) |
|---|---|---|---|
| Thunder | Neon Tempest — $1.99 | Thunder Apocalypse — $6.99 | Thunder Upgrade — $4.99 |
| Inferno | Infernal Dominion — $1.99 | Inferno Apocalypse — $6.99 | Inferno Upgrade — $4.99 |
| Absolute Zero | Polar Aurora — $1.99 | Absolute Zero Apocalypse — $6.99 | Absolute Zero Upgrade — $4.99 |
| Golden Law | Gilded Eclipse — $1.99 | Golden Law Apocalypse — $8.99 | Golden Law Upgrade — $6.99 |

Note: `design/21_premium_themes_and_apocalypse_arsenal_plan.md` §13.3 records a phased rollout decision — the team planned to create only the **3 Thunder-series product IDs** in ASC first ("在霓虹 / 雷霆样板未通过前，不在 App Store Connect 创建其余九个产品 ID"), to avoid locking in naming before the pattern was validated. That phasing may or may not still apply by the time this is used — check current ASC state before bulk-creating all 12. The metadata above is complete for all 12 regardless, so it's ready whichever phase you're at.

---

## Checklist: what else App Store Connect needs per IAP

- [ ] **Review screenshot** — one image per product showing the actual purchase screen/preview as it appears in the app (design doc requires: theme cards show all 4 hero costume thumbnails, weapon colorway, and UI/base preview; arsenal cards show all 4 equipment pieces plus level-1 and max-level stats). Must match real in-app rendering — no mocked-up or pre-rendered art that doesn't match what ships (`design/21` §11.3: "商品卡不能播放与实机不一致的预渲染假效果").
- [ ] **Review Notes per product** (or one shared note referencing all 12) — state the entry point (Settings → Store, or the in-game prompts listed in `design/21` §11.1: forced first-launch modal, battle-in-progress entry, defeat popup, base-critical-HP popup), confirm no test account is needed, and explain the complete/upgrade relationship (see paragraph below) so the reviewer doesn't flag the upgrade product as a duplicate or as pay-to-win escalation.
- [ ] **Cleared for Sale** toggle set to on, with territory/pricing availability chosen.
- [ ] **Family Sharing** toggle decision (on/off) — should be consistent across all 12 (likely on, since these are non-consumable cosmetic/equipment content with no live-service dependency).
- [ ] **App Store Promotional Image** (optional, 1024×1024) if you want any of these featured in a promotional placement.
- [ ] Confirm each Product ID is attached to the correct app record and, where StoreKit Configuration/testing is used locally, matches the same identifiers 1:1 (`design/21` §13.1 lists a local StoreKit Configuration file that must stay in sync).
- [ ] Localized metadata (Display Name + Description) entered for **both** zh-Hans and en-US locales — do not leave either blank; `design/21` §12 explicitly forbids English-only StoreKit titles.
- [ ] Re-verify **App Privacy** answers reflect the current IAP-enabled build rather than the older "no in-app purchases" assumption baked into `docs/app_store_metadata_zh.md`.

### On the "upgrade" products, in reviewer-friendly terms

Each series sells three things, not two independent products plus a discount coupon: a **theme** (cosmetic-only reskin of the 4 heroes, UI, and weapon colorway, no gameplay effect), a **complete arsenal** (theme + a full weapon/armor/chip/pet equipment set with a real stat bonus and unique set effects), and an **upgrade** (equipment set only, no theme). The upgrade exists purely for players who already bought the theme on its own and later decide they also want the equipment: instead of forcing them to buy the $6.99–$8.99 complete bundle and get a theme they already own for free a second time, the upgrade sells just the missing equipment piece at a lower price (e.g. Thunder: theme $1.99 + upgrade $4.99 ≈ complete $6.99, so there's no punishing "pay twice for the same theme" gap). It's the same pattern retailers use for "already own the base, buy the expansion" pricing — not a separate content track, not a subscription, and not required to progress the 99-level campaign.
