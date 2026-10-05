状态：SEARCH_CANDIDATE_NOT_YET_FEASIBLE；待Fable签字，游戏数据未写入。

# 资源表 C 候选

§8.3离线假定3★首通，挑战首通优先；非门关每章最多6次，门关不限次数、照实列高度。不是运行时胜率。P(g)/F(g)与消费策略冻结，因子[0.5,2.0]。
优化前：88/99失败，目标36.608304。
优化后：22/99失败，目标6.560640。

缩放系数与逐字段旧/新对照完整列于同名JSON；所有候选仅在内存模拟。

|曲线|缩放系数/形式|
|---|---|
|first_clear_gold|[-0.6931471805599453, 0.0]；existing authored per-level values × exp(a+b*(L-1)/98)|
|kill_gold_mult|[-0.4431471805599453, -0.25]；existing authored per-level values × exp(a+b*(L-1)/98)|
|free_unlock_star|1.5576015661428098；existing free star tiers × constant|
|skill_base_xp_costs|[1.5576015661428098, 1.5576015661428098, 2.0, 2.0, 2.0]；same five authored cost tiers times positive monotone factors|
|sig_skill_xp_costs|[2.0, 2.0, 2.0, 2.0, 2.0]；same five authored cost tiers times positive monotone factors|
|weapon_cost.weapon_autocannon|2.0；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_flamethrower|2.0；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_cryocannon|2.0；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_teslacoil|1.8462326927732715；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_venomlauncher|2.0；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_railgun|2.0；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_scattergun|2.0；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_plasmacannon|2.0；same existing linear upgrade formula × constant base cost|

|文件/字段|旧值|候选新值|系数|
|---|---:|---:|---:|
|data/levels.json/0/first_clear_reward/gold|119|60|0.5|
|data/levels.json/1/first_clear_reward/gold|143|72|0.5|
|data/levels.json/2/first_clear_reward/gold|167|84|0.5|
|data/levels.json/3/first_clear_reward/gold|192|96|0.5|
|data/levels.json/4/first_clear_reward/gold|216|108|0.5|
|data/levels.json/5/first_clear_reward/gold|241|120|0.5|
|data/levels.json/6/first_clear_reward/gold|266|133|0.5|
|data/levels.json/7/first_clear_reward/gold|291|146|0.5|
|data/levels.json/8/first_clear_reward/gold|315|158|0.5|
|data/levels.json/9/first_clear_reward/gold|340|170|0.5|
|data/levels.json/10/first_clear_reward/gold|366|183|0.5|
|data/levels.json/11/first_clear_reward/gold|391|196|0.5|
|data/levels.json/12/first_clear_reward/gold|416|208|0.5|
|data/levels.json/13/first_clear_reward/gold|442|221|0.5|
|data/levels.json/14/first_clear_reward/gold|467|234|0.5|
|data/levels.json/15/first_clear_reward/gold|493|246|0.5|
|data/levels.json/16/first_clear_reward/gold|519|260|0.5|
|data/levels.json/17/first_clear_reward/gold|545|272|0.5|
|data/levels.json/18/first_clear_reward/gold|571|286|0.5|
|data/levels.json/19/first_clear_reward/gold|597|298|0.5|
|data/levels.json/20/first_clear_reward/gold|623|312|0.5|
|data/levels.json/21/first_clear_reward/gold|650|325|0.5|
|data/levels.json/22/first_clear_reward/gold|676|338|0.5|
|data/levels.json/23/first_clear_reward/gold|703|352|0.5|
|data/levels.json/24/first_clear_reward/gold|729|364|0.5|
|data/levels.json/25/first_clear_reward/gold|756|378|0.5|
|data/levels.json/26/first_clear_reward/gold|783|392|0.5|
|data/levels.json/27/first_clear_reward/gold|810|405|0.5|
|data/levels.json/28/first_clear_reward/gold|837|418|0.5|
|data/levels.json/29/first_clear_reward/gold|864|432|0.5|
|data/levels.json/30/first_clear_reward/gold|892|446|0.5|
|data/levels.json/31/first_clear_reward/gold|919|460|0.5|
|data/levels.json/32/first_clear_reward/gold|947|474|0.5|
|data/levels.json/33/first_clear_reward/gold|975|488|0.5|
|data/levels.json/34/first_clear_reward/gold|1002|501|0.5|
|data/levels.json/35/first_clear_reward/gold|1030|515|0.5|
|data/levels.json/36/first_clear_reward/gold|1058|529|0.5|
|data/levels.json/37/first_clear_reward/gold|1086|543|0.5|
|data/levels.json/38/first_clear_reward/gold|1115|558|0.5|
|data/levels.json/39/first_clear_reward/gold|1143|572|0.5|
|data/levels.json/40/first_clear_reward/gold|1171|586|0.5|
|data/levels.json/41/first_clear_reward/gold|1200|600|0.5|
|data/levels.json/42/first_clear_reward/gold|1229|614|0.5|
|data/levels.json/43/first_clear_reward/gold|1257|628|0.5|
|data/levels.json/44/first_clear_reward/gold|1286|643|0.5|
|data/levels.json/45/first_clear_reward/gold|1315|658|0.5|
|data/levels.json/46/first_clear_reward/gold|1344|672|0.5|
|data/levels.json/47/first_clear_reward/gold|1374|687|0.5|
|data/levels.json/48/first_clear_reward/gold|1403|702|0.5|
|data/levels.json/49/first_clear_reward/gold|1432|716|0.5|
|data/levels.json/50/first_clear_reward/gold|1462|731|0.5|
|data/levels.json/51/first_clear_reward/gold|1492|746|0.5|
|data/levels.json/52/first_clear_reward/gold|1521|760|0.5|
|data/levels.json/53/first_clear_reward/gold|1551|776|0.5|
|data/levels.json/54/first_clear_reward/gold|1581|790|0.5|
|data/levels.json/55/first_clear_reward/gold|1611|806|0.5|
|data/levels.json/56/first_clear_reward/gold|1642|821|0.5|
|data/levels.json/57/first_clear_reward/gold|1672|836|0.5|
|data/levels.json/58/first_clear_reward/gold|1702|851|0.5|
|data/levels.json/59/first_clear_reward/gold|1733|866|0.5|
|data/levels.json/60/first_clear_reward/gold|1764|882|0.5|
|data/levels.json/61/first_clear_reward/gold|1794|897|0.5|
|data/levels.json/62/first_clear_reward/gold|1825|912|0.5|
|data/levels.json/63/first_clear_reward/gold|1856|928|0.5|
|data/levels.json/64/first_clear_reward/gold|1887|944|0.5|
|data/levels.json/65/first_clear_reward/gold|1919|960|0.5|
|data/levels.json/66/first_clear_reward/gold|1950|975|0.5|
|data/levels.json/67/first_clear_reward/gold|1981|990|0.5|
|data/levels.json/68/first_clear_reward/gold|2013|1006|0.5|
|data/levels.json/69/first_clear_reward/gold|2044|1022|0.5|
|data/levels.json/70/first_clear_reward/gold|2076|1038|0.5|
|data/levels.json/71/first_clear_reward/gold|2108|1054|0.5|
|data/levels.json/72/first_clear_reward/gold|2140|1070|0.5|
|data/levels.json/73/first_clear_reward/gold|2172|1086|0.5|
|data/levels.json/74/first_clear_reward/gold|2204|1102|0.5|
|data/levels.json/75/first_clear_reward/gold|2237|1118|0.5|
|data/levels.json/76/first_clear_reward/gold|2269|1134|0.5|
|data/levels.json/77/first_clear_reward/gold|2302|1151|0.5|
|data/levels.json/78/first_clear_reward/gold|2334|1167|0.5|
|data/levels.json/79/first_clear_reward/gold|2367|1184|0.5|
|data/levels.json/80/first_clear_reward/gold|2400|1200|0.5|
|data/levels.json/81/first_clear_reward/gold|2433|1216|0.5|
|data/levels.json/82/first_clear_reward/gold|2466|1233|0.5|
|data/levels.json/83/first_clear_reward/gold|2499|1250|0.5|
|data/levels.json/84/first_clear_reward/gold|2532|1266|0.5|
|data/levels.json/85/first_clear_reward/gold|2566|1283|0.5|
|data/levels.json/86/first_clear_reward/gold|2599|1300|0.5|
|data/levels.json/87/first_clear_reward/gold|2633|1316|0.5|
|data/levels.json/88/first_clear_reward/gold|2667|1334|0.5|
|data/levels.json/89/first_clear_reward/gold|2700|1350|0.5|
|data/levels.json/90/first_clear_reward/gold|2734|1367|0.5|
|data/levels.json/91/first_clear_reward/gold|2769|1384|0.5|
|data/levels.json/92/first_clear_reward/gold|2803|1402|0.5|
|data/levels.json/93/first_clear_reward/gold|2837|1418|0.5|
|data/levels.json/94/first_clear_reward/gold|2871|1436|0.5|
|data/levels.json/95/first_clear_reward/gold|2906|1453|0.5|
|data/levels.json/96/first_clear_reward/gold|2940|1470|0.5|
|data/levels.json/97/first_clear_reward/gold|2975|1488|0.5|
|data/levels.json/98/first_clear_reward/gold|3010|1505|0.5|
|data/levels.json/0/reward_gold_mult|0.56|0.35952712|0.64201271|
|data/levels.json/1/reward_gold_mult|0.55|0.35220735|0.64037701|
|data/levels.json/2/reward_gold_mult|0.55|0.35131001|0.63874548|
|data/levels.json/3/reward_gold_mult|0.55|0.35041495|0.6371181|
|data/levels.json/4/reward_gold_mult|0.54|0.34316723|0.63549487|
|data/levels.json/5/reward_gold_mult|0.54|0.34229292|0.63387577|
|data/levels.json/6/reward_gold_mult|0.53|0.33509823|0.63226081|
|data/levels.json/7/reward_gold_mult|0.53|0.33424447|0.63064995|
|data/levels.json/8/reward_gold_mult|0.53|0.3333929|0.6290432|
|data/levels.json/9/reward_gold_mult|0.52|0.32626908|0.62744054|
|data/levels.json/10/reward_gold_mult|0.52|0.32543782|0.62584197|
|data/levels.json/11/reward_gold_mult|0.52|0.32460868|0.62424747|
|data/levels.json/12/reward_gold_mult|0.51|0.31755509|0.62265703|
|data/levels.json/13/reward_gold_mult|0.51|0.31674603|0.62107064|
|data/levels.json/14/reward_gold_mult|0.51|0.31593903|0.6194883|
|data/levels.json/15/reward_gold_mult|0.5|0.30895499|0.61790999|
|data/levels.json/16/reward_gold_mult|0.5|0.30816785|0.61633569|
|data/levels.json/17/reward_gold_mult|0.5|0.30738271|0.61476541|
|data/levels.json/18/reward_gold_mult|0.49|0.30046757|0.61319913|
|data/levels.json/19/reward_gold_mult|0.49|0.29970205|0.61163684|
|data/levels.json/20/reward_gold_mult|0.48|0.2928377|0.61007853|
|data/levels.json/21/reward_gold_mult|0.48|0.29209161|0.60852419|
|data/levels.json/22/reward_gold_mult|0.48|0.29134743|0.60697381|
|data/levels.json/23/reward_gold_mult|0.47|0.28455087|0.60542738|
|data/levels.json/24/reward_gold_mult|0.47|0.2838259|0.6038849|
|data/levels.json/25/reward_gold_mult|0.47|0.28310278|0.60234634|
|data/levels.json/26/reward_gold_mult|0.46|0.27637338|0.6008117|
|data/levels.json/27/reward_gold_mult|0.46|0.27566924|0.59928097|
|data/levels.json/28/reward_gold_mult|0.46|0.2749669|0.59775414|
|data/levels.json/29/reward_gold_mult|0.45|0.26830404|0.5962312|
|data/levels.json/30/reward_gold_mult|0.45|0.26762046|0.59471214|
|data/levels.json/31/reward_gold_mult|0.44|0.26100666|0.59319695|
|data/levels.json/32/reward_gold_mult|0.44|0.26034167|0.59168562|
|data/levels.json/33/reward_gold_mult|0.44|0.25967838|0.59017814|
|data/levels.json/34/reward_gold_mult|0.43|0.25313004|0.5886745|
|data/levels.json/35/reward_gold_mult|0.43|0.25248512|0.5871747|
|data/levels.json/36/reward_gold_mult|0.43|0.25184185|0.58567871|
|data/levels.json/37/reward_gold_mult|0.42|0.24535835|0.58418654|
|data/levels.json/38/reward_gold_mult|0.42|0.24473323|0.58269816|
|data/levels.json/39/reward_gold_mult|0.42|0.2441097|0.58121358|
|data/levels.json/40/reward_gold_mult|0.41|0.23769044|0.57973279|
|data/levels.json/41/reward_gold_mult|0.41|0.23708486|0.57825576|
|data/levels.json/42/reward_gold_mult|0.41|0.23648082|0.5767825|
|data/levels.json/43/reward_gold_mult|0.4|0.2301252|0.57531299|
|data/levels.json/44/reward_gold_mult|0.4|0.22953889|0.57384722|
|data/levels.json/45/reward_gold_mult|0.39|0.22323023|0.57238519|
|data/levels.json/46/reward_gold_mult|0.39|0.22266149|0.57092689|
|data/levels.json/47/reward_gold_mult|0.39|0.2220942|0.5694723|
|data/levels.json/48/reward_gold_mult|0.38|0.21584814|0.56802141|
|data/levels.json/49/reward_gold_mult|0.38|0.21529821|0.56657423|
|data/levels.json/50/reward_gold_mult|0.38|0.21474968|0.56513073|
|data/levels.json/51/reward_gold_mult|0.37|0.20856563|0.5636909|
|data/levels.json/52/reward_gold_mult|0.37|0.20803426|0.56225475|
|data/levels.json/53/reward_gold_mult|0.37|0.20750423|0.56082225|
|data/levels.json/54/reward_gold_mult|0.36|0.20138163|0.55939341|
|data/levels.json/55/reward_gold_mult|0.36|0.20086855|0.5579682|
|data/levels.json/56/reward_gold_mult|0.35|0.19479132|0.55654663|
|data/levels.json/57/reward_gold_mult|0.35|0.19429504|0.55512868|
|data/levels.json/58/reward_gold_mult|0.35|0.19380002|0.55371434|
|data/levels.json/59/reward_gold_mult|0.34|0.18778322|0.5523036|
|data/levels.json/60/reward_gold_mult|0.34|0.1873048|0.55089646|
|data/levels.json/61/reward_gold_mult|0.34|0.18682759|0.5494929|
|data/levels.json/62/reward_gold_mult|0.33|0.18087066|0.54809292|
|data/levels.json/63/reward_gold_mult|0.33|0.18040985|0.5466965|
|data/levels.json/64/reward_gold_mult|0.33|0.1799502|0.54530365|
|data/levels.json/65/reward_gold_mult|0.32|0.17405259|0.54391434|
|data/levels.json/66/reward_gold_mult|0.32|0.17360914|0.54252857|
|data/levels.json/67/reward_gold_mult|0.32|0.17316683|0.54114633|
|data/levels.json/68/reward_gold_mult|0.31|0.16732796|0.53976762|
|data/levels.json/69/reward_gold_mult|0.31|0.16690165|0.53839242|
|data/levels.json/70/reward_gold_mult|0.3|0.16110621|0.53702072|
|data/levels.json/71/reward_gold_mult|0.3|0.16069575|0.53565251|
|data/levels.json/72/reward_gold_mult|0.3|0.16028634|0.53428779|
|data/levels.json/73/reward_gold_mult|0.29|0.1545487|0.53292655|
|data/levels.json/74/reward_gold_mult|0.29|0.15415494|0.53156878|
|data/levels.json/75/reward_gold_mult|0.29|0.15376219|0.53021446|
|data/levels.json/76/reward_gold_mult|0.28|0.14808181|0.5288636|
|data/levels.json/77/reward_gold_mult|0.28|0.14770453|0.52751617|
|data/levels.json/78/reward_gold_mult|0.28|0.14732821|0.52617218|
|data/levels.json/79/reward_gold_mult|0.27|0.14170454|0.52483162|
|data/levels.json/80/reward_gold_mult|0.27|0.14134351|0.52349447|
|data/levels.json/81/reward_gold_mult|0.26|0.13576179|0.52216073|
|data/levels.json/82/reward_gold_mult|0.26|0.1354159|0.52083038|
|data/levels.json/83/reward_gold_mult|0.26|0.13507089|0.51950343|
|data/levels.json/84/reward_gold_mult|0.26|0.13472676|0.51817985|
|data/levels.json/85/reward_gold_mult|0.26|0.13438351|0.51685965|
|data/levels.json/86/reward_gold_mult|0.26|0.13404113|0.51554281|
|data/levels.json/87/reward_gold_mult|0.26|0.13369962|0.51422932|
|data/levels.json/88/reward_gold_mult|0.26|0.13335899|0.51291919|
|data/levels.json/89/reward_gold_mult|0.26|0.13301922|0.51161239|
|data/levels.json/90/reward_gold_mult|0.26|0.13268032|0.51030892|
|data/levels.json/91/reward_gold_mult|0.26|0.13234228|0.50900877|
|data/levels.json/92/reward_gold_mult|0.26|0.1320051|0.50771193|
|data/levels.json/93/reward_gold_mult|0.26|0.13166878|0.5064184|
|data/levels.json/94/reward_gold_mult|0.26|0.13133332|0.50512816|
|data/levels.json/95/reward_gold_mult|0.26|0.13099871|0.50384121|
|data/levels.json/96/reward_gold_mult|0.26|0.13066496|0.50255754|
|data/levels.json/97/reward_gold_mult|0.26|0.13033206|0.50127714|
|data/levels.json/98/reward_gold_mult|0.26|0.13|0.5|
|data/weapons.json/weapon_flamethrower/unlock_cost_star|8|12|1.5576016|
|data/weapons.json/weapon_cryocannon/unlock_cost_star|8|12|1.5576016|
|data/weapons.json/weapon_teslacoil/unlock_cost_star|10|16|1.5576016|
|data/weapons.json/weapon_venomlauncher/unlock_cost_star|8|12|1.5576016|
|data/weapons.json/weapon_railgun/unlock_cost_star|14|22|1.5576016|
|data/weapons.json/weapon_scattergun/unlock_cost_star|9|14|1.5576016|
|data/weapons.json/weapon_plasmacannon/unlock_cost_star|16|25|1.5576016|
|data/armors.json/armor_kevlar/unlock_cost_star|8|12|1.5576016|
|data/armors.json/armor_thermal/unlock_cost_star|8|12|1.5576016|
|data/armors.json/armor_cryo/unlock_cost_star|9|14|1.5576016|
|data/armors.json/armor_faraday/unlock_cost_star|10|16|1.5576016|
|data/armors.json/armor_hazmat/unlock_cost_star|11|17|1.5576016|
|data/armors.json/armor_reactive/unlock_cost_star|14|22|1.5576016|
|data/chips.json/chip_attack/unlock_cost_star|8|12|1.5576016|
|data/chips.json/chip_haste/unlock_cost_star|8|12|1.5576016|
|data/chips.json/chip_crit/unlock_cost_star|9|14|1.5576016|
|data/chips.json/chip_pierce/unlock_cost_star|11|17|1.5576016|
|data/chips.json/chip_health/unlock_cost_star|9|14|1.5576016|
|data/chips.json/chip_guardian/unlock_cost_star|10|16|1.5576016|
|data/chips.json/chip_greed/unlock_cost_star|11|17|1.5576016|
|data/chips.json/chip_element/unlock_cost_star|14|22|1.5576016|
|data/pets.json/pet_turret_drone/unlock_cost_star|8|12|1.5576016|
|data/pets.json/pet_fire_imp/unlock_cost_star|9|14|1.5576016|
|data/pets.json/pet_frost_wisp/unlock_cost_star|10|16|1.5576016|
|data/pets.json/pet_volt_orb/unlock_cost_star|11|17|1.5576016|
|data/pets.json/pet_medic_drone/unlock_cost_star|13|20|1.5576016|
|data/pets.json/pet_collector/unlock_cost_star|14|22|1.5576016|
|data/economy.json/skill_base_xp_costs/0|350|545|1.5576016|
|data/economy.json/skill_base_xp_costs/1|900|1402|1.5576016|
|data/economy.json/skill_base_xp_costs/2|2000|4000|2|
|data/economy.json/skill_base_xp_costs/3|4000|8000|2|
|data/economy.json/skill_base_xp_costs/4|8500|17000|2|
|data/economy.json/sig_skill_xp_costs/0|450|900|2|
|data/economy.json/sig_skill_xp_costs/1|1200|2400|2|
|data/economy.json/sig_skill_xp_costs/2|2700|5400|2|
|data/economy.json/sig_skill_xp_costs/3|5400|10800|2|
|data/economy.json/sig_skill_xp_costs/4|11000|22000|2|
|data/weapons.json/weapon_autocannon/cost_base_gold|100|200|2|
|data/weapons.json/weapon_flamethrower/cost_base_gold|180|360|2|
|data/weapons.json/weapon_cryocannon/cost_base_gold|180|360|2|
|data/weapons.json/weapon_teslacoil/cost_base_gold|240|443|1.8462327|
|data/weapons.json/weapon_venomlauncher/cost_base_gold|240|480|2|
|data/weapons.json/weapon_railgun/cost_base_gold|320|640|2|
|data/weapons.json/weapon_scattergun/cost_base_gold|180|360|2|
|data/weapons.json/weapon_plasmacannon/cost_base_gold|320|640|2|

|关卡|rec|E|旧P|新P|新R|新P/E|下限|上限|达标|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
|001|50|65|65|65|1.3000|1.0000|48|71|True|
|002|50|65|69|66|1.3200|1.0154|48|71|True|
|003|50|65|73|69|1.3800|1.0615|48|71|True|
|004|64|65|74|69|1.0781|1.0615|61|71|True|
|005|76|76|81|76|1.0000|1.0000|76|83|True|
|006|53|76|82|76|1.4340|1.0000|51|83|True|
|007|53|76|89|81|1.5283|1.0658|53|83|True|
|008|79|79|96|83|1.0506|1.0506|79|86|True|
|009|79|79|106|88|1.1139|1.1139|79|86|False|
|010|87|87|112|89|1.0230|1.0230|87|95|True|
|011|99|99|116|98|0.9899|0.9899|95|108|True|
|012|108|108|122|103|0.9537|0.9537|103|118|True|
|013|131|131|131|129|0.9847|0.9847|125|144|True|
|014|138|138|141|135|0.9783|0.9783|132|151|True|
|015|147|147|151|147|1.0000|1.0000|147|161|True|
|016|98|147|152|150|1.5306|1.0204|94|161|True|
|017|165|165|166|167|1.0121|1.0121|0|181|True|
|018|185|185|207|185|1.0000|1.0000|0|203|True|
|019|188|188|210|205|1.0904|1.0904|188|206|True|
|020|291|291|291|294|1.0103|1.0103|0|320|True|
|021|164|291|323|297|1.8110|1.0206|156|320|True|
|022|183|291|339|297|1.6230|1.0206|174|320|True|
|023|186|291|355|301|1.6183|1.0344|177|320|True|
|024|201|291|374|303|1.5075|1.0412|191|320|True|
|025|260|291|410|326|1.2538|1.1203|260|320|False|
|026|226|291|410|340|1.5044|1.1684|215|320|False|
|027|195|291|410|340|1.7436|1.1684|195|320|False|
|028|231|291|474|358|1.5498|1.2302|231|320|False|
|029|206|291|509|358|1.7379|1.2302|206|320|False|
|030|332|332|515|358|1.0783|1.0783|332|365|True|
|031|159|332|522|358|2.2516|1.0783|152|365|True|
|032|245|332|530|365|1.4898|1.0994|233|365|True|
|033|228|332|573|365|1.6009|1.0994|217|365|True|
|034|330|332|573|365|1.1061|1.0994|314|365|True|
|035|219|332|648|365|1.6667|1.0994|219|365|True|
|036|225|332|679|415|1.8444|1.2500|214|365|False|
|037|232|332|685|427|1.8405|1.2861|232|365|False|
|038|484|484|710|530|1.0950|1.0950|484|532|True|
|039|533|533|849|541|1.0150|1.0150|533|586|True|
|040|574|574|849|579|1.0087|1.0087|574|631|True|
|041|236|574|880|607|2.5720|1.0575|225|631|True|
|042|375|574|942|607|1.6187|1.0575|357|631|True|
|043|587|587|951|607|1.0341|1.0341|558|645|True|
|044|757|757|957|738|0.9749|0.9749|0|832|True|
|045|655|757|963|738|1.1267|0.9749|655|832|True|
|046|600|757|972|798|1.3300|1.0542|570|832|True|
|047|670|757|983|798|1.1910|1.0542|670|832|True|
|048|663|757|983|856|1.2911|1.1308|663|832|False|
|049|658|757|1008|856|1.3009|1.1308|658|832|False|
|050|868|868|1068|897|1.0334|1.0334|868|954|True|
|051|431|868|1185|897|2.0812|1.0334|410|954|True|
|052|349|868|1185|947|2.7135|1.0910|332|954|True|
|053|427|868|1185|950|2.2248|1.0945|406|954|True|
|054|359|868|1185|963|2.6825|1.1094|342|954|False|
|055|950|950|1185|963|1.0137|1.0137|950|1045|True|
|056|354|950|1237|969|2.7373|1.0200|337|1045|True|
|057|990|990|1237|993|1.0030|1.0030|0|1089|True|
|058|503|990|1284|993|1.9742|1.0030|503|1089|True|
|059|562|990|1284|997|1.7740|1.0071|562|1089|True|
|060|990|990|1300|1032|1.0424|1.0424|990|1089|True|
|061|990|990|1491|1032|1.0424|1.0424|941|1089|True|
|062|250|990|1577|1065|4.2600|1.0758|238|1089|True|
|063|576|990|1763|1065|1.8490|1.0758|548|1089|True|
|064|955|990|1763|1065|1.1152|1.0758|908|1089|True|
|065|1014|1014|1813|1193|1.1765|1.1765|1014|1115|False|
|066|1184|1184|1813|1193|1.0076|1.0076|1125|1302|True|
|067|955|1184|1813|1204|1.2607|1.0169|955|1302|True|
|068|1042|1184|1814|1204|1.1555|1.0169|1042|1302|True|
|069|978|1184|2043|1255|1.2832|1.0600|978|1302|True|
|070|1286|1286|2043|1557|1.2107|1.2107|1286|1414|False|
|071|1146|1286|2202|1563|1.3639|1.2154|1089|1414|False|
|072|1576|1576|2308|1573|0.9981|0.9981|1498|1733|True|
|073|818|1576|2308|1811|2.2139|1.1491|778|1733|False|
|074|2034|2034|2429|2034|1.0000|1.0000|0|2237|True|
|075|1841|2034|2733|2203|1.1966|1.0831|1841|2237|True|
|076|2758|2758|2989|2687|0.9743|0.9743|0|3033|True|
|077|1652|2758|3160|2687|1.6265|0.9743|1652|3033|True|
|078|2226|2758|3160|2687|1.2071|0.9743|2226|3033|True|
|079|2030|2758|3160|2687|1.3236|0.9743|2030|3033|True|
|080|2067|2758|3220|2714|1.3130|0.9840|2067|3033|True|
|081|1096|2758|3270|2714|2.4763|0.9840|1042|3033|True|
|082|1762|2758|3270|2736|1.5528|0.9920|1674|3033|True|
|083|1815|2758|3270|2736|1.5074|0.9920|1725|3033|True|
|084|1265|2758|3271|2736|2.1628|0.9920|1202|3033|True|
|085|2204|2758|3271|2764|1.2541|1.0022|2204|3033|True|
|086|1855|2758|3538|2764|1.4900|1.0022|1763|3033|True|
|087|1857|2758|3639|2764|1.4884|1.0022|1857|3033|True|
|088|1857|2758|3700|3158|1.7006|1.1450|1857|3033|False|
|089|1994|2758|3974|3158|1.5838|1.1450|1994|3033|False|
|090|2751|2758|3994|3158|1.1479|1.1450|2751|3033|False|
|091|1234|2758|4401|3184|2.5802|1.1545|1173|3033|False|
|092|1862|2758|4401|3184|1.7100|1.1545|1769|3033|False|
|093|2266|2758|4404|3184|1.4051|1.1545|2153|3033|False|
|094|1830|2758|4406|3251|1.7765|1.1788|1739|3033|False|
|095|3370|3370|4415|3423|1.0157|1.0157|0|3707|True|
|096|2429|3370|4415|3549|1.4611|1.0531|2308|3707|True|
|097|1863|3370|4415|3549|1.9050|1.0531|1863|3707|True|
|098|2720|3370|5163|3549|1.3048|1.0531|2720|3707|True|
|099|3094|3370|5283|3549|1.1471|1.0531|3094|3707|True|

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

首次R<0.95：None；G1走廊不满足关数：22/99。

包络目标Σ|P−E|/E：6.560640。

回刷总数：89（非门10，门79）；各章非门：{'1': 2, '2': 5, '3': 0, '4': 3, '5': 0, '6': 0, '7': 0, '8': 0, '9': 0, '10': 0}。
门关：[17, 18, 20, 44, 57, 74, 76, 95]；预算后新增门：[17, 18, 44, 57, 74]；未刷够门：[]；非门失败：[9, 25, 26, 27, 28, 29, 36, 37, 48, 49, 54, 65, 70, 71, 73, 88, 89, 90, 91, 92, 93, 94]。

|回刷位置|路线(挑战/普通)|入场P|回刷后P|次数|非门章累计|刷够|八墙关|门高度/路线注记|
|---|---|---:|---:|---:|---:|---|---|---|
|005|004挑, 003挑|70|76|2|2|True|False|非门|
|013|012挑, 011挑, 010挑, 009挑|103|129|4|4|True|False|非门|
|015|014挑|137|147|1|5|True|True|非门|
|017|016挑, 015挑|151|167|2|5|True|True|2 / 仅挑战 / challenge-first route still exceeds chapter remaining budget|
|018|017挑, 013挑, 008挑, 007挑|171|185|4|5|True|True|4 / 仅挑战 / challenge-first route still exceeds chapter remaining budget|
|020|019挑, 018挑, 006挑, 005挑, 002挑, 001挑, 019普, 019普, 019普, 019普, 019普, 019普, 019普, 019普, 019普, 019普, 019普, 019普|206|294|18|5|True|True|18 / 仅挑战 / Owner fixed gate|
|038|037挑, 036挑, 035挑|431|530|3|3|True|False|非门|
|044|043挑, 042挑, 041挑, 040挑, 039挑, 038挑, 034挑, 033挑|674|738|8|0|True|True|8 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|057|056挑, 055挑, 054挑, 053挑, 052挑, 051挑, 050挑, 049挑, 048挑, 047挑, 046挑, 045挑, 044挑, 032挑, 031挑, 030挑|973|993|16|0|True|False|16 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|074|073挑, 072挑, 071挑, 070挑, 069挑, 068挑, 067挑, 066挑, 065挑, 064挑, 063挑, 062挑, 061挑, 060挑, 059挑, 058挑, 057挑|1811|2034|17|0|True|False|17 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|076|075挑, 074挑, 029挑, 028挑, 027挑, 026挑, 025挑, 024挑, 023挑, 022挑, 021挑|2233|2687|11|0|True|True|11 / 可付费（未做运行时验证） / Owner fixed gate|
|095|094挑, 093挑, 092挑|3251|3423|3|0|True|False|3 / 可付费（未做运行时验证） / Owner fixed gate|

## 门关高度（含无需回刷的固定门）

|门|高度|已刷够|路径|原因|
|---|---:|---|---|---|
|017|2|True|仅挑战|challenge-first route still exceeds chapter remaining budget|
|018|4|True|仅挑战|challenge-first route still exceeds chapter remaining budget|
|020|18|True|仅挑战|Owner fixed gate|
|044|8|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|057|16|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|074|17|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|076|11|True|可付费（未做运行时验证）|Owner fixed gate|
|095|3|True|可付费（未做运行时验证）|Owner fixed gate|

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|当关/章累计回刷|
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
|001|0|65|50|1.3000|65|1.0000|286|weapon_autocannon 1→2|0/0|
|002|286|66|50|1.3200|65|1.0154|380|weapon_autocannon 2→3; skill_multishot 0→1|0/0|
|003|666|69|50|1.3800|65|1.0615|452|weapon_autocannon 3→4|0/0|
|004|1118|69|64|1.0781|65|1.0615|554|weapon_cryocannon; weapon_autocannon 4→5; skill_pierce 0→1|0/0|
|005|2498|76|76|1.0000|76|1.0000|626|weapon_cryocannon 2→3; skill_salvo 0→1|2/2|
|006|3124|76|53|1.4340|76|1.0000|672|armor_kevlar; weapon_autocannon 5→6; skill_charge_shot 0→1|0/2|
|007|3796|81|53|1.5283|76|1.0658|725|armor_kevlar 1→3; vanguard 3→4|0/2|
|008|4521|83|79|1.0506|79|1.0506|906|weapon_autocannon 6→7; signature 0→1|0/2|
|009|5427|88|79|1.1139|79|1.1139|683|armor_kevlar 3→4; vanguard 4→5; skill_slow_field 0→1|0/2|
|010|6110|89|87|1.0230|87|1.0230|725|chip_attack; chip_attack 1→4|0/2|
|011|6835|98|99|0.9899|99|0.9899|1123|chip_attack 4→5; weapon_autocannon 7→8; skill_split_shot 0→1|0/0|
|012|7958|103|108|0.9537|108|0.9537|1151|weapon_cryocannon 3→4; skill_critical 0→1; skill_ricochet 0→1|0/0|
|013|12084|129|131|0.9847|131|0.9847|1298|weapon_autocannon 9→10|4/4|
|014|13382|135|138|0.9783|138|0.9783|1277|pet_turret_drone 3→4; weapon_cryocannon 4→5; skill_pierce 1→2|0/4|
|015|15715|147|147|1.0000|147|1.0000|824|weapon_scattergun 3→4; skill_homing 1→2|1/5|
|016|16539|150|98|1.5306|147|1.0204|1637|chip_attack 5→6; weapon_scattergun 4→5|0/5|
|017|20157|167|165|1.0121|165|1.0121|1601|weapon_scattergun 6→7; skill_salvo 1→2|2/5|
|018|25541|185|185|1.0000|185|1.0000|1294|weapon_railgun 2→3; skill_slow_field 1→2|4/5|
|019|26835|205|188|1.0904|188|1.0904|1772|weapon_scattergun 7→8|0/5|
|020|50551|294|291|1.0103|291|1.0103|1885|pet_turret_drone 7→8; vanguard 12→13|18/5|
|021|52436|297|164|1.8110|291|1.0206|1684|weapon_venomlauncher; weapon_venomlauncher 1→3|0/0|
|022|54120|297|183|1.6230|291|1.0206|1859|weapon_scattergun 8→9|0/0|
|023|55979|301|186|1.6183|291|1.0344|2144|chip_attack 10→11; weapon_venomlauncher 3→4|0/0|
|024|58123|303|201|1.5075|291|1.0412|1960|armor_kevlar 9→10; weapon_venomlauncher 4→5; skill_multishot 2→3|0/0|
|025|60083|326|260|1.2538|291|1.1203|1359|vanguard 13→14|0/0|
|026|61442|340|226|1.5044|291|1.1684|2248|weapon_venomlauncher 5→6|0/0|
|027|63690|340|195|1.7436|291|1.1684|2136|weapon_scattergun 9→10|0/0|
|028|65826|358|231|1.5498|291|1.2302|2354|weapon_railgun 5→6|0/0|
|029|68180|358|206|1.7379|291|1.2302|2398|weapon_venomlauncher 6→7|0/0|
|030|70578|358|332|1.0783|332|1.0783|1853|weapon_cryocannon 8→9; skill_pierce 2→3|0/0|
|031|72431|358|159|2.2516|332|1.0783|2651|weapon_flamethrower; chip_attack 11→12; weapon_flamethrower 1→4|0/0|
|032|75082|365|245|1.4898|332|1.0994|2481|weapon_plasmacannon; armor_kevlar 10→11; weapon_plasmacannon 1→3|0/0|
|033|77563|365|228|1.6009|332|1.0994|2255|weapon_plasmacannon 3→4|0/0|
|034|79818|365|330|1.1061|332|1.0994|2898|weapon_flamethrower 4→5; weapon_plasmacannon 4→5; skill_homing 2→3|0/0|
|035|82716|365|219|1.6667|332|1.0994|2130|weapon_scattergun 10→11|0/0|
|036|84846|415|225|1.8444|332|1.2500|2765|chip_attack 12→13; weapon_flamethrower 5→6|0/0|
|037|87611|427|232|1.8405|332|1.2861|3271|pet_turret_drone 8→9; weapon_scattergun 11→12|0/0|
|038|97503|530|484|1.0950|484|1.0950|3443|weapon_scattergun 12→13|3/3|
|039|100946|541|533|1.0150|533|1.0150|2890|weapon_scattergun 13→14|0/3|
|040|103836|579|574|1.0087|574|1.0087|3910|weapon_scattergun 14→15; skill_salvo 2→3|0/3|
|041|107746|607|236|2.5720|574|1.0575|3671|weapon_teslacoil; weapon_teslacoil 1→5|0/0|
|042|111417|607|375|1.6187|574|1.0575|3341|weapon_teslacoil 5→7|0/0|
|043|114758|607|587|1.0341|587|1.0341|4010|weapon_scattergun 15→16; skill_charge_shot 2→3|0/0|
|044|140751|738|757|0.9749|757|0.9749|3864|weapon_plasmacannon 7→8|8/0|
|045|144615|738|655|1.1267|757|0.9749|3974|weapon_scattergun 16→17|0/0|
|046|148589|798|600|1.3300|757|1.0542|3443|weapon_railgun 7→8; skill_critical 2→3|0/0|
|047|152032|798|670|1.1910|757|1.0542|3677|weapon_scattergun 17→18|0/0|
|048|155709|856|663|1.2911|757|1.1308|4362|armor_kevlar 12→13; weapon_teslacoil 8→9|0/0|
|049|160071|856|658|1.3009|757|1.1308|4168|weapon_scattergun 18→19; skill_ricochet 2→3|0/0|
|050|164239|897|868|1.0334|868|1.0334|3131|weapon_venomlauncher 8→9|0/0|
|051|167370|897|431|2.0812|868|1.0334|1332|vanguard 17→18|0/0|
|052|168702|947|349|2.7135|868|1.0910|1513|chip_attack 14→15|0/0|
|053|170215|950|427|2.2248|868|1.0945|1449|weapon_autocannon 14→15; signature 2→3|0/0|
|054|171664|963|359|2.6825|868|1.1094|1496|armor_kevlar 13→14|0/0|
|055|173160|963|950|1.0137|950|1.0137|1538|vanguard 18→19|0/0|
|056|174698|969|354|2.7373|950|1.0200|1418|chip_attack 15→16|0/0|
|057|207813|993|990|1.0030|990|1.0030|2604|weapon_autocannon 17→18|16/0|
|058|210417|993|503|1.9742|990|1.0030|1617|chip_attack 17→18|0/0|
|059|212034|997|562|1.7740|990|1.0071|1581|vanguard 20→21|0/0|
|060|213615|1032|990|1.0424|990|1.0424|3419|weapon_teslacoil 10→11; skill_barrier 3→4|0/0|
|061|217034|1032|990|1.0424|990|1.0424|1988|vanguard 21→22|0/0|
|062|219022|1065|250|4.2600|990|1.0758|2047|armor_kevlar 15→16|0/0|
|063|221069|1065|576|1.8490|990|1.0758|1884|weapon_autocannon 18→19|0/0|
|064|222953|1065|955|1.1152|990|1.0758|1892|chip_attack 18→19|0/0|
|065|224845|1193|1014|1.1765|1014|1.1765|2232|weapon_cryocannon 11→12; skill_salvo 3→4|0/0|
|066|227077|1193|1184|1.0076|1184|1.0076|1832|pet_turret_drone 12→13|0/0|
|067|228909|1204|955|1.2607|1184|1.0169|2499|weapon_flamethrower 11→12|0/0|
|068|231408|1204|1042|1.1555|1184|1.0169|2258|vanguard 22→23|0/0|
|069|233666|1255|978|1.2832|1184|1.0600|2374|vanguard 23→24; skill_charge_shot 3→4|0/0|
|070|236040|1557|1286|1.2107|1286|1.2107|2250|armor_kevlar 16→17; pet_turret_drone 13→14|0/0|
|071|238290|1563|1146|1.3639|1286|1.2154|2008|chip_attack 19→20|0/0|
|072|240298|1573|1576|0.9981|1576|0.9981|1915|vanguard 24→25|0/0|
|073|242213|1811|818|2.2139|1576|1.1491|2076|armor_kevlar 17→18; skill_slow_field 3→4|0/0|
|074|264713|2034|2034|1.0000|2034|1.0000|2498|vanguard 26→27|17/0|
|075|267211|2203|1841|1.1966|2034|1.0831|2666|chip_attack 23→24|0/0|
|076|287711|2687|2758|0.9743|2758|0.9743|2308|weapon_venomlauncher 10→11|11/0|
|077|290019|2687|1652|1.6265|2758|0.9743|2600|armor_kevlar 24→25|0/0|
|078|292619|2687|2226|1.2071|2758|0.9743|2358|weapon_flamethrower 12→13|0/0|
|079|294977|2687|2030|1.3236|2758|0.9743|2607|chip_attack 28→29|0/0|
|080|297584|2714|2067|1.3130|2758|0.9840|2852|weapon_cryocannon 13→14|0/0|
|081|300436|2714|1096|2.4763|2758|0.9840|2232|pet_turret_drone 19→20|0/0|
|082|302668|2736|1762|1.5528|2758|0.9920|2188|armor_kevlar 25→26; skill_pierce 4→5|0/0|
|083|304856|2736|1815|1.5074|2758|0.9920|2643|weapon_autocannon 20→21|0/0|
|084|307499|2736|1265|2.1628|2758|0.9920|2238|chip_attack 29→30|0/0|
|085|309737|2764|2204|1.2541|2758|1.0022|3141|weapon_teslacoil 11→12|0/0|
|086|312878|2764|1855|1.4900|2758|1.0022|3009|weapon_autocannon 21→22|0/0|
|087|315887|2764|1857|1.4884|2758|1.0022|2881|vanguard 27→28|0/0|
|088|318768|3158|1857|1.7006|2758|1.1450|2647|armor_kevlar 26→27; skill_homing 4→5|0/0|
|089|321415|3158|1994|1.5838|2758|1.1450|2936|weapon_flamethrower 13→14|0/0|
|090|324351|3158|2751|1.1479|2758|1.1450|2448|pet_turret_drone 20→21|0/0|
|091|326799|3184|1234|2.5802|2758|1.1545|2381|weapon_autocannon 22→23|0/0|
|092|329180|3184|1862|1.7100|2758|1.1545|3474|weapon_autocannon 23→24|0/0|
|093|332654|3184|2266|1.4051|2758|1.1545|2952|vanguard 28→29|0/0|
|094|335606|3251|1830|1.7765|2758|1.1788|3200|weapon_autocannon 24→25; skill_barrier 4→5|0/0|
|095|344228|3423|3370|1.0157|3370|1.0157|2958|vanguard 30→31|3/0|
|096|347186|3549|2429|1.4611|3370|1.0531|3923|weapon_venomlauncher 11→12|0/0|
|097|351109|3549|1863|1.9050|3370|1.0531|3672|weapon_teslacoil 12→13; skill_salvo 4→5|0/0|
|098|354781|3549|2720|1.3048|3370|1.0531|3665|weapon_cryocannon 14→15|0/0|
|099|358446|3549|3094|1.1471|3370|1.0531|3185|vanguard 31→32|0/0|
