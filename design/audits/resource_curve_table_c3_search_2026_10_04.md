状态：SEARCH_CANDIDATE_NOT_YET_FEASIBLE；待Fable签字，游戏数据未写入。

# 资源表 C 候选

§8.4离线假定3★首通，挑战首通优先；非门关每章最多6次，门关刷到R≥1、不限次数、照实列高度；全关P≤1.20E。不是运行时胜率。P(g)/F(g)与消费策略冻结，因子[0.5,2.0]；八把免费武器共用一个升级基价系数。
优化顺序：零硬约束失败 → 非门回刷次数 → Σ|P−E|/E。门次数完整披露，不参与第二目标。
优化前：69/99失败，目标36.608304。
优化后：4/99失败，目标4.800291。

缩放系数与逐字段旧/新对照完整列于同名JSON；所有候选仅在内存模拟。

|曲线|缩放系数/形式|
|---|---|
|first_clear_gold|[-0.5654789993176951, 0.09118861476063411]；existing authored per-level values × exp(a+b*(L-1)/98)|
|kill_gold_mult|[-0.5859884569341294, -0.038910227642740214]；existing authored per-level values × exp(a+b*(L-1)/98)|
|free_unlock_star|1.7255418463104217；existing free star tiers × constant|
|skill_base_xp_costs|[0.7351564065826917, 0.8670328063942269, 0.9971856944658832, 1.1009364214035482, 1.5225779516406888]；same five authored cost tiers times positive monotone factors|
|sig_skill_xp_costs|[0.8685544204081754, 1.0027251587060977, 1.0767393321591823, 1.1938763716241663, 1.858658068467446]；same five authored cost tiers times positive monotone factors|
|free_weapon_cost|1.0453592980894413；all existing free linear upgrade formulas × ONE common base-price factor|

|文件/字段|旧值|候选新值|系数|
|---|---:|---:|---:|
|data/levels.json/0/first_clear_reward/gold|119|68|0.56808797|
|data/levels.json/1/first_clear_reward/gold|143|81|0.56861682|
|data/levels.json/2/first_clear_reward/gold|167|95|0.56914616|
|data/levels.json/3/first_clear_reward/gold|192|109|0.56967599|
|data/levels.json/4/first_clear_reward/gold|216|123|0.57020632|
|data/levels.json/5/first_clear_reward/gold|241|138|0.57073714|
|data/levels.json/6/first_clear_reward/gold|266|152|0.57126846|
|data/levels.json/7/first_clear_reward/gold|291|166|0.57180027|
|data/levels.json/8/first_clear_reward/gold|315|180|0.57233258|
|data/levels.json/9/first_clear_reward/gold|340|195|0.57286538|
|data/levels.json/10/first_clear_reward/gold|366|210|0.57339867|
|data/levels.json/11/first_clear_reward/gold|391|224|0.57393247|
|data/levels.json/12/first_clear_reward/gold|416|239|0.57446676|
|data/levels.json/13/first_clear_reward/gold|442|254|0.57500155|
|data/levels.json/14/first_clear_reward/gold|467|269|0.57553683|
|data/levels.json/15/first_clear_reward/gold|493|284|0.57607262|
|data/levels.json/16/first_clear_reward/gold|519|299|0.5766089|
|data/levels.json/17/first_clear_reward/gold|545|315|0.57714568|
|data/levels.json/18/first_clear_reward/gold|571|330|0.57768296|
|data/levels.json/19/first_clear_reward/gold|597|345|0.57822074|
|data/levels.json/20/first_clear_reward/gold|623|361|0.57875903|
|data/levels.json/21/first_clear_reward/gold|650|377|0.57929781|
|data/levels.json/22/first_clear_reward/gold|676|392|0.57983709|
|data/levels.json/23/first_clear_reward/gold|703|408|0.58037688|
|data/levels.json/24/first_clear_reward/gold|729|423|0.58091717|
|data/levels.json/25/first_clear_reward/gold|756|440|0.58145796|
|data/levels.json/26/first_clear_reward/gold|783|456|0.58199926|
|data/levels.json/27/first_clear_reward/gold|810|472|0.58254106|
|data/levels.json/28/first_clear_reward/gold|837|488|0.58308337|
|data/levels.json/29/first_clear_reward/gold|864|504|0.58362617|
|data/levels.json/30/first_clear_reward/gold|892|521|0.58416949|
|data/levels.json/31/first_clear_reward/gold|919|537|0.58471331|
|data/levels.json/32/first_clear_reward/gold|947|554|0.58525764|
|data/levels.json/33/first_clear_reward/gold|975|571|0.58580247|
|data/levels.json/34/first_clear_reward/gold|1002|588|0.58634781|
|data/levels.json/35/first_clear_reward/gold|1030|605|0.58689366|
|data/levels.json/36/first_clear_reward/gold|1058|622|0.58744001|
|data/levels.json/37/first_clear_reward/gold|1086|639|0.58798688|
|data/levels.json/38/first_clear_reward/gold|1115|656|0.58853425|
|data/levels.json/39/first_clear_reward/gold|1143|673|0.58908214|
|data/levels.json/40/first_clear_reward/gold|1171|690|0.58963053|
|data/levels.json/41/first_clear_reward/gold|1200|708|0.59017944|
|data/levels.json/42/first_clear_reward/gold|1229|726|0.59072885|
|data/levels.json/43/first_clear_reward/gold|1257|743|0.59127878|
|data/levels.json/44/first_clear_reward/gold|1286|761|0.59182922|
|data/levels.json/45/first_clear_reward/gold|1315|779|0.59238017|
|data/levels.json/46/first_clear_reward/gold|1344|797|0.59293163|
|data/levels.json/47/first_clear_reward/gold|1374|815|0.59348361|
|data/levels.json/48/first_clear_reward/gold|1403|833|0.5940361|
|data/levels.json/49/first_clear_reward/gold|1432|851|0.5945891|
|data/levels.json/50/first_clear_reward/gold|1462|870|0.59514263|
|data/levels.json/51/first_clear_reward/gold|1492|889|0.59569666|
|data/levels.json/52/first_clear_reward/gold|1521|907|0.59625121|
|data/levels.json/53/first_clear_reward/gold|1551|926|0.59680628|
|data/levels.json/54/first_clear_reward/gold|1581|944|0.59736186|
|data/levels.json/55/first_clear_reward/gold|1611|963|0.59791797|
|data/levels.json/56/first_clear_reward/gold|1642|983|0.59847458|
|data/levels.json/57/first_clear_reward/gold|1672|1002|0.59903172|
|data/levels.json/58/first_clear_reward/gold|1702|1021|0.59958938|
|data/levels.json/59/first_clear_reward/gold|1733|1040|0.60014755|
|data/levels.json/60/first_clear_reward/gold|1764|1060|0.60070625|
|data/levels.json/61/first_clear_reward/gold|1794|1079|0.60126546|
|data/levels.json/62/first_clear_reward/gold|1825|1098|0.6018252|
|data/levels.json/63/first_clear_reward/gold|1856|1118|0.60238546|
|data/levels.json/64/first_clear_reward/gold|1887|1138|0.60294623|
|data/levels.json/65/first_clear_reward/gold|1919|1158|0.60350753|
|data/levels.json/66/first_clear_reward/gold|1950|1178|0.60406936|
|data/levels.json/67/first_clear_reward/gold|1981|1198|0.6046317|
|data/levels.json/68/first_clear_reward/gold|2013|1218|0.60519457|
|data/levels.json/69/first_clear_reward/gold|2044|1238|0.60575796|
|data/levels.json/70/first_clear_reward/gold|2076|1259|0.60632188|
|data/levels.json/71/first_clear_reward/gold|2108|1279|0.60688633|
|data/levels.json/72/first_clear_reward/gold|2140|1300|0.60745129|
|data/levels.json/73/first_clear_reward/gold|2172|1321|0.60801679|
|data/levels.json/74/first_clear_reward/gold|2204|1341|0.60858281|
|data/levels.json/75/first_clear_reward/gold|2237|1363|0.60914936|
|data/levels.json/76/first_clear_reward/gold|2269|1383|0.60971643|
|data/levels.json/77/first_clear_reward/gold|2302|1405|0.61028403|
|data/levels.json/78/first_clear_reward/gold|2334|1426|0.61085216|
|data/levels.json/79/first_clear_reward/gold|2367|1447|0.61142082|
|data/levels.json/80/first_clear_reward/gold|2400|1469|0.61199001|
|data/levels.json/81/first_clear_reward/gold|2433|1490|0.61255973|
|data/levels.json/82/first_clear_reward/gold|2466|1512|0.61312998|
|data/levels.json/83/first_clear_reward/gold|2499|1534|0.61370076|
|data/levels.json/84/first_clear_reward/gold|2532|1555|0.61427208|
|data/levels.json/85/first_clear_reward/gold|2566|1578|0.61484392|
|data/levels.json/86/first_clear_reward/gold|2599|1599|0.6154163|
|data/levels.json/87/first_clear_reward/gold|2633|1622|0.6159892|
|data/levels.json/88/first_clear_reward/gold|2667|1644|0.61656265|
|data/levels.json/89/first_clear_reward/gold|2700|1666|0.61713662|
|data/levels.json/90/first_clear_reward/gold|2734|1689|0.61771113|
|data/levels.json/91/first_clear_reward/gold|2769|1712|0.61828618|
|data/levels.json/92/first_clear_reward/gold|2803|1735|0.61886176|
|data/levels.json/93/first_clear_reward/gold|2837|1757|0.61943788|
|data/levels.json/94/first_clear_reward/gold|2871|1780|0.62001453|
|data/levels.json/95/first_clear_reward/gold|2906|1803|0.62059172|
|data/levels.json/96/first_clear_reward/gold|2940|1826|0.62116944|
|data/levels.json/97/first_clear_reward/gold|2975|1850|0.62174771|
|data/levels.json/98/first_clear_reward/gold|3010|1873|0.62232651|
|data/levels.json/0/reward_gold_mult|0.56|0.31167106|0.55655546|
|data/levels.json/1/reward_gold_mult|0.55|0.30598399|0.55633453|
|data/levels.json/2/reward_gold_mult|0.55|0.30586252|0.55611368|
|data/levels.json/3/reward_gold_mult|0.55|0.30574111|0.55589292|
|data/levels.json/4/reward_gold_mult|0.54|0.30006302|0.55567225|
|data/levels.json/5/reward_gold_mult|0.54|0.2999439|0.55545167|
|data/levels.json/6/reward_gold_mult|0.53|0.29427252|0.55523118|
|data/levels.json/7/reward_gold_mult|0.53|0.29415571|0.55501077|
|data/levels.json/8/reward_gold_mult|0.53|0.29403894|0.55479045|
|data/levels.json/9/reward_gold_mult|0.52|0.28837651|0.55457022|
|data/levels.json/10/reward_gold_mult|0.52|0.28826204|0.55435007|
|data/levels.json/11/reward_gold_mult|0.52|0.28814761|0.55413002|
|data/levels.json/12/reward_gold_mult|0.51|0.28249412|0.55391005|
|data/levels.json/13/reward_gold_mult|0.51|0.28238198|0.55369016|
|data/levels.json/14/reward_gold_mult|0.51|0.28226989|0.55347037|
|data/levels.json/15/reward_gold_mult|0.5|0.27662533|0.55325066|
|data/levels.json/16/reward_gold_mult|0.5|0.27651552|0.55303104|
|data/levels.json/17/reward_gold_mult|0.5|0.27640575|0.55281151|
|data/levels.json/18/reward_gold_mult|0.49|0.27077011|0.55259206|
|data/levels.json/19/reward_gold_mult|0.49|0.27066262|0.5523727|
|data/levels.json/20/reward_gold_mult|0.48|0.26503365|0.55215343|
|data/levels.json/21/reward_gold_mult|0.48|0.26492844|0.55193424|
|data/levels.json/22/reward_gold_mult|0.48|0.26482327|0.55171515|
|data/levels.json/23/reward_gold_mult|0.47|0.25920318|0.55149613|
|data/levels.json/24/reward_gold_mult|0.47|0.25910029|0.55127721|
|data/levels.json/25/reward_gold_mult|0.47|0.25899744|0.55105837|
|data/levels.json/26/reward_gold_mult|0.46|0.25338623|0.55083962|
|data/levels.json/27/reward_gold_mult|0.46|0.25328564|0.55062096|
|data/levels.json/28/reward_gold_mult|0.46|0.2531851|0.55040238|
|data/levels.json/29/reward_gold_mult|0.45|0.24758275|0.55018389|
|data/levels.json/30/reward_gold_mult|0.45|0.24748447|0.54996549|
|data/levels.json/31/reward_gold_mult|0.44|0.24188876|0.54974717|
|data/levels.json/32/reward_gold_mult|0.44|0.24179273|0.54952894|
|data/levels.json/33/reward_gold_mult|0.44|0.24169675|0.5493108|
|data/levels.json/34/reward_gold_mult|0.43|0.23610988|0.54909274|
|data/levels.json/35/reward_gold_mult|0.43|0.23601615|0.54887477|
|data/levels.json/36/reward_gold_mult|0.43|0.23592246|0.54865689|
|data/levels.json/37/reward_gold_mult|0.42|0.23034442|0.54843909|
|data/levels.json/38/reward_gold_mult|0.42|0.23025298|0.54822138|
|data/levels.json/39/reward_gold_mult|0.42|0.23016158|0.54800376|
|data/levels.json/40/reward_gold_mult|0.41|0.22459235|0.54778622|
|data/levels.json/41/reward_gold_mult|0.41|0.22450319|0.54756877|
|data/levels.json/42/reward_gold_mult|0.41|0.22441407|0.5473514|
|data/levels.json/43/reward_gold_mult|0.4|0.21885365|0.54713412|
|data/levels.json/44/reward_gold_mult|0.4|0.21876677|0.54691693|
|data/levels.json/45/reward_gold_mult|0.39|0.21321293|0.54669982|
|data/levels.json/46/reward_gold_mult|0.39|0.21312829|0.5464828|
|data/levels.json/47/reward_gold_mult|0.39|0.21304369|0.54626587|
|data/levels.json/48/reward_gold_mult|0.38|0.20749863|0.54604902|
|data/levels.json/49/reward_gold_mult|0.38|0.20741626|0.54583226|
|data/levels.json/50/reward_gold_mult|0.38|0.20733392|0.54561558|
|data/levels.json/51/reward_gold_mult|0.37|0.20179763|0.54539899|
|data/levels.json/52/reward_gold_mult|0.37|0.20171752|0.54518249|
|data/levels.json/53/reward_gold_mult|0.37|0.20163745|0.54496607|
|data/levels.json/54/reward_gold_mult|0.36|0.19610991|0.54474974|
|data/levels.json/55/reward_gold_mult|0.36|0.19603206|0.54453349|
|data/levels.json/56/reward_gold_mult|0.35|0.19051107|0.54431733|
|data/levels.json/57/reward_gold_mult|0.35|0.19043544|0.54410126|
|data/levels.json/58/reward_gold_mult|0.35|0.19035984|0.54388527|
|data/levels.json/59/reward_gold_mult|0.34|0.18484758|0.54366936|
|data/levels.json/60/reward_gold_mult|0.34|0.18477421|0.54345355|
|data/levels.json/61/reward_gold_mult|0.34|0.18470086|0.54323782|
|data/levels.json/62/reward_gold_mult|0.33|0.17919732|0.54302217|
|data/levels.json/63/reward_gold_mult|0.33|0.17912618|0.54280661|
|data/levels.json/64/reward_gold_mult|0.33|0.17905507|0.54259113|
|data/levels.json/65/reward_gold_mult|0.32|0.17356024|0.54237575|
|data/levels.json/66/reward_gold_mult|0.32|0.17349134|0.54216044|
|data/levels.json/67/reward_gold_mult|0.32|0.17342247|0.54194522|
|data/levels.json/68/reward_gold_mult|0.31|0.16793633|0.54173009|
|data/levels.json/69/reward_gold_mult|0.31|0.16786966|0.54151504|
|data/levels.json/70/reward_gold_mult|0.3|0.16239002|0.54130008|
|data/levels.json/71/reward_gold_mult|0.3|0.16232556|0.5410852|
|data/levels.json/72/reward_gold_mult|0.3|0.16226112|0.54087041|
|data/levels.json/73/reward_gold_mult|0.29|0.15679015|0.54065571|
|data/levels.json/74/reward_gold_mult|0.29|0.15672791|0.54044108|
|data/levels.json/75/reward_gold_mult|0.29|0.1566657|0.54022655|
|data/levels.json/76/reward_gold_mult|0.28|0.15120339|0.5400121|
|data/levels.json/77/reward_gold_mult|0.28|0.15114337|0.53979773|
|data/levels.json/78/reward_gold_mult|0.28|0.15108337|0.53958345|
|data/levels.json/79/reward_gold_mult|0.27|0.1456297|0.53936926|
|data/levels.json/80/reward_gold_mult|0.27|0.14557189|0.53915515|
|data/levels.json/81/reward_gold_mult|0.26|0.14012469|0.53894112|
|data/levels.json/82/reward_gold_mult|0.26|0.14006907|0.53872718|
|data/levels.json/83/reward_gold_mult|0.26|0.14001346|0.53851333|
|data/levels.json/84/reward_gold_mult|0.26|0.13995788|0.53829955|
|data/levels.json/85/reward_gold_mult|0.26|0.13990233|0.53808587|
|data/levels.json/86/reward_gold_mult|0.26|0.13984679|0.53787227|
|data/levels.json/87/reward_gold_mult|0.26|0.13979128|0.53765875|
|data/levels.json/88/reward_gold_mult|0.26|0.13973578|0.53744532|
|data/levels.json/89/reward_gold_mult|0.26|0.13968031|0.53723197|
|data/levels.json/90/reward_gold_mult|0.26|0.13962487|0.53701871|
|data/levels.json/91/reward_gold_mult|0.26|0.13956944|0.53680553|
|data/levels.json/92/reward_gold_mult|0.26|0.13951403|0.53659244|
|data/levels.json/93/reward_gold_mult|0.26|0.13945865|0.53637943|
|data/levels.json/94/reward_gold_mult|0.26|0.13940329|0.53616651|
|data/levels.json/95/reward_gold_mult|0.26|0.13934795|0.53595367|
|data/levels.json/96/reward_gold_mult|0.26|0.13929264|0.53574092|
|data/levels.json/97/reward_gold_mult|0.26|0.13923734|0.53552825|
|data/levels.json/98/reward_gold_mult|0.26|0.13918207|0.53531566|
|data/weapons.json/weapon_flamethrower/unlock_cost_star|8|14|1.7255418|
|data/weapons.json/weapon_cryocannon/unlock_cost_star|8|14|1.7255418|
|data/weapons.json/weapon_teslacoil/unlock_cost_star|10|17|1.7255418|
|data/weapons.json/weapon_venomlauncher/unlock_cost_star|8|14|1.7255418|
|data/weapons.json/weapon_railgun/unlock_cost_star|14|24|1.7255418|
|data/weapons.json/weapon_scattergun/unlock_cost_star|9|16|1.7255418|
|data/weapons.json/weapon_plasmacannon/unlock_cost_star|16|28|1.7255418|
|data/armors.json/armor_kevlar/unlock_cost_star|8|14|1.7255418|
|data/armors.json/armor_thermal/unlock_cost_star|8|14|1.7255418|
|data/armors.json/armor_cryo/unlock_cost_star|9|16|1.7255418|
|data/armors.json/armor_faraday/unlock_cost_star|10|17|1.7255418|
|data/armors.json/armor_hazmat/unlock_cost_star|11|19|1.7255418|
|data/armors.json/armor_reactive/unlock_cost_star|14|24|1.7255418|
|data/chips.json/chip_attack/unlock_cost_star|8|14|1.7255418|
|data/chips.json/chip_haste/unlock_cost_star|8|14|1.7255418|
|data/chips.json/chip_crit/unlock_cost_star|9|16|1.7255418|
|data/chips.json/chip_pierce/unlock_cost_star|11|19|1.7255418|
|data/chips.json/chip_health/unlock_cost_star|9|16|1.7255418|
|data/chips.json/chip_guardian/unlock_cost_star|10|17|1.7255418|
|data/chips.json/chip_greed/unlock_cost_star|11|19|1.7255418|
|data/chips.json/chip_element/unlock_cost_star|14|24|1.7255418|
|data/pets.json/pet_turret_drone/unlock_cost_star|8|14|1.7255418|
|data/pets.json/pet_fire_imp/unlock_cost_star|9|16|1.7255418|
|data/pets.json/pet_frost_wisp/unlock_cost_star|10|17|1.7255418|
|data/pets.json/pet_volt_orb/unlock_cost_star|11|19|1.7255418|
|data/pets.json/pet_medic_drone/unlock_cost_star|13|22|1.7255418|
|data/pets.json/pet_collector/unlock_cost_star|14|24|1.7255418|
|data/economy.json/skill_base_xp_costs/0|350|257|0.73515641|
|data/economy.json/skill_base_xp_costs/1|900|780|0.86703281|
|data/economy.json/skill_base_xp_costs/2|2000|1994|0.99718569|
|data/economy.json/skill_base_xp_costs/3|4000|4404|1.1009364|
|data/economy.json/skill_base_xp_costs/4|8500|12942|1.522578|
|data/economy.json/sig_skill_xp_costs/0|450|391|0.86855442|
|data/economy.json/sig_skill_xp_costs/1|1200|1203|1.0027252|
|data/economy.json/sig_skill_xp_costs/2|2700|2907|1.0767393|
|data/economy.json/sig_skill_xp_costs/3|5400|6447|1.1938764|
|data/economy.json/sig_skill_xp_costs/4|11000|20445|1.8586581|
|data/weapons.json/weapon_autocannon/cost_base_gold|100|105|1.0453593|
|data/weapons.json/weapon_flamethrower/cost_base_gold|180|188|1.0453593|
|data/weapons.json/weapon_cryocannon/cost_base_gold|180|188|1.0453593|
|data/weapons.json/weapon_teslacoil/cost_base_gold|240|251|1.0453593|
|data/weapons.json/weapon_venomlauncher/cost_base_gold|240|251|1.0453593|
|data/weapons.json/weapon_railgun/cost_base_gold|320|335|1.0453593|
|data/weapons.json/weapon_scattergun/cost_base_gold|180|188|1.0453593|
|data/weapons.json/weapon_plasmacannon/cost_base_gold|320|335|1.0453593|

|关卡|rec|E|旧P|新P|新R|新P/E|下限|上限|达标|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
|001|50|65|65|65|1.3000|1.0000|48|78|True|
|002|50|65|69|67|1.3400|1.0308|48|78|True|
|003|50|65|73|70|1.4000|1.0769|48|78|True|
|004|64|65|74|73|1.1406|1.1231|61|78|True|
|005|76|76|81|76|1.0000|1.0000|76|91|True|
|006|53|76|82|80|1.5094|1.0526|51|91|True|
|007|53|76|89|85|1.6038|1.1184|53|91|True|
|008|79|79|96|88|1.1139|1.1139|79|94|True|
|009|79|79|106|93|1.1772|1.1772|79|94|True|
|010|87|87|112|96|1.1034|1.1034|87|104|True|
|011|99|99|116|100|1.0101|1.0101|95|118|True|
|012|108|108|122|118|1.0926|1.0926|103|129|True|
|013|131|131|131|134|1.0229|1.0229|125|157|True|
|014|138|138|141|139|1.0072|1.0072|132|165|True|
|015|147|147|151|150|1.0204|1.0204|147|176|True|
|016|98|147|152|150|1.5306|1.0204|94|176|True|
|017|165|165|166|165|1.0000|1.0000|0|198|True|
|018|185|185|207|202|1.0919|1.0919|0|222|True|
|019|188|188|210|202|1.0745|1.0745|188|225|True|
|020|291|291|291|291|1.0000|1.0000|0|349|True|
|021|164|291|323|294|1.7927|1.0103|156|349|True|
|022|183|291|339|294|1.6066|1.0103|174|349|True|
|023|186|291|355|297|1.5968|1.0206|177|349|True|
|024|201|291|374|297|1.4776|1.0206|191|349|True|
|025|260|291|410|307|1.1808|1.0550|260|349|True|
|026|226|291|410|307|1.3584|1.0550|215|349|True|
|027|195|291|410|314|1.6103|1.0790|195|349|True|
|028|231|291|474|323|1.3983|1.1100|231|349|True|
|029|206|291|509|336|1.6311|1.1546|206|349|True|
|030|332|332|515|350|1.0542|1.0542|332|398|True|
|031|159|332|522|350|2.2013|1.0542|152|398|True|
|032|245|332|530|353|1.4408|1.0633|233|398|True|
|033|228|332|573|360|1.5789|1.0843|217|398|True|
|034|330|332|573|373|1.1303|1.1235|314|398|True|
|035|219|332|648|373|1.7032|1.1235|219|398|True|
|036|225|332|679|412|1.8311|1.2410|214|398|False|
|037|232|332|685|412|1.7759|1.2410|232|398|False|
|038|484|484|710|484|1.0000|1.0000|484|580|True|
|039|533|533|849|536|1.0056|1.0056|0|639|True|
|040|574|574|849|597|1.0401|1.0401|0|688|True|
|041|236|574|880|597|2.5297|1.0401|225|688|True|
|042|375|574|942|620|1.6533|1.0801|357|688|True|
|043|587|587|951|620|1.0562|1.0562|558|704|True|
|044|757|757|957|741|0.9789|0.9789|720|908|True|
|045|655|757|963|804|1.2275|1.0621|655|908|True|
|046|600|757|972|842|1.4033|1.1123|570|908|True|
|047|670|757|983|867|1.2940|1.1453|670|908|True|
|048|663|757|983|892|1.3454|1.1783|663|908|True|
|049|658|757|1008|892|1.3556|1.1783|658|908|True|
|050|868|868|1068|933|1.0749|1.0749|868|1041|True|
|051|431|868|1185|949|2.2019|1.0933|410|1041|True|
|052|349|868|1185|955|2.7364|1.1002|332|1041|True|
|053|427|868|1185|955|2.2365|1.1002|406|1041|True|
|054|359|868|1185|955|2.6602|1.1002|342|1041|True|
|055|950|950|1185|955|1.0053|1.0053|950|1140|True|
|056|354|950|1237|955|2.6977|1.0053|337|1140|True|
|057|990|990|1237|991|1.0010|1.0010|990|1188|True|
|058|503|990|1284|991|1.9702|1.0010|503|1188|True|
|059|562|990|1284|991|1.7633|1.0010|562|1188|True|
|060|990|990|1300|991|1.0010|1.0010|990|1188|True|
|061|990|990|1491|996|1.0061|1.0061|941|1188|True|
|062|250|990|1577|996|3.9840|1.0061|238|1188|True|
|063|576|990|1763|1004|1.7431|1.0141|548|1188|True|
|064|955|990|1763|1004|1.0513|1.0141|908|1188|True|
|065|1014|1014|1813|1055|1.0404|1.0404|1014|1216|True|
|066|1184|1184|1813|1185|1.0008|1.0008|1125|1420|True|
|067|955|1184|1813|1185|1.2408|1.0008|955|1420|True|
|068|1042|1184|1814|1185|1.1372|1.0008|1042|1420|True|
|069|978|1184|2043|1185|1.2117|1.0008|978|1420|True|
|070|1286|1286|2043|1575|1.2247|1.2247|0|1543|False|
|071|1146|1286|2202|1575|1.3743|1.2247|1089|1543|False|
|072|1576|1576|2308|1575|0.9994|0.9994|1498|1891|True|
|073|818|1576|2308|1575|1.9254|0.9994|778|1891|True|
|074|2034|2034|2429|2035|1.0005|1.0005|0|2440|True|
|075|1841|2034|2733|2035|1.1054|1.0005|1841|2440|True|
|076|2758|2758|2989|2760|1.0007|1.0007|0|3309|True|
|077|1652|2758|3160|2760|1.6707|1.0007|1652|3309|True|
|078|2226|2758|3160|2760|1.2399|1.0007|2226|3309|True|
|079|2030|2758|3160|2760|1.3596|1.0007|2030|3309|True|
|080|2067|2758|3220|2760|1.3353|1.0007|2067|3309|True|
|081|1096|2758|3270|2760|2.5182|1.0007|1042|3309|True|
|082|1762|2758|3270|2760|1.5664|1.0007|1674|3309|True|
|083|1815|2758|3270|2760|1.5207|1.0007|1725|3309|True|
|084|1265|2758|3271|2760|2.1818|1.0007|1202|3309|True|
|085|2204|2758|3271|2760|1.2523|1.0007|2204|3309|True|
|086|1855|2758|3538|2760|1.4879|1.0007|1763|3309|True|
|087|1857|2758|3639|2760|1.4863|1.0007|1857|3309|True|
|088|1857|2758|3700|2760|1.4863|1.0007|1857|3309|True|
|089|1994|2758|3974|2760|1.3842|1.0007|1994|3309|True|
|090|2751|2758|3994|2760|1.0033|1.0007|2751|3309|True|
|091|1234|2758|4401|2760|2.2366|1.0007|1173|3309|True|
|092|1862|2758|4401|2760|1.4823|1.0007|1769|3309|True|
|093|2266|2758|4404|2760|1.2180|1.0007|2153|3309|True|
|094|1830|2758|4406|2760|1.5082|1.0007|1739|3309|True|
|095|3370|3370|4415|3512|1.0421|1.0421|0|4044|True|
|096|2429|3370|4415|3512|1.4459|1.0421|2308|4044|True|
|097|1863|3370|4415|3512|1.8851|1.0421|1863|4044|True|
|098|2720|3370|5163|3512|1.2912|1.0421|2720|4044|True|
|099|3094|3370|5283|3512|1.1351|1.0421|3094|4044|True|

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

首次R<0.95：None；G1走廊不满足关数：4/99。

包络目标Σ|P−E|/E：4.800291。

回刷总数：94（非门18，门76）；各章非门：{'1': 0, '2': 4, '3': 0, '4': 0, '5': 4, '6': 6, '7': 4, '8': 0, '9': 0, '10': 0}。
门关：[17, 18, 20, 39, 40, 70, 74, 76, 95]；预算后新增门：[17, 18, 39, 40, 70, 74]；未刷够门：[]；非门失败：[36, 37, 71]。

|回刷位置|路线(挑战/普通)|入场P|回刷后P|次数|非门章累计|刷够|八墙关|门高度/路线注记|
|---|---|---:|---:|---:|---:|---|---|---|
|012|011挑, 010挑, 009挑|101|118|3|3|True|False|非门|
|013|012挑|121|134|1|4|True|False|非门|
|017|016挑, 015挑, 014挑|157|165|3|4|True|True|3 / 仅挑战 / challenge-first route still exceeds chapter remaining budget|
|018|017挑, 013挑, 008挑|171|202|3|4|True|True|3 / 仅挑战 / challenge-first route still exceeds chapter remaining budget|
|020|019挑, 018挑, 007挑, 006挑, 005挑, 004挑, 003挑, 002挑, 001挑, 019普|202|291|10|4|True|True|10 / 仅挑战 / Owner fixed gate|
|039|038挑, 037挑, 036挑, 035挑, 034挑, 033挑, 032挑|495|536|7|0|True|False|7 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|040|039挑, 031挑, 030挑, 029挑, 028挑, 027挑, 026挑, 025挑, 024挑, 023挑|546|597|10|0|True|True|10 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|044|043挑, 042挑, 041挑, 040挑|643|741|4|4|True|True|非门|
|057|056挑, 055挑, 054挑, 053挑, 052挑, 051挑|955|991|6|6|True|False|非门|
|065|064挑|1004|1055|1|1|True|False|非门|
|066|065挑, 063挑, 062挑|1055|1185|3|4|True|False|非门|
|070|069挑, 068挑, 067挑, 066挑, 061挑, 060挑, 059挑, 058挑|1185|1575|8|4|True|False|8 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|074|073挑, 072挑, 071挑, 070挑, 057挑, 050挑, 049挑, 048挑, 047挑, 046挑, 045挑, 044挑, 022挑, 021挑, 020挑|1575|2035|15|0|True|False|15 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|076|075挑, 074挑, 075普, 075普, 075普, 075普, 075普, 075普, 075普, 075普, 075普, 075普, 075普, 075普, 075普|2035|2760|15|0|True|True|15 / 可付费（未做运行时验证） / Owner fixed gate|
|095|094挑, 093挑, 092挑, 091挑, 090挑|2760|3512|5|0|True|False|5 / 可付费（未做运行时验证） / Owner fixed gate|

## 门关高度（含无需回刷的固定门）

|门|高度|已刷够|路径|原因|
|---|---:|---|---|---|
|017|3|True|仅挑战|challenge-first route still exceeds chapter remaining budget|
|018|3|True|仅挑战|challenge-first route still exceeds chapter remaining budget|
|020|10|True|仅挑战|Owner fixed gate|
|039|7|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|040|10|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|070|8|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|074|15|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|076|15|True|可付费（未做运行时验证）|Owner fixed gate|
|095|5|True|可付费（未做运行时验证）|Owner fixed gate|

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|当关/章累计回刷|
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
|001|0|65|50|1.3000|65|1.0000|287|vanguard 1→2; weapon_autocannon 1→2|0/0|
|002|287|67|50|1.3400|65|1.0308|382|weapon_autocannon 2→3; skill_multishot 0→1; skill_pierce 0→1|0/0|
|003|669|70|50|1.4000|65|1.0769|394|vanguard 2→3; weapon_autocannon 3→4; skill_barrier 0→1; skill_homing 0→1|0/0|
|004|1063|73|64|1.1406|65|1.1231|483|weapon_autocannon 4→5; skill_salvo 0→1|0/0|
|005|1546|76|76|1.0000|76|1.0000|530|weapon_cryocannon; weapon_autocannon 5→6; weapon_cryocannon 1→2; skill_charge_shot 0→1; skill_slow_field 0→1|0/0|
|006|2076|80|53|1.5094|76|1.0526|690|weapon_autocannon 6→7; weapon_cryocannon 2→3; signature 0→1|0/0|
|007|2766|85|53|1.6038|76|1.1184|656|weapon_autocannon 7→8; skill_critical 0→1; skill_split_shot 0→1|0/0|
|008|3422|88|79|1.1139|79|1.1139|866|vanguard 3→4; weapon_autocannon 8→9; skill_ricochet 0→1|0/0|
|009|4288|93|79|1.1772|79|1.1772|705|weapon_autocannon 9→10; skill_multishot 1→2|0/0|
|010|4993|96|87|1.1034|87|1.1034|699|armor_kevlar; weapon_autocannon 10→11|0/0|
|011|5692|100|99|1.0101|99|1.0101|978|armor_kevlar 1→2; weapon_autocannon 11→12; skill_pierce 1→2|0/0|
|012|8467|118|108|1.0926|108|1.0926|1074|armor_kevlar 3→4; weapon_autocannon 12→13; skill_salvo 1→2|3/3|
|013|10391|134|131|1.0229|131|1.0229|1218|weapon_autocannon 13→14|1/4|
|014|11609|139|138|1.0072|138|1.0072|1253|armor_kevlar 4→5; weapon_autocannon 14→15; signature 1→2|0/4|
|015|12862|150|147|1.0204|147|1.0204|784|weapon_cryocannon 5→6|0/4|
|016|13646|150|98|1.5306|147|1.0204|1483|weapon_scattergun; weapon_autocannon 15→16; weapon_scattergun 1→3; skill_slow_field 1→2|0/4|
|017|17842|165|165|1.0000|165|1.0000|1499|weapon_autocannon 17→18; skill_ricochet 1→2|3/4|
|018|22220|202|185|1.0919|185|1.0919|1171|pet_turret_drone 3→4; weapon_cryocannon 6→7|3/4|
|019|23391|202|188|1.0745|188|1.0745|1685|weapon_autocannon 19→20; skill_pierce 2→3|0/4|
|020|31298|291|291|1.0000|291|1.0000|1754|weapon_autocannon 21→22|10/4|
|021|33052|294|164|1.7927|291|1.0103|1608|weapon_venomlauncher; armor_kevlar 7→8; weapon_venomlauncher 1→4; skill_salvo 2→3|0/0|
|022|34660|294|183|1.6066|291|1.0103|1772|weapon_autocannon 22→23|0/0|
|023|36432|297|186|1.5968|291|1.0206|2021|weapon_railgun 3→4; weapon_venomlauncher 4→5|0/0|
|024|38453|297|201|1.4776|291|1.0206|1893|chip_attack 8→9; weapon_autocannon 23→24; skill_charge_shot 2→3|0/0|
|025|40346|307|260|1.1808|291|1.0550|1300|weapon_railgun 4→5|0/0|
|026|41646|307|226|1.3584|291|1.0550|2183|chip_attack 9→10; weapon_autocannon 24→25; skill_slow_field 2→3|0/0|
|027|43829|314|195|1.6103|291|1.0790|2048|weapon_autocannon 25→26|0/0|
|028|45877|323|231|1.3983|291|1.1100|2252|weapon_autocannon 26→27|0/0|
|029|48129|336|206|1.6311|291|1.1546|2282|armor_kevlar 8→9; weapon_autocannon 27→28; skill_split_shot 2→3|0/0|
|030|50411|350|332|1.0542|332|1.0542|1911|weapon_scattergun 6→7; weapon_venomlauncher 5→6|0/0|
|031|52322|350|159|2.2013|332|1.0542|2651|weapon_flamethrower; pet_turret_drone 6→7; weapon_flamethrower 1→6; skill_critical 2→3|0/0|
|032|54973|353|245|1.4408|332|1.0633|2462|weapon_plasmacannon; chip_attack 10→11; weapon_flamethrower 6→7; weapon_plasmacannon 1→3|0/0|
|033|57435|360|228|1.5789|332|1.0843|2238|weapon_autocannon 28→29|0/0|
|034|59673|373|330|1.1303|332|1.1235|2764|weapon_flamethrower 7→8; weapon_plasmacannon 3→5; skill_ricochet 2→3|0/0|
|035|62437|373|219|1.7032|332|1.1235|2063|weapon_autocannon 29→30|0/0|
|036|64500|412|225|1.8311|332|1.2410|2804|weapon_flamethrower 8→9; weapon_plasmacannon 5→6|0/0|
|037|67304|412|232|1.7759|332|1.2410|3172|weapon_autocannon 30→31; weapon_flamethrower 9→10; signature 2→3|0/0|
|038|70476|484|484|1.0000|484|1.0000|3386|weapon_autocannon 31→32; weapon_venomlauncher 6→7|0/0|
|039|88635|536|533|1.0056|533|1.0056|2943|weapon_autocannon 35→36; skill_pierce 3→4|7/0|
|040|108302|597|574|1.0401|574|1.0401|3801|weapon_flamethrower 10→11; weapon_railgun 8→9; skill_barrier 3→4|10/0|
|041|112103|597|236|2.5297|574|1.0401|3568|weapon_teslacoil; weapon_autocannon 36→37; weapon_teslacoil 1→4|0/0|
|042|115671|620|375|1.6533|574|1.0801|3449|weapon_teslacoil 4→7|0/0|
|043|119120|620|587|1.0562|587|1.0562|3864|weapon_autocannon 37→38; weapon_teslacoil 7→8; skill_salvo 3→4|0/0|
|044|134869|741|757|0.9789|757|0.9789|3817|chip_attack 12→13; weapon_autocannon 41→42|4/4|
|045|138686|804|655|1.2275|757|1.0621|3873|weapon_autocannon 42→43|0/4|
|046|142559|842|600|1.4033|757|1.1123|3386|armor_kevlar 11→12; weapon_autocannon 43→44|0/4|
|047|145945|867|670|1.2940|757|1.1453|3633|weapon_autocannon 44→45; skill_slow_field 3→4|0/4|
|048|149578|892|663|1.3454|757|1.1783|4195|weapon_plasmacannon 9→10; weapon_teslacoil 9→10|0/4|
|049|153773|892|658|1.3556|757|1.1783|4211|weapon_autocannon 45→46; weapon_cryocannon 10→11|0/4|
|050|157984|933|868|1.0749|868|1.0749|3222|weapon_autocannon 46→47; skill_split_shot 3→4|0/4|
|051|161206|949|431|2.2019|868|1.0933|1443|vanguard 10→11|0/0|
|052|162649|955|349|2.7364|868|1.1002|1617|weapon_teslacoil 10→11|0/0|
|053|164266|955|427|2.2365|868|1.1002|1581|weapon_cryocannon 11→12|0/0|
|054|165847|955|359|2.6602|868|1.1002|1611|weapon_venomlauncher 10→11; skill_critical 3→4|0/0|
|055|167458|955|950|1.0053|950|1.0053|1615|weapon_flamethrower 11→12|0/0|
|056|169073|955|354|2.6977|950|1.0053|1563|weapon_scattergun 10→11; skill_ricochet 3→4|0/0|
|057|174567|991|990|1.0010|990|1.0010|2702|weapon_railgun 9→10|6/6|
|058|177269|991|503|1.9702|990|1.0010|1777|weapon_teslacoil 11→12|0/6|
|059|179046|991|562|1.7633|990|1.0010|1739|weapon_venomlauncher 11→12|0/6|
|060|180785|991|990|1.0010|990|1.0010|3585|weapon_autocannon 47→48|0/6|
|061|184370|996|990|1.0061|990|1.0061|2137|weapon_cryocannon 12→13|0/0|
|062|186507|996|250|3.9840|990|1.0061|2197|weapon_plasmacannon 10→11; skill_multishot 4→5|0/0|
|063|188704|1004|576|1.7431|990|1.0141|2049|weapon_flamethrower 12→13|0/0|
|064|190753|1004|955|1.0513|990|1.0141|2082|weapon_railgun 10→11|0/0|
|065|193799|1055|1014|1.0404|1014|1.0404|2422|weapon_teslacoil 12→13|1/1|
|066|199574|1185|1184|1.0008|1184|1.0008|2006|weapon_cryocannon 13→14|3/4|
|067|201580|1185|955|1.2408|1184|1.0008|2702|weapon_plasmacannon 11→12|0/4|
|068|204282|1185|1042|1.1372|1184|1.0008|2466|weapon_railgun 11→12|0/4|
|069|206748|1185|978|1.2117|1184|1.0008|2586|weapon_venomlauncher 12→13|0/4|
|070|219457|1575|1286|1.2247|1286|1.2247|2466|weapon_venomlauncher 13→14; skill_barrier 4→5|8/4|
|071|221923|1575|1146|1.3743|1286|1.2247|2251|weapon_cryocannon 14→15|0/0|
|072|224174|1575|1576|0.9994|1576|0.9994|2147|weapon_flamethrower 14→15|0/0|
|073|226321|1575|818|1.9254|1576|0.9994|2306|weapon_plasmacannon 12→13|0/0|
|074|259249|2035|2034|1.0005|2034|1.0005|2822|weapon_flamethrower 15→16|15/0|
|075|262071|2035|1841|1.1054|2034|1.0005|2951|weapon_railgun 13→14|0/0|
|076|289063|2760|2758|1.0007|2758|1.0007|2553|weapon_teslacoil 15→16|15/0|
|077|291616|2760|1652|1.6707|2758|1.0007|2851|weapon_venomlauncher 15→16|0/0|
|078|294467|2760|2226|1.2399|2758|1.0007|2685|weapon_teslacoil 16→17; skill_split_shot 4→5|0/0|
|079|297152|2760|2030|1.3596|2758|1.0007|2934|weapon_venomlauncher 16→17|0/0|
|080|300086|2760|2067|1.3353|2758|1.0007|3142|weapon_plasmacannon 14→15|0/0|
|081|303228|2760|1096|2.5182|2758|1.0007|2525|weapon_cryocannon 17→18|0/0|
|082|305753|2760|1762|1.5664|2758|1.0007|2522|weapon_flamethrower 17→18|0/0|
|083|308275|2760|1815|1.5207|2758|1.0007|2965|weapon_railgun 14→15; skill_critical 4→5|0/0|
|084|311240|2760|1265|2.1818|2758|1.0007|2602|weapon_cryocannon 18→19|0/0|
|085|313842|2760|2204|1.2523|2758|1.0007|3545|weapon_plasmacannon 15→16|0/0|
|086|317387|2760|1855|1.4879|2758|1.0007|3362|weapon_teslacoil 17→18|0/0|
|087|320749|2760|1857|1.4863|2758|1.0007|3259|weapon_railgun 15→16|0/0|
|088|324008|2760|1857|1.4863|2758|1.0007|3029|weapon_venomlauncher 17→18; skill_ricochet 4→5|0/0|
|089|327037|2760|1994|1.3842|2758|1.0007|3254|weapon_flamethrower 18→19|0/0|
|090|330291|2760|2751|1.0033|2758|1.0007|2778|weapon_teslacoil 18→19|0/0|
|091|333069|2760|1234|2.2366|2758|1.0007|2764|weapon_cryocannon 19→20|0/0|
|092|335833|2760|1862|1.4823|2758|1.0007|3936|weapon_plasmacannon 16→17|0/0|
|093|339769|2760|2266|1.2180|2758|1.0007|3376|weapon_railgun 16→17|0/0|
|094|343145|2760|1830|1.5082|2758|1.0007|3671|weapon_venomlauncher 18→19|0/0|
|095|354782|3512|3370|1.0421|3370|1.0421|3408|weapon_teslacoil 19→20|5/0|
|096|358190|3512|2429|1.4459|3370|1.0421|4461|weapon_plasmacannon 17→18|0/0|
|097|362651|3512|1863|1.8851|3370|1.0421|4195|weapon_railgun 17→18|0/0|
|098|366846|3512|2720|1.2912|3370|1.0421|4181|weapon_plasmacannon 18→19|0/0|
|099|371027|3512|3094|1.1351|3370|1.0421|3671|weapon_venomlauncher 19→20|0/0|
