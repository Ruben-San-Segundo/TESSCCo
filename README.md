# FESSCCo - Full EEG Silent Speech Command Dataset

This repository contains the complete pipeline for the FESSCCo (Full EEG Silent Speech Command) database, a multimodal bio-signal dataset for Silent Speech Interface (SSI) research. The project encompasses experiment design, stimuli presentation, EEG data acquisition, preprocessing, and statistical analysis for both overt (spoken aloud) and covert (silent) speech recognition using brain-computer interface (BCI) technology.

## Overview

FESSCCo provides a comprehensive framework for conducting experiments in silent speech recognition using EEG signals. The repository supports researchers and developers working on:

- **Brain-Computer Interfaces (BCI)** for speech recognition
- **Silent Speech Interfaces (SSI)** using EEG signals
- **Multimodal bio-signal acquisition** for speech studies
- **Deep Learning** applications in neuroscience and speech processing

The dataset focuses on Spanish and English command recognition in both overt and covert speech conditions, providing a rich resource for developing and testing silent speech recognition algorithms.

## Repository Structure

The repository is organized into three main components:

### 1. Stimuli Presentation
**Location:** `Stimuli Presentation/`

Contains the experimental stimuli presentation system built with PsychoPy for data acquisition.

**Key Features:**
- Real-time stimulus presentation with precise timing
- Synchronization with EEG recording systems via LSL (Lab Streaming Layer)
- Audio recording capabilities
- Automated task randomization and session management
- Marker generation for stimulus timing

**Experiment Design:**
The experiment consists of 4 main tasks:
- Covertly pronounce Spanish commands
- Overtly pronounce Spanish commands
- Covertly pronounce English commands
- Overtly pronounce English commands

Each task is repeated once per session in random order, with two sessions completed per subject on different days.

**Documentation:** See [Stimuli Presentation/README.md](./Stimuli%20Presentation/README.md) for detailed setup and usage instructions.

### 2. EEG Processing
**Location:** `EEG_Processing/`

Complete pipeline for EEG signal preprocessing and preparation for analysis.

**Pipeline Stages:**
- **Trimming**: Extract relevant data segments from raw recordings
- **Filtering**: Apply frequency filters to remove noise
- **Epoching**: Segment continuous data into task-relevant epochs
- **ICA**: Independent Component Analysis for artifact removal
- **Label Extraction**: Generate labels for Deep Learning applications

**Technologies:**
- Python for orchestration and data manipulation
- MATLAB/EEGLAB for advanced signal processing
- NumPy, Pandas, SciPy for data analysis

**Documentation:** See [EEG_Processing/readme.md](./EEG_Processing/readme.md) for detailed pipeline documentation.

### 3. EEG Statistical Analysis
**Location:** `EEG_Statistical_Analysis/`

Tools and scripts for statistical analysis of the preprocessed EEG data.

**Documentation:** See [EEG_Statistical_Analysis/readme.md](./EEG_Statistical_Analysis/readme.md) for more information.

## Requirements

### Hardware
- **Minimum**: PC with microphone
- **Full Experiment**: EEG acquisition system (e.g., BitBrain), audio recording equipment, and stimulus presentation display

### Software Dependencies

#### For Stimuli Presentation:
- Python 3.10
- PsychoPy 2023.1.3
- PyAudio 0.2.14
- pylsl 1.16.2 (Lab Streaming Layer)

#### For EEG Processing:
- Python 3.x
- NumPy 2.3.1
- Pandas 2.3.1
- SciPy 1.16.0
- h5py >= 3.0.0
- MATLAB with EEGLAB toolbox
- MATLAB Engine API for Python

## Installation

### Stimuli Presentation Setup

1. Install PsychoPy from the [official webpage](https://psychopy.org/) (pip installation often fails)

2. Install additional dependencies using PsychoPy's Python:
```bash
& "C:/Program Files/PsychoPy/python.exe" -m pip install -r "Stimuli Presentation/requirements.txt"
```

Or install individually:
```bash
& "C:/Program Files/PsychoPy/python.exe" -m pip install pylsl
& "C:/Program Files/PsychoPy/python.exe" -m pip install pyaudio
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

4. Install MATLAB Engine API for Python (from MATLAB installation)

## Quick Start

### Running an Experiment Session

1. Navigate to your desired data storage location:
```bash
cd C:/My_experiments/Subject_00/Session_01
```

2. Execute the main script:
```bash
& "C:/Program Files/PsychoPy/python.exe" "C:/path-to-scripts/script_general.py"
```

The script will:
- Create necessary CSV files for tracking tasks and markers
- Run calibration (first session only)
- Randomly select and present tasks
- Record all data and timestamps

### Processing EEG Data

1. Configure the `Batch_Preprocessing.py` script (lines 19-30) with your data paths

2. Ensure the following directory structure exists:
   - RAW data folder (with Subject_XX/Session_YY structure)
   - Trimmed and translated folder (empty initially)
   - Pre-processed folder (empty initially)

3. Run the batch processing:
```bash
python EEG_Processing/Scripts/Batch_Preprocessing.py
```

The pipeline will automatically:
- Trim and translate timestamps
- Apply filtering and epoching
- Perform ICA
- Extract labels for each epoch

## Data Structure

The repository expects and generates the following directory structure:

```
Data/
├── 1. RAW/
│   └── Subject_XX/
│       └── Session_YY/
│           └── BBT-E32-*/
├── 2. Trimmed and Translated/
│   └── Subject_XX/
│       └── Session_YY/
└── 3. Pre-processed/
    └── Subject_XX/
        └── Session_YY/
```

## Use Cases

This repository supports various research applications:

- **BCI Development**: Build brain-computer interfaces for speech control
- **Silent Speech Recognition**: Develop algorithms to recognize unspoken commands
- **Neuroscience Research**: Study brain activity patterns during speech production
- **Deep Learning**: Train neural networks for EEG-based classification
- **Multimodal Analysis**: Integrate EEG with audio recordings

## Citation

If you use this repository or the FESSCCo database in your research, please cite the relevant publications (refer to DEL-BCI-2 documentation).

## License

Please refer to the repository license for usage terms and conditions.

## Contributing

Contributions to improve the pipeline, add new features, or fix bugs are welcome. Please ensure any changes maintain compatibility with the existing data structure and processing workflow.

## Support

For questions, issues, or contributions, please use the GitHub issue tracker or contact the repository maintainers.

## Acknowledgments

This project supports research in brain-computer interfaces and silent speech recognition, contributing to assistive technologies and human-computer interaction advancements.
