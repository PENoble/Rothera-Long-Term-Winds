%% MR Linear regression 
% Current working version 23rd Sept
% Attempting to put in case code structure.
% t-stat version

% 28th Sept 2021 - added to process GW tendencies in the regression too c
clear all;

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
output_dir = 'C:\Users\pn399\OneDrive - University of Bath\Paper1\Figure code\Figure6and7\';

%% Indices
list = {'SOLAR','ENSO','QBO10','QBO30','SAM'};
list_label = {'per \alpha sfu','per \alpha �C','per \alpha m/s','per \alpha m/s','per \alpha hPa'};

% Load the indices
load('C:\Users\pn399\OneDrive - University of Bath\MATLAB\Linear Regression\NewIndices\Indices.mat');

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
                MR = load('C:\Users\pn399\OneDrive - University of Bath\Paper1\Figure code\MRProcessing\Data\AllYears.mat');
                walt = mean(MR.AllYears.MonthlyWalt,2,'omitnan');

                switch direction
                    case 1; U = MR.AllYears.MonthlyMedU(:,1+12*(start_yr-2005):end-(2021-end_yr)*12);
                    case 2; U = MR.AllYears.MonthlyMedV(:,1+12*(start_yr-2005):end-(2021-end_yr)*12);
                    case 3; U = MR.AllYears.MonthlyMedV(:,1+12*(start_yr-2005):end-(2021-end_yr)*12); % this is just to make the code work - nothing is saved.
                end
            case 2
                % Load WACCM data
                WACCM = load('C:\Users\pn399\OneDrive - University of Bath\Paper1\Figure code\WACCMProcessing\Winds\AllModelRotheraBoxHeight.mat','All');
                walt = WACCM.All.Data.MRHeights;

                switch direction
                    case 1; U = WACCM.All.Data.MonthlyMedU(:,(start_yr-1980)*12+1:end-12*(2017-end_yr));
                    case 2; U = WACCM.All.Data.MonthlyMedV(:,(start_yr-1980)*12+1:end-12*(2017-end_yr));
                    case 3; load('C:\Users\pn399\OneDrive - University of Bath\Paper1\Figure code\WACCMProcessing\UTGW\UTGW_AllYears.mat');
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

end %input_data


% 
% %% Working out if t-stat is significant.
% T_test95 = ((t_stat>2.05)|(t_stat<-2.05));
% T_test90 = ((t_stat>1.7)|(t_stat<-1.7));
% 
% %% Now we want to plot contoU_anomaly maps
% matrix = [f107, ENSO, QBO10, QBO30, SAM];
% 
% % scaling_list1 = [2*std(f107,'omitnan'),2*std(ENSO,'omitnan'),2*std(QBO10,'omitnan'),2*std(QBO30,'omitnan'),2*std(SAM,'omitnan')]; % scaling for plotting.
%             

% 
% %%            
% for a = 2:6 % a is just a pointer to each index f10.7 etc.. (starts at 2 because 1 is the coefficient in the lin regression).
%     component = a;
%     scaling = scaling_list(a-1);
%     
%     coeff = coeffs(3:26,:,component);
%     pv_temp = pv(3:26,:,component);
%     t_stat_temp = t_stat(3:26,:,component);
% 
%     Coeffs = [coeff coeff coeff];
%     pValues = [pv_temp pv_temp pv_temp];
%     t_values = [t_stat_temp  t_stat_temp t_stat_temp];
%     
% 
%     
%     f2 = figU_anomalye('position',[50 50 950 550]);
%     axx = gca;
%     hold on
% %     contoU_anomalyf(1:36,  walt(3:26), scaling*Coeffs,[Zlims{a-1}(1):1:Zlims{a-1}(2)],'LineStyle','none');
%     contoU_anomaly(1:36, walt(3:26), t_values,[1.7,1.7],'LineColor','black','LineWidth',1.5);
%     contoU_anomaly(1:36, walt(3:26), t_values,[-1.7,-1.7],'LineColor','black','LineWidth',1.5);
% %     contoU_anomaly(1:36, walt(3:26), t_values,[2.05,2.05],'LineColor','black','LineWidth',1.5);
% %     contoU_anomaly(1:36, walt(3:26), t_values,[-2.05,-2.05],'LineColor','black','LineWidth',1.5);
%     
%     h = patch(axx.XLim([1 2 2 1]), axx.YLim([1 1 2 2]),'red');
%     hh = hatchfill(h, 'single',45,8);
%     set(hh, 'color', [0 0 0 0.8],'linewi',1);
%     
% %     nanmask = gb.HWD.Data.wtime>datenum(2017,05,06);
% %     gb.HWD.Data.u(~nanmask) = NaN;
% %     hold on; pcolor(gb.HWD.Data.wtime(:,gb.timeinds)+localtimeshift,gb.HWD.Data.walt(:,gb.timeinds),gb.HWD.Data.u(:,gb.timeinds)); shat;
%     
%     nanmask = t_values<1.7 & t_values>-1.7;
%     Coeffs(~nanmask) = NaN;
%     contoU_anomalyf(1:36,  walt(3:26), scaling*Coeffs,[Zlims{a-1}(1):1:Zlims{a-1}(2)],'LineStyle','none');
% 
% 
%     hold off
% 
%     c = colorbar;
%     colormap(cbrew('RdBu',100)), c.Label.String = strcat('ms^{-1}',{' '}, list_label(a-1));
%     set(c,'YTick',[-10:2:10]);
%     set(gca, 'ydir','normal'); 
%     clim(Zlims{a-1})
%     %clim([-11,11]);
%     set(gcf,'color','w')
%     set(gca,'TickDir','out','TickLength',[0.005,0.005],'LineWidth',1.5);
%     set(gca, 'fontsize', 20);
%     set(gca, 'xtick',12.5:24.5);
% 
%     % Offset the label to appear in the gap
%     gapsize = 7;
%     set(gca,'xticklabel', {[ blanks(gapsize) 'J'], [ blanks(gapsize) 'F'], [ blanks(gapsize) 'M'],[ blanks(gapsize) 'A'],[ blanks(gapsize) 'M'], [ blanks(gapsize) 'J'],[ blanks(gapsize) 'J'], [ blanks(gapsize) 'A'], [ blanks(gapsize) 'S'], [ blanks(gapsize) 'O'],[ blanks(gapsize) 'N'], [ blanks(gapsize) 'D'], ''});
%     
%     yline(80);
%     yline(100);
%     xline(12.5);
%     xline(24.5);
% 
%     ylim([80,100]);
%     %xlim([12.5,24.5]);
%     xlim([12.5,24.5]);
%     title(strcat('MR',{' '}, direction_label,{' '},'WIND'));
%     xlabel('MONTH');
%     ylabel('HEIGHT (km)');
%     
%     if save == 1
%         saveas(f2, strcat('C:\Users\pn399\OneDrive - University of Bath\MATLAB\Linear Regression\AutoPlots\T-Stats\MR\MR',yr_label,string(direction_label),string(list(a-1)),'.png'));
%     end
% 
% end %a
% 
% %% Plot line plots of contributions:
% 
% 
% coloU_anomalys = {[0.8500, 0.3250, 0.0980],[0.9290, 0.6940, 0.1250],[0.4940, 0.1840, 0.5560],[0.4660, 0.6740, 0.1880],[0.3010, 0.7450, 0.9330]};
% 
% 
% 
% % for h_i = 5:5:25
% %     F = figU_anomalye('position',[50 50 950 550]);
% %     hold on
% %     for k = 2:6
% % 
% %         x = 1:36;
% %         yy = scaling_list(k-1)*coeffs(h_i,:,k);
% %         yy = [yy yy yy];
% % 
% %         t = t_stat(h_i,:,k);
% %         t = [t t t];
% % 
% %         h = plot(x,yy,'color',coloU_anomalys{k-1},'LineWidth',1);
% %         h.Annotation.LegendInformation.IconDisplayStyle = 'on';
% %         
% %         % We have to interpolate p values in order for them to show up.
% %         x_t = 1:0.05:36;
% %         t_t = interp1(x,t,x_t);
% %         y_t = interp1(x,yy,x_t);
% %         
% %         idx = t_t<1.7 & t_t>-1.7;
% %         y_t(idx) = nan;
% %         
% %         h2 = plot(x_t,y_t,'color',coloU_anomalys{k-1},'LineWidth',4);
% %         try
% %         h2.Annotation.LegendInformation.IconDisplayStyle = 'off';
% %         catch
% %             continue
% %         end
% % 
% %         xlim([12.5,24.5]);
% % 
% %         title(strcat('MR',{' '}, direction_label,{' '}, string(round(walt(h_i),0)), {' '}, 'km'));
% %         set(gca, 'fontsize', 20);
% %         set(gca, 'xtick',12.5:24.5);
% % 
% %         % Offset the label to appear in the gap
% %         gapsize = 8;
% %         set(gca,'xticklabel', {[ blanks(gapsize) 'J'], [ blanks(gapsize) 'F'], [ blanks(gapsize) 'M'],[ blanks(gapsize) 'A'],[ blanks(gapsize) 'M'], [ blanks(gapsize) 'J'],[ blanks(gapsize) 'J'], [ blanks(gapsize) 'A'], [ blanks(gapsize) 'S'], [ blanks(gapsize) 'O'],[ blanks(gapsize) 'N'], [ blanks(gapsize) 'D'], ''});
% % 
% %         xlabel('Month');
% %         ylabel('Contribution (m/s /\alpha index units)');
% %         ylim([-12,12]);
% % 
% %     end
% %     hold off
% %     yline(0,'--');
% %     legend(list,'NumColumns',2,'FontSize',15);
% %     saveas(F, strcat('C:\Users\pn399\OneDrive - University of Bath\MATLAB\Linear Regression\AutoPlots\\T-Stats\MR\MR',yr_label,string(direction_label),string(round(walt(h_i),0)),'Line.png'));
% % 
% % end % h_i
% % 
% 
% %
% % 
% % % Plotting linear regression results by height. 
% % for h_i = 1:30
% %     
% %     mC = abs(squeeze(C(h_i,:,:)));
% %     ylimits = [-max(mC(:)), max(mC(:))];
% %     
% %     f3 = figU_anomalye('units','normalized','outerposition',[0 0 1 1]); 
% %     hold all; set(gcf,'color','w')
% % 
% %     set(gca, 'fontsize', 20);
% %     
% %     %-------------------------------------------------------
% %     vert_gap = 0.08;        horz_gap = 0.05;
% %     lower_marg = 0.08;     upper_marg = 0.1;
% %     left_marg = 0.07;      right_marg = 0.07;
% % 
% %     subplot = @(rows,cols,p) subtightplot (rows,cols,p,[vert_gap horz_gap],[lower_marg upper_marg],[left_marg right_marg]);
% %     sgtitle({strcat('Linear regression model for', {' '}, string(direction_label),' MR observations'),strcat('Height =',{' '},string(round(walt(h_i),0)),{' '},'km')}); 
% % 
% %     subplot(2,1,1)
% %     hold on
% %     plot(time,U_anomaly(h_i,:),'LineWidth',2);
% %     plot(time,Y(h_i,:),'LineWidth',2);
% %     hold off
% %     legend('MR','Predicted', 'Orientation','horizontal');
% %     ylabel('windspeed (m/s)');
% %     if direction == 'U'
% %         ylim([-16,16]);
% %     else
% %         ylim([-16,16]);
% %     end
% %     
% %     datetick('x','YYYY');
% % 
% %     subplot(2,1,2)
% %     hold on
% %     plot(time,C(h_i,:,1),'LineWidth',2);
% %     plot(time,C(h_i,:,2),'LineWidth',2);
% %     plot(time,C(h_i,:,3),'LineWidth',2);
% %     plot(time,C(h_i,:,4),'LineWidth',2);
% %     plot(time,C(h_i,:,5),'LineWidth',2);
% %     plot(time,C(h_i,:,6),'LineWidth',2);
% %     hold off
% %     L = legend('Constant','F10.7','ENSO','QBO10','QBO30','SAM');
% %     set(L,'Orientation','horizontal','Location','SouthWest');
% %     datetick('x','YYYY');
% %     ylim(ylimits);
% %     ylabel('windspeed (m/s)');
% %     if direction == 'U'
% %         ylim([-10,10]);
% %     else
% %         ylim([-6,6]);
% %     end
% %     
% % 
% %     saveas(f3, strcat('C:\Users\pn399\OneDrive - University of Bath\MATLAB\Linear Regression\AutoPlots\NoLinTerm\TStatMR',yr_label,'\MR',yr_label,string(direction_label),string(round(walt(h_i),0)),'km.png'));
% % end % height
% % 
% % %% Plotting individual subplots of contributions
% % for h_i = 1:30
% %     
% %     mC = abs(squeeze(C(h_i,:,:)));
% %     ylimits = [-max(mC(:)), max(mC(:))];
% %     
% %     f4 = figU_anomalye('units','normalized','outerposition',[0 0 1 1]); 
% %     hold all; set(gcf,'color','w')
% % 
% %     set(gca, 'fontsize', 20);
% %     
% %     %-------------------------------------------------------
% %     vert_gap = 0.08;        horz_gap = 0.05;
% %     lower_marg = 0.08;     upper_marg = 0.1;
% %     left_marg = 0.07;      right_marg = 0.07;
% % 
% %     subplot = @(rows,cols,p) subtightplot (rows,cols,p,[vert_gap horz_gap],[lower_marg upper_marg],[left_marg right_marg]);
% %     sgtitle({strcat('Linear regression model for', {' '}, string(direction_label),' MR observations'),strcat('Height =',{' '},string(round(walt(h_i),0)),{' '},'km')}); 
% % 
% %     if direction == 'U'
% %         ylim([-10,10]);
% %     else
% %         ylim([-6,6]);
% %     end
% %     
% %     subplot(5,1,1)
% %     plot(time,C(h_i,:,2),'LineWidth',2,'color',[0.8500, 0.3250, 0.0980]);
% %     ylabel('Solar (m/s)');
% %     yline(0,'--');
% %     datetick('x','YYYY');
% %     ylim(ylimits);
% %     box off;
% %     
% %     subplot(5,1,2)
% %     plot(time,C(h_i,:,3),'LineWidth',2, 'color', [0.9290, 0.6940, 0.1250]);
% %     ylabel('ENSO (m/s)');
% %     yline(0,'--');
% %     datetick('x','YYYY');
% %     ylim(ylimits);
% %     box off;  
% %     
% %     subplot(5,1,3)
% %     plot(time,C(h_i,:,4),'LineWidth',2, 'color',[0.4940, 0.1840, 0.5560]);
% %     ylabel('QBO10 (m/s)');
% %     yline(0,'--');
% %     datetick('x','YYYY');
% %     ylim(ylimits);
% %     box off;
% %     
% %     subplot(5,1,4)
% %     plot(time,C(h_i,:,5),'LineWidth',2, 'color', [0.4660, 0.6740, 0.1880]);
% %     ylabel('QBO30 (m/s)');
% %     yline(0,'--');
% %     datetick('x','YYYY');
% %     ylim(ylimits);
% %     box off;
% %         
% %     subplot(5,1,5)
% %     plot(time,C(h_i,:,6),'LineWidth',2, 'color', [0.3010, 0.7450, 0.9330]);
% %     ylabel('SAM (m/s)');
% %     yline(0,'--');
% %     datetick('x','YYYY');
% %     ylim(ylimits);
% %     box off;
% %     
% %     saveas(f4, strcat('C:\Users\pn399\OneDrive - University of Bath\MATLAB\Linear Regression\AutoPlots\NoLinTerm\TStatMR',yr_label,'\MR',yr_label,string(direction_label),string(round(walt(h_i),0)),'km_individualPlotsLin.png'));
% % end % height
% 
% 
% % save(strcat('C:\Users\pn399\OneDrive - University of Bath\MATLAB\Linear Regression\DW_stats\',yr_label,string(direction_label),'DW_MR.mat'), 'DW_test');
% 
% 
% 
% 
% %% ***************************** 
% %  WACCM Linear regression 
% %  *****************************
% 
% WACCM_start_yr = 2005; % note that the start year cannot be earlier than 2005 (as MR data doesn't exist).
% WACCM_end_yr = 2015; % latest = 2021
% 
% WACCM_yr_label = strcat(string(WACCM_start_yr),'-',string(WACCM_end_yr));
% WACCM_length_yrs = WACCM_end_yr - WACCM_start_yr + 1;
% 
% 
% 
% %% REGRESSION PRE PROCESSING - find anomaly 
% 
% % Variables for first step
% U_WACCM_anomaly = nan(15,12*WACCM_length_yrs);
% % U_WACCM_r = nan(15,12,WACCM_length_yrs);
% WACCM_trend = nan(15,12);
% WACCM_p_trend = nan(15,12);
% 
% for W_height_i = 1:30
%     %average year - and use this as oU_anomaly season
%     aveU_WACCM = mean(reshape(U_WACCM(W_height_i,:), [12,WACCM_length_yrs]),2,'omitnan')';
%     % copying the season (length_yrs) times for each year.
%     season = repmat(aveU_WACCM, [1,WACCM_length_yrs])';
% 
%     U_WACCM_anomaly(W_height_i,:) = U_WACCM(W_height_i,:) - season';
% 
% end % W_height_i
% U_WACCM_r = U_WACCM_anomaly;
% 
% 
% %% Before we run the main regression we want to check the VIFs using the three month sliding windows.
% 
% 
% % For Main regression later
% mdl = cell(30,12);
% DW_test = nan(30,12);
% p_DW_test = nan(30,12);
% coeffs = nan(30,12,6);
% pv = nan(30,12,6);
% t_stat = nan(30,12,6);
% Y_WACCM = nan(30,12,WACCM_length_yrs);
% componentsM = nan(30,12,WACCM_length_yrs,6);
% C = nan(30,WACCM_length_yrs*12,6);
% 
% for W_height_ii = 1:30
%     for W_mnth_ii = 1:12
%         %Extracting month window around selected month.
%         if W_mnth_ii == 12
%             mnth_plus = 1;
%         else
%             mnth_plus = W_mnth_ii+1;
%         end
% 
%         if W_mnth_ii == 1
%             mnth_minus = 12;
%         else
%             mnth_minus = W_mnth_ii-1;
%         end
%       
%         %Selecting the values from those months
%         W_idx2 = month(time) == mnth_minus | month(time) == W_mnth_ii | month(time) == mnth_plus;
%         
%         f107m = f107(W_idx2);
%         ENSOm = ENSO(W_idx2);
%         QBO10m = QBO10(W_idx2);
%         QBO30m = QBO30(W_idx2);       
%         SAMm = SAM(W_idx2);
%         monthsm = months(W_idx2);
%         timem = time(W_idx2);
%         WACCM_Um = U_WACCM_r(W_height_ii, W_idx2);
% 
%        
%         f107m_Normalised = f107m - mean(f107m,'omitnan');
%         ENSOm_Normalised = ENSOm - mean(ENSOm,'omitnan');
%         QBO10m_Normalised = QBO10m - mean(QBO10m,'omitnan');
%         QBO30m_Normalised = QBO30m - mean(QBO30m,'omitnan');
%         SAMm_Normalised = SAMm - mean(SAMm,'omitnan');
%         
%         %% Regression
%         matrix = [f107m_Normalised, ENSOm_Normalised, QBO10m_Normalised, QBO30m_Normalised, SAMm_Normalised];
%         mdl{W_height_ii,W_mnth_ii} = fitlm(matrix, WACCM_Um);
%         
%         % Properties of the regression
%         [t,DW] = dwtest(mdl{W_height_ii, W_mnth_ii});
%         DW_test(W_height_ii, W_mnth_ii) = DW;
%         p_DW_test(W_height_ii, W_mnth_ii) = t;
%         
%         coefs = mdl{W_height_ii,W_mnth_ii}.Coefficients.Estimate;
% 
%         components = [coefs(1)*ones(length_yrs*3,1),coefs(2)*f107m_Normalised, ...
%                         coefs(3)*ENSOm_Normalised,coefs(4)*QBO10m_Normalised, ...
%                         coefs(5)*QBO30m_Normalised,coefs(6)*SAMm_Normalised];
%                     
%         % saved for later
%         coeffs(W_height_ii, W_mnth_ii,:) = coefs;        
%         pv(W_height_ii, W_mnth_ii,:) = mdl{W_height_ii,W_mnth_ii}.Coefficients.pValue;
%         t_stat(W_height_ii, W_mnth_ii,:) = mdl{W_height_ii,W_mnth_ii}.Coefficients.tStat;
%         
%         y = sum(components,2);
%         
%         W_idx3 = month(timem) == W_mnth_ii;
%         Y_WACCM(W_height_ii,W_mnth_ii,:) = y(W_idx3);
%         componentsM(W_height_ii, W_mnth_ii,:,:) = components(W_idx3,:);
%         
%     end % mnth
%     C(W_height_ii,:,:) = reshape(componentsM(W_height_ii,:,:,:), [WACCM_length_yrs*12,6]);
% end %height
% 
% 
% %% Now we want to plot contoU_anomaly maps
% %matrix = [f107, ENSO, QBO10, QBO30, SAM];
% 
% for a = 2:6
%     component = a;
%     scaling = scaling_list(a-1);
%     
%     coeff = coeffs(3:26,:,component);
%     pv_temp = pv(3:26,:,component);
%     t_stat_temp = t_stat(3:26,:,component);
% 
%     Coeffs = [coeff coeff coeff];
%     pValues = [pv_temp pv_temp pv_temp];
%     t_values = [t_stat_temp  t_stat_temp t_stat_temp];
%     
% 
%     
%     %%
%     f2 = figU_anomalye('position',[50 50 950 550]);
%     hold on
%     contoU_anomalyf(1:36,  walt(3:26), scaling*Coeffs,[-20:1:20],'LineStyle','none');
%     contoU_anomaly(1:36, walt(3:26), t_values,[1.7,1.7],'LineColor','black','LineWidth',1.5);
%     contoU_anomaly(1:36, walt(3:26), t_values,[-1.7,-1.7],'LineColor','black','LineWidth',1.5);
% %     contoU_anomaly(1:36, walt(3:26), t_values,[2.05,2.05],'LineColor','black','LineWidth',1.5);
% %     contoU_anomaly(1:36, walt(3:26), t_values,[-2.05,-2.05],'LineColor','black','LineWidth',1.5);
%     hold off
% 
%     c = colorbar;
%     colormap(cbrew('RdBu',100)), c.Label.String = strcat('ms^{-1}', {' '}, list_label(a-1));
%     set(c,'YTick',[-10:2:10]);
%     set(gca, 'ydir','normal'); 
%     clim(Zlims{a-1})
%     set(gcf,'color','w')
%     set(gca,'TickDir','out','TickLength',[0.005,0.005],'LineWidth',1.5);
%     set(gcf,'color','w');
%     set(gca, 'fontsize', 20);
%     set(gca, 'xtick',12.5:24.5);
% 
%     % Offset the label to appear in the gap
%     gapsize = 7;
%     set(gca,'xticklabel', {[ blanks(gapsize) 'J'], [ blanks(gapsize) 'F'], [ blanks(gapsize) 'M'],[ blanks(gapsize) 'A'],[ blanks(gapsize) 'M'], [ blanks(gapsize) 'J'],[ blanks(gapsize) 'J'], [ blanks(gapsize) 'A'], [ blanks(gapsize) 'S'], [ blanks(gapsize) 'O'],[ blanks(gapsize) 'N'], [ blanks(gapsize) 'D'], ''});
%     
%     yline(80);
%     yline(100);
%     xline(12.5);
%     xline(24.5);
%     
%     ylim([80,100]);
%     %xlim([12.5,24.5]);
%     xlim([12.5,24.5]);
%     title(strcat('WACCM',{' '}, direction_label,{' '},'WIND'));
%     xlabel('MONTH');
%     ylabel('HEIGHT (km)');
%     
%     if save == 1
%         saveas(f2, strcat('C:\Users\pn399\OneDrive - University of Bath\MATLAB\Linear Regression\AutoPlots\T-Stats\WACCM\WACCM',WACCM_yr_label,string(direction_label),string(list(a-1)),'Lin.png'));
%     end
% 
% end %a
% 
% % save(strcat('C:\Users\pn399\OneDrive - University of Bath\MATLAB\Linear Regression\DW_stats\',yr_label,string(direction_label),'DW_WACCM.mat'), 'DW_test');
% % % 
% % for h_i = 5:5:25
% %     F = figU_anomalye('position',[50 50 950 550]);
% %     hold on
% %     for k = 2:6
% % 
% %         x = 1:36;
% %         yy = scaling_list(k-1)*coeffs(h_i,:,k);
% %         yy = [yy yy yy];
% % 
% %         t = t_stat(h_i,:,k);
% %         t = [t t t];
% % 
% %         h = plot(x,yy,'color',coloU_anomalys{k-1},'LineWidth',1);
% %         h.Annotation.LegendInformation.IconDisplayStyle = 'on';
% %         
% %         % We have to interpolate p values in order for them to show up.
% %         x_t = 1:0.05:36;
% %         t_t = interp1(x,t,x_t);
% %         y_t = interp1(x,yy,x_t);
% %         
% %         idx = t_t<1.7 & t_t>-1.7;
% %         y_t(idx) = nan;
% %         
% %         h2 = plot(x_t,y_t,'color',coloU_anomalys{k-1},'LineWidth',4);
% %         try
% %         h2.Annotation.LegendInformation.IconDisplayStyle = 'off';
% %         catch
% %             continue
% %         end
% % 
% %         xlim([12.5,24.5]);
% % 
% %         title(strcat('WACCM',{' '}, direction_label,{' '}, string(round(walt(h_i),0)), {' '}, 'km'));
% %         set(gca, 'fontsize', 20);
% %         set(gca, 'xtick',12.5:24.5);
% % 
% %         % Offset the label to appear in the gap
% %         gapsize = 8;
% %         set(gca,'xticklabel', {[ blanks(gapsize) 'J'], [ blanks(gapsize) 'F'], [ blanks(gapsize) 'M'],[ blanks(gapsize) 'A'],[ blanks(gapsize) 'M'], [ blanks(gapsize) 'J'],[ blanks(gapsize) 'J'], [ blanks(gapsize) 'A'], [ blanks(gapsize) 'S'], [ blanks(gapsize) 'O'],[ blanks(gapsize) 'N'], [ blanks(gapsize) 'D'], ''});
% % 
% %         xlabel('Month');
% %         ylabel('Contribution (m/s / \alpha index units)');
% %         ylim([-12,12]);
% % 
% %     end
% %     hold off
% %     yline(0,'--');
% %     legend(list,'NumColumns',2,'FontSize',15,'location','southeast');
% %     saveas(F, strcat('C:\Users\pn399\OneDrive - University of Bath\MATLAB\Linear Regression\AutoPlots\T-Stats\WACCM\WACCM',yr_label,string(direction_label),string(round(walt(h_i),0)),'Line.png'));
% % 
% % end % h_i
% 
% 
% % 
% % 
% % %% Plotting
% % %Height strip plots
% % 
% % for h_i = 1:30
% %     
% %     mC = abs(squeeze(C(h_i,:,:)));
% %     ylimits = [-max(mC(:)), max(mC(:))];
% %     
% %     f3 = figU_anomalye('units','normalized','outerposition',[0 0 1 1]); 
% %     hold all; set(gcf,'color','w')
% % 
% %     set(gca, 'fontsize', 20);
% %     
% % %     -------------------------------------------------------
% %     vert_gap = 0.08;        horz_gap = 0.05;
% %     lower_marg = 0.08;     upper_marg = 0.1;
% %     left_marg = 0.07;      right_marg = 0.07;
% % 
% %     subplot = @(rows,cols,p) subtightplot (rows,cols,p,[vert_gap horz_gap],[lower_marg upper_marg],[left_marg right_marg]);
% %     sgtitle({strcat('Linear regression model for', {' '}, string(direction_label),' WACCM'),strcat('Height =',{' '},string(round(walt(h_i),0)),{' '},'km')}); 
% % 
% %     subplot(2,1,1)
% %     hold on
% %     plot(time,U_WACCM_r(h_i,:),'LineWidth',2);
% %     plot(time,Y_WACCM(h_i,:),'LineWidth',2);
% %     hold off
% %     legend('WACCM','Predicted', 'Orientation','horizontal');
% %     ylabel('windspeed (m/s)');
% %     if direction == 'U'
% %         ylim([-16,16]);
% %     else
% %         ylim([-16,16]);
% %     end
% %     
% %     datetick('x','YYYY');
% % 
% %     subplot(2,1,2)
% %     hold on
% %     plot(time,C(h_i,:,1),'LineWidth',2);
% %     plot(time,C(h_i,:,2),'LineWidth',2);
% %     plot(time,C(h_i,:,3),'LineWidth',2);
% %     plot(time,C(h_i,:,4),'LineWidth',2);
% %     plot(time,C(h_i,:,5),'LineWidth',2);
% %     plot(time,C(h_i,:,6),'LineWidth',2);
% %     hold off
% %     L = legend('Constant','F10.7','ENSO','QBO10','QBO30','SAM');
% %     set(L,'Orientation','horizontal','Location','SouthWest');
% %     datetick('x','YYYY');
% %     ylim(ylimits);
% %     ylabel('windspeed (m/s)');
% %     if direction == 'U'
% %         ylim([-10,10]);
% %     else
% %         ylim([-6,6]);
% %     end
% %     
% % 
% %     saveas(f3, strcat('C:\Users\pn399\OneDrive - University of Bath\MATLAB\Linear Regression\AutoPlots\NoLinTerm\TStatWACCM',WACCM_yr_label,'\WACCM',WACCM_yr_label,string(direction_label),string(round(walt(h_i),0)),'km.png'));
% % end % height
% %     
% % 
% % 
% % %% Plotting individual subplots of contributions
% % for h_i = 1:30
% %     
% %     mC = abs(squeeze(C(h_i,:,:)));
% %     ylimits = [-max(mC(:)), max(mC(:))];
% %     
% %     f4 = figU_anomalye('units','normalized','outerposition',[0 0 1 1]); 
% %     hold all; set(gcf,'color','w')
% % 
% %     set(gca, 'fontsize', 20);
% %     
% % %     -------------------------------------------------------
% %     vert_gap = 0.08;        horz_gap = 0.05;
% %     lower_marg = 0.08;     upper_marg = 0.1;
% %     left_marg = 0.07;      right_marg = 0.07;
% % 
% %     subplot = @(rows,cols,p) subtightplot (rows,cols,p,[vert_gap horz_gap],[lower_marg upper_marg],[left_marg right_marg]);
% %     sgtitle({strcat('Linear regression model for', {' '}, string(direction_label),' WACCM'),strcat('Height =',{' '},string(round(walt(h_i),0)),{' '},'km')}); 
% % 
% %     if direction == 'U'
% %         ylim([-10,10]);
% %     else
% %         ylim([-6,6]);
% %     end
% %     
% %     subplot(5,1,1)
% %     plot(time,C(h_i,:,2),'LineWidth',2,'color',[0.8500, 0.3250, 0.0980]);
% %     ylabel('Solar (m/s)');
% %     yline(0,'--');
% %     datetick('x','YYYY');
% %     ylim(ylimits);
% %     box off;
% %     
% %     subplot(5,1,2)
% %     plot(time,C(h_i,:,3),'LineWidth',2, 'color', [0.9290, 0.6940, 0.1250]);
% %     ylabel('ENSO (m/s)');
% %     yline(0,'--');
% %     datetick('x','YYYY');
% %     ylim(ylimits);
% %     box off;  
% %     
% %     subplot(5,1,3)
% %     plot(time,C(h_i,:,4),'LineWidth',2, 'color',[0.4940, 0.1840, 0.5560]);
% %     ylabel('QBO10 (m/s)');
% %     yline(0,'--');
% %     datetick('x','YYYY');
% %     ylim(ylimits);
% %     box off;
% %     
% %     subplot(5,1,4)
% %     plot(time,C(h_i,:,5),'LineWidth',2, 'color', [0.4660, 0.6740, 0.1880]);
% %     ylabel('QBO30 (m/s)');
% %     yline(0,'--');
% %     datetick('x','YYYY');
% %     ylim(ylimits);
% %     box off;
% %         
% %     subplot(5,1,5)
% %     plot(time,C(h_i,:,6),'LineWidth',2, 'color', [0.3010, 0.7450, 0.9330]);
% %     ylabel('SAM (m/s)');
% %     yline(0,'--');
% %     datetick('x','YYYY');
% %     ylim(ylimits);
% %     box off;
% %     
% %     saveas(f4, strcat('C:\Users\pn399\OneDrive - University of Bath\MATLAB\Linear Regression\AutoPlots\NoLinTerm\TStatWACCM',WACCM_yr_label,'\WACCM',WACCM_yr_label,string(direction_label),string(round(walt(h_i),0)),'km_individualPlots.png'));
% % end % height
% 
% %% Testing how good the model is - run regression on the whole result
% r_MR_Notime = nan(1,30);
% r_WACCM_Notime = nan(1,30);
% 
% for h = 1:30
%     mdl_all_MR = fitlm(U_anomaly(h,:),Y(h,:));
%     r_MR_Notime(h) = mdl_all_MR.Rsquared.ordinary;
%     mdl_all_WACCM = fitlm(U_WACCM_r(h,:),Y_WACCM(h,:));
%     r_WACCM_Notime(h) = mdl_all_WACCM.Rsquared.ordinary;
% end
%  
