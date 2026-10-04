状态：SEARCH_CANDIDATE_NOT_YET_FEASIBLE；待Fable签字，游戏数据未写入。

# 资源表 C 候选

§8.4离线假定3★首通，挑战首通优先；非门关每章最多6次，门关刷到R≥1、不限次数、照实列高度；全关P≤1.20E。不是运行时胜率。P(g)/F(g)与消费策略冻结，因子[0.5,2.0]；八把免费武器共用一个升级基价系数。
优化顺序：零硬约束失败 → 非门回刷次数 → Σ|P−E|/E。门次数完整披露，不参与第二目标。
优化前：69/99失败，目标36.608304。
优化后：15/99失败，目标9.551006。

缩放系数与逐字段旧/新对照完整列于同名JSON；所有候选仅在内存模拟。

|曲线|缩放系数/形式|
|---|---|
|first_clear_gold|[-0.24315434976331196, -0.19999283079663333]；existing authored per-level values × exp(a+b*(L-1)/98)|
|kill_gold_mult|[-0.4910044200090515, -0.11935502598504005]；existing authored per-level values × exp(a+b*(L-1)/98)|
|free_unlock_star|1.2451682810355265；existing free star tiers × constant|
|skill_base_xp_costs|[0.6623715678431924, 0.8562217224077878, 0.8723933608328281, 1.04348065787068, 1.2442084521533852]；same five authored cost tiers times positive monotone factors|
|sig_skill_xp_costs|[0.5153435217367096, 0.988975704299648, 0.9925952342232989, 1.0035285009048651, 1.0614096796785202]；same five authored cost tiers times positive monotone factors|
|free_weapon_cost|1.6；all existing free linear upgrade formulas × ONE common base-price factor|

|文件/字段|旧值|候选新值|系数|
|---|---:|---:|---:|
|data/levels.json/0/first_clear_reward/gold|119|93|0.78415047|
|data/levels.json/1/first_clear_reward/gold|143|112|0.78255185|
|data/levels.json/2/first_clear_reward/gold|167|130|0.78095649|
|data/levels.json/3/first_clear_reward/gold|192|150|0.77936439|
|data/levels.json/4/first_clear_reward/gold|216|168|0.77777553|
|data/levels.json/5/first_clear_reward/gold|241|187|0.77618991|
|data/levels.json/6/first_clear_reward/gold|266|206|0.77460752|
|data/levels.json/7/first_clear_reward/gold|291|225|0.77302835|
|data/levels.json/8/first_clear_reward/gold|315|243|0.77145241|
|data/levels.json/9/first_clear_reward/gold|340|262|0.76987968|
|data/levels.json/10/first_clear_reward/gold|366|281|0.76831015|
|data/levels.json/11/first_clear_reward/gold|391|300|0.76674383|
|data/levels.json/12/first_clear_reward/gold|416|318|0.7651807|
|data/levels.json/13/first_clear_reward/gold|442|338|0.76362075|
|data/levels.json/14/first_clear_reward/gold|467|356|0.76206399|
|data/levels.json/15/first_clear_reward/gold|493|375|0.7605104|
|data/levels.json/16/first_clear_reward/gold|519|394|0.75895997|
|data/levels.json/17/first_clear_reward/gold|545|413|0.75741271|
|data/levels.json/18/first_clear_reward/gold|571|432|0.7558686|
|data/levels.json/19/first_clear_reward/gold|597|450|0.75432764|
|data/levels.json/20/first_clear_reward/gold|623|469|0.75278982|
|data/levels.json/21/first_clear_reward/gold|650|488|0.75125514|
|data/levels.json/22/first_clear_reward/gold|676|507|0.74972358|
|data/levels.json/23/first_clear_reward/gold|703|526|0.74819515|
|data/levels.json/24/first_clear_reward/gold|729|544|0.74666983|
|data/levels.json/25/first_clear_reward/gold|756|563|0.74514762|
|data/levels.json/26/first_clear_reward/gold|783|582|0.74362852|
|data/levels.json/27/first_clear_reward/gold|810|601|0.74211251|
|data/levels.json/28/first_clear_reward/gold|837|620|0.74059959|
|data/levels.json/29/first_clear_reward/gold|864|639|0.73908976|
|data/levels.json/30/first_clear_reward/gold|892|658|0.73758301|
|data/levels.json/31/first_clear_reward/gold|919|676|0.73607932|
|data/levels.json/32/first_clear_reward/gold|947|696|0.73457871|
|data/levels.json/33/first_clear_reward/gold|975|715|0.73308115|
|data/levels.json/34/first_clear_reward/gold|1002|733|0.73158664|
|data/levels.json/35/first_clear_reward/gold|1030|752|0.73009519|
|data/levels.json/36/first_clear_reward/gold|1058|771|0.72860677|
|data/levels.json/37/first_clear_reward/gold|1086|790|0.72712139|
|data/levels.json/38/first_clear_reward/gold|1115|809|0.72563903|
|data/levels.json/39/first_clear_reward/gold|1143|828|0.7241597|
|data/levels.json/40/first_clear_reward/gold|1171|846|0.72268338|
|data/levels.json/41/first_clear_reward/gold|1200|865|0.72121007|
|data/levels.json/42/first_clear_reward/gold|1229|885|0.71973977|
|data/levels.json/43/first_clear_reward/gold|1257|903|0.71827246|
|data/levels.json/44/first_clear_reward/gold|1286|922|0.71680815|
|data/levels.json/45/first_clear_reward/gold|1315|941|0.71534682|
|data/levels.json/46/first_clear_reward/gold|1344|959|0.71388847|
|data/levels.json/47/first_clear_reward/gold|1374|979|0.71243309|
|data/levels.json/48/first_clear_reward/gold|1403|998|0.71098068|
|data/levels.json/49/first_clear_reward/gold|1432|1016|0.70953123|
|data/levels.json/50/first_clear_reward/gold|1462|1035|0.70808474|
|data/levels.json/51/first_clear_reward/gold|1492|1054|0.70664119|
|data/levels.json/52/first_clear_reward/gold|1521|1073|0.70520059|
|data/levels.json/53/first_clear_reward/gold|1551|1092|0.70376292|
|data/levels.json/54/first_clear_reward/gold|1581|1110|0.70232819|
|data/levels.json/55/first_clear_reward/gold|1611|1129|0.70089638|
|data/levels.json/56/first_clear_reward/gold|1642|1149|0.69946749|
|data/levels.json/57/first_clear_reward/gold|1672|1167|0.69804151|
|data/levels.json/58/first_clear_reward/gold|1702|1186|0.69661844|
|data/levels.json/59/first_clear_reward/gold|1733|1205|0.69519827|
|data/levels.json/60/first_clear_reward/gold|1764|1224|0.69378099|
|data/levels.json/61/first_clear_reward/gold|1794|1242|0.69236661|
|data/levels.json/62/first_clear_reward/gold|1825|1261|0.69095511|
|data/levels.json/63/first_clear_reward/gold|1856|1280|0.68954648|
|data/levels.json/64/first_clear_reward/gold|1887|1299|0.68814073|
|data/levels.json/65/first_clear_reward/gold|1919|1318|0.68673784|
|data/levels.json/66/first_clear_reward/gold|1950|1336|0.68533782|
|data/levels.json/67/first_clear_reward/gold|1981|1355|0.68394064|
|data/levels.json/68/first_clear_reward/gold|2013|1374|0.68254632|
|data/levels.json/69/first_clear_reward/gold|2044|1392|0.68115484|
|data/levels.json/70/first_clear_reward/gold|2076|1411|0.67976619|
|data/levels.json/71/first_clear_reward/gold|2108|1430|0.67838038|
|data/levels.json/72/first_clear_reward/gold|2140|1449|0.67699739|
|data/levels.json/73/first_clear_reward/gold|2172|1467|0.67561722|
|data/levels.json/74/first_clear_reward/gold|2204|1486|0.67423987|
|data/levels.json/75/first_clear_reward/gold|2237|1505|0.67286532|
|data/levels.json/76/first_clear_reward/gold|2269|1524|0.67149358|
|data/levels.json/77/first_clear_reward/gold|2302|1543|0.67012463|
|data/levels.json/78/first_clear_reward/gold|2334|1561|0.66875847|
|data/levels.json/79/first_clear_reward/gold|2367|1580|0.6673951|
|data/levels.json/80/first_clear_reward/gold|2400|1598|0.6660345|
|data/levels.json/81/first_clear_reward/gold|2433|1617|0.66467668|
|data/levels.json/82/first_clear_reward/gold|2466|1636|0.66332163|
|data/levels.json/83/first_clear_reward/gold|2499|1654|0.66196934|
|data/levels.json/84/first_clear_reward/gold|2532|1673|0.66061981|
|data/levels.json/85/first_clear_reward/gold|2566|1692|0.65927303|
|data/levels.json/86/first_clear_reward/gold|2599|1710|0.657929|
|data/levels.json/87/first_clear_reward/gold|2633|1729|0.6565877|
|data/levels.json/88/first_clear_reward/gold|2667|1748|0.65524914|
|data/levels.json/89/first_clear_reward/gold|2700|1766|0.65391331|
|data/levels.json/90/first_clear_reward/gold|2734|1784|0.6525802|
|data/levels.json/91/first_clear_reward/gold|2769|1803|0.65124981|
|data/levels.json/92/first_clear_reward/gold|2803|1822|0.64992213|
|data/levels.json/93/first_clear_reward/gold|2837|1840|0.64859716|
|data/levels.json/94/first_clear_reward/gold|2871|1858|0.64727489|
|data/levels.json/95/first_clear_reward/gold|2906|1877|0.64595531|
|data/levels.json/96/first_clear_reward/gold|2940|1895|0.64463843|
|data/levels.json/97/first_clear_reward/gold|2975|1914|0.64332423|
|data/levels.json/98/first_clear_reward/gold|3010|1932|0.64201271|
|data/levels.json/0/reward_gold_mult|0.56|0.34272637|0.61201137|
|data/levels.json/1/reward_gold_mult|0.55|0.33619655|0.61126645|
|data/levels.json/2/reward_gold_mult|0.55|0.33578734|0.61052244|
|data/levels.json/3/reward_gold_mult|0.55|0.33537863|0.60977933|
|data/levels.json/4/reward_gold_mult|0.54|0.32888005|0.60903712|
|data/levels.json/5/reward_gold_mult|0.54|0.32847975|0.60829582|
|data/levels.json/6/reward_gold_mult|0.53|0.32200438|0.60755543|
|data/levels.json/7/reward_gold_mult|0.53|0.32161244|0.60681593|
|data/levels.json/8/reward_gold_mult|0.53|0.32122099|0.60607733|
|data/levels.json/9/reward_gold_mult|0.52|0.31477661|0.60533964|
|data/levels.json/10/reward_gold_mult|0.52|0.31439348|0.60460284|
|data/levels.json/11/reward_gold_mult|0.52|0.31401081|0.60386693|
|data/levels.json/12/reward_gold_mult|0.51|0.30759728|0.60313193|
|data/levels.json/13/reward_gold_mult|0.51|0.30722289|0.60239782|
|data/levels.json/14/reward_gold_mult|0.51|0.30684894|0.6016646|
|data/levels.json/15/reward_gold_mult|0.5|0.30046613|0.60093227|
|data/levels.json/16/reward_gold_mult|0.5|0.30010042|0.60020083|
|data/levels.json/17/reward_gold_mult|0.5|0.29973515|0.59947029|
|data/levels.json/18/reward_gold_mult|0.49|0.29338291|0.59874063|
|data/levels.json/19/reward_gold_mult|0.49|0.29302582|0.59801187|
|data/levels.json/20/reward_gold_mult|0.48|0.28669631|0.59728399|
|data/levels.json/21/reward_gold_mult|0.48|0.28634736|0.59655699|
|data/levels.json/22/reward_gold_mult|0.48|0.28599882|0.59583088|
|data/levels.json/23/reward_gold_mult|0.47|0.27969966|0.59510566|
|data/levels.json/24/reward_gold_mult|0.47|0.27935922|0.59438131|
|data/levels.json/25/reward_gold_mult|0.47|0.27901919|0.59365785|
|data/levels.json/26/reward_gold_mult|0.46|0.27275023|0.59293527|
|data/levels.json/27/reward_gold_mult|0.46|0.27241824|0.59221357|
|data/levels.json/28/reward_gold_mult|0.46|0.27208666|0.59149275|
|data/levels.json/29/reward_gold_mult|0.45|0.26584776|0.5907728|
|data/levels.json/30/reward_gold_mult|0.45|0.26552418|0.59005373|
|data/levels.json/31/reward_gold_mult|0.44|0.25930764|0.58933554|
|data/levels.json/32/reward_gold_mult|0.44|0.25899202|0.58861822|
|data/levels.json/33/reward_gold_mult|0.44|0.25867678|0.58790177|
|data/levels.json/34/reward_gold_mult|0.43|0.25249007|0.5871862|
|data/levels.json/35/reward_gold_mult|0.43|0.25218274|0.58647149|
|data/levels.json/36/reward_gold_mult|0.43|0.25187579|0.58575766|
|data/levels.json/37/reward_gold_mult|0.42|0.24571877|0.5850447|
|data/levels.json/38/reward_gold_mult|0.42|0.24541969|0.5843326|
|data/levels.json/39/reward_gold_mult|0.42|0.24512097|0.58362137|
|data/levels.json/40/reward_gold_mult|0.41|0.23899351|0.582911|
|data/levels.json/41/reward_gold_mult|0.41|0.23870262|0.5822015|
|data/levels.json/42/reward_gold_mult|0.41|0.23841208|0.58149287|
|data/levels.json/43/reward_gold_mult|0.4|0.23231404|0.58078509|
|data/levels.json/44/reward_gold_mult|0.4|0.23203127|0.58007818|
|data/levels.json/45/reward_gold_mult|0.39|0.22595513|0.57937213|
|data/levels.json/46/reward_gold_mult|0.39|0.2256801|0.57866694|
|data/levels.json/47/reward_gold_mult|0.39|0.22540541|0.5779626|
|data/levels.json/48/reward_gold_mult|0.38|0.21935847|0.57725912|
|data/levels.json/49/reward_gold_mult|0.38|0.21909147|0.5765565|
|data/levels.json/50/reward_gold_mult|0.38|0.2188248|0.57585474|
|data/levels.json/51/reward_gold_mult|0.37|0.21280692|0.57515383|
|data/levels.json/52/reward_gold_mult|0.37|0.21254789|0.57445377|
|data/levels.json/53/reward_gold_mult|0.37|0.21228919|0.57375456|
|data/levels.json/54/reward_gold_mult|0.36|0.20630023|0.57305621|
|data/levels.json/55/reward_gold_mult|0.36|0.20604913|0.5723587|
|data/levels.json/56/reward_gold_mult|0.35|0.20008172|0.57166205|
|data/levels.json/57/reward_gold_mult|0.35|0.19983818|0.57096624|
|data/levels.json/58/reward_gold_mult|0.35|0.19959495|0.57027128|
|data/levels.json/59/reward_gold_mult|0.34|0.19365623|0.56957716|
|data/levels.json/60/reward_gold_mult|0.34|0.19342052|0.56888389|
|data/levels.json/61/reward_gold_mult|0.34|0.1931851|0.56819146|
|data/levels.json/62/reward_gold_mult|0.33|0.18727496|0.56749988|
|data/levels.json/63/reward_gold_mult|0.33|0.18704702|0.56680914|
|data/levels.json/64/reward_gold_mult|0.33|0.18681935|0.56611924|
|data/levels.json/65/reward_gold_mult|0.32|0.18093766|0.56543017|
|data/levels.json/66/reward_gold_mult|0.32|0.18071742|0.56474195|
|data/levels.json/67/reward_gold_mult|0.32|0.18049746|0.56405457|
|data/levels.json/68/reward_gold_mult|0.31|0.17464409|0.56336802|
|data/levels.json/69/reward_gold_mult|0.31|0.17443151|0.5626823|
|data/levels.json/70/reward_gold_mult|0.3|0.16859923|0.56199743|
|data/levels.json/71/reward_gold_mult|0.3|0.16839401|0.56131338|
|data/levels.json/72/reward_gold_mult|0.3|0.16818905|0.56063017|
|data/levels.json/73/reward_gold_mult|0.29|0.16238486|0.55994779|
|data/levels.json/74/reward_gold_mult|0.29|0.16218721|0.55926624|
|data/levels.json/75/reward_gold_mult|0.29|0.1619898|0.55858552|
|data/levels.json/76/reward_gold_mult|0.28|0.15621358|0.55790563|
|data/levels.json/77/reward_gold_mult|0.28|0.15602344|0.55722656|
|data/levels.json/78/reward_gold_mult|0.28|0.15583353|0.55654832|
|data/levels.json/79/reward_gold_mult|0.27|0.15008515|0.55587091|
|data/levels.json/80/reward_gold_mult|0.27|0.14990247|0.55519432|
|data/levels.json/81/reward_gold_mult|0.26|0.14417483|0.55451856|
|data/levels.json/82/reward_gold_mult|0.26|0.14399934|0.55384362|
|data/levels.json/83/reward_gold_mult|0.26|0.14382407|0.5531695|
|data/levels.json/84/reward_gold_mult|0.26|0.14364901|0.5524962|
|data/levels.json/85/reward_gold_mult|0.26|0.14347417|0.55182372|
|data/levels.json/86/reward_gold_mult|0.26|0.14329953|0.55115206|
|data/levels.json/87/reward_gold_mult|0.26|0.14312511|0.55048121|
|data/levels.json/88/reward_gold_mult|0.26|0.14295091|0.54981118|
|data/levels.json/89/reward_gold_mult|0.26|0.14277691|0.54914197|
|data/levels.json/90/reward_gold_mult|0.26|0.14260313|0.54847357|
|data/levels.json/91/reward_gold_mult|0.26|0.14242956|0.54780599|
|data/levels.json/92/reward_gold_mult|0.26|0.1422562|0.54713922|
|data/levels.json/93/reward_gold_mult|0.26|0.14208305|0.54647326|
|data/levels.json/94/reward_gold_mult|0.26|0.14191011|0.54580811|
|data/levels.json/95/reward_gold_mult|0.26|0.14173738|0.54514377|
|data/levels.json/96/reward_gold_mult|0.26|0.14156486|0.54448024|
|data/levels.json/97/reward_gold_mult|0.26|0.14139255|0.54381752|
|data/levels.json/98/reward_gold_mult|0.26|0.14122046|0.5431556|
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
|data/economy.json/skill_base_xp_costs/3|4000|4174|1.0434807|
|data/economy.json/skill_base_xp_costs/4|8500|10576|1.2442085|
|data/economy.json/sig_skill_xp_costs/0|450|232|0.51534352|
|data/economy.json/sig_skill_xp_costs/1|1200|1187|0.9889757|
|data/economy.json/sig_skill_xp_costs/2|2700|2680|0.99259523|
|data/economy.json/sig_skill_xp_costs/3|5400|5419|1.0035285|
|data/economy.json/sig_skill_xp_costs/4|11000|11676|1.0614097|
|data/weapons.json/weapon_autocannon/cost_base_gold|100|160|1.6|
|data/weapons.json/weapon_flamethrower/cost_base_gold|180|288|1.6|
|data/weapons.json/weapon_cryocannon/cost_base_gold|180|288|1.6|
|data/weapons.json/weapon_teslacoil/cost_base_gold|240|384|1.6|
|data/weapons.json/weapon_venomlauncher/cost_base_gold|240|384|1.6|
|data/weapons.json/weapon_railgun/cost_base_gold|320|512|1.6|
|data/weapons.json/weapon_scattergun/cost_base_gold|180|288|1.6|
|data/weapons.json/weapon_plasmacannon/cost_base_gold|320|512|1.6|

|关卡|rec|E|旧P|新P|新R|新P/E|下限|上限|达标|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
|001|50|65|65|65|1.3000|1.0000|48|78|True|
|002|50|65|69|68|1.3600|1.0462|48|78|True|
|003|50|65|73|70|1.4000|1.0769|48|78|True|
|004|64|65|74|73|1.1406|1.1231|61|78|True|
|005|76|76|81|78|1.0263|1.0263|76|91|True|
|006|53|76|82|82|1.5472|1.0789|51|91|True|
|007|53|76|89|82|1.5472|1.0789|53|91|True|
|008|79|79|96|85|1.0759|1.0759|79|94|True|
|009|79|79|106|91|1.1519|1.1519|79|94|True|
|010|87|87|112|93|1.0690|1.0690|87|104|True|
|011|99|99|116|101|1.0202|1.0202|95|118|True|
|012|108|108|122|103|0.9537|0.9537|103|129|True|
|013|131|131|131|126|0.9618|0.9618|125|157|True|
|014|138|138|141|139|1.0072|1.0072|132|165|True|
|015|147|147|151|155|1.0544|1.0544|147|176|True|
|016|98|147|152|155|1.5816|1.0544|94|176|True|
|017|165|165|166|169|1.0242|1.0242|165|198|True|
|018|185|185|207|201|1.0865|1.0865|185|222|True|
|019|188|188|210|202|1.0745|1.0745|188|225|True|
|020|291|291|291|294|1.0103|1.0103|0|349|True|
|021|164|291|323|298|1.8171|1.0241|156|349|True|
|022|183|291|339|298|1.6284|1.0241|174|349|True|
|023|186|291|355|300|1.6129|1.0309|177|349|True|
|024|201|291|374|311|1.5473|1.0687|191|349|True|
|025|260|291|410|317|1.2192|1.0893|260|349|True|
|026|226|291|410|317|1.4027|1.0893|215|349|True|
|027|195|291|410|333|1.7077|1.1443|195|349|True|
|028|231|291|474|352|1.5238|1.2096|231|349|False|
|029|206|291|509|352|1.7087|1.2096|206|349|False|
|030|332|332|515|359|1.0813|1.0813|332|398|True|
|031|159|332|522|359|2.2579|1.0813|152|398|True|
|032|245|332|530|359|1.4653|1.0813|233|398|True|
|033|228|332|573|379|1.6623|1.1416|217|398|True|
|034|330|332|573|379|1.1485|1.1416|314|398|True|
|035|219|332|648|428|1.9543|1.2892|219|398|False|
|036|225|332|679|428|1.9022|1.2892|214|398|False|
|037|232|332|685|499|2.1509|1.5030|232|398|False|
|038|484|484|710|514|1.0620|1.0620|484|580|True|
|039|533|533|849|536|1.0056|1.0056|533|639|True|
|040|574|574|849|580|1.0105|1.0105|0|688|True|
|041|236|574|880|605|2.5636|1.0540|225|688|True|
|042|375|574|942|641|1.7093|1.1167|357|688|True|
|043|587|587|951|641|1.0920|1.0920|558|704|True|
|044|757|757|957|759|1.0026|1.0026|0|908|True|
|045|655|757|963|814|1.2427|1.0753|655|908|True|
|046|600|757|972|862|1.4367|1.1387|570|908|True|
|047|670|757|983|901|1.3448|1.1902|670|908|True|
|048|663|757|983|901|1.3590|1.1902|663|908|True|
|049|658|757|1008|948|1.4407|1.2523|658|908|False|
|050|868|868|1068|954|1.0991|1.0991|868|1041|True|
|051|431|868|1185|957|2.2204|1.1025|410|1041|True|
|052|349|868|1185|957|2.7421|1.1025|332|1041|True|
|053|427|868|1185|957|2.2412|1.1025|406|1041|True|
|054|359|868|1185|992|2.7632|1.1429|342|1041|True|
|055|950|950|1185|992|1.0442|1.0442|950|1140|True|
|056|354|950|1237|992|2.8023|1.0442|337|1140|True|
|057|990|990|1237|1003|1.0131|1.0131|990|1188|True|
|058|503|990|1284|1003|1.9940|1.0131|503|1188|True|
|059|562|990|1284|1003|1.7847|1.0131|562|1188|True|
|060|990|990|1300|1202|1.2141|1.2141|990|1188|False|
|061|990|990|1491|1202|1.2141|1.2141|941|1188|False|
|062|250|990|1577|1202|4.8080|1.2141|238|1188|False|
|063|576|990|1763|1202|2.0868|1.2141|548|1188|False|
|064|955|990|1763|1202|1.2586|1.2141|908|1188|False|
|065|1014|1014|1813|1214|1.1972|1.1972|1014|1216|True|
|066|1184|1184|1813|1250|1.0557|1.0557|1125|1420|True|
|067|955|1184|1813|1250|1.3089|1.0557|955|1420|True|
|068|1042|1184|1814|1250|1.1996|1.0557|1042|1420|True|
|069|978|1184|2043|1250|1.2781|1.0557|978|1420|True|
|070|1286|1286|2043|1327|1.0319|1.0319|1286|1543|True|
|071|1146|1286|2202|1327|1.1579|1.0319|1089|1543|True|
|072|1576|1576|2308|1544|0.9797|0.9797|1498|1891|True|
|073|818|1576|2308|1554|1.8998|0.9860|778|1891|True|
|074|2034|2034|2429|2038|1.0020|1.0020|0|2440|True|
|075|1841|2034|2733|2038|1.1070|1.0020|1841|2440|True|
|076|2758|2758|2989|2760|1.0007|1.0007|0|3309|True|
|077|1652|2758|3160|2760|1.6707|1.0007|1652|3309|True|
|078|2226|2758|3160|2760|1.2399|1.0007|2226|3309|True|
|079|2030|2758|3160|2760|1.3596|1.0007|2030|3309|True|
|080|2067|2758|3220|2760|1.3353|1.0007|2067|3309|True|
|081|1096|2758|3270|2760|2.5182|1.0007|1042|3309|True|
|082|1762|2758|3270|3164|1.7957|1.1472|1674|3309|True|
|083|1815|2758|3270|3164|1.7433|1.1472|1725|3309|True|
|084|1265|2758|3271|3164|2.5012|1.1472|1202|3309|True|
|085|2204|2758|3271|3239|1.4696|1.1744|2204|3309|True|
|086|1855|2758|3538|3239|1.7461|1.1744|1763|3309|True|
|087|1857|2758|3639|3239|1.7442|1.1744|1857|3309|True|
|088|1857|2758|3700|3239|1.7442|1.1744|1857|3309|True|
|089|1994|2758|3974|3239|1.6244|1.1744|1994|3309|True|
|090|2751|2758|3994|3239|1.1774|1.1744|2751|3309|True|
|091|1234|2758|4401|3357|2.7204|1.2172|1173|3309|False|
|092|1862|2758|4401|3357|1.8029|1.2172|1769|3309|False|
|093|2266|2758|4404|3357|1.4815|1.2172|2153|3309|False|
|094|1830|2758|4406|3357|1.8344|1.2172|1739|3309|False|
|095|3370|3370|4415|3429|1.0175|1.0175|0|4044|True|
|096|2429|3370|4415|3429|1.4117|1.0175|2308|4044|True|
|097|1863|3370|4415|3429|1.8406|1.0175|1863|4044|True|
|098|2720|3370|5163|3429|1.2607|1.0175|2720|4044|True|
|099|3094|3370|5283|3429|1.1083|1.0175|3094|4044|True|

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

首次R<0.95：None；G1走廊不满足关数：15/99。

包络目标Σ|P−E|/E：9.551006。

回刷总数：76（非门12，门64）；各章非门：{'1': 0, '2': 6, '3': 0, '4': 2, '5': 0, '6': 0, '7': 2, '8': 2, '9': 0, '10': 0}。
门关：[20, 40, 44, 74, 76, 95]；预算后新增门：[40, 44, 74]；未刷够门：[]；非门失败：[28, 29, 35, 36, 37, 49, 60, 61, 62, 63, 64, 91, 92, 93, 94]。

|回刷位置|路线(挑战/普通)|入场P|回刷后P|次数|非门章累计|刷够|八墙关|门高度/路线注记|
|---|---|---:|---:|---:|---:|---|---|---|
|013|012挑, 011挑, 010挑|104|126|3|3|True|False|非门|
|018|017挑, 016挑, 015挑|178|201|3|6|True|True|非门|
|020|019挑, 018挑, 014挑, 013挑, 009挑, 008挑, 007挑, 006挑, 005挑|203|294|9|6|True|True|9 / 仅挑战 / Owner fixed gate|
|039|038挑, 037挑|522|536|2|2|True|False|非门|
|040|039挑, 036挑, 035挑, 034挑, 033挑, 032挑, 031挑|539|580|7|2|True|True|7 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|044|043挑, 042挑, 041挑, 040挑, 030挑, 029挑, 028挑, 027挑, 026挑|656|759|9|0|True|True|9 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|070|069挑, 068挑|1250|1327|2|2|True|False|非门|
|072|071挑, 070挑|1327|1544|2|2|True|False|非门|
|074|073挑, 072挑, 067挑, 066挑, 065挑, 064挑, 063挑, 062挑, 061挑, 060挑, 059挑, 058挑, 057挑, 056挑, 055挑, 054挑, 053挑, 052挑, 051挑, 050挑, 049挑, 048挑, 047挑, 046挑, 045挑, 044挑, 025挑, 024挑|1554|2038|28|2|True|False|28 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|076|075挑, 074挑, 023挑, 022挑, 021挑, 020挑, 004挑, 003挑, 002挑|2331|2760|9|2|True|True|9 / 可付费（未做运行时验证） / Owner fixed gate|
|095|094挑, 093挑|3357|3429|2|0|True|False|2 / 可付费（未做运行时验证） / Owner fixed gate|

## 门关高度（含无需回刷的固定门）

|门|高度|已刷够|路径|原因|
|---|---:|---|---|---|
|020|9|True|仅挑战|Owner fixed gate|
|040|7|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|044|9|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|074|28|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|076|9|True|可付费（未做运行时验证）|Owner fixed gate|
|095|2|True|可付费（未做运行时验证）|Owner fixed gate|

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|当关/章累计回刷|
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
|001|0|65|50|1.3000|65|1.0000|312|vanguard 1→2; weapon_autocannon 1→2; skill_multishot 0→1|0/0|
|002|312|68|50|1.3600|65|1.0462|420|weapon_autocannon 2→3; skill_pierce 0→1|0/0|
|003|732|70|50|1.4000|65|1.0769|498|vanguard 2→3; weapon_autocannon 3→4; skill_barrier 0→1; skill_homing 0→1|0/0|
|004|1230|73|64|1.1406|65|1.1231|566|weapon_cryocannon; weapon_autocannon 4→5; skill_charge_shot 0→1; skill_salvo 0→1|0/0|
|005|1796|78|76|1.0263|76|1.0263|685|weapon_autocannon 5→6; skill_slow_field 0→1; signature 0→1|0/0|
|006|2481|82|53|1.5472|76|1.0789|739|weapon_cryocannon 1→3; skill_critical 0→1; skill_split_shot 0→1|0/0|
|007|3220|82|53|1.5472|76|1.0789|754|armor_kevlar; armor_kevlar 1→2; weapon_autocannon 6→7; skill_ricochet 0→1|0/0|
|008|3974|85|79|1.0759|79|1.0759|985|armor_kevlar 2→3; weapon_autocannon 7→8; skill_multishot 1→2|0/0|
|009|4959|91|79|1.1519|79|1.1519|768|armor_kevlar 3→4; vanguard 3→4|0/0|
|010|5727|93|87|1.0690|87|1.0690|798|chip_attack; weapon_autocannon 8→9; skill_pierce 1→2|0/0|
|011|6525|101|99|1.0202|99|1.0202|1221|chip_attack 1→2; weapon_autocannon 9→10; skill_homing 1→2|0/0|
|012|7746|103|108|0.9537|108|0.9537|1255|weapon_autocannon 10→11|0/0|
|013|11432|126|131|0.9618|131|0.9618|1297|vanguard 5→6; weapon_scattergun 3→4|3/3|
|014|12729|139|138|1.0072|138|1.0072|1337|armor_kevlar 4→5; chip_attack 4→5; weapon_scattergun 4→5; signature 1→2|0/3|
|015|14066|155|147|1.0544|147|1.0544|914|weapon_cryocannon 4→5|0/3|
|016|14980|155|98|1.5816|147|1.0544|1766|vanguard 6→7; weapon_scattergun 5→6; skill_slow_field 1→2|0/3|
|017|16746|169|165|1.0242|165|1.0242|1735|weapon_railgun; weapon_railgun 1→2; weapon_scattergun 6→7; skill_split_shot 1→2|0/3|
|018|21771|201|185|1.0865|185|1.0865|1435|weapon_scattergun 7→8|3/6|
|019|23206|202|188|1.0745|188|1.0745|1918|weapon_scattergun 8→9; skill_multishot 2→3|0/6|
|020|32512|294|291|1.0103|291|1.0103|2015|weapon_scattergun 9→10|9/6|
|021|34527|298|164|1.8171|291|1.0241|1841|weapon_venomlauncher; weapon_venomlauncher 1→4; skill_salvo 2→3|0/0|
|022|36368|298|183|1.6284|291|1.0241|1956|vanguard 8→9; weapon_venomlauncher 4→5|0/0|
|023|38324|300|186|1.6129|291|1.0309|2251|weapon_scattergun 10→11; skill_charge_shot 2→3|0/0|
|024|40575|311|201|1.5473|291|1.0687|2098|chip_attack 8→9; weapon_venomlauncher 5→6|0/0|
|025|42673|317|260|1.2192|291|1.0893|1497|weapon_cryocannon 7→8|0/0|
|026|44170|317|226|1.4027|291|1.0893|2433|weapon_scattergun 11→12; skill_slow_field 2→3|0/0|
|027|46603|333|195|1.7077|291|1.1443|2257|weapon_scattergun 12→13|0/0|
|028|48860|352|231|1.5238|291|1.2096|2550|armor_kevlar 7→8; weapon_railgun 5→6; skill_split_shot 2→3|0/0|
|029|51410|352|206|1.7087|291|1.2096|2600|chip_attack 9→10; weapon_venomlauncher 6→7|0/0|
|030|54010|359|332|1.0813|332|1.0813|2059|weapon_venomlauncher 7→8; skill_critical 2→3|0/0|
|031|56069|359|159|2.2579|332|1.0813|2863|weapon_flamethrower; armor_kevlar 8→9; weapon_flamethrower 1→5|0/0|
|032|58932|359|245|1.4653|332|1.0813|2697|weapon_plasmacannon; weapon_scattergun 13→14; skill_ricochet 2→3|0/0|
|033|61629|379|228|1.6623|332|1.1416|2477|weapon_flamethrower 5→6; weapon_plasmacannon 1→3|0/0|
|034|64106|379|330|1.1485|332|1.1416|3125|weapon_scattergun 14→15|0/0|
|035|67231|428|219|1.9543|332|1.2892|2337|weapon_flamethrower 6→7; weapon_plasmacannon 3→4|0/0|
|036|69568|428|225|1.9022|332|1.2892|3002|weapon_scattergun 15→16; signature 2→3|0/0|
|037|72570|499|232|2.1509|332|1.5030|3513|weapon_scattergun 16→17|0/0|
|038|76083|514|484|1.0620|484|1.0620|3690|weapon_scattergun 17→18|0/0|
|039|85415|536|533|1.0056|533|1.0056|3141|pet_turret_drone 6→7; weapon_plasmacannon 6→7|2/2|
|040|103159|580|574|1.0105|574|1.0105|4168|weapon_scattergun 18→19; skill_homing 3→4|7/2|
|041|107327|605|236|2.5636|574|1.0540|3931|weapon_teslacoil; vanguard 11→12; weapon_teslacoil 1→5|0/0|
|042|111258|641|375|1.7093|574|1.1167|3656|weapon_teslacoil 5→7|0/0|
|043|114914|641|587|1.0920|587|1.0920|4281|armor_kevlar 9→10; weapon_scattergun 19→20; skill_barrier 3→4|0/0|
|044|140701|759|757|1.0026|757|1.0026|4235|weapon_scattergun 20→21|9/0|
|045|144936|814|655|1.2427|757|1.0753|4254|weapon_scattergun 21→22|0/0|
|046|149190|862|600|1.4367|757|1.1387|3726|vanguard 13→14; weapon_plasmacannon 8→9; skill_slow_field 3→4|0/0|
|047|152916|901|670|1.3448|757|1.1902|3964|armor_kevlar 10→11; weapon_railgun 8→9|0/0|
|048|156880|901|663|1.3590|757|1.1902|4654|weapon_scattergun 22→23|0/0|
|049|161534|948|658|1.4407|757|1.2523|4609|weapon_scattergun 23→24; skill_split_shot 3→4|0/0|
|050|166143|954|868|1.0991|868|1.0991|3476|chip_attack 12→13; weapon_teslacoil 9→10|0/0|
|051|169619|957|431|2.2204|868|1.1025|1657|weapon_autocannon 15→16|0/0|
|052|171276|957|349|2.7421|868|1.1025|1821|weapon_autocannon 16→17|0/0|
|053|173097|957|427|2.2412|868|1.1025|1795|vanguard 14→15; skill_critical 3→4|0/0|
|054|174892|992|359|2.7632|868|1.1429|1812|weapon_autocannon 17→18|0/0|
|055|176704|992|950|1.0442|950|1.0442|1864|weapon_autocannon 18→19; skill_ricochet 3→4|0/0|
|056|178568|992|354|2.8023|950|1.0442|1741|vanguard 15→16|0/0|
|057|180309|1003|990|1.0131|990|1.0131|3009|weapon_venomlauncher 9→10|0/0|
|058|183318|1003|503|1.9940|990|1.0131|1971|weapon_cryocannon 11→12|0/0|
|059|185289|1003|562|1.7847|990|1.0131|1941|weapon_flamethrower 11→12; signature 3→4|0/0|
|060|187230|1202|990|1.2141|990|1.2141|3899|weapon_plasmacannon 9→10|0/0|
|061|191129|1202|990|1.2141|990|1.2141|2361|weapon_teslacoil 10→11|0/0|
|062|193490|1202|250|4.8080|990|1.2141|2392|weapon_autocannon 19→20|0/0|
|063|195882|1202|576|2.0868|990|1.2141|2233|weapon_cryocannon 12→13|0/0|
|064|198115|1202|955|1.2586|990|1.2141|2281|armor_kevlar 11→12; pet_turret_drone 8→9|0/0|
|065|200396|1214|1014|1.1972|1014|1.1972|2603|weapon_venomlauncher 10→11; skill_multishot 4→5|0/0|
|066|202999|1250|1184|1.0557|1184|1.0557|2206|weapon_flamethrower 12→13|0/0|
|067|205205|1250|955|1.3089|1184|1.0557|2876|weapon_cryocannon 13→14|0/0|
|068|208081|1250|1042|1.1996|1184|1.0557|2638|weapon_flamethrower 13→14|0/0|
|069|210719|1250|978|1.2781|1184|1.0557|2750|weapon_cryocannon 14→15|0/0|
|070|216128|1327|1286|1.0319|1286|1.0319|2641|weapon_autocannon 20→21|2/2|
|071|218769|1327|1146|1.1579|1286|1.0319|2403|weapon_autocannon 21→22|0/0|
|072|223413|1544|1576|0.9797|1576|0.9797|2298|armor_kevlar 12→13; chip_attack 14→15|2/2|
|073|225711|1554|818|1.8998|1576|0.9860|2493|weapon_autocannon 22→23|0/2|
|074|273143|2038|2034|1.0020|2034|1.0020|2971|weapon_teslacoil 13→14|28/2|
|075|276114|2038|1841|1.1070|2034|1.0020|3104|weapon_flamethrower 14→15; signature 4→5|0/2|
|076|289581|2760|2758|1.0007|2758|1.0007|2703|weapon_autocannon 24→25; skill_split_shot 4→5|9/2|
|077|292284|2760|1652|1.6707|2758|1.0007|3060|weapon_autocannon 25→26|0/2|
|078|295344|2760|2226|1.2399|2758|1.0007|2831|weapon_autocannon 26→27|0/2|
|079|298175|2760|2030|1.3596|2758|1.0007|3077|weapon_cryocannon 15→16|0/2|
|080|301252|2760|2067|1.3353|2758|1.0007|3357|weapon_flamethrower 15→16; skill_critical 4→5|0/2|
|081|304609|2760|1096|2.5182|2758|1.0007|2654|vanguard 21→22|0/0|
|082|307263|3164|1762|1.7957|2758|1.1472|2673|weapon_cryocannon 16→17|0/0|
|083|309936|3164|1815|1.7433|2758|1.1472|3160|weapon_flamethrower 16→17|0/0|
|084|313096|3164|1265|2.5012|2758|1.1472|2722|vanguard 22→23; skill_ricochet 4→5|0/0|
|085|315818|3239|2204|1.4696|2758|1.1744|3675|weapon_plasmacannon 11→12|0/0|
|086|319493|3239|1855|1.7461|2758|1.1744|3488|weapon_cryocannon 17→18|0/0|
|087|322981|3239|1857|1.7442|2758|1.1744|3378|weapon_autocannon 27→28|0/0|
|088|326359|3239|1857|1.7442|2758|1.1744|3201|weapon_flamethrower 17→18|0/0|
|089|329560|3239|1994|1.6244|2758|1.1744|3453|weapon_autocannon 28→29|0/0|
|090|333013|3239|2751|1.1774|2758|1.1744|2936|vanguard 23→24|0/0|
|091|335949|3357|1234|2.7204|2758|1.2172|2859|weapon_venomlauncher 13→14|0/0|
|092|338808|3357|1862|1.8029|2758|1.2172|4047|weapon_railgun 11→12|0/0|
|093|342855|3357|2266|1.4815|2758|1.2172|3491|weapon_autocannon 29→30|0/0|
|094|346346|3357|1830|1.8344|2758|1.2172|3762|weapon_teslacoil 14→15|0/0|
|095|353699|3429|3370|1.0175|3370|1.0175|3531|weapon_venomlauncher 14→15|2/0|
|096|357230|3429|2429|1.4117|3370|1.0175|4605|weapon_plasmacannon 12→13|0/0|
|097|361835|3429|1863|1.8406|3370|1.0175|4280|weapon_railgun 12→13|0/0|
|098|366115|3429|2720|1.2607|3370|1.0175|4292|weapon_teslacoil 15→16|0/0|
|099|370407|3429|3094|1.1083|3370|1.0175|3739|weapon_cryocannon 18→19|0/0|
