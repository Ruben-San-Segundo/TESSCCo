import os
import csv
import random
from datetime import datetime

# Name of the file where the tasks already completed are registered and the available tasks to do the experiment (tasks list)
nombre_archivo = 'Tasks-Completed.csv'
tasks = ['Task-1','Task-2','Task-3','Task-4'] #Task 1: ES-Overt Speech   Task 2: ES-Covert Speech   Task 3: EN-Overt Speech   Task 4: EN-Covert Speech

# Function to create the CSV file if it does not exist
def crear_csv(nombre):
    with open(nombre, mode='w', newline='') as archivo:
        escribir = csv.writer(archivo)
        escribir.writerow(["Task","Timestamp_start","Timestamp_end"]) #Writes the headings
        print(f"File {os.path.abspath(nombre)} created.")

# Function to read the CSV file and obtain the existing tasks
def leer_csv(nombre):
    tasks_realizadas = []
    if os.path.exists(nombre): #Makes sure it exists
        with open(nombre, mode='r') as archivo:
            leer = list(csv.reader(archivo))
            if len(leer)>1:
                for fila in leer:
                    if fila:
                        tasks_realizadas.extend([task.strip() for task in fila if task.strip()]) #Go through the rows of the csv and add in task_realizadas the ones that are already done
    return tasks_realizadas

# Reads which task have already been completed and chooses randomly the next task among the ones that haven't been done
def elegir_task():
    #print(' The .csv file exists')
    print(f"A task is chosen from those not registred in {os.path.abspath(nombre_archivo)}.")
    tasks_realizadas = leer_csv(nombre_archivo) #reads the .csv and returns the list of completed task    
    tasks_por_hacer = [task for task in tasks if task not in tasks_realizadas] #Creates list of tasks not done yet

    if len(tasks_por_hacer)>0:
        task_aleatoria = random.choice(tasks_por_hacer)
        #print(f"The task that is going to begin is: {task_aleatoria}")
        return task_aleatoria
    else:
        task_aleatoria = None #The experiment is over
        print("All tasks have already been completed")
        return task_aleatoria        
    
def meter_task_csv(task_aleatoria):
    # Add in the .csv the chosen task and the start timestamp
    if task_aleatoria:
        timestamp_start= int(datetime.now().timestamp())
        with open(nombre_archivo, mode='a', newline='') as archivo:
            escritor = csv.writer(archivo)
            escritor.writerow([task_aleatoria,timestamp_start])
        #print(f"Task {task_aleatoria} has been added to the csv whith the following timestamp {timestamp_start}")

def meter_timestamp_end(task_aleatoria):
    if task_aleatoria:
        timestamp_end = int(datetime.now().timestamp())
        lines = []
        with open(nombre_archivo, mode='r') as archivo:
            reader = csv.reader(archivo)
            for row in reader:
                if row[0] == task_aleatoria:
                    row.append(timestamp_end)
                lines.append(row)
        
        with open(nombre_archivo, mode='w', newline='') as archivo:
            writer = csv.writer(archivo)
            writer.writerows(lines)
        print(f"Ending timestamp {timestamp_end} for task {task_aleatoria} has been added.")