#IMPORTANT: In this script, we refer to "eyes open" and "eyes closed" as words even if they are not words
#This is to maintain the idea for other tasks as calibration is a "task 0"
from psychopy import core, visual, event

from datetime import datetime

import csv_tasks
import variables_setup
import csv_markers

def run_calibration():
    #Creamos el csv que contendrá los markers de la fase de calibración
    nom_csv_markers='Markers-Task-0.csv'
    csv_markers.crear_csv_markers(nom_csv_markers) 

        #Presentation of the instructions of the calibration phase:
    instructions1 = visual.TextStim(variables_setup.win, pos=[0,+3],text='Before the begining of the beginning of the experiment:',color='white')
    instructions2 = visual.TextStim(variables_setup.win, pos=[0,-3],text='Please relax and open/close your eyes as instructed in the screen when you hear the beep', color='white')
    instructions3 = visual.TextStim(variables_setup.win, pos=[0,-7],text='Press any key when you are ready', color='white')
    instructions1.draw()
    instructions2.draw()
    instructions3.draw()
    variables_setup.fixation.draw()
    variables_setup.win.flip()
    event.waitKeys()

    num_marker=variables_setup.markers_calibracion['comienzo_calibrado'] #Send a 0 marker to know the moment when the calibration phase has started
    #timestamp_marker= int(datetime.now().timestamp())
    variables_setup.outlet.push_sample(num_marker)
    csv_tasks.meter_task_csv('Task-0')
    

        #First 30s with eyes open:
    openEyesMessage = visual.TextStim(variables_setup.win, pos=[0,+3],text='Keep your eyes open until you hear the beep (30s)',color='white')
    openEyesMessage.draw()
    variables_setup.fixation.draw()
    variables_setup.win.flip()
    word=variables_setup.markers_calibracion['ojos_abiertos'] #Send a 1 marker when the 30s with open eyes have ended (started?)
    timestamp_start= int(datetime.now().timestamp())
    variables_setup.outlet.push_sample(word)
    
    core.wait(29.5)
    variables_setup.audio.play()
    core.wait(0.5)
    variables_setup.audio.stop()
    #core.wait(4.5) #PRUEBAS
   
           
    print('End of the 30s with eyes open')
    timestamp_end= int(datetime.now().timestamp())
    csv_markers.meter_marker(nom_csv_markers,1,1,timestamp_start,0,timestamp_end) #Write the marker in the .csv

        #First 30s with eyes closed:
    openEyesMessage = visual.TextStim(variables_setup.win, pos=[0,+3],text='Keep your eyes closed until you hear the beep (30s)',color='white')
    openEyesMessage.draw()
    variables_setup.fixation.draw()
    variables_setup.win.flip()
    word=variables_setup.markers_calibracion['ojos_cerrados'] #Send a 2 marker when the 30s with closed eyes have ended (started?)
    timestamp_start= int(datetime.now().timestamp())
    variables_setup.outlet.push_sample(num_marker)
    #csv_markers.meter_marker(nom_csv_markers,num_marker,timestamp_marker) #Write the marker in the .csv
    core.wait(29.5)
    variables_setup.audio.play()
    core.wait(0.5)
    variables_setup.audio.stop()

    print('End of the 30s with eyes closed')
    timestamp_end= int(datetime.now().timestamp())
    csv_markers.meter_marker(nom_csv_markers,1,2,timestamp_start,0,timestamp_end)

        #Seccond 30s with eyes open:
    openEyesMessage = visual.TextStim(variables_setup.win, pos=[0,+3],text='Keep your eyes open until you hear the beep (30s)',color='white')
    openEyesMessage.draw()
    variables_setup.fixation.draw()
    variables_setup.win.flip()
    word=variables_setup.markers_calibracion['ojos_abiertos'] #Send a 3 marker when the 30s with open eyes have ended (start, no?)
    timestamp_start= int(datetime.now().timestamp())
    variables_setup.outlet.push_sample(num_marker)
    #csv_markers.meter_marker(nom_csv_markers,num_marker,timestamp_marker) #Write the marker in the .csv
    core.wait(29.5)
    variables_setup.audio.play()
    core.wait(0.5)
    variables_setup.audio.stop()

    print('End of the 30s with eyes open')
    timestamp_end= int(datetime.now().timestamp())
    csv_markers.meter_marker(nom_csv_markers,2,1,timestamp_start,0,timestamp_end)


        #Seccond 30s with eyes closed:
    openEyesMessage = visual.TextStim(variables_setup.win, pos=[0,+3],text='Keep your eyes closed until you hear the beep (30s)',color='white')
    openEyesMessage.draw()
    variables_setup.fixation.draw()
    variables_setup.win.flip()
    word=variables_setup.markers_calibracion['ojos_cerrados'] #Send a 4 marker when the 30s with closed eyes have ended (started?)
    timestamp_start = int(datetime.now().timestamp())
    variables_setup.outlet.push_sample(num_marker)
    #csv_markers.meter_marker(nom_csv_markers,num_marker,timestamp_marker) #Write the marker in the .csv
    core.wait(29.5)
    variables_setup.audio.play()
    core.wait(0.5)
    variables_setup.audio.stop()

    print('End of the 30s with eyes closed')
    timestamp_end= int(datetime.now().timestamp())
    csv_markers.meter_marker(nom_csv_markers,2,2,timestamp_start,0,timestamp_end)


    num_marker=variables_setup.markers_calibracion['final'] #Send a 4 marker when the 30s with closed eyes have ended (started?)
    variables_setup.outlet.push_sample(num_marker)
    csv_tasks.meter_timestamp_end('Task-0')
    #timestamp_marker= int(datetime.now().timestamp())
    #csv_markers.meter_marker(nom_csv_markers,num_marker,timestamp_marker) #Write the marker in the .csv

