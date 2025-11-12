# FESSCCo Stimuli Presentation
This folder contains all the code related to the FESSCCo database stimuli presentation.

## Experiment Overview
Further information can be read in the [**Official publication in Scientific Data (Nature)**](Link).
However, this README summarizes the most important concepts and explains the code.

Before the participant’s arrives, the experimenter prepares all required materials. Then, participants must be informed about the procedure and sign the consent form. Then, the electrodes are placed and the session begins.
<br>
A session comprises a training phase (only in the first session), a calibration phase (i.e., \textit{task 0}), and four tasks presented in random order without repetition:
- Overtly pronounce Spanish commands (Task-1)
- Covertly pronounce Spanish commands (Task-2)
- Overtly pronounce English commands (Task-3)
- Covertly pronounce English commands (Task-4)

> Task-1 always refers to Spanish Overt Speech, but it can be presented as first, second, third, or last task in a Session.

Each task begins with a 40-second baseline recording. After this baseline, a red command appears for two seconds, during which the participant silently read the command. The text then changes to green for three seconds, indicating the period to pronounce the command either overtly or covertly. Each task consists of ten rounds. In each round, participants pronounce (either overtly or covertly) the five commands (in English or Spanish), presented in random order without repetition.

The general pipeline is summarized in ![General pipeline summary](./Images/Adquisition%20Protocol%20Pipeline.png)

## Code explanation

The first time the code is run for a Session, it checks the folder from which it has been called (typically, the Markers folder for that Session). If no Tasks-markers.csv is found, then it creates the .csv file and pop-ups the calibration (Task-0) window. To start it, any key has to be pressed. The script saves the UNIX timestamps for the beginning and end of the calibration. 
<br>
<br>
![Calibration Script](./Images/Calibration%20script.png)
<br>
<br>
After Task-0, the script goes to the main code. The aforementioned steps are summarized in the next flow chart:
<br>
<br>
![General Script](./Images/General%20Script.png)
<br>
<br>

The *Run task* block meets the tasks' steps:

![Task pipeline example](./Images/Task%20pipeline%20example.png)
<br />
<br />

And is coded following this chart:
<br />
<br>
![Task Script](./Images/Task%20script.png)

## Requirements
### Hardware
In order to run the code, the only hardware requirements are a PC and a microphone.
However, since the experiment aims to record physiological data, those devices and their recording programs are essential as well. In our case, we used BitBrain Versatile E32 headset and BitBrain Viewer software.
### Python
The code is based in python 3.10, specifically in the PsychoPy Python dependency. Thus, it is mandatory to have PsychoPy installed and the path where the dependency has been installed (usually C:\Program Files\PsychoPy if default installation was followed).
Moreover, thirdparty libraries are used:
- pyaudio
- pylsl
## Instalation
PsychoPy must be installed from the official webpage as using pip commands usually leads to an error building a wheel.\
[PsychoPy official webpage](https://psychopy.org/)\
In order to install the other libraries the use of _pip_ is recommended. However, since the python dependency is the psychopy's one, the installation of the dependencies must be done with _pip_ command of the aforementioned dependency.\
That means:
```bash
& "C:/Program Files/PsychoPy/python.exe" -m pip install -r /path/to/Requirements.txt
```
## Running the code
Once all the libraries are installed, executing _script_general.py_ will start stimulus. All the information will be recorded in the path from where the script has been called. Thus, if a record of subjects stimuli is wanted, the script should be called as follows
```bash
C:/My_experiments/Subject_00/Session_01/Markers> & "C:/Program Files/PsychoPy/python.exe" "C:/path-to-scripts/script_general.py"
```

For the training before the first session, the code is
```bash
C:/My_experiments/Subject_00/Session_01/Markers> & "C:/Program Files/PsychoPy/python.exe" "C:/path-to-scripts/training_script.py"
```

