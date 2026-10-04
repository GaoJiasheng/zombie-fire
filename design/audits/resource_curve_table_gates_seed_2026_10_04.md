状态：SEARCH_CANDIDATE_NOT_YET_FEASIBLE；待Fable签字，游戏数据未写入。

# 资源表 C 候选

§8.3离线假定3★首通，挑战首通优先；非门关每章最多6次，门关不限次数、照实列高度。不是运行时胜率。P(g)/F(g)与消费策略冻结，因子[0.5,2.0]。
优化前：88/99失败，目标36.608304。
优化后：26/99失败，目标6.586357。

缩放系数与逐字段旧/新对照完整列于同名JSON；所有候选仅在内存模拟。

|曲线|缩放系数/形式|
|---|---|
|first_clear_gold|[-0.5985306819899631, -0.09461649856998222]；existing authored per-level values × exp(a+b*(L-1)/98)|
|kill_gold_mult|[-0.2601318148712112, -0.418535190670553]；existing authored per-level values × exp(a+b*(L-1)/98)|
|free_unlock_star|1.1903490410215907；existing free star tiers × constant|
|skill_base_xp_costs|[1.7210840034052919, 1.6829363567660056, 1.4750963937990744, 1.434155641207124, 1.2954105268300655]；same five authored cost tiers times positive monotone factors|
|sig_skill_xp_costs|[0.8917704623459298, 0.9036935128924484, 0.9439074721906024, 1.2808747038072086, 1.3240797853307809]；same five authored cost tiers times positive monotone factors|
|weapon_cost.weapon_autocannon|1.8746604082207952；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_flamethrower|1.3694002976685395；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_cryocannon|0.7270569814769955；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_teslacoil|2.0；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_venomlauncher|0.5998577067298161；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_railgun|1.1770028027012027；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_scattergun|0.8809692636941789；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_plasmacannon|1.2374981161531327；same existing linear upgrade formula × constant base cost|

|文件/字段|旧值|候选新值|系数|
|---|---:|---:|---:|
|data/levels.json/0/first_clear_reward/gold|119|65|0.54961861|
|data/levels.json/1/first_clear_reward/gold|143|79|0.54908822|
|data/levels.json/2/first_clear_reward/gold|167|92|0.54855835|
|data/levels.json/3/first_clear_reward/gold|192|105|0.54802898|
|data/levels.json/4/first_clear_reward/gold|216|118|0.54750013|
|data/levels.json/5/first_clear_reward/gold|241|132|0.54697179|
|data/levels.json/6/first_clear_reward/gold|266|145|0.54644396|
|data/levels.json/7/first_clear_reward/gold|291|159|0.54591663|
|data/levels.json/8/first_clear_reward/gold|315|172|0.54538982|
|data/levels.json/9/first_clear_reward/gold|340|185|0.54486351|
|data/levels.json/10/first_clear_reward/gold|366|199|0.54433771|
|data/levels.json/11/first_clear_reward/gold|391|213|0.54381242|
|data/levels.json/12/first_clear_reward/gold|416|226|0.54328764|
|data/levels.json/13/first_clear_reward/gold|442|240|0.54276336|
|data/levels.json/14/first_clear_reward/gold|467|253|0.54223959|
|data/levels.json/15/first_clear_reward/gold|493|267|0.54171633|
|data/levels.json/16/first_clear_reward/gold|519|281|0.54119356|
|data/levels.json/17/first_clear_reward/gold|545|295|0.54067131|
|data/levels.json/18/first_clear_reward/gold|571|308|0.54014956|
|data/levels.json/19/first_clear_reward/gold|597|322|0.53962831|
|data/levels.json/20/first_clear_reward/gold|623|336|0.53910756|
|data/levels.json/21/first_clear_reward/gold|650|350|0.53858732|
|data/levels.json/22/first_clear_reward/gold|676|364|0.53806758|
|data/levels.json/23/first_clear_reward/gold|703|378|0.53754834|
|data/levels.json/24/first_clear_reward/gold|729|391|0.5370296|
|data/levels.json/25/first_clear_reward/gold|756|406|0.53651136|
|data/levels.json/26/first_clear_reward/gold|783|420|0.53599362|
|data/levels.json/27/first_clear_reward/gold|810|434|0.53547638|
|data/levels.json/28/first_clear_reward/gold|837|448|0.53495964|
|data/levels.json/29/first_clear_reward/gold|864|462|0.5344434|
|data/levels.json/30/first_clear_reward/gold|892|476|0.53392766|
|data/levels.json/31/first_clear_reward/gold|919|490|0.53341242|
|data/levels.json/32/first_clear_reward/gold|947|505|0.53289767|
|data/levels.json/33/first_clear_reward/gold|975|519|0.53238342|
|data/levels.json/34/first_clear_reward/gold|1002|533|0.53186966|
|data/levels.json/35/first_clear_reward/gold|1030|547|0.5313564|
|data/levels.json/36/first_clear_reward/gold|1058|562|0.53084364|
|data/levels.json/37/first_clear_reward/gold|1086|576|0.53033137|
|data/levels.json/38/first_clear_reward/gold|1115|591|0.5298196|
|data/levels.json/39/first_clear_reward/gold|1143|605|0.52930832|
|data/levels.json/40/first_clear_reward/gold|1171|619|0.52879753|
|data/levels.json/41/first_clear_reward/gold|1200|634|0.52828724|
|data/levels.json/42/first_clear_reward/gold|1229|649|0.52777743|
|data/levels.json/43/first_clear_reward/gold|1257|663|0.52726812|
|data/levels.json/44/first_clear_reward/gold|1286|677|0.52675931|
|data/levels.json/45/first_clear_reward/gold|1315|692|0.52625098|
|data/levels.json/46/first_clear_reward/gold|1344|707|0.52574314|
|data/levels.json/47/first_clear_reward/gold|1374|722|0.5252358|
|data/levels.json/48/first_clear_reward/gold|1403|736|0.52472894|
|data/levels.json/49/first_clear_reward/gold|1432|751|0.52422257|
|data/levels.json/50/first_clear_reward/gold|1462|766|0.52371669|
|data/levels.json/51/first_clear_reward/gold|1492|781|0.5232113|
|data/levels.json/52/first_clear_reward/gold|1521|795|0.5227064|
|data/levels.json/53/first_clear_reward/gold|1551|810|0.52220198|
|data/levels.json/54/first_clear_reward/gold|1581|825|0.52169805|
|data/levels.json/55/first_clear_reward/gold|1611|840|0.52119461|
|data/levels.json/56/first_clear_reward/gold|1642|855|0.52069165|
|data/levels.json/57/first_clear_reward/gold|1672|870|0.52018918|
|data/levels.json/58/first_clear_reward/gold|1702|885|0.51968719|
|data/levels.json/59/first_clear_reward/gold|1733|900|0.51918569|
|data/levels.json/60/first_clear_reward/gold|1764|915|0.51868467|
|data/levels.json/61/first_clear_reward/gold|1794|930|0.51818414|
|data/levels.json/62/first_clear_reward/gold|1825|945|0.51768408|
|data/levels.json/63/first_clear_reward/gold|1856|960|0.51718451|
|data/levels.json/64/first_clear_reward/gold|1887|975|0.51668543|
|data/levels.json/65/first_clear_reward/gold|1919|991|0.51618682|
|data/levels.json/66/first_clear_reward/gold|1950|1006|0.5156887|
|data/levels.json/67/first_clear_reward/gold|1981|1021|0.51519105|
|data/levels.json/68/first_clear_reward/gold|2013|1036|0.51469389|
|data/levels.json/69/first_clear_reward/gold|2044|1051|0.5141972|
|data/levels.json/70/first_clear_reward/gold|2076|1066|0.513701|
|data/levels.json/71/first_clear_reward/gold|2108|1082|0.51320527|
|data/levels.json/72/first_clear_reward/gold|2140|1097|0.51271003|
|data/levels.json/73/first_clear_reward/gold|2172|1113|0.51221526|
|data/levels.json/74/first_clear_reward/gold|2204|1128|0.51172096|
|data/levels.json/75/first_clear_reward/gold|2237|1144|0.51122715|
|data/levels.json/76/first_clear_reward/gold|2269|1159|0.51073381|
|data/levels.json/77/first_clear_reward/gold|2302|1175|0.51024095|
|data/levels.json/78/first_clear_reward/gold|2334|1190|0.50974856|
|data/levels.json/79/first_clear_reward/gold|2367|1205|0.50925665|
|data/levels.json/80/first_clear_reward/gold|2400|1221|0.50876521|
|data/levels.json/81/first_clear_reward/gold|2433|1237|0.50827425|
|data/levels.json/82/first_clear_reward/gold|2466|1252|0.50778376|
|data/levels.json/83/first_clear_reward/gold|2499|1268|0.50729375|
|data/levels.json/84/first_clear_reward/gold|2532|1283|0.5068042|
|data/levels.json/85/first_clear_reward/gold|2566|1299|0.50631513|
|data/levels.json/86/first_clear_reward/gold|2599|1315|0.50582653|
|data/levels.json/87/first_clear_reward/gold|2633|1331|0.50533841|
|data/levels.json/88/first_clear_reward/gold|2667|1346|0.50485075|
|data/levels.json/89/first_clear_reward/gold|2700|1362|0.50436357|
|data/levels.json/90/first_clear_reward/gold|2734|1378|0.50387685|
|data/levels.json/91/first_clear_reward/gold|2769|1394|0.50339061|
|data/levels.json/92/first_clear_reward/gold|2803|1410|0.50290483|
|data/levels.json/93/first_clear_reward/gold|2837|1425|0.50241952|
|data/levels.json/94/first_clear_reward/gold|2871|1441|0.50193468|
|data/levels.json/95/first_clear_reward/gold|2906|1457|0.50145031|
|data/levels.json/96/first_clear_reward/gold|2940|1473|0.50096641|
|data/levels.json/97/first_clear_reward/gold|2975|1489|0.50048297|
|data/levels.json/98/first_clear_reward/gold|3010|1505|0.5|
|data/levels.json/0/reward_gold_mult|0.56|0.43173198|0.77094996|
|data/levels.json/1/reward_gold_mult|0.55|0.42221544|0.76766443|
|data/levels.json/2/reward_gold_mult|0.55|0.4204161|0.7643929|
|data/levels.json/3/reward_gold_mult|0.55|0.41862443|0.76113532|
|data/levels.json/4/reward_gold_mult|0.54|0.40926148|0.75789162|
|data/levels.json/5/reward_gold_mult|0.54|0.40751734|0.75466174|
|data/levels.json/6/reward_gold_mult|0.53|0.39826618|0.75144563|
|data/levels.json/7/reward_gold_mult|0.53|0.39656891|0.74824323|
|data/levels.json/8/reward_gold_mult|0.53|0.39487887|0.74505447|
|data/levels.json/9/reward_gold_mult|0.52|0.38577723|0.7418793|
|data/levels.json/10/reward_gold_mult|0.52|0.38413318|0.73871766|
|data/levels.json/11/reward_gold_mult|0.52|0.38249614|0.7355695|
|data/levels.json/12/reward_gold_mult|0.51|0.37354172|0.73243475|
|data/levels.json/13/reward_gold_mult|0.51|0.37194981|0.72931336|
|data/levels.json/14/reward_gold_mult|0.51|0.37036469|0.72620527|
|data/levels.json/15/reward_gold_mult|0.5|0.36155522|0.72311043|
|data/levels.json/16/reward_gold_mult|0.5|0.36001439|0.72002878|
|data/levels.json/17/reward_gold_mult|0.5|0.35848013|0.71696027|
|data/levels.json/18/reward_gold_mult|0.49|0.34981336|0.71390482|
|data/levels.json/19/reward_gold_mult|0.49|0.34832258|0.7108624|
|data/levels.json/20/reward_gold_mult|0.48|0.33975982|0.70783295|
|data/levels.json/21/reward_gold_mult|0.48|0.33831187|0.70481641|
|data/levels.json/22/reward_gold_mult|0.48|0.3368701|0.70181272|
|data/levels.json/23/reward_gold_mult|0.47|0.32844626|0.69882183|
|data/levels.json/24/reward_gold_mult|0.47|0.32704653|0.69584369|
|data/levels.json/25/reward_gold_mult|0.47|0.32565277|0.69287824|
|data/levels.json/26/reward_gold_mult|0.46|0.3173657|0.68992543|
|data/levels.json/27/reward_gold_mult|0.46|0.31601319|0.6869852|
|data/levels.json/28/reward_gold_mult|0.46|0.31466645|0.6840575|
|data/levels.json/29/reward_gold_mult|0.45|0.30651403|0.68114228|
|data/levels.json/30/reward_gold_mult|0.45|0.30520777|0.67823948|
|data/levels.json/31/reward_gold_mult|0.44|0.29715359|0.67534906|
|data/levels.json/32/reward_gold_mult|0.44|0.29588722|0.67247095|
|data/levels.json/33/reward_gold_mult|0.44|0.29462625|0.66960511|
|data/levels.json/34/reward_gold_mult|0.43|0.28670313|0.66675148|
|data/levels.json/35/reward_gold_mult|0.43|0.2854813|0.66391001|
|data/levels.json/36/reward_gold_mult|0.43|0.28426468|0.66108065|
|data/levels.json/37/reward_gold_mult|0.42|0.27647061|0.65826335|
|data/levels.json/38/reward_gold_mult|0.42|0.27529238|0.65545805|
|data/levels.json/39/reward_gold_mult|0.42|0.27411918|0.65266471|
|data/levels.json/40/reward_gold_mult|0.41|0.26645214|0.64988328|
|data/levels.json/41/reward_gold_mult|0.41|0.26531662|0.6471137|
|data/levels.json/42/reward_gold_mult|0.41|0.26418593|0.64435592|
|data/levels.json/43/reward_gold_mult|0.4|0.25664396|0.64160989|
|data/levels.json/44/reward_gold_mult|0.4|0.25555023|0.63887557|
|data/levels.json/45/reward_gold_mult|0.39|0.24809963|0.6361529|
|data/levels.json/46/reward_gold_mult|0.39|0.24704231|0.63344183|
|data/levels.json/47/reward_gold_mult|0.39|0.2459895|0.63074231|
|data/levels.json/48/reward_gold_mult|0.38|0.23866064|0.62805431|
|data/levels.json/49/reward_gold_mult|0.38|0.23764355|0.62537775|
|data/levels.json/50/reward_gold_mult|0.38|0.23663079|0.6227126|
|data/levels.json/51/reward_gold_mult|0.37|0.22942176|0.62005881|
|data/levels.json/52/reward_gold_mult|0.37|0.22844404|0.61741633|
|data/levels.json/53/reward_gold_mult|0.37|0.22747049|0.61478511|
|data/levels.json/54/reward_gold_mult|0.36|0.22037944|0.61216511|
|data/levels.json/55/reward_gold_mult|0.36|0.21944026|0.60955627|
|data/levels.json/56/reward_gold_mult|0.35|0.21243549|0.60695855|
|data/levels.json/57/reward_gold_mult|0.35|0.21153016|0.6043719|
|data/levels.json/58/reward_gold_mult|0.35|0.21062869|0.60179627|
|data/levels.json/59/reward_gold_mult|0.34|0.20373875|0.59923162|
|data/levels.json/60/reward_gold_mult|0.34|0.20287048|0.5966779|
|data/levels.json/61/reward_gold_mult|0.34|0.20200592|0.59413506|
|data/levels.json/62/reward_gold_mult|0.33|0.19522901|0.59160305|
|data/levels.json/63/reward_gold_mult|0.33|0.19439701|0.58908184|
|data/levels.json/64/reward_gold_mult|0.33|0.19356855|0.58657138|
|data/levels.json/65/reward_gold_mult|0.32|0.18690291|0.58407161|
|data/levels.json/66/reward_gold_mult|0.32|0.1861064|0.58158249|
|data/levels.json/67/reward_gold_mult|0.32|0.18531328|0.57910399|
|data/levels.json/68/reward_gold_mult|0.31|0.17875717|0.57663604|
|data/levels.json/69/reward_gold_mult|0.31|0.17799537|0.57417861|
|data/levels.json/70/reward_gold_mult|0.3|0.1715195|0.57173166|
|data/levels.json/71/reward_gold_mult|0.3|0.17078854|0.56929513|
|data/levels.json/72/reward_gold_mult|0.3|0.1700607|0.56686899|
|data/levels.json/73/reward_gold_mult|0.29|0.16369142|0.56445319|
|data/levels.json/74/reward_gold_mult|0.29|0.16299383|0.56204768|
|data/levels.json/75/reward_gold_mult|0.29|0.1622992|0.55965242|
|data/levels.json/76/reward_gold_mult|0.28|0.15603487|0.55726738|
|data/levels.json/77/reward_gold_mult|0.28|0.1553699|0.55489249|
|data/levels.json/78/reward_gold_mult|0.28|0.15470776|0.55252773|
|data/levels.json/79/reward_gold_mult|0.27|0.14854672|0.55017304|
|data/levels.json/80/reward_gold_mult|0.27|0.14791367|0.54782839|
|data/levels.json/81/reward_gold_mult|0.26|0.14182837|0.54549373|
|data/levels.json/82/reward_gold_mult|0.26|0.14122395|0.54316902|
|data/levels.json/83/reward_gold_mult|0.26|0.1406221|0.54085422|
|data/levels.json/84/reward_gold_mult|0.26|0.14002281|0.53854928|
|data/levels.json/85/reward_gold_mult|0.26|0.13942608|0.53625417|
|data/levels.json/86/reward_gold_mult|0.26|0.1388319|0.53396884|
|data/levels.json/87/reward_gold_mult|0.26|0.13824024|0.53169324|
|data/levels.json/88/reward_gold_mult|0.26|0.13765111|0.52942735|
|data/levels.json/89/reward_gold_mult|0.26|0.13706449|0.52717111|
|data/levels.json/90/reward_gold_mult|0.26|0.13648037|0.52492448|
|data/levels.json/91/reward_gold_mult|0.26|0.13589873|0.52268743|
|data/levels.json/92/reward_gold_mult|0.26|0.13531958|0.52045992|
|data/levels.json/93/reward_gold_mult|0.26|0.13474289|0.51824189|
|data/levels.json/94/reward_gold_mult|0.26|0.13416866|0.51603332|
|data/levels.json/95/reward_gold_mult|0.26|0.13359688|0.51383416|
|data/levels.json/96/reward_gold_mult|0.26|0.13302754|0.51164438|
|data/levels.json/97/reward_gold_mult|0.26|0.13246062|0.50946392|
|data/levels.json/98/reward_gold_mult|0.26|0.13189612|0.50729276|
|data/weapons.json/weapon_flamethrower/unlock_cost_star|8|10|1.190349|
|data/weapons.json/weapon_cryocannon/unlock_cost_star|8|10|1.190349|
|data/weapons.json/weapon_teslacoil/unlock_cost_star|10|12|1.190349|
|data/weapons.json/weapon_venomlauncher/unlock_cost_star|8|10|1.190349|
|data/weapons.json/weapon_railgun/unlock_cost_star|14|17|1.190349|
|data/weapons.json/weapon_scattergun/unlock_cost_star|9|11|1.190349|
|data/weapons.json/weapon_plasmacannon/unlock_cost_star|16|19|1.190349|
|data/armors.json/armor_kevlar/unlock_cost_star|8|10|1.190349|
|data/armors.json/armor_thermal/unlock_cost_star|8|10|1.190349|
|data/armors.json/armor_cryo/unlock_cost_star|9|11|1.190349|
|data/armors.json/armor_faraday/unlock_cost_star|10|12|1.190349|
|data/armors.json/armor_hazmat/unlock_cost_star|11|13|1.190349|
|data/armors.json/armor_reactive/unlock_cost_star|14|17|1.190349|
|data/chips.json/chip_attack/unlock_cost_star|8|10|1.190349|
|data/chips.json/chip_haste/unlock_cost_star|8|10|1.190349|
|data/chips.json/chip_crit/unlock_cost_star|9|11|1.190349|
|data/chips.json/chip_pierce/unlock_cost_star|11|13|1.190349|
|data/chips.json/chip_health/unlock_cost_star|9|11|1.190349|
|data/chips.json/chip_guardian/unlock_cost_star|10|12|1.190349|
|data/chips.json/chip_greed/unlock_cost_star|11|13|1.190349|
|data/chips.json/chip_element/unlock_cost_star|14|17|1.190349|
|data/pets.json/pet_turret_drone/unlock_cost_star|8|10|1.190349|
|data/pets.json/pet_fire_imp/unlock_cost_star|9|11|1.190349|
|data/pets.json/pet_frost_wisp/unlock_cost_star|10|12|1.190349|
|data/pets.json/pet_volt_orb/unlock_cost_star|11|13|1.190349|
|data/pets.json/pet_medic_drone/unlock_cost_star|13|15|1.190349|
|data/pets.json/pet_collector/unlock_cost_star|14|17|1.190349|
|data/economy.json/skill_base_xp_costs/0|350|602|1.721084|
|data/economy.json/skill_base_xp_costs/1|900|1515|1.6829364|
|data/economy.json/skill_base_xp_costs/2|2000|2950|1.4750964|
|data/economy.json/skill_base_xp_costs/3|4000|5737|1.4341556|
|data/economy.json/skill_base_xp_costs/4|8500|11011|1.2954105|
|data/economy.json/sig_skill_xp_costs/0|450|401|0.89177046|
|data/economy.json/sig_skill_xp_costs/1|1200|1084|0.90369351|
|data/economy.json/sig_skill_xp_costs/2|2700|2549|0.94390747|
|data/economy.json/sig_skill_xp_costs/3|5400|6917|1.2808747|
|data/economy.json/sig_skill_xp_costs/4|11000|14565|1.3240798|
|data/weapons.json/weapon_autocannon/cost_base_gold|100|187|1.8746604|
|data/weapons.json/weapon_flamethrower/cost_base_gold|180|246|1.3694003|
|data/weapons.json/weapon_cryocannon/cost_base_gold|180|131|0.72705698|
|data/weapons.json/weapon_teslacoil/cost_base_gold|240|480|2|
|data/weapons.json/weapon_venomlauncher/cost_base_gold|240|144|0.59985771|
|data/weapons.json/weapon_railgun/cost_base_gold|320|377|1.1770028|
|data/weapons.json/weapon_scattergun/cost_base_gold|180|159|0.88096926|
|data/weapons.json/weapon_plasmacannon/cost_base_gold|320|396|1.2374981|

|关卡|rec|E|旧P|新P|新R|新P/E|下限|上限|达标|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
|001|50|65|65|65|1.3000|1.0000|48|71|True|
|002|50|65|69|66|1.3200|1.0154|48|71|True|
|003|50|65|73|70|1.4000|1.0769|48|71|True|
|004|64|65|74|73|1.1406|1.1231|61|71|False|
|005|76|76|81|77|1.0132|1.0132|76|83|True|
|006|53|76|82|80|1.5094|1.0526|51|83|True|
|007|53|76|89|86|1.6226|1.1316|53|83|False|
|008|79|79|96|86|1.0886|1.0886|79|86|True|
|009|79|79|106|93|1.1772|1.1772|79|86|False|
|010|87|87|112|101|1.1609|1.1609|87|95|False|
|011|99|99|116|102|1.0303|1.0303|95|108|True|
|012|108|108|122|104|0.9630|0.9630|103|118|True|
|013|131|131|131|142|1.0840|1.0840|125|144|True|
|014|138|138|141|150|1.0870|1.0870|132|151|True|
|015|147|147|151|152|1.0340|1.0340|147|161|True|
|016|98|147|152|152|1.5510|1.0340|94|161|True|
|017|165|165|166|191|1.1576|1.1576|0|181|False|
|018|185|185|207|197|1.0649|1.0649|185|203|True|
|019|188|188|210|197|1.0479|1.0479|188|206|True|
|020|291|291|291|294|1.0103|1.0103|0|320|True|
|021|164|291|323|297|1.8110|1.0206|156|320|True|
|022|183|291|339|297|1.6230|1.0206|174|320|True|
|023|186|291|355|297|1.5968|1.0206|177|320|True|
|024|201|291|374|297|1.4776|1.0206|191|320|True|
|025|260|291|410|300|1.1538|1.0309|260|320|True|
|026|226|291|410|300|1.3274|1.0309|215|320|True|
|027|195|291|410|300|1.5385|1.0309|195|320|True|
|028|231|291|474|321|1.3896|1.1031|231|320|False|
|029|206|291|509|334|1.6214|1.1478|206|320|False|
|030|332|332|515|334|1.0060|1.0060|332|365|True|
|031|159|332|522|334|2.1006|1.0060|152|365|True|
|032|245|332|530|350|1.4286|1.0542|233|365|True|
|033|228|332|573|350|1.5351|1.0542|217|365|True|
|034|330|332|573|350|1.0606|1.0542|314|365|True|
|035|219|332|648|350|1.5982|1.0542|219|365|True|
|036|225|332|679|362|1.6089|1.0904|214|365|True|
|037|232|332|685|379|1.6336|1.1416|232|365|False|
|038|484|484|710|498|1.0289|1.0289|484|532|True|
|039|533|533|849|534|1.0019|1.0019|533|586|True|
|040|574|574|849|575|1.0017|1.0017|574|631|True|
|041|236|574|880|575|2.4364|1.0017|225|631|True|
|042|375|574|942|577|1.5387|1.0052|357|631|True|
|043|587|587|951|582|0.9915|0.9915|558|645|True|
|044|757|757|957|742|0.9802|0.9802|720|832|True|
|045|655|757|963|798|1.2183|1.0542|655|832|True|
|046|600|757|972|842|1.4033|1.1123|570|832|False|
|047|670|757|983|871|1.3000|1.1506|670|832|False|
|048|663|757|983|903|1.3620|1.1929|663|832|False|
|049|658|757|1008|950|1.4438|1.2550|658|832|False|
|050|868|868|1068|956|1.1014|1.1014|868|954|False|
|051|431|868|1185|956|2.2181|1.1014|410|954|False|
|052|349|868|1185|956|2.7393|1.1014|332|954|False|
|053|427|868|1185|966|2.2623|1.1129|406|954|False|
|054|359|868|1185|968|2.6964|1.1152|342|954|False|
|055|950|950|1185|1003|1.0558|1.0558|950|1045|True|
|056|354|950|1237|1003|2.8333|1.0558|337|1045|True|
|057|990|990|1237|1003|1.0131|1.0131|990|1089|True|
|058|503|990|1284|1003|1.9940|1.0131|503|1089|True|
|059|562|990|1284|1003|1.7847|1.0131|562|1089|True|
|060|990|990|1300|1071|1.0818|1.0818|990|1089|True|
|061|990|990|1491|1079|1.0899|1.0899|941|1089|True|
|062|250|990|1577|1079|4.3160|1.0899|238|1089|True|
|063|576|990|1763|1079|1.8733|1.0899|548|1089|True|
|064|955|990|1763|1207|1.2639|1.2192|908|1089|False|
|065|1014|1014|1813|1207|1.1903|1.1903|1014|1115|False|
|066|1184|1184|1813|1237|1.0448|1.0448|1125|1302|True|
|067|955|1184|1813|1312|1.3738|1.1081|955|1302|False|
|068|1042|1184|1814|1312|1.2591|1.1081|1042|1302|False|
|069|978|1184|2043|1385|1.4162|1.1698|978|1302|False|
|070|1286|1286|2043|1385|1.0770|1.0770|1286|1414|True|
|071|1146|1286|2202|1385|1.2086|1.0770|1089|1414|True|
|072|1576|1576|2308|1537|0.9753|0.9753|1498|1733|True|
|073|818|1576|2308|1537|1.8790|0.9753|778|1733|True|
|074|2034|2034|2429|2204|1.0836|1.0836|0|2237|True|
|075|1841|2034|2733|2204|1.1972|1.0836|1841|2237|True|
|076|2758|2758|2989|2684|0.9732|0.9732|0|3033|True|
|077|1652|2758|3160|2684|1.6247|0.9732|1652|3033|True|
|078|2226|2758|3160|2684|1.2058|0.9732|2226|3033|True|
|079|2030|2758|3160|2684|1.3222|0.9732|2030|3033|True|
|080|2067|2758|3220|2684|1.2985|0.9732|2067|3033|True|
|081|1096|2758|3270|2684|2.4489|0.9732|1042|3033|True|
|082|1762|2758|3270|2684|1.5233|0.9732|1674|3033|True|
|083|1815|2758|3270|2684|1.4788|0.9732|1725|3033|True|
|084|1265|2758|3271|2684|2.1217|0.9732|1202|3033|True|
|085|2204|2758|3271|2684|1.2178|0.9732|2204|3033|True|
|086|1855|2758|3538|2684|1.4469|0.9732|1763|3033|True|
|087|1857|2758|3639|2684|1.4453|0.9732|1857|3033|True|
|088|1857|2758|3700|2684|1.4453|0.9732|1857|3033|True|
|089|1994|2758|3974|2996|1.5025|1.0863|1994|3033|True|
|090|2751|2758|3994|2996|1.0891|1.0863|2751|3033|True|
|091|1234|2758|4401|3035|2.4595|1.1004|1173|3033|False|
|092|1862|2758|4401|3035|1.6300|1.1004|1769|3033|False|
|093|2266|2758|4404|3035|1.3394|1.1004|2153|3033|False|
|094|1830|2758|4406|3035|1.6585|1.1004|1739|3033|False|
|095|3370|3370|4415|3553|1.0543|1.0543|0|3707|True|
|096|2429|3370|4415|3553|1.4627|1.0543|2308|3707|True|
|097|1863|3370|4415|3553|1.9071|1.0543|1863|3707|True|
|098|2720|3370|5163|3553|1.3062|1.0543|2720|3707|True|
|099|3094|3370|5283|3553|1.1484|1.0543|3094|3707|True|

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

首次R<0.95：None；G1走廊不满足关数：26/99。

包络目标Σ|P−E|/E：6.586357。

回刷总数：39（非门13，门26）；各章非门：{'1': 2, '2': 3, '3': 0, '4': 3, '5': 5, '6': 0, '7': 0, '8': 0, '9': 0, '10': 0}。
门关：[17, 20, 74, 76, 95]；预算后新增门：[17, 74]；未刷够门：[]；非门失败：[4, 7, 9, 10, 28, 29, 37, 46, 47, 48, 49, 50, 51, 52, 53, 54, 64, 65, 67, 68, 69, 91, 92, 93, 94]。

|回刷位置|路线(挑战/普通)|入场P|回刷后P|次数|非门章累计|刷够|八墙关|门高度/路线注记|
|---|---|---:|---:|---:|---:|---|---|---|
|005|004挑, 003挑|73|77|2|2|True|False|非门|
|013|012挑, 011挑, 010挑|113|142|3|3|True|False|非门|
|017|016挑, 015挑, 014挑, 013挑, 009挑, 008挑|154|191|6|3|True|True|6 / 仅挑战 / challenge-first route still exceeds chapter remaining budget|
|020|019挑, 018挑, 017挑, 007挑, 006挑, 005挑|199|294|6|3|True|True|6 / 仅挑战 / Owner fixed gate|
|038|037挑, 036挑, 035挑|411|498|3|3|True|False|非门|
|044|043挑, 042挑, 041挑, 040挑, 039挑|584|742|5|5|True|True|非门|
|074|073挑, 072挑, 071挑, 070挑, 069挑, 068挑, 067挑|1643|2204|7|0|True|False|7 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|076|075挑, 074挑, 066挑, 065挑, 064挑, 063挑, 062挑|2204|2684|7|0|True|True|7 / 可付费（未做运行时验证） / Owner fixed gate|

## 门关高度（含无需回刷的固定门）

|门|高度|已刷够|路径|原因|
|---|---:|---|---|---|
|017|6|True|仅挑战|challenge-first route still exceeds chapter remaining budget|
|020|6|True|仅挑战|Owner fixed gate|
|074|7|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|076|7|True|可付费（未做运行时验证）|Owner fixed gate|
|095|0|True|可付费（未做运行时验证）|Owner fixed gate|

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|当关/章累计回刷|
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
|001|0|65|50|1.3000|65|1.0000|307|weapon_autocannon 1→2|0/0|
|002|307|66|50|1.3200|65|1.0154|490|vanguard 1→2; weapon_autocannon 2→3; skill_multishot 0→1|0/0|
|003|797|70|50|1.4000|65|1.0769|567|vanguard 2→3; weapon_autocannon 3→4; signature 0→1|0/0|
|004|1364|73|64|1.1406|65|1.1231|667|weapon_cryocannon; weapon_cryocannon 1→4|0/0|
|005|3068|77|76|1.0132|76|1.0132|698|armor_kevlar; weapon_autocannon 5→6|2/2|
|006|3766|80|53|1.5094|76|1.0526|831|weapon_autocannon 6→7; skill_barrier 0→1|0/2|
|007|4597|86|53|1.6226|76|1.1316|861|armor_kevlar 1→3; weapon_cryocannon 4→5; skill_salvo 0→1|0/2|
|008|5458|86|79|1.0886|79|1.0886|1069|chip_attack; chip_attack 1→3; weapon_autocannon 7→8; skill_charge_shot 0→1|0/2|
|009|6527|93|79|1.1772|79|1.1772|830|chip_attack 3→4; vanguard 4→5; skill_slow_field 0→1|0/2|
|010|7357|101|87|1.1609|87|1.1609|845|armor_kevlar 3→4; weapon_cryocannon 5→6|0/2|
|011|8202|102|99|1.0303|99|1.0303|1227|chip_attack 4→5; weapon_autocannon 8→9; skill_split_shot 0→1|0/0|
|012|9429|104|108|0.9630|108|0.9630|1313|weapon_scattergun; weapon_scattergun 1→5; skill_critical 0→1|0/0|
|013|13530|142|131|1.0840|131|1.0840|1508|armor_kevlar 4→5; pet_turret_drone 2→3; weapon_scattergun 8→9|3/3|
|014|15038|150|138|1.0870|138|1.0870|1470|chip_attack 5→6; weapon_scattergun 9→10; skill_multishot 1→2|0/3|
|015|16508|152|147|1.0340|147|1.0340|924|pet_turret_drone 3→4; weapon_cryocannon 6→7|0/3|
|016|17432|152|98|1.5510|147|1.0340|1884|vanguard 6→7; weapon_scattergun 10→11; skill_pierce 1→2|0/3|
|017|25684|191|165|1.1576|165|1.1576|1950|chip_attack 6→7; weapon_scattergun 13→14|6/3|
|018|27634|197|185|1.0649|185|1.0649|1483|weapon_railgun 4→5; skill_salvo 1→2|0/3|
|019|29117|197|188|1.0479|188|1.0479|2031|weapon_cryocannon 8→9; weapon_scattergun 14→15|0/3|
|020|37723|294|291|1.0103|291|1.0103|2135|weapon_scattergun 17→18; skill_split_shot 1→2|6/3|
|021|39858|297|164|1.8110|291|1.0206|1988|weapon_venomlauncher; weapon_venomlauncher 1→7; skill_critical 1→2|0/0|
|022|41846|297|183|1.6230|291|1.0206|2081|weapon_autocannon 9→10; weapon_venomlauncher 7→8|0/0|
|023|43927|297|186|1.5968|291|1.0206|2364|weapon_railgun 5→6; weapon_venomlauncher 8→9; skill_ricochet 1→2|0/0|
|024|46291|297|201|1.4776|291|1.0206|2207|weapon_scattergun 18→19|0/0|
|025|48498|300|260|1.1538|291|1.0309|1542|weapon_railgun 6→7|0/0|
|026|50040|300|226|1.3274|291|1.0309|2650|weapon_autocannon 10→11; weapon_venomlauncher 9→10|0/0|
|027|52690|300|195|1.5385|291|1.0309|2425|chip_attack 8→9; weapon_scattergun 19→20; skill_multishot 2→3|0/0|
|028|55115|321|231|1.3896|291|1.1031|2567|weapon_scattergun 20→21|0/0|
|029|57682|334|206|1.6214|291|1.1478|2709|weapon_railgun 7→8; weapon_venomlauncher 10→11|0/0|
|030|60391|334|332|1.0060|332|1.0060|2164|weapon_railgun 8→9|0/0|
|031|62555|334|159|2.1006|332|1.0060|3115|weapon_flamethrower; weapon_flamethrower 1→3; weapon_scattergun 21→22; skill_pierce 2→3|0/0|
|032|65670|350|245|1.4286|332|1.0542|2877|weapon_plasmacannon; weapon_flamethrower 3→4; weapon_plasmacannon 1→4|0/0|
|033|68547|350|228|1.5351|332|1.0542|2519|weapon_flamethrower 4→6; weapon_plasmacannon 4→5|0/0|
|034|71066|350|330|1.0606|332|1.0542|3146|weapon_flamethrower 6→7; weapon_plasmacannon 5→6; skill_homing 2→3|0/0|
|035|74212|350|219|1.5982|332|1.0542|2302|weapon_scattergun 22→23|0/0|
|036|76514|362|225|1.6089|332|1.0904|3151|weapon_cryocannon 9→10; weapon_scattergun 23→24|0/0|
|037|79665|379|232|1.6336|332|1.1416|3546|weapon_flamethrower 7→8; weapon_plasmacannon 6→7; signature 2→3|0/0|
|038|90568|498|484|1.0289|484|1.0289|3785|vanguard 9→10; weapon_scattergun 25→26|3/3|
|039|94353|534|533|1.0019|533|1.0019|3285|armor_kevlar 8→9; weapon_scattergun 26→27|0/3|
|040|97638|575|574|1.0017|574|1.0017|4307|weapon_flamethrower 9→10; weapon_plasmacannon 8→9; skill_salvo 2→3|0/3|
|041|101945|575|236|2.4364|574|1.0017|4152|weapon_teslacoil; weapon_scattergun 27→28; weapon_teslacoil 1→3|0/0|
|042|106097|577|375|1.5387|574|1.0052|3788|weapon_cryocannon 10→11; weapon_teslacoil 3→5; skill_charge_shot 2→3|0/0|
|043|109885|582|587|0.9915|587|0.9915|4390|weapon_autocannon 11→12; weapon_scattergun 28→29|0/0|
|044|131099|742|757|0.9802|757|0.9802|4253|pet_turret_drone 6→7; weapon_scattergun 33→34|5/5|
|045|135352|798|655|1.2183|757|1.0542|4255|weapon_scattergun 34→35; skill_critical 2→3|0/5|
|046|139607|842|600|1.4033|757|1.1123|3710|weapon_scattergun 35→36|0/5|
|047|143317|871|670|1.3000|757|1.1506|3982|weapon_scattergun 36→37|0/5|
|048|147299|903|663|1.3620|757|1.1929|4692|chip_attack 10→11; weapon_scattergun 37→38; skill_ricochet 2→3|0/5|
|049|151991|950|658|1.4438|757|1.2550|4585|weapon_scattergun 38→39|0/5|
|050|156576|956|868|1.1014|868|1.1014|3435|weapon_autocannon 12→13; weapon_teslacoil 6→7|0/5|
|051|160011|956|431|2.2181|868|1.1014|1417|weapon_cryocannon 11→12|0/0|
|052|161428|956|349|2.7393|868|1.1014|1621|weapon_flamethrower 10→11; skill_multishot 3→4|0/0|
|053|163049|966|427|2.2623|868|1.1129|1565|pet_turret_drone 7→8; weapon_venomlauncher 11→12|0/0|
|054|164614|968|359|2.6964|868|1.1152|1587|vanguard 11→12|0/0|
|055|166201|1003|950|1.0558|950|1.0558|1589|weapon_flamethrower 11→12|0/0|
|056|167790|1003|354|2.8333|950|1.0558|1486|weapon_cryocannon 12→13; skill_pierce 3→4|0/0|
|057|169276|1003|990|1.0131|990|1.0131|2789|weapon_teslacoil 7→8|0/0|
|058|172065|1003|503|1.9940|990|1.0131|1719|weapon_autocannon 13→14|0/0|
|059|173784|1003|562|1.7847|990|1.0131|1674|armor_kevlar 9→10; weapon_venomlauncher 12→13; skill_homing 3→4|0/0|
|060|175458|1071|990|1.0818|990|1.0818|3747|chip_attack 11→12; weapon_teslacoil 8→9|0/0|
|061|179205|1079|990|1.0899|990|1.0899|2112|weapon_railgun 9→10|0/0|
|062|181317|1079|250|4.3160|990|1.0899|2179|weapon_flamethrower 12→13|0/0|
|063|183496|1079|576|1.8733|990|1.0899|1975|weapon_autocannon 14→15; skill_barrier 3→4|0/0|
|064|185471|1207|955|1.2639|990|1.2192|1982|armor_kevlar 10→11; weapon_cryocannon 13→14|0/0|
|065|187453|1207|1014|1.1903|1014|1.1903|2351|chip_attack 12→13; weapon_venomlauncher 13→14|0/0|
|066|189804|1237|1184|1.0448|1184|1.0448|1911|pet_turret_drone 8→9; vanguard 12→13; skill_salvo 3→4|0/0|
|067|191715|1312|955|1.3738|1184|1.1081|2611|weapon_plasmacannon 9→10|0/0|
|068|194326|1312|1042|1.2591|1184|1.1081|2377|weapon_flamethrower 13→14; skill_charge_shot 3→4|0/0|
|069|196703|1385|978|1.4162|1184|1.1698|2482|weapon_autocannon 15→16|0/0|
|070|199185|1385|1286|1.0770|1286|1.0770|2345|weapon_railgun 10→11|0/0|
|071|201530|1385|1146|1.2086|1286|1.0770|2096|weapon_autocannon 16→17; signature 3→4|0/0|
|072|203626|1537|1576|0.9753|1576|0.9753|1950|weapon_cryocannon 14→15|0/0|
|073|205576|1537|818|1.8790|1576|0.9753|2164|vanguard 13→14; weapon_venomlauncher 14→15|0/0|
|074|216406|2204|2034|1.0836|2034|1.0836|2625|weapon_plasmacannon 10→11|7/0|
|075|219031|2204|1841|1.1972|2034|1.0836|2746|weapon_flamethrower 14→15; skill_ricochet 3→4|0/0|
|076|230504|2684|2758|0.9732|2758|0.9732|2342|weapon_autocannon 17→18|7/0|
|077|232846|2684|1652|1.6247|2758|0.9732|2695|weapon_railgun 11→12|0/0|
|078|235541|2684|2226|1.2058|2758|0.9732|2455|weapon_autocannon 18→19; skill_pierce 4→5|0/0|
|079|237996|2684|2030|1.3222|2758|0.9732|2706|weapon_flamethrower 15→16|0/0|
|080|240702|2684|2067|1.2985|2758|0.9732|2979|weapon_flamethrower 16→17|0/0|
|081|243681|2684|1096|2.4489|2758|0.9732|2277|weapon_autocannon 19→20|0/0|
|082|245958|2684|1762|1.5233|2758|0.9732|2269|weapon_cryocannon 17→18; skill_homing 4→5|0/0|
|083|248227|2684|1815|1.4788|2758|0.9732|2707|weapon_teslacoil 9→10|0/0|
|084|250934|2684|1265|2.1217|2758|0.9732|2336|weapon_venomlauncher 17→18|0/0|
|085|253270|2684|2204|1.2178|2758|0.9732|3273|weapon_teslacoil 10→11|0/0|
|086|256543|2684|1855|1.4469|2758|0.9732|3083|weapon_plasmacannon 11→12; skill_barrier 4→5|0/0|
|087|259626|2684|1857|1.4453|2758|0.9732|2975|weapon_railgun 12→13|0/0|
|088|262601|2684|1857|1.4453|2758|0.9732|2727|chip_attack 16→17; vanguard 16→17|0/0|
|089|265328|2996|1994|1.5025|2758|1.0863|2948|weapon_autocannon 20→21|0/0|
|090|268276|2996|2751|1.0891|2758|1.0863|2468|pet_turret_drone 11→12; weapon_cryocannon 18→19; skill_salvo 4→5|0/0|
|091|270744|3035|1234|2.4595|2758|1.1004|2453|weapon_venomlauncher 18→19|0/0|
|092|273197|3035|1862|1.6300|2758|1.1004|3497|weapon_teslacoil 11→12|0/0|
|093|276694|3035|2266|1.3394|2758|1.1004|2983|weapon_flamethrower 17→18|0/0|
|094|279677|3035|1830|1.6585|2758|1.1004|3261|weapon_plasmacannon 12→13; skill_charge_shot 4→5|0/0|
|095|282938|3553|3370|1.0543|3370|1.0543|3008|weapon_autocannon 21→22|0/0|
|096|285946|3553|2429|1.4627|3370|1.0543|4087|weapon_teslacoil 12→13|0/0|
|097|290033|3553|1863|1.9071|3370|1.0543|3739|weapon_railgun 13→14|0/0|
|098|293772|3553|2720|1.3062|3370|1.0543|3713|weapon_plasmacannon 13→14; skill_slow_field 4→5|0/0|
|099|297485|3553|3094|1.1484|3370|1.0543|3191|weapon_flamethrower 18→19|0/0|
