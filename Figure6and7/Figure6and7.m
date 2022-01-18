%% One plot of wind results
clear all;
load('C:\Users\pn399\OneDrive - University of Bath\MATLAB\LinearRegressionResults_GPH.mat');


for direction = 1:2 % 1 is zonal, 2 meridional

    gcf = figure();
    title('ll');
    set(gcf,'color','w','position',[50 50 800 600]);

    %-------------------------------------------------------
    vert_gap = 0.03;        horz_gap = 0.04;
    lower_marg = 0.05;     upper_marg = 0.12;
    left_marg = 0.2;      right_marg = 0.25;

    rows = 5; cols = 2;

    subplot = @(rows,cols,p) subtightplot (rows,cols,p,[vert_gap horz_gap],[lower_marg upper_marg],[left_marg right_marg]);
    switch direction
        case 1; sgtitle('ZONAL WIND REGRESSION COEFFICIENTS','Fontsize',18);
        case 2; sgtitle('MERIDIONAL WIND REGRESSION COEFFICIENTS','Fontsize',18);
    end
    
    figLabels = {'(a)','(b)','(c)','(d)','(e)','(f)','(g)','(h)','(i)','(j)'};
    for index = 2:6
        
        for type = 1:2    % 1 is MR, 2 WACCM
            switch direction 
                case 1
                switch type
                    case 1; Results = RegressionResults.MR.U;
                    case 2; Results = RegressionResults.WACCM.U;
                end
                case 2
                switch type 
                    case 1; Results = RegressionResults.MR.V;
                    case 2; Results = RegressionResults.WACCM.V;
                end
            end
            
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

            num = (index-2)*2 + type;
            subplot(5,2,num);
            text(0.01,0.9,string(figLabels(num)),'Units','Normalized','Fontsize',13);
            
            axx = gca;
            x = interpolated_months; y = interpolated_walt; Z = interpolated_coeffs; t = interpolated_t;

            hold on
            H1 = pcolor(x,y,Z);
            h = patch(axx.XLim([1 2 2 1]), axx.YLim([1 1 2 2]),'red');
            hh = hatchfill(h, 'single',45,3);
            set(H1, 'EdgeColor', 'none');

            set(hh, 'color', [0 0 0 0.5],'linewi',1);


            nanmask = t<1.7 & t>-1.7;
            Z_nan = Z;
            Z_nan(~nanmask) = NaN;

            H2 = pcolor(x, y, Z_nan);
            set(H2, 'EdgeColor', 'none');


            contour(x,y,Z,-10:5:10,'k','Showtext','on');

            hold off

            gapsize = 5;



            switch index
                case 6
                    set(gca,'xticklabel', {[ blanks(gapsize) 'J'], [ blanks(gapsize) 'F'], [ blanks(gapsize) 'M'],[ blanks(gapsize) 'A'],[ blanks(gapsize) 'M'], [ blanks(gapsize) 'J'],[ blanks(gapsize) 'J'], [ blanks(gapsize) 'A'], [ blanks(gapsize) 'S'], [ blanks(gapsize) 'O'],[ blanks(gapsize) 'N'], [ blanks(gapsize) 'D'], ''});
                    switch type
                        case 1
                            text(-0.3,3,'HEIGHT (km)','Units','Normalized','Rotation',90,'Fontsize',15,'VerticalAlignment','middle', 'HorizontalAlignment','center') 
                        case 2
                            c = colorbar; 
                            c.Label.String = strcat('Regression coefficient (ms^{-1} per \alpha)');
                            set(c,'YTick',[-10:2:10],'Fontsize',13);
                            set(c,'Position',[0.83 0.2 0.02 0.6]);
                    end
            end



            colormap(cbrew('RdBu',100))
            set(gca, 'ydir','normal'); 
            clim([-10,10])
            set(gcf,'color','w')
            set(gca,'TickDir','out','TickLength',[0.005,0.005],'LineWidth',1.5);
            set(gca, 'fontsize', 10);
            set(gca, 'xtick',12.5:24.5);


            yline(80);
            yline(100);
            xline(12.5);
            xline(24.5);

            ylim([80,100]);    
            
            switch type
                case 1; yticks(80:10:100);
                case 2; yticks(80:10:100); yticklabels({[]});
            end
            

            xlim([12.5,24.5]);

            switch index
                case 2
                    switch direction
                        case 1
                        switch type
                            case 1; title('MR','fontsize',15);
                            case 2; title('WACCM-X','fontsize',15);
                        end
                        case 2
                        switch type
                            case 1; title('MR','fontsize',15);
                            case 2; title('WACCM-X','fontsize',15);
                        end
                    end
                    xticklabels({[]});
                case 3; xticklabels({[]});
                case 4; xticklabels({[]});
                case 5; xticklabels({[]});
            end
            
            switch type
                case 2
                    switch index
                        case 2;text(1.05, 0.5, 'SOLAR', 'Units', 'Normalized', 'fontsize', 18, 'rotation', 90, 'HorizontalAlignment','center','VerticalAlignment','middle');
                        case 3;text(1.05, 0.5, 'ENSO', 'Units', 'Normalized', 'fontsize', 18, 'rotation', 90, 'HorizontalAlignment','center','VerticalAlignment','middle');
                        case 4;text(1.05, 0.5, 'QBO10', 'Units', 'Normalized', 'fontsize', 18, 'rotation', 90, 'HorizontalAlignment','center','VerticalAlignment','middle');
                        case 5;text(1.05, 0.5, 'QBO30', 'Units', 'Normalized', 'fontsize', 18, 'rotation', 90, 'HorizontalAlignment','center','VerticalAlignment','middle');
                        case 6;text(1.05, 0.5, 'SAM', 'Units', 'Normalized', 'fontsize', 18, 'rotation', 90, 'HorizontalAlignment','center','VerticalAlignment','middle');
                    end
            end
            



        end % panel

    end %index
end % figure