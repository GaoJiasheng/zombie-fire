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
