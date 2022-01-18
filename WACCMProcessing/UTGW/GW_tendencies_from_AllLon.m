%% This code reads in Chihoko's all longitude files 
% Saves extracted GWs in year structures 366*30 (day by height)

GWTendencies = struct;
in_direc = [LocalDataDir, '/phoebe/SD-WACCM_alllons/'];
out_direc = [LocalDataDir,'/phoebe/'];

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
tbl = readtable([LocalDataDir, '/phoebe/MRHeights.txt'], opts);
MRHeights = tbl.VarName1;
clear opts tbl

disp('Up to date version');

for yr = 2015:2015
    t1 = datetime(yr,01,01);
    t2 = datetime(yr,12,31);
    
    Time = datetime(t1:caldays(1):t2);

    GW = nan(length(Time),30);

    for i = 1:length(Time)
        daterange = datestr(Time(i),'yyyy-mm-dd');
        % All Lons SD WACCM - load one day.
        disp(daterange);

        %We are interested in UTGW
        %UTGW - Total U tendency due to GW drag
        try    
          a = nph_getnet(strcat(in_direc,'sdwaccm_sh_',daterange,'.nc'));
        catch err
            disp(['Can''t load ' daterange])
            continue
        end
        
        % There are some days without 8 entries
        if length(a.Data.time)~= 8
            NumMissing = 8-length(a.Data.time);
            
            U = cat(4, a.Data.UTGW_TOTAL, nan(144,28,145,NumMissing));
            Z3 = cat(4, a.Data.Z3/1000, nan(144,28,145,NumMissing));
        else
            U = a.Data.UTGW_TOTAL;
            Z3 = a.Data.Z3/1000;
        end
        
        % UTGW is [144,28,145,8] - lon, lat, lev, time
        % First we want to interpolate onto MR grid.
        UTGW_interp = nan(144,28,length(MRHeights),8);
        for lon = 1:144
            for lat = 1:28
                for time = 1:8
                    U_now = squeeze(U(lon,lat,:,time)); 
                    gph = squeeze(Z3(lon, lat, :, time));
                    try
                    UTGW_interp(lon, lat, :, time) = interp1(gph, U_now, MRHeights);
                    catch
                        continue
                    end
                end % time
            end % lat
        end % lon

        
        % mean over lon? first dimension

        UTGW = squeeze(mean(UTGW_interp,1,'omitnan'));

        % Lat = -67.2 is the closest? i = 10, include i=9,10,11.
        UTGW = (UTGW(9:11,:,:));
        UTGW = squeeze(mean(UTGW,1,'omitnan'));

        % Finally mean over time to get m/s /s daily average 
        UTGW = squeeze(mean(UTGW,2,'omitnan'));

        GW(i,:) = UTGW;
    end % days

    save(strcat(out_direc, '/extractedGWs',string(yr),'.mat'),'GW');  
end % yr