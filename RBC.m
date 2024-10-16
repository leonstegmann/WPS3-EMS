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
loadprofile =  loadprofile_hourly(:,2)';        % Dynamic load profile (kW)
pv_generation = pv_production_cloudy_24h(:,2)'; % PV generation 


% Battery parameters
battery_capacity = 12;      % Battery capacity in kWh
battery_soc = zeros(1, length(time));  % State of Charge (SOC) over time
battery_soc(1) = 3;         % Initial SOC
battery_max_charge = 5;     % Maximum charge rate (kW)
battery_max_discharge = 5;  % Maximum discharge rate (kW)
battery_efficiency = 0.95;  % Charging/discharging efficiency
battery_max_soc = 100;      %in %
battery_min_soc = 0;        %in %

% Grid power (positive = bought from grid, negative = sold to grid)
grid_power = zeros(1, length(time));    

%% Rule-Based Control for Battery Management

for t = 1:length(time)
    current_load = loadprofile(t);  % Dynamic load at time t
    current_pv = pv_generation(t);  % PV generation at time t
    current_price = price(t);       % Electricity price at time t
    
    % Net load is load minus PV generation
    net_load = current_load - current_pv;  % Net load to be supplied

    % If net load is positive, we need to either discharge the battery or buy from grid
    if net_load > 0
        if battery_soc(t) > battery_min_soc/100 *battery_capacity  % If battery has charge, discharge to meet load
            discharge_power = min([battery_max_discharge, net_load, battery_soc(t)]);  % Max discharge
            battery_soc(t+1) = battery_soc(t) - discharge_power * (1 / battery_efficiency);  % Update SOC
            grid_power(t) = net_load - discharge_power;  % Remaining load taken from grid
        else
            grid_power(t) = net_load;  % No battery charge left, so get all from grid
            battery_soc(t+1) = battery_soc(t);  % SOC remains unchanged
        end
    else  % If net load is negative, we have excess PV power
        excess_pv = abs(net_load);  % Excess PV available for charging or selling
        if battery_soc(t) < battery_max_soc/100 *battery_capacity  % If battery not full, charge it
            charge_power = min([battery_max_charge, excess_pv, (battery_capacity - battery_soc(t))]);  % Max charge
            battery_soc(t+1) = battery_soc(t) + charge_power * battery_efficiency;  % Update SOC
            grid_power(t) = -(excess_pv - charge_power);  % Sell remaining PV to grid
        else
            grid_power(t) = -excess_pv;  % Battery is full, sell all excess PV to grid
            battery_soc(t+1) = battery_soc(t);  % SOC remains unchanged
        end
    end
end

%% Cost Calculation

% Total energy bought from the grid (kWh)
energy_bought = max(grid_power, 0);  % Only consider positive grid power (bought)
energy_sold = max(-grid_power, 0);  % Only consider negative grid power (sold)

% Cost of energy bought and revenue from energy sold
total_cost = sum(energy_bought .* price);  % Total cost in $
total_revenue = sum(energy_sold .* price);  % Total revenue from selling excess PV
net_cost = total_cost - total_revenue;  % Net cost (including revenue)

fprintf('Total energy cost for the day: DKK %.2f\n', total_cost);
fprintf('Total revenue from selling excess energy: DKK %.2f\n', total_revenue);
fprintf('Net cost for the day: DKK %.2f\n', net_cost);

%% Plot Results

fig_RBC = figure;

subplot(4,1,1);
plot(time, loadprofile, '--', 'LineWidth', 2);
hold on;
plot(time, pv_generation, '-o', 'LineWidth', 2);
xlim([0, 24]);
xticks(0:24);
title('Load Consumption and PV Generation');
xlabel('Time (hours)');
ylabel('Power (kW)');
legend('Load Profile', 'PV Generation');
grid on;

subplot(4,1,2);
stairs(time, price, 'LineWidth', 2,'Color','black');
xlim([0, 24]);
xticks(0:24);
title('Electricity Price');
xlabel('Time (hours)');
ylabel('DKK per kWh');
legend('Buying Price');
grid on;


subplot(4,1,3);
plot(time, battery_soc(1:end-1)/battery_capacity *100, '-o', 'LineWidth', 2);
xlim([0, 24]);
xticks(0:24);
yticks(0:20:100);
yline(battery_min_soc,'LineWidth', 1.5)
title('Battery State of Charge (SOC)');
xlabel('Time (hours)');
ylabel('SOC in %');
legend('Battery (12kWh)');
grid on;

subplot(4,1,4);
b = bar(time+0.15, [energy_sold ; energy_bought]',0.3,'stacked');
b(1).FaceColor = [.2 .6 .5]; % SOld Energy = green
xlim([0, 24]);
xticks(0:24);
title('Bought and Sold Grid Power');
xlabel('Time (hours)');
ylabel('Energy (kWh)'); 
legend( 'Sold to Grid','Bought from Grid');%, 'Location', 'northeast', 'Orientation', 'vertical', 'Position', [0.75, 0.2, 0.05, 0.05]);
grid on;

% Stretch Figure
width = 9; % Width in inches
height = 15; % Height in inches
set(gcf, 'Units', 'Inches', 'Position', [1, 1, width, height]);

%% post processing
cd ../
cd ../
ResultsFolder = './Results/';

% Export file
saveas(fig_RBC, append(ResultsFolder , 'RBC_24h'),'epsc')
saveas(fig_RBC, append(ResultsFolder , 'RBC_24h'),'pdf')


