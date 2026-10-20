function varargout = BDCH_AEACO(PlotEnabled)
if nargin < 1
    PlotEnabled = true;
end
validateattributes(PlotEnabled,{'logical','numeric'},{'scalar','real','finite'});
PlotEnabled = logical(PlotEnabled);
G = [
0 0 0 0 0 0 1 1 0 0 0 0 0 1 0 0 0 0 0 1;
0 0 0 0 0 0 0 0 0 0 1 1 0 1 1 0 1 1 1 1;
0 0 1 0 1 1 0 0 1 1 1 1 0 1 1 0 0 0 0 1;
1 0 0 0 1 1 0 0 1 1 1 1 0 0 0 0 0 0 0 0;
1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1;
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 1;
0 0 0 1 1 1 0 1 0 0 0 0 0 1 0 1 1 1 0 0;
0 0 0 1 1 1 0 0 1 1 0 0 1 1 0 1 1 1 0 0;
0 0 0 1 1 1 0 0 1 1 1 1 1 1 1 1 1 1 0 0;
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0;
0 0 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0;
0 0 1 0 0 1 1 1 0 0 0 1 1 1 0 0 1 1 1 0;
0 1 1 0 0 1 1 1 0 0 0 1 1 0 0 0 1 1 1 0;
0 1 1 0 0 1 1 0 0 1 1 1 0 0 0 0 1 1 1 0;
0 0 0 0 0 1 1 0 1 1 0 0 0 0 0 0 0 0 0 0;
0 0 0 0 0 1 0 0 1 1 0 0 0 1 1 1 0 0 0 0;
0 1 1 1 1 1 0 0 1 0 0 0 0 1 1 1 0 0 0 0;
0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0;
];
K = 100;
M = 50;
S = 1;
E = numel(G);
MM = size(G,1);
if size(G,2) ~= MM || any(G(:) ~= 0 & G(:) ~= 1)
    error('G必须为方形0/1栅格矩阵。');
end
if G(1,1) ~= 0 || G(end,end) ~= 0
    error('起点或终点位于障碍物内。');
end
tol = 1e-10;
timerHandle = tic;
[PL, ROUTES] = runOneBDCHAEACO(G,K,M,S,E);
RunTime = toc(timerHandle);
metrics = calculateRunMetrics(PL,ROUTES,tol,K,M,MM,'rowmajor','minturncount');
Result = metrics;
Result.algorithm = 'BDCH_AEACO';
Result.PL = PL;
Result.ROUTES = ROUTES;
Result.G = G;
Result.S = S;
Result.E = E;
Result.K = K;
Result.M = M;
Result.runtime = RunTime;
Result.plannerSuccess = any(isfinite(PL(:)) & PL(:)>0);
Result.generationBest = inf(K,1);
for k = 1:K
    values = PL(k,:);
    values = values(isfinite(values) & values>0);
    if ~isempty(values)
        Result.generationBest(k) = min(values);
    end
end
if PlotEnabled
    figure('Color','w','Name','BDCH_AEACO best-so-far');
    curve = Result.bestHistory;
    curve(~isfinite(curve)) = NaN;
    plot(1:K,curve,'LineWidth',1.5);
    xlabel('Iteration');
    ylabel('Best-so-far path length');
    xlim([1 K]);
    set(gca,'FontName','Times New Roman','FontSize',16);
    figure('Color','w','Name','BDCH_AEACO path');
    imagesc([0.5 MM-0.5],[0.5 MM-0.5],flipud(G));
    colormap([1 1 1;0 0 0]);
    caxis([0 1]);
    set(gca,'YDir','normal');
    hold on;
    for q=0:MM
        plot([q q],[0 MM],'Color',[0.75 0.75 0.75]);
        plot([0 MM],[q q],'Color',[0.75 0.75 0.75]);
    end
    if ~isempty(Result.bestPath)
        [row,col]=pathNodeCoordinates(Result.bestPath,MM,'rowmajor');
        plot(col-0.5,MM-row+0.5,'r-','LineWidth',2);
    end
    plot(0.5,MM-0.5,'go','MarkerFaceColor','g');
    plot(MM-0.5,0.5,'bo','MarkerFaceColor','b');
    axis equal;
    axis([0 MM 0 MM]);
    xlabel('\itx');ylabel('\ity');
    set(gca,'FontName','Times New Roman','FontSize',16);
end
if nargout > 0
    varargout{1} = Result;
end
end

function metrics = calculateRunMetrics(PL, ROUTES, tol, K, M, MM, indexMode, bestPathTieMode)

successMask = isfinite(PL) & PL > 0;
successCount = nnz(successMask);

metrics = struct();
metrics.bestLength = NaN;
metrics.meanSuccessLength = NaN;
metrics.convergenceIteration = NaN;
metrics.successPathRatio = 0;
metrics.cumulativeTurnAngle = NaN;
metrics.bestPath = [];
metrics.bestHistory = inf(K,1);

metrics.successPathRatio = 100 * successCount / (K * M);

if successCount == 0
    return;
end

successfulLengths = PL(successMask);
metrics.bestLength = min(successfulLengths);
metrics.meanSuccessLength = mean(successfulLengths);

generationBest = inf(K,1);
for k = 1:K
    values = PL(k,:);
    values = values(isfinite(values) & values > 0);
    if ~isempty(values)
        generationBest(k) = min(values);
    end

    if k == 1
        metrics.bestHistory(k) = generationBest(k);
    else
        metrics.bestHistory(k) = min(metrics.bestHistory(k-1), generationBest(k));
    end
end

bestHistory = cummin(generationBest);
metrics.bestHistory = bestHistory;
finalBest = bestHistory(end);
metrics.convergenceIteration = NaN;
if isfinite(finalBest)
    metrics.convergenceIteration = find( ...
        isfinite(bestHistory) & ...
        abs(bestHistory - finalBest) <= tol, ...
        1, 'first');
end

bestMask = successMask & abs(PL - metrics.bestLength) <= tol;
[bestRows, bestCols] = find(bestMask);
if isempty(bestRows)
    return;
end

chronologicalOrder = (bestRows - 1) * M + bestCols;
[~, order] = sort(chronologicalOrder, 'ascend');
bestRows = bestRows(order);
bestCols = bestCols(order);

switch lower(bestPathTieMode)
    case 'first'
        metrics.bestPath = ROUTES{bestRows(1), bestCols(1)};

    case 'minturncount'
        minTurns = inf;
        selectedPath = [];
        for q = 1:numel(bestRows)
            candidatePath = ROUTES{bestRows(q), bestCols(q)};
            if isempty(candidatePath)
                continue;
            end
            turns = pathTurnCount(candidatePath, MM, indexMode);
            if turns < minTurns
                minTurns = turns;
                selectedPath = candidatePath;
            end
        end
        metrics.bestPath = selectedPath;

    otherwise
        error('未知的最优路径并列处理方式：%s', bestPathTieMode);
end

if ~isempty(metrics.bestPath)
    metrics.cumulativeTurnAngle = cumulativeTurnAngle( ...
        metrics.bestPath, MM, indexMode);
end
end

function nTurns = pathTurnCount(path, MM, indexMode)
if numel(path) < 3
    nTurns = 0;
    return;
end
[row, col] = pathNodeCoordinates(path, MM, indexMode);
v = diff([double(col), double(row)], 1, 1);
nTurns = sum(any(abs(v(2:end,:) - v(1:end-1,:)) > 1e-12, 2));
end

function angleSum = cumulativeTurnAngle(path, MM, indexMode)
if numel(path) < 3
    angleSum = 0;
    return;
end

[row, col] = pathNodeCoordinates(path, MM, indexMode);
xy = [double(col), double(row)];
v = diff(xy, 1, 1);
angleSum = 0;
for i = 1:(size(v,1)-1)
    n1 = hypot(v(i,1), v(i,2));
    n2 = hypot(v(i+1,1), v(i+1,2));
    if n1 <= eps || n2 <= eps
        continue;
    end
    c = dot(v(i,:), v(i+1,:)) / (n1*n2);
    c = min(max(c,-1),1);
    angleSum = angleSum + acosd(c);
end
end

function [row, col] = pathNodeCoordinates(path, MM, indexMode)
switch lower(indexMode)
    case 'rowmajor'
        row = ceil(path(:) / MM);
        col = mod(path(:) - 1, MM) + 1;
    case 'columnmajor'
        [row, col] = ind2sub([MM, MM], path(:));
    otherwise
        error('未知节点编号方式：%s', indexMode);
end
end

function [mu, sigma] = finiteMeanStd(x)
x = x(isfinite(x));
if isempty(x)
    mu = NaN;
    sigma = NaN;
elseif numel(x) == 1
    mu = x;
    sigma = 0;
else
    mu = mean(x);
    sigma = std(x,0);
end
end

function D = G2D_compare(G)
l = size(G,1);
N = l*l;
D = zeros(N,N);

dir = [
    -1  0;
     1  0;
     0 -1;
     0  1;
    -1 -1;
    -1  1;
     1 -1;
     1  1
];

for i = 1:l
    for j = 1:l

        if G(i,j) == 1
            continue;
        end

        current = (i-1)*l + j;

        for d = 1:size(dir,1)

            m = i + dir(d,1);
            n = j + dir(d,2);

            if m < 1 || m > l || n < 1 || n > l
                continue;
            end

            if G(m,n) == 1
                continue;
            end

            next = (m-1)*l + n;

            if dir(d,1) == 0 || dir(d,2) == 0

                D(current,next) = 1;

            else

                side1 = G(i,n);
                side2 = G(m,j);

                if side1 == 1 && side2 == 1
                    continue;
                else
                    D(current,next) = sqrt(2);
                end
            end

        end
    end
end
end

function [PL, ROUTES] = runOneBDCHAEACO(G, K, M, S, E)
MM = size(G,1);
N = MM*MM;

Alpha = 2;
Beta = 9;
Q = 10;

rho_min = 0.10;
rho_max = 0.40;
kappa = 6;
lambda_e = 2.5;

Tau0 = 8;
Gamma = 0.75;
epsilon = 1e-12;

omega1 = 0.1;
omega2 = 0.8;
omega3 = 0.1;

D = G2D_compare(G);
a = 1;
Ex = a*(mod(E-1,MM)+0.5);
Ey = a*(MM+0.5-ceil(E/MM));
Sx = a*(mod(S-1,MM)+0.5);
Sy = a*(MM+0.5-ceil(S/MM));

NodeX = zeros(1,N);
NodeY = zeros(1,N);
FreeNode = false(1,N);
DistanceSum = inf(1,N);
DistanceToGoal = inf(1,N);

for i = 1:N
    row = ceil(i/MM);
    col = mod(i-1,MM)+1;
    NodeX(i) = a*(mod(i-1,MM)+0.5);
    NodeY(i) = a*(MM+0.5-ceil(i/MM));

    if G(row,col) == 0
        FreeNode(i) = true;
        dS = hypot(NodeX(i)-Sx, NodeY(i)-Sy);
        dE = hypot(NodeX(i)-Ex, NodeY(i)-Ey);
        DistanceSum(i) = dS+dE;
        DistanceToGoal(i) = dE;
    end
end

Dmin = min(DistanceSum(FreeNode));
Dmax = max(DistanceSum(FreeNode));
GuideFactor = zeros(1,N);
GuideFactor(FreeNode) = ...
    (Dmax-DistanceSum(FreeNode)) ./ (Dmax-Dmin+epsilon);

NodeTau = zeros(1,N);
NodeTau(FreeNode) = Tau0 .* (1 + Gamma.*GuideFactor(FreeNode));

Tau = zeros(N,N);
for i = 1:N
    neighbors = find(D(i,:) > 0);
    for j = neighbors
        Tau(i,j) = (NodeTau(i)+NodeTau(j))/2;
    end
end

dEmin = min(DistanceToGoal(FreeNode));
dEmax = max(DistanceToGoal(FreeNode));
GoalFactor = zeros(1,N);
GoalFactor(FreeNode) = ...
    (dEmax-DistanceToGoal(FreeNode)) ./ (dEmax-dEmin+epsilon);

ROUTES = cell(K,M);
PL = zeros(K,M);

for k = 1:K
    for m = 1:M
        W = S;
        Path = S;
        PLkm = 0;
        TABUkm = ones(1,N);
        TABUkm(S) = 0;
        DD = D;

        DW = DD(W,:);
        DW1 = find(DW);
        for j = 1:length(DW1)
            if TABUkm(DW1(j)) == 0
                DW(DW1(j)) = 0;
            end
        end
        LJD = find(DW);
        Len_LJD = length(LJD);

        while W ~= E && Len_LJD >= 1
            PP = zeros(1,Len_LJD);

            for i = 1:Len_LJD
                Jnext = LJD(i);

                Gj = GoalFactor(Jnext);
                diE = DistanceToGoal(W);
                djE = DistanceToGoal(Jnext);

                dij = hypot(NodeX(Jnext)-NodeX(W), ...
                            NodeY(Jnext)-NodeY(W));

                Rij = 0.5*(1+(diE-djE)/dij);
                Rij = min(max(Rij,0),1);

                if numel(Path) == 1
                    Chij = 1;
                else
                    H = Path(end-1);
                    vhi_x = NodeX(W)-NodeX(H);
                    vhi_y = NodeY(W)-NodeY(H);
                    vij_x = NodeX(Jnext)-NodeX(W);
                    vij_y = NodeY(Jnext)-NodeY(W);
                    dhi = hypot(vhi_x,vhi_y);
                    cosPhi = (vhi_x*vij_x + vhi_y*vij_y)/(dhi*dij);
                    cosPhi = min(max(cosPhi,-1),1);
                    Chij = (1+cosPhi)/2;
                end

                Eta_ij = epsilon + omega1*Gj + omega2*Rij + omega3*Chij;
                PP(i) = (Tau(W,Jnext)^Alpha) * (Eta_ij^Beta);
            end

            sumpp = sum(PP);
            if ~isfinite(sumpp) || sumpp <= 0
                PP = ones(1,Len_LJD)/Len_LJD;
            else
                PP = PP/sumpp;
            end

            Pcum = cumsum(PP);
            Select = find(Pcum >= rand,1,'first');
            if isempty(Select)
                Select = Len_LJD;
            end
            to_visit = LJD(Select);

            Path = [Path,to_visit];
            PLkm = PLkm + DD(W,to_visit);
            W = to_visit;

            for J = 1:N
                if TABUkm(J) == 0
                    DD(W,J) = 0;
                    DD(J,W) = 0;
                end
            end
            TABUkm(W) = 0;

            DW = DD(W,:);
            DW1 = find(DW);
            for j = 1:length(DW1)
                if TABUkm(DW1(j)) == 0
                    DW(DW1(j)) = 0;
                end
            end
            LJD = find(DW);
            Len_LJD = length(LJD);
        end

        ROUTES{k,m} = Path;
        if ~isempty(Path) && Path(end) == E
            PL(k,m) = PLkm;
        else
            PL(k,m) = 0;
        end
    end

    SuccessAnts = find(PL(k,:) > 0);

    Delta_Tau_base = zeros(N,N);
    for idx = 1:numel(SuccessAnts)
        m_success = SuccessAnts(idx);
        ROUT = ROUTES{k,m_success};
        PL_km = PL(k,m_success);

        for s = 1:(length(ROUT)-1)
            x = ROUT(s);
            y = ROUT(s+1);
            Delta_Tau_base(x,y) = Delta_Tau_base(x,y) + Q/PL_km;
            Delta_Tau_base(y,x) = Delta_Tau_base(y,x) + Q/PL_km;
        end
    end

    Delta_Tau_elite = zeros(N,N);
    if ~isempty(SuccessAnts)
        [L_best_iter,localPos] = min(PL(k,SuccessAnts));
        m_best_iter = SuccessAnts(localPos);
        ROUT_best = ROUTES{k,m_best_iter};
        eliteIncrement = lambda_e*Q/L_best_iter;

        for s = 1:(length(ROUT_best)-1)
            x = ROUT_best(s);
            y = ROUT_best(s+1);
            Delta_Tau_elite(x,y) = Delta_Tau_elite(x,y) + eliteIncrement;
            Delta_Tau_elite(y,x) = Delta_Tau_elite(y,x) + eliteIncrement;
        end
    end

    Rho_k = rho_min + (rho_max-rho_min) / ...
        (1 + exp(-kappa*(k/K-0.5)));

    Tau = (1-Rho_k).*Tau + Delta_Tau_base + Delta_Tau_elite;
end
end
