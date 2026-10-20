BDCH-AEACO Supplementary Material Guide

This package contains Code, Maps and Results.

Single-run code

Code/BDCH_AEACO.m performs one experiment using the embedded map G. Required helper functions are included in the same file.

In MATLAB, open the Code folder and run run_single_demo. Defaults are Run=1, Seed=20260716, 100 iterations and 50 ants per iteration. Set PlotEnabled=false to disable figures.

Alternatively, execute: rng(20260716,'twister'); Result=BDCH_AEACO(true); Per-run metrics are returned in Result. The manuscript experiments used MATLAB R2021b.

Maps

Maps contains 15 distinct maps. In G, 0 denotes free space and 1 denotes an obstacle. startRC and goalRC are one-based [row,column] indices; cellSize is the cell side length. Each map function returns these variables directly.

map_ablation corresponds to Tables 5--6; map_env01--03 to Tables 7--9; map_env04--12 to Tables 10--12, with two endpoint pairs per map. Table 13 uses pair 1 of map_env07 plus map_env07_50x50 and map_env07_100x100, with cell sizes 1, 0.6 and 0.3.

To read endpoint pair 2 of Environment 7, open Maps and execute:
  [G,startPairs,goalPairs,cellSize]=map_env07();
  startRC=startPairs(2,:);
  goalRC=goalPairs(2,:);

The single-run code uses comparative Environment 1 (20-by-20) by default. To change maps, update G and the endpoints together. Internal node indices are (row-1)*N+column. Row 1 is the top row; cell-center coordinates are x=(column-0.5)*cellSize and y=(N-row+0.5)*cellSize. Scale higher-resolution path lengths by cellSize.

Per-run results

Results are organized by manuscript table, environment, endpoint pair and algorithm. Each CSV row represents one independent run: 30 runs per condition for Tables 5--12 and 10 for Table 13. ACO1, ACO2 and ACO3 in Table 6 reuse the corresponding Table 5 records.

Column definitions:
  Run: Run index
  Seed: Integer random seed
  BestPathLength: Final best-path length
  AllIterMeanSuccessPathLength: Mean successful-ant path length over all iterations
  ConvergenceIteration: First iteration attaining the final best-path length
  AllIterSuccessPathRatioPercent: Successful-ant ratio over all iterations (%)
  CumulativeTurnAngleDeg: Cumulative turning angle (degrees)
  RunTimeSec: Runtime (seconds)
  PlannerSuccess: 1 for a successful planning run, otherwise 0

Tables 10--13 include the metrics reported in those tables. Failed runs are retained with blank path length and turning angle, while runtime is retained. CSV files preserve source precision; means and sample standard deviations can be calculated from the per-run values.

In Table 13, A* and TP-A* are deterministic and Seed is blank; BDCH-AEACO seeds follow 20260715+Run in the matching scripts. A* seeds in Tables 10--12 identify experimental run blocks. Open CSV files in Excel or MATLAB; widen Seed or use integer formatting if scientific notation is displayed.
