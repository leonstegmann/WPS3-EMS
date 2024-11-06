% Rule-Based Control for HEMS with Battery and PV Integration
% Goal: Minimize cost by managing battery charging/discharging based on PV and prices

% my computer specific
cd  'C:\dev\WPS3-EMS\' 
cd .\API_service/Datasets\

clear; clc; close all;

%% Load FIles

files = dir('*.mat'); % Get all .mat files in the current directory

% Load each .mat file and extract structs into variables
for i = 1:length(files)
    data = load(files(i).name);     % Load the file    
    structNames = fieldnames(data);     % Get field names (struct variable names)
    
    % Extract each struct into its own variable
    for j = 1:length(structNames)
        assignin('base', structNames{j}, data.(structNames{j}));
    end
end

clear i j files data structNames


%% Parameters

time = 0:23;  % Time vector (hours)
price = price_hourly(:,2)';                     % Buying Price Electricit Grid
FIT = transpose(0.6*price' + randi([-6 6],24,1)/100); %Selling Price Electricit Grid
loadprofile =  loadprofile_hourly_24h(:,2)';        % Dynamic load profile (kW)
pv_generation = pv_production_cloudy_hourly_24h(:,2)'; % PV generation 


% Battery parameters
battery_capacity = 15;      % Battery capacity in kWh
battery_soc_initial = 40;   % Initial SOC in %
battery_max_charge = 5;     % Maximum charge rate (kW)
battery_max_discharge = 5;  % Maximum discharge rate (kW)
battery_efficiency = 0.95;  % Charging/discharging efficiency
battery_max_soc = 90;      %in %
battery_min_soc = 20;        %in %

%% Initalisation

% Grid power (positive = bought from grid, negative = sold to grid)
grid_power = zeros(1, length(time));    
BESS_power = zeros(1, length(time));    

% Battery SOC 
battery_soc_kWh = zeros(1, length(time));  % State of Charge (SOC) over time
battery_soc_kWh(1) = battery_soc_initial/100 *battery_capacity;         % Initial SOC

%% Rule-Based Control for Battery Management

for t = 1:length(time)
    current_load = loadprofile(t);  % Dynamic load at time t
    current_pv = pv_generation(t);  % PV generation at time t
    current_price = price(t);       % Electricity price at time t
    
    % Net load is load minus PV generation
    net_load = current_load - current_pv;  % Net load to be supplied

    % If net load is positive, we need to either discharge the battery or buy from grid
    if net_load > 0
        if battery_soc_kWh(t) > battery_min_soc/100 *battery_capacity % If battery has charge, discharge to meet load
            discharge_power = min([battery_max_discharge, net_load, (battery_soc_kWh(t) - battery_min_soc/100 *battery_capacity)]);  % Max discharge
            battery_soc_kWh(t+1) = battery_soc_kWh(t) - discharge_power * 1/battery_efficiency;  % Update SOC
            grid_power(t) = net_load - discharge_power;  % Remaining load taken from grid
            BESS_power(t) = discharge_power; % for Energy calc only
        else
            grid_power(t) = net_load;  % No battery charge left, so get all from grid
            battery_soc_kWh(t+1) = battery_soc_kWh(t);  % SOC remains unchanged
            BESS_power(t) = 0; % for Energy calc only            
        end
    else  % If net load is negative, we have excess PV power
        excess_pv = abs(net_load);  % Excess PV available for charging or selling
        if battery_soc_kWh(t) < battery_max_soc/100 *battery_capacity  % If battery not full, charge it
            charge_power = min([battery_max_charge, excess_pv, ( battery_max_soc/100 *battery_capacity - battery_soc_kWh(t))]);  % Max charge
            battery_soc_kWh(t+1) = battery_soc_kWh(t) + charge_power * battery_efficiency;  % Update SOC
            grid_power(t) = -(excess_pv - charge_power);  % Sell remaining PV to grid
            BESS_power(t) = -charge_power* battery_efficiency; % for Energy calc only
        else
            grid_power(t) = -excess_pv;  % Battery is full, sell all excess PV to grid
            battery_soc_kWh(t+1) = battery_soc_kWh(t);  % SOC remains unchanged
            BESS_power(t) = 0; % for Energy calc only            
        end
    end
end

%% Cost Calculation

% Total energy consumed & produced
E_load = sum(loadprofile);
E_PV =  sum(pv_generation);
% Total energy stored
E_BESS_dis = sum(max(BESS_power,0));
E_BESS_ch = sum(max(-BESS_power,0));
E_BESS_lost = (E_BESS_dis + E_BESS_dis)*(1-battery_efficiency);

% Total energy bought from the grid (kWh)
energy_bought = max(grid_power, 0);  % Only consider positive grid power (bought)
energy_sold = max(-grid_power, 0);  % Only consider negative grid power (sold)

% Cost of energy bought and revenue from energy sold
total_cost = sum(energy_bought .* price);  % Total cost in DKK
total_revenue = sum(energy_sold .* FIT);  % Total revenue from selling excess PV
net_cost = total_cost - total_revenue;  % Net cost (including revenue)

fprintf('------------ Rule-Based Control (RBC) ------------------\n')
fprintf('Total energy cost for the day: DKK %.2f\n', total_cost);
fprintf('Total revenue from selling excess energy: DKK %.2f\n', total_revenue);
fprintf('Net cost for the day: DKK %.2f\n', net_cost);

%% Plot Results

fig_RBC = figure;
sgtitle('Rule-Based Control')

% LOAD & RES
subplot(5,1,1);
hold on;
plot(time, loadprofile, '--', 'LineWidth', 2,'Color','black');
plot(time, pv_generation, '-', 'LineWidth', 2,'Color',"#0072BD");
xlim([0, 24]);
xticks(0:24);
title('Load Consumption and RES Power Generation');
xlabel('Time (hours)');
ylabel('Power (kW)');
legend('Load Profile', 'RES Generation', 'Location', 'northwest');
grid on;
str = sprintf('Enery produced: %0.1f kWh\nEnergy consumed: %0.1f kWh', E_PV, E_load);
annotation('textbox',[0.72 0.855 0.2 0.05],'String',str,'FitBoxToText','on','EdgeColor', 'black', 'FontSize',8,'FontWeight', 'bold', 'BackgroundColor',"white");

% PRICE
subplot(5,1,2);
hold on
stairs(time, price, 'LineWidth', 2,'Color',	"#D95319"); % Orange
stairs(time, FIT, '-','LineWidth', 2,'Color',[.2 .6 .5]);   % Green
xlim([0, 24]);
xticks(0:24);
yticks(0:0.2:1);
title('Electricity Price');
xlabel('Time (hours)');
ylabel('DKK per kWh');
legend('Buying Price','Selling Price', 'Location', 'northwest');
grid on;
hold off

% SOC
subplot(5,1,3);
plot(time, battery_soc_kWh(1:end-1)/battery_capacity *100, '-o', 'LineWidth', 2);
xlim([0, 24]);
xticks(0:24);
yticks(0:20:100);
ylim([0 100]);
yline(battery_min_soc,'LineWidth', 1.5)
yline(battery_max_soc,'LineWidth', 1.5)
title('Battery State of Charge (SOC)');
xlabel('Time (hours)');
ylabel('SOC in %');
str = sprintf('Battery (%dkWh)',battery_capacity);
legend(str, 'Location', 'northwest');
grid on;
str = sprintf('charged: %0.1f kWh\ndicharged: %0.1f kWh\nlost: %0.1f kWh', E_BESS_ch, E_BESS_dis,E_BESS_lost);
annotation('textbox',[0.78 0.54 0.2 0.05],'String',str,'FitBoxToText','on','EdgeColor', 'black', 'FontSize',8,'FontWeight', 'bold','BackgroundColor',"white");

% GRID
subplot(5,1,4);
b = bar(time+0.15, [energy_sold ; energy_bought]',0.3,'stacked');
b(1).FaceColor = [.2 .6 .5]; % SOld Energy = green  
xlim([0, 24]);
xticks(0:24);
title('Bought and Sold Grid Power');
xlabel('Time (hours)');
ylabel('Energy (kWh)'); 
legend( 'Sold to Grid','Bought from Grid');%, 'Location', 'northeast', 'Orientation', 'vertical', 'Position', [0.75, 0.2, 0.05, 0.05]);
grid on;

% Text below Plots
str = 'Cost caluclation over the whole time period:';
annotation('textbox', [0.13 0.14 0.8 0.1], ... % dim = [x y w h]
    'String', str,'FontWeight', 'bold','EdgeColor', 'none')
str = sprintf('Revenue:           DKK    ,    Cost:           DKK          =>     Total Cost:    %0.2f DKK', net_cost);
annotation('textbox', [0.15 0.10 0.8 0.1], ... % dim = [x y w h]
    'String', str,'FontWeight', 'bold','EdgeColor', 'none')
str = sprintf('%0.2f',total_revenue);
annotation('textbox', [0.24 0.10 0.1 0.1], 'Color', [.2 .6 .5],... % dim = [x y w h]
    'String', str,'FontWeight', 'bold','EdgeColor', 'none')
str = sprintf('%0.2f',total_cost);
annotation('textbox', [0.42 0.10 0.1 0.1], 'Color', "#D95319",... % dim = [x y w h]
    'String', str,'FontWeight', 'bold','EdgeColor', 'none')
annotation( 'line' , [0.59 0.79] , [0.17 0.17] )
annotation( 'line' , [0.59 0.79] , [0.165 0.165] )

% Stretch Figure
width = 8; % Width in inches
height = 8; % Height in inches
set(gcf, 'Units', 'Inches', 'Position', [1, 1, width, height]);

%% post processing

cd ../
cd ../
ResultsFolder = './Results/';

% Export file
saveas(fig_RBC, append(ResultsFolder , 'RBC_24h'),'epsc')
saveas(fig_RBC, append(ResultsFolder , 'RBC_24h'),'pdf')


