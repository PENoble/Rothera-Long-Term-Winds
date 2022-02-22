% Meteor radar plots for paper
clear all

mpdFiles_direc = 'C:\Users\pn399\OneDrive - University of Bath\Paper1\Figure code\Figure1\mpdFiles';

load(strcat(mpdFiles_direc,'\20050701_rothera-sk_mpd.mat'));

%Plotting topography in lat/lon
LonBox = [-90 -45]; 
LatBox = [-80 -55];

rothera_lon = -68.125;
rothera_lat = -67.568;

%% In lat/lon co-ordinate frame.
% background image
[Topo,Coasts,Image] = topo_v2(LonBox,LatBox,'Image','HRNatEarth');

f1 = figure();
set(f1,'color','w','position',[50 50 1000 700]);

vert_gap = 0.17;        horz_gap = 0.1;
lower_marg = 0.15;     upper_marg = 0.15;
left_marg = 0.1;      right_marg = 0.1;

rows = 2; cols = 2;

subplot = @(rows,cols,p) subtightplot (rows,cols,p,[vert_gap horz_gap],[lower_marg upper_marg],[left_marg right_marg]);

subplot(2,3,[1:2,4:5])
imagesc(Image.Lon,Image.Lat,Image.Map);
set(gca, 'ydir','normal');
% Coastline in lat/lon
hold on

C = nph_draw_coastline([LonBox(1) LatBox(1) ; LonBox(2) LatBox(2)],0,0,'noplot','color','k');
for i = 1:length(C)
    if length(C(i).Lon) > 100
        hold on; plot(C(i).Lon,C(i).Lat,'color','w','linewi',2);
        hold on; plot(C(i).Lon,C(i).Lat,'color','k','linewi',1.5);
    end
end

plot(rothera_lon,rothera_lat,'r.','MarkerSize',10);

title({'(a) Detected meteors above Rothera', '1st July 2005'},'fontsize',15);

xlim([-75,-54]);
ylim([-71,-62]);
xlabel('Longitude');
ylabel('Latitude');

%% Adding the meteors on top


% Meteor radar plots for paper from one day?
theta = MPD.Data.Azimuth;
range = km2deg(((MPD.Data.x).^2 + (MPD.Data.y).^2).^0.5);


[lat,lon] = reckon(rothera_lat, rothera_lon, range, theta);
plot(lon,lat,'b.','MarkerSize',3);


hold off

%%
% For the histograms we want to take data from a month
start_day = 20050700;
heights = [];
times = [];
for j = 1:29
    day = string(start_day + j);
    try
        load(strcat(mpdFiles_direc,'\',day,'_rothera-sk_mpd.mat'));
    catch
        disp(strcat('Cannot load',day));
    end
    heights = [heights; MPD.Data.Alt];
    times = [times; MPD.Data.Time];
end

%% Histograms

% figure('position',[50 50 1200 450]); 
subplot(2,3,3);
% Histogram of vertical MR distribution
% subplot(1,2,1)
histogram(heights,50,'EdgeColor',[51	161	201	]/255,'FaceColor',[51	161	201]/255);
set(gca,'view',[90 -90]);
xlim([70,110]);
xlabel('Height (km)');
ylabel('Number of meteors');
title({'(b) Meteor detection heights', 'July 2005'},'fontsize',15);
yticks([10000,20000]);
yticklabels({'10000','20000'});
set(gca,'TickLength',[0.02, 0.01]);

% Histogram of meteors over the day 
% subplot(1,2,2)
subplot(2,3,6);
histogram([hour(times) hour(times)+24],47,'EdgeColor',[51	161	201	]/255,'FaceColor',[51	161	201]/255);
ylabel('Number of meteors');
xlabel('Hour of day (UT)');
% xlim([3,24+3]);
% xticks([3,7,11,15,19,23,27]);
% xticklabels({'0','4','8','12','16','20','24'});
title({'(c) Meteor detection time', 'July 2005'},'fontsize',15);
xlim([0,24]);
xticks([0,4,8,12,16,20,24]);
set(gca,'TickLength',[0.02, 0.01]);

% % Meteors projected onto the ground
% figure('position',[50 50 600 600]); 
% polaraxes
% hold on
% % [28	134	238	]/255
% polarplot(MPD.Data.Azimuth, ((MPD.Data.x).^2 + (MPD.Data.y).^2).^0.5,'b.','MarkerSize',4);
% grid on
% thetaticks([0,90,180,270]);
% rticks([]);
% thetaticklabels({'E','N','W','S'});
% set(gca, 'FontSize',20);
% rlim([0,350]);
% % Coastline
% rothera_lon = -68.125796;
% rothera_lat = -67.568417;
% LonBox = [-70 -60]; 
% LatBox = [-70 -60];
% C = nph_draw_coastline([LonBox(1) LatBox(1) ; LonBox(2) LatBox(2)],0,0,'noplot','color','k');
% 
% 
% for i = 1:length(C)
% 
%     rothera_lat_copy = repmat(rothera_lat, size(C(i).Lat));
%     rothera_lon_copy = repmat(rothera_lon, size(C(i).Lon));
% 
%     [arclen,az] = distance(rothera_lat_copy, rothera_lon_copy, C(i).Lat, C(i).Lon);
%     arclen_km = deg2km(arclen);
%     
% 
%     polarplot(-deg2rad(az)+pi/2, arclen_km,'k','LineWidth',2);
% 
% end