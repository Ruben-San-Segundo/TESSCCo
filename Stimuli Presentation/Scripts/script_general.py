#Signal adquisition prototype

from psychopy import core

import os

import variables_setup
import script_task
import csv_markers
import csv_tasks
import script_calibration


#First, make sure if the .csv exists. The .csv file will register which tasks have been done and when in time (timestamps unix) they start and end
if not os.path.exists(csv_tasks.nombre_archivo):
    print('The CSV file didn\' exist. Creating a new one.')
    csv_tasks.crear_csv(csv_tasks.nombre_archivo) #If the .csv doesn't exist, create a new one
    print(f"Archivo {csv_tasks.nombre_archivo} creado.")
    script_calibration.run_calibration()
    #Esto creo que va dentro de "ni no existe csv de tasks" porque quiere decir que es la primera vez que lo hace, entonces hacemos ahí la adquisición de calibración
    #Add progress bar
    
task_elegida=csv_tasks.elegir_task() #Read the completed tasks in tasksCompletadas.csv and choose randomly the ones that haven't been done 

#Depending on the result of elegir_task(), the used variables in run_task will have different values
if task_elegida=='Task-1': 
    print('The chosen task is Task 1: Spanish Overt Speech')
    mensaje_tarea='Tarea 1: Pronuncia los siguientes comandos en español EN VOZ ALTA y de forma clara (overt speech)' 
    vocab_task=["Baja el volumen", "Sube el volumen","Silencia FireTV","Enciende la televisión","Apaga FireTV"]
    csv_tasks.meter_task_csv(task_elegida)
    nom_csv_markers='Markers-Task-1.csv'
    csv_markers.crear_csv_markers(nom_csv_markers)
    
    script_task.run_task(mensaje_tarea,vocab_task,nom_csv_markers)


elif task_elegida=='Task-2': 
    print('The chosen task is Task 2: Spanish Covert Speech')
    mensaje_tarea='Tarea 2: Articula los siguientes comandos en español de forma clara pero SIN PRODUCIR SONIDO (covert speech)'
    vocab_task=["Baja el volumen", "Sube el volumen","Silencia FireTV","Enciende la televisión","Apaga FireTV"]
    csv_tasks.meter_task_csv(task_elegida)
    nom_csv_markers='Markers-Task-2.csv'
    csv_markers.crear_csv_markers(nom_csv_markers)
    
    script_task.run_task(mensaje_tarea,vocab_task,nom_csv_markers)


elif task_elegida=='Task-3': 
    print('The chosen task is Task 3: English Overt Speech')
    mensaje_tarea='Task 3: Pronounce the following English commands ALOUD clearly (overt speech)'
    vocab_task=["Turn down volume","Turn up volume","Mute FireTV","Turn on television","Turn off FireTV"]
    csv_tasks.meter_task_csv(task_elegida)
    nom_csv_markers='Markers-Task-3.csv'
    csv_markers.crear_csv_markers(nom_csv_markers)
    
    script_task.run_task(mensaje_tarea,vocab_task,nom_csv_markers)


elif task_elegida=='Task-4': 
    print('The chosen task is Task 4: English Covert Speech')
    mensaje_tarea='Task 4: Articulate the following English commands clearly but remain SILENT (covert speech)' 
    vocab_task=["Turn down volume","Turn up volume","Mute FireTV","Turn on television","Turn off FireTV"] 
    csv_tasks.meter_task_csv(task_elegida)
    nom_csv_markers='Markers-Task-4.csv'
    csv_markers.crear_csv_markers(nom_csv_markers)
    
    script_task.run_task(mensaje_tarea,vocab_task,nom_csv_markers)


# Add to 'tasksCompletadas.csv' the timestamp of when the task ends
csv_tasks.meter_timestamp_end(task_elegida)

print("Recording ended")

### End of the experiment
variables_setup.win.close() #When the task ends, close the window
core.quit()

print('---END OF THE EXPERIMENT---')


    