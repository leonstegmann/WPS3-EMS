%% Data from Weather Station: Hvide Sande Oktober 2024
%
% DATA PROCESSING USED ONCE TO CREATE FIXED DATA SETS
%
%% Load FIles

cd C:\dev\WPS3-EMS\API_service\Datasets\

files = dir('*DMIOpenData_oktober24.csv'); % Get all .csv files in the current directory

% Preallocate cell array to store tables
tables = cell(1, length(files));

% Loop through each file and read into a table
for i = 1:length(files)
    % Generate full file path
    filePath = fullfile(files(i).folder, files(i).name);
    
    % Read CSV file into a table and store it in the cell array
    tables{i} = readtable(filePath,'Delimiter', ',');
    tables{i}.Properties.VariableNames = {'time', files(i).name(1:length(files(i).name)-26)};
  
    % Optional: Display the name of the file being read
    fprintf('Loaded file: %s\n', files(i).name);

end

clear files

%% Plot Full Oktober: Solar Wind Temperature humidity

close all

fig_weather = figure;
subplot(4,1,4)
x = tables{1,1}.time(:);
x = datetime(x, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone', 'UTC','Format','yyyy-MM-dd''T''HH');
y = tables{1,1}.Humidity(:);
plot(x,y);
xlabel('Time')
title('Humidity')
ylabel('%')
xticks([x(end):days(7):x(1)])
xlim('tight')


%Solar
subplot(4,1,1)
x = tables{1,2}.time(:);
x = datetime(x, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone', 'UTC','Format','yyyy-MM-dd''T''HH');
y = tables{1,2}.Solar(:);
plot(x,y);
title('Solar')
ylabel('W/m^2')
xticks([x(end):days(7):x(1)])
xlim('tight')

%Temperature
subplot(4,1,3)
x = tables{1,3}.time(:);
x = datetime(x, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone', 'UTC','Format','yyyy-MM-dd''T''HH');
y = tables{1,3}.Temperature(:);
plot(x,y);
title('Temperature')
ylabel('°C')
xticks([x(end):days(7):x(1)])
xlim('tight')

%Wind
subplot(4,1,2)
x = tables{1,4}.time(:);
x = datetime(x, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone', 'UTC','Format','yyyy-MM-dd''T''HH');
y = tables{1,4}.Wind(:);
plot(x,y);
title('Wind')
ylabel('m/s')
xticks([x(end):days(7):x(1)])
xlim('tight')


sgtitle('Weather Station Hvide Sande Oktober 2024')

disp('done')

%% Safe File
save_files false

if save_files
    % Stretch Figure
    figwidth = 8; % Width in inches
    figheight = 8; % Height in inches
    set(gcf, 'Units', 'Inches', 'Position', [1, 1, figwidth, figheight]);
    
    cd ../
    cd ../
    ResultsFolder = './Results/';
    
    saveas(fig_weather, append(ResultsFolder , 'Weather_HvideSande_Oktober24'),'epsc')
    saveas(fig_weather, append(ResultsFolder , 'Weather_HvideSande_Oktober24'),'pdf')
    
    disp('saved')

    clear figwidth figheight
    
end

