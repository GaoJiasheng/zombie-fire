状态：SEARCH_CANDIDATE_NOT_YET_FEASIBLE；待Fable签字，游戏数据未写入。

# 资源表 C 候选

§8.4离线假定3★首通，挑战首通优先；非门关每章最多6次，门关刷到R≥1、不限次数、照实列高度；全关P≤1.20E。不是运行时胜率。P(g)/F(g)与消费策略冻结，因子[0.5,2.0]；八把免费武器共用一个升级基价系数。
优化顺序：零硬约束失败 → 非门回刷次数 → Σ|P−E|/E。门次数完整披露，不参与第二目标。
优化前：69/99失败，目标36.608304。
优化后：9/99失败，目标10.091418。

缩放系数与逐字段旧/新对照完整列于同名JSON；所有候选仅在内存模拟。

|曲线|缩放系数/形式|
|---|---|
|first_clear_gold|[-0.49315434976331196, 0.011894505347973927]；existing authored per-level values × exp(a+b*(L-1)/98)|
|kill_gold_mult|[-0.4910044200090515, -0.029355025985040084]；existing authored per-level values × exp(a+b*(L-1)/98)|
|free_unlock_star|1.2451682810355265；existing free star tiers × constant|
|skill_base_xp_costs|[0.6623715678431924, 0.8900168757520964, 0.9321832020632573, 1.1303891020402654, 1.3478349257096396]；same five authored cost tiers times positive monotone factors|
|sig_skill_xp_costs|[0.5582649725074463, 0.8266266896932006, 0.988975704299648, 0.9925952342232989, 1.0035285009048651]；same five authored cost tiers times positive monotone factors|
|free_weapon_cost|2.0；all existing free linear upgrade formulas × ONE common base-price factor|

|文件/字段|旧值|候选新值|系数|
|---|---:|---:|---:|
|data/levels.json/0/first_clear_reward/gold|119|73|0.610697|
|data/levels.json/1/first_clear_reward/gold|143|87|0.61077113|
|data/levels.json/2/first_clear_reward/gold|167|102|0.61084526|
|data/levels.json/3/first_clear_reward/gold|192|117|0.61091941|
|data/levels.json/4/first_clear_reward/gold|216|132|0.61099356|
|data/levels.json/5/first_clear_reward/gold|241|147|0.61106772|
|data/levels.json/6/first_clear_reward/gold|266|163|0.61114189|
|data/levels.json/7/first_clear_reward/gold|291|178|0.61121607|
|data/levels.json/8/first_clear_reward/gold|315|193|0.61129026|
|data/levels.json/9/first_clear_reward/gold|340|208|0.61136446|
|data/levels.json/10/first_clear_reward/gold|366|224|0.61143867|
|data/levels.json/11/first_clear_reward/gold|391|239|0.61151289|
|data/levels.json/12/first_clear_reward/gold|416|254|0.61158711|
|data/levels.json/13/first_clear_reward/gold|442|270|0.61166135|
|data/levels.json/14/first_clear_reward/gold|467|286|0.61173559|
|data/levels.json/15/first_clear_reward/gold|493|302|0.61180984|
|data/levels.json/16/first_clear_reward/gold|519|318|0.6118841|
|data/levels.json/17/first_clear_reward/gold|545|334|0.61195837|
|data/levels.json/18/first_clear_reward/gold|571|349|0.61203265|
|data/levels.json/19/first_clear_reward/gold|597|365|0.61210694|
|data/levels.json/20/first_clear_reward/gold|623|381|0.61218124|
|data/levels.json/21/first_clear_reward/gold|650|398|0.61225554|
|data/levels.json/22/first_clear_reward/gold|676|414|0.61232986|
|data/levels.json/23/first_clear_reward/gold|703|431|0.61240418|
|data/levels.json/24/first_clear_reward/gold|729|446|0.61247852|
|data/levels.json/25/first_clear_reward/gold|756|463|0.61255286|
|data/levels.json/26/first_clear_reward/gold|783|480|0.61262721|
|data/levels.json/27/first_clear_reward/gold|810|496|0.61270157|
|data/levels.json/28/first_clear_reward/gold|837|513|0.61277594|
|data/levels.json/29/first_clear_reward/gold|864|530|0.61285032|
|data/levels.json/30/first_clear_reward/gold|892|547|0.61292471|
|data/levels.json/31/first_clear_reward/gold|919|563|0.61299911|
|data/levels.json/32/first_clear_reward/gold|947|581|0.61307351|
|data/levels.json/33/first_clear_reward/gold|975|598|0.61314793|
|data/levels.json/34/first_clear_reward/gold|1002|614|0.61322235|
|data/levels.json/35/first_clear_reward/gold|1030|632|0.61329678|
|data/levels.json/36/first_clear_reward/gold|1058|649|0.61337122|
|data/levels.json/37/first_clear_reward/gold|1086|666|0.61344568|
|data/levels.json/38/first_clear_reward/gold|1115|684|0.61352014|
|data/levels.json/39/first_clear_reward/gold|1143|701|0.6135946|
|data/levels.json/40/first_clear_reward/gold|1171|719|0.61366908|
|data/levels.json/41/first_clear_reward/gold|1200|736|0.61374357|
|data/levels.json/42/first_clear_reward/gold|1229|754|0.61381807|
|data/levels.json/43/first_clear_reward/gold|1257|772|0.61389257|
|data/levels.json/44/first_clear_reward/gold|1286|790|0.61396709|
|data/levels.json/45/first_clear_reward/gold|1315|807|0.61404161|
|data/levels.json/46/first_clear_reward/gold|1344|825|0.61411614|
|data/levels.json/47/first_clear_reward/gold|1374|844|0.61419068|
|data/levels.json/48/first_clear_reward/gold|1403|862|0.61426523|
|data/levels.json/49/first_clear_reward/gold|1432|880|0.61433979|
|data/levels.json/50/first_clear_reward/gold|1462|898|0.61441436|
|data/levels.json/51/first_clear_reward/gold|1492|917|0.61448894|
|data/levels.json/52/first_clear_reward/gold|1521|935|0.61456352|
|data/levels.json/53/first_clear_reward/gold|1551|953|0.61463812|
|data/levels.json/54/first_clear_reward/gold|1581|972|0.61471272|
|data/levels.json/55/first_clear_reward/gold|1611|990|0.61478734|
|data/levels.json/56/first_clear_reward/gold|1642|1010|0.61486196|
|data/levels.json/57/first_clear_reward/gold|1672|1028|0.61493659|
|data/levels.json/58/first_clear_reward/gold|1702|1047|0.61501123|
|data/levels.json/59/first_clear_reward/gold|1733|1066|0.61508588|
|data/levels.json/60/first_clear_reward/gold|1764|1085|0.61516054|
|data/levels.json/61/first_clear_reward/gold|1794|1104|0.61523521|
|data/levels.json/62/first_clear_reward/gold|1825|1123|0.61530989|
|data/levels.json/63/first_clear_reward/gold|1856|1142|0.61538457|
|data/levels.json/64/first_clear_reward/gold|1887|1161|0.61545927|
|data/levels.json/65/first_clear_reward/gold|1919|1181|0.61553397|
|data/levels.json/66/first_clear_reward/gold|1950|1200|0.61560869|
|data/levels.json/67/first_clear_reward/gold|1981|1220|0.61568341|
|data/levels.json/68/first_clear_reward/gold|2013|1240|0.61575814|
|data/levels.json/69/first_clear_reward/gold|2044|1259|0.61583288|
|data/levels.json/70/first_clear_reward/gold|2076|1279|0.61590763|
|data/levels.json/71/first_clear_reward/gold|2108|1298|0.61598239|
|data/levels.json/72/first_clear_reward/gold|2140|1318|0.61605716|
|data/levels.json/73/first_clear_reward/gold|2172|1338|0.61613194|
|data/levels.json/74/first_clear_reward/gold|2204|1358|0.61620672|
|data/levels.json/75/first_clear_reward/gold|2237|1379|0.61628152|
|data/levels.json/76/first_clear_reward/gold|2269|1399|0.61635632|
|data/levels.json/77/first_clear_reward/gold|2302|1419|0.61643113|
|data/levels.json/78/first_clear_reward/gold|2334|1439|0.61650596|
|data/levels.json/79/first_clear_reward/gold|2367|1459|0.61658079|
|data/levels.json/80/first_clear_reward/gold|2400|1480|0.61665563|
|data/levels.json/81/first_clear_reward/gold|2433|1501|0.61673048|
|data/levels.json/82/first_clear_reward/gold|2466|1521|0.61680534|
|data/levels.json/83/first_clear_reward/gold|2499|1542|0.6168802|
|data/levels.json/84/first_clear_reward/gold|2532|1562|0.61695508|
|data/levels.json/85/first_clear_reward/gold|2566|1583|0.61702997|
|data/levels.json/86/first_clear_reward/gold|2599|1604|0.61710486|
|data/levels.json/87/first_clear_reward/gold|2633|1625|0.61717977|
|data/levels.json/88/first_clear_reward/gold|2667|1646|0.61725468|
|data/levels.json/89/first_clear_reward/gold|2700|1667|0.6173296|
|data/levels.json/90/first_clear_reward/gold|2734|1688|0.61740453|
|data/levels.json/91/first_clear_reward/gold|2769|1710|0.61747947|
|data/levels.json/92/first_clear_reward/gold|2803|1731|0.61755442|
|data/levels.json/93/first_clear_reward/gold|2837|1752|0.61762938|
|data/levels.json/94/first_clear_reward/gold|2871|1773|0.61770435|
|data/levels.json/95/first_clear_reward/gold|2906|1795|0.61777933|
|data/levels.json/96/first_clear_reward/gold|2940|1816|0.61785431|
|data/levels.json/97/first_clear_reward/gold|2975|1838|0.61792931|
|data/levels.json/98/first_clear_reward/gold|3010|1860|0.61800431|
|data/levels.json/0/reward_gold_mult|0.56|0.34272637|0.61201137|
|data/levels.json/1/reward_gold_mult|0.55|0.33650544|0.61182807|
|data/levels.json/2/reward_gold_mult|0.55|0.33640466|0.61164483|
|data/levels.json/3/reward_gold_mult|0.55|0.33630391|0.61146165|
|data/levels.json/4/reward_gold_mult|0.54|0.3300904|0.61127852|
|data/levels.json/5/reward_gold_mult|0.54|0.32999154|0.61109544|
|data/levels.json/6/reward_gold_mult|0.53|0.32378358|0.61091242|
|data/levels.json/7/reward_gold_mult|0.53|0.32368661|0.61072946|
|data/levels.json/8/reward_gold_mult|0.53|0.32358967|0.61054654|
|data/levels.json/9/reward_gold_mult|0.52|0.31738912|0.61036369|
|data/levels.json/10/reward_gold_mult|0.52|0.31729406|0.61018089|
|data/levels.json/11/reward_gold_mult|0.52|0.31719903|0.60999814|
|data/levels.json/12/reward_gold_mult|0.51|0.31100588|0.60981545|
|data/levels.json/13/reward_gold_mult|0.51|0.31091273|0.60963281|
|data/levels.json/14/reward_gold_mult|0.51|0.31081962|0.60945023|
|data/levels.json/15/reward_gold_mult|0.5|0.30463385|0.6092677|
|data/levels.json/16/reward_gold_mult|0.5|0.30454261|0.60908523|
|data/levels.json/17/reward_gold_mult|0.5|0.3044514|0.60890281|
|data/levels.json/18/reward_gold_mult|0.49|0.29827302|0.60872044|
|data/levels.json/19/reward_gold_mult|0.49|0.29818369|0.60853813|
|data/levels.json/20/reward_gold_mult|0.48|0.29201082|0.60835588|
|data/levels.json/21/reward_gold_mult|0.48|0.29192337|0.60817368|
|data/levels.json/22/reward_gold_mult|0.48|0.29183594|0.60799153|
|data/levels.json/23/reward_gold_mult|0.47|0.28567044|0.60780944|
|data/levels.json/24/reward_gold_mult|0.47|0.28558488|0.6076274|
|data/levels.json/25/reward_gold_mult|0.47|0.28549935|0.60744542|
|data/levels.json/26/reward_gold_mult|0.46|0.27934121|0.6072635|
|data/levels.json/27/reward_gold_mult|0.46|0.27925755|0.60708162|
|data/levels.json/28/reward_gold_mult|0.46|0.27917391|0.6068998|
|data/levels.json/29/reward_gold_mult|0.45|0.27302312|0.60671804|
|data/levels.json/30/reward_gold_mult|0.45|0.27294135|0.60653633|
|data/levels.json/31/reward_gold_mult|0.44|0.26679606|0.60635467|
|data/levels.json/32/reward_gold_mult|0.44|0.26671615|0.60617307|
|data/levels.json/33/reward_gold_mult|0.44|0.26663627|0.60599153|
|data/levels.json/34/reward_gold_mult|0.43|0.26049831|0.60581003|
|data/levels.json/35/reward_gold_mult|0.43|0.2604203|0.6056286|
|data/levels.json/36/reward_gold_mult|0.43|0.2603423|0.60544721|
|data/levels.json/37/reward_gold_mult|0.42|0.25421167|0.60526588|
|data/levels.json/38/reward_gold_mult|0.42|0.25413554|0.60508461|
|data/levels.json/39/reward_gold_mult|0.42|0.25405942|0.60490339|
|data/levels.json/40/reward_gold_mult|0.41|0.24793611|0.60472222|
|data/levels.json/41/reward_gold_mult|0.41|0.24786186|0.60454111|
|data/levels.json/42/reward_gold_mult|0.41|0.24778762|0.60436005|
|data/levels.json/43/reward_gold_mult|0.4|0.24167162|0.60417905|
|data/levels.json/44/reward_gold_mult|0.4|0.24159924|0.6039981|
|data/levels.json/45/reward_gold_mult|0.39|0.23548871|0.6038172|
|data/levels.json/46/reward_gold_mult|0.39|0.23541818|0.60363636|
|data/levels.json/47/reward_gold_mult|0.39|0.23534767|0.60345558|
|data/levels.json/48/reward_gold_mult|0.38|0.22924444|0.60327484|
|data/levels.json/49/reward_gold_mult|0.38|0.22917578|0.60309417|
|data/levels.json/50/reward_gold_mult|0.38|0.22910715|0.60291354|
|data/levels.json/51/reward_gold_mult|0.37|0.2230112|0.60273297|
|data/levels.json/52/reward_gold_mult|0.37|0.22294441|0.60255245|
|data/levels.json/53/reward_gold_mult|0.37|0.22287764|0.60237199|
|data/levels.json/54/reward_gold_mult|0.36|0.21678897|0.60219158|
|data/levels.json/55/reward_gold_mult|0.36|0.21672404|0.60201123|
|data/levels.json/56/reward_gold_mult|0.35|0.21064083|0.60183093|
|data/levels.json/57/reward_gold_mult|0.35|0.21057774|0.60165068|
|data/levels.json/58/reward_gold_mult|0.35|0.21051467|0.60147049|
|data/levels.json/59/reward_gold_mult|0.34|0.20443872|0.60129035|
|data/levels.json/60/reward_gold_mult|0.34|0.20437749|0.60111027|
|data/levels.json/61/reward_gold_mult|0.34|0.20431628|0.60093024|
|data/levels.json/62/reward_gold_mult|0.33|0.19824759|0.60075026|
|data/levels.json/63/reward_gold_mult|0.33|0.19818821|0.60057034|
|data/levels.json/64/reward_gold_mult|0.33|0.19812886|0.60039047|
|data/levels.json/65/reward_gold_mult|0.32|0.19206741|0.60021066|
|data/levels.json/66/reward_gold_mult|0.32|0.19200989|0.6000309|
|data/levels.json/67/reward_gold_mult|0.32|0.19195238|0.59985119|
|data/levels.json/68/reward_gold_mult|0.31|0.18589818|0.59967154|
|data/levels.json/69/reward_gold_mult|0.31|0.1858425|0.59949194|
|data/levels.json/70/reward_gold_mult|0.3|0.17979372|0.59931239|
|data/levels.json/71/reward_gold_mult|0.3|0.17973987|0.5991329|
|data/levels.json/72/reward_gold_mult|0.3|0.17968604|0.59895346|
|data/levels.json/73/reward_gold_mult|0.29|0.17364448|0.59877408|
|data/levels.json/74/reward_gold_mult|0.29|0.17359248|0.59859475|
|data/levels.json/75/reward_gold_mult|0.29|0.17354049|0.59841547|
|data/levels.json/76/reward_gold_mult|0.28|0.16750615|0.59823625|
|data/levels.json/77/reward_gold_mult|0.28|0.16745598|0.59805708|
|data/levels.json/78/reward_gold_mult|0.28|0.16740583|0.59787796|
|data/levels.json/79/reward_gold_mult|0.27|0.1613787|0.5976989|
|data/levels.json/80/reward_gold_mult|0.27|0.16133037|0.59751989|
|data/levels.json/81/reward_gold_mult|0.26|0.15530864|0.59734094|
|data/levels.json/82/reward_gold_mult|0.26|0.15526213|0.59716203|
|data/levels.json/83/reward_gold_mult|0.26|0.15521563|0.59698319|
|data/levels.json/84/reward_gold_mult|0.26|0.15516914|0.59680439|
|data/levels.json/85/reward_gold_mult|0.26|0.15512267|0.59662565|
|data/levels.json/86/reward_gold_mult|0.26|0.15507621|0.59644696|
|data/levels.json/87/reward_gold_mult|0.26|0.15502977|0.59626833|
|data/levels.json/88/reward_gold_mult|0.26|0.15498334|0.59608975|
|data/levels.json/89/reward_gold_mult|0.26|0.15493692|0.59591122|
|data/levels.json/90/reward_gold_mult|0.26|0.15489052|0.59573275|
|data/levels.json/91/reward_gold_mult|0.26|0.15484413|0.59555433|
|data/levels.json/92/reward_gold_mult|0.26|0.15479775|0.59537596|
|data/levels.json/93/reward_gold_mult|0.26|0.15475139|0.59519765|
|data/levels.json/94/reward_gold_mult|0.26|0.15470504|0.59501939|
|data/levels.json/95/reward_gold_mult|0.26|0.15465871|0.59484119|
|data/levels.json/96/reward_gold_mult|0.26|0.15461239|0.59466303|
|data/levels.json/97/reward_gold_mult|0.26|0.15456608|0.59448493|
|data/levels.json/98/reward_gold_mult|0.26|0.15451979|0.59430689|
|data/weapons.json/weapon_flamethrower/unlock_cost_star|8|10|1.2451683|
|data/weapons.json/weapon_cryocannon/unlock_cost_star|8|10|1.2451683|
|data/weapons.json/weapon_teslacoil/unlock_cost_star|10|12|1.2451683|
|data/weapons.json/weapon_venomlauncher/unlock_cost_star|8|10|1.2451683|
|data/weapons.json/weapon_railgun/unlock_cost_star|14|17|1.2451683|
|data/weapons.json/weapon_scattergun/unlock_cost_star|9|11|1.2451683|
|data/weapons.json/weapon_plasmacannon/unlock_cost_star|16|20|1.2451683|
|data/armors.json/armor_kevlar/unlock_cost_star|8|10|1.2451683|
|data/armors.json/armor_thermal/unlock_cost_star|8|10|1.2451683|
|data/armors.json/armor_cryo/unlock_cost_star|9|11|1.2451683|
|data/armors.json/armor_faraday/unlock_cost_star|10|12|1.2451683|
|data/armors.json/armor_hazmat/unlock_cost_star|11|14|1.2451683|
|data/armors.json/armor_reactive/unlock_cost_star|14|17|1.2451683|
|data/chips.json/chip_attack/unlock_cost_star|8|10|1.2451683|
|data/chips.json/chip_haste/unlock_cost_star|8|10|1.2451683|
|data/chips.json/chip_crit/unlock_cost_star|9|11|1.2451683|
|data/chips.json/chip_pierce/unlock_cost_star|11|14|1.2451683|
|data/chips.json/chip_health/unlock_cost_star|9|11|1.2451683|
|data/chips.json/chip_guardian/unlock_cost_star|10|12|1.2451683|
|data/chips.json/chip_greed/unlock_cost_star|11|14|1.2451683|
|data/chips.json/chip_element/unlock_cost_star|14|17|1.2451683|
|data/pets.json/pet_turret_drone/unlock_cost_star|8|10|1.2451683|
|data/pets.json/pet_fire_imp/unlock_cost_star|9|11|1.2451683|
|data/pets.json/pet_frost_wisp/unlock_cost_star|10|12|1.2451683|
|data/pets.json/pet_volt_orb/unlock_cost_star|11|14|1.2451683|
|data/pets.json/pet_medic_drone/unlock_cost_star|13|16|1.2451683|
|data/pets.json/pet_collector/unlock_cost_star|14|17|1.2451683|
|data/economy.json/skill_base_xp_costs/0|350|232|0.66237157|
|data/economy.json/skill_base_xp_costs/1|900|801|0.89001688|
|data/economy.json/skill_base_xp_costs/2|2000|1864|0.9321832|
|data/economy.json/skill_base_xp_costs/3|4000|4522|1.1303891|
|data/economy.json/skill_base_xp_costs/4|8500|11457|1.3478349|
|data/economy.json/sig_skill_xp_costs/0|450|251|0.55826497|
|data/economy.json/sig_skill_xp_costs/1|1200|992|0.82662669|
|data/economy.json/sig_skill_xp_costs/2|2700|2670|0.9889757|
|data/economy.json/sig_skill_xp_costs/3|5400|5360|0.99259523|
|data/economy.json/sig_skill_xp_costs/4|11000|11039|1.0035285|
|data/weapons.json/weapon_autocannon/cost_base_gold|100|200|2|
|data/weapons.json/weapon_flamethrower/cost_base_gold|180|360|2|
|data/weapons.json/weapon_cryocannon/cost_base_gold|180|360|2|
|data/weapons.json/weapon_teslacoil/cost_base_gold|240|480|2|
|data/weapons.json/weapon_venomlauncher/cost_base_gold|240|480|2|
|data/weapons.json/weapon_railgun/cost_base_gold|320|640|2|
|data/weapons.json/weapon_scattergun/cost_base_gold|180|360|2|
|data/weapons.json/weapon_plasmacannon/cost_base_gold|320|640|2|

|关卡|rec|E|旧P|新P|新R|新P/E|下限|上限|达标|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
|001|50|65|65|65|1.3000|1.0000|48|78|True|
|002|50|65|69|67|1.3400|1.0308|48|78|True|
|003|50|65|73|70|1.4000|1.0769|48|78|True|
|004|64|65|74|71|1.1094|1.0923|61|78|True|
|005|76|76|81|76|1.0000|1.0000|76|91|True|
|006|53|76|82|79|1.4906|1.0395|51|91|True|
|007|53|76|89|82|1.5472|1.0789|53|91|True|
|008|79|79|96|85|1.0759|1.0759|79|94|True|
|009|79|79|106|90|1.1392|1.1392|79|94|True|
|010|87|87|112|90|1.0345|1.0345|87|104|True|
|011|99|99|116|100|1.0101|1.0101|95|118|True|
|012|108|108|122|103|0.9537|0.9537|103|129|True|
|013|131|131|131|130|0.9924|0.9924|125|157|True|
|014|138|138|141|142|1.0290|1.0290|132|165|True|
|015|147|147|151|150|1.0204|1.0204|147|176|True|
|016|98|147|152|162|1.6531|1.1020|94|176|True|
|017|165|165|166|169|1.0242|1.0242|165|198|True|
|018|185|185|207|200|1.0811|1.0811|185|222|True|
|019|188|188|210|201|1.0691|1.0691|188|225|True|
|020|291|291|291|293|1.0069|1.0069|0|349|True|
|021|164|291|323|293|1.7866|1.0069|156|349|True|
|022|183|291|339|295|1.6120|1.0137|174|349|True|
|023|186|291|355|297|1.5968|1.0206|177|349|True|
|024|201|291|374|301|1.4975|1.0344|191|349|True|
|025|260|291|410|307|1.1808|1.0550|260|349|True|
|026|226|291|410|307|1.3584|1.0550|215|349|True|
|027|195|291|410|314|1.6103|1.0790|195|349|True|
|028|231|291|474|314|1.3593|1.0790|231|349|True|
|029|206|291|509|328|1.5922|1.1271|206|349|True|
|030|332|332|515|337|1.0151|1.0151|332|398|True|
|031|159|332|522|337|2.1195|1.0151|152|398|True|
|032|245|332|530|337|1.3755|1.0151|233|398|True|
|033|228|332|573|337|1.4781|1.0151|217|398|True|
|034|330|332|573|352|1.0667|1.0602|314|398|True|
|035|219|332|648|369|1.6849|1.1114|219|398|True|
|036|225|332|679|375|1.6667|1.1295|214|398|True|
|037|232|332|685|375|1.6164|1.1295|232|398|True|
|038|484|484|710|490|1.0124|1.0124|484|580|True|
|039|533|533|849|537|1.0075|1.0075|0|639|True|
|040|574|574|849|663|1.1551|1.1551|0|688|True|
|041|236|574|880|688|2.9153|1.1986|225|688|True|
|042|375|574|942|688|1.8347|1.1986|357|688|True|
|043|587|587|951|699|1.1908|1.1908|558|704|True|
|044|757|757|957|734|0.9696|0.9696|720|908|True|
|045|655|757|963|793|1.2107|1.0476|655|908|True|
|046|600|757|972|852|1.4200|1.1255|570|908|True|
|047|670|757|983|886|1.3224|1.1704|670|908|True|
|048|663|757|983|961|1.4495|1.2695|663|908|False|
|049|658|757|1008|969|1.4726|1.2801|658|908|False|
|050|868|868|1068|969|1.1164|1.1164|868|1041|True|
|051|431|868|1185|969|2.2483|1.1164|410|1041|True|
|052|349|868|1185|984|2.8195|1.1336|332|1041|True|
|053|427|868|1185|988|2.3138|1.1382|406|1041|True|
|054|359|868|1185|988|2.7521|1.1382|342|1041|True|
|055|950|950|1185|996|1.0484|1.0484|950|1140|True|
|056|354|950|1237|999|2.8220|1.0516|337|1140|True|
|057|990|990|1237|999|1.0091|1.0091|990|1188|True|
|058|503|990|1284|999|1.9861|1.0091|503|1188|True|
|059|562|990|1284|1022|1.8185|1.0323|562|1188|True|
|060|990|990|1300|1062|1.0727|1.0727|990|1188|True|
|061|990|990|1491|1062|1.0727|1.0727|941|1188|True|
|062|250|990|1577|1062|4.2480|1.0727|238|1188|True|
|063|576|990|1763|1203|2.0885|1.2152|548|1188|False|
|064|955|990|1763|1257|1.3162|1.2697|908|1188|False|
|065|1014|1014|1813|1257|1.2396|1.2396|1014|1216|False|
|066|1184|1184|1813|1305|1.1022|1.1022|1125|1420|True|
|067|955|1184|1813|1305|1.3665|1.1022|955|1420|True|
|068|1042|1184|1814|1305|1.2524|1.1022|1042|1420|True|
|069|978|1184|2043|1328|1.3579|1.1216|978|1420|True|
|070|1286|1286|2043|1504|1.1695|1.1695|1286|1543|True|
|071|1146|1286|2202|1504|1.3124|1.1695|1089|1543|True|
|072|1576|1576|2308|1545|0.9803|0.9803|1498|1891|True|
|073|818|1576|2308|1563|1.9108|0.9918|778|1891|True|
|074|2034|2034|2429|2216|1.0895|1.0895|0|2440|True|
|075|1841|2034|2733|2216|1.2037|1.0895|1841|2440|True|
|076|2758|2758|2989|3019|1.0946|1.0946|0|3309|True|
|077|1652|2758|3160|3019|1.8275|1.0946|1652|3309|True|
|078|2226|2758|3160|3019|1.3562|1.0946|2226|3309|True|
|079|2030|2758|3160|3019|1.4872|1.0946|2030|3309|True|
|080|2067|2758|3220|3019|1.4606|1.0946|2067|3309|True|
|081|1096|2758|3270|3019|2.7546|1.0946|1042|3309|True|
|082|1762|2758|3270|3205|1.8190|1.1621|1674|3309|True|
|083|1815|2758|3270|3288|1.8116|1.1922|1725|3309|True|
|084|1265|2758|3271|3288|2.5992|1.1922|1202|3309|True|
|085|2204|2758|3271|3288|1.4918|1.1922|2204|3309|True|
|086|1855|2758|3538|3288|1.7725|1.1922|1763|3309|True|
|087|1857|2758|3639|3288|1.7706|1.1922|1857|3309|True|
|088|1857|2758|3700|3288|1.7706|1.1922|1857|3309|True|
|089|1994|2758|3974|3288|1.6489|1.1922|1994|3309|True|
|090|2751|2758|3994|3288|1.1952|1.1922|2751|3309|True|
|091|1234|2758|4401|3417|2.7690|1.2389|1173|3309|False|
|092|1862|2758|4401|3550|1.9066|1.2872|1769|3309|False|
|093|2266|2758|4404|3550|1.5666|1.2872|2153|3309|False|
|094|1830|2758|4406|3550|1.9399|1.2872|1739|3309|False|
|095|3370|3370|4415|3550|1.0534|1.0534|0|4044|True|
|096|2429|3370|4415|3550|1.4615|1.0534|2308|4044|True|
|097|1863|3370|4415|3700|1.9860|1.0979|1863|4044|True|
|098|2720|3370|5163|3700|1.3603|1.0979|2720|4044|True|
|099|3094|3370|5283|3700|1.1959|1.0979|3094|4044|True|

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

首次R<0.95：None；G1走廊不满足关数：9/99。

包络目标Σ|P−E|/E：10.091418。

回刷总数：63（非门10，门53）；各章非门：{'1': 0, '2': 6, '3': 0, '4': 4, '5': 0, '6': 0, '7': 0, '8': 0, '9': 0, '10': 0}。
门关：[20, 39, 40, 74, 76, 95]；预算后新增门：[39, 40, 74]；未刷够门：[]；非门失败：[48, 49, 63, 64, 65, 91, 92, 93, 94]。

|回刷位置|路线(挑战/普通)|入场P|回刷后P|次数|非门章累计|刷够|八墙关|门高度/路线注记|
|---|---|---:|---:|---:|---:|---|---|---|
|013|012挑, 011挑, 010挑, 009挑|104|130|4|4|True|False|非门|
|018|017挑, 016挑|178|200|2|6|True|True|非门|
|020|019挑, 018挑, 015挑, 014挑, 013挑, 008挑, 007挑, 006挑, 005挑, 004挑|202|293|10|6|True|True|10 / 仅挑战 / Owner fixed gate|
|038|037挑, 036挑, 035挑, 034挑|481|490|4|4|True|False|非门|
|039|038挑, 033挑, 032挑, 031挑, 030挑, 029挑, 028挑, 027挑, 026挑, 025挑|514|537|10|4|True|False|10 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|040|039挑, 024挑, 023挑, 022挑|537|663|4|4|True|True|4 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|074|073挑, 072挑, 071挑, 070挑, 069挑, 068挑, 067挑, 066挑, 065挑, 064挑, 063挑, 062挑, 061挑, 060挑, 059挑, 058挑, 057挑|1573|2216|17|0|True|False|17 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|076|075挑, 074挑, 056挑, 055挑, 054挑, 053挑, 052挑, 051挑, 050挑, 049挑, 048挑, 047挑|2216|3019|12|0|True|True|12 / 可付费（未做运行时验证） / Owner fixed gate|

## 门关高度（含无需回刷的固定门）

|门|高度|已刷够|路径|原因|
|---|---:|---|---|---|
|020|10|True|仅挑战|Owner fixed gate|
|039|10|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|040|4|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|074|17|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|076|12|True|可付费（未做运行时验证）|Owner fixed gate|
|095|0|True|可付费（未做运行时验证）|Owner fixed gate|

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|当关/章累计回刷|
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
|001|0|65|50|1.3000|65|1.0000|292|weapon_autocannon 1→2; skill_multishot 0→1|0/0|
|002|292|67|50|1.3400|65|1.0308|395|vanguard 1→2; weapon_autocannon 2→3; skill_pierce 0→1|0/0|
|003|687|70|50|1.4000|65|1.0769|470|vanguard 2→3; skill_barrier 0→1; skill_homing 0→1|0/0|
|004|1157|71|64|1.1094|65|1.0923|533|weapon_cryocannon; weapon_autocannon 3→4; skill_charge_shot 0→1; skill_salvo 0→1|0/0|
|005|1690|76|76|1.0000|76|1.0000|649|weapon_autocannon 4→5; skill_slow_field 0→1; signature 0→1|0/0|
|006|2339|79|53|1.4906|76|1.0395|699|weapon_autocannon 5→6; skill_critical 0→1; skill_split_shot 0→1|0/0|
|007|3038|82|53|1.5472|76|1.0789|711|armor_kevlar; weapon_autocannon 6→7; skill_ricochet 0→1|0/0|
|008|3749|85|79|1.0759|79|1.0759|938|armor_kevlar 1→2; vanguard 3→4; weapon_cryocannon 1→2; skill_multishot 1→2|0/0|
|009|4687|90|79|1.1392|79|1.1392|718|armor_kevlar 2→3; weapon_cryocannon 2→3|0/0|
|010|5405|90|87|1.0345|87|1.0345|744|chip_attack; chip_attack 1→3; vanguard 4→5; skill_pierce 1→2|0/0|
|011|6149|100|99|1.0101|99|1.0101|1164|weapon_autocannon 7→8|0/0|
|012|7313|103|108|0.9537|108|0.9537|1194|weapon_autocannon 8→9; skill_homing 1→2|0/0|
|013|11463|130|131|0.9924|131|0.9924|1233|chip_attack 4→5; weapon_scattergun 3→4; skill_slow_field 1→2|4/4|
|014|12696|142|138|1.0290|138|1.0290|1269|armor_kevlar 4→5; weapon_scattergun 4→5|0/4|
|015|13965|150|147|1.0204|147|1.0204|874|vanguard 6→7; signature 1→2|0/4|
|016|14839|162|98|1.6531|147|1.1020|1693|weapon_railgun; weapon_railgun 1→2; weapon_scattergun 5→6; skill_split_shot 1→2|0/4|
|017|16532|169|165|1.0242|165|1.0242|1659|weapon_scattergun 6→7; skill_critical 1→2|0/4|
|018|20923|200|185|1.0811|185|1.0811|1356|pet_turret_drone 2→3; weapon_cryocannon 4→5|2/6|
|019|22279|201|188|1.0691|188|1.0691|1835|weapon_scattergun 7→8; skill_multishot 2→3|0/6|
|020|31981|293|291|1.0069|291|1.0069|1952|weapon_cryocannon 6→7|10/6|
|021|33933|293|164|1.7866|291|1.0069|1753|weapon_venomlauncher; chip_attack 8→9; weapon_venomlauncher 1→3|0/0|
|022|35686|295|183|1.6120|291|1.0137|1932|vanguard 9→10; weapon_venomlauncher 3→4; skill_salvo 2→3|0/0|
|023|37618|297|186|1.5968|291|1.0206|2220|weapon_scattergun 8→9|0/0|
|024|39838|301|201|1.4975|291|1.0344|2039|armor_kevlar 7→8; weapon_venomlauncher 4→5; skill_charge_shot 2→3|0/0|
|025|41877|307|260|1.1808|291|1.0550|1441|weapon_autocannon 10→11|0/0|
|026|43318|307|226|1.3584|291|1.0550|2393|weapon_scattergun 9→10|0/0|
|027|45711|314|195|1.6103|291|1.0790|2224|weapon_railgun 4→5; skill_slow_field 2→3|0/0|
|028|47935|314|231|1.3593|291|1.0790|2445|weapon_scattergun 10→11|0/0|
|029|50380|328|206|1.5922|291|1.1271|2493|chip_attack 9→10; weapon_venomlauncher 5→6; skill_split_shot 2→3|0/0|
|030|52873|337|332|1.0151|332|1.0151|1952|weapon_cryocannon 7→8|0/0|
|031|54825|337|159|2.1195|332|1.0151|2894|weapon_flamethrower; weapon_flamethrower 1→5; skill_critical 2→3|0/0|
|032|57719|337|245|1.3755|332|1.0151|2663|weapon_plasmacannon; armor_kevlar 8→9; weapon_plasmacannon 1→3|0/0|
|033|60382|337|228|1.4781|332|1.0151|2451|vanguard 10→11; weapon_plasmacannon 3→4; skill_ricochet 2→3|0/0|
|034|62833|352|330|1.0667|332|1.0602|3008|weapon_scattergun 11→12|0/0|
|035|65841|369|219|1.6849|332|1.1114|2274|pet_turret_drone 6→7; weapon_plasmacannon 4→5|0/0|
|036|68115|375|225|1.6667|332|1.1295|3008|weapon_flamethrower 5→7|0/0|
|037|71123|375|232|1.6164|332|1.1295|3408|weapon_scattergun 12→13; signature 2→3|0/0|
|038|83736|490|484|1.0124|484|1.0124|3644|chip_attack 10→11; weapon_scattergun 13→14|4/4|
|039|106695|537|533|1.0075|533|1.0075|3134|weapon_railgun 6→7|10/4|
|040|117227|663|574|1.1551|574|1.1551|4102|pet_turret_drone 8→9; weapon_scattergun 14→15|4/4|
|041|121329|688|236|2.9153|574|1.1986|4028|weapon_teslacoil; weapon_teslacoil 1→5|0/0|
|042|125357|688|375|1.8347|574|1.1986|3646|armor_kevlar 10→11; chip_attack 12→13; weapon_teslacoil 5→6|0/0|
|043|129003|699|587|1.1908|587|1.1908|4237|weapon_scattergun 15→16; skill_salvo 3→4|0/0|
|044|133240|734|757|0.9696|757|0.9696|4104|weapon_scattergun 16→17|0/0|
|045|137344|793|655|1.2107|757|1.0476|4218|weapon_scattergun 17→18|0/0|
|046|141562|852|600|1.4200|757|1.1255|3629|vanguard 15→16; weapon_teslacoil 6→7|0/0|
|047|145191|886|670|1.3224|757|1.1704|4100|vanguard 16→17; weapon_teslacoil 7→8; skill_charge_shot 3→4|0/0|
|048|149291|961|663|1.4495|757|1.2695|4643|weapon_scattergun 18→19|0/0|
|049|153934|969|658|1.4726|757|1.2801|4614|armor_kevlar 11→12; weapon_plasmacannon 7→8|0/0|
|050|158548|969|868|1.1164|868|1.1164|3438|weapon_railgun 7→8|0/0|
|051|161986|969|431|2.2483|868|1.1164|1528|weapon_autocannon 15→16; signature 3→4|0/0|
|052|163514|984|349|2.8195|868|1.1336|1740|chip_attack 13→14|0/0|
|053|165254|988|427|2.3138|868|1.1382|1672|weapon_flamethrower 9→10|0/0|
|054|166926|988|359|2.7521|868|1.1382|1708|vanguard 17→18; skill_slow_field 3→4|0/0|
|055|168634|996|950|1.0484|950|1.0484|1731|pet_turret_drone 9→10|0/0|
|056|170365|999|354|2.8220|950|1.0516|1636|weapon_autocannon 16→17|0/0|
|057|172001|999|990|1.0091|990|1.0091|2944|weapon_teslacoil 8→9; skill_split_shot 3→4|0/0|
|058|174945|999|503|1.9861|990|1.0091|1877|armor_kevlar 12→13; chip_attack 14→15|0/0|
|059|176822|1022|562|1.8185|990|1.0323|1836|vanguard 18→19|0/0|
|060|178658|1062|990|1.0727|990|1.0727|3913|armor_kevlar 13→14; weapon_venomlauncher 8→9; skill_critical 3→4|0/0|
|061|182571|1062|990|1.0727|990|1.0727|2320|weapon_autocannon 17→18|0/0|
|062|184891|1062|250|4.2480|990|1.0727|2353|chip_attack 15→16; pet_turret_drone 10→11; skill_ricochet 3→4|0/0|
|063|187244|1203|576|2.0885|990|1.2152|2153|vanguard 19→20|0/0|
|064|189397|1257|955|1.3162|990|1.2697|2183|weapon_cryocannon 10→11|0/0|
|065|191580|1257|1014|1.2396|1014|1.2396|2549|vanguard 20→21|0/0|
|066|194129|1305|1184|1.1022|1184|1.1022|2120|weapon_autocannon 18→19|0/0|
|067|196249|1305|955|1.3665|1184|1.1022|2854|weapon_flamethrower 10→11|0/0|
|068|199103|1305|1042|1.2524|1184|1.1022|2610|weapon_autocannon 19→20; skill_multishot 4→5|0/0|
|069|201713|1328|978|1.3579|1184|1.1216|2713|armor_kevlar 14→15; chip_attack 16→17|0/0|
|070|204426|1504|1286|1.1695|1286|1.1695|2607|weapon_cryocannon 11→12|0/0|
|071|207033|1504|1146|1.3124|1286|1.1695|2350|chip_attack 17→18; pet_turret_drone 11→12|0/0|
|072|209383|1545|1576|0.9803|1576|0.9803|2254|vanguard 21→22|0/0|
|073|211637|1563|818|1.9108|1576|0.9918|2442|armor_kevlar 15→16; chip_attack 18→19; skill_pierce 4→5|0/0|
|074|236396|2216|2034|1.0895|2034|1.0895|2976|weapon_flamethrower 11→12|17/0|
|075|239372|2216|1841|1.2037|2034|1.0895|3128|weapon_teslacoil 9→10|0/0|
|076|263642|3019|2758|1.0946|2758|1.0946|2716|weapon_cryocannon 12→13|12/0|
|077|266358|3019|1652|1.8275|2758|1.0946|3050|weapon_autocannon 20→21|0/0|
|078|269408|3019|2226|1.3562|2758|1.0946|2823|weapon_autocannon 21→22|0/0|
|079|272231|3019|2030|1.4872|2758|1.0946|3136|weapon_flamethrower 12→13|0/0|
|080|275367|3019|2067|1.4606|2758|1.0946|3354|weapon_cryocannon 13→14; skill_slow_field 4→5|0/0|
|081|278721|3019|1096|2.7546|2758|1.0946|2660|vanguard 25→26|0/0|
|082|281381|3205|1762|1.8190|2758|1.1621|2621|vanguard 26→27|0/0|
|083|284002|3288|1815|1.8116|2758|1.1922|3159|weapon_autocannon 22→23|0/0|
|084|287161|3288|1265|2.5992|2758|1.1922|2690|armor_kevlar 21→22|0/0|
|085|289851|3288|2204|1.4918|2758|1.1922|3713|weapon_plasmacannon 9→10; skill_split_shot 4→5|0/0|
|086|293564|3288|1855|1.7725|2758|1.1922|3593|weapon_venomlauncher 10→11|0/0|
|087|297157|3288|1857|1.7706|2758|1.1922|3474|weapon_teslacoil 11→12|0/0|
|088|300631|3288|1857|1.7706|2758|1.1922|3197|weapon_flamethrower 13→14; skill_critical 4→5|0/0|
|089|303828|3288|1994|1.6489|2758|1.1922|3474|weapon_autocannon 23→24|0/0|
|090|307302|3288|2751|1.1952|2758|1.1922|2913|vanguard 27→28|0/0|
|091|310215|3417|1234|2.7690|2758|1.2389|2905|vanguard 28→29|0/0|
|092|313120|3550|1862|1.9066|2758|1.2872|4175|weapon_railgun 9→10; skill_ricochet 4→5|0/0|
|093|317295|3550|2266|1.5666|2758|1.2872|3549|weapon_venomlauncher 11→12|0/0|
|094|320844|3550|1830|1.9399|2758|1.2872|3871|weapon_cryocannon 14→15|0/0|
|095|324715|3550|3370|1.0534|3370|1.0534|3560|weapon_flamethrower 14→15|0/0|
|096|328275|3550|2429|1.4615|3370|1.0534|4801|weapon_scattergun 19→20|0/0|
|097|333076|3700|1863|1.9860|3370|1.0979|4482|weapon_teslacoil 12→13|0/0|
|098|337558|3700|2720|1.3603|3370|1.0979|4452|weapon_plasmacannon 10→11|0/0|
|099|342010|3700|3094|1.1959|3370|1.0979|3833|weapon_cryocannon 15→16|0/0|
