%% Data from Weather Station: Hvide Sande Oktober 2024
%
% DATA PROCESSING USED ONCE TO CREATE FIXED DATA SETS
%
%% Load FIles

cd C:\dev\WPS3-EMS\API_service\
cd Datasets\

files = dir('*DMIOpenData_oktober24.csv'); % Get all .csv files in the current directory

cd ..

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
%%
WeatherData_table = table();
% ADD COLUMN Time AND HUMIDITY
WeatherData_table = tables{1,1};
% ADD COLUMN  SOLAR
columnName =tables{1,2}.Properties.VariableNames{2};
WeatherData_table.(columnName) = tables{1,2}.Solar;
% ADD COLUMN TEMP
columnName =tables{1,3}.Properties.VariableNames{2};
WeatherData_table.(columnName) = tables{1,3}.Temperature;
% ADD COLUMN WIND
columnName =tables{1,4}.Properties.VariableNames{2};
WeatherData_table.(columnName) = tables{1,4}.Wind;

clear files tables


%% Plot Full Oktober: Solar Wind Temperature humidity

close all

fig_weather = figure;
subplot(4,1,4)
x = WeatherData_table.time(:);
x = datetime(x, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone', 'UTC','Format','yyyy-MM-dd''T''HH');
y = WeatherData_table.Humidity(:);
plot(x,y);
xlabel('Time')
title('Humidity')
ylabel('%')
xticks([x(end):days(7):x(1)])
xlim('tight')


%Solar
subplot(4,1,1)
x = WeatherData_table.time(:);
x = datetime(x, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone', 'UTC','Format','yyyy-MM-dd''T''HH');
y = WeatherData_table.Solar(:);
plot(x,y);
title('Solar')
ylabel('W/m^2')
xticks([x(end):days(7):x(1)])
xlim('tight')

%Temperature
subplot(4,1,3)
x = WeatherData_table.time(:);
x = datetime(x, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone', 'UTC','Format','yyyy-MM-dd''T''HH');
y = WeatherData_table.Temperature(:);
plot(x,y);
title('Temperature')
ylabel('°C')
xticks([x(end):days(7):x(1)])
xlim('tight')

%Wind
subplot(4,1,2)
x = WeatherData_table.time(:);
x = datetime(x, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone', 'UTC','Format','yyyy-MM-dd''T''HH');
y = WeatherData_table.Wind(:);
plot(x,y);
title('Wind')
ylabel('m/s')
xticks([x(end):days(7):x(1)])
xlim('tight')


sgtitle('Weather Station Hvide Sande Oktober 2024')

disp('done')

%% Safe processed Files

save_files = true;

if save_files

DataFolder = './Datasets/';

% Save the table as a .mat file
save(append(DataFolder ,'WeatherData_okt24.mat'), 'WeatherData_table');

disp('Files saved as .mat ')

clear DataFolder

end


%% Safe Figures

save_figures = true;

if save_figures
    % Stretch Figure
    figwidth = 8; % Width in inches
    figheight = 8; % Height in inches
    set(gcf, 'Units', 'Inches', 'Position', [1, 1, figwidth, figheight]);
    
    ResultsFolder = './Results/';
    
    saveas(fig_weather, append(ResultsFolder , 'Weather_HvideSande_Oktober24'),'epsc')
    saveas(fig_weather, append(ResultsFolder , 'Weather_HvideSande_Oktober24'),'pdf')
    
    disp('Figures saved as PDF and eps')

    clear figwidth figheight
    
end

