%% STRIP PLOTS MR
clear all

direc = 'C:\Users\pn399\OneDrive - University of Bath\Paper1\Figure code\Data\';

for WindDirection = 1:2  
    % Set up figure
    gcf = figure('position',[10 10 1000 900]); 
    set(gcf,'color','w')

    % set(gcf,'position',[50 50 1000 750]);
    vert_gap = 0.05;        horz_gap = 0.05;
    lower_marg = 0.12;     upper_marg = 0.13;
    left_marg = 0.15;      right_marg = 0.15;

    subplot = @(rows,cols,p) subtightplot (rows,cols,p,[vert_gap horz_gap],[lower_marg upper_marg],[left_marg right_marg]);
    
    switch WindDirection
        case 1; sgtitle('ZONAL WINDS','fontsize',20); 
        case 2; sgtitle('MERIDIONAL WINDS','fontsize',20); 
    end

    %Load data
    MR = load(strcat(direc,'AllMR.mat'));
    walt = mean(MR.AllYears.MonthlyWalt,2,'omitnan');
    WACCM = load(strcat(direc,'AllWACCMRothera.mat'));
    height = WACCM.All.Data.gph_MRHeights;
    
    for type = 1:2
        switch type
            case 1
            switch WindDirection
                case 1
                Z = MR.AllYears.MonthlyMeanU;
                Zlims = 50;
                AllU = mean(reshape(MR.AllYears.MonthlyMeanU(:,	1:end-12),[30,12,16]),3,'omitnan');
                
                case 2
                Z = MR.AllYears.MonthlyMeanV;
                Zlims = 20;
                AllU = mean(reshape(MR.AllYears.MonthlyMeanV(:,1:end-12),[30,12,16]),3,'omitnan');
            end
            case 2
            switch WindDirection
                case 1
                Z = WACCM.All.Data.MonthlyMedU(:,(2004-1980)*12+1:end);
                Zlims = 50;
                AllU = mean(reshape(WACCM.All.Data.MonthlyMedU(:,(2005-1980)*12+1:end),[30,12,13]),3,'omitnan');
                
                case 2
                Z = WACCM.All.Data.MonthlyMedV(:,(2004-1980)*12+1:end);
                Zlims = 20;
                AllU = mean(reshape(WACCM.All.Data.MonthlyMedV(:,(2005-1980)*12+1:end),[30,12,13]),3,'omitnan');
            end %switch wind direction
            
        end % switch type


        %Position the monthly average at the 15th of each month
        switch type
            case 1; Time = datenum(datetime(2005,01,15):calmonths(1):datetime(datetime(2021,12,15)));
            case 2; Time = datenum(datetime(2004,01,15):calmonths(1):datetime(datetime(2017,12,15)));
        end
        
        % Subplot of long time series looped over two parts
            for i = 1:2 % repeat for two strips
                switch type
                    case 1; subplot(26,2,[19+(8*(i-1)):26+(8*(i-1))])
                    case 2; subplot(26,2,[37+(8*(i-1)):44+(8*(i-1))])
                end
                hold on
                
                contourf(Time,  walt, Z, [-Zlims-10:1:Zlims+10], 'LineColor','none'); 
                [C1,h1] = contour(Time,  walt, Z, [-Zlims:10:Zlims],'LineColor','black');
                [C3,h3] = contour(Time,  walt, Z, [0 0],'LineWidth', 2, 'LineColor','black');
                yline(100, 'LineWidth',1,'Alpha',1);
                yline(80, 'LineWidth',1,'Alpha',1);
                xline(datenum(2005+(i-1)*8,01,01), 'LineWidth',1,'Alpha',1);
                xline(datenum(2012+(i-1)*8,12,31), 'LineWidth',1,'Alpha',1);
                hold off

                colormap(cbrew('RdBu',100))
                set(gca, 'ydir','normal'); clim([-Zlims,Zlims])
                grey = [170 170 170]/255;
                set(gca,'color',grey);
                set(gcf,'color','w');
                set(gca,'TickDir','out','TickLength',[0.005,0.005],'LineWidth',1);
                set(gca, 'fontsize', 15);

                %Position xticks at the beginning of each month
                times = datenum(datetime(2005,01,01):calyears(1):datetime(datetime(2021,12,31)));
                xticks(times);
                % Offset the label to appear in the gap
                datetick('x','              yyyy','keepticks');

                ylim([80,100]);
                xlim([datenum(2005+(i-1)*8, 01,01),datenum(2012+(i-1)*8, 12,31)]);
                switch i
                    case 1
                        switch type
                            case 1
                                title('(c) Meteor radar wind','fontsize',15);
                                text(-0.11,-0.2,'HEIGHT (km)','Units','Normalized','Rotation',90,'Fontsize',18,'VerticalAlignment','middle', 'HorizontalAlignment','center'); 

                            case 2
                                title('(d) WACCM-X wind','fontsize',15);
                                cbar = colorbar;
                                cbar.Ticks = -60:20:60;
                                cbar.Ruler.MinorTick = 'on';
                                cbar.Ruler.MinorTickValues = -60:10:60;
                                cbar.TickDirection = 'out';
                                set(gca,'color',0*[1 1 1]); 
                                cbar.Label.FontSize = 15;
                                cbar.Label.String = 'Wind speed (ms^{-1})';
                                set(cbar,'YTick',[-60:10:60],'Fontsize',15);
                                set(cbar,'Position',[0.88 0.2 0.02 0.6]);
                        end 
                end
            end %i 




        % Plotting composite year
        AllU = [AllU AllU AllU];
        
        switch type
            case 1; subplot(26,2,[1,15]);
            case 2; subplot(26,2,[2,16]);
        end
        
        hold on
        contourf(1:36,  walt, AllU, [-Zlims-10:1:Zlims+10], 'LineColor','none'); 
        [C1,h1] = contour(1:36,  walt, AllU, [0:10:Zlims],'LineColor','black');
        [C2,h2] = contour(1:36,  walt, AllU, [-Zlims:10:0],'LineStyle','--', 'LineColor','black');
        [C3,h3] = contour(1:36,  walt, AllU, [0 0],'LineWidth', 2, 'LineColor','black');
        yline(100, 'LineWidth',1,'Alpha',1);
        yline(80, 'LineWidth',1,'Alpha',1);
        hold off

        switch type
            case 1; title(strcat('(a) Meteor radar average year'));            
            case 2; title(strcat('(b) WACCM-X average year'));
        end

        colormap(cbrew('RdBu',100))
        set(gca, 'ydir','normal'); clim([-Zlims,Zlims])
        set(gca,'TickDir','out','TickLength',[0.005,0.005],'LineWidth',1);
        set(gcf,'InvertHardCopy','off');
        set(gca, 'fontsize', 15);

        %Position xticks at the beginning of each month
        xlim([12.5,24.5])
        xline(24.5);
        xline(12.5);
        ylim([80,100]);
        yticks([80,90,100]);

        gapsize = 4;
        box off;
        clim([-Zlims,Zlims]);
        xticks(12.5:1:24.5);
        set(gca,'xticklabel', {[ blanks(gapsize) 'J'], [ blanks(gapsize) 'F'], [ blanks(gapsize) 'M'],[ blanks(gapsize) 'A'],[ blanks(gapsize) 'M'], [ blanks(gapsize) 'J'],[ blanks(gapsize) 'J'], [ blanks(gapsize) 'A'], [ blanks(gapsize) 'S'], [ blanks(gapsize) 'O'],[ blanks(gapsize) 'N'], [ blanks(gapsize) 'D'], ''});

    end %type
end % wind direction
