%% MR Linear regression 
% Current working version 23rd Sept
% Attempting to put in case code structure.
% t-stat version

% 28th Sept 2021 - added to process GW tendencies in the regression too c
clear all;

in_dir = 'C:\Users\pn399\OneDrive - University of Bath\Paper1\Figure code\';
output_dir = 'C:\Users\pn399\OneDrive - University of Bath\Paper1\Figure code\Figure6and7\';

% Settings
save1 = 1; % 1 to save 

start_yr = 2005; % note that the start year cannot be earlier than 2005 (as MR data doesn't exist).
end_yr = 2015; % latest = 2021


yr_label = strcat(string(start_yr),'-',string(end_yr));
length_yrs = end_yr - start_yr + 1;

% Output variables
RegressionResults = struct;
RegressionResults.MR = struct;
RegressionResults.WACCM = struct;
RegressionResults.MR.U = struct;
RegressionResults.MR.V = struct;
RegressionResults.WACCM.U = struct;
RegressionResults.WACCM.V = struct;

%% Indices
list = {'SOLAR','ENSO','QBO10','QBO30','SAM'};
list_label = {'per \alpha sfu','per \alpha °C','per \alpha m/s','per \alpha m/s','per \alpha hPa'};

% Load the indices
load(strcat(in_dir, 'Figure2\Indices.mat'));

%Note these indices start in 1980 - so we remove the first bit
f107 = indices.f107((start_yr-1980)*12+1:end-(2021-end_yr)*12)';
ENSO = indices.ENSO((start_yr-1980)*12+1:end-(2021-end_yr)*12)';
QBO10 = indices.QBO10((start_yr-1980)*12+1:end-(2021-end_yr)*12)';
QBO30 = indices.QBO30((start_yr-1980)*12+1:end-(2021-end_yr)*12)';
SAM = indices.SAM((start_yr-1980)*12+1:end-(2021-end_yr)*12)';
time = indices.time((start_yr-1980)*12+1:end-(2021-end_yr)*12)';
months = (1:length(time))';

for input_data = 1:2 % 1 = MR, 2 = WACCM
    for direction = 1:3 % 1 = Zonal wind, 2 = meridional wind, 3 = UTGW
        switch input_data
            
            % Loading necessary data for direction and source
            case 1
                % Load MR data
                MR = load(strcat(in_dir, 'Data\AllMR.mat'));
                walt = mean(MR.AllYears.MonthlyWalt,2,'omitnan');

                switch direction
                    case 1; U = MR.AllYears.MonthlyMedU(:,1+12*(start_yr-2005):end-(2021-end_yr)*12);
                    case 2; U = MR.AllYears.MonthlyMedV(:,1+12*(start_yr-2005):end-(2021-end_yr)*12);
                    case 3; U = MR.AllYears.MonthlyMedV(:,1+12*(start_yr-2005):end-(2021-end_yr)*12); % this is just to make the code work - nothing is saved.
                end
            case 2
                % Load WACCM data
                WACCM = load(strcat(in_dir,'Data\AllWACCMRothera.mat'));
                walt = WACCM.All.Data.MRHeights;

                switch direction
                    case 1; U = WACCM.All.Data.MonthlyMedU(:,(start_yr-1980)*12+1:end-12*(2017-end_yr));
                    case 2; U = WACCM.All.Data.MonthlyMedV(:,(start_yr-1980)*12+1:end-12*(2017-end_yr));
                    case 3; load(strcat(in_dir,'Data\UTGW_AllYears.mat');
                            U = UTGW.AllYears';
                end
                
        end % input_data switch
      
        %% REGRESSION PRE PROCESSING - find and remove anomaly 
        % Variables for first step
        U_anomaly = nan(30,12*length_yrs);

        for height_i = 1:30
            %average year - and use this as oU_anomaly season
            aveU = mean(reshape(U(height_i,:), [12,length_yrs]),2,'omitnan')';
            % copying the season (length_yrs) times for each year.
            season = repmat(aveU, [1,length_yrs])';

            % Subtracting the anomaly from the wind
            U_anomaly(height_i,:) = U(height_i,:) - season'; 

        end % height_i

        %% Before we run the main regression we want to check the VIFs using the three month sliding windows.
        VIF = nan(12,5);

        % For Main regression later
        mdl = cell(30,12);
        DW_test = nan(30,12);
        p_DW_test = nan(30,12);
        coeffs = nan(30,12,6);
        pv = nan(30,12,6);
        t_stat = nan(30,12,6);
        Y = nan(30,12,length_yrs);
        componentsM = nan(30,12,length_yrs,6);
        C = nan(30,length_yrs*12,6);
        Y_reshaped = nan(30,length_yrs*12);

        for height_ii = 1:30
            for mnth_ii = 1:12
                %Extracting month window around selected month.
                if mnth_ii == 12
                    mnth_plus = 1;
                else
                    mnth_plus = mnth_ii+1;
                end

                if mnth_ii == 1
                    mnth_minus = 12;
                else
                    mnth_minus = mnth_ii-1;
                end

                %Selecting the values from those months
                idx2 = month(time) == mnth_minus | month(time) == mnth_ii | month(time) == mnth_plus;

                % Extracting the index values for each three month window
                f107m = f107(idx2);
                ENSOm = ENSO(idx2);
                QBO10m = QBO10(idx2);
                QBO30m = QBO30(idx2);       
                SAMm = SAM(idx2);
                monthsm = months(idx2);
                timem = time(idx2);
                Um = U_anomaly(height_ii, idx2);

                %VIF testing
                mdl1 = fitlm([ENSOm, QBO10m, QBO30m, SAMm],f107m);
                VIF(mnth_ii,1) = 1/(1-mdl1.Rsquared.ordinary);

                mdl2 = fitlm([f107m, QBO10m, QBO30m, SAMm],ENSOm);
                VIF(mnth_ii,2) = 1/(1-mdl2.Rsquared.ordinary);

                mdl3 = fitlm([f107m, ENSOm, QBO30m, SAMm],QBO10m);
                VIF(mnth_ii,3) = 1/(1-mdl3.Rsquared.ordinary);

                mdl4 = fitlm([f107m, ENSOm, QBO10m, SAMm],QBO30m);
                VIF(mnth_ii,4) = 1/(1-mdl4.Rsquared.ordinary);

                mdl5 = fitlm([f107m, ENSOm, QBO10m, QBO30m],SAMm);
                VIF(mnth_ii,5) = 1/(1-mdl5.Rsquared.ordinary);


                %We want to normalise the data within each month model
                f107m_Normalised = f107m - mean(f107m,'omitnan');
                ENSOm_Normalised = ENSOm - mean(ENSOm,'omitnan');
                QBO10m_Normalised = QBO10m - mean(QBO10m,'omitnan');
                QBO30m_Normalised = QBO30m - mean(QBO30m,'omitnan');
                SAMm_Normalised = SAMm - mean(SAMm,'omitnan');



                %% Regression
                matrix = [f107m_Normalised, ENSOm_Normalised, QBO10m_Normalised, QBO30m_Normalised, SAMm_Normalised];
                % Saving the linear regression in a cell array.
                mdl{height_ii,mnth_ii} = fitlm(matrix, Um);

                % Properties of the regression
                [t,DW] = dwtest(mdl{height_ii, mnth_ii});
                DW_test(height_ii, mnth_ii) = DW;
                p_DW_test(height_ii, mnth_ii) = t;

                coefs = mdl{height_ii,mnth_ii}.Coefficients.Estimate;

                components = [coefs(1)*ones(length_yrs*3,1),coefs(2)*f107m_Normalised, ...
                                coefs(3)*ENSOm_Normalised,coefs(4)*QBO10m_Normalised, ...
                                coefs(5)*QBO30m_Normalised,coefs(6)*SAMm_Normalised];

                % saved for later
                % Coefficients of the regression for each height, month and term
                coeffs(height_ii, mnth_ii,:) = coefs;        
                % p values of the regression for each height, month and term
                pv(height_ii, mnth_ii,:) = mdl{height_ii,mnth_ii}.Coefficients.pValue;
                t_stat(height_ii, mnth_ii,:) = mdl{height_ii,mnth_ii}.Coefficients.tStat;
                % predicted value of winds using the regression.
                y = sum(components,2);

                % Finally here we select the actual month we are predicting (rather
                % than the three month windows). 
                idx3 = month(timem) == mnth_ii;
                Y(height_ii,mnth_ii,:) = y(idx3); % Y is the predicted wind for each month, using that months model
                componentsM(height_ii, mnth_ii,:,:) = components(idx3,:); % componentsM is the components for each month, using that months model

            end % mnth
            C(height_ii,:,:) = reshape(componentsM(height_ii,:,:,:), [length_yrs*12,6]);
            Y_reshaped(height_ii,:) = reshape(Y(height_ii,:,:), [length_yrs*12,1]);

        end %height

        perc = 90;
        scaling_list = [prctile(f107,perc) - prctile(f107,100-perc), ...
                        prctile(ENSO,perc) - prctile(ENSO,100-perc), ...
                        prctile(QBO10,perc) - prctile(QBO10,100-perc), ...
                        prctile(QBO30,perc) - prctile(QBO30,100-perc), ...
                        prctile(SAM,perc) - prctile(SAM,100-perc)];
        
        % Saving results
        switch input_data
            case 1 
            switch direction
                case 1;     RegressionResults.MR.U.scalingList = scaling_list;
                            RegressionResults.MR.U.t_stat = t_stat;
                            RegressionResults.MR.U.coefficients = coeffs;
                            RegressionResults.MR.U.walt = walt;
                            RegressionResults.MR.U.DW_test = DW_test;
                            RegressionResults.MR.U.p_DW_test = p_DW_test;

                case 2;     RegressionResults.MR.V.scalingList = scaling_list;
                            RegressionResults.MR.V.t_stat = t_stat;
                            RegressionResults.MR.V.coefficients = coeffs;
                            RegressionResults.MR.V.walt = walt;
                            RegressionResults.MR.V.DW_test = DW_test;
                            RegressionResults.MR.V.p_DW_test = p_DW_test;
            end
            
            case 2
            switch direction
                case 1;     RegressionResults.WACCM.U.scalingList = scaling_list;
                            RegressionResults.WACCM.U.t_stat = t_stat;
                            RegressionResults.WACCM.U.coefficients = coeffs;
                            RegressionResults.WACCM.U.walt = walt;
                            RegressionResults.WACCM.U.DW_test = DW_test;
                            RegressionResults.WACCM.U.p_DW_test = p_DW_test;

                case 2;     RegressionResults.WACCM.V.scalingList = scaling_list;
                            RegressionResults.WACCM.V.t_stat = t_stat;
                            RegressionResults.WACCM.V.coefficients = coeffs;
                            RegressionResults.WACCM.V.walt = walt;
                            RegressionResults.WACCM.V.DW_test = DW_test;
                            RegressionResults.WACCM.V.p_DW_test = p_DW_test;
                            
                case 3;     RegressionResults.WACCM.UTGW.scalingList = scaling_list;
                            RegressionResults.WACCM.UTGW.t_stat = t_stat;
                            RegressionResults.WACCM.UTGW.coefficients = coeffs;
                            RegressionResults.WACCM.UTGW.walt = walt;
                            RegressionResults.WACCM.UTGW.DW_test = DW_test;
                            RegressionResults.WACCM.UTGW.p_DW_test = p_DW_test;
            end    
        end % input_data
        
        RegressionResults.VIF = VIF;


        save(strcat(output_dir,'LinearRegressionResults.mat'),'RegressionResults');

    end % direction
    
%     %Checking for normality in errors of regression (in order to apply
%     the t-test correctly
%     switch direction
%         case 1 switch input_data
%                 case 1; figure()
%                 end
%     end
% 
%     subplot(2,3,direction+3*(input_data-1));
%     error = Y_reshaped - U_anomaly;
%     hist(error(:),100);
%     text(0.5, 0.5, string(mean(error(:))), 'Units', 'Normalized'); 

end %input_data

