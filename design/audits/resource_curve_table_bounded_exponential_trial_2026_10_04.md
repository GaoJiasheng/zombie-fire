状态：SEARCH_CANDIDATE_NOT_YET_FEASIBLE；待Fable签字，游戏数据未写入。

# 资源表 C 候选

离线假定3★首通与上一关回刷，每章最多6次；不是新运行时胜率。既有账户策略与P(g)/F(g)冻结。所有因子限定[0.5,2.0]。
优化前：74/99失败，目标25.563564。
优化后：30/99失败，目标9.738043。

缩放系数与逐字段旧/新对照完整列于同名JSON；所有候选仅在内存模拟。

|曲线|缩放系数/形式|
|---|---|
|first_clear_gold|[-0.15080892463020681, 0.14858568453497778]；existing authored per-level values × exp(a+b*(L-1)/98)|
|kill_gold_mult|[-0.49441060413836224, -0.037933825669873356]；existing authored per-level values × exp(a+b*(L-1)/98)|
|free_unlock_star|1.2018777184390894；existing free star tiers × constant|
|skill_base_xp_costs|[-0.019267096598644087, 0.6785795593634736]；existing 5 cost tiers × exp(a+b*(rank-1)/4)|
|sig_skill_xp_costs|[0.3119664030519497, 0.01633982432631914]；existing 5 cost tiers × exp(a+b*(rank-1)/4)|
|weapon_cost.weapon_autocannon|1.4617937428413792；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_flamethrower|1.2069911729971663；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_cryocannon|0.5236139433823451；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_teslacoil|0.9199736349834021；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_venomlauncher|1.7265659403433862；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_railgun|1.3163415504842322；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_scattergun|1.0066770375039833；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_plasmacannon|0.5841795810009244；same existing linear upgrade formula × constant base cost|

|文件/字段|旧值|候选新值|系数|
|---|---:|---:|---:|
|data/levels.json/0/first_clear_reward/gold|119|102|0.86001201|
|data/levels.json/1/first_clear_reward/gold|143|123|0.86131693|
|data/levels.json/2/first_clear_reward/gold|167|144|0.86262383|
|data/levels.json/3/first_clear_reward/gold|192|166|0.86393272|
|data/levels.json/4/first_clear_reward/gold|216|187|0.86524359|
|data/levels.json/5/first_clear_reward/gold|241|209|0.86655645|
|data/levels.json/6/first_clear_reward/gold|266|231|0.8678713|
|data/levels.json/7/first_clear_reward/gold|291|253|0.86918815|
|data/levels.json/8/first_clear_reward/gold|315|274|0.870507|
|data/levels.json/9/first_clear_reward/gold|340|296|0.87182784|
|data/levels.json/10/first_clear_reward/gold|366|320|0.8731507|
|data/levels.json/11/first_clear_reward/gold|391|342|0.87447555|
|data/levels.json/12/first_clear_reward/gold|416|364|0.87580242|
|data/levels.json/13/first_clear_reward/gold|442|388|0.8771313|
|data/levels.json/14/first_clear_reward/gold|467|410|0.8784622|
|data/levels.json/15/first_clear_reward/gold|493|434|0.87979512|
|data/levels.json/16/first_clear_reward/gold|519|457|0.88113006|
|data/levels.json/17/first_clear_reward/gold|545|481|0.88246702|
|data/levels.json/18/first_clear_reward/gold|571|505|0.88380602|
|data/levels.json/19/first_clear_reward/gold|597|528|0.88514704|
|data/levels.json/20/first_clear_reward/gold|623|552|0.8864901|
|data/levels.json/21/first_clear_reward/gold|650|577|0.8878352|
|data/levels.json/22/first_clear_reward/gold|676|601|0.88918234|
|data/levels.json/23/first_clear_reward/gold|703|626|0.89053153|
|data/levels.json/24/first_clear_reward/gold|729|650|0.89188276|
|data/levels.json/25/first_clear_reward/gold|756|675|0.89323604|
|data/levels.json/26/first_clear_reward/gold|783|700|0.89459137|
|data/levels.json/27/first_clear_reward/gold|810|726|0.89594876|
|data/levels.json/28/first_clear_reward/gold|837|751|0.89730821|
|data/levels.json/29/first_clear_reward/gold|864|776|0.89866973|
|data/levels.json/30/first_clear_reward/gold|892|803|0.9000333|
|data/levels.json/31/first_clear_reward/gold|919|828|0.90139895|
|data/levels.json/32/first_clear_reward/gold|947|855|0.90276667|
|data/levels.json/33/first_clear_reward/gold|975|882|0.90413647|
|data/levels.json/34/first_clear_reward/gold|1002|907|0.90550834|
|data/levels.json/35/first_clear_reward/gold|1030|934|0.9068823|
|data/levels.json/36/first_clear_reward/gold|1058|961|0.90825834|
|data/levels.json/37/first_clear_reward/gold|1086|988|0.90963647|
|data/levels.json/38/first_clear_reward/gold|1115|1016|0.91101668|
|data/levels.json/39/first_clear_reward/gold|1143|1043|0.912399|
|data/levels.json/40/first_clear_reward/gold|1171|1070|0.91378341|
|data/levels.json/41/first_clear_reward/gold|1200|1098|0.91516992|
|data/levels.json/42/first_clear_reward/gold|1229|1126|0.91655854|
|data/levels.json/43/first_clear_reward/gold|1257|1154|0.91794926|
|data/levels.json/44/first_clear_reward/gold|1286|1182|0.91934209|
|data/levels.json/45/first_clear_reward/gold|1315|1211|0.92073704|
|data/levels.json/46/first_clear_reward/gold|1344|1239|0.9221341|
|data/levels.json/47/first_clear_reward/gold|1374|1269|0.92353328|
|data/levels.json/48/first_clear_reward/gold|1403|1298|0.92493459|
|data/levels.json/49/first_clear_reward/gold|1432|1327|0.92633802|
|data/levels.json/50/first_clear_reward/gold|1462|1356|0.92774358|
|data/levels.json/51/first_clear_reward/gold|1492|1386|0.92915127|
|data/levels.json/52/first_clear_reward/gold|1521|1415|0.9305611|
|data/levels.json/53/first_clear_reward/gold|1551|1445|0.93197307|
|data/levels.json/54/first_clear_reward/gold|1581|1476|0.93338718|
|data/levels.json/55/first_clear_reward/gold|1611|1506|0.93480344|
|data/levels.json/56/first_clear_reward/gold|1642|1537|0.93622184|
|data/levels.json/57/first_clear_reward/gold|1672|1568|0.9376424|
|data/levels.json/58/first_clear_reward/gold|1702|1598|0.93906511|
|data/levels.json/59/first_clear_reward/gold|1733|1630|0.94048999|
|data/levels.json/60/first_clear_reward/gold|1764|1662|0.94191702|
|data/levels.json/61/first_clear_reward/gold|1794|1692|0.94334622|
|data/levels.json/62/first_clear_reward/gold|1825|1724|0.94477759|
|data/levels.json/63/first_clear_reward/gold|1856|1756|0.94621113|
|data/levels.json/64/first_clear_reward/gold|1887|1788|0.94764684|
|data/levels.json/65/first_clear_reward/gold|1919|1821|0.94908474|
|data/levels.json/66/first_clear_reward/gold|1950|1854|0.95052481|
|data/levels.json/67/first_clear_reward/gold|1981|1886|0.95196707|
|data/levels.json/68/first_clear_reward/gold|2013|1919|0.95341152|
|data/levels.json/69/first_clear_reward/gold|2044|1952|0.95485816|
|data/levels.json/70/first_clear_reward/gold|2076|1985|0.956307|
|data/levels.json/71/first_clear_reward/gold|2108|2019|0.95775803|
|data/levels.json/72/first_clear_reward/gold|2140|2053|0.95921126|
|data/levels.json/73/first_clear_reward/gold|2172|2087|0.9606667|
|data/levels.json/74/first_clear_reward/gold|2204|2121|0.96212435|
|data/levels.json/75/first_clear_reward/gold|2237|2156|0.96358421|
|data/levels.json/76/first_clear_reward/gold|2269|2190|0.96504629|
|data/levels.json/77/first_clear_reward/gold|2302|2225|0.96651058|
|data/levels.json/78/first_clear_reward/gold|2334|2259|0.9679771|
|data/levels.json/79/first_clear_reward/gold|2367|2295|0.96944584|
|data/levels.json/80/first_clear_reward/gold|2400|2330|0.97091681|
|data/levels.json/81/first_clear_reward/gold|2433|2366|0.97239001|
|data/levels.json/82/first_clear_reward/gold|2466|2402|0.97386545|
|data/levels.json/83/first_clear_reward/gold|2499|2437|0.97534312|
|data/levels.json/84/first_clear_reward/gold|2532|2473|0.97682304|
|data/levels.json/85/first_clear_reward/gold|2566|2510|0.97830521|
|data/levels.json/86/first_clear_reward/gold|2599|2546|0.97978962|
|data/levels.json/87/first_clear_reward/gold|2633|2584|0.98127628|
|data/levels.json/88/first_clear_reward/gold|2667|2621|0.9827652|
|data/levels.json/89/first_clear_reward/gold|2700|2657|0.98425638|
|data/levels.json/90/first_clear_reward/gold|2734|2695|0.98574983|
|data/levels.json/91/first_clear_reward/gold|2769|2734|0.98724553|
|data/levels.json/92/first_clear_reward/gold|2803|2771|0.98874351|
|data/levels.json/93/first_clear_reward/gold|2837|2809|0.99024376|
|data/levels.json/94/first_clear_reward/gold|2871|2847|0.99174629|
|data/levels.json/95/first_clear_reward/gold|2906|2886|0.9932511|
|data/levels.json/96/first_clear_reward/gold|2940|2925|0.99475819|
|data/levels.json/97/first_clear_reward/gold|2975|2964|0.99626756|
|data/levels.json/98/first_clear_reward/gold|3010|3003|0.99777923|
|data/levels.json/0/reward_gold_mult|0.56|0.34156096|0.60993029|
|data/levels.json/1/reward_gold_mult|0.55|0.33533184|0.60969425|
|data/levels.json/2/reward_gold_mult|0.55|0.33520206|0.60945829|
|data/levels.json/3/reward_gold_mult|0.55|0.33507234|0.60922243|
|data/levels.json/4/reward_gold_mult|0.54|0.32885279|0.60898666|
|data/levels.json/5/reward_gold_mult|0.54|0.32872553|0.60875097|
|data/levels.json/6/reward_gold_mult|0.53|0.32251315|0.60851539|
|data/levels.json/7/reward_gold_mult|0.53|0.32238834|0.60827989|
|data/levels.json/8/reward_gold_mult|0.53|0.32226357|0.60804448|
|data/levels.json/9/reward_gold_mult|0.52|0.31606076|0.60780916|
|data/levels.json/10/reward_gold_mult|0.52|0.31593845|0.60757394|
|data/levels.json/11/reward_gold_mult|0.52|0.31581618|0.6073388|
|data/levels.json/12/reward_gold_mult|0.51|0.30962292|0.60710376|
|data/levels.json/13/reward_gold_mult|0.51|0.30950309|0.60686881|
|data/levels.json/14/reward_gold_mult|0.51|0.30938331|0.60663395|
|data/levels.json/15/reward_gold_mult|0.5|0.30319959|0.60639918|
|data/levels.json/16/reward_gold_mult|0.5|0.30308225|0.6061645|
|data/levels.json/17/reward_gold_mult|0.5|0.30296495|0.60592991|
|data/levels.json/18/reward_gold_mult|0.49|0.29679075|0.60569541|
|data/levels.json/19/reward_gold_mult|0.49|0.29667589|0.605461|
|data/levels.json/20/reward_gold_mult|0.48|0.29050881|0.60522669|
|data/levels.json/21/reward_gold_mult|0.48|0.29039638|0.60499246|
|data/levels.json/22/reward_gold_mult|0.48|0.290284|0.60475833|
|data/levels.json/23/reward_gold_mult|0.47|0.28412641|0.60452428|
|data/levels.json/24/reward_gold_mult|0.47|0.28401645|0.60429033|
|data/levels.json/25/reward_gold_mult|0.47|0.28390654|0.60405646|
|data/levels.json/26/reward_gold_mult|0.46|0.27775844|0.60382269|
|data/levels.json/27/reward_gold_mult|0.46|0.27765094|0.60358901|
|data/levels.json/28/reward_gold_mult|0.46|0.27754349|0.60335542|
|data/levels.json/29/reward_gold_mult|0.45|0.27140486|0.60312192|
|data/levels.json/30/reward_gold_mult|0.45|0.27129983|0.60288851|
|data/levels.json/31/reward_gold_mult|0.44|0.26516828|0.60265518|
|data/levels.json/32/reward_gold_mult|0.44|0.26506566|0.60242195|
|data/levels.json/33/reward_gold_mult|0.44|0.26496308|0.60218881|
|data/levels.json/34/reward_gold_mult|0.43|0.25884098|0.60195576|
|data/levels.json/35/reward_gold_mult|0.43|0.25874081|0.6017228|
|data/levels.json/36/reward_gold_mult|0.43|0.25864067|0.60148993|
|data/levels.json/37/reward_gold_mult|0.42|0.252528|0.60125715|
|data/levels.json/38/reward_gold_mult|0.42|0.25243028|0.60102446|
|data/levels.json/39/reward_gold_mult|0.42|0.25233258|0.60079187|
|data/levels.json/40/reward_gold_mult|0.41|0.24622934|0.60055936|
|data/levels.json/41/reward_gold_mult|0.41|0.24613404|0.60032694|
|data/levels.json/42/reward_gold_mult|0.41|0.24603879|0.60009461|
|data/levels.json/43/reward_gold_mult|0.4|0.23994495|0.59986237|
|data/levels.json/44/reward_gold_mult|0.4|0.23985209|0.59963022|
|data/levels.json/45/reward_gold_mult|0.39|0.23376528|0.59939816|
|data/levels.json/46/reward_gold_mult|0.39|0.23367481|0.59916619|
|data/levels.json/47/reward_gold_mult|0.39|0.23358438|0.59893431|
|data/levels.json/48/reward_gold_mult|0.38|0.22750696|0.59870252|
|data/levels.json/49/reward_gold_mult|0.38|0.22741891|0.59847082|
|data/levels.json/50/reward_gold_mult|0.38|0.2273309|0.5982392|
|data/levels.json/51/reward_gold_mult|0.37|0.22126284|0.59800768|
|data/levels.json/52/reward_gold_mult|0.37|0.22117721|0.59777625|
|data/levels.json/53/reward_gold_mult|0.37|0.22109162|0.59754491|
|data/levels.json/54/reward_gold_mult|0.36|0.21503292|0.59731366|
|data/levels.json/55/reward_gold_mult|0.36|0.2149497|0.59708249|
|data/levels.json/56/reward_gold_mult|0.35|0.208898|0.59685142|
|data/levels.json/57/reward_gold_mult|0.35|0.20881715|0.59662043|
|data/levels.json/58/reward_gold_mult|0.35|0.20873634|0.59638954|
|data/levels.json/59/reward_gold_mult|0.34|0.20269397|0.59615873|
|data/levels.json/60/reward_gold_mult|0.34|0.20261553|0.59592802|
|data/levels.json/61/reward_gold_mult|0.34|0.20253711|0.59569739|
|data/levels.json/62/reward_gold_mult|0.33|0.19650406|0.59546685|
|data/levels.json/63/reward_gold_mult|0.33|0.19642801|0.5952364|
|data/levels.json/64/reward_gold_mult|0.33|0.19635199|0.59500604|
|data/levels.json/65/reward_gold_mult|0.32|0.19032825|0.59477577|
|data/levels.json/66/reward_gold_mult|0.32|0.19025459|0.59454559|
|data/levels.json/67/reward_gold_mult|0.32|0.19018096|0.5943155|
|data/levels.json/68/reward_gold_mult|0.31|0.1841665|0.5940855|
|data/levels.json/69/reward_gold_mult|0.31|0.18409523|0.59385558|
|data/levels.json/70/reward_gold_mult|0.3|0.17808773|0.59362576|
|data/levels.json/71/reward_gold_mult|0.3|0.17801881|0.59339602|
|data/levels.json/72/reward_gold_mult|0.3|0.17794991|0.59316638|
|data/levels.json/73/reward_gold_mult|0.29|0.17195168|0.59293682|
|data/levels.json/74/reward_gold_mult|0.29|0.17188513|0.59270735|
|data/levels.json/75/reward_gold_mult|0.29|0.17181861|0.59247797|
|data/levels.json/76/reward_gold_mult|0.28|0.16582963|0.59224868|
|data/levels.json/77/reward_gold_mult|0.28|0.16576545|0.59201947|
|data/levels.json/78/reward_gold_mult|0.28|0.1657013|0.59179036|
|data/levels.json/79/reward_gold_mult|0.27|0.15972156|0.59156133|
|data/levels.json/80/reward_gold_mult|0.27|0.15965975|0.59133239|
|data/levels.json/81/reward_gold_mult|0.26|0.15368692|0.59110355|
|data/levels.json/82/reward_gold_mult|0.26|0.15362744|0.59087479|
|data/levels.json/83/reward_gold_mult|0.26|0.15356799|0.59064611|
|data/levels.json/84/reward_gold_mult|0.26|0.15350856|0.59041753|
|data/levels.json/85/reward_gold_mult|0.26|0.15344915|0.59018904|
|data/levels.json/86/reward_gold_mult|0.26|0.15338976|0.58996063|
|data/levels.json/87/reward_gold_mult|0.26|0.1533304|0.58973231|
|data/levels.json/88/reward_gold_mult|0.26|0.15327106|0.58950408|
|data/levels.json/89/reward_gold_mult|0.26|0.15321175|0.58927594|
|data/levels.json/90/reward_gold_mult|0.26|0.15315245|0.58904789|
|data/levels.json/91/reward_gold_mult|0.26|0.15309318|0.58881993|
|data/levels.json/92/reward_gold_mult|0.26|0.15303393|0.58859205|
|data/levels.json/93/reward_gold_mult|0.26|0.15297471|0.58836426|
|data/levels.json/94/reward_gold_mult|0.26|0.15291551|0.58813656|
|data/levels.json/95/reward_gold_mult|0.26|0.15285633|0.58790895|
|data/levels.json/96/reward_gold_mult|0.26|0.15279717|0.58768143|
|data/levels.json/97/reward_gold_mult|0.26|0.15273804|0.58745399|
|data/levels.json/98/reward_gold_mult|0.26|0.15267893|0.58722664|
|data/weapons.json/weapon_flamethrower/unlock_cost_star|8|10|1.2018777|
|data/weapons.json/weapon_cryocannon/unlock_cost_star|8|10|1.2018777|
|data/weapons.json/weapon_teslacoil/unlock_cost_star|10|12|1.2018777|
|data/weapons.json/weapon_venomlauncher/unlock_cost_star|8|10|1.2018777|
|data/weapons.json/weapon_railgun/unlock_cost_star|14|17|1.2018777|
|data/weapons.json/weapon_scattergun/unlock_cost_star|9|11|1.2018777|
|data/weapons.json/weapon_plasmacannon/unlock_cost_star|16|19|1.2018777|
|data/armors.json/armor_kevlar/unlock_cost_star|8|10|1.2018777|
|data/armors.json/armor_thermal/unlock_cost_star|8|10|1.2018777|
|data/armors.json/armor_cryo/unlock_cost_star|9|11|1.2018777|
|data/armors.json/armor_faraday/unlock_cost_star|10|12|1.2018777|
|data/armors.json/armor_hazmat/unlock_cost_star|11|13|1.2018777|
|data/armors.json/armor_reactive/unlock_cost_star|14|17|1.2018777|
|data/chips.json/chip_attack/unlock_cost_star|8|10|1.2018777|
|data/chips.json/chip_haste/unlock_cost_star|8|10|1.2018777|
|data/chips.json/chip_crit/unlock_cost_star|9|11|1.2018777|
|data/chips.json/chip_pierce/unlock_cost_star|11|13|1.2018777|
|data/chips.json/chip_health/unlock_cost_star|9|11|1.2018777|
|data/chips.json/chip_guardian/unlock_cost_star|10|12|1.2018777|
|data/chips.json/chip_greed/unlock_cost_star|11|13|1.2018777|
|data/chips.json/chip_element/unlock_cost_star|14|17|1.2018777|
|data/pets.json/pet_turret_drone/unlock_cost_star|8|10|1.2018777|
|data/pets.json/pet_fire_imp/unlock_cost_star|9|11|1.2018777|
|data/pets.json/pet_frost_wisp/unlock_cost_star|10|12|1.2018777|
|data/pets.json/pet_volt_orb/unlock_cost_star|11|13|1.2018777|
|data/pets.json/pet_medic_drone/unlock_cost_star|13|16|1.2018777|
|data/pets.json/pet_collector/unlock_cost_star|14|17|1.2018777|
|data/economy.json/skill_base_xp_costs/0|350|343|0.98091733|
|data/economy.json/skill_base_xp_costs/1|900|1046|1.1622733|
|data/economy.json/skill_base_xp_costs/2|2000|2754|1.377159|
|data/economy.json/skill_base_xp_costs/3|4000|6527|1.6317737|
|data/economy.json/skill_base_xp_costs/4|8500|16434|1.9334625|
|data/economy.json/sig_skill_xp_costs/0|450|615|1.3661088|
|data/economy.json/sig_skill_xp_costs/1|1200|1646|1.3717007|
|data/economy.json/sig_skill_xp_costs/2|2700|3719|1.3773155|
|data/economy.json/sig_skill_xp_costs/3|5400|7468|1.3829533|
|data/economy.json/sig_skill_xp_costs/4|11000|15275|1.3886141|
|data/weapons.json/weapon_autocannon/cost_base_gold|100|146|1.4617937|
|data/weapons.json/weapon_flamethrower/cost_base_gold|180|217|1.2069912|
|data/weapons.json/weapon_cryocannon/cost_base_gold|180|94|0.52361394|
|data/weapons.json/weapon_teslacoil/cost_base_gold|240|221|0.91997363|
|data/weapons.json/weapon_venomlauncher/cost_base_gold|240|414|1.7265659|
|data/weapons.json/weapon_railgun/cost_base_gold|320|421|1.3163416|
|data/weapons.json/weapon_scattergun/cost_base_gold|180|181|1.006677|
|data/weapons.json/weapon_plasmacannon/cost_base_gold|320|187|0.58417958|

|关卡|rec|E|旧P|新P|新R|新P/E|下限|上限|达标|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
|001|50|65|65|65|1.3000|1.0000|48|71|True|
|002|50|65|69|67|1.3400|1.0308|48|71|True|
|003|50|65|73|70|1.4000|1.0769|48|71|True|
|004|64|65|74|73|1.1406|1.1231|61|71|False|
|005|76|76|81|76|1.0000|1.0000|76|83|True|
|006|53|76|82|77|1.4528|1.0132|51|83|True|
|007|53|76|89|82|1.5472|1.0789|53|83|True|
|008|79|79|96|85|1.0759|1.0759|79|86|True|
|009|79|79|106|89|1.1266|1.1266|79|86|False|
|010|87|87|112|92|1.0575|1.0575|87|95|True|
|011|99|99|116|101|1.0202|1.0202|95|108|True|
|012|108|108|122|110|1.0185|1.0185|103|118|True|
|013|131|131|131|125|0.9542|0.9542|125|144|True|
|014|138|138|141|143|1.0362|1.0362|132|151|True|
|015|147|147|151|151|1.0272|1.0272|147|161|True|
|016|98|147|152|159|1.6224|1.0816|94|161|True|
|017|165|165|166|163|0.9879|0.9879|165|181|False|
|018|185|185|185|177|0.9568|0.9568|185|203|False|
|019|188|188|191|181|0.9628|0.9628|188|206|False|
|020|291|291|294|204|0.7010|0.7010|291|320|False|
|021|164|291|296|206|1.2561|0.7079|156|320|True|
|022|183|291|299|208|1.1366|0.7148|174|320|True|
|023|186|291|302|209|1.1237|0.7182|177|320|True|
|024|201|291|306|209|1.0398|0.7182|191|320|True|
|025|260|291|306|262|1.0077|0.9003|260|320|True|
|026|226|291|348|262|1.1593|0.9003|215|320|True|
|027|195|291|410|300|1.5385|1.0309|195|320|True|
|028|231|291|412|304|1.3160|1.0447|231|320|True|
|029|206|291|414|335|1.6262|1.1512|206|320|False|
|030|332|332|415|351|1.0572|1.0572|332|365|True|
|031|159|332|417|364|2.2893|1.0964|152|365|True|
|032|245|332|418|368|1.5020|1.1084|233|365|False|
|033|228|332|418|368|1.6140|1.1084|217|365|False|
|034|330|332|520|410|1.2424|1.2349|314|365|False|
|035|219|332|565|410|1.8721|1.2349|219|365|False|
|036|225|332|565|410|1.8222|1.2349|214|365|False|
|037|232|332|574|410|1.7672|1.2349|232|365|False|
|038|484|484|581|486|1.0041|1.0041|484|532|True|
|039|533|533|582|490|0.9193|0.9193|533|586|False|
|040|574|574|657|508|0.8850|0.8850|574|631|False|
|041|236|574|696|523|2.2161|0.9111|225|631|True|
|042|375|574|716|530|1.4133|0.9233|357|631|True|
|043|587|587|716|596|1.0153|1.0153|558|645|True|
|044|757|757|756|695|0.9181|0.9181|720|832|False|
|045|655|757|828|695|1.0611|0.9181|655|832|True|
|046|600|757|951|702|1.1700|0.9273|570|832|True|
|047|670|757|951|708|1.0567|0.9353|670|832|True|
|048|663|757|953|715|1.0784|0.9445|663|832|True|
|049|658|757|959|715|1.0866|0.9445|658|832|True|
|050|868|868|968|948|1.0922|1.0922|868|954|True|
|051|431|868|1021|948|2.1995|1.0922|410|954|True|
|052|349|868|1021|961|2.7536|1.1071|332|954|False|
|053|427|868|1035|977|2.2881|1.1256|406|954|False|
|054|359|868|1045|979|2.7270|1.1279|342|954|False|
|055|950|950|1045|979|1.0305|1.0305|950|1045|True|
|056|354|950|1045|984|2.7797|1.0358|337|1045|True|
|057|990|990|1186|992|1.0020|1.0020|990|1089|True|
|058|503|990|1193|992|1.9722|1.0020|503|1089|True|
|059|562|990|1258|992|1.7651|1.0020|562|1089|True|
|060|990|990|1258|992|1.0020|1.0020|990|1089|True|
|061|990|990|1300|1025|1.0354|1.0354|941|1089|True|
|062|250|990|1381|1025|4.1000|1.0354|238|1089|True|
|063|576|990|1387|1039|1.8038|1.0495|548|1089|True|
|064|955|990|1387|1039|1.0880|1.0495|908|1089|True|
|065|1014|1014|1387|1039|1.0247|1.0247|1014|1115|True|
|066|1184|1184|1552|1188|1.0034|1.0034|1125|1302|True|
|067|955|1184|1558|1188|1.2440|1.0034|955|1302|True|
|068|1042|1184|1811|1188|1.1401|1.0034|1042|1302|True|
|069|978|1184|1811|1188|1.2147|1.0034|978|1302|True|
|070|1286|1286|2204|1560|1.2131|1.2131|1286|1414|False|
|071|1146|1286|2204|1571|1.3709|1.2216|1089|1414|False|
|072|1576|1576|2204|1820|1.1548|1.1548|1498|1733|False|
|073|818|1576|2301|1820|2.2249|1.1548|778|1733|False|
|074|2034|2034|2301|1845|0.9071|0.9071|1933|2237|False|
|075|1841|2034|2427|1845|1.0022|0.9071|1841|2237|True|
|076|2758|2758|2748|2009|0.7284|0.7284|2621|3033|False|
|077|1652|2758|2748|2018|1.2215|0.7317|1652|3033|True|
|078|2226|2758|3016|2050|0.9209|0.7433|2226|3033|False|
|079|2030|2758|3177|2050|1.0099|0.7433|2030|3033|True|
|080|2067|2758|3177|2050|0.9918|0.7433|2067|3033|False|
|081|1096|2758|3238|2237|2.0411|0.8111|1042|3033|True|
|082|1762|2758|3274|2237|1.2696|0.8111|1674|3033|True|
|083|1815|2758|3274|2237|1.2325|0.8111|1725|3033|True|
|084|1265|2758|3282|2322|1.8356|0.8419|1202|3033|True|
|085|2204|2758|3282|2419|1.0975|0.8771|2204|3033|True|
|086|1855|2758|3536|2466|1.3294|0.8941|1763|3033|True|
|087|1857|2758|3637|2507|1.3500|0.9090|1857|3033|True|
|088|1857|2758|3720|2507|1.3500|0.9090|1857|3033|True|
|089|1994|2758|3911|2507|1.2573|0.9090|1994|3033|True|
|090|2751|2758|3988|2956|1.0745|1.0718|2751|3033|True|
|091|1234|2758|3988|2956|2.3955|1.0718|1173|3033|True|
|092|1862|2758|4090|2956|1.5875|1.0718|1769|3033|True|
|093|2266|2758|4393|3161|1.3950|1.1461|2153|3033|False|
|094|1830|2758|4395|3225|1.7623|1.1693|1739|3033|False|
|095|3370|3370|5022|3334|0.9893|0.9893|3370|3707|False|
|096|2429|3370|5090|3334|1.3726|0.9893|2308|3707|True|
|097|1863|3370|5098|3345|1.7955|0.9926|1863|3707|True|
|098|2720|3370|5230|3347|1.2305|0.9932|2720|3707|True|
|099|3094|3370|5230|3358|1.0853|0.9964|3094|3707|True|

## 优化前回刷门与预算

状态：离线条件模拟，不代表实际3★通关；未改数据。

# T3 进度闭环

只用假定3★首通，金币按逐敌四舍五入；非Boss波support不计。
§8.2主路径在账户副本内回刷上一关，每章累计最多6次；未达门槛后的行仅为条件诊断。
不计动态召唤、金币卡、付费助推；按现有购买/升级优先级和技能经验成本。
重复3★没有新增星星，只有金币与递减经验。R是显示战力比，不等于已验证胜率。

design/41 section 8.2: all P>=.95rec; Boss/x7-x9 P>=rec; all P<=1.10E; <=6 predecessor farms/chapter; E=max(65,rec(1..L))

首次R<0.95：None；G1走廊不满足关数：74/99。

包络目标Σ|P−E|/E：25.563564。

回刷总数：8；各章：{1: 0, 2: 5, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 3, 9: 0, 10: 0}；墙过高/预算内未满足下限：[]。

|回刷门|前一关|入门P|回刷后P|次数|章累计|下限满足|八墙关|
|---|---:|---:|---:|---:|---:|---|---|
|018|17|169|185|2|2|True|True|
|019|18|187|191|1|3|True|True|
|020|19|202|294|2|5|True|True|
|076|75|2464|2748|3|3|True|True|

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|回刷至R≥1|
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|
|001|0|65|50|1.3000|65|1.0000|466|vanguard 1→2; weapon_autocannon 1→3|不可恢复/未收敛|
|002|466|69|50|1.3800|65|1.0615|649|vanguard 2→3; weapon_autocannon 3→4; skill_multishot 0→1|不可恢复/未收敛|
|003|1115|73|50|1.4600|65|1.1231|757|weapon_cryocannon; weapon_autocannon 4→5; weapon_cryocannon 1→3; skill_pierce 0→1|不可恢复/未收敛|
|004|1872|74|64|1.1562|65|1.1385|878|vanguard 3→4; weapon_autocannon 5→6; skill_barrier 0→1; skill_homing 0→1|不可恢复/未收敛|
|005|2750|81|76|1.0658|76|1.0658|999|weapon_autocannon 6→7; weapon_cryocannon 3→4; skill_salvo 0→1|不可恢复/未收敛|
|006|3749|82|53|1.5472|76|1.0789|1198|armor_kevlar; armor_kevlar 1→3; weapon_autocannon 7→8; weapon_cryocannon 4→5; skill_charge_shot 0→1|不可恢复/未收敛|
|007|4947|89|53|1.6792|76|1.1711|1194|armor_kevlar 3→4; vanguard 4→5; weapon_autocannon 8→9; skill_slow_field 0→1; signature 0→1|不可恢复/未收敛|
|008|6141|96|79|1.2152|79|1.2152|1501|chip_attack; chip_attack 1→5; weapon_autocannon 9→10; skill_split_shot 0→1|不可恢复/未收敛|
|009|7642|106|79|1.3418|79|1.3418|1281|vanguard 5→6; weapon_autocannon 10→11; skill_critical 0→1|不可恢复/未收敛|
|010|8923|112|87|1.2874|87|1.2874|1245|armor_kevlar 4→5; weapon_autocannon 11→12; skill_ricochet 0→1|不可恢复/未收敛|
|011|10168|116|99|1.1717|99|1.1717|1826|weapon_scattergun; weapon_autocannon 12→13; weapon_scattergun 1→4; skill_multishot 1→2|不可恢复/未收敛|
|012|11994|122|108|1.1296|108|1.1296|1926|vanguard 6→7; weapon_autocannon 13→14; weapon_scattergun 4→5|不可恢复/未收敛|
|013|13920|131|131|1.0000|131|1.0000|2071|chip_attack 5→6; weapon_cryocannon 5→6; weapon_scattergun 5→6; skill_pierce 1→2|不可恢复/未收敛|
|014|15991|141|138|1.0217|138|1.0217|2143|vanguard 7→8; weapon_cryocannon 6→7; weapon_scattergun 6→7; skill_homing 1→2|不可恢复/未收敛|
|015|18134|151|147|1.0272|147|1.0272|1393|armor_kevlar 5→6; weapon_scattergun 7→8|不可恢复/未收敛|
|016|19527|152|98|1.5510|147|1.0340|2742|weapon_railgun; weapon_railgun 1→4; weapon_scattergun 8→9; skill_barrier 1→2|不可恢复/未收敛|
|017|22269|166|165|1.0061|165|1.0061|2719|chip_attack 6→7; weapon_railgun 4→5; weapon_scattergun 9→10; skill_salvo 1→2|不可恢复/未收敛|
|018|29388|185|185|1.0000|185|1.0000|2161|chip_attack 7→8; weapon_scattergun 12→13|不可恢复/未收敛|
|019|33165|191|188|1.0160|188|1.0160|2977|pet_turret_drone; pet_turret_drone 1→5; weapon_scattergun 14→15; signature 1→2|不可恢复/未收敛|
|020|40954|294|291|1.0103|291|1.0103|3195|weapon_railgun 5→6; weapon_scattergun 17→18; skill_split_shot 1→2|不可恢复/未收敛|
|021|44149|296|164|1.8049|291|1.0172|2916|weapon_venomlauncher; weapon_scattergun 18→19; weapon_venomlauncher 1→3|不可恢复/未收敛|
|022|47065|299|183|1.6339|291|1.0275|3177|weapon_scattergun 19→20; weapon_venomlauncher 3→4; skill_critical 1→2|不可恢复/未收敛|
|023|50242|302|186|1.6237|291|1.0378|3563|pet_turret_drone 5→6; weapon_scattergun 20→21; weapon_venomlauncher 4→5; skill_ricochet 1→2|不可恢复/未收敛|
|024|53805|306|201|1.5224|291|1.0515|3343|weapon_venomlauncher 5→8|不可恢复/未收敛|
|025|57148|306|260|1.1769|291|1.0515|2321|vanguard 9→10; weapon_railgun 6→7|不可恢复/未收敛|
|026|59469|348|226|1.5398|291|1.1959|3935|chip_attack 8→9; weapon_railgun 7→8; weapon_venomlauncher 8→9; skill_multishot 2→3|不可恢复/未收敛|
|027|63404|410|195|2.1026|291|1.4089|3720|weapon_cryocannon 8→9; weapon_scattergun 21→22|不可恢复/未收敛|
|028|67124|412|231|1.7835|291|1.4158|4002|armor_kevlar 7→8; weapon_railgun 8→9; weapon_venomlauncher 9→10; skill_pierce 2→3|不可恢复/未收敛|
|029|71126|414|206|2.0097|291|1.4227|4148|weapon_cryocannon 9→10; weapon_scattergun 22→23|不可恢复/未收敛|
|030|75274|415|332|1.2500|332|1.2500|3328|chip_attack 9→10; weapon_scattergun 23→24|不可恢复/未收敛|
|031|78602|417|159|2.6226|332|1.2560|4714|weapon_flamethrower; weapon_flamethrower 1→5; weapon_scattergun 24→25; skill_homing 2→3|不可恢复/未收敛|
|032|83316|418|245|1.7061|332|1.2590|4420|weapon_plasmacannon; weapon_flamethrower 5→7; weapon_plasmacannon 1→5|不可恢复/未收敛|
|033|87736|418|228|1.8333|332|1.2590|3968|weapon_flamethrower 7→8; weapon_scattergun 25→26; skill_barrier 2→3|不可恢复/未收敛|
|034|91704|520|330|1.5758|332|1.5663|4994|armor_kevlar 8→9; weapon_flamethrower 8→9; weapon_scattergun 26→27|不可恢复/未收敛|
|035|96698|565|219|2.5799|332|1.7018|3689|weapon_flamethrower 9→10; weapon_plasmacannon 5→7; skill_salvo 2→3|不可恢复/未收敛|
|036|100387|565|225|2.5111|332|1.7018|4999|weapon_flamethrower 10→11; weapon_scattergun 27→28|不可恢复/未收敛|
|037|105386|574|232|2.4741|332|1.7289|5600|pet_turret_drone 6→7; weapon_flamethrower 11→12; weapon_scattergun 28→29; skill_charge_shot 2→3|不可恢复/未收敛|
|038|110986|581|484|1.2004|484|1.2004|6000|weapon_autocannon 14→15; weapon_flamethrower 12→13; weapon_scattergun 29→30|不可恢复/未收敛|
|039|116986|582|533|1.0919|533|1.0919|5156|weapon_cryocannon 10→11; weapon_flamethrower 13→14; weapon_plasmacannon 7→8; skill_slow_field 2→3|不可恢复/未收敛|
|040|122142|657|574|1.1446|574|1.1446|6793|vanguard 10→11; weapon_flamethrower 14→15; weapon_scattergun 30→31|不可恢复/未收敛|
|041|128935|696|236|2.9492|574|1.2125|6462|weapon_teslacoil; weapon_scattergun 31→32; weapon_teslacoil 1→6; signature 2→3|不可恢复/未收敛|
|042|135397|716|375|1.9093|574|1.2474|6075|weapon_plasmacannon 8→9; weapon_teslacoil 6→9|不可恢复/未收敛|
|043|141472|716|587|1.2198|587|1.2198|7055|weapon_scattergun 32→33; weapon_teslacoil 9→11; skill_split_shot 2→3|不可恢复/未收敛|
|044|148527|756|757|0.9987|757|0.9987|6867|chip_attack 10→11; weapon_scattergun 33→34; weapon_teslacoil 11→12|不可恢复/未收敛|
|045|155394|828|655|1.2641|757|1.0938|7042|armor_kevlar 9→10; weapon_scattergun 34→35; weapon_teslacoil 12→13; skill_critical 2→3|不可恢复/未收敛|
|046|162436|951|600|1.5850|757|1.2563|6022|weapon_plasmacannon 9→10; weapon_teslacoil 13→14; weapon_venomlauncher 10→11; skill_ricochet 2→3|不可恢复/未收敛|
|047|168458|951|670|1.4194|757|1.2563|6656|pet_turret_drone 7→8; weapon_cryocannon 11→12; weapon_railgun 9→10; weapon_teslacoil 14→15|不可恢复/未收敛|
|048|175114|953|663|1.4374|757|1.2589|7623|weapon_scattergun 35→36; weapon_teslacoil 15→16|不可恢复/未收敛|
|049|182737|959|658|1.4574|757|1.2668|7652|chip_attack 11→12; weapon_scattergun 36→37; weapon_teslacoil 16→17|不可恢复/未收敛|
|050|190389|968|868|1.1152|868|1.1152|5724|armor_kevlar 10→11; weapon_scattergun 37→38; skill_multishot 3→4|不可恢复/未收敛|
|051|196113|1021|431|2.3689|868|1.1763|2522|weapon_plasmacannon 10→11|不可恢复/未收敛|
|052|198635|1021|349|2.9255|868|1.1763|2819|pet_turret_drone 8→9; weapon_railgun 10→11|不可恢复/未收敛|
|053|201454|1035|427|2.4239|868|1.1924|2763|chip_attack 12→13; weapon_venomlauncher 11→12; skill_pierce 3→4|不可恢复/未收敛|
|054|204217|1045|359|2.9109|868|1.2039|2807|weapon_plasmacannon 11→12|不可恢复/未收敛|
|055|207024|1045|950|1.1000|950|1.1000|2897|weapon_railgun 11→12; skill_homing 3→4|不可恢复/未收敛|
|056|209921|1045|354|2.9520|950|1.1000|2693|vanguard 11→12; weapon_cryocannon 12→13|不可恢复/未收敛|
|057|212614|1186|990|1.1980|990|1.1980|4919|weapon_scattergun 38→39|不可恢复/未收敛|
|058|217533|1193|503|2.3718|990|1.2051|3084|weapon_autocannon 15→16; weapon_venomlauncher 12→13; skill_barrier 3→4|不可恢复/未收敛|
|059|220617|1258|562|2.2384|990|1.2707|2995|weapon_plasmacannon 12→13|不可恢复/未收敛|
|060|223612|1258|990|1.2707|990|1.2707|6400|weapon_cryocannon 13→14; weapon_scattergun 39→40; skill_salvo 3→4|不可恢复/未收敛|
|061|230012|1300|990|1.3131|990|1.3131|3770|vanguard 12→13; weapon_railgun 12→13|不可恢复/未收敛|
|062|233782|1381|250|5.5240|990|1.3949|3835|weapon_autocannon 16→17; weapon_venomlauncher 13→14; skill_charge_shot 3→4|不可恢复/未收敛|
|063|237617|1387|576|2.4080|990|1.4010|3555|weapon_autocannon 17→18; weapon_plasmacannon 13→14|不可恢复/未收敛|
|064|241172|1387|955|1.4524|990|1.4010|3609|weapon_railgun 13→14|不可恢复/未收敛|
|065|244781|1387|1014|1.3679|1014|1.3679|4223|weapon_cryocannon 14→15; weapon_venomlauncher 14→15; signature 3→4|不可恢复/未收敛|
|066|249004|1552|1184|1.3108|1184|1.3108|3497|pet_turret_drone 9→10; weapon_plasmacannon 14→15|不可恢复/未收敛|
|067|252501|1558|955|1.6314|1184|1.3159|4705|vanguard 13→14; weapon_railgun 14→15; skill_slow_field 3→4|不可恢复/未收敛|
|068|257206|1811|1042|1.7380|1184|1.5296|4315|weapon_cryocannon 15→16; weapon_flamethrower 15→16|不可恢复/未收敛|
|069|261521|1811|978|1.8517|1184|1.5296|4485|armor_kevlar 11→12; vanguard 14→15; weapon_venomlauncher 15→16; skill_split_shot 3→4|不可恢复/未收敛|
|070|266006|2204|1286|1.7138|1286|1.7138|4298|weapon_plasmacannon 15→16|不可恢复/未收敛|
|071|270304|2204|1146|1.9232|1286|1.7138|3880|weapon_autocannon 18→19; weapon_railgun 15→16; skill_critical 3→4|不可恢复/未收敛|
|072|274184|2204|1576|1.3985|1576|1.3985|3661|vanguard 15→16; weapon_cryocannon 16→17|不可恢复/未收敛|
|073|277845|2301|818|2.8130|1576|1.4600|4011|weapon_autocannon 19→20; weapon_flamethrower 16→17; skill_ricochet 3→4|不可恢复/未收敛|
|074|281856|2301|2034|1.1313|2034|1.1313|4820|weapon_scattergun 40→41|不可恢复/未收敛|
|075|286676|2427|1841|1.3183|2034|1.1932|5072|weapon_scattergun 41→42|不可恢复/未收敛|
|076|300352|2748|2758|0.9964|2758|0.9964|4419|armor_kevlar 12→13; weapon_plasmacannon 16→17|不可恢复/未收敛|
|077|304771|2748|1652|1.6634|2758|0.9964|5041|weapon_scattergun 42→43|不可恢复/未收敛|
|078|309812|3016|2226|1.3549|2758|1.0935|4662|chip_attack 14→15; weapon_railgun 16→17|不可恢复/未收敛|
|079|314474|3177|2030|1.5650|2758|1.1519|5091|weapon_autocannon 20→21; weapon_teslacoil 17→18; skill_pierce 4→5|不可恢复/未收敛|
|080|319565|3177|2067|1.5370|2758|1.1519|5579|weapon_scattergun 43→44|不可恢复/未收敛|
|081|325144|3238|1096|2.9544|2758|1.1740|4320|vanguard 16→17; weapon_venomlauncher 17→18|不可恢复/未收敛|
|082|329464|3274|1762|1.8581|2758|1.1871|4313|pet_turret_drone 10→11; weapon_plasmacannon 17→18; skill_homing 4→5|不可恢复/未收敛|
|083|333777|3274|1815|1.8039|2758|1.1871|5146|armor_kevlar 13→14; weapon_railgun 17→18|不可恢复/未收敛|
|084|338923|3282|1265|2.5945|2758|1.1900|4431|weapon_cryocannon 18→19; weapon_flamethrower 18→19|不可恢复/未收敛|
|085|343354|3282|2204|1.4891|2758|1.1900|6158|weapon_scattergun 44→45; skill_barrier 4→5|不可恢复/未收敛|
|086|349512|3536|1855|1.9062|2758|1.2821|5850|weapon_scattergun 45→46|不可恢复/未收敛|
|087|355362|3637|1857|1.9585|2758|1.3187|5717|weapon_scattergun 46→47|不可恢复/未收敛|
|088|361079|3720|1857|2.0032|2758|1.3488|5260|chip_attack 15→16; weapon_autocannon 21→22; weapon_teslacoil 18→19; skill_salvo 4→5|不可恢复/未收敛|
|089|366339|3911|1994|1.9614|2758|1.4181|5703|vanguard 17→18; weapon_venomlauncher 18→19|不可恢复/未收敛|
|090|372042|3988|2751|1.4497|2758|1.4460|4834|weapon_autocannon 22→23; weapon_plasmacannon 18→19|不可恢复/未收敛|
|091|376876|3988|1234|3.2318|2758|1.4460|4742|weapon_railgun 18→19; skill_charge_shot 4→5|不可恢复/未收敛|
|092|381618|4090|1862|2.1966|2758|1.4830|6828|chip_attack 16→17; weapon_scattergun 47→48|不可恢复/未收敛|
|093|388446|4393|2266|1.9387|2758|1.5928|5903|weapon_scattergun 48→49|不可恢复/未收敛|
|094|394349|4395|1830|2.4016|2758|1.5935|6393|weapon_scattergun 49→50; skill_slow_field 4→5|不可恢复/未收敛|
|095|400742|5022|3370|1.4902|3370|1.4902|5911|armor_kevlar 14→15; weapon_cryocannon 19→20; weapon_flamethrower 19→20|不可恢复/未收敛|
|096|406653|5090|2429|2.0955|3370|1.5104|7903|pet_turret_drone 11→12; weapon_teslacoil 19→20; weapon_venomlauncher 19→20|不可恢复/未收敛|
|097|414556|5098|1863|2.7364|3370|1.5128|7350|chip_attack 17→18; vanguard 18→19; weapon_plasmacannon 19→20; skill_split_shot 4→5|不可恢复/未收敛|
|098|421906|5230|2720|1.9228|3370|1.5519|7317|weapon_cryocannon 20→21; weapon_railgun 19→20|不可恢复/未收敛|
|099|429223|5230|3094|1.6904|3370|1.5519|6337|weapon_flamethrower 20→21; weapon_teslacoil 20→21|不可恢复/未收敛|

## 优化后回刷门与预算

状态：离线条件模拟，不代表实际3★通关；未改数据。

# T3 进度闭环

只用假定3★首通，金币按逐敌四舍五入；非Boss波support不计。
§8.2主路径在账户副本内回刷上一关，每章累计最多6次；未达门槛后的行仅为条件诊断。
不计动态召唤、金币卡、付费助推；按现有购买/升级优先级和技能经验成本。
重复3★没有新增星星，只有金币与递减经验。R是显示战力比，不等于已验证胜率。

design/41 section 8.2: all P>=.95rec; Boss/x7-x9 P>=rec; all P<=1.10E; <=6 predecessor farms/chapter; E=max(65,rec(1..L))

首次R<0.95：20；G1走廊不满足关数：30/99。

包络目标Σ|P−E|/E：9.738043。

回刷总数：37；各章：{1: 0, 2: 6, 3: 5, 4: 6, 5: 6, 6: 1, 7: 1, 8: 6, 9: 0, 10: 6}；墙过高/预算内未满足下限：[17, 18, 19, 20, 39, 40, 44, 74, 76, 78, 80, 95]。

|回刷门|前一关|入门P|回刷后P|次数|章累计|下限满足|八墙关|
|---|---:|---:|---:|---:|---:|---|---|
|012|11|102|110|1|1|True|False|
|013|12|114|125|4|5|True|False|
|014|13|126|143|1|6|True|False|
|017|16|163|163|0|6|False|True|
|018|17|177|177|0|6|False|True|
|019|18|181|181|0|6|False|True|
|020|19|204|204|0|6|False|True|
|025|24|214|262|5|5|True|False|
|038|37|473|486|2|2|True|False|
|039|38|486|490|4|6|False|False|
|040|39|508|508|0|6|False|True|
|044|43|599|695|6|6|False|True|
|057|56|984|992|1|1|True|False|
|070|69|1188|1560|1|1|True|False|
|074|73|1820|1845|6|6|False|False|
|076|75|2009|2009|0|6|False|True|
|078|77|2050|2050|0|6|False|False|
|080|79|2050|2050|0|6|False|False|
|095|94|3225|3334|6|6|False|False|

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|回刷至R≥1|
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|
|001|0|65|50|1.3000|65|1.0000|321|vanguard 1→2; weapon_autocannon 1→2|不可恢复/未收敛|
|002|321|67|50|1.3400|65|1.0308|431|weapon_autocannon 2→3; skill_multishot 0→1|不可恢复/未收敛|
|003|752|70|50|1.4000|65|1.0769|512|vanguard 2→3; weapon_autocannon 3→4; skill_pierce 0→1|不可恢复/未收敛|
|004|1264|73|64|1.1406|65|1.1231|582|weapon_cryocannon; weapon_autocannon 4→5; weapon_cryocannon 1→3; skill_barrier 0→1; skill_homing 0→1|不可恢复/未收敛|
|005|1846|76|76|1.0000|76|1.0000|704|vanguard 3→4; weapon_cryocannon 3→4; skill_salvo 0→1|不可恢复/未收敛|
|006|2550|77|53|1.4528|76|1.0132|761|weapon_autocannon 5→6; weapon_cryocannon 4→5; skill_charge_shot 0→1; skill_slow_field 0→1|不可恢复/未收敛|
|007|3311|82|53|1.5472|76|1.0789|779|armor_kevlar; armor_kevlar 1→2; weapon_autocannon 6→7; skill_split_shot 0→1|不可恢复/未收敛|
|008|4090|85|79|1.0759|79|1.0759|1013|armor_kevlar 2→3; vanguard 4→5; weapon_cryocannon 5→6; signature 0→1|不可恢复/未收敛|
|009|5103|89|79|1.1266|79|1.1266|799|weapon_autocannon 7→8; skill_critical 0→1|不可恢复/未收敛|
|010|5902|92|87|1.0575|87|1.0575|832|chip_attack; weapon_autocannon 8→9; skill_ricochet 0→1|不可恢复/未收敛|
|011|6734|101|99|1.0202|99|1.0202|1260|chip_attack 1→3; weapon_autocannon 9→10|不可恢复/未收敛|
|012|8934|110|108|1.0185|108|1.0185|1297|armor_kevlar 4→5; weapon_autocannon 10→11|不可恢复/未收敛|
|013|14051|125|131|0.9542|131|0.9542|1343|weapon_autocannon 12→13; skill_homing 1→2|不可恢复/未收敛|
|014|16373|143|138|1.0362|138|1.0362|1387|weapon_scattergun; chip_attack 6→7; weapon_scattergun 1→4; skill_barrier 1→2|不可恢复/未收敛|
|015|17760|151|147|1.0272|147|1.0272|968|weapon_scattergun 4→5|不可恢复/未收敛|
|016|18728|159|98|1.6224|147|1.0816|1825|weapon_cryocannon 8→9; weapon_scattergun 5→7; skill_salvo 1→2|不可恢复/未收敛|
|017|20553|163|165|0.9879|165|0.9879|1798|vanguard 8→9; weapon_scattergun 7→8|不可恢复/未收敛|
|018|22351|177|185|0.9568|185|0.9568|1503|weapon_cryocannon 9→10; weapon_scattergun 8→9; skill_charge_shot 1→2|不可恢复/未收敛|
|019|23854|181|188|0.9628|188|0.9628|1991|chip_attack 7→8; weapon_scattergun 9→10; skill_slow_field 1→2|不可恢复/未收敛|
|020|25845|204|291|0.7010|291|0.7010|2115|weapon_railgun; armor_kevlar 6→7; weapon_railgun 1→2; weapon_scattergun 10→11; skill_split_shot 1→2|不可恢复/未收敛|
|021|27960|206|164|1.2561|291|0.7079|1924|armor_kevlar 7→8; weapon_scattergun 11→12|不可恢复/未收敛|
|022|29884|208|183|1.1366|291|0.7148|2111|weapon_scattergun 12→13; skill_critical 1→2|不可恢复/未收敛|
|023|31995|209|186|1.1237|291|0.7182|2407|weapon_venomlauncher; weapon_scattergun 13→14; weapon_venomlauncher 1→3; skill_ricochet 1→2|不可恢复/未收敛|
|024|34402|209|201|1.0398|291|0.7182|2234|weapon_scattergun 14→15|不可恢复/未收敛|
|025|44676|262|260|1.0077|291|0.9003|1645|weapon_venomlauncher 5→6|不可恢复/未收敛|
|026|46321|262|226|1.1593|291|0.9003|2605|pet_turret_drone; pet_turret_drone 1→3; weapon_scattergun 16→17|不可恢复/未收敛|
|027|48926|300|195|1.5385|291|1.0309|2444|pet_turret_drone 3→4; weapon_scattergun 17→18|不可恢复/未收敛|
|028|51370|304|231|1.3160|291|1.0447|2675|pet_turret_drone 4→5; weapon_scattergun 18→19; skill_multishot 2→3|不可恢复/未收敛|
|029|54045|335|206|1.6262|291|1.1512|2731|weapon_scattergun 19→20|不可恢复/未收敛|
|030|56776|351|332|1.0572|332|1.0572|2198|weapon_scattergun 20→21|不可恢复/未收敛|
|031|58974|364|159|2.2893|332|1.0964|3150|weapon_flamethrower; pet_turret_drone 5→6; weapon_flamethrower 1→6; skill_pierce 2→3|不可恢复/未收敛|
|032|62124|368|245|1.5020|332|1.1084|2928|weapon_flamethrower 6→7; weapon_railgun 5→6|不可恢复/未收敛|
|033|65052|368|228|1.6140|332|1.1084|2725|weapon_scattergun 21→22|不可恢复/未收敛|
|034|67777|410|330|1.2424|332|1.2349|3292|chip_attack 9→10; weapon_flamethrower 7→8; weapon_venomlauncher 6→7; skill_homing 2→3|不可恢复/未收敛|
|035|71069|410|219|1.8721|332|1.2349|2537|pet_turret_drone 6→7; weapon_railgun 6→7|不可恢复/未收敛|
|036|73606|410|225|1.8222|332|1.2349|3310|weapon_plasmacannon; weapon_flamethrower 8→9; weapon_plasmacannon 1→5|不可恢复/未收敛|
|037|76916|410|232|1.7672|332|1.2349|3720|weapon_flamethrower 9→10; weapon_scattergun 22→23; skill_barrier 2→3|不可恢复/未收敛|
|038|86154|486|484|1.0041|484|1.0041|3966|weapon_flamethrower 10→11; weapon_venomlauncher 7→8|不可恢复/未收敛|
|039|102032|490|533|0.9193|533|0.9193|3466|armor_kevlar 8→9; weapon_scattergun 25→26|不可恢复/未收敛|
|040|105498|508|574|0.8850|574|0.8850|4442|weapon_flamethrower 11→12; weapon_railgun 8→9; skill_charge_shot 2→3|不可恢复/未收敛|
|041|109940|523|236|2.2161|574|0.9111|4379|weapon_teslacoil; weapon_scattergun 26→27; weapon_teslacoil 1→4|不可恢复/未收敛|
|042|114319|530|375|1.4133|574|0.9233|4008|weapon_teslacoil 4→8; skill_slow_field 2→3|不可恢复/未收敛|
|043|118327|596|587|1.0153|587|1.0153|4609|weapon_scattergun 27→28; weapon_teslacoil 8→9|不可恢复/未收敛|
|044|143834|695|757|0.9181|757|0.9181|4486|weapon_teslacoil 11→12; weapon_venomlauncher 10→11|不可恢复/未收敛|
|045|148320|695|655|1.0611|757|0.9181|4539|weapon_cryocannon 13→14; weapon_scattergun 30→31; skill_critical 2→3|不可恢复/未收敛|
|046|152859|702|600|1.1700|757|0.9273|4033|weapon_scattergun 31→32|不可恢复/未收敛|
|047|156892|708|670|1.0567|757|0.9353|4435|weapon_scattergun 32→33; skill_ricochet 2→3|不可恢复/未收敛|
|048|161327|715|663|1.0784|757|0.9445|5068|weapon_railgun 10→11; weapon_teslacoil 12→13|不可恢复/未收敛|
|049|166395|715|658|1.0866|757|0.9445|5050|vanguard 11→12; weapon_scattergun 33→34|不可恢复/未收敛|
|050|171445|948|868|1.0922|868|1.0922|3883|weapon_autocannon 13→14; weapon_cryocannon 14→15; weapon_plasmacannon 11→12|不可恢复/未收敛|
|051|175328|948|431|2.1995|868|1.0922|1986|weapon_plasmacannon 12→13; signature 2→3|不可恢复/未收敛|
|052|177314|961|349|2.7536|868|1.1071|2170|armor_kevlar 9→10; weapon_flamethrower 12→13|不可恢复/未收敛|
|053|179484|977|427|2.2881|868|1.1256|2152|pet_turret_drone 8→9; weapon_autocannon 14→15|不可恢复/未收敛|
|054|181636|979|359|2.7270|868|1.1279|2192|weapon_plasmacannon 13→14|不可恢复/未收敛|
|055|183828|979|950|1.0305|950|1.0305|2234|weapon_flamethrower 13→14; skill_multishot 3→4|不可恢复/未收敛|
|056|186062|984|354|2.7797|950|1.0358|2152|weapon_teslacoil 13→14|不可恢复/未收敛|
|057|188860|992|990|1.0020|990|1.0020|3461|weapon_venomlauncher 11→12|不可恢复/未收敛|
|058|192321|992|503|1.9722|990|1.0020|2417|weapon_autocannon 15→16; weapon_cryocannon 15→16|不可恢复/未收敛|
|059|194738|992|562|1.7651|990|1.0020|2371|weapon_autocannon 16→17; skill_pierce 3→4|不可恢复/未收敛|
|060|197109|992|990|1.0020|990|1.0020|4473|chip_attack 11→12; weapon_scattergun 34→35|不可恢复/未收敛|
|061|201582|1025|990|1.0354|990|1.0354|2828|armor_kevlar 10→11; weapon_plasmacannon 14→15|不可恢复/未收敛|
|062|204410|1025|250|4.1000|990|1.0354|2941|pet_turret_drone 9→10; weapon_flamethrower 14→15; skill_homing 3→4|不可恢复/未收敛|
|063|207351|1039|576|1.8038|990|1.0495|2754|weapon_teslacoil 14→15|不可恢复/未收敛|
|064|210105|1039|955|1.0880|990|1.0495|2797|weapon_railgun 11→12|不可恢复/未收敛|
|065|212902|1039|1014|1.0247|1014|1.0247|3172|vanguard 13→14; weapon_autocannon 17→18|不可恢复/未收敛|
|066|216074|1188|1184|1.0034|1184|1.0034|2741|weapon_plasmacannon 15→16; skill_barrier 3→4|不可恢复/未收敛|
|067|218815|1188|955|1.2440|1184|1.0034|3492|weapon_venomlauncher 12→13|不可恢复/未收敛|
|068|222307|1188|1042|1.1401|1184|1.0034|3269|weapon_railgun 12→13|不可恢复/未收敛|
|069|225576|1188|978|1.2147|1184|1.0034|3384|weapon_cryocannon 16→17; weapon_flamethrower 15→16; skill_salvo 3→4|不可恢复/未收敛|
|070|230425|1560|1286|1.2131|1286|1.2131|3290|chip_attack 12→13; weapon_teslacoil 15→16|不可恢复/未收敛|
|071|233715|1571|1146|1.3709|1286|1.2216|3037|weapon_autocannon 18→19; weapon_cryocannon 17→18; skill_charge_shot 3→4|不可恢复/未收敛|
|072|236752|1820|1576|1.1548|1576|1.1548|2975|armor_kevlar 11→12; weapon_plasmacannon 16→17|不可恢复/未收敛|
|073|239727|1820|818|2.2249|1576|1.1548|3177|weapon_flamethrower 16→17|不可恢复/未收敛|
|074|249648|1845|2034|0.9071|2034|0.9071|3691|weapon_venomlauncher 13→14|不可恢复/未收敛|
|075|253339|1845|1841|1.0022|2034|0.9071|3889|weapon_railgun 13→14; signature 3→4|不可恢复/未收敛|
|076|257228|2009|2758|0.7284|2758|0.7284|3447|pet_turret_drone 10→11; weapon_teslacoil 16→17|不可恢复/未收敛|
|077|260675|2018|1652|1.2215|2758|0.7317|3806|vanguard 16→17; weapon_autocannon 19→20|不可恢复/未收敛|
|078|264481|2050|2226|0.9209|2758|0.7433|3621|weapon_cryocannon 20→21; weapon_plasmacannon 17→18; skill_split_shot 3→4|不可恢复/未收敛|
|079|268102|2050|2030|1.0099|2758|0.7433|3888|armor_kevlar 13→14; weapon_flamethrower 17→18|不可恢复/未收敛|
|080|271990|2050|2067|0.9918|2758|0.7433|4187|weapon_scattergun 35→36|不可恢复/未收敛|
|081|276177|2237|1096|2.0411|2758|0.8111|3470|weapon_teslacoil 17→18; skill_critical 3→4|不可恢复/未收敛|
|082|279647|2237|1762|1.2696|2758|0.8111|3486|weapon_venomlauncher 14→15|不可恢复/未收敛|
|083|283133|2237|1815|1.2325|2758|0.8111|4005|vanguard 17→18; weapon_autocannon 20→21; skill_ricochet 3→4|不可恢复/未收敛|
|084|287138|2322|1265|1.8356|2758|0.8419|3585|chip_attack 15→16; weapon_plasmacannon 18→19|不可恢复/未收敛|
|085|290723|2419|2204|1.0975|2758|0.8771|4620|weapon_scattergun 36→37|不可恢复/未收敛|
|086|295343|2466|1855|1.3294|2758|0.8941|4462|weapon_scattergun 37→38|不可恢复/未收敛|
|087|299805|2507|1857|1.3500|2758|0.9090|4414|weapon_railgun 14→15|不可恢复/未收敛|
|088|304219|2507|1857|1.3500|2758|0.9090|4156|weapon_cryocannon 21→22; weapon_flamethrower 18→19|不可恢复/未收敛|
|089|308375|2507|1994|1.2573|2758|0.9090|4404|weapon_venomlauncher 15→16; skill_multishot 4→5|不可恢复/未收敛|
|090|312779|2956|2751|1.0745|2758|1.0718|3901|armor_kevlar 14→15; weapon_teslacoil 18→19|不可恢复/未收敛|
|091|316680|2956|1234|2.3955|2758|1.0718|3851|weapon_autocannon 21→22; weapon_cryocannon 22→23|不可恢复/未收敛|
|092|320531|2956|1862|1.5875|2758|1.0718|5125|weapon_scattergun 38→39|不可恢复/未收敛|
|093|325656|3161|2266|1.3950|2758|1.1461|4589|weapon_scattergun 39→40|不可恢复/未收敛|
|094|330245|3225|1830|1.7623|2758|1.1693|4889|weapon_railgun 15→16|不可恢复/未收敛|
|095|347614|3334|3370|0.9893|3370|0.9893|4630|weapon_cryocannon 23→24; weapon_plasmacannon 19→20|不可恢复/未收敛|
|096|352244|3334|2429|1.3726|3370|0.9893|5802|armor_kevlar 15→16; weapon_scattergun 40→41|不可恢复/未收敛|
|097|358046|3345|1863|1.7955|3370|0.9926|5477|weapon_scattergun 41→42|不可恢复/未收敛|
|098|363523|3347|2720|1.2305|3370|0.9932|5504|weapon_scattergun 42→43; signature 4→5|不可恢复/未收敛|
|099|369027|3358|3094|1.0853|3370|0.9964|4970|weapon_venomlauncher 16→17|不可恢复/未收敛|

