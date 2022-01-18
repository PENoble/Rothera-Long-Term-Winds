% This takes our processed daily GW tendencies and makes monthly mean UTGW

clear all

% Save MonthlyMeans to:
output_dir = 'C:\Users\pn399\OneDrive - University of Bath\MATLAB\ChihokoModel';

UTGW = nan(11,12,30);

for i = 1:11
    yr = 2003+i;
    yr_str = string(yr);
    a = load(strcat('C:\Users\pn399\OneDrive - University of Bath\MATLAB\ChihokoModel\UTGW\extractedGWs',yr_str,'.mat'));
    time = datenum(datetime(yr,01,01):caldays(1):datetime(yr,12,31));
    
    % Monthly averages
    for m = 1:12
        idx = month(time) == m;
        UTGW(i,m,:) = 86400*mean(a.GW(idx,:),1,'omitnan'); % converting to m/s /day
    end % month
    

end % year

UTGW_ave = squeeze(mean(UTGW,1,'omitnan'));

% Import MR heights from text file
opts = delimitedTextImportOptions("NumVariables", 1);
opts.DataLines = [1, Inf];
opts.Delimiter = " ";
opts.VariableNames = "VarName1";
opts.VariableTypes = "double";
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts.ConsecutiveDelimitersRule = "join";
opts.LeadingDelimitersRule = "ignore";
tbl = readtable("C:\Users\pn399\OneDrive - University of Bath\MATLAB\ChihokoModel\MRHeights.txt", opts);
MRHeights = tbl.VarName1;
clear opts tbl

%% Plot of average year of UTGW
UTGW_ = [UTGW_ave; UTGW_ave; UTGW_ave];

figure('position',[50 50 900 500]); 
hold on
contourf(1:36,  MRHeights, UTGW_', -100:10:110, 'LineColor','none'); 
contour(1:36,  MRHeights, UTGW_', -100:10:110, 'Showtext','on', 'LineColor','black'); 
[C1,h1] = contour(1:36,  MRHeights, UTGW_', [0 0], 'LineColor','black');
% [C2,h2] = contour(1:36,  MRHeights, UTGW_' ,'LineStyle','--', 'LineColor','black');
% [C3,h3] = contour(1:36,  MRHeights, UTGW_' ,'LineWidth', 2, 'LineColor','black');
yline(100, 'LineWidth',1,'Alpha',1);
yline(80, 'LineWidth',1,'Alpha',1);
hold off

cbar = colorbar;
cbar.Ticks = -100:20:100;
cbar.Ruler.MinorTick = 'on';
cbar.Ruler.MinorTickValues = -100:10:100;
cbar.TickDirection = 'out';
set(gca,'color',1*[1 1 1]); 
cbar.Label.FontSize = 15;
cbar.Label.String = 'UTGW (m/s /day)';

colormap(cbrew('RdBu',100))
set(gca, 'ydir','normal'); 
clim([-100,100]);
set(gca,'color','k');
set(gca,'TickDir','out','TickLength',[0.005,0.005],'LineWidth',1);
set(gcf,'InvertHardCopy','off');
set(gca, 'fontsize', 20);

%Position xticks at the beginning of each month
xlim([12.5,24.5])
xlabel('AVERAGE YEAR','fontsize',15);
xline(24.5);
xline(12.5);
ylim([80,100]);
yticks([80,90,100]);

title(strcat('GRAVITY WAVE TENDENCIES AVERAGE YEAR'));
xlabel('MONTH');
ylabel('HEIGHT (km)');
box off;
gapsize = 4;
xticks(12.5:1:24.5);
set(gca,'xticklabel', {[ blanks(gapsize) 'J'], [ blanks(gapsize) 'F'], [ blanks(gapsize) 'M'],[ blanks(gapsize) 'A'],[ blanks(gapsize) 'M'], [ blanks(gapsize) 'J'],[ blanks(gapsize) 'J'], [ blanks(gapsize) 'A'], [ blanks(gapsize) 'S'], [ blanks(gapsize) 'O'],[ blanks(gapsize) 'N'], [ blanks(gapsize) 'D'], ''});


%% Strip plots of all years
UTGW_ALL = nan(132,30);

for h = 1:30
    UTGW_ALL(:,h) = reshape(squeeze(UTGW(:,:,h))',[132 1]);
end

time = datenum(datetime(2005,01,15):calmonths(1):datetime(2015,12,15));

figure('position',[50 50 1700 200]); 
set(gcf,'color','w')

hold on
contourf(time,  MRHeights, UTGW_ALL', -100:20:110, 'LineColor','none'); 
contour(time,  MRHeights, UTGW_ALL', -100:20:110, 'Showtext','on', 'LineColor','black'); 
contour(time,  MRHeights, UTGW_ALL', [0 0],'LineWidth', 2, 'LineColor','black');
yline(100, 'LineWidth',1,'Alpha',1);
yline(80, 'LineWidth',1,'Alpha',1);
xline(datenum(2005,01,01), 'LineWidth',1,'Alpha',1);
xline(datenum(2015,12,31), 'LineWidth',1,'Alpha',1);
hold off

colormap(cbrew('RdBu',100))
set(gca, 'ydir','normal'); 
clim([-100,100]);
set(gca,'color','k');
set(gca,'TickDir','out','TickLength',[0.005,0.005],'LineWidth',1);
set(gcf,'InvertHardCopy','off');
set(gca, 'fontsize', 20);

%Position xticks at the beginning of each month
times = datenum(datetime(2005,01,01):calyears(1):datetime(datetime(2015,12,31)));
xticks(times);
% Offset the label to appear in the gap
datetick('x','               yyyy','keepticks');

ylim([80,100]);
xlim([datenum(2005, 01,01),datenum(2015, 12,31)]);
ylabel('HEIGHT (km)', 'fontsize',20);
% title(strcat(string(label),{' '}, 'WIND WACCM'),'fontsize',20);

UTGW = struct;
UTGW.AllYears = UTGW_ALL;
UTGW.CompYear = UTGW_ave;
UTGW.MRHeights = MRHeights;
save(strcat(output_dir,'\UTGW_AllYears.mat'),'UTGW');

