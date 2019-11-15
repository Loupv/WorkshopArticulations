#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Oct 23 09:09:47 2017

@author: Klaus Förger / Förger Analytics
@version: 1.00
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
    downloaded_folder = sys.argv[ind_arg + 1] + '/'
  if (sys.argv[ind_arg] == "-synced"):
    synced_folder = sys.argv[ind_arg + 1]  + '/'
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
      
#%% Matching streamed BioHarness with the FSenSync data and outputting files with new timestamps

print("", flush=True)
print("Processing files...", flush=True)

def processMatchingFiles(fileName, syncRecord, downloaded_f):
  extra_delay = 0
  if (fileName.endswith('ACC.csv')):
    extra_delay = 0
  if (fileName.endswith('BRE.csv')):
    extra_delay = -405
  if (fileName.endswith('ECG.csv')):
    extra_delay = 155
  if (fileName.endswith('SUM.csv')):
    extra_delay = 1000
  try:
    streamedHarnessFile = open(downloaded_f + fileName, 'r')
    lines = streamedHarnessFile.readlines()
    data = pd.read_csv(downloaded_f + fileName)
    unit_names = np.unique(data.iloc[:, 0])
    if not os.path.exists(synced_folder):
      os.makedirs(synced_folder)
    for indUnit, unitName in enumerate(unit_names):
      if (unitName == syncRecord['harness']):
        outputFileName = fileName[0:-4] + '_' + unitName[3:] + '.csv'
        harnessOutput = open(synced_folder + outputFileName, 'w')
        ind_comma = lines[0].find(',')
        ind_comma2 = lines[0].find(',', ind_comma+1)
        harnessOutput.write('Timestamp(milliseconds)' + lines[0][ind_comma2:])
        for ind_line in range(1, len(lines)):
          try:
            ind_comma = lines[ind_line].find(',')
            if (ind_comma > 0 and lines[ind_line][0:ind_comma] == unitName):
              ind_comma2 = lines[ind_line].find(',', ind_comma+1)
              time_str = lines[ind_line][ind_comma+1:ind_comma2]
              stamp = datetime.datetime.strptime(time_str, "%d/%m/%Y %H:%M:%S.%f").timestamp() * 1000
              stamp = stamp + syncRecord['polynom'](stamp) - extra_delay
              harnessOutput.write(str((int)(stamp)) + lines[ind_line][ind_comma2:-1] + '\n')
          except:
            pass
        streamedHarnessFile.close()
        harnessOutput.close()
        
        print('Processed file: ' + fileName + ' > ' + outputFileName, flush=True)
  except:
    print('Problem while processing file:' + fileName, flush=True)

for ind_s, sync_record in enumerate(sync_info):
  
  file_base = sync_record['sync_file'][0:-4]

  processMatchingFiles(file_base + 'ACC.csv', sync_record, downloaded_folder)
  processMatchingFiles(file_base + 'BRE.csv', sync_record, downloaded_folder)
  processMatchingFiles(file_base + 'ECG.csv', sync_record, downloaded_folder)
  processMatchingFiles(file_base + 'SUM.csv', sync_record, downloaded_folder)

