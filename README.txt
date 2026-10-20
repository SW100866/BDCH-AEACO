BDCH-AEACO 补充材料说明 / Supplementary Material Guide

本包包含Code代码、Maps地图及Results逐次结果。
This package contains Code, Maps and Results.

一、单次运行代码 / Single-run code

Code/BDCH_AEACO.m执行一次实验，地图已内置为G，所需辅助函数已包含在同一文件中。
Code/BDCH_AEACO.m performs one experiment using the embedded map G. Required helper functions are included in the same file.

在MATLAB中进入Code文件夹，运行run_single_demo。默认Run=1、Seed=20260716，执行100次迭代，每代50只蚂蚁。PlotEnabled=false可关闭绘图。
In MATLAB, open the Code folder and run run_single_demo. Defaults are Run=1, Seed=20260716, 100 iterations and 50 ants per iteration. Set PlotEnabled=false to disable figures.

也可直接执行：rng(20260716,'twister'); Result=BDCH_AEACO(true); 单次指标保存在Result中。论文实验使用MATLAB R2021b。
Alternatively, execute: rng(20260716,'twister'); Result=BDCH_AEACO(true); Per-run metrics are returned in Result. The manuscript experiments used MATLAB R2021b.

二、地图 / Maps

Maps包含15张不同地图。G中0为可通行、1为障碍；startRC和goalRC是从1开始的[行,列]坐标，cellSize为栅格边长。每份地图函数直接返回这些变量。
Maps contains 15 distinct maps. In G, 0 denotes free space and 1 denotes an obstacle. startRC and goalRC are one-based [row,column] indices; cellSize is the cell side length. Each map function returns these variables directly.

map_ablation对应表5—6；map_env01—03对应表7—9；map_env04—12对应表10—12，每张有两组起终点。表13使用map_env07第一组，以及map_env07_50x50和map_env07_100x100，栅格边长分别为1、0.6、0.3。
map_ablation corresponds to Tables 5--6; map_env01--03 to Tables 7--9; map_env04--12 to Tables 10--12, with two endpoint pairs per map. Table 13 uses pair 1 of map_env07 plus map_env07_50x50 and map_env07_100x100, with cell sizes 1, 0.6 and 0.3.

读取环境7第2组端点：先进入Maps文件夹，执行以下三行。
To read endpoint pair 2 of Environment 7, open Maps and execute:
  [G,startPairs,goalPairs,cellSize]=map_env07();
  startRC=startPairs(2,:);
  goalRC=goalPairs(2,:);

单次代码默认使用对比环境1地图（20×20）；如更换地图，需要同步调整代码中的G和起终点。其内部节点编号为(row-1)*N+column。第1行为地图顶部，栅格中心物理坐标为x=(column-0.5)*cellSize，y=(N-row+0.5)*cellSize；高分辨率路径长度须按cellSize换算。
The single-run code uses comparative Environment 1 (20-by-20) by default. To change maps, update G and the endpoints together. Internal node indices are (row-1)*N+column. Row 1 is the top row; cell-center coordinates are x=(column-0.5)*cellSize and y=(N-row+0.5)*cellSize. Scale higher-resolution path lengths by cellSize.

三、逐次运行结果 / Per-run results

结果按论文表号、环境、起终点组和算法分类。每个CSV中，每行对应一次独立运行。表5—12每份30次，表13每份10次。表6中的ACO1、ACO2和ACO3沿用表5相同记录。
Results are organized by manuscript table, environment, endpoint pair and algorithm. Each CSV row represents one independent run: 30 runs per condition for Tables 5--12 and 10 for Table 13. ACO1, ACO2 and ACO3 in Table 6 reuse the corresponding Table 5 records.

字段说明 / Column definitions:
  Run：运行编号 / Run index
  Seed：完整随机种子 / Integer random seed
  BestPathLength：本次最优路径长度 / Final best-path length
  AllIterMeanSuccessPathLength：本次全迭代成功路径平均长度 / Mean successful-ant path length over all iterations
  ConvergenceIteration：首次达到本次最终最优长度的迭代数 / First iteration attaining the final best-path length
  AllIterSuccessPathRatioPercent：本次全迭代成功蚂蚁比例（%） / Successful-ant ratio over all iterations (%)
  CumulativeTurnAngleDeg：累计转角（度） / Cumulative turning angle (degrees)
  RunTimeSec：运行时间（秒） / Runtime (seconds)
  PlannerSuccess：单次成功为1，失败为0 / 1 for a successful planning run, otherwise 0

表10—13仅保留对应表格报告的指标。失败运行保留，路径长度和转角留空，运行时间保留。CSV保留原始精度；均值和样本标准差可由逐次结果计算。
Tables 10--13 include the metrics reported in those tables. Failed runs are retained with blank path length and turning angle, while runtime is retained. CSV files preserve source precision; means and sample standard deviations can be calculated from the per-run values.

表13的A*和TP-A*为确定性算法，Seed留空；BDCH-AEACO的Seed按对应程序的20260715+Run填写。表10—12中A*的Seed用于标识实验运行组。CSV可用Excel或MATLAB打开；如Seed显示为科学计数法，可加宽列或设为整数格式。
In Table 13, A* and TP-A* are deterministic and Seed is blank; BDCH-AEACO seeds follow 20260715+Run in the matching scripts. A* seeds in Tables 10--12 identify experimental run blocks. Open CSV files in Excel or MATLAB; widen Seed or use integer formatting if scientific notation is displayed.
