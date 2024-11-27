%% Data Generated at AAU with Load generator Tool
% DATA PROCESSING USED ONCE TO CREATE FIXED DATA SETS
%
% The Load profiles are in seconds and are 1 day long 
%   => 24*60*60 = 86400 samples
% They show Power in each Phase L1,L2,L3
%
%% Load FIles

cd C:\dev\WPS3-EMS\API_service\Datasets\Load_profiles\

files = dir('*_day.mat'); % Get all .csv files in the current directory

% Preallocate cell array to store tables
tables = cell(1, length(files));

% Loop through each file and read into a table
for i = 1:length(files)
    % Generate full file path
    filePath = fullfile(files(i).folder, files(i).name);
    
    % Read CSV file into a table and store it in the cell array
    tables{i} = load(filePath);

    % Optional: Display the name of the file being read
    fprintf('Loaded file: %s\n', files(i).name);

end

%% Create time array for plotting

% Define the start and end times
startTime = datetime('00:00:00', 'Format', 'HH:mm:ss');
endTime = datetime('23:59:59', 'Format', 'HH:mm:ss');

% Define the time step (e.g., 1 second)
timeStep = seconds(1); % Change to minutes(1) or hours(1) as needed

% Generate the datetime array
time_s_dt = startTime:timeStep:endTime;

%Create Final power Table
LoadProfiles = table();
LoadProfiles.time = time_s_dt'; % add time column

%% calculate Power for each Load profile

for i = 2:length(tables)
    L1 = tables{1,i}.L1(:,2);
    L2 = tables{1,i}.L2(:,2);
    L3 = tables{1,i}.L3(:,2);
    P = L1+L2+L3; 
    P = P/1000; % from W to kW

    % Add P as a new column to LoadProfiles with a dynamic name
    columnName = files(i-1).name(1:length(files(i).name)-4);
    LoadProfiles.(columnName) = P; % Dynamically add the column
    
end

clear files tables

%% PLot

close all

fig_ALLloadprofiles = figure;
columnNames = LoadProfiles.Properties.VariableNames;

for i = 2:numel(columnNames)
    subplot(length(columnNames)-1,1,i-1)
    x = LoadProfiles.time(:);
    y = LoadProfiles.(columnNames{i});
    plot(x,y);
    xlabel('Time')
    title(columnNames{i})
    ylabel('kW')
    xlim('tight')
end


%% Choose 2 loadprofiles

fig_loadprofiles = figure;

%Load profile 01
subplot(2,1,1)
x = datetime(2024,8, 1) + timeofday(LoadProfiles.time(:));
x.Format = 'HH:mm:ss';
y = LoadProfiles.LoadProfile01_summer_day(:);
plot(x,y);
xlabel('Time')
title('Summer day')
ylabel('kW')
xlim('tight')
ylim('tight')

%Load profile 02
subplot(2,1,2)
x = datetime(2024,2, 1) + timeofday(LoadProfiles.time(:));
x.Format = 'HH:mm:ss';
y = LoadProfiles.LoadProfile01_winter_day(:);
plot(x,y);
xlabel('Time')
title('Winter day')
ylabel('kW')
xlim('tight')
ylim('tight')

disp('done')

%% Safe processed Load Files

save_files = false;

% navigate back to main file
cd ../
cd ../


if save_files

DataFolder = './Datasets/';

% Save the table as a .mat file
save(append(DataFolder ,'LoadProfiles_1day.mat'), 'LoadProfiles');

% Save the table as a .csv file
writetable(LoadProfiles, append(DataFolder ,'LoadProfiles_1day.csv'));

disp('Files saved as .mat and .csv')

clear DataFolder

end

%% Safe Figures
save_figures = false;

if save_figures
    % Stretch Figure
    figwidth = 8; % Width in inches
    figheight = 8; % Height in inches
    set(gcf, 'Units', 'Inches', 'Position', [1, 1, figwidth, figheight]);

    cd ../
    ResultsFolder = './Results/';
    
    saveas(fig_loadprofiles, append(ResultsFolder , 'loadprofiles_1day'),'epsc')
    saveas(fig_loadprofiles, append(ResultsFolder , 'loadprofiles_1day'),'pdf')
    
    disp('Figures saved as PDF and eps')

    clear figwidth figheight ResultsFolder
    
end


