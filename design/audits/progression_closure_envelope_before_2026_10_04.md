状态：离线条件模拟，不代表实际3★通关；未改数据。

# T3 进度闭环

只用假定3★首通，金币按逐敌四舍五入；非Boss波support不计。
主路径不刷关；恢复次数是独立副本反事实，不向后续99关注入刷取资源。
不计动态召唤、金币卡、付费助推；按现有购买/升级优先级和技能经验成本。
重复3★没有新增星星，只有金币与递减经验。R是显示战力比，不等于已验证胜率。

design/41 section 8.1: all P>=.95rec; Boss/x7-x9 P>=rec; all P<=1.10E; E=max(65,rec(1..L))

首次R<0.95：18；G1走廊不满足关数：64/99。

包络目标Σ|P−E|/E：18.733553。

|关卡|累计金币(入场前)|当前战力|推荐|R|E|P/E|首通金币|当关购入/升级|回刷至R≥1|
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|
|001|0|65|50|1.3000|65|1.0000|466|vanguard 1→2; weapon_autocannon 1→3|0|
|002|466|69|50|1.3800|65|1.0615|649|vanguard 2→3; weapon_autocannon 3→4; skill_multishot 0→1|0|
|003|1115|73|50|1.4600|65|1.1231|757|weapon_cryocannon; weapon_autocannon 4→5; weapon_cryocannon 1→3; skill_pierce 0→1|0|
|004|1872|74|64|1.1562|65|1.1385|878|vanguard 3→4; weapon_autocannon 5→6; skill_barrier 0→1; skill_homing 0→1|0|
|005|2750|81|76|1.0658|76|1.0658|999|weapon_autocannon 6→7; weapon_cryocannon 3→4; skill_salvo 0→1|0|
|006|3749|82|53|1.5472|76|1.0789|1198|armor_kevlar; armor_kevlar 1→3; weapon_autocannon 7→8; weapon_cryocannon 4→5; skill_charge_shot 0→1|0|
|007|4947|89|53|1.6792|76|1.1711|1194|armor_kevlar 3→4; vanguard 4→5; weapon_autocannon 8→9; skill_slow_field 0→1; signature 0→1|0|
|008|6141|96|79|1.2152|79|1.2152|1501|chip_attack; chip_attack 1→5; weapon_autocannon 9→10; skill_split_shot 0→1|0|
|009|7642|106|79|1.3418|79|1.3418|1281|vanguard 5→6; weapon_autocannon 10→11; skill_critical 0→1|0|
|010|8923|112|87|1.2874|87|1.2874|1245|armor_kevlar 4→5; weapon_autocannon 11→12; skill_ricochet 0→1|0|
|011|10168|116|99|1.1717|99|1.1717|1826|weapon_scattergun; weapon_autocannon 12→13; weapon_scattergun 1→4; skill_multishot 1→2|0|
|012|11994|122|108|1.1296|108|1.1296|1926|vanguard 6→7; weapon_autocannon 13→14; weapon_scattergun 4→5|0|
|013|13920|131|131|1.0000|131|1.0000|2071|chip_attack 5→6; weapon_cryocannon 5→6; weapon_scattergun 5→6; skill_pierce 1→2|0|
|014|15991|141|138|1.0217|138|1.0217|2143|vanguard 7→8; weapon_cryocannon 6→7; weapon_scattergun 6→7; skill_homing 1→2|0|
|015|18134|151|147|1.0272|147|1.0272|1393|armor_kevlar 5→6; weapon_scattergun 7→8|0|
|016|19527|152|98|1.5510|147|1.0340|2742|weapon_railgun; weapon_railgun 1→4; weapon_scattergun 8→9; skill_barrier 1→2|0|
|017|22269|166|165|1.0061|165|1.0061|2719|chip_attack 6→7; weapon_railgun 4→5; weapon_scattergun 9→10; skill_salvo 1→2|0|
|018|24988|169|185|0.9135|185|0.9135|2161|weapon_cryocannon 7→8; weapon_scattergun 10→11|2|
|019|27149|178|188|0.9468|188|0.9468|2977|pet_turret_drone; pet_turret_drone 1→3; weapon_railgun 5→6; weapon_scattergun 11→12; skill_charge_shot 1→2|7|
|020|30126|189|291|0.6495|291|0.6495|3195|weapon_railgun 6→7; weapon_scattergun 12→13; signature 1→2|6|
|021|33321|198|164|1.2073|291|0.6804|2916|weapon_venomlauncher; weapon_scattergun 13→14; weapon_venomlauncher 1→4; skill_slow_field 1→2|0|
|022|36237|209|183|1.1421|291|0.7182|3177|pet_turret_drone 3→5; weapon_scattergun 14→15; weapon_venomlauncher 4→5; skill_split_shot 1→2|0|
|023|39414|209|186|1.1237|291|0.7182|3563|vanguard 8→9; weapon_scattergun 15→16; weapon_venomlauncher 5→6; skill_critical 1→2|0|
|024|42977|278|201|1.3831|291|0.9553|3343|weapon_scattergun 16→17; weapon_venomlauncher 6→7|0|
|025|46320|282|260|1.0846|291|0.9691|2321|weapon_scattergun 17→18; skill_ricochet 1→2|0|
|026|48641|286|226|1.2655|291|0.9828|3935|chip_attack 7→8; weapon_scattergun 18→19; weapon_venomlauncher 7→8|0|
|027|52576|293|195|1.5026|291|1.0069|3720|weapon_scattergun 19→20; weapon_venomlauncher 8→9; skill_multishot 2→3|0|
|028|56296|304|231|1.3160|291|1.0447|4002|armor_kevlar 6→7; weapon_railgun 7→8; weapon_venomlauncher 9→10|0|
|029|60298|312|206|1.5146|291|1.0722|4148|pet_turret_drone 5→6; weapon_cryocannon 8→9; weapon_scattergun 20→21|0|
|030|64446|326|332|0.9819|332|0.9819|3328|chip_attack 8→9; weapon_scattergun 21→22; skill_pierce 2→3|1|
|031|67774|350|159|2.2013|332|1.0542|4714|weapon_flamethrower; weapon_flamethrower 1→6; weapon_scattergun 22→23|0|
|032|72488|362|245|1.4776|332|1.0904|4420|weapon_plasmacannon; weapon_flamethrower 6→8; weapon_plasmacannon 1→5; skill_homing 2→3|0|
|033|76908|362|228|1.5877|332|1.0904|3968|weapon_flamethrower 8→9; weapon_scattergun 23→24|0|
|034|80876|379|330|1.1485|332|1.1416|4994|armor_kevlar 7→8; weapon_flamethrower 9→10; weapon_scattergun 24→25|0|
|035|85870|413|219|1.8858|332|1.2440|3689|weapon_cryocannon 9→10; weapon_flamethrower 10→11; weapon_plasmacannon 5→6; skill_barrier 2→3|0|
|036|89559|486|225|2.1600|332|1.4639|4999|weapon_flamethrower 11→12; weapon_scattergun 25→26|0|
|037|94558|491|232|2.1164|332|1.4789|5600|vanguard 9→10; weapon_flamethrower 12→13; weapon_scattergun 26→27; skill_salvo 2→3|0|
|038|100158|522|484|1.0785|484|1.0785|6000|vanguard 10→11; weapon_flamethrower 13→14; weapon_scattergun 27→28|0|
|039|106158|577|533|1.0826|533|1.0826|5156|weapon_flamethrower 14→15; weapon_plasmacannon 6→8; skill_charge_shot 2→3|0|
|040|111314|581|574|1.0122|574|1.0122|6793|weapon_cryocannon 10→11; weapon_flamethrower 15→16; weapon_scattergun 28→29; skill_slow_field 2→3|0|
|041|118107|659|236|2.7924|574|1.1481|6462|weapon_teslacoil; weapon_scattergun 29→30; weapon_teslacoil 1→6|0|
|042|124569|665|375|1.7733|574|1.1585|6075|weapon_scattergun 30→31; weapon_teslacoil 6→8; skill_split_shot 2→3|0|
|043|130644|671|587|1.1431|587|1.1431|7055|weapon_scattergun 31→32; weapon_teslacoil 8→10|0|
|044|137699|678|757|0.8956|757|0.8956|6867|weapon_autocannon 14→15; weapon_scattergun 32→33; weapon_teslacoil 10→11; signature 2→3|6|
|045|144566|697|655|1.0641|757|0.9207|7042|chip_attack 9→10; weapon_scattergun 33→34; weapon_teslacoil 11→12|0|
|046|151608|707|600|1.1783|757|0.9339|6022|weapon_plasmacannon 8→9; weapon_railgun 8→9; weapon_teslacoil 12→13; skill_critical 2→3|0|
|047|157630|707|670|1.0552|757|0.9339|6656|weapon_scattergun 34→35; weapon_teslacoil 13→14|0|
|048|164286|713|663|1.0754|757|0.9419|7623|vanguard 11→12; weapon_scattergun 35→36; weapon_teslacoil 14→15; skill_ricochet 2→3|0|
|049|171909|947|658|1.4392|757|1.2510|7652|pet_turret_drone 6→7; weapon_scattergun 36→37; weapon_teslacoil 15→16|0|
|050|179561|954|868|1.0991|868|1.0991|5724|armor_kevlar 8→9; weapon_scattergun 37→38|0|
|051|185285|977|431|2.2668|868|1.1256|2522|pet_turret_drone 7→8; weapon_plasmacannon 9→10; skill_multishot 3→4|0|
|052|187807|990|349|2.8367|868|1.1406|2819|chip_attack 10→11; weapon_railgun 9→10|0|
|053|190626|995|427|2.3302|868|1.1463|2763|armor_kevlar 9→10; weapon_venomlauncher 10→11|0|
|054|193389|1046|359|2.9136|868|1.2051|2807|weapon_plasmacannon 10→11; skill_pierce 3→4|0|
|055|196196|1046|950|1.1011|950|1.1011|2897|weapon_autocannon 15→16; weapon_railgun 10→11|0|
|056|199093|1046|354|2.9548|950|1.1011|2693|vanguard 12→13; weapon_cryocannon 11→12; skill_homing 3→4|0|
|057|201786|1190|990|1.2020|990|1.2020|4919|weapon_scattergun 38→39|0|
|058|206705|1197|503|2.3797|990|1.2091|3084|weapon_autocannon 16→17; weapon_venomlauncher 11→12|0|
|059|209789|1197|562|2.1299|990|1.2091|2995|weapon_plasmacannon 11→12; skill_barrier 3→4|0|
|060|212784|1233|990|1.2455|990|1.2455|6400|weapon_cryocannon 12→13; weapon_scattergun 39→40|0|
|061|219184|1281|990|1.2939|990|1.2939|3770|weapon_cryocannon 13→14; weapon_railgun 11→12; skill_salvo 3→4|0|
|062|222954|1281|250|5.1240|990|1.2939|3835|weapon_cryocannon 14→15; weapon_venomlauncher 12→13|0|
|063|226789|1281|576|2.2240|990|1.2939|3555|pet_turret_drone 8→9; weapon_plasmacannon 12→13|0|
|064|230344|1296|955|1.3571|990|1.3091|3609|chip_attack 11→12; weapon_railgun 12→13; skill_charge_shot 3→4|0|
|065|233953|1379|1014|1.3600|1014|1.3600|4223|vanguard 13→14; weapon_venomlauncher 13→14; skill_slow_field 3→4|0|
|066|238176|1683|1184|1.4215|1184|1.4215|3497|armor_kevlar 10→11; weapon_plasmacannon 13→14|0|
|067|241673|1764|955|1.8471|1184|1.4899|4705|weapon_autocannon 17→18; weapon_railgun 13→14; skill_split_shot 3→4|0|
|068|246378|1764|1042|1.6929|1184|1.4899|4315|weapon_cryocannon 15→16; weapon_venomlauncher 14→15|0|
|069|250693|1764|978|1.8037|1184|1.4899|4485|weapon_scattergun 40→41; skill_critical 3→4|0|
|070|255178|1807|1286|1.4051|1286|1.4051|4298|chip_attack 12→13; weapon_plasmacannon 14→15|0|
|071|259476|1808|1146|1.5777|1286|1.4059|3880|pet_turret_drone 9→10; weapon_railgun 14→15; skill_ricochet 3→4|0|
|072|263356|1808|1576|1.1472|1576|1.1472|3661|armor_kevlar 11→12; weapon_venomlauncher 15→16|0|
|073|267017|1813|818|2.2164|1576|1.1504|4011|weapon_plasmacannon 15→16; signature 3→4|0|
|074|271028|1817|2034|0.8933|2034|0.8933|4820|weapon_scattergun 41→42|1|
|075|275848|1818|1841|0.9875|2034|0.8938|5072|weapon_scattergun 42→43|1|
|076|280920|1820|2758|0.6599|2758|0.6599|4419|chip_attack 13→14; weapon_railgun 15→16|7|
|077|285339|1821|1652|1.1023|2758|0.6603|5041|vanguard 14→15; weapon_autocannon 18→19; weapon_cryocannon 16→17; skill_multishot 4→5|0|
|078|290380|2285|2226|1.0265|2758|0.8285|4662|weapon_flamethrower 16→17; weapon_teslacoil 16→17|0|
|079|295042|2285|2030|1.1256|2758|0.8285|5091|vanguard 15→16; weapon_venomlauncher 16→17|0|
|080|300133|2878|2067|1.3924|2758|1.0435|5579|weapon_flamethrower 17→18; weapon_plasmacannon 16→17; skill_pierce 4→5|0|
|081|305712|2878|1096|2.6259|2758|1.0435|4320|armor_kevlar 12→13; weapon_railgun 16→17|0|
|082|310032|3016|1762|1.7117|2758|1.0935|4313|pet_turret_drone 10→11; weapon_autocannon 19→20; weapon_cryocannon 17→18|0|
|083|314345|3055|1815|1.6832|2758|1.1077|5146|weapon_autocannon 20→21; weapon_teslacoil 17→18|0|
|084|319491|3055|1265|2.4150|2758|1.1077|4431|vanguard 16→17; weapon_venomlauncher 17→18; skill_homing 4→5|0|
|085|323922|3241|2204|1.4705|2758|1.1751|6158|chip_attack 14→15; weapon_scattergun 43→44|0|
|086|330080|3274|1855|1.7650|2758|1.1871|5850|weapon_scattergun 44→45|0|
|087|335930|3277|1857|1.7647|2758|1.1882|5717|weapon_scattergun 45→46; skill_barrier 4→5|0|
|088|341647|3637|1857|1.9585|2758|1.3187|5260|weapon_autocannon 21→22; weapon_plasmacannon 17→18|0|
|089|346907|3637|1994|1.8240|2758|1.3187|5703|weapon_scattergun 46→47|0|
|090|352610|3720|2751|1.3522|2758|1.3488|4834|armor_kevlar 13→14; weapon_railgun 17→18; skill_salvo 4→5|0|
|091|357444|3720|1234|3.0146|2758|1.3488|4742|weapon_cryocannon 18→19; weapon_flamethrower 18→19|0|
|092|362186|3720|1862|1.9979|2758|1.3488|6828|weapon_scattergun 47→48|0|
|093|369014|3932|2266|1.7352|2758|1.4257|5903|weapon_scattergun 48→49; skill_charge_shot 4→5|0|
|094|374917|4065|1830|2.2213|2758|1.4739|6393|weapon_scattergun 49→50|0|
|095|381310|4087|3370|1.2128|3370|1.2128|5911|weapon_teslacoil 18→19; weapon_venomlauncher 18→19|0|
|096|387221|4087|2429|1.6826|3370|1.2128|7903|weapon_plasmacannon 18→19; weapon_railgun 18→19; signature 4→5|0|
|097|395124|4388|1863|2.3553|3370|1.3021|7350|pet_turret_drone 11→12; vanguard 17→18; weapon_cryocannon 19→20; weapon_flamethrower 19→20|0|
|098|402474|4403|2720|1.6187|3370|1.3065|7317|weapon_teslacoil 19→20; weapon_venomlauncher 19→20|0|
|099|409791|4403|3094|1.4231|3370|1.3065|6337|chip_attack 15→16; weapon_autocannon 22→23; weapon_plasmacannon 19→20; skill_slow_field 4→5|0|
