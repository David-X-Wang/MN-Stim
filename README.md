# MNstimulation
The multi-noise stimulation is a part of the brain-computer interface development at the Texas Computational Memory Lab (Lega Lab), Department of Neurological Surgery, UT Southwestern Medical Center, Dallas, Texas, USA.

Multi-Noise stimulation paradigm is a open-loop deep brain stimulation (DBS) paradigm that applies biphasic charge-balanced electrical pulses directly to the target brain cortecies. This open loop DBS aims at capturing neural dymanical reponses of certain brain regions (neocortecies and hippocampus) for the system identification (predictive modeling) in the development of a closed-loop brain computer interfaces. 

This paradigm is based on Neural Signal Processor (NSP), Cerestim R96 Stimulator and other relavent peripheral devices (including cables, front-end amplifier, adaptors, etc) manufactured by Blackrock Neurotech (https://blackrockneurotech.com/). The hardware with human-in-the-loop configuration is listed as follows, in parallel to the clinical Nihon Kodhen EEG system at the Epilepsy Monitoring Unit (EMU). Specific customized cable adaptors are required. 

![blackrocksetup!](https://github.com/David-X-Wang/MNstimulation/blob/main/blackrock_setup/blackrock_wiring_setup.png?raw=true)



This open-source repositories include:  

1. NSP_codes: Scripts and configurations for multi-noise stimulation using Ceresetim.
   Dependency: BlackrockNeurotech Neural Processing Matlab Kit (NPMK) (https://github.com/BlackrockNeurotech/NPMK)
2. Cerestim_cose: Scripts and configurations for processing iEEG collected by NSP module.
   Dependency: 
4. 


