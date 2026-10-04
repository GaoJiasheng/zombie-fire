状态：CANDIDATE_FEASIBLE_AWAITING_GATE_C；待Fable签字，游戏数据未写入。

# 资源表 C 候选

§8.4离线假定3★首通，挑战首通优先；非门关每章最多6次，门关刷到R≥1、不限次数、照实列高度；全关P≤1.20E。不是运行时胜率。P(g)/F(g)与消费策略冻结，因子[0.5,2.0]；八把免费武器共用一个升级基价系数。
优化顺序：零硬约束失败 → 非门回刷次数 → Σ|P−E|/E。门次数完整披露，不参与第二目标。
优化前：69/99失败，目标36.608304。
优化后：0/99失败，目标5.832909。

缩放系数与逐字段旧/新对照完整列于同名JSON；所有候选仅在内存模拟。

|曲线|缩放系数/形式|
|---|---|
|first_clear_gold|[-0.5904789993176951, 0.36118861476063413]；existing authored per-level values × exp(a+b*(L-1)/98)|
|kill_gold_mult|[-0.5809884569341294, -0.11215872362581591]；existing authored per-level values × exp(a+b*(L-1)/98)|
|free_unlock_star|1.5928758847033262；existing free star tiers × constant|
|skill_base_xp_costs|[1.185784901025024, 0.9288213240477036, 0.8670328063942269, 0.7805017685283158, 0.7351564065826917]；same five authored cost tiers times positive monotone factors|
|sig_skill_xp_costs|[0.8685544204081754, 1.0027251587060977, 1.3825606696397745, 1.532967605548369, 1.858658068467446]；same five authored cost tiers times positive monotone factors|
|free_weapon_cost|0.964988255913623；all existing free linear upgrade formulas × ONE common base-price factor|

|文件/字段|旧值|候选新值|系数|
|---|---:|---:|---:|
|data/levels.json/0/first_clear_reward/gold|119|66|0.55406183|
|data/levels.json/1/first_clear_reward/gold|143|80|0.55610764|
|data/levels.json/2/first_clear_reward/gold|167|93|0.55816101|
|data/levels.json/3/first_clear_reward/gold|192|108|0.56022197|
|data/levels.json/4/first_clear_reward/gold|216|121|0.56229053|
|data/levels.json/5/first_clear_reward/gold|241|136|0.56436673|
|data/levels.json/6/first_clear_reward/gold|266|151|0.5664506|
|data/levels.json/7/first_clear_reward/gold|291|165|0.56854216|
|data/levels.json/8/first_clear_reward/gold|315|180|0.57064144|
|data/levels.json/9/first_clear_reward/gold|340|195|0.57274848|
|data/levels.json/10/first_clear_reward/gold|366|210|0.57486329|
|data/levels.json/11/first_clear_reward/gold|391|226|0.57698592|
|data/levels.json/12/first_clear_reward/gold|416|241|0.57911638|
|data/levels.json/13/first_clear_reward/gold|442|257|0.58125471|
|data/levels.json/14/first_clear_reward/gold|467|272|0.58340093|
|data/levels.json/15/first_clear_reward/gold|493|289|0.58555508|
|data/levels.json/16/first_clear_reward/gold|519|305|0.58771718|
|data/levels.json/17/first_clear_reward/gold|545|321|0.58988727|
|data/levels.json/18/first_clear_reward/gold|571|338|0.59206537|
|data/levels.json/19/first_clear_reward/gold|597|355|0.59425151|
|data/levels.json/20/first_clear_reward/gold|623|372|0.59644572|
|data/levels.json/21/first_clear_reward/gold|650|389|0.59864804|
|data/levels.json/22/first_clear_reward/gold|676|406|0.60085848|
|data/levels.json/23/first_clear_reward/gold|703|424|0.60307709|
|data/levels.json/24/first_clear_reward/gold|729|441|0.60530389|
|data/levels.json/25/first_clear_reward/gold|756|459|0.60753892|
|data/levels.json/26/first_clear_reward/gold|783|477|0.60978219|
|data/levels.json/27/first_clear_reward/gold|810|496|0.61203375|
|data/levels.json/28/first_clear_reward/gold|837|514|0.61429362|
|data/levels.json/29/first_clear_reward/gold|864|533|0.61656184|
|data/levels.json/30/first_clear_reward/gold|892|552|0.61883843|
|data/levels.json/31/first_clear_reward/gold|919|571|0.62112343|
|data/levels.json/32/first_clear_reward/gold|947|590|0.62341686|
|data/levels.json/33/first_clear_reward/gold|975|610|0.62571877|
|data/levels.json/34/first_clear_reward/gold|1002|629|0.62802917|
|data/levels.json/35/first_clear_reward/gold|1030|649|0.6303481|
|data/levels.json/36/first_clear_reward/gold|1058|669|0.6326756|
|data/levels.json/37/first_clear_reward/gold|1086|690|0.63501169|
|data/levels.json/38/first_clear_reward/gold|1115|711|0.63735641|
|data/levels.json/39/first_clear_reward/gold|1143|731|0.63970978|
|data/levels.json/40/first_clear_reward/gold|1171|752|0.64207184|
|data/levels.json/41/first_clear_reward/gold|1200|773|0.64444263|
|data/levels.json/42/first_clear_reward/gold|1229|795|0.64682217|
|data/levels.json/43/first_clear_reward/gold|1257|816|0.64921049|
|data/levels.json/44/first_clear_reward/gold|1286|838|0.65160764|
|data/levels.json/45/first_clear_reward/gold|1315|860|0.65401363|
|data/levels.json/46/first_clear_reward/gold|1344|882|0.65642851|
|data/levels.json/47/first_clear_reward/gold|1374|905|0.65885231|
|data/levels.json/48/first_clear_reward/gold|1403|928|0.66128505|
|data/levels.json/49/first_clear_reward/gold|1432|950|0.66372678|
|data/levels.json/50/first_clear_reward/gold|1462|974|0.66617752|
|data/levels.json/51/first_clear_reward/gold|1492|998|0.66863732|
|data/levels.json/52/first_clear_reward/gold|1521|1021|0.67110619|
|data/levels.json/53/first_clear_reward/gold|1551|1045|0.67358418|
|data/levels.json/54/first_clear_reward/gold|1581|1069|0.67607132|
|data/levels.json/55/first_clear_reward/gold|1611|1093|0.67856765|
|data/levels.json/56/first_clear_reward/gold|1642|1118|0.68107319|
|data/levels.json/57/first_clear_reward/gold|1672|1143|0.68358798|
|data/levels.json/58/first_clear_reward/gold|1702|1168|0.68611206|
|data/levels.json/59/first_clear_reward/gold|1733|1193|0.68864546|
|data/levels.json/60/first_clear_reward/gold|1764|1219|0.69118821|
|data/levels.json/61/first_clear_reward/gold|1794|1245|0.69374036|
|data/levels.json/62/first_clear_reward/gold|1825|1271|0.69630192|
|data/levels.json/63/first_clear_reward/gold|1856|1297|0.69887295|
|data/levels.json/64/first_clear_reward/gold|1887|1324|0.70145346|
|data/levels.json/65/first_clear_reward/gold|1919|1351|0.70404351|
|data/levels.json/66/first_clear_reward/gold|1950|1378|0.70664312|
|data/levels.json/67/first_clear_reward/gold|1981|1405|0.70925233|
|data/levels.json/68/first_clear_reward/gold|2013|1433|0.71187117|
|data/levels.json/69/first_clear_reward/gold|2044|1460|0.71449968|
|data/levels.json/70/first_clear_reward/gold|2076|1489|0.7171379|
|data/levels.json/71/first_clear_reward/gold|2108|1517|0.71978586|
|data/levels.json/72/first_clear_reward/gold|2140|1546|0.72244359|
|data/levels.json/73/first_clear_reward/gold|2172|1575|0.72511114|
|data/levels.json/74/first_clear_reward/gold|2204|1604|0.72778854|
|data/levels.json/75/first_clear_reward/gold|2237|1634|0.73047583|
|data/levels.json/76/first_clear_reward/gold|2269|1664|0.73317303|
|data/levels.json/77/first_clear_reward/gold|2302|1694|0.7358802|
|data/levels.json/78/first_clear_reward/gold|2334|1724|0.73859736|
|data/levels.json/79/first_clear_reward/gold|2367|1755|0.74132456|
|data/levels.json/80/first_clear_reward/gold|2400|1786|0.74406182|
|data/levels.json/81/first_clear_reward/gold|2433|1817|0.7468092|
|data/levels.json/82/first_clear_reward/gold|2466|1848|0.74956671|
|data/levels.json/83/first_clear_reward/gold|2499|1880|0.75233441|
|data/levels.json/84/first_clear_reward/gold|2532|1912|0.75511233|
|data/levels.json/85/first_clear_reward/gold|2566|1945|0.75790051|
|data/levels.json/86/first_clear_reward/gold|2599|1977|0.76069898|
|data/levels.json/87/first_clear_reward/gold|2633|2010|0.76350778|
|data/levels.json/88/first_clear_reward/gold|2667|2044|0.76632696|
|data/levels.json/89/first_clear_reward/gold|2700|2077|0.76915654|
|data/levels.json/90/first_clear_reward/gold|2734|2111|0.77199657|
|data/levels.json/91/first_clear_reward/gold|2769|2146|0.77484709|
|data/levels.json/92/first_clear_reward/gold|2803|2180|0.77770813|
|data/levels.json/93/first_clear_reward/gold|2837|2215|0.78057974|
|data/levels.json/94/first_clear_reward/gold|2871|2249|0.78346195|
|data/levels.json/95/first_clear_reward/gold|2906|2285|0.78635481|
|data/levels.json/96/first_clear_reward/gold|2940|2320|0.78925834|
|data/levels.json/97/first_clear_reward/gold|2975|2357|0.7921726|
|data/levels.json/98/first_clear_reward/gold|3010|2393|0.79509762|
|data/levels.json/0/reward_gold_mult|0.56|0.31323331|0.5593452|
|data/levels.json/1/reward_gold_mult|0.55|0.30728798|0.55870541|
|data/levels.json/2/reward_gold_mult|0.55|0.30693649|0.55806635|
|data/levels.json/3/reward_gold_mult|0.55|0.30658541|0.55742802|
|data/levels.json/4/reward_gold_mult|0.54|0.30066683|0.55679043|
|data/levels.json/5/reward_gold_mult|0.54|0.30032292|0.55615356|
|data/levels.json/6/reward_gold_mult|0.53|0.29442423|0.55551742|
|data/levels.json/7/reward_gold_mult|0.53|0.29408746|0.554882|
|data/levels.json/8/reward_gold_mult|0.53|0.29375108|0.55424732|
|data/levels.json/9/reward_gold_mult|0.52|0.28787895|0.55361336|
|data/levels.json/10/reward_gold_mult|0.52|0.28754966|0.55298012|
|data/levels.json/11/reward_gold_mult|0.52|0.28722076|0.55234761|
|data/levels.json/12/reward_gold_mult|0.51|0.28137507|0.55171582|
|data/levels.json/13/reward_gold_mult|0.51|0.28105323|0.55108476|
|data/levels.json/14/reward_gold_mult|0.51|0.28073175|0.55045442|
|data/levels.json/15/reward_gold_mult|0.5|0.2749124|0.54982479|
|data/levels.json/16/reward_gold_mult|0.5|0.27459795|0.54919589|
|data/levels.json/17/reward_gold_mult|0.5|0.27428385|0.54856771|
|data/levels.json/18/reward_gold_mult|0.49|0.26849072|0.54794025|
|data/levels.json/19/reward_gold_mult|0.49|0.26818361|0.5473135|
|data/levels.json/20/reward_gold_mult|0.48|0.26240999|0.54668747|
|data/levels.json/21/reward_gold_mult|0.48|0.26210984|0.54606216|
|data/levels.json/22/reward_gold_mult|0.48|0.26181003|0.54543756|
|data/levels.json/23/reward_gold_mult|0.47|0.25606243|0.54481368|
|data/levels.json/24/reward_gold_mult|0.47|0.25576954|0.54419051|
|data/levels.json/25/reward_gold_mult|0.47|0.25547698|0.54356805|
|data/levels.json/26/reward_gold_mult|0.46|0.2497553|0.5429463|
|data/levels.json/27/reward_gold_mult|0.46|0.24946962|0.54232527|
|data/levels.json/28/reward_gold_mult|0.46|0.24918427|0.54170495|
|data/levels.json/29/reward_gold_mult|0.45|0.2434884|0.54108533|
|data/levels.json/30/reward_gold_mult|0.45|0.24320989|0.54046643|
|data/levels.json/31/reward_gold_mult|0.44|0.23753322|0.53984823|
|data/levels.json/32/reward_gold_mult|0.44|0.23726152|0.53923074|
|data/levels.json/33/reward_gold_mult|0.44|0.23699014|0.53861395|
|data/levels.json/34/reward_gold_mult|0.43|0.23133909|0.53799788|
|data/levels.json/35/reward_gold_mult|0.43|0.23107448|0.5373825|
|data/levels.json/36/reward_gold_mult|0.43|0.23081017|0.53676783|
|data/levels.json/37/reward_gold_mult|0.42|0.22518462|0.53615387|
|data/levels.json/38/reward_gold_mult|0.42|0.22492705|0.5355406|
|data/levels.json/39/reward_gold_mult|0.42|0.22466978|0.53492804|
|data/levels.json/40/reward_gold_mult|0.41|0.21906963|0.53431617|
|data/levels.json/41/reward_gold_mult|0.41|0.21881905|0.53370501|
|data/levels.json/42/reward_gold_mult|0.41|0.21856876|0.53309455|
|data/levels.json/43/reward_gold_mult|0.4|0.21299391|0.53248478|
|data/levels.json/44/reward_gold_mult|0.4|0.21275029|0.53187572|
|data/levels.json/45/reward_gold_mult|0.39|0.20719426|0.53126734|
|data/levels.json/46/reward_gold_mult|0.39|0.20695727|0.53065967|
|data/levels.json/47/reward_gold_mult|0.39|0.20672055|0.53005269|
|data/levels.json/48/reward_gold_mult|0.38|0.20118963|0.5294464|
|data/levels.json/49/reward_gold_mult|0.38|0.20095951|0.52884081|
|data/levels.json/50/reward_gold_mult|0.38|0.20072965|0.52823591|
|data/levels.json/51/reward_gold_mult|0.37|0.19522373|0.5276317|
|data/levels.json/52/reward_gold_mult|0.37|0.19500043|0.52702819|
|data/levels.json/53/reward_gold_mult|0.37|0.19477738|0.52642536|
|data/levels.json/54/reward_gold_mult|0.36|0.18929636|0.52582322|
|data/levels.json/55/reward_gold_mult|0.36|0.18907984|0.52522177|
|data/levels.json/56/reward_gold_mult|0.35|0.18361735|0.52462101|
|data/levels.json/57/reward_gold_mult|0.35|0.18340733|0.52402094|
|data/levels.json/58/reward_gold_mult|0.35|0.18319754|0.52342155|
|data/levels.json/59/reward_gold_mult|0.34|0.17775977|0.52282285|
|data/levels.json/60/reward_gold_mult|0.34|0.17755644|0.52222484|
|data/levels.json/61/reward_gold_mult|0.34|0.17735335|0.5216275|
|data/levels.json/62/reward_gold_mult|0.33|0.17194018|0.52103085|
|data/levels.json/63/reward_gold_mult|0.33|0.17174351|0.52043489|
|data/levels.json/64/reward_gold_mult|0.33|0.17154707|0.5198396|
|data/levels.json/65/reward_gold_mult|0.32|0.1661584|0.519245|
|data/levels.json/66/reward_gold_mult|0.32|0.16596834|0.51865108|
|data/levels.json/67/reward_gold_mult|0.32|0.16577851|0.51805783|
|data/levels.json/68/reward_gold_mult|0.31|0.16041423|0.51746526|
|data/levels.json/69/reward_gold_mult|0.31|0.16023075|0.51687338|
|data/levels.json/70/reward_gold_mult|0.3|0.15488465|0.51628217|
|data/levels.json/71/reward_gold_mult|0.3|0.15470749|0.51569163|
|data/levels.json/72/reward_gold_mult|0.3|0.15453053|0.51510177|
|data/levels.json/73/reward_gold_mult|0.29|0.14920865|0.51451259|
|data/levels.json/74/reward_gold_mult|0.29|0.14903798|0.51392408|
|data/levels.json/75/reward_gold_mult|0.29|0.14886751|0.51333624|
|data/levels.json/76/reward_gold_mult|0.28|0.14356974|0.51274907|
|data/levels.json/77/reward_gold_mult|0.28|0.14340552|0.51216258|
|data/levels.json/78/reward_gold_mult|0.28|0.14324149|0.51157676|
|data/levels.json/79/reward_gold_mult|0.27|0.13796773|0.5109916|
|data/levels.json/80/reward_gold_mult|0.27|0.13780992|0.51040712|
|data/levels.json/81/reward_gold_mult|0.26|0.13255406|0.5098233|
|data/levels.json/82/reward_gold_mult|0.26|0.13240244|0.50924016|
|data/levels.json/83/reward_gold_mult|0.26|0.132251|0.50865768|
|data/levels.json/84/reward_gold_mult|0.26|0.13209972|0.50807586|
|data/levels.json/85/reward_gold_mult|0.26|0.13194863|0.50749471|
|data/levels.json/86/reward_gold_mult|0.26|0.1317977|0.50691423|
|data/levels.json/87/reward_gold_mult|0.26|0.13164695|0.50633441|
|data/levels.json/88/reward_gold_mult|0.26|0.13149637|0.50575525|
|data/levels.json/89/reward_gold_mult|0.26|0.13134596|0.50517676|
|data/levels.json/90/reward_gold_mult|0.26|0.13119572|0.50459893|
|data/levels.json/91/reward_gold_mult|0.26|0.13104566|0.50402176|
|data/levels.json/92/reward_gold_mult|0.26|0.13089576|0.50344525|
|data/levels.json/93/reward_gold_mult|0.26|0.13074604|0.50286939|
|data/levels.json/94/reward_gold_mult|0.26|0.13059649|0.5022942|
|data/levels.json/95/reward_gold_mult|0.26|0.13044711|0.50171967|
|data/levels.json/96/reward_gold_mult|0.26|0.1302979|0.50114579|
|data/levels.json/97/reward_gold_mult|0.26|0.13014887|0.50057257|
|data/levels.json/98/reward_gold_mult|0.26|0.13|0.5|
|data/weapons.json/weapon_flamethrower/unlock_cost_star|8|13|1.5928759|
|data/weapons.json/weapon_cryocannon/unlock_cost_star|8|13|1.5928759|
|data/weapons.json/weapon_teslacoil/unlock_cost_star|10|16|1.5928759|
|data/weapons.json/weapon_venomlauncher/unlock_cost_star|8|13|1.5928759|
|data/weapons.json/weapon_railgun/unlock_cost_star|14|22|1.5928759|
|data/weapons.json/weapon_scattergun/unlock_cost_star|9|14|1.5928759|
|data/weapons.json/weapon_plasmacannon/unlock_cost_star|16|25|1.5928759|
|data/armors.json/armor_kevlar/unlock_cost_star|8|13|1.5928759|
|data/armors.json/armor_thermal/unlock_cost_star|8|13|1.5928759|
|data/armors.json/armor_cryo/unlock_cost_star|9|14|1.5928759|
|data/armors.json/armor_faraday/unlock_cost_star|10|16|1.5928759|
|data/armors.json/armor_hazmat/unlock_cost_star|11|18|1.5928759|
|data/armors.json/armor_reactive/unlock_cost_star|14|22|1.5928759|
|data/chips.json/chip_attack/unlock_cost_star|8|13|1.5928759|
|data/chips.json/chip_haste/unlock_cost_star|8|13|1.5928759|
|data/chips.json/chip_crit/unlock_cost_star|9|14|1.5928759|
|data/chips.json/chip_pierce/unlock_cost_star|11|18|1.5928759|
|data/chips.json/chip_health/unlock_cost_star|9|14|1.5928759|
|data/chips.json/chip_guardian/unlock_cost_star|10|16|1.5928759|
|data/chips.json/chip_greed/unlock_cost_star|11|18|1.5928759|
|data/chips.json/chip_element/unlock_cost_star|14|22|1.5928759|
|data/pets.json/pet_turret_drone/unlock_cost_star|8|13|1.5928759|
|data/pets.json/pet_fire_imp/unlock_cost_star|9|14|1.5928759|
|data/pets.json/pet_frost_wisp/unlock_cost_star|10|16|1.5928759|
|data/pets.json/pet_volt_orb/unlock_cost_star|11|18|1.5928759|
|data/pets.json/pet_medic_drone/unlock_cost_star|13|21|1.5928759|
|data/pets.json/pet_collector/unlock_cost_star|14|22|1.5928759|
|data/economy.json/skill_base_xp_costs/0|350|415|1.1857849|
|data/economy.json/skill_base_xp_costs/1|900|836|0.92882132|
|data/economy.json/skill_base_xp_costs/2|2000|1734|0.86703281|
|data/economy.json/skill_base_xp_costs/3|4000|3122|0.78050177|
|data/economy.json/skill_base_xp_costs/4|8500|6249|0.73515641|
|data/economy.json/sig_skill_xp_costs/0|450|391|0.86855442|
|data/economy.json/sig_skill_xp_costs/1|1200|1203|1.0027252|
|data/economy.json/sig_skill_xp_costs/2|2700|3733|1.3825607|
|data/economy.json/sig_skill_xp_costs/3|5400|8278|1.5329676|
|data/economy.json/sig_skill_xp_costs/4|11000|20445|1.8586581|
|data/weapons.json/weapon_autocannon/cost_base_gold|100|96|0.96498826|
|data/weapons.json/weapon_flamethrower/cost_base_gold|180|174|0.96498826|
|data/weapons.json/weapon_cryocannon/cost_base_gold|180|174|0.96498826|
|data/weapons.json/weapon_teslacoil/cost_base_gold|240|232|0.96498826|
|data/weapons.json/weapon_venomlauncher/cost_base_gold|240|232|0.96498826|
|data/weapons.json/weapon_railgun/cost_base_gold|320|309|0.96498826|
|data/weapons.json/weapon_scattergun/cost_base_gold|180|174|0.96498826|
|data/weapons.json/weapon_plasmacannon/cost_base_gold|320|309|0.96498826|

|关卡|rec|E|旧P|新P|新R|新P/E|下限|上限|达标|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
|001|50|65|65|65|1.3000|1.0000|48|78|True|
|002|50|65|69|67|1.3400|1.0308|48|78|True|
|003|50|65|73|71|1.4200|1.0923|48|78|True|
|004|64|65|74|73|1.1406|1.1231|61|78|True|
|005|76|76|81|77|1.0132|1.0132|76|91|True|
|006|53|76|82|81|1.5283|1.0658|51|91|True|
|007|53|76|89|82|1.5472|1.0789|53|91|True|
|008|79|79|96|86|1.0886|1.0886|79|94|True|
|009|79|79|106|93|1.1772|1.1772|79|94|True|
|010|87|87|112|97|1.1149|1.1149|87|104|True|
|011|99|99|116|99|1.0000|1.0000|95|118|True|
|012|108|108|122|105|0.9722|0.9722|103|129|True|
|013|131|131|131|126|0.9618|0.9618|125|157|True|
|014|138|138|141|136|0.9855|0.9855|132|165|True|
|015|147|147|151|150|1.0204|1.0204|147|176|True|
|016|98|147|152|156|1.5918|1.0612|94|176|True|
|017|165|165|166|165|1.0000|1.0000|0|198|True|
|018|185|185|207|202|1.0919|1.0919|0|222|True|
|019|188|188|210|202|1.0745|1.0745|188|225|True|
|020|291|291|291|294|1.0103|1.0103|0|349|True|
|021|164|291|323|296|1.8049|1.0172|156|349|True|
|022|183|291|339|296|1.6175|1.0172|174|349|True|
|023|186|291|355|298|1.6022|1.0241|177|349|True|
|024|201|291|374|299|1.4876|1.0275|191|349|True|
|025|260|291|410|308|1.1846|1.0584|260|349|True|
|026|226|291|410|308|1.3628|1.0584|215|349|True|
|027|195|291|410|317|1.6256|1.0893|195|349|True|
|028|231|291|474|326|1.4113|1.1203|231|349|True|
|029|206|291|509|339|1.6456|1.1649|206|349|True|
|030|332|332|515|351|1.0572|1.0572|332|398|True|
|031|159|332|522|351|2.2075|1.0572|152|398|True|
|032|245|332|530|354|1.4449|1.0663|233|398|True|
|033|228|332|573|354|1.5526|1.0663|217|398|True|
|034|330|332|573|364|1.1030|1.0964|314|398|True|
|035|219|332|648|364|1.6621|1.0964|219|398|True|
|036|225|332|679|374|1.6622|1.1265|214|398|True|
|037|232|332|685|374|1.6121|1.1265|232|398|True|
|038|484|484|710|491|1.0145|1.0145|484|580|True|
|039|533|533|849|535|1.0038|1.0038|0|639|True|
|040|574|574|849|591|1.0296|1.0296|0|688|True|
|041|236|574|880|623|2.6398|1.0854|225|688|True|
|042|375|574|942|642|1.7120|1.1185|357|688|True|
|043|587|587|951|642|1.0937|1.0937|558|704|True|
|044|757|757|957|721|0.9524|0.9524|720|908|True|
|045|655|757|963|810|1.2366|1.0700|655|908|True|
|046|600|757|972|810|1.3500|1.0700|570|908|True|
|047|670|757|983|848|1.2657|1.1202|670|908|True|
|048|663|757|983|881|1.3288|1.1638|663|908|True|
|049|658|757|1008|892|1.3556|1.1783|658|908|True|
|050|868|868|1068|948|1.0922|1.0922|868|1041|True|
|051|431|868|1185|952|2.2088|1.0968|410|1041|True|
|052|349|868|1185|952|2.7278|1.0968|332|1041|True|
|053|427|868|1185|952|2.2295|1.0968|406|1041|True|
|054|359|868|1185|952|2.6518|1.0968|342|1041|True|
|055|950|950|1185|952|1.0021|1.0021|950|1140|True|
|056|354|950|1237|952|2.6893|1.0021|337|1140|True|
|057|990|990|1237|990|1.0000|1.0000|0|1188|True|
|058|503|990|1284|996|1.9801|1.0061|503|1188|True|
|059|562|990|1284|996|1.7722|1.0061|562|1188|True|
|060|990|990|1300|996|1.0061|1.0061|990|1188|True|
|061|990|990|1491|996|1.0061|1.0061|941|1188|True|
|062|250|990|1577|996|3.9840|1.0061|238|1188|True|
|063|576|990|1763|996|1.7292|1.0061|548|1188|True|
|064|955|990|1763|996|1.0429|1.0061|908|1188|True|
|065|1014|1014|1813|1017|1.0030|1.0030|1014|1216|True|
|066|1184|1184|1813|1185|1.0008|1.0008|1125|1420|True|
|067|955|1184|1813|1185|1.2408|1.0008|955|1420|True|
|068|1042|1184|1814|1342|1.2879|1.1334|1042|1420|True|
|069|978|1184|2043|1342|1.3722|1.1334|978|1420|True|
|070|1286|1286|2043|1536|1.1944|1.1944|1286|1543|True|
|071|1146|1286|2202|1536|1.3403|1.1944|1089|1543|True|
|072|1576|1576|2308|1536|0.9746|0.9746|1498|1891|True|
|073|818|1576|2308|1536|1.8778|0.9746|778|1891|True|
|074|2034|2034|2429|2039|1.0025|1.0025|0|2440|True|
|075|1841|2034|2733|2039|1.1076|1.0025|1841|2440|True|
|076|2758|2758|2989|2763|1.0018|1.0018|0|3309|True|
|077|1652|2758|3160|2763|1.6725|1.0018|1652|3309|True|
|078|2226|2758|3160|2763|1.2412|1.0018|2226|3309|True|
|079|2030|2758|3160|2763|1.3611|1.0018|2030|3309|True|
|080|2067|2758|3220|2763|1.3367|1.0018|2067|3309|True|
|081|1096|2758|3270|2763|2.5210|1.0018|1042|3309|True|
|082|1762|2758|3270|2763|1.5681|1.0018|1674|3309|True|
|083|1815|2758|3270|2763|1.5223|1.0018|1725|3309|True|
|084|1265|2758|3271|2763|2.1842|1.0018|1202|3309|True|
|085|2204|2758|3271|2763|1.2536|1.0018|2204|3309|True|
|086|1855|2758|3538|2763|1.4895|1.0018|1763|3309|True|
|087|1857|2758|3639|2763|1.4879|1.0018|1857|3309|True|
|088|1857|2758|3700|2763|1.4879|1.0018|1857|3309|True|
|089|1994|2758|3974|3174|1.5918|1.1508|1994|3309|True|
|090|2751|2758|3994|3198|1.1625|1.1595|2751|3309|True|
|091|1234|2758|4401|3198|2.5916|1.1595|1173|3309|True|
|092|1862|2758|4401|3198|1.7175|1.1595|1769|3309|True|
|093|2266|2758|4404|3198|1.4113|1.1595|2153|3309|True|
|094|1830|2758|4406|3198|1.7475|1.1595|1739|3309|True|
|095|3370|3370|4415|3525|1.0460|1.0460|0|4044|True|
|096|2429|3370|4415|3525|1.4512|1.0460|2308|4044|True|
|097|1863|3370|4415|3525|1.8921|1.0460|1863|4044|True|
|098|2720|3370|5163|3525|1.2960|1.0460|2720|4044|True|
|099|3094|3370|5283|3525|1.1393|1.0460|3094|4044|True|

## 优化前回刷门与预算

状态：离线条件模拟，不代表实际3★通关；未改数据。

# T3 进度闭环

只用假定3★首通，金币按逐敌四舍五入；非Boss波support不计。
§8.4主路径在账户副本内优先挑战首通；非门关每章累计最多6次，门关刷到P≥rec、另记高度；全关上限1.20E。
不计动态召唤、金币卡、付费助推；按现有购买/升级优先级和技能经验成本。
挑战首通+3星一次，无普通首通金币；经验独立计数：挑战首通100%，重复50%/25%。R不是已验证胜率。

design/41 section 8.4: non-gates P>=.95rec (Boss/x7-x9 >=rec), <=6 farms/chapter; gate lower exempt, farm until P>=rec; all P<=1.20E; E=max(65,rec(1..L))

首次R<0.95：None；G1走廊不满足关数：69/99。

包络目标Σ|P−E|/E：36.608304。

回刷总数：10（非门2，门8）；各章非门：{'1': 0, '2': 2, '3': 0, '4': 0, '5': 0, '6': 0, '7': 0, '8': 0, '9': 0, '10': 0}。
门关：[20, 76, 95]；预算后新增门：[]；未刷够门：[]；非门失败：[8, 9, 10, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 75, 86, 87, 88, 89, 90, 91, 92, 93, 94, 96, 97, 98, 99]。

|回刷位置|路线(挑战/普通)|入场P|回刷后P|次数|非门章累计|刷够|八墙关|门高度/路线注记|
|---|---|---:|---:|---:|---:|---|---|---|
|018|017挑, 016挑|169|207|2|2|True|True|非门|
|020|019挑, 018挑, 015挑, 014挑, 013挑, 012挑, 011挑, 010挑|234|291|8|2|True|True|8 / 仅挑战 / Owner fixed gate|

## 门关高度（含无需回刷的固定门）

|门|高度|已刷够|路径|原因|
|---|---:|---|---|---|
|020|8|True|仅挑战|Owner fixed gate|
|076|0|True|可付费（未做运行时验证）|Owner fixed gate|
|095|0|True|可付费（未做运行时验证）|Owner fixed gate|

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|当关/章累计回刷|
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
|001|0|65|50|1.3000|65|1.0000|466|vanguard 1→2; weapon_autocannon 1→3|0/0|
|002|466|69|50|1.3800|65|1.0615|649|vanguard 2→3; weapon_autocannon 3→4; skill_multishot 0→1|0/0|
|003|1115|73|50|1.4600|65|1.1231|757|weapon_cryocannon; weapon_autocannon 4→5; weapon_cryocannon 1→3; skill_pierce 0→1|0/0|
|004|1872|74|64|1.1562|65|1.1385|878|vanguard 3→4; weapon_autocannon 5→6; skill_barrier 0→1; skill_homing 0→1|0/0|
|005|2750|81|76|1.0658|76|1.0658|999|weapon_autocannon 6→7; weapon_cryocannon 3→4; skill_salvo 0→1|0/0|
|006|3749|82|53|1.5472|76|1.0789|1198|armor_kevlar; armor_kevlar 1→3; weapon_autocannon 7→8; weapon_cryocannon 4→5; skill_charge_shot 0→1|0/0|
|007|4947|89|53|1.6792|76|1.1711|1194|armor_kevlar 3→4; vanguard 4→5; weapon_autocannon 8→9; skill_slow_field 0→1; signature 0→1|0/0|
|008|6141|96|79|1.2152|79|1.2152|1501|chip_attack; chip_attack 1→5; weapon_autocannon 9→10; skill_split_shot 0→1|0/0|
|009|7642|106|79|1.3418|79|1.3418|1281|vanguard 5→6; weapon_autocannon 10→11; skill_critical 0→1|0/0|
|010|8923|112|87|1.2874|87|1.2874|1245|armor_kevlar 4→5; weapon_autocannon 11→12; skill_ricochet 0→1|0/0|
|011|10168|116|99|1.1717|99|1.1717|1826|weapon_scattergun; weapon_autocannon 12→13; weapon_scattergun 1→4; skill_multishot 1→2|0/0|
|012|11994|122|108|1.1296|108|1.1296|1926|vanguard 6→7; weapon_autocannon 13→14; weapon_scattergun 4→5|0/0|
|013|13920|131|131|1.0000|131|1.0000|2071|chip_attack 5→6; weapon_cryocannon 5→6; weapon_scattergun 5→6; skill_pierce 1→2|0/0|
|014|15991|141|138|1.0217|138|1.0217|2143|vanguard 7→8; weapon_cryocannon 6→7; weapon_scattergun 6→7; skill_homing 1→2|0/0|
|015|18134|151|147|1.0272|147|1.0272|1393|armor_kevlar 5→6; weapon_scattergun 7→8|0/0|
|016|19527|152|98|1.5510|147|1.0340|2742|weapon_railgun; weapon_railgun 1→4; weapon_scattergun 8→9; skill_barrier 1→2|0/0|
|017|22269|166|165|1.0061|165|1.0061|2719|chip_attack 6→7; weapon_railgun 4→5; weapon_scattergun 9→10; skill_salvo 1→2|0/0|
|018|29437|207|185|1.1189|185|1.1189|2161|vanguard 8→9; weapon_scattergun 12→13|2/2|
|019|31598|210|188|1.1170|188|1.1170|2977|weapon_railgun 5→6; weapon_scattergun 13→14; signature 1→2|0/2|
|020|46779|291|291|1.0000|291|1.0000|3195|armor_kevlar 6→7; vanguard 9→10; weapon_scattergun 16→17|8/2|
|021|49974|323|164|1.9695|291|1.1100|2916|weapon_venomlauncher; weapon_scattergun 17→18; weapon_venomlauncher 1→3|0/0|
|022|52890|339|183|1.8525|291|1.1649|3177|weapon_scattergun 18→19; weapon_venomlauncher 3→4; skill_pierce 2→3|0/0|
|023|56067|355|186|1.9086|291|1.2199|3563|pet_turret_drone 5→6; weapon_scattergun 19→20; weapon_venomlauncher 4→5|0/0|
|024|59630|374|201|1.8607|291|1.2852|3343|weapon_scattergun 20→21; weapon_venomlauncher 5→6; skill_homing 2→3|0/0|
|025|62973|410|260|1.5769|291|1.4089|2321|weapon_venomlauncher 6→8|0/0|
|026|65294|410|226|1.8142|291|1.4089|3935|chip_attack 8→9; weapon_venomlauncher 8→10|0/0|
|027|69229|410|195|2.1026|291|1.4089|3720|weapon_cryocannon 10→11; weapon_scattergun 21→22; skill_barrier 2→3|0/0|
|028|72949|474|231|2.0519|291|1.6289|4002|vanguard 10→11; weapon_scattergun 22→23|0/0|
|029|76951|509|206|2.4709|291|1.7491|4148|weapon_cryocannon 11→12; weapon_scattergun 23→24; skill_salvo 2→3|0/0|
|030|81099|515|332|1.5512|332|1.5512|3328|weapon_scattergun 24→25|0/0|
|031|84427|522|159|3.2830|332|1.5723|4714|weapon_flamethrower; weapon_flamethrower 1→5; weapon_scattergun 25→26|0/0|
|032|89141|530|245|2.1633|332|1.5964|4420|weapon_plasmacannon; pet_turret_drone 6→7; weapon_flamethrower 5→7; weapon_plasmacannon 1→5; skill_charge_shot 2→3|0/0|
|033|93561|573|228|2.5132|332|1.7259|3968|weapon_flamethrower 7→8; weapon_plasmacannon 5→7|0/0|
|034|97529|573|330|1.7364|332|1.7259|4994|armor_kevlar 7→8; weapon_flamethrower 8→9; weapon_scattergun 26→27; skill_slow_field 2→3|0/0|
|035|102523|648|219|2.9589|332|1.9518|3689|vanguard 11→12; weapon_flamethrower 9→10; weapon_plasmacannon 7→8|0/0|
|036|106212|679|225|3.0178|332|2.0452|4999|weapon_flamethrower 10→11; weapon_scattergun 27→28|0/0|
|037|111211|685|232|2.9526|332|2.0633|5600|chip_attack 9→10; weapon_flamethrower 11→12; weapon_scattergun 28→29; signature 2→3|0/0|
|038|116811|710|484|1.4669|484|1.4669|6000|armor_kevlar 8→9; weapon_flamethrower 12→13; weapon_scattergun 29→30|0/0|
|039|122811|849|533|1.5929|533|1.5929|5156|weapon_flamethrower 13→14; weapon_plasmacannon 8→9; weapon_venomlauncher 10→11; skill_split_shot 2→3|0/0|
|040|127967|849|574|1.4791|574|1.4791|6793|weapon_autocannon 14→15; weapon_flamethrower 14→15; weapon_scattergun 30→31|0/0|
|041|134760|880|236|3.7288|574|1.5331|6462|weapon_teslacoil; pet_turret_drone 7→8; weapon_scattergun 31→32; weapon_teslacoil 1→5; skill_critical 2→3|0/0|
|042|141222|942|375|2.5120|574|1.6411|6075|weapon_scattergun 32→33; weapon_teslacoil 5→7|0/0|
|043|147297|951|587|1.6201|587|1.6201|7055|weapon_scattergun 33→34; weapon_teslacoil 7→9; skill_ricochet 2→3|0/0|
|044|154352|957|757|1.2642|757|1.2642|6867|weapon_autocannon 15→16; weapon_scattergun 34→35; weapon_teslacoil 9→10|0/0|
|045|161219|963|655|1.4702|757|1.2721|7042|chip_attack 10→11; weapon_scattergun 35→36; weapon_teslacoil 10→11|0/0|
|046|168261|972|600|1.6200|757|1.2840|6022|weapon_plasmacannon 9→10; weapon_railgun 9→10; weapon_teslacoil 11→12; skill_multishot 3→4|0/0|
|047|174283|983|670|1.4672|757|1.2985|6656|weapon_plasmacannon 10→11; weapon_teslacoil 12→13; weapon_venomlauncher 11→12|0/0|
|048|180939|983|663|1.4827|757|1.2985|7623|armor_kevlar 9→10; weapon_scattergun 36→37; weapon_teslacoil 13→14|0/0|
|049|188562|1008|658|1.5319|757|1.3316|7652|chip_attack 11→12; weapon_scattergun 37→38; weapon_teslacoil 14→15; skill_pierce 3→4|0/0|
|050|196214|1068|868|1.2304|868|1.2304|5724|armor_kevlar 10→11; weapon_scattergun 38→39|0/0|
|051|201938|1185|431|2.7494|868|1.3652|2522|weapon_railgun 10→11|0/0|
|052|204460|1185|349|3.3954|868|1.3652|2819|weapon_plasmacannon 11→12; skill_homing 3→4|0/0|
|053|207279|1185|427|2.7752|868|1.3652|2763|weapon_railgun 11→12|0/0|
|054|210042|1185|359|3.3008|868|1.3652|2807|weapon_cryocannon 12→14|0/0|
|055|212849|1185|950|1.2474|950|1.2474|2897|chip_attack 12→13; weapon_venomlauncher 12→13; skill_barrier 3→4|0/0|
|056|215746|1237|354|3.4944|950|1.3021|2693|weapon_plasmacannon 12→13|0/0|
|057|218439|1237|990|1.2495|990|1.2495|4919|weapon_scattergun 39→40; skill_salvo 3→4|0/0|
|058|223358|1284|503|2.5527|990|1.2970|3084|weapon_railgun 12→13|0/0|
|059|226442|1284|562|2.2847|990|1.2970|2995|pet_turret_drone 8→9; weapon_venomlauncher 13→14|0/0|
|060|229437|1300|990|1.3131|990|1.3131|6400|vanguard 12→13; weapon_scattergun 40→41; skill_charge_shot 3→4|0/0|
|061|235837|1491|990|1.5061|990|1.5061|3770|armor_kevlar 11→12; weapon_plasmacannon 13→14|0/0|
|062|239607|1577|250|6.3080|990|1.5929|3835|chip_attack 13→14; weapon_railgun 13→14; skill_slow_field 3→4|0/0|
|063|243442|1763|576|3.0608|990|1.7808|3555|weapon_autocannon 16→17; weapon_cryocannon 14→15|0/0|
|064|246997|1763|955|1.8461|990|1.7808|3609|vanguard 13→14; weapon_venomlauncher 14→15; skill_split_shot 3→4|0/0|
|065|250606|1813|1014|1.7880|1014|1.7880|4223|weapon_autocannon 17→18; weapon_plasmacannon 14→15|0/0|
|066|254829|1813|1184|1.5312|1184|1.5312|3497|weapon_railgun 14→15; skill_critical 3→4|0/0|
|067|258326|1813|955|1.8984|1184|1.5312|4705|pet_turret_drone 9→10; weapon_cryocannon 15→16; weapon_flamethrower 15→16|0/0|
|068|263031|1814|1042|1.7409|1184|1.5321|4315|vanguard 14→15; weapon_teslacoil 15→16; skill_ricochet 3→4|0/0|
|069|267346|2043|978|2.0890|1184|1.7255|4485|armor_kevlar 12→13; weapon_autocannon 18→19; weapon_venomlauncher 15→16|0/0|
|070|271831|2043|1286|1.5886|1286|1.5886|4298|chip_attack 14→15; weapon_plasmacannon 15→16|0/0|
|071|276129|2202|1146|1.9215|1286|1.7123|3880|weapon_railgun 15→16; signature 3→4|0/0|
|072|280009|2308|1576|1.4645|1576|1.4645|3661|weapon_cryocannon 16→17; weapon_flamethrower 16→17|0/0|
|073|283670|2308|818|2.8215|1576|1.4645|4011|armor_kevlar 13→14; weapon_teslacoil 16→17|0/0|
|074|287681|2429|2034|1.1942|2034|1.1942|4820|vanguard 15→16; weapon_venomlauncher 16→17; skill_multishot 4→5|0/0|
|075|292501|2733|1841|1.4845|2034|1.3437|5072|weapon_scattergun 41→42|0/0|
|076|297573|2989|2758|1.0838|2758|1.0838|4419|chip_attack 15→16; weapon_plasmacannon 16→17|0/0|
|077|301992|3160|1652|1.9128|2758|1.1458|5041|weapon_autocannon 19→20; weapon_railgun 16→17|0/0|
|078|307033|3160|2226|1.4196|2758|1.1458|4662|weapon_cryocannon 17→18; weapon_flamethrower 17→18; skill_pierce 4→5|0/0|
|079|311695|3160|2030|1.5567|2758|1.1458|5091|weapon_scattergun 42→43|0/0|
|080|316786|3220|2067|1.5578|2758|1.1675|5579|weapon_scattergun 43→44|0/0|
|081|322365|3270|1096|2.9836|2758|1.1856|4320|weapon_autocannon 20→21; weapon_teslacoil 17→18; skill_homing 4→5|0/0|
|082|326685|3270|1762|1.8558|2758|1.1856|4313|weapon_autocannon 21→22; weapon_venomlauncher 17→18|0/0|
|083|330998|3270|1815|1.8017|2758|1.1856|5146|pet_turret_drone 10→11; weapon_plasmacannon 17→18|0/0|
|084|336144|3271|1265|2.5858|2758|1.1860|4431|weapon_railgun 17→18|0/0|
|085|340575|3271|2204|1.4841|2758|1.1860|6158|chip_attack 16→17; weapon_scattergun 44→45; skill_barrier 4→5|0/0|
|086|346733|3538|1855|1.9073|2758|1.2828|5850|weapon_scattergun 45→46|0/0|
|087|352583|3639|1857|1.9596|2758|1.3194|5717|weapon_scattergun 46→47; skill_salvo 4→5|0/0|
|088|358300|3700|1857|1.9925|2758|1.3416|5260|armor_kevlar 14→15; vanguard 16→17; weapon_cryocannon 18→19|0/0|
|089|363560|3974|1994|1.9930|2758|1.4409|5703|weapon_scattergun 47→48|0/0|
|090|369263|3994|2751|1.4518|2758|1.4482|4834|vanguard 17→18; weapon_flamethrower 18→19; skill_charge_shot 4→5|0/0|
|091|374097|4401|1234|3.5665|2758|1.5957|4742|weapon_cryocannon 19→20; weapon_teslacoil 18→19|0/0|
|092|378839|4401|1862|2.3636|2758|1.5957|6828|weapon_scattergun 48→49|0/0|
|093|385667|4404|2266|1.9435|2758|1.5968|5903|weapon_scattergun 49→50|0/0|
|094|391570|4406|1830|2.4077|2758|1.5975|6393|pet_turret_drone 11→12; weapon_flamethrower 19→20; weapon_venomlauncher 18→19; signature 4→5|0/0|
|095|397963|4415|3370|1.3101|3370|1.3101|5911|weapon_autocannon 22→23; weapon_plasmacannon 18→19|0/0|
|096|403874|4415|2429|1.8176|3370|1.3101|7903|weapon_railgun 18→19; weapon_teslacoil 19→20|0/0|
|097|411777|4415|1863|2.3698|3370|1.3101|7350|weapon_plasmacannon 19→20; weapon_venomlauncher 19→20; skill_slow_field 4→5|0/0|
|098|419127|5163|2720|1.8982|3370|1.5320|7317|vanguard 18→19; weapon_autocannon 23→24; weapon_railgun 19→20|0/0|
|099|426444|5283|3094|1.7075|3370|1.5677|6337|chip_attack 17→18; weapon_cryocannon 20→21; weapon_flamethrower 20→21|0/0|

## 优化后回刷门与预算

状态：离线条件模拟，不代表实际3★通关；未改数据。

# T3 进度闭环

只用假定3★首通，金币按逐敌四舍五入；非Boss波support不计。
§8.4主路径在账户副本内优先挑战首通；非门关每章累计最多6次，门关刷到P≥rec、另记高度；全关上限1.20E。
不计动态召唤、金币卡、付费助推；按现有购买/升级优先级和技能经验成本。
挑战首通+3星一次，无普通首通金币；经验独立计数：挑战首通100%，重复50%/25%。R不是已验证胜率。

design/41 section 8.4: non-gates P>=.95rec (Boss/x7-x9 >=rec), <=6 farms/chapter; gate lower exempt, farm until P>=rec; all P<=1.20E; E=max(65,rec(1..L))

首次R<0.95：None；G1走廊不满足关数：0/99。

包络目标Σ|P−E|/E：5.832909。

回刷总数：89（非门14，门75）；各章非门：{'1': 0, '2': 6, '3': 0, '4': 2, '5': 2, '6': 0, '7': 4, '8': 0, '9': 0, '10': 0}。
门关：[17, 18, 20, 39, 40, 57, 74, 76, 95]；预算后新增门：[17, 18, 39, 40, 57, 74]；未刷够门：[]；非门失败：[]。

|回刷位置|路线(挑战/普通)|入场P|回刷后P|次数|非门章累计|刷够|八墙关|门高度/路线注记|
|---|---|---:|---:|---:|---:|---|---|---|
|012|011挑, 010挑|100|105|2|2|True|False|非门|
|013|012挑, 009挑, 008挑|107|126|3|5|True|False|非门|
|014|013挑|129|136|1|6|True|False|非门|
|017|016挑|161|165|1|6|True|True|1 / 仅挑战 / challenge-first route still exceeds chapter remaining budget|
|018|017挑, 015挑, 014挑, 007挑, 006挑, 005挑|169|202|6|6|True|True|6 / 仅挑战 / challenge-first route still exceeds chapter remaining budget|
|020|019挑, 018挑, 004挑, 003挑, 002挑, 001挑, 019普, 019普, 019普|203|294|9|6|True|True|9 / 仅挑战 / Owner fixed gate|
|038|037挑, 036挑|470|491|2|2|True|False|非门|
|039|038挑, 035挑, 034挑, 033挑, 032挑|498|535|5|2|True|False|5 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|040|039挑, 031挑, 030挑, 029挑, 028挑, 027挑|541|591|6|2|True|True|6 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|044|043挑, 042挑|689|721|2|2|True|True|非门|
|057|056挑, 055挑, 054挑, 053挑, 052挑, 051挑, 050挑, 049挑, 048挑|952|990|9|0|True|False|9 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|065|064挑, 063挑|996|1017|2|2|True|False|非门|
|066|065挑, 062挑|1034|1185|2|4|True|False|非门|
|074|073挑, 072挑, 071挑, 070挑, 069挑, 068挑, 067挑, 066挑, 061挑, 060挑, 059挑, 058挑, 057挑, 047挑, 046挑, 045挑, 044挑|1536|2039|17|0|True|False|17 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|076|075挑, 074挑, 041挑, 040挑, 026挑, 025挑, 024挑, 023挑, 022挑, 021挑, 020挑, 075普, 075普, 075普, 075普, 075普, 075普|2039|2763|17|0|True|True|17 / 可付费（未做运行时验证） / Owner fixed gate|
|095|094挑, 093挑, 092挑, 091挑, 090挑|3297|3525|5|0|True|False|5 / 可付费（未做运行时验证） / Owner fixed gate|

## 门关高度（含无需回刷的固定门）

|门|高度|已刷够|路径|原因|
|---|---:|---|---|---|
|017|1|True|仅挑战|challenge-first route still exceeds chapter remaining budget|
|018|6|True|仅挑战|challenge-first route still exceeds chapter remaining budget|
|020|9|True|仅挑战|Owner fixed gate|
|039|5|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|040|6|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|057|9|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|074|17|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|076|17|True|可付费（未做运行时验证）|Owner fixed gate|
|095|5|True|可付费（未做运行时验证）|Owner fixed gate|

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|当关/章累计回刷|
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
|001|0|65|50|1.3000|65|1.0000|285|vanguard 1→2; weapon_autocannon 1→2|0/0|
|002|285|67|50|1.3400|65|1.0308|381|vanguard 2→3; weapon_autocannon 2→3; skill_multishot 0→1|0/0|
|003|666|71|50|1.4200|65|1.0923|392|weapon_autocannon 3→4; skill_pierce 0→1|0/0|
|004|1058|73|64|1.1406|65|1.1231|482|vanguard 3→4; weapon_autocannon 4→5; skill_homing 0→1|0/0|
|005|1540|77|76|1.0132|76|1.0132|528|weapon_cryocannon; weapon_autocannon 5→6; weapon_cryocannon 1→2; skill_barrier 0→1|0/0|
|006|2068|81|53|1.5283|76|1.0658|688|weapon_autocannon 6→7; skill_salvo 0→1|0/0|
|007|2756|82|53|1.5472|76|1.0789|655|weapon_autocannon 7→8; weapon_cryocannon 2→3; skill_charge_shot 0→1; signature 0→1|0/0|
|008|3411|86|79|1.0886|79|1.0886|865|weapon_autocannon 8→9; weapon_cryocannon 3→4; skill_slow_field 0→1|0/0|
|009|4276|93|79|1.1772|79|1.1772|663|armor_kevlar; weapon_autocannon 9→10; skill_split_shot 0→1|0/0|
|010|4939|97|87|1.1149|87|1.1149|699|weapon_autocannon 10→11; skill_critical 0→1|0/0|
|011|5638|99|99|1.0000|99|1.0000|978|armor_kevlar 1→2; weapon_autocannon 11→12; skill_ricochet 0→1|0/0|
|012|7888|105|108|0.9722|108|0.9722|1076|chip_attack 3→4; weapon_autocannon 13→14; skill_pierce 1→2|2/2|
|013|10997|126|131|0.9618|131|0.9618|1209|weapon_scattergun; chip_attack 4→5; weapon_scattergun 1→4; skill_salvo 1→2|3/5|
|014|13174|136|138|0.9855|138|0.9855|1256|weapon_autocannon 15→16; skill_charge_shot 1→2|1/6|
|015|14430|150|147|1.0204|147|1.0204|785|weapon_autocannon 16→17; skill_slow_field 1→2|0/6|
|016|15215|156|98|1.5918|147|1.0612|1488|armor_kevlar 4→5; vanguard 5→6; weapon_scattergun 4→5; skill_split_shot 1→2|0/6|
|017|17902|165|165|1.0000|165|1.0000|1505|weapon_autocannon 18→19; skill_ricochet 1→2|1/6|
|018|23582|202|185|1.0919|185|1.0919|1177|pet_turret_drone 3→4; weapon_railgun 3→4|6/6|
|019|24759|202|188|1.0745|188|1.0745|1693|pet_turret_drone 4→5; weapon_autocannon 20→21|0/6|
|020|33921|294|291|1.0103|291|1.0103|1759|weapon_autocannon 24→25|9/6|
|021|35680|296|164|1.8049|291|1.0172|1619|weapon_venomlauncher; armor_kevlar 6→7; weapon_venomlauncher 1→4|0/0|
|022|37299|296|183|1.6175|291|1.0172|1784|weapon_autocannon 25→26; skill_salvo 2→3|0/0|
|023|39083|298|186|1.6022|291|1.0241|2035|pet_turret_drone 5→6; weapon_venomlauncher 4→6|0/0|
|024|41118|299|201|1.4876|291|1.0275|1860|weapon_autocannon 26→27; skill_charge_shot 2→3|0/0|
|025|42978|308|260|1.1846|291|1.0584|1318|weapon_railgun 5→6|0/0|
|026|44296|308|226|1.3628|291|1.0584|2142|chip_attack 8→9; weapon_autocannon 27→28; skill_slow_field 2→3|0/0|
|027|46438|317|195|1.6256|291|1.0893|2018|weapon_autocannon 28→29|0/0|
|028|48456|326|231|1.4113|291|1.1203|2261|weapon_autocannon 29→30; skill_split_shot 2→3|0/0|
|029|50717|339|206|1.6456|291|1.1649|2308|armor_kevlar 7→8; weapon_autocannon 30→31|0/0|
|030|53025|351|332|1.0572|332|1.0572|1850|weapon_scattergun 6→7; weapon_venomlauncher 6→7|0/0|
|031|54875|351|159|2.2075|332|1.0572|2603|weapon_flamethrower; pet_turret_drone 6→7; weapon_flamethrower 1→6; skill_critical 2→3|0/0|
|032|57478|354|245|1.4449|332|1.0663|2417|weapon_plasmacannon; weapon_flamethrower 6→7; weapon_plasmacannon 1→4|0/0|
|033|59895|354|228|1.5526|332|1.0663|2227|weapon_autocannon 31→32; skill_ricochet 2→3|0/0|
|034|62122|364|330|1.1030|332|1.0964|2803|weapon_flamethrower 7→8; weapon_plasmacannon 4→6|0/0|
|035|64925|364|219|1.6621|332|1.0964|2102|chip_attack 9→10; weapon_plasmacannon 6→7|0/0|
|036|67027|374|225|1.6622|332|1.1265|2722|weapon_flamethrower 8→9; weapon_railgun 6→7|0/0|
|037|69749|374|232|1.6121|332|1.1265|3202|weapon_autocannon 32→33; weapon_flamethrower 9→10; signature 2→3|0/0|
|038|77557|491|484|1.0145|484|1.0145|3359|weapon_cryocannon 7→8; weapon_flamethrower 10→11; weapon_venomlauncher 7→8; skill_multishot 3→4|2/2|
|039|90734|535|533|1.0038|533|1.0038|2872|weapon_autocannon 37→38|5/2|
|040|104235|591|574|1.0296|574|1.0296|3855|vanguard 9→10; weapon_flamethrower 11→12; weapon_venomlauncher 9→10|6/2|
|041|108090|623|236|2.6398|574|1.0854|3613|weapon_teslacoil; chip_attack 10→11; weapon_teslacoil 1→6; skill_salvo 3→4|0/0|
|042|111703|642|375|1.7120|574|1.1185|3395|weapon_scattergun 8→9; weapon_teslacoil 6→8|0/0|
|043|115098|642|587|1.0937|587|1.0937|3837|weapon_autocannon 39→40; weapon_teslacoil 8→9; skill_charge_shot 3→4|0/0|
|044|124599|721|757|0.9524|757|0.9524|3794|vanguard 10→11; weapon_autocannon 42→43; skill_slow_field 3→4|2/2|
|045|128393|810|655|1.2366|757|1.0700|3947|weapon_plasmacannon 9→10; weapon_teslacoil 9→10|0/2|
|046|132340|810|600|1.3500|757|1.0700|3449|armor_kevlar 9→10; weapon_autocannon 43→44; skill_split_shot 3→4|0/2|
|047|135789|848|670|1.2657|757|1.1202|3718|pet_turret_drone 7→8; weapon_autocannon 44→45|0/2|
|048|139507|881|663|1.3288|757|1.1638|4270|pet_turret_drone 8→9; weapon_railgun 9→10; weapon_teslacoil 10→11|0/2|
|049|143777|892|658|1.3556|757|1.1783|4156|chip_attack 11→12; weapon_autocannon 45→46; skill_critical 3→4|0/2|
|050|147933|948|868|1.0922|868|1.0922|3225|weapon_autocannon 46→47|0/2|
|051|151158|952|431|2.2088|868|1.0968|1526|weapon_cryocannon 10→11|0/0|
|052|152684|952|349|2.7278|868|1.0968|1709|weapon_venomlauncher 10→11; skill_ricochet 3→4|0/0|
|053|154393|952|427|2.2295|868|1.0968|1670|weapon_plasmacannon 10→11|0/0|
|054|156063|952|359|2.6518|868|1.0968|1708|weapon_scattergun 9→10|0/0|
|055|157771|952|950|1.0021|950|1.0021|1733|weapon_railgun 10→11|0/0|
|056|159504|952|354|2.6893|950|1.0021|1657|weapon_cryocannon 11→12|0/0|
|057|173832|990|990|1.0000|990|1.0000|2827|weapon_autocannon 49→50; skill_pierce 4→5|9/0|
|058|176659|996|503|1.9801|990|1.0061|1886|weapon_venomlauncher 11→12|0/0|
|059|178545|996|562|1.7722|990|1.0061|1839|weapon_cryocannon 12→13|0/0|
|060|180384|996|990|1.0061|990|1.0061|3621|weapon_flamethrower 12→13; weapon_plasmacannon 11→12; skill_homing 4→5|0/0|
|061|184005|996|990|1.0061|990|1.0061|2258|weapon_teslacoil 12→13|0/0|
|062|186263|996|250|3.9840|990|1.0061|2296|weapon_railgun 11→12|0/0|
|063|188559|996|576|1.7292|990|1.0061|2165|weapon_venomlauncher 12→13|0/0|
|064|190724|996|955|1.0429|990|1.0061|2184|armor_kevlar 11→12; weapon_scattergun 11→12; skill_barrier 4→5|0/0|
|065|194689|1017|1014|1.0030|1014|1.0030|2536|pet_turret_drone 10→11; weapon_cryocannon 13→14|2/2|
|066|199488|1185|1184|1.0008|1184|1.0008|2156|weapon_flamethrower 13→14|2/4|
|067|201644|1185|955|1.2408|1184|1.0008|2837|weapon_plasmacannon 12→13; skill_charge_shot 4→5|0/4|
|068|204481|1342|1042|1.2879|1184|1.1334|2593|weapon_railgun 12→13|0/4|
|069|207074|1342|978|1.3722|1184|1.1334|2704|chip_attack 14→15; weapon_teslacoil 13→14|0/4|
|070|209778|1536|1286|1.1944|1286|1.1944|2637|weapon_venomlauncher 13→14; skill_slow_field 4→5|0/4|
|071|212415|1536|1146|1.3403|1286|1.1944|2402|weapon_plasmacannon 13→14|0/0|
|072|214817|1536|1576|0.9746|1576|0.9746|2297|weapon_scattergun 12→13; skill_split_shot 4→5|0/0|
|073|217114|1536|818|1.8778|1576|0.9746|2529|weapon_railgun 13→14|0/0|
|074|246321|2039|2034|1.0025|2034|1.0025|2945|weapon_flamethrower 15→16; weapon_scattergun 14→15|17/0|
|075|249266|2039|1841|1.1076|2034|1.0025|3066|weapon_teslacoil 15→16|0/0|
|076|279592|2763|2758|1.0018|2758|1.0018|2773|weapon_flamethrower 16→17|17/0|
|077|282365|2763|1652|1.6725|2758|1.0018|3085|weapon_railgun 15→16|0/0|
|078|285450|2763|2226|1.2412|2758|1.0018|2858|weapon_teslacoil 16→17|0/0|
|079|288308|2763|2030|1.3611|2758|1.0018|3162|weapon_venomlauncher 16→17|0/0|
|080|291470|2763|2067|1.3367|2758|1.0018|3414|weapon_plasmacannon 16→17|0/0|
|081|294884|2763|1096|2.5210|2758|1.0018|2758|weapon_railgun 16→17|0/0|
|082|297642|2763|1762|1.5681|2758|1.0018|2789|weapon_cryocannon 17→18|0/0|
|083|300431|2763|1815|1.5223|2758|1.0018|3258|weapon_flamethrower 17→18; weapon_scattergun 16→17|0/0|
|084|303689|2763|1265|2.1842|2758|1.0018|2868|weapon_teslacoil 17→18|0/0|
|085|306557|2763|2204|1.2536|2758|1.0018|3761|weapon_venomlauncher 17→18|0/0|
|086|310318|2763|1855|1.4895|2758|1.0018|3573|weapon_plasmacannon 17→18|0/0|
|087|313891|2763|1857|1.4879|2758|1.0018|3558|weapon_railgun 17→18|0/0|
|088|317449|2763|1857|1.4879|2758|1.0018|3339|vanguard 17→18; weapon_cryocannon 18→19|0/0|
|089|320788|3174|1994|1.5918|2758|1.1508|3596|pet_turret_drone 15→16; weapon_flamethrower 18→19|0/0|
|090|324384|3198|2751|1.1625|2758|1.1595|3121|weapon_teslacoil 18→19|0/0|
|091|327505|3198|1234|2.5916|2758|1.1595|3125|weapon_venomlauncher 18→19|0/0|
|092|330630|3198|1862|1.7175|2758|1.1595|4236|weapon_plasmacannon 18→19|0/0|
|093|334866|3198|2266|1.4113|2758|1.1595|3730|weapon_railgun 18→19|0/0|
|094|338596|3198|1830|1.7475|2758|1.1595|3989|vanguard 18→19; weapon_cryocannon 19→20|0/0|
|095|350057|3525|3370|1.0460|3370|1.0460|3771|weapon_teslacoil 19→20|5/0|
|096|353828|3525|2429|1.4512|3370|1.0460|4755|weapon_scattergun 17→18; weapon_venomlauncher 19→20|0/0|
|097|358583|3525|1863|1.8921|3370|1.0460|4464|weapon_plasmacannon 19→20|0/0|
|098|363047|3525|2720|1.2960|3370|1.0460|4534|weapon_railgun 19→20|0/0|
|099|367581|3525|3094|1.1393|3370|1.0460|4073|weapon_cryocannon 20→21; weapon_scattergun 18→19|0/0|
