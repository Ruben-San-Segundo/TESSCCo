from psychopy import visual, event

import variables_setup

#To exit the experiment, press the 'Q' key on the experimenter's keyboard during the 5s of extra
#resting time between vocabulary rounds

def check_escape(t_espera):
    if event.waitKeys(maxWait=t_espera, keyList='q'):
        return 1

    
#When the 'q' key has been pressed, a confirmation message appears to make sure the experimenter really wants to end the experiment
#To exit press'y' and to go back to the experiment press 'n'
def confirmar_cierre(): 
    print('Are you sure you want to exit the experiment?  Press Y -> yes   Press N -> no')
    mensaje = visual.TextStim(variables_setup.win, text="Are you sure you want to exit the experiment?", color='white') 
    mensaje.draw() 
    variables_setup.win.flip() 
    respuesta = event.waitKeys(keyList=['y', 'n']) #Wait for the user's answer 'y' for yes or 'n' for no 
    variables_setup.win.flip() 
    return respuesta[0]