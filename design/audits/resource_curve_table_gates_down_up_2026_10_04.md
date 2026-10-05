状态：SEARCH_CANDIDATE_NOT_YET_FEASIBLE；待Fable签字，游戏数据未写入。

# 资源表 C 候选

§8.3离线假定3★首通，挑战首通优先；非门关每章最多6次，门关不限次数、照实列高度。不是运行时胜率。P(g)/F(g)与消费策略冻结，因子[0.5,2.0]。
优化前：88/99失败，目标36.608304。
优化后：13/99失败，目标5.923432。

缩放系数与逐字段旧/新对照完整列于同名JSON；所有候选仅在内存模拟。

|曲线|缩放系数/形式|
|---|---|
|first_clear_gold|[-0.4431471805599453, 0.003570082605774072]；existing authored per-level values × exp(a+b*(L-1)/98)|
|kill_gold_mult|[-0.44599192128257653, -0.12703160465368252]；existing authored per-level values × exp(a+b*(L-1)/98)|
|free_unlock_star|0.9615965867489217；existing free star tiers × constant|
|skill_base_xp_costs|[1.1123851221320116, 1.0921103953766542, 0.803075416971268, 0.7599744461183237, 0.5545577104848811]；same five authored cost tiers times positive monotone factors|
|sig_skill_xp_costs|[0.6503352553566473, 0.761384035320247, 1.2459813628034573, 1.2924836176638193, 1.7355373950026944]；same five authored cost tiers times positive monotone factors|
|weapon_cost.weapon_autocannon|2.0；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_flamethrower|0.8214915881820145；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_cryocannon|1.0824192775879842；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_teslacoil|0.5416435338374793；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_venomlauncher|1.2941091729838878；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_railgun|0.823848716708028；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_scattergun|1.7409122469605807；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_plasmacannon|0.5295773954314711；same existing linear upgrade formula × constant base cost|

|文件/字段|旧值|候选新值|系数|
|---|---:|---:|---:|
|data/levels.json/0/first_clear_reward/gold|119|76|0.64201271|
|data/levels.json/1/first_clear_reward/gold|143|92|0.6420361|
|data/levels.json/2/first_clear_reward/gold|167|107|0.64205949|
|data/levels.json/3/first_clear_reward/gold|192|123|0.64208288|
|data/levels.json/4/first_clear_reward/gold|216|139|0.64210627|
|data/levels.json/5/first_clear_reward/gold|241|155|0.64212966|
|data/levels.json/6/first_clear_reward/gold|266|171|0.64215305|
|data/levels.json/7/first_clear_reward/gold|291|187|0.64217645|
|data/levels.json/8/first_clear_reward/gold|315|202|0.64219984|
|data/levels.json/9/first_clear_reward/gold|340|218|0.64222324|
|data/levels.json/10/first_clear_reward/gold|366|235|0.64224663|
|data/levels.json/11/first_clear_reward/gold|391|251|0.64227003|
|data/levels.json/12/first_clear_reward/gold|416|267|0.64229343|
|data/levels.json/13/first_clear_reward/gold|442|284|0.64231683|
|data/levels.json/14/first_clear_reward/gold|467|300|0.64234023|
|data/levels.json/15/first_clear_reward/gold|493|317|0.64236363|
|data/levels.json/16/first_clear_reward/gold|519|333|0.64238703|
|data/levels.json/17/first_clear_reward/gold|545|350|0.64241043|
|data/levels.json/18/first_clear_reward/gold|571|367|0.64243383|
|data/levels.json/19/first_clear_reward/gold|597|384|0.64245724|
|data/levels.json/20/first_clear_reward/gold|623|400|0.64248064|
|data/levels.json/21/first_clear_reward/gold|650|418|0.64250405|
|data/levels.json/22/first_clear_reward/gold|676|434|0.64252745|
|data/levels.json/23/first_clear_reward/gold|703|452|0.64255086|
|data/levels.json/24/first_clear_reward/gold|729|468|0.64257427|
|data/levels.json/25/first_clear_reward/gold|756|486|0.64259768|
|data/levels.json/26/first_clear_reward/gold|783|503|0.64262109|
|data/levels.json/27/first_clear_reward/gold|810|521|0.6426445|
|data/levels.json/28/first_clear_reward/gold|837|538|0.64266791|
|data/levels.json/29/first_clear_reward/gold|864|555|0.64269132|
|data/levels.json/30/first_clear_reward/gold|892|573|0.64271474|
|data/levels.json/31/first_clear_reward/gold|919|591|0.64273815|
|data/levels.json/32/first_clear_reward/gold|947|609|0.64276157|
|data/levels.json/33/first_clear_reward/gold|975|627|0.64278498|
|data/levels.json/34/first_clear_reward/gold|1002|644|0.6428084|
|data/levels.json/35/first_clear_reward/gold|1030|662|0.64283182|
|data/levels.json/36/first_clear_reward/gold|1058|680|0.64285523|
|data/levels.json/37/first_clear_reward/gold|1086|698|0.64287865|
|data/levels.json/38/first_clear_reward/gold|1115|717|0.64290207|
|data/levels.json/39/first_clear_reward/gold|1143|735|0.64292549|
|data/levels.json/40/first_clear_reward/gold|1171|753|0.64294892|
|data/levels.json/41/first_clear_reward/gold|1200|772|0.64297234|
|data/levels.json/42/first_clear_reward/gold|1229|790|0.64299576|
|data/levels.json/43/first_clear_reward/gold|1257|808|0.64301919|
|data/levels.json/44/first_clear_reward/gold|1286|827|0.64304261|
|data/levels.json/45/first_clear_reward/gold|1315|846|0.64306604|
|data/levels.json/46/first_clear_reward/gold|1344|864|0.64308947|
|data/levels.json/47/first_clear_reward/gold|1374|884|0.64311289|
|data/levels.json/48/first_clear_reward/gold|1403|902|0.64313632|
|data/levels.json/49/first_clear_reward/gold|1432|921|0.64315975|
|data/levels.json/50/first_clear_reward/gold|1462|940|0.64318318|
|data/levels.json/51/first_clear_reward/gold|1492|960|0.64320661|
|data/levels.json/52/first_clear_reward/gold|1521|978|0.64323004|
|data/levels.json/53/first_clear_reward/gold|1551|998|0.64325348|
|data/levels.json/54/first_clear_reward/gold|1581|1017|0.64327691|
|data/levels.json/55/first_clear_reward/gold|1611|1036|0.64330035|
|data/levels.json/56/first_clear_reward/gold|1642|1056|0.64332378|
|data/levels.json/57/first_clear_reward/gold|1672|1076|0.64334722|
|data/levels.json/58/first_clear_reward/gold|1702|1095|0.64337065|
|data/levels.json/59/first_clear_reward/gold|1733|1115|0.64339409|
|data/levels.json/60/first_clear_reward/gold|1764|1135|0.64341753|
|data/levels.json/61/first_clear_reward/gold|1794|1154|0.64344097|
|data/levels.json/62/first_clear_reward/gold|1825|1174|0.64346441|
|data/levels.json/63/first_clear_reward/gold|1856|1194|0.64348785|
|data/levels.json/64/first_clear_reward/gold|1887|1214|0.6435113|
|data/levels.json/65/first_clear_reward/gold|1919|1235|0.64353474|
|data/levels.json/66/first_clear_reward/gold|1950|1255|0.64355818|
|data/levels.json/67/first_clear_reward/gold|1981|1275|0.64358163|
|data/levels.json/68/first_clear_reward/gold|2013|1296|0.64360507|
|data/levels.json/69/first_clear_reward/gold|2044|1316|0.64362852|
|data/levels.json/70/first_clear_reward/gold|2076|1336|0.64365197|
|data/levels.json/71/first_clear_reward/gold|2108|1357|0.64367542|
|data/levels.json/72/first_clear_reward/gold|2140|1378|0.64369887|
|data/levels.json/73/first_clear_reward/gold|2172|1398|0.64372232|
|data/levels.json/74/first_clear_reward/gold|2204|1419|0.64374577|
|data/levels.json/75/first_clear_reward/gold|2237|1440|0.64376922|
|data/levels.json/76/first_clear_reward/gold|2269|1461|0.64379267|
|data/levels.json/77/first_clear_reward/gold|2302|1482|0.64381612|
|data/levels.json/78/first_clear_reward/gold|2334|1503|0.64383958|
|data/levels.json/79/first_clear_reward/gold|2367|1524|0.64386303|
|data/levels.json/80/first_clear_reward/gold|2400|1545|0.64388649|
|data/levels.json/81/first_clear_reward/gold|2433|1567|0.64390995|
|data/levels.json/82/first_clear_reward/gold|2466|1588|0.6439334|
|data/levels.json/83/first_clear_reward/gold|2499|1609|0.64395686|
|data/levels.json/84/first_clear_reward/gold|2532|1631|0.64398032|
|data/levels.json/85/first_clear_reward/gold|2566|1653|0.64400378|
|data/levels.json/86/first_clear_reward/gold|2599|1674|0.64402724|
|data/levels.json/87/first_clear_reward/gold|2633|1696|0.6440507|
|data/levels.json/88/first_clear_reward/gold|2667|1718|0.64407417|
|data/levels.json/89/first_clear_reward/gold|2700|1739|0.64409763|
|data/levels.json/90/first_clear_reward/gold|2734|1761|0.6441211|
|data/levels.json/91/first_clear_reward/gold|2769|1784|0.64414456|
|data/levels.json/92/first_clear_reward/gold|2803|1806|0.64416803|
|data/levels.json/93/first_clear_reward/gold|2837|1828|0.64419149|
|data/levels.json/94/first_clear_reward/gold|2871|1850|0.64421496|
|data/levels.json/95/first_clear_reward/gold|2906|1872|0.64423843|
|data/levels.json/96/first_clear_reward/gold|2940|1894|0.6442619|
|data/levels.json/97/first_clear_reward/gold|2975|1917|0.64428537|
|data/levels.json/98/first_clear_reward/gold|3010|1939|0.64430884|
|data/levels.json/0/reward_gold_mult|0.56|0.35850581|0.64018894|
|data/levels.json/1/reward_gold_mult|0.55|0.3516478|0.63935964|
|data/levels.json/2/reward_gold_mult|0.55|0.35119228|0.63853142|
|data/levels.json/3/reward_gold_mult|0.55|0.35073734|0.63770426|
|data/levels.json/4/reward_gold_mult|0.54|0.34391422|0.63687818|
|data/levels.json/5/reward_gold_mult|0.54|0.34346871|0.63605317|
|data/levels.json/6/reward_gold_mult|0.53|0.33667149|0.63522922|
|data/levels.json/7/reward_gold_mult|0.53|0.33623536|0.63440634|
|data/levels.json/8/reward_gold_mult|0.53|0.3357998|0.63358453|
|data/levels.json/9/reward_gold_mult|0.52|0.32903717|0.63276379|
|data/levels.json/10/reward_gold_mult|0.52|0.32861093|0.63194411|
|data/levels.json/11/reward_gold_mult|0.52|0.32818525|0.63112548|
|data/levels.json/12/reward_gold_mult|0.51|0.32145704|0.63030792|
|data/levels.json/13/reward_gold_mult|0.51|0.32104063|0.62949142|
|data/levels.json/14/reward_gold_mult|0.51|0.32062475|0.62867598|
|data/levels.json/15/reward_gold_mult|0.5|0.3139308|0.62786159|
|data/levels.json/16/reward_gold_mult|0.5|0.31352413|0.62704826|
|data/levels.json/17/reward_gold_mult|0.5|0.31311799|0.62623598|
|data/levels.json/18/reward_gold_mult|0.49|0.30645813|0.62542475|
|data/levels.json/19/reward_gold_mult|0.49|0.30606114|0.62461458|
|data/levels.json/20/reward_gold_mult|0.48|0.29942662|0.62380545|
|data/levels.json/21/reward_gold_mult|0.48|0.29903874|0.62299737|
|data/levels.json/22/reward_gold_mult|0.48|0.29865136|0.62219034|
|data/levels.json/23/reward_gold_mult|0.47|0.29205065|0.62138435|
|data/levels.json/24/reward_gold_mult|0.47|0.29167232|0.62057941|
|data/levels.json/25/reward_gold_mult|0.47|0.29129449|0.61977551|
|data/levels.json/26/reward_gold_mult|0.46|0.28472742|0.61897265|
|data/levels.json/27/reward_gold_mult|0.46|0.28435858|0.61817084|
|data/levels.json/28/reward_gold_mult|0.46|0.28399023|0.61737006|
|data/levels.json/29/reward_gold_mult|0.45|0.27745664|0.61657032|
|data/levels.json/30/reward_gold_mult|0.45|0.27709722|0.61577161|
|data/levels.json/31/reward_gold_mult|0.44|0.27058853|0.61497394|
|data/levels.json/32/reward_gold_mult|0.44|0.27023801|0.6141773|
|data/levels.json/33/reward_gold_mult|0.44|0.26988795|0.61338169|
|data/levels.json/34/reward_gold_mult|0.43|0.26341246|0.61258712|
|data/levels.json/35/reward_gold_mult|0.43|0.26307124|0.61179357|
|data/levels.json/36/reward_gold_mult|0.43|0.26273045|0.61100106|
|data/levels.json/37/reward_gold_mult|0.42|0.25628802|0.61020956|
|data/levels.json/38/reward_gold_mult|0.42|0.25595602|0.6094191|
|data/levels.json/39/reward_gold_mult|0.42|0.25562446|0.60862966|
|data/levels.json/40/reward_gold_mult|0.41|0.24921491|0.60784124|
|data/levels.json/41/reward_gold_mult|0.41|0.24889207|0.60705384|
|data/levels.json/42/reward_gold_mult|0.41|0.24856966|0.60626746|
|data/levels.json/43/reward_gold_mult|0.4|0.24219284|0.6054821|
|data/levels.json/44/reward_gold_mult|0.4|0.2418791|0.60469776|
|data/levels.json/45/reward_gold_mult|0.39|0.23552663|0.60391443|
|data/levels.json/46/reward_gold_mult|0.39|0.23522153|0.60313212|
|data/levels.json/47/reward_gold_mult|0.39|0.23491682|0.60235082|
|data/levels.json/48/reward_gold_mult|0.38|0.2285968|0.60157054|
|data/levels.json/49/reward_gold_mult|0.38|0.22830068|0.60079126|
|data/levels.json/50/reward_gold_mult|0.38|0.22800494|0.600013|
|data/levels.json/51/reward_gold_mult|0.37|0.22171722|0.59923574|
|data/levels.json/52/reward_gold_mult|0.37|0.22143001|0.59845949|
|data/levels.json/53/reward_gold_mult|0.37|0.22114317|0.59768424|
|data/levels.json/54/reward_gold_mult|0.36|0.2148876|0.59691|
|data/levels.json/55/reward_gold_mult|0.36|0.21460923|0.59613676|
|data/levels.json/56/reward_gold_mult|0.35|0.20837758|0.59536453|
|data/levels.json/57/reward_gold_mult|0.35|0.20810765|0.59459329|
|data/levels.json/58/reward_gold_mult|0.35|0.20783807|0.59382305|
|data/levels.json/59/reward_gold_mult|0.34|0.2016383|0.59305382|
|data/levels.json/60/reward_gold_mult|0.34|0.20137709|0.59228557|
|data/levels.json/61/reward_gold_mult|0.34|0.20111623|0.59151833|
|data/levels.json/62/reward_gold_mult|0.33|0.19494818|0.59075207|
|data/levels.json/63/reward_gold_mult|0.33|0.19469565|0.58998681|
|data/levels.json/64/reward_gold_mult|0.33|0.19444344|0.58922254|
|data/levels.json/65/reward_gold_mult|0.32|0.18830696|0.58845926|
|data/levels.json/66/reward_gold_mult|0.32|0.18806303|0.58769697|
|data/levels.json/67/reward_gold_mult|0.32|0.18781941|0.58693567|
|data/levels.json/68/reward_gold_mult|0.31|0.18171436|0.58617535|
|data/levels.json/69/reward_gold_mult|0.31|0.18147897|0.58541602|
|data/levels.json/70/reward_gold_mult|0.3|0.1753973|0.58465767|
|data/levels.json/71/reward_gold_mult|0.3|0.17517009|0.5839003|
|data/levels.json/72/reward_gold_mult|0.3|0.17494318|0.58314392|
|data/levels.json/73/reward_gold_mult|0.29|0.16889267|0.58238851|
|data/levels.json/74/reward_gold_mult|0.29|0.16867389|0.58163409|
|data/levels.json/75/reward_gold_mult|0.29|0.16845538|0.58088064|
|data/levels.json/76/reward_gold_mult|0.28|0.16243589|0.58012816|
|data/levels.json/77/reward_gold_mult|0.28|0.16222547|0.57937667|
|data/levels.json/78/reward_gold_mult|0.28|0.16201532|0.57862614|
|data/levels.json/79/reward_gold_mult|0.27|0.15602668|0.57787659|
|data/levels.json/80/reward_gold_mult|0.27|0.15582456|0.57712801|
|data/levels.json/81/reward_gold_mult|0.26|0.1498589|0.57638039|
|data/levels.json/82/reward_gold_mult|0.26|0.14966477|0.57563375|
|data/levels.json/83/reward_gold_mult|0.26|0.1494709|0.57488807|
|data/levels.json/84/reward_gold_mult|0.26|0.14927727|0.57414336|
|data/levels.json/85/reward_gold_mult|0.26|0.1490839|0.57339962|
|data/levels.json/86/reward_gold_mult|0.26|0.14889078|0.57265683|
|data/levels.json/87/reward_gold_mult|0.26|0.1486979|0.57191501|
|data/levels.json/88/reward_gold_mult|0.26|0.14850528|0.57117415|
|data/levels.json/89/reward_gold_mult|0.26|0.14831291|0.57043425|
|data/levels.json/90/reward_gold_mult|0.26|0.14812078|0.56969531|
|data/levels.json/91/reward_gold_mult|0.26|0.14792891|0.56895733|
|data/levels.json/92/reward_gold_mult|0.26|0.14773728|0.5682203|
|data/levels.json/93/reward_gold_mult|0.26|0.1475459|0.56748423|
|data/levels.json/94/reward_gold_mult|0.26|0.14735477|0.56674911|
|data/levels.json/95/reward_gold_mult|0.26|0.14716388|0.56601494|
|data/levels.json/96/reward_gold_mult|0.26|0.14697325|0.56528172|
|data/levels.json/97/reward_gold_mult|0.26|0.14678286|0.56454946|
|data/levels.json/98/reward_gold_mult|0.26|0.14659272|0.56381814|
|data/weapons.json/weapon_railgun/unlock_cost_star|14|13|0.96159659|
|data/weapons.json/weapon_plasmacannon/unlock_cost_star|16|15|0.96159659|
|data/armors.json/armor_reactive/unlock_cost_star|14|13|0.96159659|
|data/chips.json/chip_element/unlock_cost_star|14|13|0.96159659|
|data/pets.json/pet_collector/unlock_cost_star|14|13|0.96159659|
|data/economy.json/skill_base_xp_costs/0|350|389|1.1123851|
|data/economy.json/skill_base_xp_costs/1|900|983|1.0921104|
|data/economy.json/skill_base_xp_costs/2|2000|1606|0.80307542|
|data/economy.json/skill_base_xp_costs/3|4000|3040|0.75997445|
|data/economy.json/skill_base_xp_costs/4|8500|4714|0.55455771|
|data/economy.json/sig_skill_xp_costs/0|450|293|0.65033526|
|data/economy.json/sig_skill_xp_costs/1|1200|914|0.76138404|
|data/economy.json/sig_skill_xp_costs/2|2700|3364|1.2459814|
|data/economy.json/sig_skill_xp_costs/3|5400|6979|1.2924836|
|data/economy.json/sig_skill_xp_costs/4|11000|19091|1.7355374|
|data/weapons.json/weapon_autocannon/cost_base_gold|100|200|2|
|data/weapons.json/weapon_flamethrower/cost_base_gold|180|148|0.82149159|
|data/weapons.json/weapon_cryocannon/cost_base_gold|180|195|1.0824193|
|data/weapons.json/weapon_teslacoil/cost_base_gold|240|130|0.54164353|
|data/weapons.json/weapon_venomlauncher/cost_base_gold|240|311|1.2941092|
|data/weapons.json/weapon_railgun/cost_base_gold|320|264|0.82384872|
|data/weapons.json/weapon_scattergun/cost_base_gold|180|313|1.7409122|
|data/weapons.json/weapon_plasmacannon/cost_base_gold|320|169|0.5295774|

|关卡|rec|E|旧P|新P|新R|新P/E|下限|上限|达标|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
|001|50|65|65|65|1.3000|1.0000|48|71|True|
|002|50|65|69|66|1.3200|1.0154|48|71|True|
|003|50|65|73|70|1.4000|1.0769|48|71|True|
|004|64|65|74|71|1.1094|1.0923|61|71|True|
|005|76|76|81|77|1.0132|1.0132|76|83|True|
|006|53|76|82|82|1.5472|1.0789|51|83|True|
|007|53|76|89|87|1.6415|1.1447|53|83|False|
|008|79|79|96|90|1.1392|1.1392|79|86|False|
|009|79|79|106|94|1.1899|1.1899|79|86|False|
|010|87|87|112|102|1.1724|1.1724|87|95|False|
|011|99|99|116|106|1.0707|1.0707|95|108|True|
|012|108|108|122|107|0.9907|0.9907|103|118|True|
|013|131|131|131|135|1.0305|1.0305|125|144|True|
|014|138|138|141|142|1.0290|1.0290|132|151|True|
|015|147|147|151|157|1.0680|1.0680|147|161|True|
|016|98|147|152|158|1.6122|1.0748|94|161|True|
|017|165|165|166|167|1.0121|1.0121|165|181|True|
|018|185|185|207|202|1.0919|1.0919|185|203|True|
|019|188|188|210|203|1.0798|1.0798|188|206|True|
|020|291|291|291|297|1.0206|1.0206|0|320|True|
|021|164|291|323|300|1.8293|1.0309|156|320|True|
|022|183|291|339|300|1.6393|1.0309|174|320|True|
|023|186|291|355|304|1.6344|1.0447|177|320|True|
|024|201|291|374|311|1.5473|1.0687|191|320|True|
|025|260|291|410|317|1.2192|1.0893|260|320|True|
|026|226|291|410|317|1.4027|1.0893|215|320|True|
|027|195|291|410|333|1.7077|1.1443|195|320|False|
|028|231|291|474|339|1.4675|1.1649|231|320|False|
|029|206|291|509|348|1.6893|1.1959|206|320|False|
|030|332|332|515|348|1.0482|1.0482|332|365|True|
|031|159|332|522|360|2.2642|1.0843|152|365|True|
|032|245|332|530|360|1.4694|1.0843|233|365|True|
|033|228|332|573|360|1.5789|1.0843|217|365|True|
|034|330|332|573|360|1.0909|1.0843|314|365|True|
|035|219|332|648|360|1.6438|1.0843|219|365|True|
|036|225|332|679|360|1.6000|1.0843|214|365|True|
|037|232|332|685|412|1.7759|1.2410|232|365|False|
|038|484|484|710|484|1.0000|1.0000|484|532|True|
|039|533|533|849|539|1.0113|1.0113|0|586|True|
|040|574|574|849|641|1.1167|1.1167|574|631|False|
|041|236|574|880|641|2.7161|1.1167|225|631|False|
|042|375|574|942|641|1.7093|1.1167|357|631|False|
|043|587|587|951|657|1.1193|1.1193|558|645|False|
|044|757|757|957|740|0.9775|0.9775|0|832|True|
|045|655|757|963|740|1.1298|0.9775|655|832|True|
|046|600|757|972|740|1.2333|0.9775|570|832|True|
|047|670|757|983|796|1.1881|1.0515|670|832|True|
|048|663|757|983|796|1.2006|1.0515|663|832|True|
|049|658|757|1008|796|1.2097|1.0515|658|832|True|
|050|868|868|1068|945|1.0887|1.0887|868|954|True|
|051|431|868|1185|949|2.2019|1.0933|410|954|True|
|052|349|868|1185|949|2.7192|1.0933|332|954|True|
|053|427|868|1185|952|2.2295|1.0968|406|954|True|
|054|359|868|1185|986|2.7465|1.1359|342|954|False|
|055|950|950|1185|986|1.0379|1.0379|950|1045|True|
|056|354|950|1237|986|2.7853|1.0379|337|1045|True|
|057|990|990|1237|994|1.0040|1.0040|990|1089|True|
|058|503|990|1284|994|1.9761|1.0040|503|1089|True|
|059|562|990|1284|994|1.7687|1.0040|562|1089|True|
|060|990|990|1300|994|1.0040|1.0040|990|1089|True|
|061|990|990|1491|996|1.0061|1.0061|941|1089|True|
|062|250|990|1577|996|3.9840|1.0061|238|1089|True|
|063|576|990|1763|996|1.7292|1.0061|548|1089|True|
|064|955|990|1763|996|1.0429|1.0061|908|1089|True|
|065|1014|1014|1813|1033|1.0187|1.0187|1014|1115|True|
|066|1184|1184|1813|1294|1.0929|1.0929|1125|1302|True|
|067|955|1184|1813|1294|1.3550|1.0929|955|1302|True|
|068|1042|1184|1814|1294|1.2418|1.0929|1042|1302|True|
|069|978|1184|2043|1294|1.3231|1.0929|978|1302|True|
|070|1286|1286|2043|1317|1.0241|1.0241|1286|1414|True|
|071|1146|1286|2202|1317|1.1492|1.0241|1089|1414|True|
|072|1576|1576|2308|1543|0.9791|0.9791|1498|1733|True|
|073|818|1576|2308|1543|1.8863|0.9791|778|1733|True|
|074|2034|2034|2429|2004|0.9853|0.9853|0|2237|True|
|075|1841|2034|2733|2004|1.0885|0.9853|1841|2237|True|
|076|2758|2758|2989|2688|0.9746|0.9746|0|3033|True|
|077|1652|2758|3160|2688|1.6271|0.9746|1652|3033|True|
|078|2226|2758|3160|2688|1.2075|0.9746|2226|3033|True|
|079|2030|2758|3160|2688|1.3241|0.9746|2030|3033|True|
|080|2067|2758|3220|2688|1.3004|0.9746|2067|3033|True|
|081|1096|2758|3270|2688|2.4526|0.9746|1042|3033|True|
|082|1762|2758|3270|2688|1.5255|0.9746|1674|3033|True|
|083|1815|2758|3270|2688|1.4810|0.9746|1725|3033|True|
|084|1265|2758|3271|2688|2.1249|0.9746|1202|3033|True|
|085|2204|2758|3271|2688|1.2196|0.9746|2204|3033|True|
|086|1855|2758|3538|2688|1.4491|0.9746|1763|3033|True|
|087|1857|2758|3639|2688|1.4475|0.9746|1857|3033|True|
|088|1857|2758|3700|2688|1.4475|0.9746|1857|3033|True|
|089|1994|2758|3974|2688|1.3480|0.9746|1994|3033|True|
|090|2751|2758|3994|2983|1.0843|1.0816|2751|3033|True|
|091|1234|2758|4401|2983|2.4173|1.0816|1173|3033|True|
|092|1862|2758|4401|2983|1.6020|1.0816|1769|3033|True|
|093|2266|2758|4404|2983|1.3164|1.0816|2153|3033|True|
|094|1830|2758|4406|2983|1.6301|1.0816|1739|3033|True|
|095|3370|3370|4415|3441|1.0211|1.0211|0|3707|True|
|096|2429|3370|4415|3441|1.4166|1.0211|2308|3707|True|
|097|1863|3370|4415|3614|1.9399|1.0724|1863|3707|True|
|098|2720|3370|5163|3614|1.3287|1.0724|2720|3707|True|
|099|3094|3370|5283|3614|1.1681|1.0724|3094|3707|True|

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

首次R<0.95：None；G1走廊不满足关数：13/99。

包络目标Σ|P−E|/E：5.923432。

回刷总数：121（非门17，门104）；各章非门：{'1': 2, '2': 5, '3': 0, '4': 1, '5': 0, '6': 0, '7': 1, '8': 3, '9': 5, '10': 0}。
门关：[20, 39, 44, 74, 76, 95]；预算后新增门：[39, 44, 74]；未刷够门：[]；非门失败：[7, 8, 9, 10, 27, 28, 29, 37, 40, 41, 42, 43, 54]。

|回刷位置|路线(挑战/普通)|入场P|回刷后P|次数|非门章累计|刷够|八墙关|门高度/路线注记|
|---|---|---:|---:|---:|---:|---|---|---|
|005|004挑, 003挑|74|77|2|2|True|False|非门|
|013|012挑, 011挑, 010挑|123|135|3|3|True|False|非门|
|017|016挑, 015挑|159|167|2|5|True|True|非门|
|020|019挑, 018挑, 017挑, 014挑, 013挑, 009挑, 008挑, 007挑, 006挑, 005挑, 002挑, 001挑, 019普, 019普, 019普, 019普, 019普|203|297|17|5|True|True|17 / 仅挑战 / Owner fixed gate|
|038|037挑|473|484|1|1|True|False|非门|
|039|038挑, 036挑, 035挑, 034挑, 033挑, 032挑, 031挑, 030挑, 029挑, 028挑, 027挑, 026挑, 025挑, 024挑, 023挑, 022挑|484|539|16|1|True|False|16 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|044|043挑, 042挑, 041挑, 040挑, 039挑, 021挑, 020挑, 043普|657|740|8|0|True|True|8 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|066|065挑|1033|1294|1|1|True|False|非门|
|072|071挑, 070挑, 069挑|1317|1543|3|3|True|False|非门|
|074|073挑, 072挑, 068挑, 067挑, 066挑, 064挑, 063挑, 062挑, 061挑, 060挑, 059挑, 058挑, 057挑, 056挑, 055挑, 054挑, 053挑, 052挑, 051挑, 050挑, 049挑, 048挑, 047挑, 046挑, 045挑, 044挑, 073普, 073普, 073普, 073普|1543|2004|30|3|True|False|30 / 可付费（未做运行时验证） / challenge-first route still exceeds chapter remaining budget|
|076|075挑, 074挑, 075普, 075普, 075普, 075普, 075普, 075普, 075普, 075普, 075普, 075普, 075普, 075普, 075普, 075普|2004|2688|16|3|True|True|16 / 可付费（未做运行时验证） / Owner fixed gate|
|090|089挑, 088挑, 087挑, 086挑, 085挑|2688|2983|5|5|True|False|非门|
|095|094挑, 093挑, 092挑, 091挑, 090挑, 084挑, 083挑, 082挑, 081挑, 080挑, 079挑, 078挑, 077挑, 076挑, 094普, 094普, 094普|2983|3441|17|0|True|False|17 / 可付费（未做运行时验证） / Owner fixed gate|

## 门关高度（含无需回刷的固定门）

|门|高度|已刷够|路径|原因|
|---|---:|---|---|---|
|020|17|True|仅挑战|Owner fixed gate|
|039|16|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|044|8|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|074|30|True|可付费（未做运行时验证）|challenge-first route still exceeds chapter remaining budget|
|076|16|True|可付费（未做运行时验证）|Owner fixed gate|
|095|17|True|可付费（未做运行时验证）|Owner fixed gate|

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|当关/章累计回刷|
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
|001|0|65|50|1.3000|65|1.0000|302|weapon_autocannon 1→2|0/0|
|002|302|66|50|1.3200|65|1.0154|400|vanguard 1→2; weapon_autocannon 2→3; skill_multishot 0→1|0/0|
|003|702|70|50|1.4000|65|1.0769|475|weapon_cryocannon; weapon_autocannon 3→4; skill_pierce 0→1|0/0|
|004|1177|71|64|1.1094|65|1.0923|581|vanguard 2→3; weapon_cryocannon 1→2; skill_homing 0→1; signature 0→1|0/0|
|005|2584|77|76|1.0132|76|1.0132|657|armor_kevlar 1→3; vanguard 3→4; skill_charge_shot 0→1|2/2|
|006|3241|82|53|1.5472|76|1.0789|707|chip_attack; chip_attack 1→4; skill_slow_field 0→1|0/2|
|007|3948|87|53|1.6415|76|1.1447|763|weapon_autocannon 5→6; skill_split_shot 0→1|0/2|
|008|4711|90|79|1.1392|79|1.1392|947|weapon_autocannon 6→7; skill_critical 0→1; skill_ricochet 0→1|0/2|
|009|5658|94|79|1.1899|79|1.1899|727|pet_turret_drone; pet_turret_drone 1→3; weapon_cryocannon 3→4|0/2|
|010|6385|102|87|1.1724|87|1.1724|791|armor_kevlar 3→4; weapon_cryocannon 4→5; signature 1→2|0/2|
|011|7176|106|99|1.0707|99|1.0707|1175|weapon_autocannon 7→8|0/0|
|012|8351|107|108|0.9907|108|0.9907|1206|weapon_scattergun; vanguard 4→5; weapon_scattergun 1→3; skill_multishot 1→2|0/0|
|013|12025|135|131|1.0305|131|1.0305|1357|weapon_railgun; chip_attack 4→5; weapon_railgun 1→2; weapon_scattergun 4→5|3/3|
|014|13382|142|138|1.0290|138|1.0290|1340|weapon_scattergun 5→6; skill_barrier 1→2|0/3|
|015|14722|157|147|1.0680|147|1.0680|892|armor_kevlar 4→5; weapon_railgun 2→3|0/3|
|016|15614|158|98|1.6122|147|1.0748|1708|chip_attack 5→6; weapon_scattergun 6→7; skill_salvo 1→2|0/3|
|017|19305|167|165|1.0121|165|1.0121|1710|weapon_scattergun 7→8; skill_slow_field 1→2|2/5|
|018|21015|202|185|1.0919|185|1.0919|1372|armor_kevlar 5→6; weapon_railgun 5→6; skill_split_shot 1→2|0/5|
|019|22387|203|188|1.0798|188|1.0798|1906|weapon_scattergun 8→9|0/5|
|020|41553|297|291|1.0206|291|1.0206|1976|weapon_scattergun 9→10|17/5|
|021|43529|300|164|1.8293|291|1.0309|1772|weapon_venomlauncher; weapon_venomlauncher 1→4; skill_salvo 2→3|0/0|
|022|45301|300|183|1.6393|291|1.0309|1952|weapon_scattergun 10→11|0/0|
|023|47253|304|186|1.6344|291|1.0447|2257|weapon_venomlauncher 4→6; skill_charge_shot 2→3|0/0|
|024|49510|311|201|1.5473|291|1.0687|2060|chip_attack 8→9; weapon_venomlauncher 6→7|0/0|
|025|51570|317|260|1.2192|291|1.0893|1499|weapon_venomlauncher 7→8|0/0|
|026|53069|317|226|1.4027|291|1.0893|2543|weapon_scattergun 11→12; skill_slow_field 2→3|0/0|
|027|55612|333|195|1.7077|291|1.1443|2305|pet_turret_drone 6→7; weapon_venomlauncher 8→9|0/0|
|028|57917|339|231|1.4675|291|1.1649|2470|chip_attack 9→10; weapon_railgun 9→10; skill_split_shot 2→3|0/0|
|029|60387|348|206|1.6893|291|1.1959|2518|weapon_venomlauncher 9→10|0/0|
|030|62905|348|332|1.0482|332|1.0482|2067|vanguard 9→10; weapon_autocannon 11→12; skill_critical 2→3|0/0|
|031|64972|360|159|2.2642|332|1.0843|2920|weapon_flamethrower; weapon_flamethrower 1→7|0/0|
|032|67892|360|245|1.4694|332|1.0843|2707|weapon_plasmacannon; weapon_flamethrower 7→8; weapon_plasmacannon 1→6; skill_ricochet 2→3|0/0|
|033|70599|360|228|1.5789|332|1.0843|2479|weapon_flamethrower 8→9; weapon_plasmacannon 6→8|0/0|
|034|73078|360|330|1.0909|332|1.0843|3037|weapon_flamethrower 9→10; weapon_plasmacannon 8→10|0/0|
|035|76115|360|219|1.6438|332|1.0843|2305|weapon_flamethrower 10→11; weapon_plasmacannon 10→11|0/0|
|036|78420|360|225|1.6000|332|1.0843|3089|armor_kevlar 8→9; weapon_cryocannon 10→11; weapon_flamethrower 11→12; signature 2→3|0/0|
|037|81509|412|232|1.7759|332|1.2410|3455|chip_attack 10→11; weapon_scattergun 12→13|0/0|
|038|87739|484|484|1.0000|484|1.0000|3676|weapon_flamethrower 12→13; weapon_venomlauncher 10→11|1/1|
|039|122520|539|533|1.0113|533|1.0113|3167|weapon_scattergun 14→15; skill_charge_shot 3→4|16/1|
|040|125687|641|574|1.1167|574|1.1167|4136|weapon_flamethrower 14→15; weapon_venomlauncher 12→13|0/1|
|041|129823|641|236|2.7161|574|1.1167|4062|weapon_teslacoil; weapon_teslacoil 1→9|0/0|
|042|133885|641|375|1.7093|574|1.1167|3757|weapon_scattergun 15→16; weapon_teslacoil 9→10; skill_slow_field 3→4|0/0|
|043|137642|657|587|1.1193|587|1.1193|4273|weapon_teslacoil 10→14|0/0|
|044|163990|740|757|0.9775|757|0.9775|4140|weapon_autocannon 16→17; weapon_teslacoil 15→16|8/0|
|045|168130|740|655|1.1298|757|0.9775|4255|armor_kevlar 11→12; weapon_cryocannon 14→15; weapon_teslacoil 16→17|0/0|
|046|172385|740|600|1.2333|757|0.9775|3668|weapon_scattergun 18→19|0/0|
|047|176053|796|670|1.1881|757|1.0515|4060|weapon_autocannon 17→18; weapon_teslacoil 17→18|0/0|
|048|180113|796|663|1.2006|757|1.0515|4683|weapon_railgun 14→15; weapon_teslacoil 18→19|0/0|
|049|184796|796|658|1.2097|757|1.0515|4654|weapon_scattergun 19→20; signature 3→4|0/0|
|050|189450|945|868|1.0887|868|1.0887|3479|chip_attack 13→14; weapon_venomlauncher 14→15|0/0|
|051|192929|949|431|2.2019|868|1.0933|1570|weapon_flamethrower 15→16|0/0|
|052|194499|949|349|2.7192|868|1.0933|1744|weapon_plasmacannon 15→16; skill_multishot 4→5|0/0|
|053|196243|952|427|2.2295|868|1.0968|1715|vanguard 14→15|0/0|
|054|197958|986|359|2.7465|868|1.1359|1745|weapon_flamethrower 16→17|0/0|
|055|199703|986|950|1.0379|950|1.0379|1775|weapon_cryocannon 15→16; skill_pierce 4→5|0/0|
|056|201478|986|354|2.7853|950|1.0379|1682|vanguard 15→16|0/0|
|057|203160|994|990|1.0040|990|1.0040|2980|weapon_railgun 15→16|0/0|
|058|206140|994|503|1.9761|990|1.0040|1919|weapon_plasmacannon 16→17; skill_homing 4→5|0/0|
|059|208059|994|562|1.7687|990|1.0040|1868|weapon_flamethrower 17→18|0/0|
|060|209927|994|990|1.0040|990|1.0040|3958|pet_turret_drone 9→10; weapon_venomlauncher 15→16|0/0|
|061|213885|996|990|1.0061|990|1.0061|2301|weapon_cryocannon 16→17; skill_barrier 4→5|0/0|
|062|216186|996|250|3.9840|990|1.0061|2365|weapon_plasmacannon 17→18|0/0|
|063|218551|996|576|1.7292|990|1.0061|2204|weapon_autocannon 18→19|0/0|
|064|220755|996|955|1.0429|990|1.0061|2216|vanguard 16→17; skill_salvo 4→5|0/0|
|065|222971|1033|1014|1.0187|1014|1.0187|2590|weapon_railgun 16→17|0/0|
|066|226937|1294|1184|1.0929|1184|1.0929|2155|weapon_cryocannon 17→18|1/1|
|067|229092|1294|955|1.3550|1184|1.0929|2893|weapon_autocannon 19→20; skill_slow_field 4→5|0/1|
|068|231985|1294|1042|1.2418|1184|1.0929|2650|weapon_autocannon 20→21|0/1|
|069|234635|1294|978|1.3231|1184|1.0929|2742|chip_attack 14→15; weapon_flamethrower 18→19|0/1|
|070|237377|1317|1286|1.0241|1286|1.0241|2639|weapon_plasmacannon 18→19; skill_split_shot 4→5|0/1|
|071|240016|1317|1146|1.1492|1286|1.0241|2388|weapon_cryocannon 18→19|0/0|
|072|246225|1543|1576|0.9791|1576|0.9791|2259|weapon_teslacoil 19→20|3/3|
|073|248484|1543|818|1.8863|1576|0.9791|2464|weapon_autocannon 21→22|0/3|
|074|299214|2004|2034|0.9853|2034|0.9853|3002|weapon_flamethrower 20→21|30/3|
|075|302216|2004|1841|1.0885|2034|0.9853|3089|weapon_venomlauncher 17→18|0/3|
|076|331959|2688|2758|0.9746|2758|0.9746|2723|weapon_plasmacannon 20→21|16/3|
|077|334682|2688|1652|1.6271|2758|0.9746|3077|weapon_cryocannon 20→21|0/3|
|078|337759|2688|2226|1.2075|2758|0.9746|2843|weapon_autocannon 23→24|0/3|
|079|340602|2688|2030|1.3241|2758|0.9746|3089|weapon_flamethrower 21→22|0/3|
|080|343691|2688|2067|1.3004|2758|0.9746|3389|weapon_venomlauncher 18→19|0/3|
|081|347080|2688|1096|2.4526|2758|0.9746|2665|weapon_plasmacannon 21→22|0/0|
|082|349745|2688|1762|1.5255|2758|0.9746|2663|weapon_cryocannon 21→22|0/0|
|083|352408|2688|1815|1.4810|2758|0.9746|3120|weapon_autocannon 24→25|0/0|
|084|355528|2688|1265|2.1249|2758|0.9746|2727|weapon_flamethrower 22→23|0/0|
|085|358255|2688|2204|1.2196|2758|0.9746|3744|weapon_railgun 20→21|0/0|
|086|361999|2688|1855|1.4491|2758|0.9746|3507|weapon_plasmacannon 22→23|0/0|
|087|365506|2688|1857|1.4475|2758|0.9746|3457|weapon_venomlauncher 19→20|0/0|
|088|368963|2688|1857|1.4475|2758|0.9746|3190|weapon_cryocannon 22→23|0/0|
|089|372153|2688|1994|1.3480|2758|0.9746|3451|weapon_railgun 21→22|0/0|
|090|384581|2983|2751|1.0843|2758|1.0816|2973|weapon_plasmacannon 23→24|5/5|
|091|387554|2983|1234|2.4173|2758|1.0816|2917|weapon_autocannon 25→26|0/0|
|092|390471|2983|1862|1.6020|2758|1.0816|4115|weapon_railgun 22→23|0/0|
|093|394586|2983|2266|1.3164|2758|1.0816|3543|weapon_cryocannon 23→24|0/0|
|094|398129|2983|1830|1.6301|2758|1.0816|3846|weapon_autocannon 26→27|0/0|
|095|429082|3441|3370|1.0211|3370|1.0211|3582|weapon_cryocannon 24→25|17/0|
|096|432664|3441|2429|1.4166|3370|1.0211|4698|weapon_scattergun 21→22|0/0|
|097|437362|3614|1863|1.9399|3370|1.0724|4393|weapon_venomlauncher 20→21|0/0|
|098|441755|3614|2720|1.3287|3370|1.0724|4377|weapon_railgun 23→24|0/0|
|099|446132|3614|3094|1.1681|3370|1.0724|3827|weapon_autocannon 27→28|0/0|
