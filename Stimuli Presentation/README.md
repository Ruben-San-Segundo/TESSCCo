# EPIIC BCI-Silent Speech
This repository contains all the code related to the EPIIC BCI-Silent Speech Request.\
At this moment, the repository is organized with the needs and information on how to use the stimuli presentation for a multimodal bio-signal data acquisition for Silent Speech interfaces.

## Experiment
The experiment is divided in 4 main tasks:
- Covertly pronounce numbers
- Overtly pronounce numbers
- Covertly pronounce words
- Overtly pronounce words

All the tasks are repeated once per session in random order. Two sessions are completed per subject in two different days.
Further information can be read in DEL-BCI-2. \
Sessions are disposed as follows:\
![Intra-session pipeline protocol](./Images/Intra-session%20pipeline.png)

An example of a task pipeline:\
![Task pipeline example](./Images/Task%20pipeline%20example.png)

Regarding the pipelines, the code is prepared to present the stimulus while saving the moment a stimulus has been presented, the moment a task has started or the words and tasks already done.\
<br />
![General Script](./Images/General%20Script.png)
<br />
<br />
<br />
The calibration script proceeds as follows:\
![Calibration Script](./Images/Calibration%20script.png)
<br />
<br />
<br />
Finally, all the tasks follow the same diagram:\
<br />
![Task Script](./Images/Task%20script.png)

## Requirements
### Hardware
In order to run the code, the only hardware requirements are a PC and a microphone.
If a replication of the experiment is desired, then the hardware Requirements become larger. That means, hardware to complete the following scheme:\
![Hardware Scheme](./Images/Hardware%20Scheme.png)
### Python
The code is based in python 3.10, specifically in the PsychoPy Python dependency. Thus, it is mandatory to have PsychoPy installed and the path where the dependency has been installed (usually C:\Program Files\PsychoPy if default installation has been followed).
Moreover, thirdparty libraries are used:
- pyaudio
- pylsl
## Instalation
PsychoPy must be installed from the official webpage as using pip commands usually leads to an error building a wheel.\
[PsychoPy official webpage](https://psychopy.org/)\
In order to install the other libraries the use of _pip_ is recommended. However, since the python dependency is the psychopy's one, the installation of the dependencies must be done with _pip_ command of the aforementioned dependency.\
That means:
```ruby
& "C:/Program Files/PsychoPy/python.exe" -m pip install pylsl
& "C:/Program Files/PsychoPy/python.exe" -m pip install pyaudio
```
However, a _Requirements.txt_ file can be found in the repository. That means, the installation can be made with:
```ruby
& "C:/Program Files/PsychoPy/python.exe" -m pip install -r /path/to/Requirements.txt
```
## Running the code
Once all the libraries are installed, executing _script_general.py_ will start stimulus. All the information will be recorded in the path from where the script has been called. Thus, if a record of subjects stimuli is wanted, the script should be called as follows
```ruby
C:/My_experiments/Subject_00/Session_01> & "C:/Program Files/PsychoPy/python.exe" "C:/path-to-scripts/script_general.py"
```
