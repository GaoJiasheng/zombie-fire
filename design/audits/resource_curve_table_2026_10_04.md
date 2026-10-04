状态：SEARCH_CANDIDATE_NOT_YET_FEASIBLE；待Fable签字，游戏数据未写入。

# 资源表 C 候选

离线假定3★首通与上一关回刷，每章最多6次；不是新运行时胜率。既有账户策略与P(g)/F(g)冻结。所有因子限定[0.5,2.0]。
优化前：74/99失败，目标25.563564。
优化后：18/99失败，目标7.936772。

缩放系数与逐字段旧/新对照完整列于同名JSON；所有候选仅在内存模拟。

|曲线|缩放系数/形式|
|---|---|
|first_clear_gold|[-0.34853068198996306, -0.3446164985699822]；existing authored per-level values × exp(a+b*(L-1)/98)|
|kill_gold_mult|[-0.5101318148712112, -0.168535190670553]；existing authored per-level values × exp(a+b*(L-1)/98)|
|free_unlock_star|1.0042556053791614；existing free star tiers × constant|
|skill_base_xp_costs|[1.0088667326941962, 1.1169215364183809, 1.4750963937990744, 1.6829363567660056, 1.7210840034052919]；same five authored cost tiers times positive monotone factors|
|sig_skill_xp_costs|[0.871336417055634, 0.8917704623459298, 0.9036935128924484, 0.9975462223414078, 1.3240797853307809]；same five authored cost tiers times positive monotone factors|
|weapon_cost.weapon_autocannon|1.8746604082207952；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_flamethrower|1.3694002976685395；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_cryocannon|0.7270569814769955；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_teslacoil|1.8024169003640462；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_venomlauncher|0.5998577067298161；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_railgun|1.1770028027012027；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_scattergun|0.8809692636941789；same existing linear upgrade formula × constant base cost|
|weapon_cost.weapon_plasmacannon|1.3405657055008122；same existing linear upgrade formula × constant base cost|

|文件/字段|旧值|候选新值|系数|
|---|---:|---:|---:|
|data/levels.json/0/first_clear_reward/gold|119|84|0.70572426|
|data/levels.json/1/first_clear_reward/gold|143|101|0.70324694|
|data/levels.json/2/first_clear_reward/gold|167|117|0.70077832|
|data/levels.json/3/first_clear_reward/gold|192|134|0.69831837|
|data/levels.json/4/first_clear_reward/gold|216|150|0.69586705|
|data/levels.json/5/first_clear_reward/gold|241|167|0.69342433|
|data/levels.json/6/first_clear_reward/gold|266|184|0.69099019|
|data/levels.json/7/first_clear_reward/gold|291|200|0.68856459|
|data/levels.json/8/first_clear_reward/gold|315|216|0.68614751|
|data/levels.json/9/first_clear_reward/gold|340|232|0.68373892|
|data/levels.json/10/first_clear_reward/gold|366|249|0.68133877|
|data/levels.json/11/first_clear_reward/gold|391|265|0.67894706|
|data/levels.json/12/first_clear_reward/gold|416|281|0.67656374|
|data/levels.json/13/first_clear_reward/gold|442|298|0.67418878|
|data/levels.json/14/first_clear_reward/gold|467|314|0.67182216|
|data/levels.json/15/first_clear_reward/gold|493|330|0.66946385|
|data/levels.json/16/first_clear_reward/gold|519|346|0.66711382|
|data/levels.json/17/first_clear_reward/gold|545|362|0.66477204|
|data/levels.json/18/first_clear_reward/gold|571|378|0.66243848|
|data/levels.json/19/first_clear_reward/gold|597|394|0.66011311|
|data/levels.json/20/first_clear_reward/gold|623|410|0.6577959|
|data/levels.json/21/first_clear_reward/gold|650|426|0.65548683|
|data/levels.json/22/first_clear_reward/gold|676|442|0.65318586|
|data/levels.json/23/first_clear_reward/gold|703|458|0.65089297|
|data/levels.json/24/first_clear_reward/gold|729|473|0.64860812|
|data/levels.json/25/first_clear_reward/gold|756|489|0.6463313|
|data/levels.json/26/first_clear_reward/gold|783|504|0.64406247|
|data/levels.json/27/first_clear_reward/gold|810|520|0.64180161|
|data/levels.json/28/first_clear_reward/gold|837|535|0.63954868|
|data/levels.json/29/first_clear_reward/gold|864|551|0.63730366|
|data/levels.json/30/first_clear_reward/gold|892|566|0.63506652|
|data/levels.json/31/first_clear_reward/gold|919|582|0.63283723|
|data/levels.json/32/first_clear_reward/gold|947|597|0.63061577|
|data/levels.json/33/first_clear_reward/gold|975|613|0.62840211|
|data/levels.json/34/first_clear_reward/gold|1002|627|0.62619622|
|data/levels.json/35/first_clear_reward/gold|1030|643|0.62399807|
|data/levels.json/36/first_clear_reward/gold|1058|658|0.62180764|
|data/levels.json/37/first_clear_reward/gold|1086|673|0.61962489|
|data/levels.json/38/first_clear_reward/gold|1115|688|0.61744981|
|data/levels.json/39/first_clear_reward/gold|1143|703|0.61528237|
|data/levels.json/40/first_clear_reward/gold|1171|718|0.61312253|
|data/levels.json/41/first_clear_reward/gold|1200|733|0.61097027|
|data/levels.json/42/first_clear_reward/gold|1229|748|0.60882557|
|data/levels.json/43/first_clear_reward/gold|1257|763|0.6066884|
|data/levels.json/44/first_clear_reward/gold|1286|777|0.60455873|
|data/levels.json/45/first_clear_reward/gold|1315|792|0.60243654|
|data/levels.json/46/first_clear_reward/gold|1344|807|0.60032179|
|data/levels.json/47/first_clear_reward/gold|1374|822|0.59821447|
|data/levels.json/48/first_clear_reward/gold|1403|836|0.59611455|
|data/levels.json/49/first_clear_reward/gold|1432|851|0.594022|
|data/levels.json/50/first_clear_reward/gold|1462|865|0.59193679|
|data/levels.json/51/first_clear_reward/gold|1492|880|0.5898589|
|data/levels.json/52/first_clear_reward/gold|1521|894|0.58778831|
|data/levels.json/53/first_clear_reward/gold|1551|908|0.58572498|
|data/levels.json/54/first_clear_reward/gold|1581|923|0.5836689|
|data/levels.json/55/first_clear_reward/gold|1611|937|0.58162004|
|data/levels.json/56/first_clear_reward/gold|1642|952|0.57957837|
|data/levels.json/57/first_clear_reward/gold|1672|966|0.57754386|
|data/levels.json/58/first_clear_reward/gold|1702|980|0.5755165|
|data/levels.json/59/first_clear_reward/gold|1733|994|0.57349625|
|data/levels.json/60/first_clear_reward/gold|1764|1008|0.5714831|
|data/levels.json/61/first_clear_reward/gold|1794|1022|0.56947701|
|data/levels.json/62/first_clear_reward/gold|1825|1036|0.56747796|
|data/levels.json/63/first_clear_reward/gold|1856|1050|0.56548593|
|data/levels.json/64/first_clear_reward/gold|1887|1063|0.5635009|
|data/levels.json/65/first_clear_reward/gold|1919|1078|0.56152283|
|data/levels.json/66/first_clear_reward/gold|1950|1091|0.5595517|
|data/levels.json/67/first_clear_reward/gold|1981|1105|0.5575875|
|data/levels.json/68/first_clear_reward/gold|2013|1118|0.55563019|
|data/levels.json/69/first_clear_reward/gold|2044|1132|0.55367975|
|data/levels.json/70/first_clear_reward/gold|2076|1145|0.55173616|
|data/levels.json/71/first_clear_reward/gold|2108|1159|0.54979939|
|data/levels.json/72/first_clear_reward/gold|2140|1172|0.54786942|
|data/levels.json/73/first_clear_reward/gold|2172|1186|0.54594622|
|data/levels.json/74/first_clear_reward/gold|2204|1199|0.54402977|
|data/levels.json/75/first_clear_reward/gold|2237|1213|0.54212006|
|data/levels.json/76/first_clear_reward/gold|2269|1226|0.54021704|
|data/levels.json/77/first_clear_reward/gold|2302|1239|0.53832071|
|data/levels.json/78/first_clear_reward/gold|2334|1252|0.53643103|
|data/levels.json/79/first_clear_reward/gold|2367|1265|0.53454798|
|data/levels.json/80/first_clear_reward/gold|2400|1278|0.53267155|
|data/levels.json/81/first_clear_reward/gold|2433|1291|0.5308017|
|data/levels.json/82/first_clear_reward/gold|2466|1304|0.52893842|
|data/levels.json/83/first_clear_reward/gold|2499|1317|0.52708168|
|data/levels.json/84/first_clear_reward/gold|2532|1330|0.52523145|
|data/levels.json/85/first_clear_reward/gold|2566|1343|0.52338772|
|data/levels.json/86/first_clear_reward/gold|2599|1356|0.52155046|
|data/levels.json/87/first_clear_reward/gold|2633|1368|0.51971966|
|data/levels.json/88/first_clear_reward/gold|2667|1381|0.51789527|
|data/levels.json/89/first_clear_reward/gold|2700|1393|0.5160773|
|data/levels.json/90/first_clear_reward/gold|2734|1406|0.5142657|
|data/levels.json/91/first_clear_reward/gold|2769|1419|0.51246046|
|data/levels.json/92/first_clear_reward/gold|2803|1431|0.51066156|
|data/levels.json/93/first_clear_reward/gold|2837|1444|0.50886898|
|data/levels.json/94/first_clear_reward/gold|2871|1456|0.50708269|
|data/levels.json/95/first_clear_reward/gold|2906|1468|0.50530266|
|data/levels.json/96/first_clear_reward/gold|2940|1480|0.50352889|
|data/levels.json/97/first_clear_reward/gold|2975|1493|0.50176134|
|data/levels.json/98/first_clear_reward/gold|3010|1505|0.5|
|data/levels.json/0/reward_gold_mult|0.56|0.3362332|0.60041643|
|data/levels.json/1/reward_gold_mult|0.55|0.32966161|0.59938475|
|data/levels.json/2/reward_gold_mult|0.55|0.32909517|0.59835485|
|data/levels.json/3/reward_gold_mult|0.55|0.32852969|0.59732671|
|data/levels.json/4/reward_gold_mult|0.54|0.32200219|0.59630035|
|data/levels.json/5/reward_gold_mult|0.54|0.3214489|0.59527574|
|data/levels.json/6/reward_gold_mult|0.53|0.31495404|0.5942529|
|data/levels.json/7/reward_gold_mult|0.53|0.31441286|0.59323181|
|data/levels.json/8/reward_gold_mult|0.53|0.31387261|0.59221248|
|data/levels.json/9/reward_gold_mult|0.52|0.30742135|0.5911949|
|data/levels.json/10/reward_gold_mult|0.52|0.30689312|0.59017907|
|data/levels.json/11/reward_gold_mult|0.52|0.30636579|0.58916498|
|data/levels.json/12/reward_gold_mult|0.51|0.29995785|0.58815264|
|data/levels.json/13/reward_gold_mult|0.51|0.29944244|0.58714203|
|data/levels.json/14/reward_gold_mult|0.51|0.29892791|0.58613317|
|data/levels.json/15/reward_gold_mult|0.5|0.29256302|0.58512603|
|data/levels.json/16/reward_gold_mult|0.5|0.29206031|0.58412063|
|data/levels.json/17/reward_gold_mult|0.5|0.29155848|0.58311695|
|data/levels.json/18/reward_gold_mult|0.49|0.28523635|0.582115|
|data/levels.json/19/reward_gold_mult|0.49|0.28474624|0.58111477|
|data/levels.json/20/reward_gold_mult|0.48|0.2784558|0.58011626|
|data/levels.json/21/reward_gold_mult|0.48|0.27797734|0.57911946|
|data/levels.json/22/reward_gold_mult|0.48|0.2774997|0.57812438|
|data/levels.json/23/reward_gold_mult|0.47|0.27125157|0.57713101|
|data/levels.json/24/reward_gold_mult|0.47|0.27078549|0.57613934|
|data/levels.json/25/reward_gold_mult|0.47|0.27032021|0.57514938|
|data/levels.json/26/reward_gold_mult|0.46|0.26411411|0.57416112|
|data/levels.json/27/reward_gold_mult|0.46|0.26366029|0.57317455|
|data/levels.json/28/reward_gold_mult|0.46|0.26320725|0.57218968|
|data/levels.json/29/reward_gold_mult|0.45|0.25704293|0.57120651|
|data/levels.json/30/reward_gold_mult|0.45|0.25660126|0.57022502|
|data/levels.json/31/reward_gold_mult|0.44|0.2504679|0.56924522|
|data/levels.json/32/reward_gold_mult|0.44|0.25003753|0.56826711|
|data/levels.json/33/reward_gold_mult|0.44|0.24960789|0.56729067|
|data/levels.json/34/reward_gold_mult|0.43|0.24351584|0.56631591|
|data/levels.json/35/reward_gold_mult|0.43|0.24309742|0.56534283|
|data/levels.json/36/reward_gold_mult|0.43|0.24267971|0.56437142|
|data/levels.json/37/reward_gold_mult|0.42|0.2366287|0.56340168|
|data/levels.json/38/reward_gold_mult|0.42|0.23622211|0.5624336|
|data/levels.json/39/reward_gold_mult|0.42|0.23581622|0.56146719|
|data/levels.json/40/reward_gold_mult|0.41|0.229806|0.56050244|
|data/levels.json/41/reward_gold_mult|0.41|0.22941113|0.55953934|
|data/levels.json/42/reward_gold_mult|0.41|0.22901694|0.5585779|
|data/levels.json/43/reward_gold_mult|0.4|0.22304725|0.55761812|
|data/levels.json/44/reward_gold_mult|0.4|0.22266399|0.55665998|
|data/levels.json/45/reward_gold_mult|0.39|0.21672436|0.55570349|
|data/levels.json/46/reward_gold_mult|0.39|0.21635197|0.55474864|
|data/levels.json/47/reward_gold_mult|0.39|0.21598022|0.55379543|
|data/levels.json/48/reward_gold_mult|0.38|0.21008067|0.55284386|
|data/levels.json/49/reward_gold_mult|0.38|0.20971969|0.55189393|
|data/levels.json/50/reward_gold_mult|0.38|0.20935934|0.55094563|
|data/levels.json/51/reward_gold_mult|0.37|0.20349961|0.54999895|
|data/levels.json/52/reward_gold_mult|0.37|0.20314995|0.54905391|
|data/levels.json/53/reward_gold_mult|0.37|0.20280088|0.54811048|
|data/levels.json/54/reward_gold_mult|0.36|0.19698073|0.54716868|
|data/levels.json/55/reward_gold_mult|0.36|0.19664226|0.5462285|
|data/levels.json/56/reward_gold_mult|0.35|0.19085148|0.54528993|
|data/levels.json/57/reward_gold_mult|0.35|0.19052354|0.54435298|
|data/levels.json/58/reward_gold_mult|0.35|0.19019617|0.54341763|
|data/levels.json/59/reward_gold_mult|0.34|0.18444452|0.5424839|
|data/levels.json/60/reward_gold_mult|0.34|0.1841276|0.54155176|
|data/levels.json/61/reward_gold_mult|0.34|0.18381122|0.54062123|
|data/levels.json/62/reward_gold_mult|0.33|0.17809846|0.5396923|
|data/levels.json/63/reward_gold_mult|0.33|0.17779244|0.53876496|
|data/levels.json/64/reward_gold_mult|0.33|0.17748694|0.53783922|
|data/levels.json/65/reward_gold_mult|0.32|0.17181282|0.53691507|
|data/levels.json/66/reward_gold_mult|0.32|0.1715176|0.5359925|
|data/levels.json/67/reward_gold_mult|0.32|0.17122289|0.53507152|
|data/levels.json/68/reward_gold_mult|0.31|0.16558716|0.53415213|
|data/levels.json/69/reward_gold_mult|0.31|0.16530264|0.53323431|
|data/levels.json/70/reward_gold_mult|0.3|0.15969542|0.53231807|
|data/levels.json/71/reward_gold_mult|0.3|0.15942102|0.5314034|
|data/levels.json/72/reward_gold_mult|0.3|0.15914709|0.53049031|
|data/levels.json/73/reward_gold_mult|0.29|0.15357785|0.52957878|
|data/levels.json/74/reward_gold_mult|0.29|0.15331396|0.52866883|
|data/levels.json/75/reward_gold_mult|0.29|0.15305052|0.52776043|
|data/levels.json/76/reward_gold_mult|0.28|0.14751901|0.5268536|
|data/levels.json/77/reward_gold_mult|0.28|0.14726553|0.52594832|
|data/levels.json/78/reward_gold_mult|0.28|0.14701249|0.5250446|
|data/levels.json/79/reward_gold_mult|0.27|0.14151846|0.52414243|
|data/levels.json/80/reward_gold_mult|0.27|0.14127529|0.52324181|
|data/levels.json/81/reward_gold_mult|0.26|0.13580911|0.52234274|
|data/levels.json/82/reward_gold_mult|0.26|0.13557576|0.52144522|
|data/levels.json/83/reward_gold_mult|0.26|0.1353428|0.52054924|
|data/levels.json/84/reward_gold_mult|0.26|0.13511025|0.51965479|
|data/levels.json/85/reward_gold_mult|0.26|0.13487809|0.51876189|
|data/levels.json/86/reward_gold_mult|0.26|0.13464633|0.51787051|
|data/levels.json/87/reward_gold_mult|0.26|0.13441497|0.51698067|
|data/levels.json/88/reward_gold_mult|0.26|0.13418401|0.51609236|
|data/levels.json/89/reward_gold_mult|0.26|0.13395345|0.51520557|
|data/levels.json/90/reward_gold_mult|0.26|0.13372328|0.51432031|
|data/levels.json/91/reward_gold_mult|0.26|0.13349351|0.51343657|
|data/levels.json/92/reward_gold_mult|0.26|0.13326413|0.51255435|
|data/levels.json/93/reward_gold_mult|0.26|0.13303515|0.51167364|
|data/levels.json/94/reward_gold_mult|0.26|0.13280656|0.51079445|
|data/levels.json/95/reward_gold_mult|0.26|0.13257836|0.50991677|
|data/levels.json/96/reward_gold_mult|0.26|0.13235055|0.50904059|
|data/levels.json/97/reward_gold_mult|0.26|0.13212314|0.50816593|
|data/levels.json/98/reward_gold_mult|0.26|0.13189612|0.50729276|
|data/economy.json/skill_base_xp_costs/0|350|353|1.0088667|
|data/economy.json/skill_base_xp_costs/1|900|1005|1.1169215|
|data/economy.json/skill_base_xp_costs/2|2000|2950|1.4750964|
|data/economy.json/skill_base_xp_costs/3|4000|6732|1.6829364|
|data/economy.json/skill_base_xp_costs/4|8500|14629|1.721084|
|data/economy.json/sig_skill_xp_costs/0|450|392|0.87133642|
|data/economy.json/sig_skill_xp_costs/1|1200|1070|0.89177046|
|data/economy.json/sig_skill_xp_costs/2|2700|2440|0.90369351|
|data/economy.json/sig_skill_xp_costs/3|5400|5387|0.99754622|
|data/economy.json/sig_skill_xp_costs/4|11000|14565|1.3240798|
|data/weapons.json/weapon_autocannon/cost_base_gold|100|187|1.8746604|
|data/weapons.json/weapon_flamethrower/cost_base_gold|180|246|1.3694003|
|data/weapons.json/weapon_cryocannon/cost_base_gold|180|131|0.72705698|
|data/weapons.json/weapon_teslacoil/cost_base_gold|240|433|1.8024169|
|data/weapons.json/weapon_venomlauncher/cost_base_gold|240|144|0.59985771|
|data/weapons.json/weapon_railgun/cost_base_gold|320|377|1.1770028|
|data/weapons.json/weapon_scattergun/cost_base_gold|180|159|0.88096926|
|data/weapons.json/weapon_plasmacannon/cost_base_gold|320|429|1.3405657|

|关卡|rec|E|旧P|新P|新R|新P/E|下限|上限|达标|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
|001|50|65|65|65|1.3000|1.0000|48|71|True|
|002|50|65|69|66|1.3200|1.0154|48|71|True|
|003|50|65|73|70|1.4000|1.0769|48|71|True|
|004|64|65|74|71|1.1094|1.0923|61|71|True|
|005|76|76|81|77|1.0132|1.0132|76|83|True|
|006|53|76|82|82|1.5472|1.0789|51|83|True|
|007|53|76|89|84|1.5849|1.1053|53|83|False|
|008|79|79|96|86|1.0886|1.0886|79|86|True|
|009|79|79|106|94|1.1899|1.1899|79|86|False|
|010|87|87|112|100|1.1494|1.1494|87|95|False|
|011|99|99|116|100|1.0101|1.0101|95|108|True|
|012|108|108|122|117|1.0833|1.0833|103|118|True|
|013|131|131|131|127|0.9695|0.9695|125|144|True|
|014|138|138|141|136|0.9855|0.9855|132|151|True|
|015|147|147|151|157|1.0680|1.0680|147|161|True|
|016|98|147|152|158|1.6122|1.0748|94|161|True|
|017|165|165|166|162|0.9818|0.9818|165|181|False|
|018|185|185|185|200|1.0811|1.0811|185|203|True|
|019|188|188|191|200|1.0638|1.0638|188|206|True|
|020|291|291|294|204|0.7010|0.7010|291|320|False|
|021|164|291|296|204|1.2439|0.7010|156|320|True|
|022|183|291|299|204|1.1148|0.7010|174|320|True|
|023|186|291|302|205|1.1022|0.7045|177|320|True|
|024|201|291|306|207|1.0299|0.7113|191|320|True|
|025|260|291|306|268|1.0308|0.9210|260|320|True|
|026|226|291|348|293|1.2965|1.0069|215|320|True|
|027|195|291|410|297|1.5231|1.0206|195|320|True|
|028|231|291|412|300|1.2987|1.0309|231|320|True|
|029|206|291|414|314|1.5243|1.0790|206|320|True|
|030|332|332|415|314|0.9458|0.9458|332|365|False|
|031|159|332|417|314|1.9748|0.9458|152|365|True|
|032|245|332|418|325|1.3265|0.9789|233|365|True|
|033|228|332|418|325|1.4254|0.9789|217|365|True|
|034|330|332|520|325|0.9848|0.9789|314|365|True|
|035|219|332|565|325|1.4840|0.9789|219|365|True|
|036|225|332|565|325|1.4444|0.9789|214|365|True|
|037|232|332|574|340|1.4655|1.0241|232|365|True|
|038|484|484|581|502|1.0372|1.0372|484|532|True|
|039|533|533|582|537|1.0075|1.0075|533|586|True|
|040|574|574|657|552|0.9617|0.9617|574|631|False|
|041|236|574|696|574|2.4322|1.0000|225|631|True|
|042|375|574|716|579|1.5440|1.0087|357|631|True|
|043|587|587|716|580|0.9881|0.9881|558|645|True|
|044|757|757|756|742|0.9802|0.9802|720|832|True|
|045|655|757|828|783|1.1954|1.0343|655|832|True|
|046|600|757|951|826|1.3767|1.0911|570|832|True|
|047|670|757|951|826|1.2328|1.0911|670|832|True|
|048|663|757|953|826|1.2459|1.0911|663|832|True|
|049|658|757|959|871|1.3237|1.1506|658|832|False|
|050|868|868|968|903|1.0403|1.0403|868|954|True|
|051|431|868|1021|903|2.0951|1.0403|410|954|True|
|052|349|868|1021|903|2.5874|1.0403|332|954|True|
|053|427|868|1035|903|2.1148|1.0403|406|954|True|
|054|359|868|1045|903|2.5153|1.0403|342|954|True|
|055|950|950|1045|951|1.0011|1.0011|950|1045|True|
|056|354|950|1045|983|2.7768|1.0347|337|1045|True|
|057|990|990|1186|999|1.0091|1.0091|990|1089|True|
|058|503|990|1193|999|1.9861|1.0091|503|1089|True|
|059|562|990|1258|1026|1.8256|1.0364|562|1089|True|
|060|990|990|1258|1026|1.0364|1.0364|990|1089|True|
|061|990|990|1300|1076|1.0869|1.0869|941|1089|True|
|062|250|990|1381|1076|4.3040|1.0869|238|1089|True|
|063|576|990|1387|1085|1.8837|1.0960|548|1089|True|
|064|955|990|1387|1085|1.1361|1.0960|908|1089|True|
|065|1014|1014|1387|1085|1.0700|1.0700|1014|1115|True|
|066|1184|1184|1552|1206|1.0186|1.0186|1125|1302|True|
|067|955|1184|1558|1206|1.2628|1.0186|955|1302|True|
|068|1042|1184|1811|1206|1.1574|1.0186|1042|1302|True|
|069|978|1184|1811|1340|1.3701|1.1318|978|1302|False|
|070|1286|1286|2204|1340|1.0420|1.0420|1286|1414|True|
|071|1146|1286|2204|1340|1.1693|1.0420|1089|1414|True|
|072|1576|1576|2204|1515|0.9613|0.9613|1498|1733|True|
|073|818|1576|2301|1515|1.8521|0.9613|778|1733|True|
|074|2034|2034|2301|1839|0.9041|0.9041|1933|2237|False|
|075|1841|2034|2427|2011|1.0923|0.9887|1841|2237|True|
|076|2758|2758|2748|2011|0.7292|0.7292|2621|3033|False|
|077|1652|2758|2748|2027|1.2270|0.7350|1652|3033|True|
|078|2226|2758|3016|2203|0.9897|0.7988|2226|3033|False|
|079|2030|2758|3177|2203|1.0852|0.7988|2030|3033|True|
|080|2067|2758|3177|2239|1.0832|0.8118|2067|3033|True|
|081|1096|2758|3238|2239|2.0429|0.8118|1042|3033|True|
|082|1762|2758|3274|2239|1.2707|0.8118|1674|3033|True|
|083|1815|2758|3274|2369|1.3052|0.8590|1725|3033|True|
|084|1265|2758|3282|2369|1.8727|0.8590|1202|3033|True|
|085|2204|2758|3282|2369|1.0749|0.8590|2204|3033|True|
|086|1855|2758|3536|2369|1.2771|0.8590|1763|3033|True|
|087|1857|2758|3637|2369|1.2757|0.8590|1857|3033|True|
|088|1857|2758|3720|2369|1.2757|0.8590|1857|3033|True|
|089|1994|2758|3911|2477|1.2422|0.8981|1994|3033|True|
|090|2751|2758|3988|2748|0.9989|0.9964|2751|3033|False|
|091|1234|2758|3988|3048|2.4700|1.1051|1173|3033|False|
|092|1862|2758|4090|3048|1.6369|1.1051|1769|3033|False|
|093|2266|2758|4393|3048|1.3451|1.1051|2153|3033|False|
|094|1830|2758|4395|3048|1.6656|1.1051|1739|3033|False|
|095|3370|3370|5022|3323|0.9861|0.9861|3370|3707|False|
|096|2429|3370|5090|3323|1.3681|0.9861|2308|3707|True|
|097|1863|3370|5098|3323|1.7837|0.9861|1863|3707|True|
|098|2720|3370|5230|3323|1.2217|0.9861|2720|3707|True|
|099|3094|3370|5230|3323|1.0740|0.9861|3094|3707|True|

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

回刷总数：8；各章：{'1': 0, '2': 5, '3': 0, '4': 0, '5': 0, '6': 0, '7': 0, '8': 3, '9': 0, '10': 0}；墙过高/预算内未满足下限：[]。

|回刷门|前一关|入门P|回刷后P|次数|章累计|下限满足|八墙关|达到下限所需章次数(反事实)|
|---|---:|---:|---:|---:|---:|---|---|---|
|018|17|169|185|2|2|True|True|2|
|019|18|187|191|1|3|True|True|3|
|020|19|202|294|2|5|True|True|5|
|076|75|2464|2748|3|3|True|True|3|

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
|018|29388|185|185|1.0000|185|1.0000|2161|chip_attack 7→8; weapon_scattergun 12→13|2/2|
|019|33165|191|188|1.0160|188|1.0160|2977|pet_turret_drone; pet_turret_drone 1→5; weapon_scattergun 14→15; signature 1→2|1/3|
|020|40954|294|291|1.0103|291|1.0103|3195|weapon_railgun 5→6; weapon_scattergun 17→18; skill_split_shot 1→2|2/5|
|021|44149|296|164|1.8049|291|1.0172|2916|weapon_venomlauncher; weapon_scattergun 18→19; weapon_venomlauncher 1→3|0/0|
|022|47065|299|183|1.6339|291|1.0275|3177|weapon_scattergun 19→20; weapon_venomlauncher 3→4; skill_critical 1→2|0/0|
|023|50242|302|186|1.6237|291|1.0378|3563|pet_turret_drone 5→6; weapon_scattergun 20→21; weapon_venomlauncher 4→5; skill_ricochet 1→2|0/0|
|024|53805|306|201|1.5224|291|1.0515|3343|weapon_venomlauncher 5→8|0/0|
|025|57148|306|260|1.1769|291|1.0515|2321|vanguard 9→10; weapon_railgun 6→7|0/0|
|026|59469|348|226|1.5398|291|1.1959|3935|chip_attack 8→9; weapon_railgun 7→8; weapon_venomlauncher 8→9; skill_multishot 2→3|0/0|
|027|63404|410|195|2.1026|291|1.4089|3720|weapon_cryocannon 8→9; weapon_scattergun 21→22|0/0|
|028|67124|412|231|1.7835|291|1.4158|4002|armor_kevlar 7→8; weapon_railgun 8→9; weapon_venomlauncher 9→10; skill_pierce 2→3|0/0|
|029|71126|414|206|2.0097|291|1.4227|4148|weapon_cryocannon 9→10; weapon_scattergun 22→23|0/0|
|030|75274|415|332|1.2500|332|1.2500|3328|chip_attack 9→10; weapon_scattergun 23→24|0/0|
|031|78602|417|159|2.6226|332|1.2560|4714|weapon_flamethrower; weapon_flamethrower 1→5; weapon_scattergun 24→25; skill_homing 2→3|0/0|
|032|83316|418|245|1.7061|332|1.2590|4420|weapon_plasmacannon; weapon_flamethrower 5→7; weapon_plasmacannon 1→5|0/0|
|033|87736|418|228|1.8333|332|1.2590|3968|weapon_flamethrower 7→8; weapon_scattergun 25→26; skill_barrier 2→3|0/0|
|034|91704|520|330|1.5758|332|1.5663|4994|armor_kevlar 8→9; weapon_flamethrower 8→9; weapon_scattergun 26→27|0/0|
|035|96698|565|219|2.5799|332|1.7018|3689|weapon_flamethrower 9→10; weapon_plasmacannon 5→7; skill_salvo 2→3|0/0|
|036|100387|565|225|2.5111|332|1.7018|4999|weapon_flamethrower 10→11; weapon_scattergun 27→28|0/0|
|037|105386|574|232|2.4741|332|1.7289|5600|pet_turret_drone 6→7; weapon_flamethrower 11→12; weapon_scattergun 28→29; skill_charge_shot 2→3|0/0|
|038|110986|581|484|1.2004|484|1.2004|6000|weapon_autocannon 14→15; weapon_flamethrower 12→13; weapon_scattergun 29→30|0/0|
|039|116986|582|533|1.0919|533|1.0919|5156|weapon_cryocannon 10→11; weapon_flamethrower 13→14; weapon_plasmacannon 7→8; skill_slow_field 2→3|0/0|
|040|122142|657|574|1.1446|574|1.1446|6793|vanguard 10→11; weapon_flamethrower 14→15; weapon_scattergun 30→31|0/0|
|041|128935|696|236|2.9492|574|1.2125|6462|weapon_teslacoil; weapon_scattergun 31→32; weapon_teslacoil 1→6; signature 2→3|0/0|
|042|135397|716|375|1.9093|574|1.2474|6075|weapon_plasmacannon 8→9; weapon_teslacoil 6→9|0/0|
|043|141472|716|587|1.2198|587|1.2198|7055|weapon_scattergun 32→33; weapon_teslacoil 9→11; skill_split_shot 2→3|0/0|
|044|148527|756|757|0.9987|757|0.9987|6867|chip_attack 10→11; weapon_scattergun 33→34; weapon_teslacoil 11→12|0/0|
|045|155394|828|655|1.2641|757|1.0938|7042|armor_kevlar 9→10; weapon_scattergun 34→35; weapon_teslacoil 12→13; skill_critical 2→3|0/0|
|046|162436|951|600|1.5850|757|1.2563|6022|weapon_plasmacannon 9→10; weapon_teslacoil 13→14; weapon_venomlauncher 10→11; skill_ricochet 2→3|0/0|
|047|168458|951|670|1.4194|757|1.2563|6656|pet_turret_drone 7→8; weapon_cryocannon 11→12; weapon_railgun 9→10; weapon_teslacoil 14→15|0/0|
|048|175114|953|663|1.4374|757|1.2589|7623|weapon_scattergun 35→36; weapon_teslacoil 15→16|0/0|
|049|182737|959|658|1.4574|757|1.2668|7652|chip_attack 11→12; weapon_scattergun 36→37; weapon_teslacoil 16→17|0/0|
|050|190389|968|868|1.1152|868|1.1152|5724|armor_kevlar 10→11; weapon_scattergun 37→38; skill_multishot 3→4|0/0|
|051|196113|1021|431|2.3689|868|1.1763|2522|weapon_plasmacannon 10→11|0/0|
|052|198635|1021|349|2.9255|868|1.1763|2819|pet_turret_drone 8→9; weapon_railgun 10→11|0/0|
|053|201454|1035|427|2.4239|868|1.1924|2763|chip_attack 12→13; weapon_venomlauncher 11→12; skill_pierce 3→4|0/0|
|054|204217|1045|359|2.9109|868|1.2039|2807|weapon_plasmacannon 11→12|0/0|
|055|207024|1045|950|1.1000|950|1.1000|2897|weapon_railgun 11→12; skill_homing 3→4|0/0|
|056|209921|1045|354|2.9520|950|1.1000|2693|vanguard 11→12; weapon_cryocannon 12→13|0/0|
|057|212614|1186|990|1.1980|990|1.1980|4919|weapon_scattergun 38→39|0/0|
|058|217533|1193|503|2.3718|990|1.2051|3084|weapon_autocannon 15→16; weapon_venomlauncher 12→13; skill_barrier 3→4|0/0|
|059|220617|1258|562|2.2384|990|1.2707|2995|weapon_plasmacannon 12→13|0/0|
|060|223612|1258|990|1.2707|990|1.2707|6400|weapon_cryocannon 13→14; weapon_scattergun 39→40; skill_salvo 3→4|0/0|
|061|230012|1300|990|1.3131|990|1.3131|3770|vanguard 12→13; weapon_railgun 12→13|0/0|
|062|233782|1381|250|5.5240|990|1.3949|3835|weapon_autocannon 16→17; weapon_venomlauncher 13→14; skill_charge_shot 3→4|0/0|
|063|237617|1387|576|2.4080|990|1.4010|3555|weapon_autocannon 17→18; weapon_plasmacannon 13→14|0/0|
|064|241172|1387|955|1.4524|990|1.4010|3609|weapon_railgun 13→14|0/0|
|065|244781|1387|1014|1.3679|1014|1.3679|4223|weapon_cryocannon 14→15; weapon_venomlauncher 14→15; signature 3→4|0/0|
|066|249004|1552|1184|1.3108|1184|1.3108|3497|pet_turret_drone 9→10; weapon_plasmacannon 14→15|0/0|
|067|252501|1558|955|1.6314|1184|1.3159|4705|vanguard 13→14; weapon_railgun 14→15; skill_slow_field 3→4|0/0|
|068|257206|1811|1042|1.7380|1184|1.5296|4315|weapon_cryocannon 15→16; weapon_flamethrower 15→16|0/0|
|069|261521|1811|978|1.8517|1184|1.5296|4485|armor_kevlar 11→12; vanguard 14→15; weapon_venomlauncher 15→16; skill_split_shot 3→4|0/0|
|070|266006|2204|1286|1.7138|1286|1.7138|4298|weapon_plasmacannon 15→16|0/0|
|071|270304|2204|1146|1.9232|1286|1.7138|3880|weapon_autocannon 18→19; weapon_railgun 15→16; skill_critical 3→4|0/0|
|072|274184|2204|1576|1.3985|1576|1.3985|3661|vanguard 15→16; weapon_cryocannon 16→17|0/0|
|073|277845|2301|818|2.8130|1576|1.4600|4011|weapon_autocannon 19→20; weapon_flamethrower 16→17; skill_ricochet 3→4|0/0|
|074|281856|2301|2034|1.1313|2034|1.1313|4820|weapon_scattergun 40→41|0/0|
|075|286676|2427|1841|1.3183|2034|1.1932|5072|weapon_scattergun 41→42|0/0|
|076|300352|2748|2758|0.9964|2758|0.9964|4419|armor_kevlar 12→13; weapon_plasmacannon 16→17|3/3|
|077|304771|2748|1652|1.6634|2758|0.9964|5041|weapon_scattergun 42→43|0/3|
|078|309812|3016|2226|1.3549|2758|1.0935|4662|chip_attack 14→15; weapon_railgun 16→17|0/3|
|079|314474|3177|2030|1.5650|2758|1.1519|5091|weapon_autocannon 20→21; weapon_teslacoil 17→18; skill_pierce 4→5|0/3|
|080|319565|3177|2067|1.5370|2758|1.1519|5579|weapon_scattergun 43→44|0/3|
|081|325144|3238|1096|2.9544|2758|1.1740|4320|vanguard 16→17; weapon_venomlauncher 17→18|0/0|
|082|329464|3274|1762|1.8581|2758|1.1871|4313|pet_turret_drone 10→11; weapon_plasmacannon 17→18; skill_homing 4→5|0/0|
|083|333777|3274|1815|1.8039|2758|1.1871|5146|armor_kevlar 13→14; weapon_railgun 17→18|0/0|
|084|338923|3282|1265|2.5945|2758|1.1900|4431|weapon_cryocannon 18→19; weapon_flamethrower 18→19|0/0|
|085|343354|3282|2204|1.4891|2758|1.1900|6158|weapon_scattergun 44→45; skill_barrier 4→5|0/0|
|086|349512|3536|1855|1.9062|2758|1.2821|5850|weapon_scattergun 45→46|0/0|
|087|355362|3637|1857|1.9585|2758|1.3187|5717|weapon_scattergun 46→47|0/0|
|088|361079|3720|1857|2.0032|2758|1.3488|5260|chip_attack 15→16; weapon_autocannon 21→22; weapon_teslacoil 18→19; skill_salvo 4→5|0/0|
|089|366339|3911|1994|1.9614|2758|1.4181|5703|vanguard 17→18; weapon_venomlauncher 18→19|0/0|
|090|372042|3988|2751|1.4497|2758|1.4460|4834|weapon_autocannon 22→23; weapon_plasmacannon 18→19|0/0|
|091|376876|3988|1234|3.2318|2758|1.4460|4742|weapon_railgun 18→19; skill_charge_shot 4→5|0/0|
|092|381618|4090|1862|2.1966|2758|1.4830|6828|chip_attack 16→17; weapon_scattergun 47→48|0/0|
|093|388446|4393|2266|1.9387|2758|1.5928|5903|weapon_scattergun 48→49|0/0|
|094|394349|4395|1830|2.4016|2758|1.5935|6393|weapon_scattergun 49→50; skill_slow_field 4→5|0/0|
|095|400742|5022|3370|1.4902|3370|1.4902|5911|armor_kevlar 14→15; weapon_cryocannon 19→20; weapon_flamethrower 19→20|0/0|
|096|406653|5090|2429|2.0955|3370|1.5104|7903|pet_turret_drone 11→12; weapon_teslacoil 19→20; weapon_venomlauncher 19→20|0/0|
|097|414556|5098|1863|2.7364|3370|1.5128|7350|chip_attack 17→18; vanguard 18→19; weapon_plasmacannon 19→20; skill_split_shot 4→5|0/0|
|098|421906|5230|2720|1.9228|3370|1.5519|7317|weapon_cryocannon 20→21; weapon_railgun 19→20|0/0|
|099|429223|5230|3094|1.6904|3370|1.5519|6337|weapon_flamethrower 20→21; weapon_teslacoil 20→21|0/0|

## 优化后回刷门与预算

状态：离线条件模拟，不代表实际3★通关；未改数据。

# T3 进度闭环

只用假定3★首通，金币按逐敌四舍五入；非Boss波support不计。
§8.2主路径在账户副本内回刷上一关，每章累计最多6次；未达门槛后的行仅为条件诊断。
不计动态召唤、金币卡、付费助推；按现有购买/升级优先级和技能经验成本。
重复3★没有新增星星，只有金币与递减经验。R是显示战力比，不等于已验证胜率。

design/41 section 8.2: all P>=.95rec; Boss/x7-x9 P>=rec; all P<=1.10E; <=6 predecessor farms/chapter; E=max(65,rec(1..L))

首次R<0.95：20；G1走廊不满足关数：18/99。

包络目标Σ|P−E|/E：7.936772。

回刷总数：49；各章：{'1': 3, '2': 6, '3': 6, '4': 6, '5': 6, '6': 4, '7': 0, '8': 6, '9': 6, '10': 6}；墙过高/预算内未满足下限：[17, 20, 30, 40, 74, 76, 78, 90, 95]。

|回刷门|前一关|入门P|回刷后P|次数|章累计|下限满足|八墙关|达到下限所需章次数(反事实)|
|---|---:|---:|---:|---:|---:|---|---|---|
|005|4|73|77|3|3|True|False|3|
|013|12|123|127|1|1|True|False|1|
|015|14|142|157|1|2|True|True|2|
|017|16|158|162|4|6|False|True|10|
|020|19|204|204|0|6|False|True|18|
|025|24|207|268|6|6|True|False|6|
|030|29|314|314|0|6|False|False|8|
|038|37|353|502|4|4|True|False|4|
|039|38|510|537|2|6|True|False|6|
|040|39|552|552|0|6|False|True|8|
|044|43|582|742|6|6|True|True|6|
|057|56|983|999|4|4|True|False|4|
|072|71|1383|1515|1|1|True|False|1|
|074|73|1582|1839|5|6|False|False|9|
|076|75|2011|2011|0|6|False|True|23|
|078|77|2203|2203|0|6|False|False|8|
|090|89|2477|2748|6|6|False|False|7|
|095|94|3048|3323|6|6|False|False|18|

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|当关/章累计回刷|
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
|001|0|65|50|1.3000|65|1.0000|303|weapon_autocannon 1→2|0/0|
|002|303|66|50|1.3200|65|1.0154|409|vanguard 1→2; weapon_autocannon 2→3; skill_multishot 0→1|0/0|
|003|712|70|50|1.4000|65|1.0769|485|weapon_cryocannon; vanguard 2→3; weapon_cryocannon 1→2; skill_pierce 0→1|0/0|
|004|1197|71|64|1.1094|65|1.0923|550|weapon_autocannon 3→4; weapon_cryocannon 2→3; skill_barrier 0→1; skill_homing 0→1|0/0|
|005|2995|77|76|1.0132|76|1.0132|667|weapon_autocannon 5→6; skill_charge_shot 0→1|3/3|
|006|3662|82|53|1.5472|76|1.0789|719|armor_kevlar; armor_kevlar 1→3; weapon_cryocannon 4→5; skill_slow_field 0→1; signature 0→1|0/3|
|007|4381|84|53|1.5849|76|1.1053|732|armor_kevlar 3→4; vanguard 4→5; skill_split_shot 0→1|0/3|
|008|5113|86|79|1.0886|79|1.0886|960|chip_attack; chip_attack 1→2; weapon_autocannon 6→7; skill_critical 0→1; skill_ricochet 0→1|0/3|
|009|6073|94|79|1.1899|79|1.1899|741|chip_attack 2→5|0/3|
|010|6814|100|87|1.1494|87|1.1494|740|weapon_cryocannon 5→6|0/3|
|011|7554|100|99|1.0101|99|1.0101|1113|weapon_scattergun; weapon_scattergun 1→5; skill_multishot 1→2|0/0|
|012|8667|117|108|1.0833|108|1.0833|1220|vanguard 5→6; weapon_scattergun 5→6; skill_pierce 1→2|0/0|
|013|10842|127|131|0.9695|131|0.9695|1260|chip_attack 5→6; weapon_scattergun 7→8; skill_homing 1→2|1/1|
|014|12102|136|138|0.9855|138|0.9855|1297|weapon_scattergun 8→9|0/1|
|015|14398|157|147|1.0680|147|1.0680|849|weapon_scattergun 10→11|1/2|
|016|15247|158|98|1.6122|147|1.0748|1606|weapon_railgun; weapon_railgun 1→2; weapon_scattergun 11→12; skill_salvo 1→2|0/2|
|017|21957|162|165|0.9818|165|0.9818|1674|weapon_scattergun 14→15; skill_slow_field 1→2|4/6|
|018|23631|200|185|1.0811|185|1.0811|1336|weapon_railgun 4→5|0/6|
|019|24967|200|188|1.0638|188|1.0638|1733|pet_turret_drone; pet_turret_drone 1→2; weapon_scattergun 15→16; signature 1→2|0/6|
|020|26700|204|291|0.7010|291|0.7010|1899|pet_turret_drone 2→3; weapon_scattergun 16→17; skill_split_shot 1→2|0/6|
|021|28599|204|164|1.2439|291|0.7010|1782|weapon_venomlauncher; weapon_venomlauncher 1→6|0/0|
|022|30381|204|183|1.1148|291|0.7010|1894|pet_turret_drone 3→4; weapon_autocannon 7→8; weapon_venomlauncher 6→7; skill_critical 1→2|0/0|
|023|32275|205|186|1.1022|291|0.7045|2071|vanguard 6→7; weapon_cryocannon 7→8; weapon_venomlauncher 7→8; skill_ricochet 1→2|0/0|
|024|34346|207|201|1.0299|291|0.7113|1943|weapon_scattergun 17→18|0/0|
|025|45199|268|260|1.0308|291|0.9210|1388|pet_turret_drone 4→5; vanguard 8→9|6/6|
|026|46587|293|226|1.2965|291|1.0069|2359|chip_attack 7→8; weapon_scattergun 18→19|0/6|
|027|48946|297|195|1.5231|291|1.0206|2179|weapon_scattergun 19→20|0/6|
|028|51125|300|231|1.2987|291|1.0309|2300|weapon_scattergun 20→21; skill_multishot 2→3|0/6|
|029|53425|314|206|1.5243|291|1.0790|2424|weapon_autocannon 10→11; weapon_venomlauncher 9→10|0/6|
|030|55849|314|332|0.9458|332|0.9458|1969|weapon_railgun 7→8|0/6|
|031|57818|314|159|1.9748|332|0.9458|2771|weapon_flamethrower; weapon_flamethrower 1→3; weapon_scattergun 21→22|0/0|
|032|60589|325|245|1.3265|332|0.9789|2603|weapon_plasmacannon; weapon_flamethrower 3→5; weapon_plasmacannon 1→3; skill_pierce 2→3|0/0|
|033|63192|325|228|1.4254|332|0.9789|2296|weapon_plasmacannon 3→5|0/0|
|034|65488|325|330|0.9848|332|0.9789|2873|weapon_flamethrower 5→6; weapon_plasmacannon 5→6|0/0|
|035|68361|325|219|1.4840|332|0.9789|2133|weapon_flamethrower 6→8|0/0|
|036|70494|325|225|1.4444|332|0.9789|2893|weapon_scattergun 22→23; skill_homing 2→3|0/0|
|037|73387|340|232|1.4655|332|1.0241|3236|weapon_cryocannon 9→10; weapon_scattergun 23→24|0/0|
|038|86935|502|484|1.0372|484|1.0372|3485|chip_attack 8→9; weapon_scattergun 25→26|4/4|
|039|96044|537|533|1.0075|533|1.0075|2975|weapon_scattergun 27→28; skill_salvo 2→3|2/6|
|040|99019|552|574|0.9617|574|0.9617|3890|chip_attack 9→10; weapon_scattergun 28→29|0/6|
|041|102909|574|236|2.4322|574|1.0000|3803|weapon_teslacoil; weapon_teslacoil 1→5; skill_charge_shot 2→3|0/0|
|042|106712|579|375|1.5440|574|1.0087|3474|weapon_scattergun 29→30|0/0|
|043|110186|580|587|0.9881|587|0.9881|4048|weapon_cryocannon 10→11; weapon_scattergun 30→31|0/0|
|044|134034|742|757|0.9802|757|0.9802|3911|weapon_scattergun 33→34; skill_split_shot 2→3|6/6|
|045|137945|783|655|1.1954|757|1.0343|3890|weapon_scattergun 34→35|0/6|
|046|141835|826|600|1.3767|757|1.0911|3399|weapon_cryocannon 11→12; weapon_teslacoil 8→9|0/6|
|047|145234|826|670|1.2328|757|1.0911|3643|weapon_railgun 9→10; weapon_venomlauncher 11→12; skill_critical 2→3|0/6|
|048|148877|826|663|1.2459|757|1.0911|4311|pet_turret_drone 6→7; weapon_scattergun 35→36|0/6|
|049|153188|871|658|1.3237|757|1.1506|4231|weapon_scattergun 36→37; skill_ricochet 2→3|0/6|
|050|157419|903|868|1.0403|868|1.0403|3224|weapon_plasmacannon 9→10|0/6|
|051|160643|903|431|2.0951|868|1.0403|1438|weapon_autocannon 11→12|0/0|
|052|162081|903|349|2.5874|868|1.0403|1608|weapon_flamethrower 10→11|0/0|
|053|163689|903|427|2.1148|868|1.0403|1568|weapon_autocannon 12→13|0/0|
|054|165257|903|359|2.5153|868|1.0403|1593|weapon_autocannon 13→14; skill_multishot 3→4|0/0|
|055|166850|951|950|1.0011|950|1.0011|1594|vanguard 11→12|0/0|
|056|168444|983|354|2.7768|950|1.0347|1537|weapon_flamethrower 11→12|0/0|
|057|172381|999|990|1.0091|990|1.0091|2671|weapon_teslacoil 9→10|4/4|
|058|175052|999|503|1.9861|990|1.0091|1741|chip_attack 10→11; weapon_venomlauncher 12→13|0/4|
|059|176793|1026|562|1.8256|990|1.0364|1698|weapon_autocannon 14→15|0/4|
|060|178491|1026|990|1.0364|990|1.0364|3539|armor_kevlar 9→10; weapon_railgun 10→11; skill_pierce 3→4|0/4|
|061|182030|1076|990|1.0869|990|1.0869|2085|weapon_flamethrower 12→13|0/0|
|062|184115|1076|250|4.3040|990|1.0869|2140|chip_attack 11→12; weapon_cryocannon 13→14|0/0|
|063|186255|1085|576|1.8837|990|1.0960|1987|weapon_venomlauncher 13→14|0/0|
|064|188242|1085|955|1.1361|990|1.0960|2014|weapon_flamethrower 13→14; skill_homing 3→4|0/0|
|065|190256|1085|1014|1.0700|1014|1.0700|2331|vanguard 12→13; weapon_cryocannon 14→15|0/0|
|066|192587|1206|1184|1.0186|1184|1.0186|1918|weapon_autocannon 15→16|0/0|
|067|194505|1206|955|1.2628|1184|1.0186|2615|weapon_autocannon 16→17|0/0|
|068|197120|1206|1042|1.1574|1184|1.0186|2373|vanguard 13→14; weapon_venomlauncher 14→15; skill_barrier 3→4|0/0|
|069|199493|1340|978|1.3701|1184|1.1318|2416|weapon_flamethrower 14→15|0/0|
|070|201909|1340|1286|1.0420|1286|1.0420|2350|weapon_autocannon 17→18|0/0|
|071|204259|1340|1146|1.1693|1286|1.0420|2115|pet_turret_drone 8→9; weapon_cryocannon 15→16; skill_salvo 3→4|0/0|
|072|207344|1515|1576|0.9613|1576|0.9613|2020|weapon_venomlauncher 15→16|1/1|
|073|209364|1515|818|1.8521|1576|0.9613|2178|weapon_flamethrower 15→16; skill_charge_shot 3→4|0/1|
|074|216572|1839|2034|0.9041|2034|0.9041|2598|weapon_autocannon 18→19; skill_slow_field 3→4|5/6|
|075|219170|2011|1841|1.0923|2034|0.9887|2761|armor_kevlar 12→13; weapon_cryocannon 16→17|0/6|
|076|221931|2011|2758|0.7292|2758|0.7292|2357|chip_attack 14→15; weapon_venomlauncher 16→17|0/6|
|077|224288|2027|1652|1.2270|2758|0.7350|2692|armor_kevlar 13→14; vanguard 15→16; skill_split_shot 3→4|0/6|
|078|226980|2203|2226|0.9897|2758|0.7988|2446|weapon_autocannon 19→20|0/6|
|079|229426|2203|2030|1.0852|2758|0.7988|2690|chip_attack 15→16; weapon_cryocannon 17→18|0/6|
|080|232116|2239|2067|1.0832|2758|0.8118|2933|weapon_flamethrower 16→17; skill_critical 3→4|0/6|
|081|235049|2239|1096|2.0429|2758|0.8118|2310|weapon_venomlauncher 17→18|0/0|
|082|237359|2239|1762|1.2707|2758|0.8118|2263|pet_turret_drone 10→11; vanguard 16→17; skill_ricochet 3→4|0/0|
|083|239622|2369|1815|1.3052|2758|0.8590|2714|weapon_railgun 11→12|0/0|
|084|242336|2369|1265|1.8727|2758|0.8590|2305|weapon_cryocannon 18→19|0/0|
|085|244641|2369|2204|1.0749|2758|0.8590|3205|weapon_plasmacannon 10→11|0/0|
|086|247846|2369|1855|1.2771|2758|0.8590|3069|weapon_teslacoil 10→11|0/0|
|087|250915|2369|1857|1.2757|2758|0.8590|2937|weapon_plasmacannon 11→12|0/0|
|088|253852|2369|1857|1.2757|2758|0.8590|2757|weapon_autocannon 20→21; skill_multishot 4→5|0/0|
|089|256609|2477|1994|1.2422|2758|0.8981|2983|weapon_flamethrower 17→18|0/0|
|090|269204|2748|2751|0.9989|2758|0.9964|2493|vanguard 18→19|6/6|
|091|271697|3048|1234|2.4700|2758|1.1051|2420|weapon_autocannon 21→22; skill_pierce 4→5|0/0|
|092|274117|3048|1862|1.6369|2758|1.1051|3509|weapon_teslacoil 11→12|0/0|
|093|277626|3048|2266|1.3451|2758|1.1051|2989|weapon_railgun 12→13|0/0|
|094|280615|3048|1830|1.6656|2758|1.1051|3226|weapon_flamethrower 18→19|0/0|
|095|294533|3323|3370|0.9861|3370|0.9861|2982|weapon_railgun 13→14|6/6|
|096|297515|3323|2429|1.3681|3370|0.9861|4008|weapon_plasmacannon 12→13|0/6|
|097|301523|3323|1863|1.7837|3370|0.9861|3746|weapon_teslacoil 12→13|0/6|
|098|305269|3323|2720|1.2217|3370|0.9861|3717|weapon_railgun 14→15|0/6|
|099|308986|3323|3094|1.0740|3370|0.9861|3191|weapon_flamethrower 19→20; skill_homing 4→5|0/6|
