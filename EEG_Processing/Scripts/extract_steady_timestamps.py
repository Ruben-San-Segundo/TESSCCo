import pandas as pd

def extract_steady_timestamps(tasks_file: str, utc_file: str, output_file: str, tasks: bool):
    """
    Associates the UTC timestaps in markers' csvs with the respective steady_timestamp indicated in UTC.csv of each device
    
    Args:
        tasks_file (str): Path to the csv with the markers in UTC format
        utc_file (str): Path to the CSV with the association between UTC and steady_timestamp of the device
        output_file (str): File path where the new CSV will be stored
        tasks (bool): Indicates if we are translating "Tasks-completed.csv" (false) or "Task-x.csv" (true)
    """
    # Loading data
    tasks_df = pd.read_csv(tasks_file, sep=',')
    utc_df = pd.read_csv(utc_file, sep=',')
    
    # Assuring timestamp columns are a numeric type
    tasks_df["Timestamp_start"] = pd.to_numeric(tasks_df["Timestamp_start"], errors="coerce")
    if tasks:
        tasks_df["Timestamp_go"] = pd.to_numeric(tasks_df["Timestamp_go"], errors="coerce")
    tasks_df["Timestamp_end"] = pd.to_numeric(tasks_df["Timestamp_end"], errors="coerce")
    utc_df["utc_timestamp"] = pd.to_numeric(utc_df["utc_timestamp"], errors="coerce")

    # Inicialating memory for each moment traduction
    steady_start = []
    if tasks:
        steady_go = []
    steady_end = []
    
    for _, row in tasks_df.iterrows():
        # Find the index with the utc_timestamp the nearest to timestamp-start in UTC
        if not pd.isna(row["Timestamp_start"]):
            idx_start = (utc_df["utc_timestamp"] - row["Timestamp_start"]*1000000).abs().idxmin()
            #Multiplying by 10^6 because we are using different resolutions. That means, the UTC of the device is 16 digit length, while markers are 10 digit lenght
            steady_start.append(utc_df.loc[idx_start, "steady_timestamp"])
        else:
            steady_start.append(None)  # Error managment

        if tasks:
            # Find the index with the utc_timestamp the nearest to timestamp-go in UTC
            if not pd.isna(row["Timestamp_go"]):
                idx_go = (utc_df["utc_timestamp"] - row["Timestamp_go"]*1000000).abs().idxmin() 
                steady_go.append(utc_df.loc[idx_go, "steady_timestamp"])
            else:
                steady_go.append(None)  # Error management

        # Find the index with the utc_timestamp the nearest to timestamp-end in UTC
        if not pd.isna(row["Timestamp_end"]):
            idx_end = (utc_df["utc_timestamp"] - row["Timestamp_end"]*1000000).abs().idxmin()
            steady_end.append(utc_df.loc[idx_end, "steady_timestamp"])
        else:
            steady_end.append(None)  # Error management
    
    # Adding the steady_timestamps to the final DataFrame
    tasks_df["steady_start"] = steady_start
    if tasks:
        tasks_df["steady_go"] = steady_go
    tasks_df["steady_end"] = steady_end
    
    # Saving the final file with the steady_timestamps associated
    tasks_df.to_csv(output_file, sep=',', index=False)
    print(f"Archivo guardado: {output_file}")