%%

InstallationCost = 100e3 ; % DKK
ReplacementCosts = 0.5 * InstallationCost; % DKK
TotalInstallationCost = InstallationCost + ReplacementCosts; % DKK
MaintenanceCostsYearly = 0.02*TotalInstallationCost; % DKK/year
SystemLifespan = 30 ; % years
EnergyProducedDaylyPerkWp = 3.205; %kWh/day per kWp
SolarkWp = 10; % kWp
EnergyProducedYearly = 365 * EnergyProducedDaylyPerkWp * SolarkWp; % KWh/year

% Calculating  the Levelized Cost of Electricity (LCOE)
LCOE = (TotalInstallationCost + MaintenanceCostsYearly * SystemLifespan) / (EnergyProducedYearly * SystemLifespan) ;% dkk/kWh

% Display Results
fprintf("\nThe PV + Battery system costs %0.3f DKK/kWh\n",LCOE)



