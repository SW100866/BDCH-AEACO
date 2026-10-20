clear
clc
demoFolder = fileparts(mfilename('fullpath'));
addpath(demoFolder);
Run = 1;
Seed = 20260715 + Run;
PlotEnabled = true;
rng(Seed, 'twister');
Result = BDCH_AEACO(PlotEnabled);
Result.run = Run;
Result.seed = Seed;
