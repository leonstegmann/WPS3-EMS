# Packages
import requests
import csv
import pandas as pd


# %% API Request
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

folderpath = 'Datasets/'

# RTP data
url = 'https://api.energidataservice.dk/dataset/Elspotprices?start=now-P5D&end=now%2BP1D'
filename = folderpath + 'RTP_data.csv'
write_api_swagger_data_to_csv(url, filename)
#%%


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
write_api_NordPoolGroup_data_to_csv(url, filename)


