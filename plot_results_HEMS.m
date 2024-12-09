%% Plot Results from HEMS model

%function plot_Results_HEMS(time,LOAD,PV,Price,SOC,Batt,Grid)

%cd C:\dev\WPS3-EMS\FuzzyLogicController\
%model = 'Training_Model_compactHEMS';
%load_system(model)
%out = sim(model); % Run simulation now. 

%%

% get Bill
Bill_time = out.SmartMeter_Bill.time;
Bill = out.SmartMeter_Bill.signals.values(:,1);

% Get Signals from simulation output.
time = out.PowerScope.time;
Load = out.PowerScope.signals.values(:,1);
PV = out.PowerScope.signals.values(:,2);
SOC = out.PowerScope.signals.values(:,3);
Batt = out.PowerScope.signals.values(:,4);
Grid = out.PowerScope.signals.values(:,5);
Price = out.PowerScope.signals.values(:,6);

%get parameters from Workspace
battery_capacity = evalin('base', 'battery_capacity');
battery_min_soc = evalin('base', 'battery_min_soc');
battery_max_soc = evalin('base', 'battery_max_soc');
%% Create Figure
fig_PowerScope_Results = figure;

% LOAD & RES
subplot(5,1,1);
hold on;
plot(time, Load, '-', 'LineWidth', 2,'Color','black');
plot(time, PV, '-', 'LineWidth', 2,'Color',"#0072BD");
xlim([0, 24]);
xticks(0:24);
ylim 'padded'
title('Load Power Consumption and RES Power Generation');
xlabel('Time (hours)');
ylabel('Power (kW)');
legend('Load', 'PV', 'Location', 'northwest');
grid on;
box on

% PRICE
subplot(5,1,2);
stairs(time, Price, 'LineWidth', 2,'Color',	"#D95319"); % Orange
xlim([0, 24]);
xticks(0:24);
yticks(0:0.2:1);
ylim 'padded'
hold on 
yline(mean(Price),'-.',Color='blue',LineWidth=0.9)
yline(mean(Price)+std(Price),'--')
yline(mean(Price)-std(Price),'--','HandleVisibility','off')
title('Electricity Price');
xlabel('Time (hours)');
ylabel('DKK per kWh');
legend('price','\mu','\pm 1\sigma','Location', 'northwest')
grid on;
box on

% SOC
subplot(5,1,3);
plot(time, SOC, '-', 'LineWidth', 3);
xlim([0, 24]);
xticks(0:24);
yticks(0:20:100);
ylim 'padded'
yline(battery_min_soc,'--','LineWidth', 1.5)
yline(battery_max_soc,'--','LineWidth', 1.5)
title('Battery State of Charge (SOC)');
xlabel('Time (hours)');
ylabel('SOC in %');
str = sprintf('Battery (%dkWh)',battery_capacity);
legend(str, 'Location', 'northwest');
grid on;
box on

% GRID
subplot(5,1,4);
hold on
plot(time,Batt,'-', 'LineWidth', 2)
plot(time,Grid,'-', 'LineWidth', 2)
xlim([0, 24]);
xticks(0:24);
ylim 'padded'
title('BAttery and Grid');
xlabel('Time (hours)');
ylabel('Power (kW)'); 
legend( 'Battery','Grid','Location', 'southeast');%, 'Location', 'northeast', 'Orientation', 'vertical', 'Position', [0.75, 0.2, 0.05, 0.05]);
grid on;
box on

%% Cost Calculation

% Total energy consumed & produced
E_load = sum(Load)*Ts;
E_PV =  sum(PV)*Ts;

% Total energy stored
E_BESS_dis = sum(max(Batt,0))*Ts;
E_BESS_ch = sum(min(Batt,0))*Ts;
total_Energy_throughput_BESS = sum(abs(Batt))*Ts; 
E_BESS_lost = (E_BESS_dis + E_BESS_dis)*(1-battery_efficiency);

% Total energy bought from the grid (kWh)
energy_bought = sum(max(Grid, 0))*Ts;  % Only consider positive grid power (bought)
energy_sold = abs(sum(min(Grid, 0))*Ts);  % Only consider negative grid power (sold)

% Cost of energy bought and revenue from energy sold
total_cost = Bill(end); % or = sum(energy_bought .* Price)*Ts;  % Total cost in DKK

fprintf('------------ Rule-Based Control (RBC) ------------------\n')
fprintf('Total Energy cost for the day: DKK %.2f\n', total_cost);
fprintf('Total Energy bought from Grid: kWh %.2f\n', energy_bought);
fprintf('Total Power Consumption of Load: kWh %.2f\n', E_load);
fprintf('Total Power Generation of RES: kWh %.2f\n', E_PV);
fprintf('Total Excess unused Energy of RES: kWh %.2f\n', energy_sold);
fprintf('Energy throughput Battery over the day: kWh %.2f\n', total_Energy_throughput_BESS);

% Text below Plots
str = 'Stats:';
annotation('textbox', [0.13 0.14 0.8 0.1], ... % dim = [x y w h]
    'String', str,'FontWeight', 'bold','EdgeColor', 'none')
str = sprintf([ ...
    'Power consumption (Load):      %0.1f kWh   ,   Power generation (PV):          %0.1f kWh' ...
    '\nUnused energy (PV):                  %0.1f kWh     ,   Energy throughput (BESS):   %0.1f kWh' ...
    '\nEnergy bought (Grid):                %0.1f kWh     ,   Final daily bill (spot price):     %0.2f DKK'] ...
    ,E_load, E_PV,energy_sold, total_Energy_throughput_BESS, energy_bought, total_cost);
annotation('textbox', [0.14 0.11 0.8 0.1], ... % dim = [x y w h]
    'String', str,'FontWeight', 'bold','EdgeColor', 'none')
% double underline 
annotation( 'line' , [0.75 0.84] , [0.14 0.14] ) % from[x1,x2]to[y1,y2]
annotation( 'line' , [0.75 0.84] , [0.135 0.135] ) % from[x1,x2]to[y1,y2]

% Stretch Figure
figwidth = 8; % Width in inches
figheight = 8; % Height in inches
set(gcf, 'Units', 'Inches', 'Position', [1, 1, figwidth, figheight]);

%% Safe Figures?
save_figures = false;

%FileName = 'PowerScope_Results_RBC';
%FileName = 'PowerScope_Results_FLC';
FileName = 'PowerScope_Results_Testing';

if save_figures
    ResultsFolder = './Results/';
 
    saveas(fig_PowerScope_Results,  append(ResultsFolder ,FileName),'epsc')
    saveas(fig_PowerScope_Results,  append(ResultsFolder ,FileName),'pdf')
    
    disp('\nFigures saved as PDF and eps')
end



%end