 % General communication test script

clear all; 
close all;
clc;
addpath(genpath('C:\Blackrock Microsystems\Binaries'))

% Create stimulator object
stimulator = cerestim96();

% Scan for devices
DeviceList = stimulator.scanForDevices();

% Select a device to connect to
stimulator.selectDevice(DeviceList(1));

% Connect and print library version
stimulator.connect; 
if (stimulator.isConnected())
    disp('IsConnected says we are connected');
else
    disp('IsConnected says we are not connected');
end
stimulator.libraryVersion;

status = stimulator.isConnected(); 
Type = stimulator.getInterface(); 
SafetyStatus = stimulator.isSafetyDisabled(); 

[MinAmp MaxAmp] = stimulator.getMinMaxAmplitude(); 
%SafetyStatus = cerestim.isSafetyDisabled();
% ElectrodeStruct = cerestim.testElectrodes();
% stimulator.stimulusMaxValue(7,9000,1000000,1000); 
% MaxOutputVoltage = stimulator.stimulusMaxValue()
% x = stimulator.maxOutputVoltage(7);
