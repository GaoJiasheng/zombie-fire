状态：SEARCH_CANDIDATE_NOT_YET_FEASIBLE；待Fable签字，游戏数据未写入。

# 资源表 C 候选

§8.3离线假定3★首通，挑战首通优先；非门关每章最多6次，门关不限次数、照实列高度。不是运行时胜率。P(g)/F(g)与消费策略冻结，因子[0.5,2.0]。
优化前：88/99失败，目标36.608304。
优化后：10/99失败，目标4.676400。

缩放系数与逐字段旧/新对照完整列于同名JSON；所有候选仅在内存模拟。

|曲线|缩放系数/形式|
|---|---|
|first_clear_gold|[-0.49315434976331196, -0.06810549465202609]；existing authored per-level values × exp(a+b*(L-1)/98)|
|kill_gold_mult|[-0.4910044200090515, -0.03435502598504009]；existing authored per-level values × exp(a+b*(L-1)/98)|
|free_unlock_star|1.2451682810355265；existing free star tiers × constant|
|skill_base_xp_costs|[0.6623715678431924, 0.8562217224077878, 0.8723933608328281, 1.049694895593656, 1.1303891020402654]；same five authored cost tiers times positive monotone factors|
|sig_skill_xp_costs|[0.5153435217367096, 0.8266266896932006, 0.988975704299648, 0.9925952342232989, 1.0035285009048651]；same five authored cost tiers times positive monotone factors|
|weapon_cost.weapon_autocannon|1.6367091754852168；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_flamethrower|0.7672611365055757；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_cryocannon|0.5542414312125498；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_teslacoil|1.7031196785223643；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_venomlauncher|1.2589323800563417；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_railgun|0.7980640456161352；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_scattergun|1.752095205180858；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_plasmacannon|1.1819738878283128；same existing linear upgrade formula × constant base cost|

|文件/字段|旧值|候选新值|系数|
|---|---:|---:|---:|
|data/levels.json/0/first_clear_reward/gold|119|73|0.610697|
|data/levels.json/1/first_clear_reward/gold|143|87|0.61027274|
|data/levels.json/2/first_clear_reward/gold|167|102|0.60984878|
|data/levels.json/3/first_clear_reward/gold|192|117|0.60942511|
|data/levels.json/4/first_clear_reward/gold|216|132|0.60900173|
|data/levels.json/5/first_clear_reward/gold|241|147|0.60857865|
|data/levels.json/6/first_clear_reward/gold|266|162|0.60815586|
|data/levels.json/7/first_clear_reward/gold|291|177|0.60773337|
|data/levels.json/8/first_clear_reward/gold|315|191|0.60731117|
|data/levels.json/9/first_clear_reward/gold|340|206|0.60688926|
|data/levels.json/10/first_clear_reward/gold|366|222|0.60646765|
|data/levels.json/11/first_clear_reward/gold|391|237|0.60604633|
|data/levels.json/12/first_clear_reward/gold|416|252|0.6056253|
|data/levels.json/13/first_clear_reward/gold|442|268|0.60520457|
|data/levels.json/14/first_clear_reward/gold|467|282|0.60478412|
|data/levels.json/15/first_clear_reward/gold|493|298|0.60436397|
|data/levels.json/16/first_clear_reward/gold|519|313|0.60394411|
|data/levels.json/17/first_clear_reward/gold|545|329|0.60352454|
|data/levels.json/18/first_clear_reward/gold|571|344|0.60310527|
|data/levels.json/19/first_clear_reward/gold|597|360|0.60268628|
|data/levels.json/20/first_clear_reward/gold|623|375|0.60226759|
|data/levels.json/21/first_clear_reward/gold|650|391|0.60184919|
|data/levels.json/22/first_clear_reward/gold|676|407|0.60143108|
|data/levels.json/23/first_clear_reward/gold|703|423|0.60101325|
|data/levels.json/24/first_clear_reward/gold|729|438|0.60059572|
|data/levels.json/25/first_clear_reward/gold|756|454|0.60017848|
|data/levels.json/26/first_clear_reward/gold|783|470|0.59976153|
|data/levels.json/27/first_clear_reward/gold|810|485|0.59934487|
|data/levels.json/28/first_clear_reward/gold|837|501|0.59892849|
|data/levels.json/29/first_clear_reward/gold|864|517|0.59851241|
|data/levels.json/30/first_clear_reward/gold|892|534|0.59809662|
|data/levels.json/31/first_clear_reward/gold|919|549|0.59768111|
|data/levels.json/32/first_clear_reward/gold|947|566|0.5972659|
|data/levels.json/33/first_clear_reward/gold|975|582|0.59685097|
|data/levels.json/34/first_clear_reward/gold|1002|598|0.59643633|
|data/levels.json/35/first_clear_reward/gold|1030|614|0.59602198|
|data/levels.json/36/first_clear_reward/gold|1058|630|0.59560791|
|data/levels.json/37/first_clear_reward/gold|1086|646|0.59519414|
|data/levels.json/38/first_clear_reward/gold|1115|663|0.59478065|
|data/levels.json/39/first_clear_reward/gold|1143|679|0.59436744|
|data/levels.json/40/first_clear_reward/gold|1171|696|0.59395453|
|data/levels.json/41/first_clear_reward/gold|1200|712|0.5935419|
|data/levels.json/42/first_clear_reward/gold|1229|729|0.59312956|
|data/levels.json/43/first_clear_reward/gold|1257|745|0.59271751|
|data/levels.json/44/first_clear_reward/gold|1286|762|0.59230574|
|data/levels.json/45/first_clear_reward/gold|1315|778|0.59189426|
|data/levels.json/46/first_clear_reward/gold|1344|795|0.59148306|
|data/levels.json/47/first_clear_reward/gold|1374|812|0.59107215|
|data/levels.json/48/first_clear_reward/gold|1403|829|0.59066152|
|data/levels.json/49/first_clear_reward/gold|1432|845|0.59025118|
|data/levels.json/50/first_clear_reward/gold|1462|862|0.58984113|
|data/levels.json/51/first_clear_reward/gold|1492|879|0.58943136|
|data/levels.json/52/first_clear_reward/gold|1521|896|0.58902187|
|data/levels.json/53/first_clear_reward/gold|1551|913|0.58861267|
|data/levels.json/54/first_clear_reward/gold|1581|930|0.58820376|
|data/levels.json/55/first_clear_reward/gold|1611|947|0.58779512|
|data/levels.json/56/first_clear_reward/gold|1642|964|0.58738677|
|data/levels.json/57/first_clear_reward/gold|1672|981|0.58697871|
|data/levels.json/58/first_clear_reward/gold|1702|998|0.58657093|
|data/levels.json/59/first_clear_reward/gold|1733|1016|0.58616343|
|data/levels.json/60/first_clear_reward/gold|1764|1033|0.58575621|
|data/levels.json/61/first_clear_reward/gold|1794|1050|0.58534928|
|data/levels.json/62/first_clear_reward/gold|1825|1068|0.58494263|
|data/levels.json/63/first_clear_reward/gold|1856|1085|0.58453627|
|data/levels.json/64/first_clear_reward/gold|1887|1102|0.58413018|
|data/levels.json/65/first_clear_reward/gold|1919|1120|0.58372438|
|data/levels.json/66/first_clear_reward/gold|1950|1137|0.58331886|
|data/levels.json/67/first_clear_reward/gold|1981|1155|0.58291362|
|data/levels.json/68/first_clear_reward/gold|2013|1173|0.58250866|
|data/levels.json/69/first_clear_reward/gold|2044|1190|0.58210399|
|data/levels.json/70/first_clear_reward/gold|2076|1208|0.58169959|
|data/levels.json/71/first_clear_reward/gold|2108|1225|0.58129548|
|data/levels.json/72/first_clear_reward/gold|2140|1243|0.58089164|
|data/levels.json/73/first_clear_reward/gold|2172|1261|0.58048809|
|data/levels.json/74/first_clear_reward/gold|2204|1279|0.58008482|
|data/levels.json/75/first_clear_reward/gold|2237|1297|0.57968183|
|data/levels.json/76/first_clear_reward/gold|2269|1314|0.57927911|
|data/levels.json/77/first_clear_reward/gold|2302|1333|0.57887668|
|data/levels.json/78/first_clear_reward/gold|2334|1350|0.57847453|
|data/levels.json/79/first_clear_reward/gold|2367|1368|0.57807265|
|data/levels.json/80/first_clear_reward/gold|2400|1386|0.57767106|
|data/levels.json/81/first_clear_reward/gold|2433|1404|0.57726975|
|data/levels.json/82/first_clear_reward/gold|2466|1423|0.57686871|
|data/levels.json/83/first_clear_reward/gold|2499|1441|0.57646795|
|data/levels.json/84/first_clear_reward/gold|2532|1459|0.57606747|
|data/levels.json/85/first_clear_reward/gold|2566|1477|0.57566727|
|data/levels.json/86/first_clear_reward/gold|2599|1495|0.57526735|
|data/levels.json/87/first_clear_reward/gold|2633|1514|0.5748677|
|data/levels.json/88/first_clear_reward/gold|2667|1532|0.57446833|
|data/levels.json/89/first_clear_reward/gold|2700|1550|0.57406924|
|data/levels.json/90/first_clear_reward/gold|2734|1568|0.57367043|
|data/levels.json/91/first_clear_reward/gold|2769|1587|0.57327189|
|data/levels.json/92/first_clear_reward/gold|2803|1606|0.57287363|
|data/levels.json/93/first_clear_reward/gold|2837|1624|0.57247565|
|data/levels.json/94/first_clear_reward/gold|2871|1642|0.57207795|
|data/levels.json/95/first_clear_reward/gold|2906|1661|0.57168052|
|data/levels.json/96/first_clear_reward/gold|2940|1680|0.57128336|
|data/levels.json/97/first_clear_reward/gold|2975|1698|0.57088648|
|data/levels.json/98/first_clear_reward/gold|3010|1717|0.57048988|
|data/levels.json/0/reward_gold_mult|0.56|0.34272637|0.61201137|
|data/levels.json/1/reward_gold_mult|0.55|0.33648827|0.61179686|
|data/levels.json/2/reward_gold_mult|0.55|0.33637033|0.61158242|
|data/levels.json/3/reward_gold_mult|0.55|0.33625244|0.61136806|
|data/levels.json/4/reward_gold_mult|0.54|0.33002304|0.61115378|
|data/levels.json/5/reward_gold_mult|0.54|0.32990737|0.61093957|
|data/levels.json/6/reward_gold_mult|0.53|0.32368448|0.61072544|
|data/levels.json/7/reward_gold_mult|0.53|0.32357103|0.61051138|
|data/levels.json/8/reward_gold_mult|0.53|0.32345762|0.61029739|
|data/levels.json/9/reward_gold_mult|0.52|0.31724341|0.61008348|
|data/levels.json/10/reward_gold_mult|0.52|0.31713222|0.60986965|
|data/levels.json/11/reward_gold_mult|0.52|0.31702106|0.60965589|
|data/levels.json/12/reward_gold_mult|0.51|0.31081552|0.60944221|
|data/levels.json/13/reward_gold_mult|0.51|0.31070658|0.6092286|
|data/levels.json/14/reward_gold_mult|0.51|0.31059768|0.60901506|
|data/levels.json/15/reward_gold_mult|0.5|0.3044008|0.6088016|
|data/levels.json/16/reward_gold_mult|0.5|0.30429411|0.60858822|
|data/levels.json/17/reward_gold_mult|0.5|0.30418745|0.60837491|
|data/levels.json/18/reward_gold_mult|0.49|0.29799922|0.60816167|
|data/levels.json/19/reward_gold_mult|0.49|0.29789477|0.60794851|
|data/levels.json/20/reward_gold_mult|0.48|0.291713|0.60773542|
|data/levels.json/21/reward_gold_mult|0.48|0.29161076|0.60752241|
|data/levels.json/22/reward_gold_mult|0.48|0.29150855|0.60730948|
|data/levels.json/23/reward_gold_mult|0.47|0.28533541|0.60709661|
|data/levels.json/24/reward_gold_mult|0.47|0.2852354|0.60688383|
|data/levels.json/25/reward_gold_mult|0.47|0.28513542|0.60667111|
|data/levels.json/26/reward_gold_mult|0.46|0.2789709|0.60645848|
|data/levels.json/27/reward_gold_mult|0.46|0.27887312|0.60624591|
|data/levels.json/28/reward_gold_mult|0.46|0.27877537|0.60603342|
|data/levels.json/29/reward_gold_mult|0.45|0.27261945|0.60582101|
|data/levels.json/30/reward_gold_mult|0.45|0.2725239|0.60560867|
|data/levels.json/31/reward_gold_mult|0.44|0.26637442|0.6053964|
|data/levels.json/32/reward_gold_mult|0.44|0.26628105|0.60518421|
|data/levels.json/33/reward_gold_mult|0.44|0.26618772|0.60497209|
|data/levels.json/34/reward_gold_mult|0.43|0.26004682|0.60476005|
|data/levels.json/35/reward_gold_mult|0.43|0.25995568|0.60454808|
|data/levels.json/36/reward_gold_mult|0.43|0.25986456|0.60433619|
|data/levels.json/37/reward_gold_mult|0.42|0.25373223|0.60412437|
|data/levels.json/38/reward_gold_mult|0.42|0.2536433|0.60391262|
|data/levels.json/39/reward_gold_mult|0.42|0.2535544|0.60370095|
|data/levels.json/40/reward_gold_mult|0.41|0.24743064|0.60348935|
|data/levels.json/41/reward_gold_mult|0.41|0.24734391|0.60327783|
|data/levels.json/42/reward_gold_mult|0.41|0.24725722|0.60306638|
|data/levels.json/43/reward_gold_mult|0.4|0.241142|0.60285501|
|data/levels.json/44/reward_gold_mult|0.4|0.24105748|0.60264371|
|data/levels.json/45/reward_gold_mult|0.39|0.23494867|0.60243248|
|data/levels.json/46/reward_gold_mult|0.39|0.23486632|0.60222133|
|data/levels.json/47/reward_gold_mult|0.39|0.234784|0.60201025|
|data/levels.json/48/reward_gold_mult|0.38|0.22868371|0.60179924|
|data/levels.json/49/reward_gold_mult|0.38|0.22860356|0.60158831|
|data/levels.json/50/reward_gold_mult|0.38|0.22852343|0.60137746|
|data/levels.json/51/reward_gold_mult|0.37|0.22243167|0.60116667|
|data/levels.json/52/reward_gold_mult|0.37|0.22235371|0.60095596|
|data/levels.json/53/reward_gold_mult|0.37|0.22227577|0.60074533|
|data/levels.json/54/reward_gold_mult|0.36|0.21619252|0.60053477|
|data/levels.json/55/reward_gold_mult|0.36|0.21611674|0.60032428|
|data/levels.json/56/reward_gold_mult|0.35|0.21003985|0.60011387|
|data/levels.json/57/reward_gold_mult|0.35|0.20996623|0.59990353|
|data/levels.json/58/reward_gold_mult|0.35|0.20989264|0.59969326|
|data/levels.json/59/reward_gold_mult|0.34|0.20382424|0.59948307|
|data/levels.json/60/reward_gold_mult|0.34|0.2037528|0.59927295|
|data/levels.json/61/reward_gold_mult|0.34|0.20368139|0.5990629|
|data/levels.json/62/reward_gold_mult|0.33|0.19762147|0.59885293|
|data/levels.json/63/reward_gold_mult|0.33|0.1975522|0.59864303|
|data/levels.json/64/reward_gold_mult|0.33|0.19748296|0.59843321|
|data/levels.json/65/reward_gold_mult|0.32|0.19143151|0.59822346|
|data/levels.json/66/reward_gold_mult|0.32|0.19136441|0.59801378|
|data/levels.json/67/reward_gold_mult|0.32|0.19129734|0.59780418|
|data/levels.json/68/reward_gold_mult|0.31|0.18525434|0.59759465|
|data/levels.json/69/reward_gold_mult|0.31|0.18518941|0.59738519|
|data/levels.json/70/reward_gold_mult|0.3|0.17915274|0.59717581|
|data/levels.json/71/reward_gold_mult|0.3|0.17908995|0.5969665|
|data/levels.json/72/reward_gold_mult|0.3|0.17902718|0.59675726|
|data/levels.json/73/reward_gold_mult|0.29|0.17299895|0.5965481|
|data/levels.json/74/reward_gold_mult|0.29|0.17293831|0.59633901|
|data/levels.json/75/reward_gold_mult|0.29|0.1728777|0.59612999|
|data/levels.json/76/reward_gold_mult|0.28|0.16685789|0.59592105|
|data/levels.json/77/reward_gold_mult|0.28|0.16679941|0.59571218|
|data/levels.json/78/reward_gold_mult|0.28|0.16674095|0.59550338|
|data/levels.json/79/reward_gold_mult|0.27|0.16072956|0.59529465|
|data/levels.json/80/reward_gold_mult|0.27|0.16067322|0.595086|
|data/levels.json/81/reward_gold_mult|0.26|0.15466813|0.59487743|
|data/levels.json/82/reward_gold_mult|0.26|0.15461392|0.59466892|
|data/levels.json/83/reward_gold_mult|0.26|0.15455973|0.59446049|
|data/levels.json/84/reward_gold_mult|0.26|0.15450555|0.59425213|
|data/levels.json/85/reward_gold_mult|0.26|0.1544514|0.59404385|
|data/levels.json/86/reward_gold_mult|0.26|0.15439726|0.59383563|
|data/levels.json/87/reward_gold_mult|0.26|0.15434315|0.59362749|
|data/levels.json/88/reward_gold_mult|0.26|0.15428905|0.59341943|
|data/levels.json/89/reward_gold_mult|0.26|0.15423497|0.59321143|
|data/levels.json/90/reward_gold_mult|0.26|0.15418091|0.59300351|
|data/levels.json/91/reward_gold_mult|0.26|0.15412687|0.59279567|
|data/levels.json/92/reward_gold_mult|0.26|0.15407285|0.59258789|
|data/levels.json/93/reward_gold_mult|0.26|0.15401885|0.59238019|
|data/levels.json/94/reward_gold_mult|0.26|0.15396487|0.59217256|
|data/levels.json/95/reward_gold_mult|0.26|0.1539109|0.591965|
|data/levels.json/96/reward_gold_mult|0.26|0.15385696|0.59175752|
|data/levels.json/97/reward_gold_mult|0.26|0.15380303|0.59155011|
|data/levels.json/98/reward_gold_mult|0.26|0.15374912|0.59134277|
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
|data/economy.json/skill_base_xp_costs/1|900|771|0.85622172|
|data/economy.json/skill_base_xp_costs/2|2000|1745|0.87239336|
|data/economy.json/skill_base_xp_costs/3|4000|4199|1.0496949|
|data/economy.json/skill_base_xp_costs/4|8500|9608|1.1303891|
|data/economy.json/sig_skill_xp_costs/0|450|232|0.51534352|
|data/economy.json/sig_skill_xp_costs/1|1200|992|0.82662669|
|data/economy.json/sig_skill_xp_costs/2|2700|2670|0.9889757|
|data/economy.json/sig_skill_xp_costs/3|5400|5360|0.99259523|
|data/economy.json/sig_skill_xp_costs/4|11000|11039|1.0035285|
|data/weapons.json/weapon_autocannon/cost_base_gold|100|164|1.6367092|
|data/weapons.json/weapon_flamethrower/cost_base_gold|180|138|0.76726114|
|data/weapons.json/weapon_cryocannon/cost_base_gold|180|100|0.55424143|
|data/weapons.json/weapon_teslacoil/cost_base_gold|240|409|1.7031197|
|data/weapons.json/weapon_venomlauncher/cost_base_gold|240|302|1.2589324|
|data/weapons.json/weapon_railgun/cost_base_gold|320|255|0.79806405|
|data/weapons.json/weapon_scattergun/cost_base_gold|180|315|1.7520952|
|data/weapons.json/weapon_plasmacannon/cost_base_gold|320|378|1.1819739|

|关卡|rec|E|旧P|新P|新R|新P/E|下限|上限|达标|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
|001|50|65|65|65|1.3000|1.0000|48|71|True|
|002|50|65|69|67|1.3400|1.0308|48|71|True|
|003|50|65|73|70|1.4000|1.0769|48|71|True|
|004|64|65|74|72|1.1250|1.1077|61|71|False|
|005|76|76|81|76|1.0000|1.0000|76|83|True|
|006|53|76|82|79|1.4906|1.0395|51|83|True|
|007|53|76|89|82|1.5472|1.0789|53|83|True|
|008|79|79|96|85|1.0759|1.0759|79|86|True|
|009|79|79|106|90|1.1392|1.1392|79|86|False|
|010|87|87|112|92|1.0575|1.0575|87|95|True|
|011|99|99|116|102|1.0303|1.0303|95|108|True|
|012|108|108|122|106|0.9815|0.9815|103|118|True|
|013|131|131|131|134|1.0229|1.0229|125|144|True|
|014|138|138|141|142|1.0290|1.0290|132|151|True|
|015|147|147|151|155|1.0544|1.0544|147|161|True|
|016|98|147|152|157|1.6020|1.0680|94|161|True|
|017|165|165|166|173|1.0485|1.0485|165|181|True|
|018|185|185|207|201|1.0865|1.0865|185|203|True|
|019|188|188|210|202|1.0745|1.0745|188|206|True|
|020|291|291|291|294|1.0103|1.0103|0|320|True|
|021|164|291|323|298|1.8171|1.0241|156|320|True|
|022|183|291|339|298|1.6284|1.0241|174|320|True|
|023|186|291|355|298|1.6022|1.0241|177|320|True|
|024|201|291|374|302|1.5025|1.0378|191|320|True|
|025|260|291|410|307|1.1808|1.0550|260|320|True|
|026|226|291|410|307|1.3584|1.0550|215|320|True|
|027|195|291|410|309|1.5846|1.0619|195|320|True|
|028|231|291|474|309|1.3377|1.0619|231|320|True|
|029|206|291|509|321|1.5583|1.1031|206|320|False|
|030|332|332|515|335|1.0090|1.0090|332|365|True|
|031|159|332|522|335|2.1069|1.0090|152|365|True|
|032|245|332|530|335|1.3673|1.0090|233|365|True|
|033|228|332|573|335|1.4693|1.0090|217|365|True|
|034|330|332|573|363|1.1000|1.0934|314|365|True|
|035|219|332|648|372|1.6986|1.1205|219|365|False|
|036|225|332|679|372|1.6533|1.1205|214|365|False|
|037|232|332|685|372|1.6034|1.1205|232|365|False|
|038|484|484|710|492|1.0165|1.0165|484|532|True|
|039|533|533|849|540|1.0131|1.0131|0|586|True|
|040|574|574|849|576|1.0035|1.0035|574|631|True|
|041|236|574|880|602|2.5508|1.0488|225|631|True|
|042|375|574|942|602|1.6053|1.0488|357|631|True|
|043|587|587|951|642|1.0937|1.0937|558|645|True|
|044|757|757|957|740|0.9775|0.9775|0|832|True|
|045|655|757|963|796|1.2153|1.0515|655|832|True|
|046|600|757|972|796|1.3267|1.0515|570|832|True|
|047|670|757|983|796|1.1881|1.0515|670|832|True|
|048|663|757|983|853|1.2866|1.1268|663|832|False|
|049|658|757|1008|891|1.3541|1.1770|658|832|False|
|050|868|868|1068|947|1.0910|1.0910|868|954|True|
|051|431|868|1185|947|2.1972|1.0910|410|954|True|
|052|349|868|1185|947|2.7135|1.0910|332|954|True|
|053|427|868|1185|959|2.2459|1.1048|406|954|False|
|054|359|868|1185|959|2.6713|1.1048|342|954|False|
|055|950|950|1185|959|1.0095|1.0095|950|1045|True|
|056|354|950|1237|995|2.8107|1.0474|337|1045|True|
|057|990|990|1237|995|1.0051|1.0051|990|1089|True|
|058|503|990|1284|995|1.9781|1.0051|503|1089|True|
|059|562|990|1284|1021|1.8167|1.0313|562|1089|True|
|060|990|990|1300|1021|1.0313|1.0313|990|1089|True|
|061|990|990|1491|1021|1.0313|1.0313|941|1089|True|
|062|250|990|1577|1046|4.1840|1.0566|238|1089|True|
|063|576|990|1763|1046|1.8160|1.0566|548|1089|True|
|064|955|990|1763|1046|1.0953|1.0566|908|1089|True|
|065|1014|1014|1813|1046|1.0316|1.0316|1014|1115|True|
|066|1184|1184|1813|1205|1.0177|1.0177|1125|1302|True|
|067|955|1184|1813|1205|1.2618|1.0177|955|1302|True|
|068|1042|1184|1814|1205|1.1564|1.0177|1042|1302|True|
|069|978|1184|2043|1205|1.2321|1.0177|978|1302|True|
|070|1286|1286|2043|1291|1.0039|1.0039|1286|1414|True|
|071|1146|1286|2202|1291|1.1265|1.0039|1089|1414|True|
|072|1576|1576|2308|1507|0.9562|0.9562|1498|1733|True|
|073|818|1576|2308|1507|1.8423|0.9562|778|1733|True|
|074|2034|2034|2429|2005|0.9857|0.9857|0|2237|True|
|075|1841|2034|2733|2005|1.0891|0.9857|1841|2237|True|
|076|2758|2758|2989|2680|0.9717|0.9717|0|3033|True|
|077|1652|2758|3160|2680|1.6223|0.9717|1652|3033|True|
|078|2226|2758|3160|2680|1.2040|0.9717|2226|3033|True|
|079|2030|2758|3160|2680|1.3202|0.9717|2030|3033|True|
|080|2067|2758|3220|2680|1.2966|0.9717|2067|3033|True|
|081|1096|2758|3270|2680|2.4453|0.9717|1042|3033|True|
|082|1762|2758|3270|2680|1.5210|0.9717|1674|3033|True|
|083|1815|2758|3270|2680|1.4766|0.9717|1725|3033|True|
|084|1265|2758|3271|2742|2.1676|0.9942|1202|3033|True|
|085|2204|2758|3271|2742|1.2441|0.9942|2204|3033|True|
|086|1855|2758|3538|2742|1.4782|0.9942|1763|3033|True|
|087|1857|2758|3639|2742|1.4766|0.9942|1857|3033|True|
|088|1857|2758|3700|2742|1.4766|0.9942|1857|3033|True|
|089|1994|2758|3974|3025|1.5171|1.0968|1994|3033|True|
|090|2751|2758|3994|3025|1.0996|1.0968|2751|3033|True|
|091|1234|2758|4401|3025|2.4514|1.0968|1173|3033|True|
|092|1862|2758|4401|3025|1.6246|1.0968|1769|3033|True|
|093|2266|2758|4404|3025|1.3350|1.0968|2153|3033|True|
|094|1830|2758|4406|3025|1.6530|1.0968|1739|3033|True|
|095|3370|3370|4415|3443|1.0217|1.0217|0|3707|True|
|096|2429|3370|4415|3443|1.4175|1.0217|2308|3707|True|
|097|1863|3370|4415|3443|1.8481|1.0217|1863|3707|True|
|098|2720|3370|5163|3443|1.2658|1.0217|2720|3707|True|
|099|3094|3370|5283|3443|1.1128|1.0217|3094|3707|True|

## 优化前回刷门与预算

状态：离线条件模拟，不代表实际3★通关；未改数据。

# T3 进度闭环

只用假定3★首通，金币按逐敌四舍五入；非Boss波support不计。
§8.3主路径在账户副本内优先挑战首通；非门关每章累计最多6次，门关刷到够为止、另记高度。
不计动态召唤、金币卡、付费助推；按现有购买/升级优先级和技能经验成本。
挑战首通+3星一次，无普通首通金币；经验独立计数：挑战首通100%，重复50%/25%。R不是已验证胜率。

design/41 section 8.3: non-gates P>=.95rec (Boss/x7-x9 >=rec), <=6 farms/chapter; gate lower exempt, farm until clear; all P<=1.10E; E=max(65,rec(1..L))

首次R<0.95：None；G1走廊不满足关数：88/99。

包络目标Σ|P−E|/E：36.608304。

回刷总数：10（非门2，门8）；各章非门：{'1': 0, '2': 2, '3': 0, '4': 0, '5': 0, '6': 0, '7': 0, '8': 0, '9': 0, '10': 0}。
门关：[20, 76, 95]；预算后新增门：[]；未刷够门：[]；非门失败：[3, 4, 7, 8, 9, 10, 11, 12, 18, 19, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 96, 97, 98, 99]。

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
§8.3主路径在账户副本内优先挑战首通；非门关每章累计最多6次，门关刷到够为止、另记高度。
不计动态召唤、金币卡、付费助推；按现有购买/升级优先级和技能经验成本。
挑战首通+3星一次，无普通首通金币；经验独立计数：挑战首通100%，重复50%/25%。R不是已验证胜率。

design/41 section 8.3: non-gates P>=.95rec (Boss/x7-x9 >=rec), <=6 farms/chapter; gate lower exempt, farm until clear; all P<=1.10E; E=max(65,rec(1..L))

首次R<0.95：None；G1走廊不满足关数：10/99。

包络目标Σ|P−E|/E：4.676400。

回刷总数：101（非门23，门78）；各章非门：{'1': 0, '2': 6, '3': 3, '4': 6, '5': 0, '6': 0, '7': 3, '8': 5, '9': 0, '10': 0}。
门关：[20, 39, 44, 74, 76, 95]；预算后新增门：[39, 44, 74]；未刷够门：[]；非门失败：[4, 9, 29, 35, 36, 37, 48, 49, 53, 54]。

|回刷位置|路线(挑战/普通)|入场P|回刷后P|次数|非门章累计|刷够|八墙关|门高度/路线注记|
|---|---|---:|---:|---:|---:|---|---|---|
|013|012挑, 011挑, 010挑|108|134|3|3|True|False|非门|
|018|017挑, 016挑, 015挑|179|201|3|6|True|True|非门|
|020|019挑, 018挑, 014挑, 013挑, 009挑, 008挑, 007挑, 006挑|203|294|8|6|True|True|8 / 仅挑战 / Owner fixed gate|
|030|029挑, 028挑, 027挑|321|335|3|3|True|False|非门|
|038|037挑, 036挑, 035挑, 034挑, 033挑, 032挑|476|492|6|6|True|False|非门|
|039|038挑, 031挑, 030挑, 026挑, 025挑, 024挑, 023挑, 022挑, 021挑, 020挑|492|540|10|6|True|False|10 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|044|043挑, 042挑, 041挑, 040挑, 039挑, 005挑, 004挑, 003挑, 002挑, 001挑|642|740|10|0|True|True|10 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|070|069挑, 068挑, 067挑|1205|1291|3|3|True|False|非门|
|072|071挑, 070挑, 066挑, 065挑, 064挑|1291|1507|5|5|True|False|非门|
|074|073挑, 072挑, 063挑, 062挑, 061挑, 060挑, 059挑, 058挑, 057挑, 056挑, 055挑, 054挑, 053挑, 052挑, 051挑, 050挑, 049挑, 048挑, 047挑, 046挑, 045挑, 044挑, 073普, 073普, 073普, 073普, 073普, 073普, 073普, 073普, 073普, 073普, 073普, 073普, 073普, 073普, 073普|1507|2005|37|5|True|False|37 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|076|075挑, 074挑, 075普, 075普, 075普, 075普, 075普, 075普, 075普, 075普|2005|2680|10|5|True|True|10 / 可付费（未做运行时验证） / Owner fixed gate|
|095|094挑, 093挑, 092挑|3308|3443|3|0|True|False|3 / 可付费（未做运行时验证） / Owner fixed gate|

## 门关高度（含无需回刷的固定门）

|门|高度|已刷够|路径|原因|
|---|---:|---|---|---|
|020|8|True|仅挑战|Owner fixed gate|
|039|10|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|044|10|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|074|37|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|076|10|True|可付费（未做运行时验证）|Owner fixed gate|
|095|3|True|可付费（未做运行时验证）|Owner fixed gate|

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|当关/章累计回刷|
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
|001|0|65|50|1.3000|65|1.0000|292|weapon_autocannon 1→2; skill_multishot 0→1|0/0|
|002|292|67|50|1.3400|65|1.0308|395|vanguard 1→2; weapon_autocannon 2→3; skill_pierce 0→1|0/0|
|003|687|70|50|1.4000|65|1.0769|470|weapon_autocannon 3→4; skill_barrier 0→1; skill_homing 0→1|0/0|
|004|1157|72|64|1.1250|65|1.1077|533|weapon_cryocannon; weapon_autocannon 4→5; weapon_cryocannon 1→2; skill_charge_shot 0→1; skill_salvo 0→1|0/0|
|005|1690|76|76|1.0000|76|1.0000|649|vanguard 2→3; weapon_cryocannon 2→4; skill_slow_field 0→1; signature 0→1|0/0|
|006|2339|79|53|1.4906|76|1.0395|699|weapon_autocannon 5→6; skill_critical 0→1; skill_split_shot 0→1|0/0|
|007|3038|82|53|1.5472|76|1.0789|710|armor_kevlar; armor_kevlar 1→2; weapon_autocannon 6→7; skill_ricochet 0→1|0/0|
|008|3748|85|79|1.0759|79|1.0759|937|armor_kevlar 2→3; vanguard 3→4; weapon_cryocannon 4→5; skill_multishot 1→2|0/0|
|009|4685|90|79|1.1392|79|1.1392|716|armor_kevlar 3→4; vanguard 4→5|0/0|
|010|5401|92|87|1.0575|87|1.0575|742|chip_attack; chip_attack 1→4; skill_pierce 1→2|0/0|
|011|6143|102|99|1.0303|99|1.0303|1162|weapon_autocannon 7→8; weapon_cryocannon 5→6; skill_homing 1→2|0/0|
|012|7305|106|108|0.9815|108|0.9815|1192|chip_attack 4→5; weapon_autocannon 8→9|0/0|
|013|10928|134|131|1.0229|131|1.0229|1231|weapon_cryocannon 6→7; weapon_scattergun 3→4|3/3|
|014|12159|142|138|1.0290|138|1.0290|1267|armor_kevlar 4→5; weapon_scattergun 4→5; signature 1→2|0/3|
|015|13426|155|147|1.0544|147|1.0544|870|vanguard 6→7|0/3|
|016|14296|157|98|1.6020|147|1.0680|1689|chip_attack 5→6; weapon_scattergun 5→6; skill_slow_field 1→2|0/3|
|017|15985|173|165|1.0485|165|1.0485|1654|weapon_railgun; weapon_railgun 1→2; weapon_scattergun 6→7; skill_critical 1→2; skill_split_shot 1→2|0/3|
|018|20959|201|185|1.0865|185|1.0865|1351|pet_turret_drone 2→3; weapon_railgun 5→6|3/6|
|019|22310|202|188|1.0745|188|1.0745|1830|weapon_scattergun 8→9; skill_multishot 2→3|0/6|
|020|31011|294|291|1.0103|291|1.0103|1947|weapon_scattergun 9→10|8/6|
|021|32958|298|164|1.8171|291|1.0241|1747|weapon_venomlauncher; weapon_venomlauncher 1→4|0/0|
|022|34705|298|183|1.6284|291|1.0241|1925|weapon_venomlauncher 4→6; skill_salvo 2→3|0/0|
|023|36630|298|186|1.6022|291|1.0241|2213|weapon_scattergun 10→11|0/0|
|024|38843|302|201|1.5025|291|1.0378|2031|weapon_cryocannon 9→10; weapon_venomlauncher 6→7; skill_charge_shot 2→3|0/0|
|025|40874|307|260|1.1808|291|1.0550|1433|weapon_railgun 8→9|0/0|
|026|42307|307|226|1.3584|291|1.0550|2384|chip_attack 7→8; weapon_venomlauncher 7→8; skill_slow_field 2→3|0/0|
|027|44691|309|195|1.5846|291|1.0619|2214|armor_kevlar 6→7; weapon_venomlauncher 8→9|0/0|
|028|46905|309|231|1.3377|291|1.0619|2434|weapon_scattergun 11→12; skill_split_shot 2→3|0/0|
|029|49339|321|206|1.5583|291|1.1031|2481|weapon_autocannon 10→12|0/0|
|030|57493|335|332|1.0090|332|1.0090|1939|weapon_railgun 10→11; skill_ricochet 2→3|3/3|
|031|59432|335|159|2.1069|332|1.0090|2881|weapon_flamethrower; weapon_flamethrower 1→8|0/0|
|032|62313|335|245|1.3673|332|1.0090|2649|weapon_plasmacannon; weapon_flamethrower 8→9; weapon_plasmacannon 1→4|0/0|
|033|64962|335|228|1.4693|332|1.0090|2436|pet_turret_drone 5→6; weapon_flamethrower 9→10; weapon_plasmacannon 4→5; signature 2→3|0/0|
|034|67398|363|330|1.1000|332|1.0934|2992|chip_attack 8→9; weapon_flamethrower 10→11; weapon_plasmacannon 5→6|0/0|
|035|70390|372|219|1.6986|332|1.1205|2258|armor_kevlar 7→8; weapon_plasmacannon 6→7|0/0|
|036|72648|372|225|1.6533|332|1.1205|2990|weapon_autocannon 12→13; weapon_flamethrower 11→12|0/0|
|037|75638|372|232|1.6034|332|1.1205|3389|vanguard 10→11; weapon_scattergun 12→13; skill_multishot 3→4|0/0|
|038|92202|492|484|1.0165|484|1.0165|3624|weapon_flamethrower 12→13; weapon_venomlauncher 10→11|6/6|
|039|113405|540|533|1.0131|533|1.0131|3113|weapon_scattergun 14→15|10/6|
|040|116518|576|574|1.0035|574|1.0035|4080|armor_kevlar 9→10; weapon_scattergun 15→16; skill_salvo 3→4|0/6|
|041|120598|602|236|2.5508|574|1.0488|4005|weapon_teslacoil; weapon_teslacoil 1→5|0/0|
|042|124603|602|375|1.6053|574|1.0488|3622|weapon_scattergun 16→17|0/0|
|043|128225|642|587|1.0937|587|1.0937|4212|weapon_cryocannon 15→16; weapon_teslacoil 5→7|0/0|
|044|149818|740|757|0.9775|757|0.9775|4077|weapon_scattergun 18→19; skill_split_shot 3→4|10/0|
|045|153895|796|655|1.2153|757|1.0515|4119|weapon_cryocannon 17→18; weapon_plasmacannon 10→11|0/0|
|046|158014|796|600|1.3267|757|1.0515|3600|weapon_teslacoil 10→11|0/0|
|047|161614|796|670|1.1881|757|1.0515|3991|weapon_scattergun 19→20|0/0|
|048|165605|853|663|1.2866|757|1.1268|4611|weapon_scattergun 20→21; skill_critical 3→4|0/0|
|049|170216|891|658|1.3541|757|1.1770|4581|weapon_scattergun 21→22|0/0|
|050|174797|947|868|1.0910|868|1.0910|3403|weapon_plasmacannon 11→12|0/0|
|051|178200|947|431|2.1972|868|1.0910|1492|weapon_autocannon 15→16|0/0|
|052|179692|947|349|2.7135|868|1.0910|1663|weapon_autocannon 16→17; signature 3→4|0/0|
|053|181355|959|427|2.2459|868|1.1048|1633|weapon_flamethrower 15→16|0/0|
|054|182988|959|359|2.6713|868|1.1048|1668|weapon_autocannon 17→18|0/0|
|055|184656|959|950|1.0095|950|1.0095|1689|vanguard 14→15; skill_ricochet 3→4|0/0|
|056|186345|995|354|2.8107|950|1.0474|1593|weapon_flamethrower 16→17|0/0|
|057|187938|995|990|1.0051|990|1.0051|2888|weapon_teslacoil 11→12|0/0|
|058|190826|995|503|1.9781|990|1.0051|1830|vanguard 15→16|0/0|
|059|192656|1021|562|1.8167|990|1.0313|1771|weapon_flamethrower 17→18|0/0|
|060|194427|1021|990|1.0313|990|1.0313|3863|armor_kevlar 11→12; weapon_venomlauncher 12→13|0/0|
|061|198290|1021|990|1.0313|990|1.0313|2230|weapon_railgun 13→14; skill_multishot 4→5|0/0|
|062|200520|1046|250|4.1840|990|1.0566|2299|weapon_railgun 14→15|0/0|
|063|202819|1046|576|1.8160|990|1.0566|2098|weapon_autocannon 18→19|0/0|
|064|204917|1046|955|1.0953|990|1.0566|2126|weapon_autocannon 19→20|0/0|
|065|207043|1046|1014|1.0316|1014|1.0316|2486|pet_turret_drone 9→10; vanguard 16→17|0/0|
|066|209529|1205|1184|1.0177|1184|1.0177|2059|weapon_cryocannon 18→19; skill_pierce 4→5|0/0|
|067|211588|1205|955|1.2618|1184|1.0177|2791|weapon_plasmacannon 12→13|0/0|
|068|214379|1205|1042|1.1564|1184|1.0177|2545|weapon_venomlauncher 13→14|0/0|
|069|216924|1205|978|1.2321|1184|1.0177|2638|weapon_autocannon 20→21|0/0|
|070|224071|1291|1286|1.0039|1286|1.0039|2538|weapon_railgun 15→16|3/3|
|071|226609|1291|1146|1.1265|1286|1.0039|2279|armor_kevlar 12→13; weapon_cryocannon 19→20|0/0|
|072|234671|1507|1576|0.9562|1576|0.9562|2181|weapon_flamethrower 19→20|5/5|
|073|236852|1507|818|1.8423|1576|0.9562|2367|weapon_autocannon 21→22|0/5|
|074|295155|2005|2034|0.9857|2034|0.9857|2899|weapon_autocannon 23→24|37/5|
|075|298054|2005|1841|1.0891|2034|0.9857|3049|weapon_railgun 18→19|0/5|
|076|318671|2680|2758|0.9717|2758|0.9717|2588|weapon_autocannon 24→25|10/5|
|077|321259|2680|1652|1.6223|2758|0.9717|2965|weapon_autocannon 25→26|0/5|
|078|324224|2680|2226|1.2040|2758|0.9717|2737|weapon_flamethrower 23→24|0/5|
|079|326961|2680|2030|1.3202|2758|0.9717|2979|weapon_railgun 19→20|0/5|
|080|329940|2680|2067|1.2966|2758|0.9717|3263|weapon_autocannon 26→27|0/5|
|081|333203|2680|1096|2.4453|2758|0.9717|2566|weapon_flamethrower 24→25|0/0|
|082|335769|2680|1762|1.5210|2758|0.9717|2524|weapon_autocannon 27→28|0/0|
|083|338293|2680|1815|1.4766|2758|0.9717|3026|vanguard 22→23|0/0|
|084|341319|2742|1265|2.1676|2758|0.9942|2589|weapon_autocannon 28→29|0/0|
|085|343908|2742|2204|1.2441|2758|0.9942|3610|weapon_venomlauncher 17→18|0/0|
|086|347518|2742|1855|1.4782|2758|0.9942|3429|weapon_flamethrower 25→26|0/0|
|087|350947|2742|1857|1.4766|2758|0.9942|3363|weapon_teslacoil 13→14|0/0|
|088|354310|2742|1857|1.4766|2758|0.9942|3086|vanguard 23→24|0/0|
|089|357396|3025|1994|1.5171|2758|1.0968|3360|weapon_plasmacannon 14→15|0/0|
|090|360756|3025|2751|1.0996|2758|1.0968|2796|weapon_autocannon 29→30|0/0|
|091|363552|3025|1234|2.4514|2758|1.0968|2785|weapon_flamethrower 26→27|0/0|
|092|366337|3025|1862|1.6246|2758|1.0968|4052|weapon_teslacoil 14→15|0/0|
|093|370389|3025|2266|1.3350|2758|1.0968|3424|weapon_railgun 20→21|0/0|
|094|373813|3025|1830|1.6530|2758|1.0968|3707|vanguard 24→25|0/0|
|095|383886|3443|3370|1.0217|3370|1.0217|3427|weapon_railgun 21→22|3/0|
|096|387313|3443|2429|1.4175|3370|1.0217|4577|weapon_plasmacannon 15→16|0/0|
|097|391890|3443|1863|1.8481|3370|1.0217|4288|weapon_teslacoil 15→16|0/0|
|098|396178|3443|2720|1.2658|3370|1.0217|4312|weapon_plasmacannon 16→17|0/0|
|099|400490|3443|3094|1.1128|3370|1.0217|3687|weapon_venomlauncher 18→19|0/0|
