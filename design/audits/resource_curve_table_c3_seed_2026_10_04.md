状态：SEARCH_CANDIDATE_NOT_YET_FEASIBLE；待Fable签字，游戏数据未写入。

# 资源表 C 候选

§8.4离线假定3★首通，挑战首通优先；非门关每章最多6次，门关刷到R≥1、不限次数、照实列高度；全关P≤1.20E。不是运行时胜率。P(g)/F(g)与消费策略冻结，因子[0.5,2.0]；八把免费武器共用一个升级基价系数。
优化顺序：零硬约束失败 → 非门回刷次数 → Σ|P−E|/E。门次数完整披露，不参与第二目标。
优化前：69/99失败，目标36.608304。
优化后：5/99失败，目标8.449117。

缩放系数与逐字段旧/新对照完整列于同名JSON；所有候选仅在内存模拟。

|曲线|缩放系数/形式|
|---|---|
|first_clear_gold|[-0.6931471805599453, 0.38188733614460724]；existing authored per-level values × exp(a+b*(L-1)/98)|
|kill_gold_mult|[-0.4910044200090515, -0.2021427605508938]；existing authored per-level values × exp(a+b*(L-1)/98)|
|free_unlock_star|1.2451682810355265；existing free star tiers × constant|
|skill_base_xp_costs|[0.6623715678431924, 0.8562217224077878, 0.8723933608328281, 1.049694895593656, 1.1303891020402654]；same five authored cost tiers times positive monotone factors|
|sig_skill_xp_costs|[0.5153435217367096, 0.8266266896932006, 0.988975704299648, 0.9925952342232989, 1.0035285009048651]；same five authored cost tiers times positive monotone factors|
|free_weapon_cost|1.5408305000252898；all existing free linear upgrade formulas × ONE common base-price factor|

|文件/字段|旧值|候选新值|系数|
|---|---:|---:|---:|
|data/levels.json/0/first_clear_reward/gold|119|60|0.5|
|data/levels.json/1/first_clear_reward/gold|143|72|0.50195221|
|data/levels.json/2/first_clear_reward/gold|167|84|0.50391203|
|data/levels.json/3/first_clear_reward/gold|192|97|0.50587951|
|data/levels.json/4/first_clear_reward/gold|216|110|0.50785468|
|data/levels.json/5/first_clear_reward/gold|241|123|0.50983755|
|data/levels.json/6/first_clear_reward/gold|266|136|0.51182817|
|data/levels.json/7/first_clear_reward/gold|291|150|0.51382655|
|data/levels.json/8/first_clear_reward/gold|315|162|0.51583274|
|data/levels.json/9/first_clear_reward/gold|340|176|0.51784677|
|data/levels.json/10/first_clear_reward/gold|366|190|0.51986866|
|data/levels.json/11/first_clear_reward/gold|391|204|0.52189844|
|data/levels.json/12/first_clear_reward/gold|416|218|0.52393614|
|data/levels.json/13/first_clear_reward/gold|442|232|0.52598181|
|data/levels.json/14/first_clear_reward/gold|467|247|0.52803546|
|data/levels.json/15/first_clear_reward/gold|493|261|0.53009712|
|data/levels.json/16/first_clear_reward/gold|519|276|0.53216684|
|data/levels.json/17/first_clear_reward/gold|545|291|0.53424464|
|data/levels.json/18/first_clear_reward/gold|571|306|0.53633055|
|data/levels.json/19/first_clear_reward/gold|597|321|0.53842461|
|data/levels.json/20/first_clear_reward/gold|623|337|0.54052684|
|data/levels.json/21/first_clear_reward/gold|650|353|0.54263728|
|data/levels.json/22/first_clear_reward/gold|676|368|0.54475596|
|data/levels.json/23/first_clear_reward/gold|703|384|0.54688291|
|data/levels.json/24/first_clear_reward/gold|729|400|0.54901816|
|data/levels.json/25/first_clear_reward/gold|756|417|0.55116176|
|data/levels.json/26/first_clear_reward/gold|783|433|0.55331372|
|data/levels.json/27/first_clear_reward/gold|810|450|0.55547409|
|data/levels.json/28/first_clear_reward/gold|837|467|0.55764288|
|data/levels.json/29/first_clear_reward/gold|864|484|0.55982015|
|data/levels.json/30/first_clear_reward/gold|892|501|0.56200592|
|data/levels.json/31/first_clear_reward/gold|919|519|0.56420022|
|data/levels.json/32/first_clear_reward/gold|947|536|0.56640309|
|data/levels.json/33/first_clear_reward/gold|975|554|0.56861456|
|data/levels.json/34/first_clear_reward/gold|1002|572|0.57083467|
|data/levels.json/35/first_clear_reward/gold|1030|590|0.57306344|
|data/levels.json/36/first_clear_reward/gold|1058|609|0.57530092|
|data/levels.json/37/first_clear_reward/gold|1086|627|0.57754713|
|data/levels.json/38/first_clear_reward/gold|1115|646|0.57980211|
|data/levels.json/39/first_clear_reward/gold|1143|665|0.5820659|
|data/levels.json/40/first_clear_reward/gold|1171|684|0.58433852|
|data/levels.json/41/first_clear_reward/gold|1200|704|0.58662002|
|data/levels.json/42/first_clear_reward/gold|1229|724|0.58891043|
|data/levels.json/43/first_clear_reward/gold|1257|743|0.59120978|
|data/levels.json/44/first_clear_reward/gold|1286|763|0.5935181|
|data/levels.json/45/first_clear_reward/gold|1315|784|0.59583544|
|data/levels.json/46/first_clear_reward/gold|1344|804|0.59816183|
|data/levels.json/47/first_clear_reward/gold|1374|825|0.6004973|
|data/levels.json/48/first_clear_reward/gold|1403|846|0.60284189|
|data/levels.json/49/first_clear_reward/gold|1432|867|0.60519563|
|data/levels.json/50/first_clear_reward/gold|1462|888|0.60755857|
|data/levels.json/51/first_clear_reward/gold|1492|910|0.60993073|
|data/levels.json/52/first_clear_reward/gold|1521|931|0.61231215|
|data/levels.json/53/first_clear_reward/gold|1551|953|0.61470286|
|data/levels.json/54/first_clear_reward/gold|1581|976|0.61710292|
|data/levels.json/55/first_clear_reward/gold|1611|998|0.61951234|
|data/levels.json/56/first_clear_reward/gold|1642|1021|0.62193117|
|data/levels.json/57/first_clear_reward/gold|1672|1044|0.62435945|
|data/levels.json/58/first_clear_reward/gold|1702|1067|0.62679721|
|data/levels.json/59/first_clear_reward/gold|1733|1090|0.62924448|
|data/levels.json/60/first_clear_reward/gold|1764|1114|0.63170131|
|data/levels.json/61/first_clear_reward/gold|1794|1138|0.63416773|
|data/levels.json/62/first_clear_reward/gold|1825|1162|0.63664378|
|data/levels.json/63/first_clear_reward/gold|1856|1186|0.6391295|
|data/levels.json/64/first_clear_reward/gold|1887|1211|0.64162493|
|data/levels.json/65/first_clear_reward/gold|1919|1236|0.6441301|
|data/levels.json/66/first_clear_reward/gold|1950|1261|0.64664505|
|data/levels.json/67/first_clear_reward/gold|1981|1286|0.64916981|
|data/levels.json/68/first_clear_reward/gold|2013|1312|0.65170444|
|data/levels.json/69/first_clear_reward/gold|2044|1337|0.65424896|
|data/levels.json/70/first_clear_reward/gold|2076|1364|0.65680342|
|data/levels.json/71/first_clear_reward/gold|2108|1390|0.65936785|
|data/levels.json/72/first_clear_reward/gold|2140|1417|0.6619423|
|data/levels.json/73/first_clear_reward/gold|2172|1443|0.66452679|
|data/levels.json/74/first_clear_reward/gold|2204|1470|0.66712138|
|data/levels.json/75/first_clear_reward/gold|2237|1498|0.66972609|
|data/levels.json/76/first_clear_reward/gold|2269|1526|0.67234098|
|data/levels.json/77/first_clear_reward/gold|2302|1554|0.67496608|
|data/levels.json/78/first_clear_reward/gold|2334|1582|0.67760142|
|data/levels.json/79/first_clear_reward/gold|2367|1610|0.68024706|
|data/levels.json/80/first_clear_reward/gold|2400|1639|0.68290302|
|data/levels.json/81/first_clear_reward/gold|2433|1668|0.68556936|
|data/levels.json/82/first_clear_reward/gold|2466|1697|0.6882461|
|data/levels.json/83/first_clear_reward/gold|2499|1727|0.6909333|
|data/levels.json/84/first_clear_reward/gold|2532|1756|0.69363099|
|data/levels.json/85/first_clear_reward/gold|2566|1787|0.69633921|
|data/levels.json/86/first_clear_reward/gold|2599|1817|0.699058|
|data/levels.json/87/first_clear_reward/gold|2633|1848|0.70178741|
|data/levels.json/88/first_clear_reward/gold|2667|1879|0.70452748|
|data/levels.json/89/first_clear_reward/gold|2700|1910|0.70727825|
|data/levels.json/90/first_clear_reward/gold|2734|1941|0.71003975|
|data/levels.json/91/first_clear_reward/gold|2769|1974|0.71281204|
|data/levels.json/92/first_clear_reward/gold|2803|2006|0.71559515|
|data/levels.json/93/first_clear_reward/gold|2837|2038|0.71838913|
|data/levels.json/94/first_clear_reward/gold|2871|2071|0.72119402|
|data/levels.json/95/first_clear_reward/gold|2906|2104|0.72400986|
|data/levels.json/96/first_clear_reward/gold|2940|2137|0.72683669|
|data/levels.json/97/first_clear_reward/gold|2975|2171|0.72967456|
|data/levels.json/98/first_clear_reward/gold|3010|2205|0.73252351|
|data/levels.json/0/reward_gold_mult|0.56|0.34272637|0.61201137|
|data/levels.json/1/reward_gold_mult|0.55|0.33591266|0.61075029|
|data/levels.json/2/reward_gold_mult|0.55|0.33522049|0.6094918|
|data/levels.json/3/reward_gold_mult|0.55|0.33452975|0.60823591|
|data/levels.json/4/reward_gold_mult|0.54|0.32777061|0.60698261|
|data/levels.json/5/reward_gold_mult|0.54|0.32709522|0.60573188|
|data/levels.json/6/reward_gold_mult|0.53|0.32037638|0.60448374|
|data/levels.json/7/reward_gold_mult|0.53|0.31971623|0.60323817|
|data/levels.json/8/reward_gold_mult|0.53|0.31905744|0.60199516|
|data/levels.json/9/reward_gold_mult|0.52|0.31239245|0.60075472|
|data/levels.json/10/reward_gold_mult|0.52|0.31174875|0.59951683|
|data/levels.json/11/reward_gold_mult|0.52|0.31110638|0.59828149|
|data/levels.json/12/reward_gold_mult|0.51|0.30449484|0.5970487|
|data/levels.json/13/reward_gold_mult|0.51|0.30386741|0.59581845|
|data/levels.json/14/reward_gold_mult|0.51|0.30324127|0.59459073|
|data/levels.json/15/reward_gold_mult|0.5|0.29668277|0.59336554|
|data/levels.json/16/reward_gold_mult|0.5|0.29607144|0.59214288|
|data/levels.json/17/reward_gold_mult|0.5|0.29546137|0.59092274|
|data/levels.json/18/reward_gold_mult|0.49|0.2889555|0.58970511|
|data/levels.json/19/reward_gold_mult|0.49|0.28836009|0.58848999|
|data/levels.json/20/reward_gold_mult|0.48|0.28189314|0.58727737|
|data/levels.json/21/reward_gold_mult|0.48|0.28131228|0.58606726|
|data/levels.json/22/reward_gold_mult|0.48|0.28073262|0.58485963|
|data/levels.json/23/reward_gold_mult|0.47|0.27431761|0.5836545|
|data/levels.json/24/reward_gold_mult|0.47|0.27375237|0.58245184|
|data/levels.json/25/reward_gold_mult|0.47|0.27318828|0.58125167|
|data/levels.json/26/reward_gold_mult|0.46|0.26682483|0.58005397|
|data/levels.json/27/reward_gold_mult|0.46|0.26627502|0.57885873|
|data/levels.json/28/reward_gold_mult|0.46|0.26572634|0.57766596|
|data/levels.json/29/reward_gold_mult|0.45|0.25941404|0.57647565|
|data/levels.json/30/reward_gold_mult|0.45|0.25887951|0.57528779|
|data/levels.json/31/reward_gold_mult|0.44|0.25260505|0.57410238|
|data/levels.json/32/reward_gold_mult|0.44|0.25208454|0.57291941|
|data/levels.json/33/reward_gold_mult|0.44|0.25156511|0.57173888|
|data/levels.json/34/reward_gold_mult|0.43|0.24534113|0.57056078|
|data/levels.json/35/reward_gold_mult|0.43|0.2448356|0.56938511|
|data/levels.json/36/reward_gold_mult|0.43|0.2443311|0.56821186|
|data/levels.json/37/reward_gold_mult|0.42|0.23815723|0.56704102|
|data/levels.json/38/reward_gold_mult|0.42|0.23766649|0.5658726|
|data/levels.json/39/reward_gold_mult|0.42|0.23717677|0.56470659|
|data/levels.json/40/reward_gold_mult|0.41|0.23105262|0.56354298|
|data/levels.json/41/reward_gold_mult|0.41|0.23057653|0.56238177|
|data/levels.json/42/reward_gold_mult|0.41|0.23010141|0.56122295|
|data/levels.json/43/reward_gold_mult|0.4|0.22402661|0.56006652|
|data/levels.json/44/reward_gold_mult|0.4|0.22356499|0.55891247|
|data/levels.json/45/reward_gold_mult|0.39|0.21752671|0.5577608|
|data/levels.json/46/reward_gold_mult|0.39|0.21707849|0.55661151|
|data/levels.json/47/reward_gold_mult|0.39|0.21663119|0.55546458|
|data/levels.json/48/reward_gold_mult|0.38|0.2106416|0.55432001|
|data/levels.json/49/reward_gold_mult|0.38|0.21020757|0.55317781|
|data/levels.json/50/reward_gold_mult|0.38|0.20977442|0.55203795|
|data/levels.json/51/reward_gold_mult|0.37|0.20383317|0.55090045|
|data/levels.json/52/reward_gold_mult|0.37|0.20341316|0.54976529|
|data/levels.json/53/reward_gold_mult|0.37|0.20299401|0.54863246|
|data/levels.json/54/reward_gold_mult|0.36|0.19710071|0.54750198|
|data/levels.json/55/reward_gold_mult|0.36|0.19669457|0.54637382|
|data/levels.json/56/reward_gold_mult|0.35|0.19083679|0.54524799|
|data/levels.json/57/reward_gold_mult|0.35|0.19044357|0.54412447|
|data/levels.json/58/reward_gold_mult|0.35|0.19005115|0.54300327|
|data/levels.json/59/reward_gold_mult|0.34|0.18424069|0.54188438|
|data/levels.json/60/reward_gold_mult|0.34|0.18386105|0.5407678|
|data/levels.json/61/reward_gold_mult|0.34|0.1834822|0.53965352|
|data/levels.json/62/reward_gold_mult|0.33|0.17771871|0.53854153|
|data/levels.json/63/reward_gold_mult|0.33|0.17735251|0.53743184|
|data/levels.json/64/reward_gold_mult|0.33|0.17698706|0.53632443|
|data/levels.json/65/reward_gold_mult|0.32|0.17127018|0.53521931|
|data/levels.json/66/reward_gold_mult|0.32|0.17091727|0.53411646|
|data/levels.json/67/reward_gold_mult|0.32|0.17056508|0.53301588|
|data/levels.json/68/reward_gold_mult|0.31|0.16489445|0.53191757|
|data/levels.json/69/reward_gold_mult|0.31|0.16455467|0.53082153|
|data/levels.json/70/reward_gold_mult|0.3|0.15891832|0.52972774|
|data/levels.json/71/reward_gold_mult|0.3|0.15859086|0.5286362|
|data/levels.json/72/reward_gold_mult|0.3|0.15826408|0.52754692|
|data/levels.json/73/reward_gold_mult|0.29|0.15267337|0.52645988|
|data/levels.json/74/reward_gold_mult|0.29|0.15235877|0.52537508|
|data/levels.json/75/reward_gold_mult|0.29|0.15204483|0.52429252|
|data/levels.json/76/reward_gold_mult|0.28|0.14649941|0.52321218|
|data/levels.json/77/reward_gold_mult|0.28|0.14619754|0.52213408|
|data/levels.json/78/reward_gold_mult|0.28|0.14589629|0.52105819|
|data/levels.json/79/reward_gold_mult|0.27|0.14039582|0.51998452|
|data/levels.json/80/reward_gold_mult|0.27|0.14010653|0.51891306|
|data/levels.json/81/reward_gold_mult|0.26|0.13463939|0.51784381|
|data/levels.json/82/reward_gold_mult|0.26|0.13436196|0.51677677|
|data/levels.json/83/reward_gold_mult|0.26|0.1340851|0.51571192|
|data/levels.json/84/reward_gold_mult|0.26|0.13380881|0.51464927|
|data/levels.json/85/reward_gold_mult|0.26|0.13353309|0.5135888|
|data/levels.json/86/reward_gold_mult|0.26|0.13325794|0.51253053|
|data/levels.json/87/reward_gold_mult|0.26|0.13298335|0.51147443|
|data/levels.json/88/reward_gold_mult|0.26|0.13270933|0.51042051|
|data/levels.json/89/reward_gold_mult|0.26|0.13243588|0.50936876|
|data/levels.json/90/reward_gold_mult|0.26|0.13216299|0.50831918|
|data/levels.json/91/reward_gold_mult|0.26|0.13189066|0.50727176|
|data/levels.json/92/reward_gold_mult|0.26|0.13161889|0.50622649|
|data/levels.json/93/reward_gold_mult|0.26|0.13134768|0.50518339|
|data/levels.json/94/reward_gold_mult|0.26|0.13107703|0.50414243|
|data/levels.json/95/reward_gold_mult|0.26|0.13080694|0.50310361|
|data/levels.json/96/reward_gold_mult|0.26|0.1305374|0.50206694|
|data/levels.json/97/reward_gold_mult|0.26|0.13026843|0.50103241|
|data/levels.json/98/reward_gold_mult|0.26|0.13|0.5|
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
|data/weapons.json/weapon_autocannon/cost_base_gold|100|154|1.5408305|
|data/weapons.json/weapon_flamethrower/cost_base_gold|180|277|1.5408305|
|data/weapons.json/weapon_cryocannon/cost_base_gold|180|277|1.5408305|
|data/weapons.json/weapon_teslacoil/cost_base_gold|240|370|1.5408305|
|data/weapons.json/weapon_venomlauncher/cost_base_gold|240|370|1.5408305|
|data/weapons.json/weapon_railgun/cost_base_gold|320|493|1.5408305|
|data/weapons.json/weapon_scattergun/cost_base_gold|180|277|1.5408305|
|data/weapons.json/weapon_plasmacannon/cost_base_gold|320|493|1.5408305|

|关卡|rec|E|旧P|新P|新R|新P/E|下限|上限|达标|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
|001|50|65|65|65|1.3000|1.0000|48|78|True|
|002|50|65|69|67|1.3400|1.0308|48|78|True|
|003|50|65|73|70|1.4000|1.0769|48|78|True|
|004|64|65|74|72|1.1250|1.1077|61|78|True|
|005|76|76|81|76|1.0000|1.0000|76|91|True|
|006|53|76|82|82|1.5472|1.0789|51|91|True|
|007|53|76|89|84|1.5849|1.1053|53|91|True|
|008|79|79|96|87|1.1013|1.1013|79|94|True|
|009|79|79|106|93|1.1772|1.1772|79|94|True|
|010|87|87|112|93|1.0690|1.0690|87|104|True|
|011|99|99|116|103|1.0404|1.0404|95|118|True|
|012|108|108|122|104|0.9630|0.9630|103|129|True|
|013|131|131|131|127|0.9695|0.9695|125|157|True|
|014|138|138|141|142|1.0290|1.0290|132|165|True|
|015|147|147|151|155|1.0544|1.0544|147|176|True|
|016|98|147|152|155|1.5816|1.0544|94|176|True|
|017|165|165|166|166|1.0061|1.0061|165|198|True|
|018|185|185|207|200|1.0811|1.0811|185|222|True|
|019|188|188|210|201|1.0691|1.0691|188|225|True|
|020|291|291|291|296|1.0172|1.0172|0|349|True|
|021|164|291|323|299|1.8232|1.0275|156|349|True|
|022|183|291|339|299|1.6339|1.0275|174|349|True|
|023|186|291|355|299|1.6075|1.0275|177|349|True|
|024|201|291|374|303|1.5075|1.0412|191|349|True|
|025|260|291|410|313|1.2038|1.0756|260|349|True|
|026|226|291|410|313|1.3850|1.0756|215|349|True|
|027|195|291|410|326|1.6718|1.1203|195|349|True|
|028|231|291|474|326|1.4113|1.1203|231|349|True|
|029|206|291|509|347|1.6845|1.1924|206|349|True|
|030|332|332|515|362|1.0904|1.0904|332|398|True|
|031|159|332|522|362|2.2767|1.0904|152|398|True|
|032|245|332|530|362|1.4776|1.0904|233|398|True|
|033|228|332|573|362|1.5877|1.0904|217|398|True|
|034|330|332|573|366|1.1091|1.1024|314|398|True|
|035|219|332|648|366|1.6712|1.1024|219|398|True|
|036|225|332|679|386|1.7156|1.1627|214|398|True|
|037|232|332|685|487|2.0991|1.4669|232|398|False|
|038|484|484|710|503|1.0393|1.0393|484|580|True|
|039|533|533|849|539|1.0113|1.0113|0|639|True|
|040|574|574|849|603|1.0505|1.0505|574|688|True|
|041|236|574|880|641|2.7161|1.1167|225|688|True|
|042|375|574|942|641|1.7093|1.1167|357|688|True|
|043|587|587|951|656|1.1175|1.1175|558|704|True|
|044|757|757|957|791|1.0449|1.0449|720|908|True|
|045|655|757|963|848|1.2947|1.1202|655|908|True|
|046|600|757|972|885|1.4750|1.1691|570|908|True|
|047|670|757|983|913|1.3627|1.2061|670|908|False|
|048|663|757|983|913|1.3771|1.2061|663|908|False|
|049|658|757|1008|949|1.4422|1.2536|658|908|False|
|050|868|868|1068|955|1.1002|1.1002|868|1041|True|
|051|431|868|1185|955|2.2158|1.1002|410|1041|True|
|052|349|868|1185|962|2.7564|1.1083|332|1041|True|
|053|427|868|1185|962|2.2529|1.1083|406|1041|True|
|054|359|868|1185|962|2.6797|1.1083|342|1041|True|
|055|950|950|1185|969|1.0200|1.0200|950|1140|True|
|056|354|950|1237|969|2.7373|1.0200|337|1140|True|
|057|990|990|1237|1045|1.0556|1.0556|990|1188|True|
|058|503|990|1284|1045|2.0775|1.0556|503|1188|True|
|059|562|990|1284|1045|1.8594|1.0556|562|1188|True|
|060|990|990|1300|1045|1.0556|1.0556|990|1188|True|
|061|990|990|1491|1045|1.0556|1.0556|941|1188|True|
|062|250|990|1577|1045|4.1800|1.0556|238|1188|True|
|063|576|990|1763|1065|1.8490|1.0758|548|1188|True|
|064|955|990|1763|1213|1.2702|1.2253|908|1188|False|
|065|1014|1014|1813|1213|1.1963|1.1963|1014|1216|True|
|066|1184|1184|1813|1213|1.0245|1.0245|1125|1420|True|
|067|955|1184|1813|1213|1.2702|1.0245|955|1420|True|
|068|1042|1184|1814|1213|1.1641|1.0245|1042|1420|True|
|069|978|1184|2043|1305|1.3344|1.1022|978|1420|True|
|070|1286|1286|2043|1305|1.0148|1.0148|1286|1543|True|
|071|1146|1286|2202|1305|1.1387|1.0148|1089|1543|True|
|072|1576|1576|2308|1538|0.9759|0.9759|1498|1891|True|
|073|818|1576|2308|1538|1.8802|0.9759|778|1891|True|
|074|2034|2034|2429|2048|1.0069|1.0069|0|2440|True|
|075|1841|2034|2733|2048|1.1124|1.0069|1841|2440|True|
|076|2758|2758|2989|2760|1.0007|1.0007|0|3309|True|
|077|1652|2758|3160|2760|1.6707|1.0007|1652|3309|True|
|078|2226|2758|3160|2760|1.2399|1.0007|2226|3309|True|
|079|2030|2758|3160|2760|1.3596|1.0007|2030|3309|True|
|080|2067|2758|3220|2760|1.3353|1.0007|2067|3309|True|
|081|1096|2758|3270|2760|2.5182|1.0007|1042|3309|True|
|082|1762|2758|3270|3164|1.7957|1.1472|1674|3309|True|
|083|1815|2758|3270|3164|1.7433|1.1472|1725|3309|True|
|084|1265|2758|3271|3164|2.5012|1.1472|1202|3309|True|
|085|2204|2758|3271|3164|1.4356|1.1472|2204|3309|True|
|086|1855|2758|3538|3164|1.7057|1.1472|1763|3309|True|
|087|1857|2758|3639|3164|1.7038|1.1472|1857|3309|True|
|088|1857|2758|3700|3164|1.7038|1.1472|1857|3309|True|
|089|1994|2758|3974|3164|1.5868|1.1472|1994|3309|True|
|090|2751|2758|3994|3164|1.1501|1.1472|2751|3309|True|
|091|1234|2758|4401|3239|2.6248|1.1744|1173|3309|True|
|092|1862|2758|4401|3239|1.7395|1.1744|1769|3309|True|
|093|2266|2758|4404|3239|1.4294|1.1744|2153|3309|True|
|094|1830|2758|4406|3239|1.7699|1.1744|1739|3309|True|
|095|3370|3370|4415|3429|1.0175|1.0175|0|4044|True|
|096|2429|3370|4415|3429|1.4117|1.0175|2308|4044|True|
|097|1863|3370|4415|3597|1.9308|1.0674|1863|4044|True|
|098|2720|3370|5163|3597|1.3224|1.0674|2720|4044|True|
|099|3094|3370|5283|3597|1.1626|1.0674|3094|4044|True|

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

首次R<0.95：None；G1走廊不满足关数：5/99。

包络目标Σ|P−E|/E：8.449117。

回刷总数：84（非门19，门65）；各章非门：{'1': 0, '2': 6, '3': 0, '4': 6, '5': 4, '6': 0, '7': 0, '8': 3, '9': 0, '10': 0}。
门关：[20, 39, 74, 76, 95]；预算后新增门：[39, 74]；未刷够门：[]；非门失败：[37, 47, 48, 49, 64]。

|回刷位置|路线(挑战/普通)|入场P|回刷后P|次数|非门章累计|刷够|八墙关|门高度/路线注记|
|---|---|---:|---:|---:|---:|---|---|---|
|013|012挑, 011挑, 010挑|106|127|3|3|True|False|非门|
|018|017挑, 016挑, 015挑|178|200|3|6|True|True|非门|
|020|019挑, 018挑, 014挑, 013挑, 009挑, 008挑, 007挑, 006挑|203|296|8|6|True|True|8 / 仅挑战 / Owner fixed gate|
|039|038挑, 037挑, 036挑, 035挑, 034挑, 033挑, 032挑, 031挑, 030挑, 029挑, 028挑, 027挑, 026挑, 025挑|516|539|14|0|True|False|14 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|040|039挑, 024挑, 023挑, 022挑, 021挑, 020挑|539|603|6|6|True|True|非门|
|044|043挑, 042挑, 041挑, 040挑|702|791|4|4|True|True|非门|
|072|071挑, 070挑, 069挑|1305|1538|3|3|True|False|非门|
|074|073挑, 072挑, 068挑, 067挑, 066挑, 065挑, 064挑, 063挑, 062挑, 061挑, 060挑, 059挑, 058挑, 057挑, 056挑, 055挑, 054挑, 053挑, 052挑, 051挑, 050挑, 049挑, 048挑, 047挑, 046挑, 045挑, 044挑, 005挑, 004挑, 003挑, 002挑, 001挑, 073普, 073普|1544|2048|34|3|True|False|34 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|076|075挑, 074挑, 075普, 075普, 075普, 075普|2048|2760|6|3|True|True|6 / 可付费（未做运行时验证） / Owner fixed gate|
|095|094挑, 093挑, 092挑|3239|3429|3|0|True|False|3 / 可付费（未做运行时验证） / Owner fixed gate|

## 门关高度（含无需回刷的固定门）

|门|高度|已刷够|路径|原因|
|---|---:|---|---|---|
|020|8|True|仅挑战|Owner fixed gate|
|039|14|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|074|34|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|076|6|True|可付费（未做运行时验证）|Owner fixed gate|
|095|3|True|可付费（未做运行时验证）|Owner fixed gate|

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|当关/章累计回刷|
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
|001|0|65|50|1.3000|65|1.0000|279|weapon_autocannon 1→2; skill_multishot 0→1|0/0|
|002|279|67|50|1.3400|65|1.0308|380|vanguard 1→2; weapon_autocannon 2→3; skill_pierce 0→1|0/0|
|003|659|70|50|1.4000|65|1.0769|452|weapon_autocannon 3→4; skill_barrier 0→1; skill_homing 0→1|0/0|
|004|1111|72|64|1.1250|65|1.1077|513|weapon_cryocannon; weapon_autocannon 4→5; skill_charge_shot 0→1; skill_salvo 0→1|0/0|
|005|1624|76|76|1.0000|76|1.0000|627|vanguard 2→3; weapon_autocannon 5→6; skill_slow_field 0→1; signature 0→1|0/0|
|006|2251|82|53|1.5472|76|1.0789|675|vanguard 3→4; weapon_cryocannon 1→2; skill_critical 0→1; skill_split_shot 0→1|0/0|
|007|2926|84|53|1.5849|76|1.1053|684|armor_kevlar; weapon_autocannon 6→7; skill_ricochet 0→1|0/0|
|008|3610|87|79|1.1013|79|1.1013|910|armor_kevlar 1→2; weapon_autocannon 7→8; skill_multishot 1→2|0/0|
|009|4520|93|79|1.1772|79|1.1772|687|armor_kevlar 2→3; weapon_cryocannon 2→3|0/0|
|010|5207|93|87|1.0690|87|1.0690|684|chip_attack; chip_attack 1→3; vanguard 4→5; skill_pierce 1→2|0/0|
|011|5891|103|99|1.0404|99|1.0404|1130|weapon_autocannon 8→9; skill_homing 1→2|0/0|
|012|7021|104|108|0.9630|108|0.9630|1159|chip_attack 3→4; weapon_autocannon 9→10|0/0|
|013|10583|127|131|0.9695|131|0.9695|1197|vanguard 5→6; weapon_scattergun 3→4|3/3|
|014|11780|142|138|1.0290|138|1.0290|1231|chip_attack 5→6; weapon_scattergun 4→5; signature 1→2|0/3|
|015|13011|155|147|1.0544|147|1.0544|782|weapon_cryocannon 4→5|0/3|
|016|13793|155|98|1.5816|147|1.0544|1550|armor_kevlar 5→6; weapon_scattergun 5→6; skill_slow_field 1→2|0/3|
|017|15343|166|165|1.0061|165|1.0061|1617|weapon_railgun; chip_attack 6→7; weapon_scattergun 6→7; skill_critical 1→2; skill_split_shot 1→2|0/3|
|018|20125|200|185|1.0811|185|1.0811|1265|weapon_scattergun 7→8|3/6|
|019|21390|201|188|1.0691|188|1.0691|1792|weapon_scattergun 8→9; skill_multishot 2→3|0/6|
|020|30005|296|291|1.0172|291|1.0172|1886|weapon_scattergun 9→10|8/6|
|021|31891|299|164|1.8232|291|1.0275|1709|weapon_venomlauncher; weapon_venomlauncher 1→4|0/0|
|022|33600|299|183|1.6339|291|1.0275|1821|armor_kevlar 7→8; weapon_venomlauncher 4→5; skill_salvo 2→3|0/0|
|023|35421|299|186|1.6075|291|1.0275|1997|weapon_scattergun 10→11|0/0|
|024|37418|303|201|1.5075|291|1.0412|1956|chip_attack 9→10; weapon_venomlauncher 5→6; skill_charge_shot 2→3|0/0|
|025|39374|313|260|1.2038|291|1.0756|1315|weapon_cryocannon 6→7|0/0|
|026|40689|313|226|1.3850|291|1.0756|2287|weapon_scattergun 11→12; skill_slow_field 2→3|0/0|
|027|42976|326|195|1.6718|291|1.1203|2108|weapon_railgun 5→6|0/0|
|028|45084|326|231|1.4113|291|1.1203|2230|weapon_scattergun 12→13; skill_split_shot 2→3|0/0|
|029|47314|347|206|1.6845|291|1.1924|2422|weapon_scattergun 13→14|0/0|
|030|49736|362|332|1.0904|332|1.0904|1903|weapon_venomlauncher 6→7|0/0|
|031|51639|362|159|2.2767|332|1.0904|2706|weapon_flamethrower; armor_kevlar 8→9; weapon_flamethrower 1→5; skill_critical 2→3|0/0|
|032|54345|362|245|1.4776|332|1.0904|2540|weapon_plasmacannon; weapon_plasmacannon 1→4|0/0|
|033|56885|362|228|1.5877|332|1.0904|2235|pet_turret_drone 6→7; weapon_plasmacannon 4→5; skill_ricochet 2→3|0/0|
|034|59120|366|330|1.1091|332|1.1024|2904|weapon_flamethrower 5→6; weapon_plasmacannon 5→6|0/0|
|035|62024|366|219|1.6712|332|1.1024|2078|vanguard 8→9; weapon_flamethrower 6→7|0/0|
|036|64102|386|225|1.7156|332|1.1627|2840|weapon_scattergun 14→15; signature 2→3|0/0|
|037|66942|487|232|2.0991|332|1.4669|3187|weapon_scattergun 15→16|0/0|
|038|70129|503|484|1.0393|484|1.0393|3439|weapon_scattergun 16→17|0/0|
|039|100603|539|533|1.0113|533|1.0113|2933|weapon_railgun 7→8|14/0|
|040|113429|603|574|1.0505|574|1.0505|3852|weapon_scattergun 18→19; skill_salvo 3→4|6/6|
|041|117281|641|236|2.7161|574|1.1167|3769|weapon_teslacoil; armor_kevlar 9→10; weapon_teslacoil 1→5|0/0|
|042|121050|641|375|1.7093|574|1.1167|3445|weapon_scattergun 19→20|0/0|
|043|124495|656|587|1.1175|587|1.1175|4024|pet_turret_drone 7→8; weapon_teslacoil 5→7; skill_charge_shot 3→4|0/0|
|044|140832|791|757|1.0449|757|1.0449|3891|weapon_scattergun 20→21|4/4|
|045|144723|848|655|1.2947|757|1.1202|3946|weapon_scattergun 21→22|0/4|
|046|148669|885|600|1.4750|757|1.1691|3391|chip_attack 11→12; weapon_teslacoil 9→10|0/4|
|047|152060|913|670|1.3627|757|1.2061|3719|weapon_plasmacannon 9→10; skill_slow_field 3→4|0/4|
|048|155779|913|663|1.3771|757|1.2061|4314|weapon_scattergun 22→23|0/4|
|049|160093|949|658|1.4422|757|1.2536|4241|weapon_scattergun 23→24|0/4|
|050|164334|955|868|1.1002|868|1.1002|3240|weapon_railgun 9→10|0/4|
|051|167574|955|431|2.2158|868|1.1002|1461|vanguard 12→13; skill_split_shot 3→4|0/0|
|052|169035|962|349|2.7564|868|1.1083|1638|weapon_flamethrower 10→11|0/0|
|053|170673|962|427|2.2529|868|1.1083|1605|weapon_autocannon 15→16|0/0|
|054|172278|962|359|2.6797|868|1.1083|1638|vanguard 13→14; skill_critical 3→4|0/0|
|055|173916|969|950|1.0200|950|1.0200|1647|weapon_autocannon 16→17|0/0|
|056|175563|969|354|2.7373|950|1.0200|1598|vanguard 14→15; skill_ricochet 3→4|0/0|
|057|177161|1045|990|1.0556|990|1.0556|2740|weapon_teslacoil 10→11|0/0|
|058|179901|1045|503|2.0775|990|1.0556|1819|weapon_autocannon 17→18|0/0|
|059|181720|1045|562|1.8594|990|1.0556|1785|weapon_autocannon 18→19|0/0|
|060|183505|1045|990|1.0556|990|1.0556|3635|armor_kevlar 10→11; weapon_venomlauncher 10→11|0/0|
|061|187140|1045|990|1.0556|990|1.0556|2191|weapon_cryocannon 11→12|0/0|
|062|189331|1045|250|4.1800|990|1.0556|2244|weapon_flamethrower 11→12; skill_multishot 4→5|0/0|
|063|191575|1065|576|1.8490|990|1.0758|2113|vanguard 15→16|0/0|
|064|193688|1213|955|1.2702|990|1.2253|2129|weapon_cryocannon 12→13|0/0|
|065|195817|1213|1014|1.1963|1014|1.1963|2479|weapon_flamethrower 12→13|0/0|
|066|198296|1213|1184|1.0245|1184|1.0245|2076|weapon_cryocannon 13→14|0/0|
|067|200372|1213|955|1.2702|1184|1.0245|2722|weapon_flamethrower 13→14; skill_pierce 4→5|0/0|
|068|203094|1213|1042|1.1641|1184|1.0245|2554|chip_attack 12→13; vanguard 16→17|0/0|
|069|205648|1305|978|1.3344|1184|1.1022|2610|weapon_autocannon 19→20|0/0|
|070|208258|1305|1286|1.0148|1286|1.0148|2529|weapon_teslacoil 11→12|0/0|
|071|210787|1305|1146|1.1387|1286|1.0148|2334|weapon_autocannon 20→21; skill_homing 4→5|0/0|
|072|216581|1538|1576|0.9759|1576|0.9759|2224|weapon_autocannon 21→22|3/3|
|073|218805|1538|818|1.8802|1576|0.9759|2423|armor_kevlar 12→13; pet_turret_drone 9→10; skill_barrier 4→5|0/3|
|074|266620|2048|2034|1.0069|2034|1.0069|2855|weapon_flamethrower 14→15|34/3|
|075|269475|2048|1841|1.1124|2034|1.0069|3030|weapon_cryocannon 15→16|0/3|
|076|281717|2760|2758|1.0007|2758|1.0007|2637|weapon_autocannon 23→24|6/3|
|077|284354|2760|1652|1.6707|2758|1.0007|2992|weapon_flamethrower 15→16|0/3|
|078|287346|2760|2226|1.2399|2758|1.0007|2761|weapon_autocannon 24→25; skill_ricochet 4→5|0/3|
|079|290107|2760|2030|1.3596|2758|1.0007|3020|weapon_cryocannon 16→17|0/3|
|080|293127|2760|2067|1.3353|2758|1.0007|3275|weapon_venomlauncher 13→14|0/3|
|081|296402|2760|1096|2.5182|2758|1.0007|2671|vanguard 21→22|0/0|
|082|299073|3164|1762|1.7957|2758|1.1472|2640|weapon_flamethrower 16→17|0/0|
|083|301713|3164|1815|1.7433|2758|1.1472|3107|weapon_autocannon 25→26|0/0|
|084|304820|3164|1265|2.5012|2758|1.1472|2715|weapon_autocannon 26→27|0/0|
|085|307535|3164|2204|1.4356|2758|1.1472|3609|weapon_teslacoil 14→15|0/0|
|086|311144|3164|1855|1.7057|2758|1.1472|3513|weapon_cryocannon 17→18|0/0|
|087|314657|3164|1857|1.7038|2758|1.1472|3398|weapon_flamethrower 17→18|0/0|
|088|318055|3164|1857|1.7038|2758|1.1472|3177|weapon_autocannon 27→28|0/0|
|089|321232|3164|1994|1.5868|2758|1.1472|3481|weapon_plasmacannon 11→12|0/0|
|090|324713|3164|2751|1.1501|2758|1.1472|3008|vanguard 22→23|0/0|
|091|327721|3239|1234|2.6248|2758|1.1744|2955|weapon_cryocannon 18→19|0/0|
|092|330676|3239|1862|1.7395|2758|1.1744|4064|weapon_railgun 11→12|0/0|
|093|334740|3239|2266|1.4294|2758|1.1744|3556|weapon_venomlauncher 14→15|0/0|
|094|338296|3239|1830|1.7699|2758|1.1744|3820|weapon_flamethrower 18→19|0/0|
|095|347538|3429|3370|1.0175|3370|1.0175|3593|weapon_autocannon 28→29|3/0|
|096|351131|3429|2429|1.4117|3370|1.0175|4574|weapon_scattergun 24→25|0/0|
|097|355705|3597|1863|1.9308|3370|1.0674|4281|weapon_plasmacannon 12→13|0/0|
|098|359986|3597|2720|1.3224|3370|1.0674|4348|weapon_railgun 12→13|0/0|
|099|364334|3597|3094|1.1626|3370|1.0674|3885|weapon_teslacoil 15→16|0/0|
