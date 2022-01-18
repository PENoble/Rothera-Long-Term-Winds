%% This script takes in individual years of MR processed winds
% calculates composite year and stitches together the monthly averages
% in order to use later in the regression.

Allyears = struct;

%% Need to load up yearly structures and link into a giant one first!
MonthlyMeanU = [];
MonthlyMeanV = [];
MonthlyMedU = [];
MonthlyMedV = [];

walt = [];

for i = 1:17 % for each year
    yr = 2004+i;

	load(strcat('C:\Users\pn399\OneDrive - University of Bath\MATLAB\MeteorRadar\rothera-sk\matlab\hwd\',string(yr),'_rothera-sk.mat'));
    disp(yr);
    
    MonthlyMeanU = [MonthlyMeanU HWD.Data.Monthly.MeanU];
    MonthlyMeanV = [MonthlyMeanV HWD.Data.Monthly.MeanV];
    MonthlyMedU = [MonthlyMedU HWD.Data.Monthly.MedianU];
    MonthlyMedV = [MonthlyMedV HWD.Data.Monthly.MedianV];
    
    walt = [walt HWD.Data.Monthly.walt];
end % year



%% We remove dodgy data 
% Dec 2009, Jan 2010, Dec 2010, 
% Feb 2016 - Oct 2018

% Dec 2009 & Jan 2010
MonthlyMeanU(:,12*5:12*5+1) = nan;
MonthlyMeanV(:,12*5:12*5+1) = nan;
MonthlyMedU(:,12*5:12*5+1) = nan;
MonthlyMedV(:,12*5:12*5+1) = nan;

% Dec 2010
MonthlyMeanU(:,12*6) = nan;
MonthlyMeanV(:,12*6) = nan;
MonthlyMedU(:,12*6) = nan;
MonthlyMedV(:,12*6) = nan;

%Jan 2016 - Dec 2018 (inclusive)
MonthlyMeanU(:,12*11+1:12*14) = nan;
MonthlyMeanV(:,12*11+1:12*14) = nan;
MonthlyMedU(:,12*11+1:12*14) = nan;
MonthlyMedV(:,12*11+1:12*14) = nan;

% May 2021 as this year hasn't finished
MonthlyMeanU(:,end-7) = nan;
MonthlyMeanV(:,end-7) = nan;
MonthlyMedU(:,end-7) = nan;
MonthlyMedV(:,end-7) = nan;


%%
AllYears.MonthlyMeanU = MonthlyMeanU;
AllYears.MonthlyMeanV = MonthlyMeanV;
AllYears.MonthlyMedU = MonthlyMedU;
AllYears.MonthlyMedV = MonthlyMedV;
AllYears.MonthlyTime = datenum(datetime(2005,01,01):calmonths(1):datetime(2021,12,01));
AllYears.MonthlyWalt = walt;

% Reshaping:
CompositeYearU = mean(reshape(MonthlyMedU,[30,12,17]),3,'omitnan');
CompositeYearV = mean(reshape(MonthlyMedV,[30,12,17]),3,'omitnan');
CompositeYearWalt = mean(reshape(walt,[30,12,17]),3,'omitnan');

AllYears.CompositeYear.U = CompositeYearU;
AllYears.CompositeYear.V = CompositeYearV;
AllYears.CompositeYear.walt = CompositeYearWalt;

save('C:\Users\pn399\OneDrive - University of Bath\MATLAB\MeteorRadar\rothera-sk\matlab\hwd\AllYears.mat','AllYears');
