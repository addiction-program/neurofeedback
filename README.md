Real-Time Neurofeedback and Cue Reactivity Experiment Suite: A Tool for Investigating Addiction and Mental Health
This repository houses a suite of scripts developed for conducting real-time neurofeedback (rt-NFB) and cue reactivity fMRI experiments. These tools are designed to integrate with fMRI data acquisition, facilitating the investigation of brain-behavior relationships, particularly within the context of addiction and mental health. This project is proudly affiliated with the Neuroscience of Addiction and Mental Health Program at Australian Catholic University (ACU).

All scripts within this repository have been developed and continuously refined by Amir Hossein Dakhili (amirhossein.dakhili@myacu.edu.au), PhD student at the Australian Catholic University. This work builds upon foundational contributions, notably by Saampras Ganesan and Aniko Kusztor.

Project Overview
The core purpose of this suite is to enable participants to learn to self-regulate specific brain regions in real time and to precisely quantify brain responses to craving cues. This offers a powerful paradigm for both basic neuroscience research and exploring potential therapeutic interventions. The workflow encompasses:

Real-Time Neurofeedback Task Execution: The primary script, Neurofeedback script, runs the fMRI experiment, presenting visual stimuli and providing participants with continous feedback on their brain activity.
Cue Reactivity fMRI Task Execution: The CR_fMRI_main script provides a general framework for presenting a cue reactivity task within an fMRI environment, including behavioral assessments.
Offline Log File Processing for Analysis: these scripts (CR_prt, NFB_prt) convert raw experimental log data into standardized formats (TurboBrainVoyager PRT files) for real-time fMRI data analysis.
Simulation and Testing Utilities: A utility script (copy_rtps_with_delay) allows for realistic offline testing of the real-time feedback system by simulating the data stream from an fMRI scanner.

CODE author- Amir Hossein Dakhili- amirhossein.dakhili@myacu.edu.au
Advice: Chao Suo- chao.suo@myacu.edu.au, Saampras Ganesan - saampras.ganesan@gmail.com

