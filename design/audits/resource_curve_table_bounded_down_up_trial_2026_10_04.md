状态：SEARCH_CANDIDATE_NOT_YET_FEASIBLE；待Fable签字，游戏数据未写入。

# 资源表 C 候选

离线假定3★首通与上一关回刷，每章最多6次；不是新运行时胜率。既有账户策略与P(g)/F(g)冻结。所有因子限定[0.5,2.0]。
优化前：74/99失败，目标25.563564。
优化后：36/99失败，目标10.413108。

缩放系数与逐字段旧/新对照完整列于同名JSON；所有候选仅在内存模拟。

|曲线|缩放系数/形式|
|---|---|
|first_clear_gold|[-0.68511866534496, 0.5201332531526064]；existing authored per-level values × exp(a+b*(L-1)/98)|
|kill_gold_mult|[-0.14707096606716982, -0.2665867356870846]；existing authored per-level values × exp(a+b*(L-1)/98)|
|free_unlock_star|1.1156719433829532；existing free star tiers × constant|
|skill_base_xp_costs|[1.1668580130381552, 0.8087420993944441, 0.7837475735643928, 0.7315785650844565, 0.5664309064353039]；same five authored cost tiers times positive monotone factors|
|sig_skill_xp_costs|[0.5628211001586663, 0.8450797732574385, 0.897576428934345, 1.91379330269167, 1.9940242696248345]；same five authored cost tiers times positive monotone factors|
|weapon_cost.weapon_autocannon|1.4278362551246069；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_flamethrower|0.9868800230227343；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_cryocannon|0.834362245985325；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_teslacoil|1.4908878220565747；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_venomlauncher|1.3302331732210815；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_railgun|0.5074943200499934；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_scattergun|1.473101319031576；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_plasmacannon|0.6758086049938121；same existing linear upgrade formula × constant base cost|

|文件/字段|旧值|候选新值|系数|
|---|---:|---:|---:|
|data/levels.json/0/first_clear_reward/gold|119|60|0.50403042|
|data/levels.json/1/first_clear_reward/gold|143|72|0.50671266|
|data/levels.json/2/first_clear_reward/gold|167|85|0.50940918|
|data/levels.json/3/first_clear_reward/gold|192|98|0.51212004|
|data/levels.json/4/first_clear_reward/gold|216|111|0.51484534|
|data/levels.json/5/first_clear_reward/gold|241|125|0.51758514|
|data/levels.json/6/first_clear_reward/gold|266|138|0.52033951|
|data/levels.json/7/first_clear_reward/gold|291|152|0.52310855|
|data/levels.json/8/first_clear_reward/gold|315|166|0.52589232|
|data/levels.json/9/first_clear_reward/gold|340|180|0.5286909|
|data/levels.json/10/first_clear_reward/gold|366|195|0.53150438|
|data/levels.json/11/first_clear_reward/gold|391|209|0.53433283|
|data/levels.json/12/first_clear_reward/gold|416|223|0.53717633|
|data/levels.json/13/first_clear_reward/gold|442|239|0.54003496|
|data/levels.json/14/first_clear_reward/gold|467|254|0.54290881|
|data/levels.json/15/first_clear_reward/gold|493|269|0.54579795|
|data/levels.json/16/first_clear_reward/gold|519|285|0.54870246|
|data/levels.json/17/first_clear_reward/gold|545|301|0.55162243|
|data/levels.json/18/first_clear_reward/gold|571|317|0.55455794|
|data/levels.json/19/first_clear_reward/gold|597|333|0.55750907|
|data/levels.json/20/first_clear_reward/gold|623|349|0.56047591|
|data/levels.json/21/first_clear_reward/gold|650|366|0.56345853|
|data/levels.json/22/first_clear_reward/gold|676|383|0.56645703|
|data/levels.json/23/first_clear_reward/gold|703|400|0.56947148|
|data/levels.json/24/first_clear_reward/gold|729|417|0.57250198|
|data/levels.json/25/first_clear_reward/gold|756|435|0.5755486|
|data/levels.json/26/first_clear_reward/gold|783|453|0.57861143|
|data/levels.json/27/first_clear_reward/gold|810|471|0.58169057|
|data/levels.json/28/first_clear_reward/gold|837|489|0.58478609|
|data/levels.json/29/first_clear_reward/gold|864|508|0.58789808|
|data/levels.json/30/first_clear_reward/gold|892|527|0.59102663|
|data/levels.json/31/first_clear_reward/gold|919|546|0.59417183|
|data/levels.json/32/first_clear_reward/gold|947|566|0.59733377|
|data/levels.json/33/first_clear_reward/gold|975|585|0.60051254|
|data/levels.json/34/first_clear_reward/gold|1002|605|0.60370822|
|data/levels.json/35/first_clear_reward/gold|1030|625|0.60692091|
|data/levels.json/36/first_clear_reward/gold|1058|646|0.6101507|
|data/levels.json/37/first_clear_reward/gold|1086|666|0.61339767|
|data/levels.json/38/first_clear_reward/gold|1115|688|0.61666192|
|data/levels.json/39/first_clear_reward/gold|1143|709|0.61994355|
|data/levels.json/40/first_clear_reward/gold|1171|730|0.62324263|
|data/levels.json/41/first_clear_reward/gold|1200|752|0.62655928|
|data/levels.json/42/first_clear_reward/gold|1229|774|0.62989357|
|data/levels.json/43/first_clear_reward/gold|1257|796|0.6332456|
|data/levels.json/44/first_clear_reward/gold|1286|819|0.63661548|
|data/levels.json/45/first_clear_reward/gold|1315|842|0.64000329|
|data/levels.json/46/first_clear_reward/gold|1344|865|0.64340912|
|data/levels.json/47/first_clear_reward/gold|1374|889|0.64683308|
|data/levels.json/48/first_clear_reward/gold|1403|912|0.65027527|
|data/levels.json/49/first_clear_reward/gold|1432|936|0.65373576|
|data/levels.json/50/first_clear_reward/gold|1462|961|0.65721468|
|data/levels.json/51/first_clear_reward/gold|1492|986|0.66071211|
|data/levels.json/52/first_clear_reward/gold|1521|1010|0.66422815|
|data/levels.json/53/first_clear_reward/gold|1551|1036|0.6677629|
|data/levels.json/54/first_clear_reward/gold|1581|1061|0.67131646|
|data/levels.json/55/first_clear_reward/gold|1611|1087|0.67488893|
|data/levels.json/56/first_clear_reward/gold|1642|1114|0.67848042|
|data/levels.json/57/first_clear_reward/gold|1672|1140|0.68209101|
|data/levels.json/58/first_clear_reward/gold|1702|1167|0.68572082|
|data/levels.json/59/first_clear_reward/gold|1733|1195|0.68936995|
|data/levels.json/60/first_clear_reward/gold|1764|1223|0.69303849|
|data/levels.json/61/first_clear_reward/gold|1794|1250|0.69672656|
|data/levels.json/62/first_clear_reward/gold|1825|1278|0.70043426|
|data/levels.json/63/first_clear_reward/gold|1856|1307|0.70416168|
|data/levels.json/64/first_clear_reward/gold|1887|1336|0.70790894|
|data/levels.json/65/first_clear_reward/gold|1919|1366|0.71167614|
|data/levels.json/66/first_clear_reward/gold|1950|1395|0.71546339|
|data/levels.json/67/first_clear_reward/gold|1981|1425|0.7192708|
|data/levels.json/68/first_clear_reward/gold|2013|1456|0.72309846|
|data/levels.json/69/first_clear_reward/gold|2044|1486|0.7269465|
|data/levels.json/70/first_clear_reward/gold|2076|1517|0.73081501|
|data/levels.json/71/first_clear_reward/gold|2108|1549|0.73470411|
|data/levels.json/72/first_clear_reward/gold|2140|1581|0.73861391|
|data/levels.json/73/first_clear_reward/gold|2172|1613|0.74254451|
|data/levels.json/74/first_clear_reward/gold|2204|1645|0.74649603|
|data/levels.json/75/first_clear_reward/gold|2237|1679|0.75046857|
|data/levels.json/76/first_clear_reward/gold|2269|1712|0.75446226|
|data/levels.json/77/first_clear_reward/gold|2302|1746|0.7584772|
|data/levels.json/78/first_clear_reward/gold|2334|1780|0.76251351|
|data/levels.json/79/first_clear_reward/gold|2367|1814|0.76657129|
|data/levels.json/80/first_clear_reward/gold|2400|1850|0.77065067|
|data/levels.json/81/first_clear_reward/gold|2433|1885|0.77475176|
|data/levels.json/82/first_clear_reward/gold|2466|1921|0.77887467|
|data/levels.json/83/first_clear_reward/gold|2499|1957|0.78301953|
|data/levels.json/84/first_clear_reward/gold|2532|1993|0.78718644|
|data/levels.json/85/first_clear_reward/gold|2566|2031|0.79137552|
|data/levels.json/86/first_clear_reward/gold|2599|2068|0.7955869|
|data/levels.json/87/first_clear_reward/gold|2633|2106|0.79982069|
|data/levels.json/88/first_clear_reward/gold|2667|2144|0.80407701|
|data/levels.json/89/first_clear_reward/gold|2700|2183|0.80835598|
|data/levels.json/90/first_clear_reward/gold|2734|2222|0.81265772|
|data/levels.json/91/first_clear_reward/gold|2769|2262|0.81698235|
|data/levels.json/92/first_clear_reward/gold|2803|2302|0.82133|
|data/levels.json/93/first_clear_reward/gold|2837|2343|0.82570078|
|data/levels.json/94/first_clear_reward/gold|2871|2383|0.83009482|
|data/levels.json/95/first_clear_reward/gold|2906|2425|0.83451225|
|data/levels.json/96/first_clear_reward/gold|2940|2467|0.83895318|
|data/levels.json/97/first_clear_reward/gold|2975|2509|0.84341775|
|data/levels.json/98/first_clear_reward/gold|3010|2552|0.84790607|
|data/levels.json/0/reward_gold_mult|0.56|0.48341032|0.86323272|
|data/levels.json/1/reward_gold_mult|0.55|0.47348822|0.86088768|
|data/levels.json/2/reward_gold_mult|0.55|0.47220196|0.85854901|
|data/levels.json/3/reward_gold_mult|0.55|0.47091918|0.8562167|
|data/levels.json/4/reward_gold_mult|0.54|0.46110099|0.85389072|
|data/levels.json/5/reward_gold_mult|0.54|0.45984837|0.85157106|
|data/levels.json/6/reward_gold_mult|0.53|0.45010658|0.8492577|
|data/levels.json/7/reward_gold_mult|0.53|0.44888383|0.84695063|
|data/levels.json/8/reward_gold_mult|0.53|0.44766441|0.84464982|
|data/levels.json/9/reward_gold_mult|0.52|0.43802474|0.84235527|
|data/levels.json/10/reward_gold_mult|0.52|0.43683481|0.84006694|
|data/levels.json/11/reward_gold_mult|0.52|0.43564812|0.83778484|
|data/levels.json/12/reward_gold_mult|0.51|0.42610956|0.83550893|
|data/levels.json/13/reward_gold_mult|0.51|0.424952|0.83323921|
|data/levels.json/14/reward_gold_mult|0.51|0.42379758|0.83097565|
|data/levels.json/15/reward_gold_mult|0.5|0.41435912|0.82871824|
|data/levels.json/16/reward_gold_mult|0.5|0.41323348|0.82646697|
|data/levels.json/17/reward_gold_mult|0.5|0.4121109|0.82422181|
|data/levels.json/18/reward_gold_mult|0.49|0.40277154|0.82198274|
|data/levels.json/19/reward_gold_mult|0.49|0.40167739|0.81974977|
|data/levels.json/20/reward_gold_mult|0.48|0.39241097|0.81752285|
|data/levels.json/21/reward_gold_mult|0.48|0.39134495|0.81530199|
|data/levels.json/22/reward_gold_mult|0.48|0.39028184|0.81308716|
|data/levels.json/23/reward_gold_mult|0.47|0.38111282|0.81087835|
|data/levels.json/24/reward_gold_mult|0.47|0.3800775|0.80867553|
|data/levels.json/25/reward_gold_mult|0.47|0.37904499|0.8064787|
|data/levels.json/26/reward_gold_mult|0.46|0.36997241|0.80428784|
|data/levels.json/27/reward_gold_mult|0.46|0.36896735|0.80210293|
|data/levels.json/28/reward_gold_mult|0.46|0.36796502|0.79992396|
|data/levels.json/29/reward_gold_mult|0.45|0.35898791|0.79775091|
|data/levels.json/30/reward_gold_mult|0.45|0.35801269|0.79558376|
|data/levels.json/31/reward_gold_mult|0.44|0.3491059|0.79342249|
|data/levels.json/32/reward_gold_mult|0.44|0.34815752|0.7912671|
|data/levels.json/33/reward_gold_mult|0.44|0.34721173|0.78911756|
|data/levels.json/34/reward_gold_mult|0.43|0.33839876|0.78697386|
|data/levels.json/35/reward_gold_mult|0.43|0.33747948|0.78483599|
|data/levels.json/36/reward_gold_mult|0.43|0.33656269|0.78270392|
|data/levels.json/37/reward_gold_mult|0.42|0.32784261|0.78057765|
|data/levels.json/38/reward_gold_mult|0.42|0.326952|0.77845715|
|data/levels.json/39/reward_gold_mult|0.42|0.32606381|0.77634241|
|data/levels.json/40/reward_gold_mult|0.41|0.3174357|0.77423342|
|data/levels.json/41/reward_gold_mult|0.41|0.31657336|0.77213015|
|data/levels.json/42/reward_gold_mult|0.41|0.31571337|0.7700326|
|data/levels.json/43/reward_gold_mult|0.4|0.3071763|0.76794075|
|data/levels.json/44/reward_gold_mult|0.4|0.30634183|0.76585458|
|data/levels.json/45/reward_gold_mult|0.39|0.29787189|0.76377408|
|data/levels.json/46/reward_gold_mult|0.39|0.2970627|0.76169923|
|data/levels.json/47/reward_gold_mult|0.39|0.29625571|0.75963001|
|data/levels.json/48/reward_gold_mult|0.38|0.28787524|0.75756642|
|data/levels.json/49/reward_gold_mult|0.38|0.2870932|0.75550843|
|data/levels.json/50/reward_gold_mult|0.38|0.28631329|0.75345604|
|data/levels.json/51/reward_gold_mult|0.37|0.27802141|0.75140922|
|data/levels.json/52/reward_gold_mult|0.37|0.27726614|0.74936796|
|data/levels.json/53/reward_gold_mult|0.37|0.27651293|0.74733224|
|data/levels.json/54/reward_gold_mult|0.36|0.26830874|0.74530206|
|data/levels.json/55/reward_gold_mult|0.36|0.26757986|0.74327739|
|data/levels.json/56/reward_gold_mult|0.35|0.25944038|0.74125822|
|data/levels.json/57/reward_gold_mult|0.35|0.25873559|0.73924453|
|data/levels.json/58/reward_gold_mult|0.35|0.25803271|0.73723632|
|data/levels.json/59/reward_gold_mult|0.34|0.24997941|0.73523356|
|data/levels.json/60/reward_gold_mult|0.34|0.24930032|0.73323624|
|data/levels.json/61/reward_gold_mult|0.34|0.24862308|0.73124435|
|data/levels.json/62/reward_gold_mult|0.33|0.2406551|0.72925787|
|data/levels.json/63/reward_gold_mult|0.33|0.24000134|0.72727678|
|data/levels.json/64/reward_gold_mult|0.33|0.23934936|0.72530108|
|data/levels.json/65/reward_gold_mult|0.32|0.23146584|0.72333075|
|data/levels.json/66/reward_gold_mult|0.32|0.23083704|0.72136576|
|data/levels.json/67/reward_gold_mult|0.32|0.23020996|0.71940612|
|data/levels.json/68/reward_gold_mult|0.31|0.22241006|0.7174518|
|data/levels.json/69/reward_gold_mult|0.31|0.22180586|0.71550278|
|data/levels.json/70/reward_gold_mult|0.3|0.21406772|0.71355907|
|data/levels.json/71/reward_gold_mult|0.3|0.21348619|0.71162063|
|data/levels.json/72/reward_gold_mult|0.3|0.21290624|0.70968746|
|data/levels.json/73/reward_gold_mult|0.29|0.20525027|0.70775954|
|data/levels.json/74/reward_gold_mult|0.29|0.20469269|0.70583685|
|data/levels.json/75/reward_gold_mult|0.29|0.20413662|0.70391939|
|data/levels.json/76/reward_gold_mult|0.28|0.196562|0.70200714|
|data/levels.json/77/reward_gold_mult|0.28|0.19602802|0.70010009|
|data/levels.json/78/reward_gold_mult|0.28|0.1954955|0.69819821|
|data/levels.json/79/reward_gold_mult|0.27|0.18800141|0.6963015|
|data/levels.json/80/reward_gold_mult|0.27|0.18749069|0.69440995|
|data/levels.json/81/reward_gold_mult|0.26|0.18005612|0.69252353|
|data/levels.json/82/reward_gold_mult|0.26|0.17956698|0.69064224|
|data/levels.json/83/reward_gold_mult|0.26|0.17907917|0.68876605|
|data/levels.json/84/reward_gold_mult|0.26|0.17859269|0.68689497|
|data/levels.json/85/reward_gold_mult|0.26|0.17810753|0.68502897|
|data/levels.json/86/reward_gold_mult|0.26|0.17762369|0.68316803|
|data/levels.json/87/reward_gold_mult|0.26|0.17714116|0.68131215|
|data/levels.json/88/reward_gold_mult|0.26|0.17665994|0.67946132|
|data/levels.json/89/reward_gold_mult|0.26|0.17618003|0.67761551|
|data/levels.json/90/reward_gold_mult|0.26|0.17570143|0.67577472|
|data/levels.json/91/reward_gold_mult|0.26|0.17522412|0.67393892|
|data/levels.json/92/reward_gold_mult|0.26|0.17474811|0.67210812|
|data/levels.json/93/reward_gold_mult|0.26|0.17427339|0.67028228|
|data/levels.json/94/reward_gold_mult|0.26|0.17379997|0.66846141|
|data/levels.json/95/reward_gold_mult|0.26|0.17332783|0.66664548|
|data/levels.json/96/reward_gold_mult|0.26|0.17285697|0.66483449|
|data/levels.json/97/reward_gold_mult|0.26|0.17238739|0.66302842|
|data/levels.json/98/reward_gold_mult|0.26|0.17191908|0.66122725|
|data/weapons.json/weapon_flamethrower/unlock_cost_star|8|9|1.1156719|
|data/weapons.json/weapon_cryocannon/unlock_cost_star|8|9|1.1156719|
|data/weapons.json/weapon_teslacoil/unlock_cost_star|10|11|1.1156719|
|data/weapons.json/weapon_venomlauncher/unlock_cost_star|8|9|1.1156719|
|data/weapons.json/weapon_railgun/unlock_cost_star|14|16|1.1156719|
|data/weapons.json/weapon_scattergun/unlock_cost_star|9|10|1.1156719|
|data/weapons.json/weapon_plasmacannon/unlock_cost_star|16|18|1.1156719|
|data/armors.json/armor_kevlar/unlock_cost_star|8|9|1.1156719|
|data/armors.json/armor_thermal/unlock_cost_star|8|9|1.1156719|
|data/armors.json/armor_cryo/unlock_cost_star|9|10|1.1156719|
|data/armors.json/armor_faraday/unlock_cost_star|10|11|1.1156719|
|data/armors.json/armor_hazmat/unlock_cost_star|11|12|1.1156719|
|data/armors.json/armor_reactive/unlock_cost_star|14|16|1.1156719|
|data/chips.json/chip_attack/unlock_cost_star|8|9|1.1156719|
|data/chips.json/chip_haste/unlock_cost_star|8|9|1.1156719|
|data/chips.json/chip_crit/unlock_cost_star|9|10|1.1156719|
|data/chips.json/chip_pierce/unlock_cost_star|11|12|1.1156719|
|data/chips.json/chip_health/unlock_cost_star|9|10|1.1156719|
|data/chips.json/chip_guardian/unlock_cost_star|10|11|1.1156719|
|data/chips.json/chip_greed/unlock_cost_star|11|12|1.1156719|
|data/chips.json/chip_element/unlock_cost_star|14|16|1.1156719|
|data/pets.json/pet_turret_drone/unlock_cost_star|8|9|1.1156719|
|data/pets.json/pet_fire_imp/unlock_cost_star|9|10|1.1156719|
|data/pets.json/pet_frost_wisp/unlock_cost_star|10|11|1.1156719|
|data/pets.json/pet_volt_orb/unlock_cost_star|11|12|1.1156719|
|data/pets.json/pet_medic_drone/unlock_cost_star|13|15|1.1156719|
|data/pets.json/pet_collector/unlock_cost_star|14|16|1.1156719|
|data/economy.json/skill_base_xp_costs/0|350|408|1.166858|
|data/economy.json/skill_base_xp_costs/1|900|728|0.8087421|
|data/economy.json/skill_base_xp_costs/2|2000|1567|0.78374757|
|data/economy.json/skill_base_xp_costs/3|4000|2926|0.73157857|
|data/economy.json/skill_base_xp_costs/4|8500|4815|0.56643091|
|data/economy.json/sig_skill_xp_costs/0|450|253|0.5628211|
|data/economy.json/sig_skill_xp_costs/1|1200|1014|0.84507977|
|data/economy.json/sig_skill_xp_costs/2|2700|2423|0.89757643|
|data/economy.json/sig_skill_xp_costs/3|5400|10334|1.9137933|
|data/economy.json/sig_skill_xp_costs/4|11000|21934|1.9940243|
|data/weapons.json/weapon_autocannon/cost_base_gold|100|143|1.4278363|
|data/weapons.json/weapon_flamethrower/cost_base_gold|180|178|0.98688002|
|data/weapons.json/weapon_cryocannon/cost_base_gold|180|150|0.83436225|
|data/weapons.json/weapon_teslacoil/cost_base_gold|240|358|1.4908878|
|data/weapons.json/weapon_venomlauncher/cost_base_gold|240|319|1.3302332|
|data/weapons.json/weapon_railgun/cost_base_gold|320|162|0.50749432|
|data/weapons.json/weapon_scattergun/cost_base_gold|180|265|1.4731013|
|data/weapons.json/weapon_plasmacannon/cost_base_gold|320|216|0.6758086|

|关卡|rec|E|旧P|新P|新R|新P/E|下限|上限|达标|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
|001|50|65|65|65|1.3000|1.0000|48|71|True|
|002|50|65|69|67|1.3400|1.0308|48|71|True|
|003|50|65|73|71|1.4200|1.0923|48|71|True|
|004|64|65|74|73|1.1406|1.1231|61|71|False|
|005|76|76|81|76|1.0000|1.0000|76|83|True|
|006|53|76|82|83|1.5660|1.0921|51|83|True|
|007|53|76|89|86|1.6226|1.1316|53|83|False|
|008|79|79|96|90|1.1392|1.1392|79|86|False|
|009|79|79|106|93|1.1772|1.1772|79|86|False|
|010|87|87|112|101|1.1609|1.1609|87|95|False|
|011|99|99|116|105|1.0606|1.0606|95|108|True|
|012|108|108|122|111|1.0278|1.0278|103|118|True|
|013|131|131|131|125|0.9542|0.9542|125|144|True|
|014|138|138|141|150|1.0870|1.0870|132|151|True|
|015|147|147|151|156|1.0612|1.0612|147|161|True|
|016|98|147|152|156|1.5918|1.0612|94|161|True|
|017|165|165|166|178|1.0788|1.0788|165|181|True|
|018|185|185|185|184|0.9946|0.9946|185|203|False|
|019|188|188|191|186|0.9894|0.9894|188|206|False|
|020|291|291|294|189|0.6495|0.6495|291|320|False|
|021|164|291|296|193|1.1768|0.6632|156|320|True|
|022|183|291|299|193|1.0546|0.6632|174|320|True|
|023|186|291|302|196|1.0538|0.6735|177|320|True|
|024|201|291|306|201|1.0000|0.6907|191|320|True|
|025|260|291|306|208|0.8000|0.7148|260|320|False|
|026|226|291|348|209|0.9248|0.7182|215|320|False|
|027|195|291|410|209|1.0718|0.7182|195|320|True|
|028|231|291|412|306|1.3247|1.0515|231|320|True|
|029|206|291|414|309|1.5000|1.0619|206|320|True|
|030|332|332|415|314|0.9458|0.9458|332|365|False|
|031|159|332|417|317|1.9937|0.9548|152|365|True|
|032|245|332|418|353|1.4408|1.0633|233|365|True|
|033|228|332|418|366|1.6053|1.1024|217|365|False|
|034|330|332|520|366|1.1091|1.1024|314|365|False|
|035|219|332|565|377|1.7215|1.1355|219|365|False|
|036|225|332|565|377|1.6756|1.1355|214|365|False|
|037|232|332|574|383|1.6509|1.1536|232|365|False|
|038|484|484|581|494|1.0207|1.0207|484|532|True|
|039|533|533|582|536|1.0056|1.0056|533|586|True|
|040|574|574|657|574|1.0000|1.0000|574|631|True|
|041|236|574|696|589|2.4958|1.0261|225|631|True|
|042|375|574|716|607|1.6187|1.0575|357|631|True|
|043|587|587|716|607|1.0341|1.0341|558|645|True|
|044|757|757|756|703|0.9287|0.9287|720|832|False|
|045|655|757|828|790|1.2061|1.0436|655|832|True|
|046|600|757|951|841|1.4017|1.1110|570|832|False|
|047|670|757|951|847|1.2642|1.1189|670|832|False|
|048|663|757|953|870|1.3122|1.1493|663|832|False|
|049|658|757|959|894|1.3587|1.1810|658|832|False|
|050|868|868|968|934|1.0760|1.0760|868|954|True|
|051|431|868|1021|948|2.1995|1.0922|410|954|True|
|052|349|868|1021|965|2.7650|1.1118|332|954|False|
|053|427|868|1035|965|2.2600|1.1118|406|954|False|
|054|359|868|1045|965|2.6880|1.1118|342|954|False|
|055|950|950|1045|965|1.0158|1.0158|950|1045|True|
|056|354|950|1045|965|2.7260|1.0158|337|1045|True|
|057|990|990|1186|986|0.9960|0.9960|990|1089|False|
|058|503|990|1193|986|1.9602|0.9960|503|1089|True|
|059|562|990|1258|986|1.7544|0.9960|562|1089|True|
|060|990|990|1258|986|0.9960|0.9960|990|1089|False|
|061|990|990|1300|986|0.9960|0.9960|941|1089|True|
|062|250|990|1381|986|3.9440|0.9960|238|1089|True|
|063|576|990|1387|986|1.7118|0.9960|548|1089|True|
|064|955|990|1387|1018|1.0660|1.0283|908|1089|True|
|065|1014|1014|1387|1018|1.0039|1.0039|1014|1115|True|
|066|1184|1184|1552|1214|1.0253|1.0253|1125|1302|True|
|067|955|1184|1558|1214|1.2712|1.0253|955|1302|True|
|068|1042|1184|1811|1214|1.1651|1.0253|1042|1302|True|
|069|978|1184|1811|1214|1.2413|1.0253|978|1302|True|
|070|1286|1286|2204|1250|0.9720|0.9720|1286|1414|False|
|071|1146|1286|2204|1250|1.0908|0.9720|1089|1414|True|
|072|1576|1576|2204|1757|1.1148|1.1148|1498|1733|False|
|073|818|1576|2301|1757|2.1479|1.1148|778|1733|False|
|074|2034|2034|2301|2001|0.9838|0.9838|1933|2237|True|
|075|1841|2034|2427|2001|1.0869|0.9838|1841|2237|True|
|076|2758|2758|2748|2001|0.7255|0.7255|2621|3033|False|
|077|1652|2758|2748|2010|1.2167|0.7288|1652|3033|True|
|078|2226|2758|3016|2010|0.9030|0.7288|2226|3033|False|
|079|2030|2758|3177|2026|0.9980|0.7346|2030|3033|False|
|080|2067|2758|3177|2026|0.9802|0.7346|2067|3033|False|
|081|1096|2758|3238|2026|1.8485|0.7346|1042|3033|True|
|082|1762|2758|3274|2035|1.1549|0.7379|1674|3033|True|
|083|1815|2758|3274|2052|1.1306|0.7440|1725|3033|True|
|084|1265|2758|3282|2052|1.6221|0.7440|1202|3033|True|
|085|2204|2758|3282|2216|1.0054|0.8035|2204|3033|True|
|086|1855|2758|3536|2216|1.1946|0.8035|1763|3033|True|
|087|1857|2758|3637|2292|1.2342|0.8310|1857|3033|True|
|088|1857|2758|3720|2292|1.2342|0.8310|1857|3033|True|
|089|1994|2758|3911|2707|1.3576|0.9815|1994|3033|True|
|090|2751|2758|3988|3011|1.0945|1.0917|2751|3033|True|
|091|1234|2758|3988|3011|2.4400|1.0917|1173|3033|True|
|092|1862|2758|4090|3011|1.6171|1.0917|1769|3033|True|
|093|2266|2758|4393|3211|1.4170|1.1642|2153|3033|False|
|094|1830|2758|4395|3211|1.7546|1.1642|1739|3033|False|
|095|3370|3370|5022|3315|0.9837|0.9837|3370|3707|False|
|096|2429|3370|5090|3389|1.3952|1.0056|2308|3707|True|
|097|1863|3370|5098|3389|1.8191|1.0056|1863|3707|True|
|098|2720|3370|5230|3389|1.2460|1.0056|2720|3707|True|
|099|3094|3370|5230|3389|1.0953|1.0056|3094|3707|True|

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

首次R<0.95：20；G1走廊不满足关数：36/99。

包络目标Σ|P−E|/E：10.413108。

回刷总数：53；各章：{1: 1, 2: 6, 3: 6, 4: 6, 5: 6, 6: 6, 7: 6, 8: 6, 9: 4, 10: 6}；墙过高/预算内未满足下限：[18, 19, 20, 25, 26, 30, 44, 57, 60, 70, 76, 78, 79, 80, 95]。

|回刷门|前一关|入门P|回刷后P|次数|章累计|下限满足|八墙关|
|---|---:|---:|---:|---:|---:|---|---|
|005|4|75|76|1|1|True|False|
|013|12|115|125|5|5|True|False|
|017|16|158|178|1|6|True|True|
|018|17|184|184|0|6|False|True|
|019|18|186|186|0|6|False|True|
|020|19|189|189|0|6|False|True|
|025|24|205|208|6|6|False|False|
|026|25|209|209|0|6|False|False|
|030|29|314|314|0|6|False|False|
|038|37|428|494|3|3|True|False|
|039|38|494|536|2|5|True|False|
|040|39|549|574|1|6|True|True|
|044|43|636|703|6|6|False|True|
|057|56|965|986|6|6|False|False|
|060|59|986|986|0|6|False|False|
|066|65|1064|1214|3|3|True|False|
|070|69|1250|1250|3|6|False|False|
|072|71|1250|1757|1|1|True|False|
|074|73|1757|2001|5|6|True|False|
|076|75|2001|2001|0|6|False|True|
|078|77|2010|2010|0|6|False|False|
|079|78|2026|2026|0|6|False|False|
|080|79|2026|2026|0|6|False|False|
|085|84|2052|2216|1|1|True|False|
|090|89|2727|3011|3|4|True|False|
|095|94|3211|3315|6|6|False|False|

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|回刷至R≥1|
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|
|001|0|65|50|1.3000|65|1.0000|384|vanguard 1→2; weapon_autocannon 1→2|不可恢复/未收敛|
|002|384|67|50|1.3400|65|1.0308|499|vanguard 2→3; weapon_autocannon 2→3; skill_multishot 0→1|不可恢复/未收敛|
|003|883|71|50|1.4200|65|1.0923|568|weapon_cryocannon; weapon_autocannon 3→4; weapon_cryocannon 1→2; skill_pierce 0→1|不可恢复/未收敛|
|004|1451|73|64|1.1406|65|1.1231|680|weapon_autocannon 4→5; weapon_cryocannon 2→3; skill_homing 0→1; signature 0→1|不可恢复/未收敛|
|005|2713|76|76|1.0000|76|1.0000|831|vanguard 3→4; weapon_autocannon 6→7; skill_barrier 0→1|不可恢复/未收敛|
|006|3544|83|53|1.5660|76|1.0921|935|armor_kevlar; armor_kevlar 1→4; weapon_cryocannon 3→4; skill_salvo 0→1|不可恢复/未收敛|
|007|4479|86|53|1.6226|76|1.1316|898|weapon_autocannon 7→8; skill_charge_shot 0→1; skill_slow_field 0→1|不可恢复/未收敛|
|008|5377|90|79|1.1392|79|1.1392|1212|weapon_autocannon 8→9; weapon_cryocannon 4→5; skill_split_shot 0→1|不可恢复/未收敛|
|009|6589|93|79|1.1772|79|1.1772|957|chip_attack; weapon_autocannon 9→10; skill_critical 0→1|不可恢复/未收敛|
|010|7546|101|87|1.1609|87|1.1609|944|chip_attack 1→4; vanguard 4→5; skill_ricochet 0→1|不可恢复/未收敛|
|011|8490|105|99|1.0606|99|1.0606|1395|chip_attack 4→5; weapon_autocannon 10→11; skill_multishot 1→2|不可恢复/未收敛|
|012|9885|111|108|1.0278|108|1.0278|1579|armor_kevlar 4→5; weapon_autocannon 11→12; skill_pierce 1→2|不可恢复/未收敛|
|013|18314|125|131|0.9542|131|0.9542|1627|weapon_scattergun; weapon_autocannon 16→17; weapon_scattergun 1→2; skill_barrier 1→2|不可恢复/未收敛|
|014|19941|150|138|1.0870|138|1.0870|1709|vanguard 6→7; weapon_scattergun 2→4; skill_salvo 1→2|不可恢复/未收敛|
|015|21650|156|147|1.0612|147|1.0612|1022|weapon_scattergun 4→5|不可恢复/未收敛|
|016|22672|156|98|1.5918|147|1.0612|2134|chip_attack 5→6; weapon_autocannon 17→18; skill_charge_shot 1→2|不可恢复/未收敛|
|017|26671|178|165|1.0788|165|1.0788|2131|weapon_autocannon 19→20; signature 1→2|不可恢复/未收敛|
|018|28802|184|185|0.9946|185|0.9946|1703|weapon_railgun; weapon_autocannon 20→21|不可恢复/未收敛|
|019|30505|186|188|0.9894|188|0.9894|2355|weapon_autocannon 21→22; weapon_railgun 1→2; skill_split_shot 1→2|不可恢复/未收敛|
|020|32860|189|291|0.6495|291|0.6495|2462|weapon_autocannon 22→23; weapon_railgun 2→3; skill_critical 1→2; skill_ricochet 1→2|不可恢复/未收敛|
|021|35322|193|164|1.1768|291|0.6632|2210|weapon_venomlauncher; weapon_railgun 3→4; weapon_venomlauncher 1→4|不可恢复/未收敛|
|022|37532|193|183|1.0546|291|0.6632|2433|weapon_autocannon 23→24|不可恢复/未收敛|
|023|39965|196|186|1.0538|291|0.6735|2754|weapon_cryocannon 6→7; weapon_railgun 4→6; weapon_venomlauncher 4→5; skill_multishot 2→3|不可恢复/未收敛|
|024|42719|201|201|1.0000|291|0.6907|2524|pet_turret_drone; pet_turret_drone 1→3; weapon_autocannon 24→25|不可恢复/未收敛|
|025|57987|208|260|0.8000|291|0.7148|1726|pet_turret_drone 4→5; weapon_scattergun 7→8; skill_homing 2→3|不可恢复/未收敛|
|026|59713|209|226|0.9248|291|0.7182|3053|chip_attack 7→8; weapon_autocannon 25→26|不可恢复/未收敛|
|027|62766|209|195|1.0718|291|0.7182|2788|weapon_autocannon 26→27; skill_barrier 2→3|不可恢复/未收敛|
|028|65554|306|231|1.3247|291|1.0515|2957|weapon_autocannon 27→28|不可恢复/未收敛|
|029|68511|309|206|1.5000|291|1.0619|3122|armor_kevlar 6→7; weapon_autocannon 28→29; skill_salvo 2→3|不可恢复/未收敛|
|030|71633|314|332|0.9458|332|0.9458|2406|pet_turret_drone 5→6; weapon_venomlauncher 8→9|不可恢复/未收敛|
|031|74039|317|159|1.9937|332|0.9548|3600|weapon_flamethrower; chip_attack 8→9; weapon_flamethrower 1→7; skill_charge_shot 2→3|不可恢复/未收敛|
|032|77639|353|245|1.4408|332|1.0633|3299|armor_kevlar 7→8; vanguard 8→9; weapon_flamethrower 7→9|不可恢复/未收敛|
|033|80938|366|228|1.6053|332|1.1024|3004|weapon_plasmacannon; weapon_flamethrower 9→10; weapon_plasmacannon 1→5; skill_slow_field 2→3|不可恢复/未收敛|
|034|83942|366|330|1.1091|332|1.1024|3736|chip_attack 9→10; weapon_flamethrower 10→11; weapon_plasmacannon 5→7|不可恢复/未收敛|
|035|87678|377|219|1.7215|332|1.1355|2740|weapon_plasmacannon 7→9; skill_split_shot 2→3|不可恢复/未收敛|
|036|90418|377|225|1.6756|332|1.1355|3709|pet_turret_drone 6→7; weapon_cryocannon 9→10; weapon_flamethrower 11→12; weapon_railgun 9→10; skill_critical 2→3|不可恢复/未收敛|
|037|94127|383|232|1.6509|332|1.1536|4200|vanguard 9→10; weapon_flamethrower 12→13; weapon_plasmacannon 9→10|不可恢复/未收敛|
|038|108989|494|484|1.0207|484|1.0207|4490|weapon_cryocannon 10→11; weapon_flamethrower 13→14; weapon_venomlauncher 9→10|不可恢复/未收敛|
|039|121127|536|533|1.0056|533|1.0056|3834|weapon_autocannon 34→35|不可恢复/未收敛|
|040|128107|574|574|1.0000|574|1.0000|5083|weapon_flamethrower 14→15; weapon_railgun 10→11; weapon_scattergun 8→9; skill_multishot 3→4|不可恢复/未收敛|
|041|133190|589|236|2.4958|574|1.0261|4918|weapon_teslacoil; weapon_autocannon 36→37; weapon_teslacoil 1→4|不可恢复/未收敛|
|042|138108|607|375|1.6187|574|1.0575|4513|weapon_teslacoil 4→7|不可恢复/未收敛|
|043|142621|607|587|1.0341|587|1.0341|5289|weapon_autocannon 37→38; weapon_teslacoil 7→8; skill_pierce 3→4|不可恢复/未收敛|
|044|175000|703|757|0.9287|757|0.9287|5020|armor_kevlar 10→11; weapon_autocannon 44→45|不可恢复/未收敛|
|045|180020|790|655|1.2061|757|1.0436|5252|pet_turret_drone 8→9; weapon_autocannon 45→46|不可恢复/未收敛|
|046|185272|841|600|1.4017|757|1.1110|4468|weapon_teslacoil 8→10; skill_barrier 3→4|不可恢复/未收敛|
|047|189740|847|670|1.2642|757|1.1189|4939|weapon_autocannon 46→47|不可恢复/未收敛|
|048|194679|870|663|1.3122|757|1.1493|5665|weapon_autocannon 47→48; weapon_cryocannon 11→12; skill_salvo 3→4|不可恢复/未收敛|
|049|200344|894|658|1.3587|757|1.1810|5642|weapon_autocannon 48→49|不可恢复/未收敛|
|050|205986|934|868|1.0760|868|1.0760|4161|weapon_autocannon 49→50|不可恢复/未收敛|
|051|210147|948|431|2.1995|868|1.0922|1746|weapon_plasmacannon 10→11; skill_charge_shot 3→4|不可恢复/未收敛|
|052|211893|965|349|2.7650|868|1.1118|1994|weapon_scattergun 9→10|不可恢复/未收敛|
|053|213887|965|427|2.2600|868|1.1118|1924|weapon_venomlauncher 10→11; skill_slow_field 3→4|不可恢复/未收敛|
|054|215811|965|359|2.6880|868|1.1118|1967|weapon_railgun 11→12|不可恢复/未收敛|
|055|217778|965|950|1.0158|950|1.0158|2009|weapon_teslacoil 10→11; skill_split_shot 3→4|不可恢复/未收敛|
|056|219787|965|354|2.7260|950|1.0158|1897|weapon_plasmacannon 11→12|不可恢复/未收敛|
|057|226544|986|990|0.9960|990|0.9960|3471|weapon_venomlauncher 11→12; skill_ricochet 3→4|不可恢复/未收敛|
|058|230015|986|503|1.9602|990|0.9960|2195|weapon_teslacoil 11→12|不可恢复/未收敛|
|059|232210|986|562|1.7544|990|0.9960|2132|weapon_scattergun 10→11|不可恢复/未收敛|
|060|234342|986|990|0.9960|990|0.9960|4630|weapon_cryocannon 12→13; weapon_plasmacannon 12→13; weapon_railgun 12→13|不可恢复/未收敛|
|061|238972|986|990|0.9960|990|0.9960|2688|weapon_venomlauncher 12→13|不可恢复/未收敛|
|062|241660|986|250|3.9440|990|0.9960|2732|weapon_teslacoil 12→13|不可恢复/未收敛|
|063|244392|986|576|1.7118|990|0.9960|2559|weapon_scattergun 11→12; signature 3→4|不可恢复/未收敛|
|064|246951|1018|955|1.0660|990|1.0283|2578|weapon_cryocannon 13→14; weapon_railgun 13→14|不可恢复/未收敛|
|065|249529|1018|1014|1.0039|1014|1.0039|3032|chip_attack 13→14; weapon_plasmacannon 13→14; skill_multishot 4→5|不可恢复/未收敛|
|066|257649|1214|1184|1.0253|1184|1.0253|2508|weapon_venomlauncher 13→14; skill_pierce 4→5|不可恢复/未收敛|
|067|260157|1214|955|1.2712|1184|1.0253|3388|weapon_teslacoil 13→14|不可恢复/未收敛|
|068|263545|1214|1042|1.1651|1184|1.0253|3117|armor_kevlar 12→13; weapon_scattergun 12→13|不可恢复/未收敛|
|069|266662|1214|978|1.2413|1184|1.0253|3244|chip_attack 14→15; weapon_plasmacannon 14→15; skill_homing 4→5|不可恢复/未收敛|
|070|275270|1250|1286|0.9720|1286|0.9720|3087|weapon_scattergun 13→14; skill_barrier 4→5|不可恢复/未收敛|
|071|278357|1250|1146|1.0908|1286|0.9720|2787|weapon_venomlauncher 14→15|不可恢复/未收敛|
|072|282414|1757|1576|1.1148|1576|1.1148|2641|weapon_plasmacannon 15→16; skill_salvo 4→5|不可恢复/未收敛|
|073|285055|1757|818|2.1479|1576|1.1148|2907|weapon_scattergun 14→15|不可恢复/未收敛|
|074|294592|2001|2034|0.9838|2034|0.9838|3498|weapon_venomlauncher 15→16; skill_slow_field 4→5|不可恢复/未收敛|
|075|298090|2001|1841|1.0869|2034|0.9838|3683|weapon_teslacoil 14→15|不可恢复/未收敛|
|076|301773|2001|2758|0.7255|2758|0.7255|3227|pet_turret_drone 10→11; weapon_railgun 16→17; skill_split_shot 4→5|不可恢复/未收敛|
|077|305000|2010|1652|1.2167|2758|0.7288|3638|weapon_teslacoil 15→16|不可恢复/未收敛|
|078|308638|2010|2226|0.9030|2758|0.7288|3350|chip_attack 16→17; weapon_flamethrower 16→17; skill_critical 4→5|不可恢复/未收敛|
|079|311988|2026|2030|0.9980|2758|0.7346|3670|armor_kevlar 14→15; weapon_plasmacannon 16→17|不可恢复/未收敛|
|080|315658|2026|2067|0.9802|2758|0.7346|4027|weapon_venomlauncher 16→17; skill_ricochet 4→5|不可恢复/未收敛|
|081|319685|2026|1096|1.8485|2758|0.7346|3202|pet_turret_drone 11→12; weapon_scattergun 15→16|不可恢复/未收敛|
|082|322887|2035|1762|1.1549|2758|0.7379|3213|chip_attack 17→18; weapon_cryocannon 17→18|不可恢复/未收敛|
|083|326100|2052|1815|1.1306|2758|0.7440|3829|weapon_cryocannon 18→19; weapon_railgun 17→18|不可恢复/未收敛|
|084|329929|2052|1265|1.6221|2758|0.7440|3295|armor_kevlar 15→16; weapon_flamethrower 17→18|不可恢复/未收敛|
|085|334562|2216|2204|1.0054|2758|0.8035|4506|weapon_teslacoil 16→17|不可恢复/未收敛|
|086|339068|2216|1855|1.1946|2758|0.8035|4267|vanguard 17→18; weapon_plasmacannon 17→18|不可恢复/未收敛|
|087|343335|2292|1857|1.2342|2758|0.8310|4148|weapon_venomlauncher 17→18|不可恢复/未收敛|
|088|347483|2292|1857|1.2342|2758|0.8310|3861|weapon_teslacoil 17→18; signature 4→5|不可恢复/未收敛|
|089|351344|2707|1994|1.3576|2758|0.9815|4206|pet_turret_drone 12→13; weapon_scattergun 16→17|不可恢复/未收敛|
|090|361736|3011|2751|1.0945|2758|1.0917|3629|armor_kevlar 16→17; weapon_flamethrower 18→19|不可恢复/未收敛|
|091|365365|3011|1234|2.4400|2758|1.0917|3581|weapon_plasmacannon 18→19|不可恢复/未收敛|
|092|368946|3011|1862|1.6171|2758|1.0917|5035|vanguard 19→20; weapon_venomlauncher 18→19|不可恢复/未收敛|
|093|373981|3211|2266|1.4170|2758|1.1642|4367|weapon_cryocannon 20→21; weapon_railgun 19→20|不可恢复/未收敛|
|094|378348|3211|1830|1.7546|2758|1.1642|4706|weapon_teslacoil 18→19|不可恢复/未收敛|
|095|397232|3315|3370|0.9837|3370|0.9837|4425|chip_attack 19→20; weapon_plasmacannon 19→20|不可恢复/未收敛|
|096|401657|3389|2429|1.3952|3370|1.0056|5770|armor_kevlar 17→18; weapon_venomlauncher 19→20|不可恢复/未收敛|
|097|407427|3389|1863|1.8191|3370|1.0056|5382|weapon_teslacoil 19→20|不可恢复/未收敛|
|098|412809|3389|2720|1.2460|3370|1.0056|5364|weapon_railgun 21→22; weapon_scattergun 17→18|不可恢复/未收敛|
|099|418173|3389|3094|1.0953|3370|1.0056|4744|vanguard 21→22; weapon_plasmacannon 20→21|不可恢复/未收敛|

