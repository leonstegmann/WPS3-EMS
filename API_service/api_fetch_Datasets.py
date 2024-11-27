# Packages
import requests
import csv
import pandas as pd

folderpath = 'Datasets/'


# %% API Request Energienet.dk
def write_api_swagger_data_to_csv(data_url, data_filename):
    # Request to API SERVER
    response = requests.get(url=data_url)

    # Extract the records from the API response
    data = response.json()
    #print(data)
    records = data.get('records', [])

    # Check if records are not empty
    if records:
        # Get the column headers from the keys of the first record
        headers = records[0].keys()

        # Write the records to a CSV file
        with open(data_filename, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=headers)

            # Write the headers to the CSV file
            writer.writeheader()

            # Write the data rows
            for record in records:
                writer.writerow(record)

        print("Data successfully written to: " + data_filename)
        print("Total entries written: ", len(records))
    else:
        print("No records found to write.")


# %% Datasets


# RTP data
# 7 days (last 5 + 2 ahead)
url = 'https://api.energidataservice.dk/dataset/Elspotprices?start=now-P5D&end=now%2BP1D&filter={"PriceArea":["DK1"]}'
filename = folderpath + 'RTP_data_dayAhead.csv'
write_api_swagger_data_to_csv(url, filename)

# 1 year
url = 'https://api.energidataservice.dk/dataset/Elspotprices?start=2022-01-01&end=2023-01-01&filter={"PriceArea":["DK1"]}'
filename = folderpath + 'RTP_data_1year.csv'
write_api_swagger_data_to_csv(url, filename)
#%%
# oktober 2024
url = 'https://api.energidataservice.dk/dataset/Elspotprices?start=2024-10-01T02:00&end=2024-11-01T02:00&filter={"PriceArea":["DK1"]}' # +2 hours to get UTC
filename = folderpath + 'Elspotprice_Energienet_oktober24.csv'
write_api_swagger_data_to_csv(url, filename)


#%% NOrdpoolgroup


def write_api_NordPoolGroup_data_to_csv(data_url, data_filename):
    # Request to API SERVER
    response = requests.get(url=data_url)

    # Extract the records from the API response
    data = response.json()
   # print(data)

    if data:

        # Open a CSV file to write the output
        with open(data_filename, mode='w', newline='') as file:
            writer = csv.writer(file)
            # Write header row
            writer.writerow(['Area', 'Value', 'StartTime', 'EndTime'])

            # Extract the values
            rows = data['data']['Rows']
            for row in rows:
                start_time = row['StartTime']
                end_time = row['EndTime']
                for column in row['Columns']:
                    area = column['Name']
                    # Replace comma with dot in the value
                    value = column['Value'].replace(',', '.')
                    # Write each row to the CSV file
                    writer.writerow([area, value, start_time, end_time])


        print(f"Data has been written to {data_filename}")
        print("Total entries written: ", len(pd.read_csv(data_filename)))
    else:
        print("No records found to write.")

# FIT
url = 'https://www.nordpoolgroup.com/api/marketdata/page/424408?currency=,,DKK,EUR'
filename = folderpath + 'FIT_data.csv'
#write_api_NordPoolGroup_data_to_csv(url, filename)

# %% Swagger API to get WInd Data from DMI Open Data (https://opendatadocs.dmi.govcloud.dk/DMIOpenData)
# Station ID :21080	Nørre Vorupør
# Station ID :06058	Hvide Sande

def API_request_fromDMIOpenData_using_swagger_writing_to_csv(data_url, data_filename):
    # Request to API SERVER
    response = requests.get(url=data_url)

    # Extract the records from the API response
    data = response.json()
    #print(data)
    if data:
        # Extract the observed time and value from the data
        features = data.get("features", [])

        # Prepare data for CSV
        rows = []
        for feature in features:
            observed_time = feature["properties"].get("observed")
            value = feature["properties"].get("value")

            # Append to rows if both fields are present
            if observed_time is not None and value is not None:
                rows.append([observed_time, value])

        # Write to CSV file
        with open(data_filename, mode='w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["observed_time", "value"])  # Header
            writer.writerows(rows)

        print(f"Data has been written to {data_filename}")
        print("Total entries written: ", len(pd.read_csv(data_filename)))

    else:
        print("No records found to write.")


# composition of URLs
base_url ='https://dmigw.govcloud.dk/v2/metObs/collections/observation/items?'
with open('api_key.txt', 'r') as file:  #Read in API Key
    api_key = '&api-key=' + file.read()
limitation = '&limit=10000'
station = '&stationId=06058'
time_period = '&datetime=2024-10-01T00:00:00Z/2024-11-01T00:00:00Z'
parameter = '&parameterId=wind_speed_past1h'

# Different URLs
wind_url = base_url + api_key + limitation + station + time_period + '&parameterId=wind_min_past1h'      # in m/s
temp_url = base_url + api_key + limitation + station + time_period + '&parameterId=temp_mean_past1h'     # in °C
humidity_url = base_url + api_key + limitation + station + time_period + '&parameterId=humidity_past1h'  # in %
solar_url = base_url + api_key + limitation + station + time_period + '&parameterId=radia_glob_past1h'   # in W/m^2

# save Files
API_request_fromDMIOpenData_using_swagger_writing_to_csv(wind_url, folderpath + 'Wind_DMIOpenData_oktober24.csv')
API_request_fromDMIOpenData_using_swagger_writing_to_csv(temp_url, folderpath + 'Temperature_DMIOpenData_oktober24.csv')
API_request_fromDMIOpenData_using_swagger_writing_to_csv(humidity_url, folderpath + 'Humidity_DMIOpenData_oktober24.csv')
API_request_fromDMIOpenData_using_swagger_writing_to_csv(solar_url, folderpath + 'Solar_DMIOpenData_oktober24.csv')



