import os
import csv


# Function to create the CSV file 
def crear_csv_markers(nombre_archivo):
    with open(nombre_archivo, mode='w', newline='') as archivo:
        escribir = csv.writer(archivo)
        escribir.writerow(["Round", "Word","Timestamp_start","Timestamp_go","Timestamp_end"]) 
        print(f"File {os.path.abspath(nombre_archivo)} created to save markers.")

# Function to add in the CSV file the marker given as a parameter and its timestamp
def meter_marker(nombre_archivo,Round,Word,UTC_start,UTC_go,UTC_end):
    #After completing the task we save the marker in the CSV file
    with open(nombre_archivo, mode='a', newline='') as archivo:
        escritor = csv.writer(archivo)
        escritor.writerow([Round,Word,UTC_start,UTC_go,UTC_end])