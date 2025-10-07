import threading
import audio_recorder

from psychopy import core, visual, event

import random
from datetime import datetime

import script_exit
import variables_setup
import csv_markers

#Recording stop event
stop_event = threading.Event()

def run_task(mensaje_tarea,vocab_task,nom_csv_markers):
    message1 = visual.TextStim(variables_setup.win, pos=[0,+3],text=mensaje_tarea,color='white')
    message2 = visual.TextStim(variables_setup.win, pos=[0,-3],text='40 seconds will go by from the begining of the experiment until the first word appears', color='white')
    message3 = visual.TextStim(variables_setup.win, pos=[0,-7],text='Press any key to begin the task', color='white')
    message1.draw()
    message2.draw()
    message3.draw()
    variables_setup.fixation.draw()
    variables_setup.win.flip()
    event.waitKeys()
    variables_setup.fixation.draw()
    variables_setup.win.flip()
    num_marker=variables_setup.markers_fase['comienza_task'] #Send marker 0 to know when the 40s of adquisition start before the task begins
    timestamp_start= int(datetime.now().timestamp())
    variables_setup.outlet.push_sample(num_marker)
    #csv_markers.meter_marker(nom_csv_markers,num_marker,timestamp_start) # Write the marker down in the .csv
    nombre_wav = nom_csv_markers[8:14]+'.wav'
    grabar = threading.Thread(target=audio_recorder.record_audio, args=(nombre_wav, stop_event))
    grabar.start()
    print('The experiment has begun, 40s of baseline signal (without stimuli presentation) are being recorded.')
    core.wait(40)
    timestamp_end = int(datetime.now().timestamp())
    csv_markers.meter_marker(nom_csv_markers,0,0,timestamp_start,0,timestamp_end) #Meter el marker en el .
    
    

    for i in range(10): #The whole vocabulary set (5 different words/numbers) is going to be shown 10 times, at the end of each task 50 words/numbers will have been recorded (x4 tasks = 200 trials at the end of the experiment)
        vocab_words=vocab_task.copy()
        #print('The words/numbers in this round of the vocabuary are: ', vocab_words)
        num_marker=i+1
        round = i+1
        timestamp_round_start = int(datetime.now().timestamp())
        variables_setup.outlet.push_sample([num_marker]) #Send a marker via LSL with the number of the actual vocabulary round (a number from 1 to 10)
        #csv_markers.meter_marker(nom_csv_markers,num_marker,timestamp_marker) #Write the marker down in the .csv
        while len(vocab_words)>0:

                ### First phase (Pre): Stimulus shown on the screen in red to give time to the subject to prepare (2s)
            palabraActual= random.choice(range(len(vocab_words)))  #To randomize the order in which words are shown in each round of the vocabulary
            hecho_bien=False
            print('Word:    ',vocab_words[palabraActual])
            while hecho_bien==False:
                variables_setup.palabra_pre.setText(vocab_words[palabraActual])
                variables_setup.palabra_pre.draw()
                variables_setup.win.flip()
                num_marker=(variables_setup.markers_words[vocab_words[palabraActual]][0]*10)+variables_setup.markers_fase['palabra_pre'][0] # For example, if palabraActual is 'Turn_down_volume_os' a '61' marker will now
                #be sent, thus we will know the the word is Turn_down_volume_os (asociated in variabes_setup.markers_words with number 6) and that we are in the first phase (asociated in variabes_setup.markers_fas with number 1) 
                #Meanwhile, word variable is for adding markers to the csvs
                word = variables_setup.markers_words[vocab_words[palabraActual]][0]
                timestamp_start= int(datetime.now().timestamp())
                variables_setup.outlet.push_sample([num_marker]) 
                #csv_markers.meter_marker(nom_csv_markers,num_marker,timestamp_marker)
                core.wait(2)
                
                ### Second phase (Go): Stimulus turns green for the subject to start pronouncing (3s)
                print('GO') #The subject can start pronouncing the word/number
                variables_setup.palabra_go.setText(vocab_words[palabraActual])
                variables_setup.palabra_go.draw()
                variables_setup.win.flip()
                num_marker=(variables_setup.markers_words[vocab_words[palabraActual]][0]*10)+variables_setup.markers_fase['palabra_go'][0]
                timestamp_go= int(datetime.now().timestamp())
                variables_setup.outlet.push_sample([num_marker])
                #csv_markers.meter_marker(nom_csv_markers,num_marker,timestamp_marker)
                core.wait(3)
                print('STOP') #The subject should stop pronouncing the word/number

                ### Third phase (Rest): Resting time and time for the experimenter to mark the trial as invalid (5s)
                variables_setup.fixation.draw()
                variables_setup.win.flip()
                num_marker=(variables_setup.markers_words[vocab_words[palabraActual]][0]*10)+variables_setup.markers_fase['final_go'][0]
                timestamp_end= int(datetime.now().timestamp())
                variables_setup.outlet.push_sample([num_marker])
                #csv_markers.meter_marker(nom_csv_markers,num_marker,timestamp_marker)
                
                #Add the 3 markers to the csv
                csv_markers.meter_marker(nom_csv_markers,round,word,timestamp_start,timestamp_go,timestamp_end)

                t_random=random.randint(0, 3500) #Pink noise will be played sometime (random each time) during the first 3.5s of the resting time 
                core.wait(t_random/1000) #Change to seconds
                variables_setup.audio.play() #Audio with pink noise
                core.wait(0.5) #Stop the audio after 500ms
                variables_setup.audio.stop()
                core.wait((4000-t_random-500)/1000) #Wait remaining time to complete the 4s
                
                 
                #During the last second of the resting time, if the 'x' key is pressed in the experimenter's keyboard, this word/number will be shown again to repeat the invalid trial
                print('Press X if invalid \n')
                if event.waitKeys(maxWait=1, keyList='x'):
                    print('X pressed --> trial invalid. Word will be now repeated')
                else:
                    hecho_bien=True
                    del vocab_words[palabraActual] #As the trial has been valid, the word/number will be removed from the list of remaining words in this vocabulary round
                    #Before the beginning of the next round of the experiment, vocab_words will be recomposed
                    #print('X not pressed, trial is considered valid and the word/number will be removed from the list') 
                    

        
        #When the 5 words have been said, we have 5 extra seconds of rest (and the possibility to exit) before starting again
        print('\n ----Round of vocabulary ', i+1, ' completed, 5s of extra rest time. Press Q to exit the experiment----')
        mensaje = "End of round " + str(i+1) + "/10" #The subject can see how many rounds of vocabulary are left
        message4 = visual.TextStim(variables_setup.win, pos=[0,+3],text=mensaje,color='white')
        message4.draw()
        variables_setup.fixation.draw()
        variables_setup.win.flip()
        #variables_setup.outlet.push_sample(variables_setup.markers['final_go'])

        #Add round information to csv
        timestamp_round_end = int(datetime.now().timestamp())
        csv_markers.meter_marker(nom_csv_markers,round,-1,timestamp_round_start,0,timestamp_round_end)

        if script_exit.check_escape(5)==1:
            if script_exit.confirmar_cierre()=='y':
                print('Closing confirmed, the experiment will end')
                stop_event.set()
                grabar.join()
                return 0
            else:
                print('Closing has not been confirmed, the experiment will continue')
                continue
        else:
            #print('Q not pressed, the next round of vocabulary will begin')
            continue
        
        

    stop_event.set()
    grabar.join()
