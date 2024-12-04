function cost = costFcn(fis,model,wsVarNames,varargin)
% Evaluate model, generate output, and find the cost.

%  Copyright 2021 The MathWorks, Inc.

% Update workspace variable for the controller.
assignin('base',wsVarNames(1),fis)

% Get simulation output. 
out = sim(model);

% Get Signals from simulation output.
%tout = out.Power.time;
%P_Load = out.Power.signals(1).values;
%P_PV = out.Power.signals(2).values;
%SOC = out.Power.signals(3).values;
%P_batt = out.Power.signals(4).values;

%Pgrid = out.Power.signals(5).values;
%Price = out.Power.signals(6);
%cost = sum(max(0,Pgrid)*Price); ;

tout =  out.tout; % time 
%Bill = out.logsout{1}.Values;
Bill = out.SmartMeter_Bill.signals(1).values; % == final Energy consumtion end of day
cost = Bill(end)

if isempty(varargin)
    return
end

% Update minimum cost data.
data = varargin{1};
if cost < data.MinCost
    data.MinCost = cost;
    data.fisTMin = fis;
    data.Tout = tout;
end

fprintf('Minimum cost = %f', data.MinCost)

end


% PLot Function
function plot_Results_HEMS(time,LOAD,PV,Price,SOC,Batt,Grid)
myfig = figure;
% LOAD & RES
subplot(5,1,1);
hold on;
plot(time, LOAD, '-', 'LineWidth', 2,'Color','black');
plot(time, PV, '-', 'LineWidth', 2,'Color',"#0072BD");
xlim([0, 24]);
xticks(0:24);
title('Load Consumption and RES Power Generation');
xlabel('Time (hours)');
ylabel('Power (kW)');
legend('Load Profile', 'RES Generation', 'Location', 'northwest');
grid on;

% PRICE
subplot(5,1,2);
stairs(time, Price, 'LineWidth', 2,'Color',	"#D95319"); % Orange
xlim([0, 24]);
xticks(0:24);
yticks(0:0.2:1);
title('Electricity Price');
xlabel('Time (hours)');
ylabel('DKK per kWh');
grid on;

% SOC
subplot(5,1,3);
plot(time, SOC, '-o', 'LineWidth', 2);
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

% GRID
subplot(5,1,4);
hold on
plot(time,Batt,'-', 'LineWidth', 2)
plot(time,Grid,'-', 'LineWidth', 2)
xlim([0, 24]);
xticks(0:24);
title('BAttery and Grid');
xlabel('Time (hours)');
ylabel('Power (kW)'); 
legend( 'Battery','Grid');%, 'Location', 'northeast', 'Orientation', 'vertical', 'Position', [0.75, 0.2, 0.05, 0.05]);
grid on;

end



