% Plot of average year UTGW and linear regression results.
clear all;

%% Load data
% UTGW ave year
load('C:\Users\pn399\OneDrive - University of Bath\Paper1\Figure code\WACCMProcessing\UTGW\UTGW_AllYears.mat')
UTGW_ave = UTGW.CompYear;
MRHeights = UTGW.MRHeights;

% Linear regression results
load('C:\Users\pn399\OneDrive - University of Bath\Paper1\Figure code\Figure6and7\LinearRegressionResults.mat');
Results = RegressionResults.WACCM.UTGW;


% Set up figure
gcf = figure();
set(gcf,'color','w','position',[50 50 1200 600]);

%-------------------------------------------------------
vert_gap = 0.19;        horz_gap = 0.11;
lower_marg = 0.1;     upper_marg = 0.2;
left_marg = 0.08;      right_marg = 0.1;

rows = 2; cols = 3;

subplot = @(rows,cols,p) subtightplot (rows,cols,p,[vert_gap horz_gap],[lower_marg upper_marg],[left_marg right_marg]);
sgtitle('ZONAL GRAVITY WAVE TENDENCIES FROM WACCM','fontsize',25);

% Plot first figure as average year UTGW
%% Plot of average year of UTGW
UTGW_ = [UTGW_ave; UTGW_ave; UTGW_ave];

subplot(2,3,1)
 
hold on
contourf(1:36,  MRHeights, UTGW_', -100:1:110, 'LineColor','none'); 
[C1,h1] = contour(1:36,  MRHeights, UTGW_', [-100:20:110], 'LineColor','black', 'ShowText','on');
% [C3,h3] = contour(1:36,  MRHeights, UTGW_' , [0 0], 'LineWidth', 2, 'LineColor','black');
clabel(C1,h1, 'labelspacing', 700);
yline(100, 'LineWidth',1,'Alpha',1);
yline(80, 'LineWidth',1,'Alpha',1);
hold off

cbar = colorbar;
cbar.Ticks = -100:50:100;
cbar.Ruler.MinorTick = 'on';
cbar.Ruler.MinorTickValues = -100:50:100;
cbar.TickDirection = 'out';
set(gca,'color',1*[1 1 1]); 
cbar.Position = cbar.Position + [0.05,0,0,0];

cbar.Label.String = 'ms^{-1} day^{-1}';
cbar.Label.Position = [cbar.Label.Position(1)-0.5,0,0];
    
colormap(cbrew('PRGn',100))
set(gca, 'ydir','normal'); 
clim([-100,100]);
set(gca,'color','k');
set(gca,'TickDir','out','TickLength',[0.005,0.005],'LineWidth',1);
set(gcf,'InvertHardCopy','off');
set(gca, 'fontsize', 15);

%Position xticks at the beginning of each month
xlim([12.5,24.5])
xline(24.5);
xline(12.5);
ylim([80,100]);
yticks([80,90,100]);

title({'(a) Zonal winds','Average year'});
ylabel('HEIGHT (km)');
box off;
gapsize = 4;
xticks(12.5:1:24.5);
set(gca,'xticklabel', {[ blanks(gapsize) 'J'], [ blanks(gapsize) 'F'], [ blanks(gapsize) 'M'],[ blanks(gapsize) 'A'],[ blanks(gapsize) 'M'], [ blanks(gapsize) 'J'],[ blanks(gapsize) 'J'], [ blanks(gapsize) 'A'], [ blanks(gapsize) 'S'], [ blanks(gapsize) 'O'],[ blanks(gapsize) 'N'], [ blanks(gapsize) 'D'], ''});



%% Linear regression results in the rest of the spots
    
for index = 2:6 % for each index
    scaling = Results.scalingList(index-1);
    t_stat = Results.t_stat(3:26,:,index);
    coeffs = Results.coefficients(3:26,:,index);
    walt = Results.walt(3:26);

    coeffs = scaling*[coeffs coeffs coeffs];
    t_stat = [t_stat  t_stat t_stat];

    %% Interpolating results
    months = 1:36;

    interpolated_walt = linspace(walt(1),walt(end),240);
    interpolated_months = 1:0.1:36;

    interpolated_coeffs_temp = nan(length(interpolated_walt), length(months));
    interpolated_coeffs = nan(length(interpolated_walt), length(interpolated_months));

    interpolated_t_temp = nan(length(interpolated_walt), length(months));
    interpolated_t = nan(length(interpolated_walt), length(interpolated_months));

    % Interpolate in y first
    for i = 1:36
        interpolated_coeffs_temp(:,i) = interp1(walt, coeffs(:,i), interpolated_walt);
        interpolated_t_temp(:,i) = interp1(walt, t_stat(:,i), interpolated_walt);
    end

    % now in x
    for j = 1:length(interpolated_walt)
        interpolated_coeffs(j,:) = interp1(months, interpolated_coeffs_temp(j,:), interpolated_months);
        interpolated_t(j,:) = interp1(months, interpolated_t_temp(j,:), interpolated_months);
    end

    ax(index) = subplot(2,3,index);
    axx = gca;
    x = interpolated_months; y = interpolated_walt; Z = interpolated_coeffs; t = interpolated_t;

    hold on
    H1 = pcolor(x,y,Z);
    h = patch(axx.XLim([1 2 2 1]), axx.YLim([1 1 2 2]),'red');
    hh = hatchfill(h, 'single',45,5);
    set(H1, 'EdgeColor', 'none');

    set(hh, 'color', [0 0 0 0.5],'linewi',1);

    nanmask = t<1.7 & t>-1.7;
    Z_nan = Z;
    Z_nan(~nanmask) = NaN;

    H2 = pcolor(x, y, Z_nan);
    set(H2, 'EdgeColor', 'none');


    [C,h ]= contour(x,y,Z,-10:5:10,'k');
    clabel(C,h,[-5,0,5],'labelspacing', 800);
    
    hold off

    gapsize = 4;  
    set(gca,'xticklabel', {[ blanks(gapsize) 'J'], [ blanks(gapsize) 'F'], [ blanks(gapsize) 'M'],[ blanks(gapsize) 'A'],[ blanks(gapsize) 'M'], [ blanks(gapsize) 'J'],[ blanks(gapsize) 'J'], [ blanks(gapsize) 'A'], [ blanks(gapsize) 'S'], [ blanks(gapsize) 'O'],[ blanks(gapsize) 'N'], [ blanks(gapsize) 'D'], ''});

    switch index
        case 2; title({'(b) Regression results','Solar cycle'}); 
        case 3; title({'(c) Regression results','ENSO'});
        case 4; title({'(d) Regression results','QBO10'});ylabel('HEIGHT (km)'); 
        case 5; title({'(e) Regression results','QBO30'});
        case 6; title({'(f) Regression results','SAM'}); 
    end
    c.Label.String = strcat('ms^{-1} day^{-1} per \alpha K');
    
    colormap(ax(index),cbrew('PuOr',100));
    set(gca, 'ydir','normal'); 
    set(gcf,'color','w');
    set(gca,'TickDir','out','TickLength',[0.005,0.005],'LineWidth',1.5);
    set(gca, 'fontsize', 15);
    set(gca, 'xtick',12.5:24.5);
    
    cbar=colorbar;    
    cbar.Ticks = -10:5:10;
    cbar.Ruler.MinorTick = 'on';
    cbar.Ruler.MinorTickValues = -10:5:10;
    cbar.Position = cbar.Position + [0.05,0,0,0];
    cbar.Label.String = strcat('ms^{-1} day^{-1} per \alpha'); 
    cbar.Label.Position = [cbar.Label.Position(1)-0.5,0,0];

    yline(80);
    yline(100);
    xline(12.5);
    xline(24.5);
    clim([-14,14]);
    ylim([80,100]);
    xlim([12.5,24.5]);
    
end %index
