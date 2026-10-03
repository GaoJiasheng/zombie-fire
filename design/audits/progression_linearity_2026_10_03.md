状态：测量不完整；门禁失败；未改数据。

# T2 线性度与战力真实化审计

章节log(value)~关卡号OLS拟合几何斜率；逐关增幅与章斜率相差>3pp单列，Boss允许额外+10pp。
R→胜率使用十种子数据的加权保序回归(PAVA)+线性插值，不在已测区间内即未验证。

## 逐关增幅

|关|推荐|P*|R*|系数|总血量|推荐增幅|P*增幅|系数增幅|血量增幅|求解状态|
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
|001|54|未测|未测/不可估|0.440|11678|未测/不可估|未测/不可估|未测/不可估|未测/不可估|lower_bound_passes|
|002|58|未测|未测/不可估|0.620|14253|7.41%|未测/不可估|40.82%|22.05%|lower_bound_passes|
|003|61|未测|未测/不可估|0.570|20644|5.17%|未测/不可估|-8.01%|44.84%|lower_bound_passes|
|004|64|未测|未测/不可估|1.294|52409|4.92%|未测/不可估|126.98%|153.87%|lower_bound_passes|
|005|72|76|1.0556|1.250|65365|12.50%|未测/不可估|-3.39%|24.72%|complete|
|006|72|未测|未测/不可估|0.948|33987|0.00%|未测/不可估|-24.14%|-48.00%|lower_bound_passes|
|007|76|未测|未测/不可估|0.627|34157|5.56%|未测/不可估|-33.91%|0.50%|lower_bound_passes|
|008|80|79|0.9875|1.263|69510|5.26%|未测/不可估|101.58%|103.50%|complete|
|009|85|79|0.9294|1.375|75496|6.25%|0.00%|8.87%|8.61%|complete|
|010|95|82|0.8632|2.150|96711|11.76%|3.80%|56.33%|28.10%|complete|
|011|95|未测|未测/不可估|1.081|70295|0.00%|未测/不可估|-49.73%|-27.31%|lower_bound_passes|
|012|100|90|0.9000|1.418|125725|5.26%|未测/不可估|31.15%|78.85%|complete|
|013|112|101|0.9018|2.876|227708|12.00%|12.22%|102.85%|81.12%|complete|
|014|118|120|1.0169|2.030|195042|5.36%|18.81%|-29.41%|-14.35%|complete|
|015|126|未测|未测/不可估|0.957|60399|6.78%|未测/不可估|-52.85%|-69.03%|upper_bound_fails|
|016|126|84|0.6667|1.190|97030|0.00%|未测/不可估|24.28%|60.65%|complete|
|017|133|未测|未测/不可估|0.719|70181|5.56%|未测/不可估|-39.54%|-27.67%|upper_bound_fails|
|018|149|未测|未测/不可估|3.217|201636|12.03%|未测/不可估|347.34%|187.31%|upper_bound_fails|
|019|157|未测|未测/不可估|2.441|219133|5.37%|未测/不可估|-24.12%|8.68%|upper_bound_fails|
|020|167|未测|未测/不可估|1.500|201876|6.37%|未测/不可估|-38.56%|-7.88%|upper_bound_fails|
|021|167|164|0.9820|1.704|160663|0.00%|未测/不可估|13.63%|-20.42%|complete|
|022|175|183|1.0457|2.232|194044|4.79%|11.59%|30.95%|20.78%|complete|
|023|197|186|0.9442|2.474|261983|12.57%|1.64%|10.84%|35.01%|complete|
|024|207|201|0.9710|1.500|172660|5.08%|8.06%|-39.37%|-34.09%|complete|
|025|219|248|1.1324|3.500|556727|5.80%|23.38%|133.33%|222.44%|complete|
|026|219|191|0.8721|7.512|727479|0.00%|-22.98%|114.63%|30.67%|complete|
|027|246|195|0.7927|2.749|331276|12.33%|2.09%|-63.40%|-54.46%|complete|
|028|259|210|0.8108|4.600|649059|5.28%|7.69%|67.32%|95.93%|complete|
|029|274|206|0.7518|3.300|411692|5.79%|-1.90%|-28.26%|-36.57%|complete|
|030|310|286|0.9226|5.000|1426590|13.14%|38.83%|51.52%|246.52%|complete|
|031|310|148|0.4774|1.950|279784|0.00%|-48.25%|-61.00%|-80.39%|complete|
|032|324|245|0.7562|1.990|338998|4.52%|65.54%|2.06%|21.16%|complete|
|033|343|209|0.6093|4.350|638264|5.86%|-14.69%|118.57%|88.28%|complete|
|034|343|296|0.8630|8.778|1478391|0.00%|41.63%|101.79%|131.63%|complete|
|035|384|183|0.4766|1.500|309940|11.95%|-38.18%|-82.91%|-79.04%|complete|
|036|384|209|0.5443|3.583|603696|0.00%|14.21%|138.90%|94.78%|complete|
|037|428|209|0.4883|2.516|688882|11.46%|0.00%|-29.80%|14.11%|complete|
|038|454|484|1.0661|5.600|1329809|6.07%|131.58%|122.61%|93.04%|complete|
|039|510|533|1.0451|6.292|1081864|12.33%|10.12%|12.36%|-18.65%|complete|
|040|540|未测|未测/不可估|3.342|2282457|5.88%|未测/不可估|-46.89%|110.97%|upper_bound_fails|
|041|540|225|0.4167|1.695|394428|0.00%|未测/不可估|-49.28%|-82.72%|complete|
|042|566|298|0.5265|5.331|1626202|4.81%|32.44%|214.48%|312.29%|complete|
|043|599|587|0.9800|5.800|1541667|5.83%|96.98%|8.80%|-5.20%|complete|
|044|632|未测|未测/不可估|4.936|1783982|5.51%|未测/不可估|-14.89%|15.72%|upper_bound_fails|
|045|672|655|0.9747|2.800|943463|6.33%|未测/不可估|-43.28%|-47.11%|complete|
|046|707|600|0.8487|4.800|1221912|5.21%|-8.40%|71.43%|29.51%|complete|
|047|749|593|0.7917|12.500|4525147|5.94%|-1.17%|160.42%|270.33%|complete|
|048|843|594|0.7046|8.000|4317783|12.55%|0.17%|-36.00%|-4.58%|complete|
|049|892|596|0.6682|6.300|4161413|5.81%|0.34%|-21.25%|-3.62%|complete|
|050|944|842|0.8919|5.784|4911594|5.83%|41.28%|-8.19%|18.03%|complete|
|051|944|414|0.4386|14.700|1631800|0.00%|-50.83%|154.14%|-66.78%|complete|
|052|944|331|0.3506|14.000|1066716|0.00%|-20.05%|-4.76%|-34.63%|complete|
|053|948|427|0.4504|10.300|1070687|0.42%|29.00%|-26.43%|0.37%|complete|
|054|948|317|0.3344|21.000|1324013|0.00%|-25.76%|103.88%|23.66%|complete|
|055|1008|950|0.9425|7.060|1317939|6.33%|199.68%|-66.38%|-0.46%|complete|
|056|1078|297|0.2755|12.450|1432785|6.94%|-68.74%|76.35%|8.71%|complete|
|057|1187|990|0.8340|10.300|5077063|10.11%|233.33%|-17.27%|254.35%|complete|
|058|1228|461|0.3754|14.300|2542241|3.45%|-53.43%|38.83%|-49.93%|complete|
|059|1262|499|0.3954|20.000|3481148|2.77%|8.24%|39.86%|36.93%|complete|
|060|1268|990|0.7808|8.000|3399154|0.48%|98.40%|-60.00%|-2.36%|complete|
|061|1268|990|0.7808|11.500|3197294|0.00%|0.00%|43.75%|-5.94%|complete|
|062|1268|186|0.1467|2.100|601356|0.00%|-81.21%|-81.74%|-81.19%|complete|
|063|1358|465|0.3424|9.400|3067536|7.10%|150.00%|347.62%|410.10%|complete|
|064|1404|955|0.6802|13.000|4156905|3.39%|105.38%|38.30%|35.51%|complete|
|065|1496|1014|0.6778|3.000|2014062|6.55%|6.18%|-76.92%|-51.55%|complete|
|066|1496|1184|0.7914|26.000|4064607|0.00%|16.77%|766.67%|101.81%|complete|
|067|1496|955|0.6384|27.000|3949336|0.00%|-19.34%|3.85%|-2.84%|complete|
|068|1703|983|0.5772|32.000|7979564|13.84%|2.93%|18.52%|102.05%|complete|
|069|1756|978|0.5569|13.000|3896489|3.11%|-0.51%|-59.38%|-51.17%|complete|
|070|1867|1228|0.6577|7.500|4420933|6.32%|25.56%|-42.31%|13.46%|complete|
|071|1867|978|0.5238|15.000|6677689|0.00%|-20.36%|100.00%|51.05%|complete|
|072|1867|1576|0.8441|15.000|7553000|0.00%|61.15%|0.00%|13.11%|complete|
|073|1867|606|0.3246|10.120|4970918|0.00%|-61.55%|-32.53%|-34.19%|complete|
|074|1944|2034|1.0463|23.000|8454908|4.12%|235.64%|127.27%|70.09%|complete|
|075|2273|1841|0.8099|9.000|6066316|16.92%|-9.49%|-60.87%|-28.25%|complete|
|076|2273|未测|未测/不可估|38.000|18567054|0.00%|未测/不可估|322.22%|206.07%|upper_bound_fails|
|077|2289|1582|0.6911|31.000|11533432|0.70%|未测/不可估|-18.42%|-37.88%|complete|
|078|2366|2226|0.9408|42.000|12443162|3.36%|40.71%|35.48%|7.89%|complete|
|079|2446|2030|0.8299|24.000|9884148|3.38%|-8.81%|-42.86%|-20.57%|complete|
|080|2592|1994|0.7693|11.000|7457761|5.97%|-1.77%|-54.17%|-24.55%|complete|
|081|2592|992|0.3827|11.636|7492600|0.00%|-50.25%|5.79%|0.47%|complete|
|082|2592|1762|0.6798|15.000|9891697|0.00%|77.62%|28.90%|32.02%|complete|
|083|2608|1815|0.6959|26.000|11809472|0.62%|3.01%|73.33%|19.39%|complete|
|084|2875|1059|0.3683|35.000|12134460|10.24%|-41.65%|34.62%|2.75%|complete|
|085|3055|2204|0.7214|20.000|13742326|6.26%|108.12%|-42.86%|13.25%|complete|
|086|3078|1819|0.5910|29.000|19753241|0.75%|-17.47%|45.00%|43.74%|complete|
|087|3179|1857|0.5841|29.000|15815549|3.28%|2.09%|0.00%|-19.93%|complete|
|088|3286|1857|0.5651|32.000|16639775|3.37%|0.00%|10.34%|5.21%|complete|
|089|3390|1994|0.5882|22.200|17222971|3.16%|7.38%|-30.63%|3.50%|complete|
|090|3720|2583|0.6944|7.000|21485940|9.73%|29.54%|-68.47%|24.75%|complete|
|091|3720|996|0.2677|15.000|12429863|0.00%|-61.44%|114.29%|-42.15%|complete|
|092|3748|1808|0.4824|23.000|20312840|0.75%|81.53%|53.33%|63.42%|complete|
|093|3874|2266|0.5849|28.000|18110782|3.36%|25.33%|21.74%|-10.84%|complete|
|094|3874|1830|0.4724|23.500|16498282|0.00%|-19.24%|-16.07%|-8.90%|complete|
|095|4384|3370|0.7687|10.500|42669878|13.16%|84.15%|-55.32%|158.63%|complete|
|096|4384|2429|0.5541|28.500|29189577|0.00%|-27.92%|171.43%|-31.59%|complete|
|097|4713|1863|0.3953|18.000|18404827|7.50%|-23.30%|-36.84%|-36.95%|complete|
|098|4718|2720|0.5765|22.000|19568587|0.11%|46.00%|22.22%|6.32%|complete|
|099|5000|2720|0.5440|11.000|29969144|5.98%|0.00%|-50.00%|53.15%|complete|

## 章节斜率与胜率合同

|章|推荐斜率|P*斜率|系数斜率|血量斜率|R=.85预计胜数|R=1预计胜数|R=1.15预计胜数|
|---|---:|---:|---:|---:|---|---|---|
|1|6.01%|1.37%|13.84%|23.50%|7.0000/10|9.4286/10|10.0000/10|

章1偏離>3pp：`[{"level": 2, "metric": "difficulty_coef", "deviation_pp": 26.97819849229478, "boss": false}, {"level": 3, "metric": "difficulty_coef", "deviation_pp": -21.845147948224046, "boss": false}, {"level": 3, "metric": "enemy_hp", "deviation_pp": 21.33805248156508, "boss": false}, {"level": 4, "metric": "difficulty_coef", "deviation_pp": 113.14247281446383, "boss": false}, {"level": 4, "metric": "enemy_hp", "deviation_pp": 130.37222402728221, "boss": false}, {"level": 5, "metric": "recommended", "deviation_pp": 6.489439233741274, "boss": true}, {"level": 5, "metric": "difficulty_coef", "deviation_pp": -17.225359736460547, "boss": true}, {"level": 6, "metric": "recommended", "deviation_pp": -6.010560766258726, "boss": false}, {"level": 6, "metric": "difficulty_coef", "deviation_pp": -37.97598332588704, "boss": false}, {"level": 6, "metric": "enemy_hp", "deviation_pp": -71.50543578185733, "boss": false}, {"level": 7, "metric": "difficulty_coef", "deviation_pp": -47.7533018959598, "boss": false}, {"level": 7, "metric": "enemy_hp", "deviation_pp": -23.000354412150408, "boss": false}, {"level": 8, "metric": "difficulty_coef", "deviation_pp": 87.73971988138919, "boss": false}, {"level": 8, "metric": "enemy_hp", "deviation_pp": 80.00182480522442, "boss": false}, {"level": 9, "metric": "difficulty_coef", "deviation_pp": -4.974314047014264, "boss": false}, {"level": 9, "metric": "enemy_hp", "deviation_pp": -14.888911388139976, "boss": false}, {"level": 10, "metric": "recommended", "deviation_pp": 5.754145116094218, "boss": true}, {"level": 10, "metric": "difficulty_coef", "deviation_pp": 42.48954477707231, "boss": true}, {"level": 10, "metric": "enemy_hp", "deviation_pp": 4.60042772606239, "boss": true}]`；Boss台阶：`[{"level": 5, "growth": {"recommended": 0.125, "p_star": null, "difficulty_coef": -0.03385376410573504, "enemy_hp": 0.24720041309860785}}, {"level": 10, "growth": {"recommended": 0.11764705882352944, "p_star": 0.03797468354430378, "difficulty_coef": 0.5632952810295935, "enemy_hp": 0.2810114704807576}}]`

|2|6.26%|-1.92%|2.72%|6.37%|7.6667/10|8.3846/10|9.4000/10|

章2偏離>3pp：`[{"level": 12, "metric": "difficulty_coef", "deviation_pp": 28.434905736794246, "boss": false}, {"level": 12, "metric": "enemy_hp", "deviation_pp": 72.48715921614244, "boss": false}, {"level": 13, "metric": "recommended", "deviation_pp": 5.73856964920349, "boss": false}, {"level": 13, "metric": "p_star", "deviation_pp": 14.144047410867772, "boss": false}, {"level": 13, "metric": "difficulty_coef", "deviation_pp": 100.13482525040081, "boss": false}, {"level": 13, "metric": "enemy_hp", "deviation_pp": 74.75073317351986, "boss": false}, {"level": 14, "metric": "p_star", "deviation_pp": 20.733706376764356, "boss": false}, {"level": 14, "metric": "difficulty_coef", "deviation_pp": -32.121098883755735, "boss": false}, {"level": 14, "metric": "enemy_hp", "deviation_pp": -20.711640915614286, "boss": false}, {"level": 15, "metric": "difficulty_coef", "deviation_pp": -55.5672786315505, "boss": true}, {"level": 15, "metric": "enemy_hp", "deviation_pp": -75.39902387392817, "boss": true}, {"level": 16, "metric": "recommended", "deviation_pp": -6.2614303507965205, "boss": false}, {"level": 16, "metric": "difficulty_coef", "deviation_pp": 21.566622371736845, "boss": false}, {"level": 16, "metric": "enemy_hp", "deviation_pp": 54.282891481166, "boss": false}, {"level": 17, "metric": "difficulty_coef", "deviation_pp": -42.25268273187829, "boss": false}, {"level": 17, "metric": "enemy_hp", "deviation_pp": -34.03679775854377, "boss": false}, {"level": 18, "metric": "recommended", "deviation_pp": 5.768644837173404, "boss": false}, {"level": 18, "metric": "difficulty_coef", "deviation_pp": 344.62920952989873, "boss": false}, {"level": 18, "metric": "enemy_hp", "deviation_pp": 180.93987722428605, "boss": false}, {"level": 19, "metric": "difficulty_coef", "deviation_pp": -26.83155708061872, "boss": false}, {"level": 20, "metric": "difficulty_coef", "deviation_pp": -41.274904595979365, "boss": true}, {"level": 20, "metric": "enemy_hp", "deviation_pp": -14.241325445010492, "boss": true}]`；Boss台阶：`[{"level": 15, "growth": {"recommended": 0.06779661016949157, "p_star": null, "difficulty_coef": -0.5285221674876848, "enemy_hp": -0.6903289192570012}}, {"level": 20, "growth": {"recommended": 0.06369426751592355, "p_star": null, "difficulty_coef": -0.38559842713197345, "enemy_hp": -0.0787519349678244}}]`

|3|6.63%|3.76%|11.60%|21.17%|7.8333/10|9.6667/10|10.0000/10|

章3偏離>3pp：`[{"level": 22, "metric": "p_star", "deviation_pp": 7.826382656619393, "boss": false}, {"level": 22, "metric": "difficulty_coef", "deviation_pp": 19.35008906999174, "boss": false}, {"level": 23, "metric": "recommended", "deviation_pp": 5.94179453872998, "boss": false}, {"level": 23, "metric": "enemy_hp", "deviation_pp": 13.846626257113781, "boss": false}, {"level": 24, "metric": "p_star", "deviation_pp": 4.305532931993097, "boss": false}, {"level": 24, "metric": "difficulty_coef", "deviation_pp": -50.966845061994725, "boss": false}, {"level": 24, "metric": "enemy_hp", "deviation_pp": -55.26015780320468, "boss": false}, {"level": 25, "metric": "p_star", "deviation_pp": 19.624101380075267, "boss": true}, {"level": 25, "metric": "difficulty_coef", "deviation_pp": 121.73593047020685, "boss": true}, {"level": 25, "metric": "enemy_hp", "deviation_pp": 201.27586475092377, "boss": true}, {"level": 26, "metric": "recommended", "deviation_pp": -6.629634032698586, "boss": false}, {"level": 26, "metric": "p_star", "deviation_pp": -26.742854164781093, "boss": false}, {"level": 26, "metric": "difficulty_coef", "deviation_pp": 103.0340257083021, "boss": false}, {"level": 26, "metric": "enemy_hp", "deviation_pp": 9.505563745519774, "boss": false}, {"level": 27, "metric": "recommended", "deviation_pp": 5.69913309058909, "boss": false}, {"level": 27, "metric": "difficulty_coef", "deviation_pp": -75.00044595360718, "boss": false}, {"level": 27, "metric": "enemy_hp", "deviation_pp": -75.62774128396848, "boss": false}, {"level": 28, "metric": "p_star", "deviation_pp": 3.9333244952685336, "boss": false}, {"level": 28, "metric": "difficulty_coef", "deviation_pp": 55.7239997267178, "boss": false}, {"level": 28, "metric": "enemy_hp", "deviation_pp": 74.76155108215215, "boss": false}, {"level": 29, "metric": "p_star", "deviation_pp": -5.663745101801062, "boss": false}, {"level": 29, "metric": "difficulty_coef", "deviation_pp": -39.85827242834389, "boss": false}, {"level": 29, "metric": "enemy_hp", "deviation_pp": -57.736193239602585, "boss": false}, {"level": 30, "metric": "recommended", "deviation_pp": 6.509052098688281, "boss": true}, {"level": 30, "metric": "p_star", "deviation_pp": 35.07596825927153, "boss": true}, {"level": 30, "metric": "difficulty_coef", "deviation_pp": 39.91774865202502, "boss": true}, {"level": 30, "metric": "enemy_hp", "deviation_pp": 225.35341422342267, "boss": true}]`；Boss台阶：`[{"level": 25, "growth": {"recommended": 0.05797101449275366, "p_star": 0.2338308457711442, "difficulty_coef": 1.3333333333333335, "enemy_hp": 2.2244114303794387}}, {"level": 30, "growth": {"recommended": 0.13138686131386867, "p_star": 0.38834951456310685, "difficulty_coef": 0.5151515151515151, "enemy_hp": 2.465186925104428}}]`

|4|6.40%|12.04%|7.08%|19.26%|8.5455/10|8.5455/10|10.0000(外推/未验)|

章4偏離>3pp：`[{"level": 32, "metric": "p_star", "deviation_pp": 53.50325631327921, "boss": false}, {"level": 32, "metric": "difficulty_coef", "deviation_pp": -5.020463318080312, "boss": false}, {"level": 33, "metric": "p_star", "deviation_pp": -26.73116177828174, "boss": false}, {"level": 33, "metric": "difficulty_coef", "deviation_pp": 111.48899611004055, "boss": false}, {"level": 33, "metric": "enemy_hp", "deviation_pp": 69.02142700611593, "boss": false}, {"level": 34, "metric": "recommended", "deviation_pp": -6.400525260120983, "boss": false}, {"level": 34, "metric": "p_star", "deviation_pp": 29.589510031111878, "boss": false}, {"level": 34, "metric": "difficulty_coef", "deviation_pp": 94.70880281808239, "boss": false}, {"level": 34, "metric": "enemy_hp", "deviation_pp": 112.36875966607525, "boss": false}, {"level": 35, "metric": "recommended", "deviation_pp": 5.552827509558321, "boss": true}, {"level": 35, "metric": "p_star", "deviation_pp": -50.212959902937015, "boss": true}, {"level": 35, "metric": "difficulty_coef", "deviation_pp": -89.9936321240064, "boss": true}, {"level": 35, "metric": "enemy_hp", "deviation_pp": -98.2935559616345, "boss": true}, {"level": 36, "metric": "recommended", "deviation_pp": -6.400525260120983, "boss": false}, {"level": 36, "metric": "difficulty_coef", "deviation_pp": 131.8179982203812, "boss": false}, {"level": 36, "metric": "enemy_hp", "deviation_pp": 75.51984633119876, "boss": false}, {"level": 37, "metric": "recommended", "deviation_pp": 5.0578080732123425, "boss": false}, {"level": 37, "metric": "p_star", "deviation_pp": -12.037284227261333, "boss": false}, {"level": 37, "metric": "difficulty_coef", "deviation_pp": -36.88247617615848, "boss": false}, {"level": 37, "metric": "enemy_hp", "deviation_pp": -5.147544442766544, "boss": false}, {"level": 38, "metric": "p_star", "deviation_pp": 119.54166314115973, "boss": false}, {"level": 38, "metric": "difficulty_coef", "deviation_pp": 115.52890615486999, "boss": false}, {"level": 38, "metric": "enemy_hp", "deviation_pp": 73.7805095622636, "boss": false}, {"level": 39, "metric": "recommended", "deviation_pp": 5.934276501993561, "boss": false}, {"level": 39, "metric": "difficulty_coef", "deviation_pp": 5.275141077524085, "boss": false}, {"level": 39, "metric": "enemy_hp", "deviation_pp": -37.90341192190025, "boss": false}, {"level": 40, "metric": "difficulty_coef", "deviation_pp": -53.970113667730665, "boss": true}, {"level": 40, "metric": "enemy_hp", "deviation_pp": 91.71609658519723, "boss": true}]`；Boss台阶：`[{"level": 35, "growth": {"recommended": 0.11953352769679304, "p_star": -0.3817567567567568, "difficulty_coef": -0.8291163034438761, "enemy_hp": -0.7903529008257136}}, {"level": 40, "growth": {"recommended": 0.05882352941176472, "p_star": null, "difficulty_coef": -0.46888111888111883, "enemy_hp": 1.1097436246426038}}]`

|5|6.56%|11.28%|10.95%|25.50%|9.1250/10|9.4965/10|10.0000(外推/未验)|

章5偏離>3pp：`[{"level": 42, "metric": "p_star", "deviation_pp": 21.164695037574326, "boss": false}, {"level": 42, "metric": "difficulty_coef", "deviation_pp": 203.5294792672686, "boss": false}, {"level": 42, "metric": "enemy_hp", "deviation_pp": 286.79532315210577, "boss": false}, {"level": 43, "metric": "p_star", "deviation_pp": 85.70011636494195, "boss": false}, {"level": 43, "metric": "enemy_hp", "deviation_pp": -30.696402372707293, "boss": false}, {"level": 44, "metric": "difficulty_coef", "deviation_pp": -25.843097266716775, "boss": false}, {"level": 44, "metric": "enemy_hp", "deviation_pp": -9.78042093695038, "boss": false}, {"level": 45, "metric": "difficulty_coef", "deviation_pp": -54.23194464677037, "boss": true}, {"level": 45, "metric": "enemy_hp", "deviation_pp": -72.61289361082379, "boss": true}, {"level": 46, "metric": "p_star", "deviation_pp": -19.676695971755628, "boss": false}, {"level": 46, "metric": "difficulty_coef", "deviation_pp": 60.47512933426846, "boss": false}, {"level": 46, "metric": "enemy_hp", "deviation_pp": 4.015373417880847, "boss": false}, {"level": 47, "metric": "p_star", "deviation_pp": -12.4464160735368, "boss": false}, {"level": 47, "metric": "difficulty_coef", "deviation_pp": 149.4632245723637, "boss": false}, {"level": 47, "metric": "enemy_hp", "deviation_pp": 244.835086182833, "boss": false}, {"level": 48, "metric": "recommended", "deviation_pp": 5.992525951151116, "boss": false}, {"level": 48, "metric": "p_star", "deviation_pp": -11.111115342789187, "boss": false}, {"level": 48, "metric": "difficulty_coef", "deviation_pp": -46.95344209430298, "boss": false}, {"level": 48, "metric": "enemy_hp", "deviation_pp": -30.080603665241085, "boss": false}, {"level": 49, "metric": "p_star", "deviation_pp": -10.943049070169783, "boss": false}, {"level": 49, "metric": "difficulty_coef", "deviation_pp": -32.20344209430298, "boss": false}, {"level": 49, "metric": "enemy_hp", "deviation_pp": -29.119670523737778, "boss": false}, {"level": 50, "metric": "p_star", "deviation_pp": 29.995418378364768, "boss": true}, {"level": 50, "metric": "difficulty_coef", "deviation_pp": -19.139156380017262, "boss": true}, {"level": 50, "metric": "enemy_hp", "deviation_pp": -7.471058390743562, "boss": true}]`；Boss台阶：`[{"level": 45, "growth": {"recommended": 0.06329113924050622, "p_star": null, "difficulty_coef": -0.4327850255246739, "enemy_hp": -0.47114763772886037}}, {"level": 50, "growth": {"recommended": 0.058295964125560484, "p_star": 0.412751677852349, "difficulty_coef": -0.08185714285714285, "enemy_hp": 0.18027071447194198}}]`

|6|4.16%|8.43%|-1.75%|15.18%|9.0000/10|10.0000/10|10.0000(外推/未验)|

章6偏離>3pp：`[{"level": 52, "metric": "recommended", "deviation_pp": -4.159000139885898, "boss": false}, {"level": 52, "metric": "p_star", "deviation_pp": -28.479953837948358, "boss": false}, {"level": 52, "metric": "difficulty_coef", "deviation_pp": -3.0147948472806756, "boss": false}, {"level": 52, "metric": "enemy_hp", "deviation_pp": -49.81275615787519, "boss": false}, {"level": 53, "metric": "recommended", "deviation_pp": -3.7352713263265773, "boss": false}, {"level": 53, "metric": "p_star", "deviation_pp": 20.57137648883186, "boss": false}, {"level": 53, "metric": "difficulty_coef", "deviation_pp": -24.68146151394734, "boss": false}, {"level": 53, "metric": "enemy_hp", "deviation_pp": -14.811035377575163, "boss": false}, {"level": 54, "metric": "recommended", "deviation_pp": -4.159000139885898, "boss": false}, {"level": 54, "metric": "p_star", "deviation_pp": -34.19276878098425, "boss": false}, {"level": 54, "metric": "difficulty_coef", "deviation_pp": 105.63060506025515, "boss": false}, {"level": 54, "metric": "enemy_hp", "deviation_pp": 8.476846312818745, "boss": false}, {"level": 55, "metric": "p_star", "deviation_pp": 191.25289792754637, "boss": true}, {"level": 55, "metric": "difficulty_coef", "deviation_pp": -64.6338424663283, "boss": true}, {"level": 55, "metric": "enemy_hp", "deviation_pp": -15.64207993671118, "boss": true}, {"level": 56, "metric": "p_star", "deviation_pp": -77.16848676446756, "boss": false}, {"level": 56, "metric": "difficulty_coef", "deviation_pp": 78.0927189797799, "boss": false}, {"level": 56, "metric": "enemy_hp", "deviation_pp": -6.469256211205007, "boss": false}, {"level": 57, "metric": "recommended", "deviation_pp": 5.952317114288503, "boss": false}, {"level": 57, "metric": "p_star", "deviation_pp": 224.90168867412893, "boss": false}, {"level": 57, "metric": "difficulty_coef", "deviation_pp": -15.521966390596795, "boss": false}, {"level": 57, "metric": "enemy_hp", "deviation_pp": 239.1660393844865, "boss": false}, {"level": 58, "metric": "p_star", "deviation_pp": -61.86598809354783, "boss": false}, {"level": 58, "metric": "difficulty_coef", "deviation_pp": 40.58206137093477, "boss": false}, {"level": 58, "metric": "enemy_hp", "deviation_pp": -65.11023655038201, "boss": false}, {"level": 59, "metric": "difficulty_coef", "deviation_pp": 41.60724977476393, "boss": false}, {"level": 59, "metric": "enemy_hp", "deviation_pp": 21.74896263115246, "boss": false}, {"level": 60, "metric": "recommended", "deviation_pp": -3.683564323721072, "boss": true}, {"level": 60, "metric": "p_star", "deviation_pp": 89.96514892796995, "boss": true}, {"level": 60, "metric": "difficulty_coef", "deviation_pp": -58.25289008537592, "boss": true}, {"level": 60, "metric": "enemy_hp", "deviation_pp": -17.53864832042432, "boss": true}]`；Boss台阶：`[{"level": 55, "growth": {"recommended": 0.06329113924050622, "p_star": 1.996845425867508, "difficulty_coef": -0.6638095238095238, "enemy_hp": -0.004587854370190381}}, {"level": 60, "growth": {"recommended": 0.004754358161648264, "p_star": 0.9839679358717435, "difficulty_coef": -0.6, "enemy_hp": -0.023553538207321756}}]`

|7|4.39%|11.16%|12.47%|13.80%|10.0000/10|10.0000/10|10.0000(外推/未验)|

章7偏離>3pp：`[{"level": 62, "metric": "recommended", "deviation_pp": -4.386521485521415, "boss": false}, {"level": 62, "metric": "p_star", "deviation_pp": -92.37081461977824, "boss": false}, {"level": 62, "metric": "difficulty_coef", "deviation_pp": -94.20992848566925, "boss": false}, {"level": 62, "metric": "enemy_hp", "deviation_pp": -94.98861517863439, "boss": false}, {"level": 63, "metric": "p_star", "deviation_pp": 138.84130659234296, "boss": false}, {"level": 63, "metric": "difficulty_coef", "deviation_pp": 335.14824956816096, "boss": false}, {"level": 63, "metric": "enemy_hp", "deviation_pp": 396.3058856866253, "boss": false}, {"level": 64, "metric": "p_star", "deviation_pp": 94.21765067836448, "boss": false}, {"level": 64, "metric": "difficulty_coef", "deviation_pp": 25.82707428953888, "boss": false}, {"level": 64, "metric": "enemy_hp", "deviation_pp": 21.71592358741879, "boss": false}, {"level": 65, "metric": "p_star", "deviation_pp": -4.980682936452843, "boss": true}, {"level": 65, "metric": "difficulty_coef", "deviation_pp": -89.39387497396356, "boss": true}, {"level": 65, "metric": "enemy_hp", "deviation_pp": -65.34590180602338, "boss": true}, {"level": 66, "metric": "recommended", "deviation_pp": -4.386521485521415, "boss": false}, {"level": 66, "metric": "p_star", "deviation_pp": 5.606592588398193, "boss": false}, {"level": 66, "metric": "difficulty_coef", "deviation_pp": 754.19586861578, "boss": false}, {"level": 66, "metric": "enemy_hp", "deviation_pp": 88.01445150447944, "boss": false}, {"level": 67, "metric": "recommended", "deviation_pp": -4.386521485521415, "boss": false}, {"level": 67, "metric": "p_star", "deviation_pp": -30.499909623873243, "boss": false}, {"level": 67, "metric": "difficulty_coef", "deviation_pp": -8.624644204732784, "boss": false}, {"level": 67, "metric": "enemy_hp", "deviation_pp": -16.632877072985046, "boss": false}, {"level": 68, "metric": "recommended", "deviation_pp": 9.450376910200514, "boss": false}, {"level": 68, "metric": "p_star", "deviation_pp": -8.226756234882163, "boss": false}, {"level": 68, "metric": "difficulty_coef", "deviation_pp": 6.047720467631873, "boss": false}, {"level": 68, "metric": "enemy_hp", "deviation_pp": 88.25133002609324, "boss": false}, {"level": 69, "metric": "p_star", "deviation_pp": -11.66734040663974, "boss": false}, {"level": 69, "metric": "difficulty_coef", "deviation_pp": -71.84579805088664, "boss": false}, {"level": 69, "metric": "enemy_hp", "deviation_pp": -64.96605437470349, "boss": false}, {"level": 70, "metric": "p_star", "deviation_pp": 14.403678780482029, "boss": true}, {"level": 70, "metric": "difficulty_coef", "deviation_pp": -54.778490358578956, "boss": true}]`；Boss台阶：`[{"level": 65, "growth": {"recommended": 0.06552706552706544, "p_star": 0.06178010471204187, "difficulty_coef": -0.7692307692307692, "enemy_hp": -0.515489908321112}}, {"level": 70, "growth": {"recommended": 0.06321184510250566, "p_star": 0.2556237218813906, "difficulty_coef": -0.42307692307692313, "enemy_hp": 0.13459379587901155}}]`

|8|4.03%|8.73%|6.22%|5.94%|8.4000/10|9.1667/10|10.0000(外推/未验)|

章8偏離>3pp：`[{"level": 72, "metric": "recommended", "deviation_pp": -4.029467231241439, "boss": false}, {"level": 72, "metric": "p_star", "deviation_pp": 52.41822062704015, "boss": false}, {"level": 72, "metric": "difficulty_coef", "deviation_pp": -6.2159982105854485, "boss": false}, {"level": 72, "metric": "enemy_hp", "deviation_pp": 7.171665095234991, "boss": false}, {"level": 73, "metric": "recommended", "deviation_pp": -4.029467231241439, "boss": false}, {"level": 73, "metric": "p_star", "deviation_pp": -70.27519699724229, "boss": false}, {"level": 73, "metric": "difficulty_coef", "deviation_pp": -38.749331543918785, "boss": false}, {"level": 73, "metric": "enemy_hp", "deviation_pp": -40.122508396086474, "boss": false}, {"level": 74, "metric": "p_star", "deviation_pp": 226.91659070944718, "boss": false}, {"level": 74, "metric": "difficulty_coef", "deviation_pp": 121.05672906214184, "boss": false}, {"level": 74, "metric": "enemy_hp", "deviation_pp": 64.15111152875252, "boss": false}, {"level": 75, "metric": "recommended", "deviation_pp": 12.894401081515767, "boss": true}, {"level": 75, "metric": "p_star", "deviation_pp": -18.21566587904354, "boss": true}, {"level": 75, "metric": "difficulty_coef", "deviation_pp": -67.08556342797675, "boss": true}, {"level": 75, "metric": "enemy_hp", "deviation_pp": -34.18728491017372, "boss": true}, {"level": 76, "metric": "recommended", "deviation_pp": -4.029467231241439, "boss": false}, {"level": 76, "metric": "difficulty_coef", "deviation_pp": 316.0062240116368, "boss": false}, {"level": 76, "metric": "enemy_hp", "deviation_pp": 200.13168189224317, "boss": false}, {"level": 77, "metric": "recommended", "deviation_pp": -3.32555170110506, "boss": false}, {"level": 77, "metric": "difficulty_coef", "deviation_pp": -24.6370508421644, "boss": false}, {"level": 77, "metric": "enemy_hp", "deviation_pp": -43.81861085902295, "boss": false}, {"level": 78, "metric": "p_star", "deviation_pp": 31.98099095478143, "boss": false}, {"level": 78, "metric": "difficulty_coef", "deviation_pp": 29.267872757156475, "boss": false}, {"level": 79, "metric": "p_star", "deviation_pp": -17.532005093529357, "boss": false}, {"level": 79, "metric": "difficulty_coef", "deviation_pp": -49.07314106772831, "boss": false}, {"level": 79, "metric": "enemy_hp", "deviation_pp": -26.50196459191154, "boss": false}, {"level": 80, "metric": "p_star", "deviation_pp": -10.5003726617668, "boss": true}, {"level": 80, "metric": "difficulty_coef", "deviation_pp": -60.382664877252125, "boss": true}, {"level": 80, "metric": "enemy_hp", "deviation_pp": -30.484604288626016, "boss": true}]`；Boss台阶：`[{"level": 75, "growth": {"recommended": 0.16923868312757206, "p_star": -0.09488692232055063, "difficulty_coef": -0.6086956521739131, "enemy_hp": -0.28250949240930423}}, {"level": 80, "growth": {"recommended": 0.05968928863450529, "p_star": -0.017733990147783207, "difficulty_coef": -0.5416666666666667, "enemy_hp": -0.24548268619382718}}]`

|9|4.08%|6.95%|-0.59%|10.34%|9.9231/10|9.9231/10|10.0000(外推/未验)|

章9偏離>3pp：`[{"level": 82, "metric": "recommended", "deviation_pp": -4.0778764089146815, "boss": false}, {"level": 82, "metric": "p_star", "deviation_pp": 70.67131922761128, "boss": false}, {"level": 82, "metric": "difficulty_coef", "deviation_pp": 29.499467330434705, "boss": false}, {"level": 82, "metric": "enemy_hp", "deviation_pp": 21.679603240250746, "boss": false}, {"level": 83, "metric": "recommended", "deviation_pp": -3.460592458297395, "boss": false}, {"level": 83, "metric": "p_star", "deviation_pp": -3.9417029978656273, "boss": false}, {"level": 83, "metric": "difficulty_coef", "deviation_pp": 73.92806126618287, "boss": false}, {"level": 83, "metric": "enemy_hp", "deviation_pp": 9.047762626656889, "boss": false}, {"level": 84, "metric": "recommended", "deviation_pp": 6.159853652435011, "boss": false}, {"level": 84, "metric": "p_star", "deviation_pp": -48.60254107630767, "boss": false}, {"level": 84, "metric": "difficulty_coef", "deviation_pp": 35.21011254823415, "boss": false}, {"level": 84, "metric": "enemy_hp", "deviation_pp": -7.58802101389234, "boss": false}, {"level": 85, "metric": "p_star", "deviation_pp": 101.17122022977401, "boss": true}, {"level": 85, "metric": "difficulty_coef", "deviation_pp": -42.26241492429333, "boss": true}, {"level": 86, "metric": "recommended", "deviation_pp": -3.3250122517952, "boss": false}, {"level": 86, "metric": "p_star", "deviation_pp": -24.417888078752515, "boss": false}, {"level": 86, "metric": "difficulty_coef", "deviation_pp": 45.59472793284952, "boss": false}, {"level": 86, "metric": "enemy_hp", "deviation_pp": 33.40020669705338, "boss": false}, {"level": 87, "metric": "p_star", "deviation_pp": -4.860588591289574, "boss": false}, {"level": 87, "metric": "enemy_hp", "deviation_pp": -30.2743622945692, "boss": false}, {"level": 88, "metric": "p_star", "deviation_pp": -6.949648514324204, "boss": false}, {"level": 88, "metric": "difficulty_coef", "deviation_pp": 10.93955551905642, "boss": false}, {"level": 88, "metric": "enemy_hp", "deviation_pp": -5.128461968829575, "boss": false}, {"level": 89, "metric": "difficulty_coef", "deviation_pp": -30.030272067150477, "boss": false}, {"level": 89, "metric": "enemy_hp", "deviation_pp": -6.8351225958875075, "boss": false}, {"level": 90, "metric": "recommended", "deviation_pp": 5.656636865421595, "boss": true}, {"level": 90, "metric": "p_star", "deviation_pp": 22.588967333218424, "boss": true}, {"level": 90, "metric": "difficulty_coef", "deviation_pp": -67.87374053561894, "boss": true}, {"level": 90, "metric": "enemy_hp", "deviation_pp": 14.41169279554785, "boss": true}]`；Boss台阶：`[{"level": 85, "growth": {"recommended": 0.06260869565217386, "p_star": 1.081208687440982, "difficulty_coef": -0.4285714285714286, "enemy_hp": 0.13250406175972107}}, {"level": 90, "growth": {"recommended": 0.09734513274336276, "p_star": 0.29538615847542626, "difficulty_coef": -0.6846846846846847, "enemy_hp": 0.24751646274975125}}]`

|10|4.06%|8.94%|-3.38%|6.91%|10.0000/10|10.0000/10|10.0000(外推/未验)|

章10偏離>3pp：`[{"level": 92, "metric": "recommended", "deviation_pp": -3.3094707216974664, "boss": false}, {"level": 92, "metric": "p_star", "deviation_pp": 72.59032785792566, "boss": false}, {"level": 92, "metric": "difficulty_coef", "deviation_pp": 56.71602452944812, "boss": false}, {"level": 92, "metric": "enemy_hp", "deviation_pp": 56.50606538987226, "boss": false}, {"level": 93, "metric": "p_star", "deviation_pp": 16.396081847334642, "boss": false}, {"level": 93, "metric": "difficulty_coef", "deviation_pp": 25.12182163089739, "boss": false}, {"level": 93, "metric": "enemy_hp", "deviation_pp": -17.754318760088122, "boss": false}, {"level": 94, "metric": "recommended", "deviation_pp": -4.062158893740481, "boss": false}, {"level": 94, "metric": "p_star", "deviation_pp": -28.176729781280763, "boss": false}, {"level": 94, "metric": "difficulty_coef", "deviation_pp": -12.688737375313796, "boss": false}, {"level": 94, "metric": "enemy_hp", "deviation_pp": -15.817132597802269, "boss": false}, {"level": 95, "metric": "recommended", "deviation_pp": 9.102528767591483, "boss": true}, {"level": 95, "metric": "p_star", "deviation_pp": 75.21722890473586, "boss": true}, {"level": 95, "metric": "difficulty_coef", "deviation_pp": -51.936457740055445, "boss": true}, {"level": 95, "metric": "enemy_hp", "deviation_pp": 151.71865638849894, "boss": true}, {"level": 96, "metric": "recommended", "deviation_pp": -4.062158893740481, "boss": false}, {"level": 96, "metric": "p_star", "deviation_pp": -36.85862522443344, "boss": false}, {"level": 96, "metric": "difficulty_coef", "deviation_pp": 174.81126262468624, "boss": false}, {"level": 96, "metric": "enemy_hp", "deviation_pp": -38.50567544487346, "boss": false}, {"level": 97, "metric": "recommended", "deviation_pp": 3.442403150055134, "boss": false}, {"level": 97, "metric": "p_star", "deviation_pp": -32.23754683557869, "boss": false}, {"level": 97, "metric": "difficulty_coef", "deviation_pp": -33.45941406704313, "boss": false}, {"level": 97, "metric": "enemy_hp", "deviation_pp": -43.86086222240896, "boss": false}, {"level": 98, "metric": "recommended", "deviation_pp": -3.956069354169073, "boss": false}, {"level": 98, "metric": "p_star", "deviation_pp": 37.065296977560415, "boss": false}, {"level": 98, "metric": "difficulty_coef", "deviation_pp": 25.604913418337006, "boss": false}, {"level": 99, "metric": "p_star", "deviation_pp": -8.935776559745014, "boss": true}, {"level": 99, "metric": "difficulty_coef", "deviation_pp": -46.61730880388523, "boss": true}, {"level": 99, "metric": "enemy_hp", "deviation_pp": 46.23564622572424, "boss": true}]`；Boss台阶：`[{"level": 95, "growth": {"recommended": 0.13164687661331964, "p_star": 0.8415300546448088, "difficulty_coef": -0.5531914893617021, "enemy_hp": 1.5863225409156283}}, {"level": 99, "growth": {"recommended": 0.059771089444679903, "p_star": 0.0, "difficulty_coef": -0.5, "enemy_hp": 0.5314924392878815}}]`


## 资源曲线

|曲线|对推荐相关|对P*相关|对P*逐关增幅差>2pp|
|---|---:|---:|---|
|first_clear_gold_formula|0.9262|0.8755|[9, 10, 13, 14, 22, 23, 24, 25, 26, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 42, 43, 46, 47, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 62, 63, 64, 65, 66, 67, 70, 71, 72, 73, 74, 75, 78, 79, 80, 81, 82, 84, 85, 86, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98]|
|first_clear_reward.gold|0.9424|0.8871|[9, 10, 13, 14, 22, 23, 24, 25, 26, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 42, 43, 46, 47, 48, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 62, 63, 64, 65, 66, 67, 69, 70, 71, 72, 73, 74, 75, 78, 79, 80, 81, 82, 84, 85, 86, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98]|
|reward_gold_mult|-0.8854|-0.8463|[10, 13, 14, 22, 24, 25, 26, 27, 28, 30, 31, 32, 33, 34, 35, 36, 38, 39, 42, 43, 46, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 78, 79, 81, 82, 83, 84, 85, 86, 87, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98]|
|earned_gold_cumulative|0.9472|0.8829|[9, 10, 13, 14, 22, 23, 25, 26, 27, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 42, 43, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 69, 70, 71, 72, 73, 74, 75, 78, 79, 80, 81, 82, 84, 85, 86, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98]|
|earned_xp_cumulative|0.9895|0.9158|[9, 10, 14, 22, 23, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 42, 43, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 69, 70, 71, 72, 73, 74, 75, 78, 79, 80, 81, 82, 84, 85, 86, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98]|
|earned_stars_cumulative|0.9262|0.8755|[9, 10, 13, 14, 22, 23, 24, 25, 26, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 42, 43, 46, 47, 48, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 62, 63, 64, 65, 66, 67, 69, 70, 71, 72, 73, 74, 75, 78, 79, 80, 81, 82, 84, 85, 86, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98]|
|star_unlock_spending_cumulative|0.5959|0.5372|[9, 10, 13, 14, 22, 24, 25, 26, 27, 28, 30, 31, 32, 33, 34, 35, 36, 38, 39, 42, 43, 46, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 62, 63, 64, 65, 66, 67, 68, 70, 71, 72, 73, 74, 75, 78, 79, 81, 82, 83, 84, 85, 86, 87, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98]|
|equipped_weapon_upgrade_cost|0.8213|0.7707|[9, 10, 13, 22, 23, 25, 26, 27, 28, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 42, 43, 46, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 70, 71, 72, 73, 74, 75, 78, 79, 81, 82, 83, 84, 85, 86, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98]|
|equipped_weapon_growth|0.8723|0.8157|[9, 10, 13, 14, 22, 23, 24, 25, 26, 27, 28, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 42, 43, 46, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 70, 71, 72, 73, 74, 75, 78, 79, 81, 82, 83, 84, 85, 86, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98]|
|permanent_skill_next_xp_cost|0.5543|0.5187|[9, 10, 13, 14, 22, 23, 25, 26, 27, 28, 30, 31, 32, 33, 34, 35, 36, 38, 39, 42, 43, 46, 47, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 62, 63, 64, 66, 67, 68, 70, 71, 72, 73, 74, 75, 78, 79, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 95, 96, 97, 98]|

### 星星门槛来源

- `data/armors.json/armor_kevlar/unlock_cost_star` = `8`
- `data/armors.json/armor_thermal/unlock_cost_star` = `8`
- `data/armors.json/armor_cryo/unlock_cost_star` = `9`
- `data/armors.json/armor_faraday/unlock_cost_star` = `10`
- `data/armors.json/armor_hazmat/unlock_cost_star` = `11`
- `data/armors.json/armor_reactive/unlock_cost_star` = `14`
- `data/armors.json/armor_apocalypse_conductor/unlock_cost_star` = `999999`
- `data/armors.json/armor_apocalypse_molten/unlock_cost_star` = `999999`
- `data/armors.json/armor_apocalypse_permafrost/unlock_cost_star` = `999999`
- `data/armors.json/armor_apocalypse_eternal_night/unlock_cost_star` = `999999`
- `data/campaign_progression_fixture.json/assumptions/stars_per_clear` = `2`
- `data/campaign_progression_fixture.json/initial_account/stars` = `0`
- `data/campaign_progression_fixture.json/weapon_strategies/matchup_aware_v2/star_weapon_pool` = `{"source": "free_star_weapons", "minimum_star_cost": 1, "maximum_star_cost": 999, "chapter_reference": "next_chapter", "final_chapter_fallback": "current_chapter", "weakness_rule": "chapter_primary_weakness_mode", "tie_break": "first_authored_level_then_unlock_cost_then_weapon_order", "reserve_stars_for_next_matching_weapon": true}`
- `data/campaign_progression_fixture.json/weapon_strategies/matchup_aware_v2/star_weapon_pool/minimum_star_cost` = `1`
- `data/campaign_progression_fixture.json/weapon_strategies/matchup_aware_v2/star_weapon_pool/maximum_star_cost` = `999`
- `data/campaign_progression_fixture.json/weapon_strategies/matchup_aware_v2/star_weapon_pool/reserve_stars_for_next_matching_weapon` = `true`
- `data/characters.json/vanguard/unlock_cost_star` = `0`
- `data/characters.json/blaze/unlock_cost_star` = `10`
- `data/characters.json/frost/unlock_cost_star` = `12`
- `data/characters.json/volt/unlock_cost_star` = `16`
- `data/chips.json/chip_attack/unlock_cost_star` = `8`
- `data/chips.json/chip_haste/unlock_cost_star` = `8`
- `data/chips.json/chip_crit/unlock_cost_star` = `9`
- `data/chips.json/chip_pierce/unlock_cost_star` = `11`
- `data/chips.json/chip_health/unlock_cost_star` = `9`
- `data/chips.json/chip_guardian/unlock_cost_star` = `10`
- `data/chips.json/chip_greed/unlock_cost_star` = `11`
- `data/chips.json/chip_element/unlock_cost_star` = `14`
- `data/chips.json/chip_apocalypse_superconductive/unlock_cost_star` = `999999`
- `data/chips.json/chip_apocalypse_stellar/unlock_cost_star` = `999999`
- `data/chips.json/chip_apocalypse_entropy/unlock_cost_star` = `999999`
- `data/chips.json/chip_apocalypse_golden_law/unlock_cost_star` = `999999`
- `data/economy.json/late_wave_count_level_ramp/start_level` = `55`
- `data/economy.json/late_wave_count_level_ramp/start_wave` = `3`
- `data/economy.json/late_wave_level_ramp/start_level` = `50`
- `data/economy.json/late_wave_damage_ramp/start_level` = `50`
- `data/economy.json/late_wave_damage_ramp/start_wave` = `3`
- `data/economy.json/boss_hp_level_bonus/start_level` = `20`
- `data/economy.json/boss_survival_hp_ramp/start_level` = `50`
- `data/economy.json/boss_pacing/same_type_hp_start_level` = `11`
- `data/economy.json/endless_boss_pacing/reference_transition/start_loop` = `7`
- `data/economy.json/star_thresholds` = `{"three_star_hp_ratio": 0.7, "two_star_hp_ratio": 0.35}`
- `data/economy.json/star_thresholds/three_star_hp_ratio` = `0.7`
- `data/economy.json/star_thresholds/two_star_hp_ratio` = `0.35`
- `data/economy.json/wave_pressure/start_level` = `11`
- `data/economy.json/wave_pressure/star_boundary_margin_pct` = `2.0`
- `data/levels.json/0/star_rule` = `"base_hp_percent"`
- `data/levels.json/1/star_rule` = `"base_hp_percent"`
- `data/levels.json/2/star_rule` = `"base_hp_percent"`
- `data/levels.json/3/star_rule` = `"base_hp_percent"`
- `data/levels.json/4/star_rule` = `"base_hp_percent"`
- `data/levels.json/5/star_rule` = `"base_hp_percent"`
- `data/levels.json/6/star_rule` = `"base_hp_percent"`
- `data/levels.json/7/star_rule` = `"base_hp_percent"`
- `data/levels.json/8/star_rule` = `"base_hp_percent"`
- `data/levels.json/9/star_rule` = `"base_hp_percent"`
- `data/levels.json/10/star_rule` = `"base_hp_percent"`
- `data/levels.json/11/star_rule` = `"base_hp_percent"`
- `data/levels.json/12/star_rule` = `"base_hp_percent"`
- `data/levels.json/13/star_rule` = `"base_hp_percent"`
- `data/levels.json/14/star_rule` = `"base_hp_percent"`
- `data/levels.json/15/star_rule` = `"base_hp_percent"`
- `data/levels.json/16/star_rule` = `"base_hp_percent"`
- `data/levels.json/17/star_rule` = `"base_hp_percent"`
- `data/levels.json/18/star_rule` = `"base_hp_percent"`
- `data/levels.json/19/star_rule` = `"base_hp_percent"`
- `data/levels.json/20/star_rule` = `"base_hp_percent"`
- `data/levels.json/21/star_rule` = `"base_hp_percent"`
- `data/levels.json/22/star_rule` = `"base_hp_percent"`
- `data/levels.json/23/star_rule` = `"base_hp_percent"`
- `data/levels.json/24/star_rule` = `"base_hp_percent"`
- `data/levels.json/25/star_rule` = `"base_hp_percent"`
- `data/levels.json/26/star_rule` = `"base_hp_percent"`
- `data/levels.json/27/star_rule` = `"base_hp_percent"`
- `data/levels.json/28/star_rule` = `"base_hp_percent"`
- `data/levels.json/29/star_rule` = `"base_hp_percent"`
- `data/levels.json/30/star_rule` = `"base_hp_percent"`
- `data/levels.json/31/star_rule` = `"base_hp_percent"`
- `data/levels.json/32/star_rule` = `"base_hp_percent"`
- `data/levels.json/33/star_rule` = `"base_hp_percent"`
- `data/levels.json/34/star_rule` = `"base_hp_percent"`
- `data/levels.json/35/star_rule` = `"base_hp_percent"`
- `data/levels.json/36/star_rule` = `"base_hp_percent"`
- `data/levels.json/37/star_rule` = `"base_hp_percent"`
- `data/levels.json/38/star_rule` = `"base_hp_percent"`
- `data/levels.json/39/star_rule` = `"base_hp_percent"`
- `data/levels.json/40/star_rule` = `"base_hp_percent"`
- `data/levels.json/41/star_rule` = `"base_hp_percent"`
- `data/levels.json/42/star_rule` = `"base_hp_percent"`
- `data/levels.json/43/star_rule` = `"base_hp_percent"`
- `data/levels.json/44/star_rule` = `"base_hp_percent"`
- `data/levels.json/45/star_rule` = `"base_hp_percent"`
- `data/levels.json/46/star_rule` = `"base_hp_percent"`
- `data/levels.json/47/star_rule` = `"base_hp_percent"`
- `data/levels.json/48/star_rule` = `"base_hp_percent"`
- `data/levels.json/49/star_rule` = `"base_hp_percent"`
- `data/levels.json/50/star_rule` = `"base_hp_percent"`
- `data/levels.json/51/star_rule` = `"base_hp_percent"`
- `data/levels.json/52/star_rule` = `"base_hp_percent"`
- `data/levels.json/53/star_rule` = `"base_hp_percent"`
- `data/levels.json/54/star_rule` = `"base_hp_percent"`
- `data/levels.json/55/star_rule` = `"base_hp_percent"`
- `data/levels.json/56/star_rule` = `"base_hp_percent"`
- `data/levels.json/57/star_rule` = `"base_hp_percent"`
- `data/levels.json/58/star_rule` = `"base_hp_percent"`
- `data/levels.json/59/star_rule` = `"base_hp_percent"`
- `data/levels.json/60/star_rule` = `"base_hp_percent"`
- `data/levels.json/61/star_rule` = `"base_hp_percent"`
- `data/levels.json/62/star_rule` = `"base_hp_percent"`
- `data/levels.json/63/star_rule` = `"base_hp_percent"`
- `data/levels.json/64/star_rule` = `"base_hp_percent"`
- `data/levels.json/65/star_rule` = `"base_hp_percent"`
- `data/levels.json/66/star_rule` = `"base_hp_percent"`
- `data/levels.json/67/star_rule` = `"base_hp_percent"`
- `data/levels.json/68/star_rule` = `"base_hp_percent"`
- `data/levels.json/69/star_rule` = `"base_hp_percent"`
- `data/levels.json/70/star_rule` = `"base_hp_percent"`
- `data/levels.json/71/star_rule` = `"base_hp_percent"`
- `data/levels.json/72/star_rule` = `"base_hp_percent"`
- `data/levels.json/73/star_rule` = `"base_hp_percent"`
- `data/levels.json/74/star_rule` = `"base_hp_percent"`
- `data/levels.json/75/star_rule` = `"base_hp_percent"`
- `data/levels.json/76/star_rule` = `"base_hp_percent"`
- `data/levels.json/77/star_rule` = `"base_hp_percent"`
- `data/levels.json/78/star_rule` = `"base_hp_percent"`
- `data/levels.json/79/star_rule` = `"base_hp_percent"`
- `data/levels.json/80/star_rule` = `"base_hp_percent"`
- `data/levels.json/81/star_rule` = `"base_hp_percent"`
- `data/levels.json/82/star_rule` = `"base_hp_percent"`
- `data/levels.json/83/star_rule` = `"base_hp_percent"`
- `data/levels.json/84/star_rule` = `"base_hp_percent"`
- `data/levels.json/85/star_rule` = `"base_hp_percent"`
- `data/levels.json/86/star_rule` = `"base_hp_percent"`
- `data/levels.json/87/star_rule` = `"base_hp_percent"`
- `data/levels.json/88/star_rule` = `"base_hp_percent"`
- `data/levels.json/89/star_rule` = `"base_hp_percent"`
- `data/levels.json/90/star_rule` = `"base_hp_percent"`
- `data/levels.json/91/star_rule` = `"base_hp_percent"`
- `data/levels.json/92/star_rule` = `"base_hp_percent"`
- `data/levels.json/93/star_rule` = `"base_hp_percent"`
- `data/levels.json/94/star_rule` = `"base_hp_percent"`
- `data/levels.json/95/star_rule` = `"base_hp_percent"`
- `data/levels.json/96/star_rule` = `"base_hp_percent"`
- `data/levels.json/97/star_rule` = `"base_hp_percent"`
- `data/levels.json/98/star_rule` = `"base_hp_percent"`
- `data/localization_en.json/ui_start` = `"Start"`
- `data/localization_zh.json/ui_start` = `"开始"`
- `data/pets.json/pet_turret_drone/unlock_cost_star` = `8`
- `data/pets.json/pet_fire_imp/unlock_cost_star` = `9`
- `data/pets.json/pet_frost_wisp/unlock_cost_star` = `10`
- `data/pets.json/pet_volt_orb/unlock_cost_star` = `11`
- `data/pets.json/pet_medic_drone/unlock_cost_star` = `13`
- `data/pets.json/pet_collector/unlock_cost_star` = `14`
- `data/pets.json/pet_apocalypse_tempest/unlock_cost_star` = `999999`
- `data/pets.json/pet_apocalypse_phoenix/unlock_cost_star` = `999999`
- `data/pets.json/pet_apocalypse_aurora/unlock_cost_star` = `999999`
- `data/pets.json/pet_apocalypse_skyfalcon/unlock_cost_star` = `999999`
- `data/weapons.json/weapon_autocannon/unlock_cost_star` = `0`
- `data/weapons.json/weapon_flamethrower/unlock_cost_star` = `8`
- `data/weapons.json/weapon_cryocannon/unlock_cost_star` = `8`
- `data/weapons.json/weapon_teslacoil/unlock_cost_star` = `10`
- `data/weapons.json/weapon_venomlauncher/unlock_cost_star` = `8`
- `data/weapons.json/weapon_railgun/unlock_cost_star` = `14`
- `data/weapons.json/weapon_scattergun/unlock_cost_star` = `9`
- `data/weapons.json/weapon_plasmacannon/unlock_cost_star` = `16`
- `data/weapons.json/weapon_apocalypse_thunder/unlock_cost_star` = `999999`
- `data/weapons.json/weapon_apocalypse_inferno/unlock_cost_star` = `999999`
- `data/weapons.json/weapon_apocalypse_absolute_zero/unlock_cost_star` = `999999`
- `data/weapons.json/weapon_apocalypse_golden_law/unlock_cost_star` = `999999`

### 成长与成本目录

所有免费/付费武器逐级成本、伤害成长与DPS成长保存在JSON的resource_catalog.weapons；按数据段计算，不用假定线性。
技能XP成本：[350, 900, 2000, 4000, 8500]；专属技能：[450, 1200, 2700, 5400, 11000]。

## 已知事实复现

```json
{
  "ch2_recommendations_low": {
    "observed_levels": [
      12,
      13,
      14,
      16
    ],
    "status": "partial",
    "median_r_star": 0.9008928571428572,
    "shortfall_as_pct_of_recommendation": [
      9.999999999999998,
      9.82142857142857,
      -1.6949152542372836,
      33.333333333333336
    ],
    "recommended_excess_as_pct_of_P_star": [
      11.111111111111116,
      10.89108910891088,
      -1.6666666666666607,
      50.0
    ],
    "observed_match": false
  },
  "035_recommendation_high": {
    "observed_levels": [
      35
    ],
    "status": "reproduced",
    "median_r_star": 0.4765625,
    "shortfall_as_pct_of_recommendation": [
      52.34375
    ],
    "recommended_excess_as_pct_of_P_star": [
      109.8360655737705
    ],
    "observed_match": true
  },
  "060_099_recommendations_high_12_40_pct": {
    "observed_levels": [
      60,
      61,
      62,
      63,
      64,
      65,
      66,
      67,
      68,
      69,
      70,
      71,
      72,
      73,
      74,
      75,
      77,
      78,
      79,
      80,
      81,
      82,
      83,
      84,
      85,
      86,
      87,
      88,
      89,
      90,
      91,
      92,
      93,
      94,
      95,
      96,
      97,
      98,
      99
    ],
    "status": "partial",
    "median_r_star": 0.5909681611435997,
    "shortfall_as_pct_of_recommendation": [
      21.924290220820186,
      21.924290220820186,
      85.33123028391168,
      65.75846833578792,
      31.980056980056982,
      32.21925133689839,
      20.85561497326203,
      36.16310160427807,
      42.27833235466824,
      44.305239179954434,
      34.22603106588109,
      47.616497054097486,
      15.586502410283876,
      67.54151044456347,
      -4.629629629629628,
      19.005719313682356,
      30.886850152905197,
      5.917159763313606,
      17.007358953393293,
      23.070987654320984,
      61.728395061728406,
      32.02160493827161,
      30.40644171779141,
      63.16521739130434,
      27.85597381342062,
      40.903183885640026,
      41.585404215162,
      43.48752282410226,
      41.179941002949846,
      30.56451612903226,
      73.2258064516129,
      51.76093916755603,
      41.50748580278781,
      52.762003097573576,
      23.129562043795616,
      44.59397810218978,
      60.471037555697,
      42.34845273420941,
      45.599999999999994
    ],
    "recommended_excess_as_pct_of_P_star": [
      28.080808080808083,
      28.080808080808083,
      581.7204301075269,
      192.04301075268816,
      47.01570680628273,
      47.53451676528599,
      26.351351351351337,
      56.64921465968584,
      73.24516785350967,
      79.55010224948873,
      52.0358306188925,
      90.8997955010225,
      18.464467005076134,
      208.08580858085807,
      -4.424778761061942,
      23.46550787615427,
      44.69026548672566,
      6.2893081761006275,
      20.49261083743843,
      29.989969909729176,
      161.29032258064518,
      47.10556186152102,
      43.69146005509641,
      171.48253068932954,
      38.61161524500907,
      69.2138537658054,
      71.1900915455035,
      76.95207323640281,
      70.0100300902708,
      44.01858304297328,
      273.49397590361446,
      107.30088495575222,
      70.96204766107678,
      111.69398907103827,
      30.08902077151334,
      80.48579662412514,
      152.9790660225443,
      73.45588235294116,
      83.8235294117647
    ],
    "observed_match": false
  }
}
```

ch2 R*>1才证明推荐偏低，035 R*<1才证明偏高。060–099的12–40%按(推荐−P*)/推荐=1−R*统计，另列以P*为分母的超额百分比，避免混用；未测不写复现。

## 悬崖

`[{"level": 14, "kind": "P_star_growth", "growth": 0.18811881188118806, "boss_edge": false}, {"level": 30, "kind": "P_star_growth", "growth": 0.38834951456310685, "boss_edge": true}, {"level": 32, "kind": "P_star_growth", "growth": 0.6554054054054055, "boss_edge": false}, {"level": 34, "kind": "P_star_growth", "growth": 0.4162679425837321, "boss_edge": false}, {"level": 38, "kind": "P_star_growth", "growth": 1.3157894736842106, "boss_edge": false}, {"level": 42, "kind": "P_star_growth", "growth": 0.32444444444444454, "boss_edge": false}, {"level": 43, "kind": "P_star_growth", "growth": 0.9697986577181208, "boss_edge": false}, {"level": 50, "kind": "P_star_growth", "growth": 0.412751677852349, "boss_edge": true}, {"level": 53, "kind": "P_star_growth", "growth": 0.29003021148036257, "boss_edge": false}, {"level": 55, "kind": "P_star_growth", "growth": 1.996845425867508, "boss_edge": true}, {"level": 57, "kind": "P_star_growth", "growth": 2.3333333333333335, "boss_edge": false}, {"level": 60, "kind": "P_star_growth", "growth": 0.9839679358717435, "boss_edge": true}, {"level": 63, "kind": "P_star_growth", "growth": 1.5, "boss_edge": false}, {"level": 64, "kind": "P_star_growth", "growth": 1.053763440860215, "boss_edge": false}, {"level": 70, "kind": "P_star_growth", "growth": 0.2556237218813906, "boss_edge": true}, {"level": 72, "kind": "P_star_growth", "growth": 0.6114519427402862, "boss_edge": false}, {"level": 74, "kind": "P_star_growth", "growth": 2.3564356435643563, "boss_edge": false}, {"level": 78, "kind": "P_star_growth", "growth": 0.4070796460176991, "boss_edge": false}, {"level": 82, "kind": "P_star_growth", "growth": 0.7762096774193548, "boss_edge": false}, {"level": 85, "kind": "P_star_growth", "growth": 1.081208687440982, "boss_edge": true}, {"level": 90, "kind": "P_star_growth", "growth": 0.29538615847542626, "boss_edge": true}, {"level": 92, "kind": "P_star_growth", "growth": 0.8152610441767068, "boss_edge": false}, {"level": 93, "kind": "P_star_growth", "growth": 0.25331858407079655, "boss_edge": false}, {"level": 95, "kind": "P_star_growth", "growth": 0.8415300546448088, "boss_edge": true}, {"level": 98, "kind": "P_star_growth", "growth": 0.46001073537305426, "boss_edge": false}]`

## 逐敌威胁 (§40.13)

下表是单体到线20秒的减伤前预算，不等于实际损血。按参考构筑的基地HP估计比例详见JSON的appearances，护盾/控场/远程/召唤等尚未建模。

|敌人|机制|每轮伤害|间隔|20秒接触伤害|
|---|---|---:|---:|---:|
|boss_tank_titan|armor_break|12|3.5|72|
|boss_inferno_maw|phase_burn|26|4.0|130|
|boss_frost_warden|freeze_field|28|4.0|140|
|boss_storm_caller|storm_chain|30|3.0|180|
|boss_plague_mother|spawn_minions|24|4.0|120|
|boss_void_phantom|phase_shift|18|2.5|144|
|boss_necrotitan|regenerate|120|5.0|480|
|boss_apex_overlord|multi_phase|24|4.0|120|
|zombie_shambler|basic|10|1.35|150|
|zombie_runner|runner|6|0.82|144|
|zombie_brute|tank|25|1.72|300|
|zombie_bomber|explode_on_death|26|1.46|364|
|zombie_screamer|buff_aura|8|1.05|152|
|zombie_spitter|ranged_spit|10|1.12|180|
|zombie_crawler|low_profile|6|0.82|144|
|zombie_armored|armor|28|1.72|336|
|zombie_shielder|shield_aura|19|1.72|228|
|zombie_hopper|leap|8|0.82|192|
|zombie_juggernaut|juggernaut|41|1.72|492|
|zombie_phantom|phase|11|0.82|264|
|zombie_necromancer|summon|9|1.05|171|
|zombie_toxic|toxic_cloud|15|1.12|270|
|zombie_charger|charge|14|0.82|336|
|zombie_regenerator|regen|17|1.35|255|
|zombie_splitter|split|13|1.35|195|
|zombie_warden|ward|26|1.72|312|
|zombie_mutant|mutate|24|1.35|360|
|zombie_berserker|enrage|22|1.35|330|

### Boss满血通关解释

每种子列出接触进度、Boss持续时间、基地受伤/减免，详见JSON的boss_reference_evidence。
未记录损血不能直接解释成Boss没有攻击：现有汇总探针不能区分未到线即被击杀和控场/前摇阻止结算；明确保留此证据缺口，不将100%基地余量当作Boss无威胁的证明。

## 门禁失败与限制

失败项：283；明细见同名JSON。
- T1 is a scaled reference ray, not a search of all builds.
- R fits pool reference families within each chapter; predictions are not new gameplay runs.
- Archived star CSV is historical context, not current runtime proof.
- Resource stage-indexed correlations use T3 actual hypothetical account progress, not a fabricated rank mapping.
- 100%-HP boss results do not prove zero threat: consult contact inventory and raw wave/boss timelines; reach-line and kill-time explanations require full runtime evidence.
