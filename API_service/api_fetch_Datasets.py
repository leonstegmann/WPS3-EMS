# Packages
import requests
import csv


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
    #print(result)

    # Prepare a list to hold CSV rows
    csv_rows = []
    if data:
        # Extracting data from JSON and organizing it for CSV
        for row in data['data']['Rows']:
            for column in row['Columns']:
                # Create a dictionary for each column
                csv_row = {
                    "Index": column['Index'],
                    "Name": column['Name'],
                    "Value": column['Value'],
                    "IsValid": column['IsValid'],
                    "IsOfficial": column['IsOfficial'],
                    "DateTimeForData": column['DateTimeForData']
                }
                csv_rows.append(csv_row)

        # Write to CSV file
        with open(data_filename, mode='w', newline='') as csv_file:
            fieldnames = csv_rows[0].keys()  # Get the field names from the first row
            writer = csv.DictWriter(csv_file, fieldnames=fieldnames)

            writer.writeheader()  # Write the header
            writer.writerows(csv_rows)  # Write the data rows

        print(f"Data has been written to {data_filename}")
        print("Total entries written: ", len(csv_rows))
    else:
        print("No records found to write.")

# FIT
url = 'https://www.nordpoolgroup.com/api/marketdata/page/424408?currency=,,,EUR'
filename = folderpath + 'FIT_data.csv'
write_api_NordPoolGroup_data_to_csv(url, filename)


