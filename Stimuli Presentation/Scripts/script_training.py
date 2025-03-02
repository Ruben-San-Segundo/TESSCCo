import variables_setup
from psychopy import core, visual, event

#Explanation of training
mensaje_tarea='This is a training mode in which you will see the different tasks to be performed' 
message1 = visual.TextStim(variables_setup.win, pos=[0,+3],text=mensaje_tarea,color='white')
message2 = visual.TextStim(variables_setup.win, pos=[0,-3],text='Before each tasks, 40 seconds will go by from the begining of the experiment until the first word appears', color='white')
message3 = visual.TextStim(variables_setup.win, pos=[0,-7],text='Press any key to begin the training', color='white')
message1.draw()
message2.draw()
message3.draw()
variables_setup.fixation.draw()
variables_setup.win.flip()
event.waitKeys()

#Explanation tasks-1
mensaje_tarea='In Task 1 you have to pronounce different Spanish commands ALOUD and Clearly (a.k.a overt speech)' 
message1 = visual.TextStim(variables_setup.win, pos=[0,+3],text=mensaje_tarea,color='white')
message2 = visual.TextStim(variables_setup.win, pos=[0,-3],text='Spanish commands are: "Baja el volumen", "Sube el volumen","Silencia FireTV","Enciende la televisión","Apaga FireTV"', color='white')
message3 = visual.TextStim(variables_setup.win, pos=[0,-7],text='Press any key to continue', color='white')
message1.draw()
message2.draw()
message3.draw()
variables_setup.fixation.draw()
variables_setup.win.flip()
event.waitKeys()

mensaje_tarea='The command will be presented in green color for 2 secods.' 
message1 = visual.TextStim(variables_setup.win, pos=[0,+3],text=mensaje_tarea,color='white')
message2 = visual.TextStim(variables_setup.win, pos=[0,-3],text='After that time, the color will change to red and you dispose of 3 seconds to perform the task', color='white')
message3 = visual.TextStim(variables_setup.win, pos=[0,-7],text='Press any key to begin the Task-1 example', color='white')
message1.draw()
message2.draw()
message3.draw()
variables_setup.fixation.draw()
variables_setup.win.flip()
event.waitKeys()

#Example Task-1
variables_setup.palabra_pre.setText("Baja el volumen")
variables_setup.palabra_pre.draw()
variables_setup.win.flip()
core.wait(2)

variables_setup.palabra_go.setText("Baja el volumen")
variables_setup.palabra_go.draw()
variables_setup.win.flip()
core.wait(3)

mensaje_tarea='You have to repeat this a total of 10 times for each command' 
message1 = visual.TextStim(variables_setup.win, pos=[0,+3],text=mensaje_tarea,color='white')
message2 = visual.TextStim(variables_setup.win, pos=[0,-3],text='If one trial is not correctly performed, the experimenter can indicate the program to repeat the stimuli', color='white')
message3 = visual.TextStim(variables_setup.win, pos=[0,-7],text='Press any key to continue', color='white')
message1.draw()
message2.draw()
message3.draw()
variables_setup.fixation.draw()
variables_setup.win.flip()
event.waitKeys()

#Explanation Task-2,3,4
mensaje_tarea='Task 2 is the same as task 1, but without producing sound while articulating the word' 
message1 = visual.TextStim(variables_setup.win, pos=[0,+3],text=mensaje_tarea,color='white')
message2 = visual.TextStim(variables_setup.win, pos=[0,-3],text='Task 3 and 4 are equivalente to 1 and 2 respectively but with english commands', color='white')
message3 = visual.TextStim(variables_setup.win, pos=[0,-7],text='Press any key to continue', color='white')
message1.draw()
message2.draw()
message3.draw()
variables_setup.fixation.draw()
variables_setup.win.flip()
event.waitKeys()

#Ennglish commands
mensaje_tarea='English commands are: "Turn down volume","Turn up volume","Mute FireTV","Turn on television","Turn off FireTV"' 
message1 = visual.TextStim(variables_setup.win, pos=[0,+3],text=mensaje_tarea,color='white')
message2 = visual.TextStim(variables_setup.win, pos=[0,-3],text='If you have any doubts, please, ask the experimenter', color='white')
message3 = visual.TextStim(variables_setup.win, pos=[0,-7],text='Press any key to finish', color='white')
message1.draw()
message2.draw()
message3.draw()
variables_setup.fixation.draw()
variables_setup.win.flip()
event.waitKeys()

quit()