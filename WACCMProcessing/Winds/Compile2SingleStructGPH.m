
All = struct;
All.Data = struct;
All.Data.U = [];
All.Data.V = [];
All.Data.TTGW = [];
All.Data.UTGW_TOTAL = [];
All.Data.Time = [];

% Loading all individual structures into a single one
for i=2004:2017
    disp(i);
    
    load(strcat('C:\Users\pn399\OneDrive - University of Bath\MATLAB\ChihokoModel\Data\',string(i),'_RotheraModelBoxGPH1.mat'));

    U_temp = Model.Data.U;
    V_temp = Model.Data.V;
%     TTGW_temp = Model.Data.TTGW;
%     UTGW_temp = Model.Data.UTGW_TOTAL;
    Time = Model.Data.Time;
    
    All.Data.U = [All.Data.U U_temp];
    All.Data.V = [All.Data.V V_temp];
%     All.Data.TTGW = [All.Data.TTGW TTGW_temp];
%     All.Data.UTGW_TOTAL = [All.Data.UTGW_TOTAL UTGW_temp];
    All.Data.Time = [All.Data.Time Time];
end

%Copying metadata to our new structure
All.Attributes = Model.Attributes;
All.Variables = Model.Variables;
All.Format = Model.Format;
All.Data.Height = p2h(Model.Data.lev);
All.Data.MRHeights = Model.Data.MRHeights;
All.Data.gph_MRHeights = Model.Data.MRHeights;

%% Averaging over each month
%Setting up array of month days
t1 = datetime(1980,01,01);
t2 = datetime(2017,12,31);
monthrange = t1:calmonths(1):t2; % months in selected year
Time = datetime(datenum(All.Data.Time),'ConvertFrom','datenum');
%Time = All.Data.Time;

MonthlyMeanU = zeros(6,length(monthrange)); MonthlyMeanV = zeros(6,length(monthrange));
MonthlyMedU = zeros(6,length(monthrange)); MonthlyMedV = zeros(6,length(monthrange));

for h = 1:30
    
    U = All.Data.U(h,:); V = All.Data.V(h,:); 

    for i = 1:length(monthrange) % for every month in our data
        indx = (monthrange(i) < Time) & (Time < monthrange(i)+calmonths(1));
        
        meanU = mean(U(indx),'omitnan'); meanV = mean(V(indx),'omitnan'); 
        medU = median(U(indx),'omitnan'); medV = median(V(indx),'omitnan');
        
        MonthlyMeanU(h,i) = meanU; MonthlyMeanV(h,i) = meanV;
        MonthlyMedU(h,i) = medU; MonthlyMedV(h,i) = medV;
    end
    disp(h);
end

All.Data.MonthlyMeanU = MonthlyMeanU; All.Data.MonthlyMeanV = MonthlyMeanV;
All.Data.MonthlyMedU = MonthlyMedU; All.Data.MonthlyMedV = MonthlyMedV;
All.Data.MonthlyTime = datenum(monthrange);

%% saving our new structure

save('C:\Users\pn399\OneDrive - University of Bath\MATLAB\ChihokoModel\Processed Data\AllModelRotheraBoxHeight.mat','All')