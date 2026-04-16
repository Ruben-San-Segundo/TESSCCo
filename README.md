# FESSCCo - FireTV EEG-based Silent Speech Command Corpus

This repository contains the all the code usedn in the **FireTV EEG-based Silent Speech Command Corpus (FESSCCo)**, a dataset for Silent Speech Interface (SSI) research.

The repository provides all the necessary **code and scripts** for:   
- Stimul presentation for reproducing the experiments (`Stimuli Presentation/`)
- Data preprocessing (`EEG_Processing/`)
- Statistical analysis (`EEG_Statistical_Analysis/`)

## Key Information

- **21 native Spanish participants** (13 male, 8 female, 23+/-2 y/o)  
- **5 commands in covert speech and overt speech, english and Spanish**: 

| Language | Commands |
|:-------:|:-------------------------------------------------------------------------------------------------:|
| Spanish | "Baja el volumen”, “Sube el volumen”, “Silencia FireTV", “Enciende la televisión”, “Apaga FireTV” |
| English |   “Turn down volume”, “Turn up volume”, “Mute FireTV”,“Turn on television”, 10:“Turn off FireTV”  |

- **32-channel water-based EEG headset** (BitBrain Versatile E32, 256 Hz sampling rate)  
- **7936 ready-to-use trials** across 2 sessions per subject (three with 1 session only)  
- **Preprocessing & statistical analysis** (Python, EEGLab, FieldTrip)  
- **Open bilingual Silent Speech dataset** for specific device control


## 📂 Dataset Access and Notebooks

The dataset is hosted publicly on [**Kaggle**](https://www.kaggle.com/datasets/rubensansegundoherna/tesscco)

## Publication
📄 [**Official publication in Scientific Data (Nature)**](Link)

---

## Repository Structure

The repository is organized into three main components:

### 1. Stimuli Presentation
**Location:** `Stimuli Presentation/`

Contains the experimental stimuli presentation system built with PsychoPy for data acquisition.

**Key Features:**
- Real-time stimulus presentation with precise timing
- Audio recording capabilities
- Automated task randomization and session management
- Marker generation for stimulus timing

**Experiment Design:**
The experiment consists of 4 main tasks:
- Covertly pronounce Spanish commands
- Overtly pronounce Spanish commands
- Covertly pronounce English commands
- Overtly pronounce English commands

Each task is repeated once per session in random order, with two sessions completed per subject. Further information — including precise timing, trial structure, and stimulus files. 

**Documentation:** See [Stimuli Presentation/README.md](./Stimuli%20Presentation/README.md) for detailed setup and usage instructions.

### 2. EEG Processing
**Location:** `EEG_Processing/`

Complete pipeline for EEG signal preprocessing and preparation for analysis.

**Pipeline Stages:**
- **Trimming**: Extract relevant data segments from raw recordings
- **Filtering**: Apply frequency filters to remove noise
- **Epoching**: Segment continuous data into task-relevant epochs
- **ICA**: Independent Component Analysis for artifact removal
- **Label Extraction**: Generate labels for different applications

**Technologies:**
- Python for orchestration and data manipulation
- MATLAB/EEGLAB for advanced signal processing
- NumPy, Pandas, SciPy for data analysis

**Documentation:** See [EEG_Processing/readme.md](./EEG_Processing/readme.md) for detailed pipeline documentation.

### 3. EEG Statistical Analysis
**Location:** `EEG_Statistical_Analysis/`

Tools and scripts for statistical analysis of the preprocessed EEG data. Specifically, 1-WAY ANOVA tests using EEGLab and FieldTrip capabilities.

**Documentation:** See [EEG_Statistical_Analysis/readme.md](./EEG_Statistical_Analysis/readme.md) for more information.

## Requirements

<!-- TODO: Add specific hardware requirements including:
     - EEG system model and specifications
     - Computer specifications (CPU, RAM, OS)
     - Additional peripherals used in data collection
-->

### Software Dependencies

#### For Stimuli Presentation:
- Python 3.10
- PsychoPy 2023.1.3
- PyAudio 0.2.14
- pylsl 1.16.2 (Lab Streaming Layer)

#### For EEG Processing:
- MATLAB (R2024b)
     - MATLAB Engine API for Python
     - MATLAB toolboxes:
          - Signal Processing Toolbox
          - EEGLab

- EEGLAB (v2024.2)
     - Required plugins (ensure installed and on path):
          - ICLabel == 1.6
          - clean_rawdata == 2.10

- FieldTrip (latest stable release)

- Python (3.10)
     - numpy == 2.3.1
     - pandas == 2.3.1
     - scipy == 1.16.0
     - h5py >= 3.0.0
     - matplotlib
     - pylsl == 1.16.2
     - pyaudio == 0.2.14
     - psychoPy == 2024.2.4

- Additional tools / notes
     - Add EEGLAB and FieldTrip folders to the MATLAB path before running pipelines
     - Install EEGLAB plugins via the EEGLAB menu or place plugin folders under EEGLAB/plugins
     - Ensure MATLAB Engine for Python is built and available to your Python environment (see MATLAB docs)


## Installation

### Stimuli Presentation Setup

1. Install PsychoPy from the [official webpage](https://psychopy.org/) (pip installation often fails)

2. Install additional dependencies using PsychoPy's Python:
```bash
& "C:/Program Files/PsychoPy/python.exe" -m pip install -r "Stimuli Presentation/requirements.txt"
```


### EEG Processing Setup

1. Create a virtual environment:
```bash
python -m venv /path/to/new/virtual/environment
```

2. Activate the virtual environment and install dependencies:
```bash
pip install -r EEG_Processing/requirements.txt
```

3. Install MATLAB and EEGLAB with required plugins (ICLabel, clean_rawdata)

4. Install MATLAB Engine API for Python


## License

### Attribution 4.0 International
[![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/80x15.png)](https://creativecommons.org/licenses/by/4.0/)  



---

### 📜 Citation

If you use the FESSCCo dataset in your work, please cite it as follows:

```bibtex
@article{Metwalli2025,
  title = {},
  volume = {},
  ISSN = {},
  url = {},
  DOI = {},
  number = {},
  journal = {},
  publisher = {},
  author = {},
  year = {},
  month = xxx 
}
```