% Statistics on Electricity Spot Sprice in Demnmark over 2023 and 2024
% 
% callutales and plots price distribution over a year and monthly

%% navigate to location and choose Data

cd C:\dev\WPS3-EMS\El_price_Analysis

DataFolderPath = '.\Data\';
filePath = append(DataFolderPath , 'Elspotprices_hourly_01_2022-11_2024.csv');

%% Prepare Data

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

%% filter out specific time period

% Define the start and end dates for 2023 with hourly precision
startDate = datetime(2023, 1, 1, 0, 0, 0);
endDate = datetime(2023, 12, 31, 23, 0, 0);  % Last hour of 2023

% Filter rows where HourDK is within the year 2023
elspot2023 = elspotData(elspotData.HourDK >= startDate & elspotData.HourDK <= endDate, :);

% Define the start and end dates for 2023 with hourly precision
startDate = datetime(2023, 11, 13, 0, 0, 0);
endDate = datetime(2024, 11, 13, 23, 0, 0);  % Last hour of 2023

% Filter rows where HourDK is within the year 2023
elspot2024 = elspotData(elspotData.HourDK >= startDate & elspotData.HourDK <= endDate, :);

clear startDate endDate

%% Histogram to show Distribution over whole year 202 and 2024

% Calculate the mean and standard deviation for 2023 and 2024 data
mean2023 = mean(elspot2023.SpotPriceDKK, 'omitnan');
mean2024 = mean(elspot2024.SpotPriceDKK, 'omitnan');

% Create a histogram of SpotPriceDKK
fig_elspot_histogram = figure;
histogram(elspot2023.SpotPriceDKK,'BinWidth', 0.05,'Normalization','pdf'); 
hold on 
histogram(elspot2024.SpotPriceDKK,'BinWidth', 0.05,'Normalization','pdf'); 


% Plot vertical lines for mean and standard deviations for 2023
xline(mean2023, '--', 'Color', 'blue', 'LineWidth', 1.5, 'Label', '\mu_{23}','LabelHorizontalAlignment', 'center');
xline(mean2024, '--', 'Color', 'red', 'LineWidth', 1.5, 'Label', '\mu_{24}','LabelHorizontalAlignment', 'center');

% Display the mean and sigma values below the x-axis
yPos =2.1;  % Position just below the x-axis
text(mean2023+0.02, yPos, sprintf('%.2f', mean2023), 'Color', 'blue', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
text(mean2024-0.02, yPos, sprintf('%.2f', mean2024), 'Color', 'red', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');


% Customize the plot
%title('P Spot Prices DK1 for 2023 and 2024');
xlim([-0.5 2])
legend('2023' ,'2024')
xlabel('Spot Price (DKK/kWh)');
ylabel('PDF');
hold off

% Plot histogram 2024
fig_elspot_histogram2024 = figure;
%title('Probability density function (PDF) Spot Prices DK1 for 2024');
h = histogram(elspot2024.SpotPriceDKK, 'Normalization','pdf');
hold on
xline(mean2024, '--', 'Color', 'blue', 'LineWidth', 1.5, 'Label', '\mu','LabelHorizontalAlignment', 'center');
text(mean2024-0.02, max(h.Values)*1.07, sprintf('%.2f', mean2024), 'Color', 'blue', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
xlabel('Electricity Spot Price (DKK/kWh)');
ylabel('PDF');
legend('2024 (DK1)')
xlim([-0.5 2])

clear h yPos mean2023 mean2024

%% Distrubution hourly over 2024

% Extract the hour from the HourDK column
elspot2023.Hour = hour(elspot2023.HourDK);
elspot2024.Hour = hour(elspot2024.HourDK);

% Group by hour and calculate the average price for each hour across the year
hourlyAverage2023 = varfun(@mean, elspot2023, 'InputVariables', 'SpotPriceDKK', 'GroupingVariables', 'Hour');
hourlyAverage2024 = varfun(@mean, elspot2024, 'InputVariables', 'SpotPriceDKK', 'GroupingVariables', 'Hour');


% Plot the average spot price for each hour
fig_hourlyAveragePrice = figure;
plot(hourlyAverage2023.Hour, hourlyAverage2023.mean_SpotPriceDKK, '-',LineWidth=1.5);
hold on
plot(hourlyAverage2024.Hour, hourlyAverage2024.mean_SpotPriceDKK, '-',LineWidth=1.5);

legend('2023' ,'2024')
%title('Average Spot Price by Hour for 2023');
xlabel('Hour of Day');
ylabel('Average Electricity Spot Price (DKK/kWh)');
xticks(0:23); grid on;

clear hourlyAverage2023 hourlyAverage2024

%%
% Assuming elspot2023 is already loaded and contains hourly data
% Extract the hour from the HourDK column
elspot2024.Hour = hour(elspot2024.HourDK);

% Group by hour and calculate the mean and standard deviation
hourlyStats = groupsummary(elspot2024, 'Hour', {'mean', 'std'}, 'SpotPriceDKK');
meanPrice = hourlyStats.mean_SpotPriceDKK;
stdPrice = hourlyStats.std_SpotPriceDKK;

% Define x-axis (hours of the day)
time_h = 0:23;

% Calculate upper and lower bounds for 1σ and 2σ
upper1Sigma = meanPrice + stdPrice;
lower1Sigma = meanPrice - stdPrice;
upper2Sigma = meanPrice + 2 * stdPrice;
lower2Sigma = meanPrice - 2 * stdPrice;

% Plot the mean line
fig_pdf_price2024_hourly = figure;
plot(time_h, meanPrice, 'LineWidth', 2, 'Color', [0 0.2 0.6]); % Dark blue for mean line
hold on;
% Plot shaded regions for 1σ and 2σ intervals
fill([time_h, fliplr(time_h)], [upper2Sigma; flipud(lower2Sigma)], [0.7 0.8 1], 'FaceAlpha', 0.4, 'EdgeColor', 'none'); % 2σ (90% CI)
fill([time_h, fliplr(time_h)], [upper1Sigma; flipud(lower1Sigma)], [0.3 0.5 0.8], 'FaceAlpha', 0.6, 'EdgeColor', 'none'); % 1σ (50% CI)

% Customize plot appearance
%$title('Probability density function of Spot Price by Hour with Confidence Intervals');
xlabel('Hour of Day');
ylabel('Distribution of Electricity Spot Price 2024 (DKK/kWh)');
xlim tight;
xticks(0:23); % Label each hour on the x-axis
legend({'\mu ', '±1\sigma (~68%)', '±2\sigma (~95%)'}, 'Location', 'best');
grid on;
hold off;

clear hourlyStats stdPrice upper1Sigma lower1Sigma upper2Sigma lower2Sigma time_h

%% Average Monthy and weekly

% Extract the month from the HourDK column
elspot2024.Month = month(elspot2024.HourDK);

% Create a box plot of SpotPriceDKK by month
fig_monthly_Boxplot2024 =figure;
% Title('Boxplot)
boxplot(elspot2024.SpotPriceDKK, elspot2024.Month);
xlabel('Month');
ylabel('Electricity Spot Price (DKK/kWh)');
set(gca, 'XTickLabel', {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'});
grid on;


%% Export files
save_files = true;

if save_files
    
    % Define the start and end times
    startTime = datetime('00:00:00', 'Format', 'HH:mm:ss');
    endTime = datetime('23:00:00', 'Format', 'HH:mm:ss');
    timeStep = hours(1); % Define the time step
    time_h_dt = startTime:timeStep:endTime; % Generate the datetime array
    % as .mat
    MeanElPrice = struct('time', time_h_dt, 'meanPrice2024', meanPrice);
    save(append(DataFolderPath ,'mean_hourly_price_2024.mat'), 'MeanElPrice');
    % as csv
    meanPrice_table = table();
    meanPrice_table.time = time_h_dt';
    meanPrice_table.('meanPrice') = meanPrice;
    writetable(meanPrice_table, append(DataFolderPath ,'mean_hourly_price_2024.csv'));
    %writecell([{'time', 'mean price'}; num2cell([time_h_dt, meanPrice])], append(DataFolderPath ,'mean_hourly_price_2024.csv'));
    
    clear startTime endTime timeStep meanPrice

    disp('Files saved as .mat and .csv')

end

%% Export figures
save_figures = true;

if save_figures

    ResultsFolder = './Results/';
    
    % Set the figure size (adjust as needed for your document layout)
    figwidth = 6; % width in inches (adjust this)
    figheight = 4; % height in inches (adjust this)

    % Figure 1 Histogram
    saveas(fig_elspot_histogram,  append(ResultsFolder ,'histogram_elspot2023u24','epsc'))
    saveas(fig_elspot_histogram,  append(ResultsFolder ,'histogram_elspot2023u24','pdf'))

    saveas(fig_elspot_histogram2024,  append(ResultsFolder ,'Histogram_elspotPrice_2024','epsc'))
    saveas(fig_elspot_histogram2024,  append(ResultsFolder ,'Histogram_elspotPrice_2024','pdf'))
    
    % Figure 2 hourly average Price
    figure(fig_hourlyAveragePrice)
    set(gcf, 'Units', 'Inches', 'Position', [1, 1, figwidth, figheight]);
    
    saveas(fig_hourlyAveragePrice,  append(ResultsFolder ,'hourlyAveragePrice','epsc'))
    saveas(fig_hourlyAveragePrice,  append(ResultsFolder ,'hourlyAveragePrice','pdf'))

    % Figure 1 PDF price 2024 hourly
    figure(fig_pdf_price2024_hourly)
    set(gcf, 'Units', 'Inches', 'Position', [1, 1, figwidth, figheight]);
    
    saveas(fig_pdf_price2024_hourly,  append(ResultsFolder , 'PDF_price2024_hourly','epsc'))
    saveas(fig_pdf_price2024_hourly,   append(ResultsFolder ,'PDF_price2024_hourly','pdf'))

    % Figure 2
    figure(fig_monthly_Boxplot2024)
    set(gcf, 'Units', 'Inches', 'Position', [1, 1, figwidth, figheight]);

  
    saveas(fig_monthly_Boxplot2024,  append(ResultsFolder , 'Boxplot_monthly2024','epsc'))
    saveas(fig_monthly_Boxplot2024,  append(ResultsFolder , 'Boxplot_monthly2024','pdf'))
    
    disp('Figures saved as PDF and eps')

    clear figwidth figheight ResultsFolder
end


