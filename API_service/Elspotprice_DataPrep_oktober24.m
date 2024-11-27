% Read in Data for Testing & Training

% my computer specific
cd  'C:\dev\WPS3-EMS\' 
cd .\API_service/Datasets\

%%
% Define the file path (make sure the path is correct)
filePath = 'Elspotprice_Energienet_oktober24.csv';

% Read the CSV file into a table
raw_elspotData = readtable(filePath,'ReadVariableNames', true); % in DKK per MWh

% Display the first few rows of the table to verify
head(raw_elspotData)

% Display Data Type of each Column 
varTypes = varfun(@class, raw_elspotData, 'OutputFormat', 'cell');
disp(table(raw_elspotData.Properties.VariableNames', varTypes', 'VariableNames', {'ColumnName', 'DataType'}));

% Check for NaN values in the table
nanExists = any(any(ismissing(raw_elspotData)));
if nanExists
    disp('The table contains NaN values.');
else
    disp('The table does not contain any NaN values.');
end

%% Loop through each column, check if it's a cell, and convert it to double if possible

% save to clean data set
elspotData = raw_elspotData;

% Loop through each column, check if it's a cell, and convert it to double if possible
for i = 1:width(elspotData)
    if iscell(elspotData{:, i})
        % Replace commas with dots in cell array strings, if they exist
        cleanedColumn = strrep(elspotData{:, i}, ',', '.');
        
        % Convert the cleaned strings to numeric
        numericColumn = str2double(cleanedColumn);

        % Check if the conversion was successful (no NaN for numeric values)
        if all(~isnan(numericColumn))
            % Convert the table column to a double array instead of a cell
            elspotData.(elspotData.Properties.VariableNames{i}) = numericColumn;
        else
            warning('Column %s contains non-numeric values and cannot be fully converted.', elspotData.Properties.VariableNames{i});
        end
    end
end

clear i numericColumn

% Display Data Type of each Column 
varTypes = varfun(@class, elspotData, 'OutputFormat', 'cell');
disp(table(elspotData.Properties.VariableNames', varTypes', 'VariableNames', {'ColumnName', 'DataType'}));

% Remove NaN values from SpotPriceDKK to ensure clean data
elspotData.SpotPriceDKK = elspotData.SpotPriceDKK(~isnan(elspotData.SpotPriceDKK));

% Convert from DKK/MWh to DKK/kWH
elspotData.SpotPriceDKK = elspotData.SpotPriceDKK/1000;
elspotData.SpotPriceEUR = elspotData.SpotPriceEUR/1000;

clear raw_elspotData cleanedColumn nanExists varTypes

%% Plot

fig_Elspotprice = figure;
x = elspotData.HourUTC(:);
x = datetime(x, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone', 'UTC','Format','yyyy-MM-dd''T''HH');
y = elspotData.SpotPriceDKK(:);
plot(x,y);
xlabel('Time')
xticks([x(end):days(7):x(1)])
xlim('tight')
title('El Spot Price')
ylabel('DKK/kWh')

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
    
    saveas(fig_Elspotprice, append(ResultsFolder , 'Elspotprice_Oktober24'),'epsc')
    saveas(fig_Elspotprice, append(ResultsFolder , 'Elspotprice_Oktober24'),'pdf')
    
    disp('saved in file')

    clear figwidth figheight

end


