% Read in Data for Testing & Training

% my computer specific
cd  'C:\dev\WPS3-EMS\' 
cd .\API_service/Datasets\


% Define the file path (make sure the path is correct)
filePath = struct();
filePath(1).name = 'Loadprofile_SingleFamHousehold_nonElHeating_Energienet_oktober24.csv';
filePath(2).name = 'Loadprofile_SingleFamHousehold_ElHeating_Energienet_oktober24';

clear filePath1 filePath2

%% Loop through each column, check if it's a cell, and convert it to double if possible
loadData_okt24 = struct();%'nonELHeating',{},'ELHeating',{});

% Read the CSV file into a table
for j = 1:length(filePath)

raw_loadData = readtable(filePath(j).name,'ReadVariableNames', true);

% Display the first few rows of the table to verify
head(raw_loadData)

% Display Data Type of each Column 
varTypes = varfun(@class, raw_loadData, 'OutputFormat', 'cell');
disp(table(raw_loadData.Properties.VariableNames', varTypes', 'VariableNames', {'ColumnName', 'DataType'}));

% Check for NaN values in the table
nanExists = any(any(ismissing(raw_loadData)));
if nanExists
    disp('The table contains NaN values.');
else
    disp('The table does not contain any NaN values.');
end


% save to clean data set
loadData = raw_loadData;

% Loop through each column, check if it's a cell, and convert it to double if possible
for i = 1:width(loadData)
    if iscell(loadData{:, i})
        % Replace commas with dots in cell array strings, if they exist
        cleanedColumn = strrep(loadData{:, i}, ',', '.');
        
        % Convert the cleaned strings to numeric
        numericColumn = str2double(cleanedColumn);

        % Check if the conversion was successful (no NaN for numeric values)
        if all(~isnan(numericColumn))
            % Convert the table column to a double array instead of a cell
            loadData.(loadData.Properties.VariableNames{i}) = numericColumn;
        else
            warning('Column %s contains non-numeric values and cannot be fully converted.', loadData.Properties.VariableNames{i});
        end
    end
end

clear i numericColumn

% Display Data Type of each Column 
varTypes = varfun(@class, loadData, 'OutputFormat', 'cell');
disp(table(loadData.Properties.VariableNames', varTypes', 'VariableNames', {'ColumnName', 'DataType'}));

% Remove NaN values from SpotPriceDKK to ensure clean data
loadData.ConsumptionkWh = loadData.ConsumptionkWh(~isnan(loadData.ConsumptionkWh));

% Add Tables into struct
tableName = filePath(j).name(1:length(filePath(j).name)-25);
loadData_okt24(j).name = tableName;
loadData_okt24(j).data = loadData; % Dynamically add the column

end

clear raw_loadData cleanedColumn nanExists varTypes

%% Plot

fig_Loadprofile_okt24 = figure;
subplot(2,1,1)
x = loadData_okt24(1).data.HourUTC(:);
x = datetime(x, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone', 'UTC','Format','yyyy-MM-dd''T''HH');
y = loadData_okt24(1).data.ConsumptionkWh(:);
plot(x,y);
xlabel('Time')
xticks([x(end):days(7):x(1)])
xlim('tight')
title('Power Consumption of Housings with non El Heating  ')
ylabel('kWh')

subplot(2,1,2)
x = loadData_okt24(2).data.HourUTC(:);
x = datetime(x, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone', 'UTC','Format','yyyy-MM-dd''T''HH');
y = loadData_okt24(2).data.ConsumptionkWh(:);
plot(x,y);
xlabel('Time')
xticks([x(end):days(7):x(1)])
xlim('tight')
title('Power Consumption of Housings with El Heating ')
ylabel('kWh')

%% Safe processed Loadprofile Files
cd ..

save_files = true;

if save_files

DataFolder = './Datasets/';

% Save the table as a .mat file
save(append(DataFolder ,'loadData_okt24.mat'), 'loadData_okt24');

disp('File saved as .mat ')

clear DataFolder

end

%% Safe Figures
save_figures = true;

if save_figures
    figure(fig_Loadprofile_okt24) % choose as active fig
    % Stretch Figure
    figwidth = 8; % Width in inches
    figheight = 8; % Height in inches
    set(gcf, 'Units', 'Inches', 'Position', [1, 1, figwidth, figheight]);
    
    ResultsFolder = './Results/';
    
    saveas(fig_Loadprofile_okt24, append(ResultsFolder , 'Loadprofile_okt24'),'epsc')
    saveas(fig_Loadprofile_okt24, append(ResultsFolder , 'fig_Loadprofile_okt24'),'pdf')
    
    disp('Figures saved as PDF and eps')

    clear figwidth figheight
    
end

