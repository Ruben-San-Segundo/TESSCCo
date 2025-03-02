from psychopy import core, visual, sound
import os 
from pylsl import StreamInfo, StreamOutlet

### Set up LabStreamingLayer stream
info = StreamInfo(name='PsychoPy_LSL', type='Markers', channel_count=1,channel_format='int32', source_id='example_stream_001')
outlet = StreamOutlet(info)
markers_fase = {'comienza_task': [0],'palabra_pre': [1],'palabra_go': [2],'final_go': [3]}  # No es necesario, pero es para saber a qué corresponde cada marker
markers_calibracion = {'comienzo_calibrado': [0], 'ojos_abiertos': [1], 'ojos_cerrados': [2], 'final': [3]}
markers_words={'Baja el volumen':[1],'Sube el volumen':[2],'Silencia FireTV':[3],'Enciende la televisión':[4],'Apaga FireTV':[5],'Turn down volume':[6],'Turn up volume':[7],'Mute FireTV':[8],'Turn on television':[9],'Turn off FireTV':[10]}

### Setup de los estímulos y la ventana de visualización
    # crear window
win=visual.Window([1600, 800],allowGUI=True,monitor='testMonitor', units='deg',color='black') #Si anadimos screen=2 podemos hacer que salga en otra pantalla, pero solo si usamos una gráfica que no sean integrados de intel
    
    #Quizás otros colores generan mejor contraste (verde rojo o rojo blanco en vez de rojo verde)
    # crear el estímulo de presentar la siguiente palabra/número (palabra_pre), el estímulo para que comience la pronunciación (palabra_go), y el estímulo para el descanso (fixation)
palabra_pre = visual.TextStim(win, pos=[0,0],text="inicio", color='red', bold=True, height=5)
palabra_go = visual.TextStim(win, pos=[0,0],text="inicio", color='green', bold=True, height=5)
fixation = visual.GratingStim(win, color='white', colorSpace='rgb',tex=None, mask='circle', size=0.4)
   
   # crear el objeto del ruido rosa
current_directory = os.path.dirname(os.path.abspath(__file__)) #Obtener la ruta completa del archivo
file_audio = os.path.join(current_directory, 'ruidoRosa.wav')
audio = sound.Sound(file_audio)

 # crear el objeto del beep
#current_directory = os.path.dirname(os.path.abspath(__file__)) #Obtener la ruta completa del archivo
#file_audio = os.path.join(current_directory, 'beep.mp3')
#beep = sound.Sound(file_audio)

    # crear relojes [mirar si quitar esta parte]
globalClock = core.Clock()
trialClock = core.Clock()