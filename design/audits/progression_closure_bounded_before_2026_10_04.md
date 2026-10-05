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
