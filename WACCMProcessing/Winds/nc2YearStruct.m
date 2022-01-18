% This code takes the individual nc day files and stores in a matlab
% structure for each day


modeldirec = 'C:\Users\pn399\OneDrive - University of Bath\Paper1\Figure Code\WACCMProcessing\Data\';

%Initialising struct
Model = struct;
Model.Data = struct;
Model.Attributes = struct;
Model.Variables = struct;
Model.Format = char;

%% Import MR heights from text file
opts = delimitedTextImportOptions("NumVariables", 1);
opts.DataLines = [1, Inf];
opts.Delimiter = " ";
opts.VariableNames = "VarName1";
opts.VariableTypes = "double";
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts.ConsecutiveDelimitersRule = "join";
opts.LeadingDelimitersRule = "ignore";
tbl = readtable("C:\Users\pn399\OneDrive - University of Bath\Paper1\Figure Code\WACCMProcessing\MRHeights.txt", opts);
MRHeights = tbl.VarName1;
clear opts tbl

for yr = 1986:2017
    Model.Data.Year = yr;

    dayrange = datenum(yr,01,01):datenum(yr,12,31);
    U_overall = []; V_overall = [];
    
    for i = 1:length(dayrange) % For every day/file
        yyyymmdd = datestr(dayrange(i), 'yyyy-mm-dd');
        yy = datestr(dayrange(i), 'yyyy');
        
        disp(yyyymmdd);
        
        A = nph_getnet([modeldirec yy '\sdwaccm_rothera_' yyyymmdd '.nc']);
        
        %Filling the days with missing data with NaNs
        if length(A.Data.time)~= 8
            NumMissing = 8-length(A.Data.time);
            
            U = cat(4, A.Data.U, nan(10,12,145,NumMissing));
            V = cat(4, A.Data.V, nan(10,12,145,NumMissing));
            gph = cat(4, A.Data.Z3/1000, nan(10,12,145,NumMissing));
        else
            U = A.Data.U;
            V = A.Data.V;
            Z3 = A.Data.Z3/1000;
        end
        
        U_interp = nan(10,12,30,8); V_interp = nan(10,12,30,8);
        for lon = 1:10
            for lat = 1:12
                for time = 1:8
                    U_now = squeeze(U(lon,lat,:,time)); 
                    V_now = squeeze(V(lon,lat,:,time));
                    gph = squeeze(Z3(lon, lat, :, time));
                    try
                    U_interp(lon, lat, :, time) = interp1(gph, U_now, MRHeights);
                    V_interp(lon, lat, :, time) = interp1(gph, V_now, MRHeights);
                    catch
                        disp(strcat('Could not interpolate',{' '},yyyymmdd));
                        U_interp(lon, lat, :, time) = nan(1,1,30);
                        V_interp(lon, lat, :, time) = nan(1,1,30);
                        continue
                    end
                    
                end % time
            end % lat
        end % lon

        UU = nan(size(U_interp));
        VV = nan(size(V_interp));
        % Selecting data that's close enough
        UU(4:8,7,:,:) = U_interp(4:8,7,:,:); VV(4:8,7,:,:) = V_interp(4:8,7,:,:);
        UU(4:8,8,:,:) = U_interp(4:8,8,:,:); VV(4:8,8,:,:) = V_interp(4:8,8,:,:);
        UU(5:7,9,:,:) = U_interp(5:7,9,:,:); VV(5:7,9,:,:) = V_interp(5:7,9,:,:);
        
        U_ave = squeeze(mean(mean(UU,2,'omitnan'),1,'omitnan'));
        V_ave = squeeze(mean(mean(VV,2,'omitnan'),1,'omitnan'));
        
        U_overall = [U_overall, U_ave];
        V_overall = [V_overall, V_ave];
    end

    Model.Attributes = A.Attributes;
    Model.Variables = A.Variables;
    Model.Format = A.Format;
    Model.Data.lev = A.Data.lev;
    Model.Data.U = U_overall;
    Model.Data.V = V_overall;
    Model.Data.MRHeights = MRHeights;

    time = datenum(dayrange(1):hours(3):dayrange(end)+1);
    time(end) = [];

    Model.Data.Time = time;

    savename = [modeldirec num2str(yr) '_RotheraModelBoxGPH1.mat'];
    save(savename,'Model')

    disp(['Saving to: ' savename '...'])
end
