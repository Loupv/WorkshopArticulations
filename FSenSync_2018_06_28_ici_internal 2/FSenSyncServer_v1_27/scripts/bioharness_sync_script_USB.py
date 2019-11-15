#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Oct 23 09:09:47 2017

@author: Klaus Förger / Förger Analytics
@version: 1.01
"""

import pandas as pd
import datetime
import numpy as np
import os
import sys

#%% Data paths

synced_folder = ""
downloaded_folder = ""
first_recording = 1
last_recording = sys.maxsize

ind_arg = 1
while (len(sys.argv) > ind_arg + 1):
  if (sys.argv[ind_arg] == "-downloaded"):
    downloaded_folder = sys.argv[ind_arg + 1]
  if (sys.argv[ind_arg] == "-synced"):
    synced_folder = sys.argv[ind_arg + 1]
  if (sys.argv[ind_arg] == "-lastRecording"):
    try:
      last_recording = int(sys.argv[ind_arg + 1]) # Note: This is currently ignored
    except:
      pass
  if (sys.argv[ind_arg] == "-firstRecording"):
    try:
      first_recording = int(sys.argv[ind_arg + 1]) # Note: This is currently ignored
    except:
      pass
  ind_arg += 2

print('Harness folder: ' + downloaded_folder,flush=True)
print('Synced folder: ' + synced_folder, flush=True)
print('Output folder: ' + synced_folder, flush=True)

#%% Loading FSenSync data and calculating timestamp corrections

print("", flush=True)
print("Reading FSenSync files...", flush=True)

sync_info = []

if (len(synced_folder) > 0):
  for dirname, dirnames, filenames in os.walk(synced_folder):
    for filename in filenames:
      if (filename.endswith('_BIO.csv')):
        sync_data = pd.read_csv(os.path.join(dirname, filename))
        harnesses_in_file = np.unique(sync_data.iloc[:, 1])
        for ind_har, harness in enumerate(harnesses_in_file):
          
          # Extracting timestamps from sent by the harness and receival timestamps from the app
          inds = sync_data.iloc[:, 1] == harness
          data = sync_data.loc[inds, :]
          stamps_server_time = data.iloc[:, 0].values
          stamps_harness_time = []
          for ind, h_record in enumerate(data.iloc[:, 2]):
            stamps_harness_time.append(datetime.datetime.strptime(h_record, "%d/%m/%Y %H:%M:%S.%f").timestamp() * 1000)
          
          # Calculating a constant time difference
          all_time_diffs = stamps_server_time - stamps_harness_time
          constant_time_diff = np.min(all_time_diffs)
          
          # Estimating the harness clock drift if we have more than 90 seconds of data
          t_span = 40000
          t_step = 10000
          if ((stamps_harness_time[-1] - stamps_harness_time[0]) > (t_span*2) + t_step):
            t_intervals = np.arange(stamps_harness_time[0],stamps_harness_time[-1] - t_span,t_step)
            sliding_values = []
            sliding_times = []
            for t in t_intervals:
              inds_t = np.logical_and(np.array(stamps_harness_time) > t,
                                      np.array(stamps_harness_time) < t + t_span)
              these_values = np.array(stamps_server_time)[inds_t] - np.array(stamps_harness_time)[inds_t]
              sliding_values.append(np.min(these_values))
              sliding_times.append(stamps_harness_time[np.argmin(these_values) + np.min(np.where(inds_t == True))])
      
            coeff = np.polyfit(sliding_times, sliding_values, 1)
            time_diff_polynom = np.poly1d(coeff)
          else:
            time_diff_polynom = np.poly1d([constant_time_diff])
            
          sync_record = {}
          sync_record['sync_file'] = filename
          sync_record['polynom'] = time_diff_polynom
          sync_record['harness'] = harness
          sync_record['harness_time_start'] = stamps_harness_time[0]
          sync_record['harness_time_end'] = stamps_harness_time[-1]
          sync_record['matched'] = []
          sync_record['num_samples'] = len(stamps_harness_time)
          sync_record['almost_matched'] = False
          sync_info.append(sync_record)

#%% Finding data files from BioHarness folder

print("", flush=True)
print("Reading BioHarness files...", flush=True)

downloaded_folder_info = []

if (len(downloaded_folder) > 0):
  for dirname, dirnames, filenames in os.walk(downloaded_folder):
    for filename in filenames:
      if (filename.endswith('SessionInfo.txt')):
        
        # Getting serial number of the harness from the files
        serialNumber = ''
        sessionInfoFile = open(os.path.join(dirname, filename), 'r')
        lines = sessionInfoFile.readlines()
        for line in lines:
          if line.startswith('Serial number: '):
            serialNumber = line[15:-1]
        sessionInfoFile.close()
        
        stamps = []
        # Finding start and end times of the harness recording
        try:
          summaryFile = open(os.path.join(dirname, filename).replace('SessionInfo.txt', 'Summary.csv'))
          lines = summaryFile.readlines()
  
          for line in lines:
            try:
              time_str = line.split(',')[0]
              stamps.append(datetime.datetime.strptime(time_str, "%d/%m/%Y %H:%M:%S.%f").timestamp() * 1000)
            except:
              pass
          summaryFile.close()
        except:
          print('Not found: ' + os.path.join(dirname, filename).replace('SessionInfo.txt', 'Summary.csv'), flush=True)  
        
        if (len(stamps) > 2):
          harness_record = {}
          harness_record['file_name_start'] = os.path.join(dirname, filename).replace('SessionInfo.txt', '') 
          harness_record['start_stamp'] = stamps[0]
          harness_record['end_stamp'] = stamps[-1]
          harness_record['name'] = serialNumber
          harness_record['matched'] = []
          downloaded_folder_info.append(harness_record)
      
#%% Matching BioHarness folders with the FSenSync data and outputting files with new timestamps

print("", flush=True)
print("Matching files...", flush=True)

def processMatchingFiles(fileName, syncRecord, harnessRecord):
  zephyr_acceleration_delay = 405
  try:
    accelerationFile = open(harnessRecord['file_name_start'] + fileName, 'r')
    lines = accelerationFile.readlines()
    if not os.path.exists(synced_folder):
      os.makedirs(synced_folder)
    textid = ''
    if (fileName == 'Accel.csv'):
      textid = 'ACCUSB'
    if (fileName == 'Breathing.csv'):
      textid = 'BREUSB'
    if (fileName == 'ECG.csv'):
      textid = 'ECGUSB'
    if (fileName == 'Summary.csv'):
      textid = 'SUMUSB'
    accelerationOutputFile = open(synced_folder + '/'
                                  + syncRecord['sync_file']
                                  .split('/')[-1]
                                  .replace('.csv', textid + '_' + harness_record['name'] + '.csv'), 'w')
    accelerationOutputFile.write(lines[0])
    for ind_line in range(1, len(lines)):
      try:
        ind_comma = lines[ind_line].find(',')
        if (ind_comma > 0):
          time_str = lines[ind_line][0:ind_comma]
          stamp = datetime.datetime.strptime(time_str, "%d/%m/%Y %H:%M:%S.%f").timestamp() * 1000
          stamp = stamp + syncRecord['polynom'](stamp) - zephyr_acceleration_delay
          accelerationOutputFile.write(str((int)(stamp)) + lines[ind_line][ind_comma:-1] + '\n')
      except:
        pass
    accelerationFile.close()
    accelerationOutputFile.close()
  except:
    print('Problem while reading file:' + harness_record['file_name_start'] + fileName, flush=True)

for ind_h, harness_record in enumerate(downloaded_folder_info):
  
  print("Harness folder " + str(ind_h + 1) + '/' + str(len(downloaded_folder_info)), flush=True)
  
  longest_sync_record = []
  longest_samples = 0
  
  for ind_s, sync_record in enumerate(sync_info):
    
    sync_time = np.mean([sync_record['harness_time_start'], sync_record['harness_time_end']])
    
    if (sync_record['harness'].endswith(harness_record['name'])
          and sync_time < harness_record['end_stamp'] 
          and sync_time > harness_record['start_stamp']):
      if (sync_record['num_samples'] > longest_samples):
        longest_sync_record = sync_record
        longest_samples = sync_record['num_samples']
        sync_record['almost_matched'] = True
  
  if (longest_samples > 0):
    processMatchingFiles('Accel.csv', longest_sync_record, harness_record)
    processMatchingFiles('Breathing.csv', longest_sync_record, harness_record)
    processMatchingFiles('ECG.csv', longest_sync_record, harness_record)
    processMatchingFiles('Summary.csv', longest_sync_record, harness_record)
    
    # The BB and RR files do not have any timestamps, thus they cannot be synced
    #processMatchingFiles('BB.csv', longest_sync_record, harness_record)
    #processMatchingFiles('RR.csv', longest_sync_record, harness_record)
    
    harness_record['matched'].append(longest_sync_record['sync_file'].replace(synced_folder, '', 1))
    longest_sync_record['matched'].append(harness_record['file_name_start'].replace(downloaded_folder, '', 1))
 
      
#%% Printing outputs and files that were not matched

all_harnesses_matched = True
all_fsensync_matched = True

print("", flush=True)
print("Successful matches:", flush=True)

for ind_h, harness_record in enumerate(downloaded_folder_info):
  if (len(harness_record['matched']) == 1):
    name = harness_record['file_name_start'].replace(downloaded_folder, '', 1)
    print(name + '* with: ' + harness_record['matched'][0], flush=True)
  else:
    all_harnesses_matched = False

for ind_s, sync_record in enumerate(sync_info):
  if (len(sync_record['matched']) == 0 and not sync_record['almost_matched']):
    all_fsensync_matched = False

if (all_harnesses_matched and all_fsensync_matched):
  print("", flush=True)
  print('All files matched.', flush=True)
else:
  
  if (not all_harnesses_matched):
    print("", flush=True)
    print("Could not match harness data from:", flush=True)
    for ind_h, harness_record in enumerate(downloaded_folder_info):
      if (len(harness_record['matched']) == 0):
        name = harness_record['file_name_start'] + '*'
        print(name, flush=True)
  
  if (not all_fsensync_matched):
    print("", flush=True)
    print("Could not match FSenSync data from:", flush=True)
    for ind_s, sync_record in enumerate(sync_info):
      if (len(sync_record['matched']) == 0 and not sync_record['almost_matched']):
        name = sync_record['sync_file']
        print(name + ' harness: ' + sync_record['harness'], flush=True)
        
  print("", flush=True)
  print('All files were NOT matched.', flush=True)
