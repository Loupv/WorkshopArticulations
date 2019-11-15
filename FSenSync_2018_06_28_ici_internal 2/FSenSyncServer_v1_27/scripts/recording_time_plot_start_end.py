#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Oct 26 12:57:03 2017

@author: Klaus Förger / Förger Analytics
@version: 1.00
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import glob
import re
import sys
from operator import itemgetter

#%% Reading command-line arguments

synced_folder = "/home/klaus/FSenSyncExp/erc_tiistai/synced"
downloaded_folder = "/home/klaus/FSenSyncExp/erc_tiistai/downloaded"
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
      last_recording = int(sys.argv[ind_arg + 1])
    except:
      pass
  if (sys.argv[ind_arg] == "-firstRecording"):
    try:
      first_recording = int(sys.argv[ind_arg + 1])
    except:
      pass
  ind_arg += 2

#%% Plotting the start/end times and times of individual samples

data_file = synced_folder + '/*.csv'

m = re.search('/synced/', data_file)
note_file = data_file[0:m.start()]
m = re.search('/\w*$', note_file)
note_file = note_file + "/" + note_file[m.start():m.end()] + "_notes.txt"

plt.figure(1)
plt.clf()

all_data = []
for ind, file in enumerate(glob.glob(data_file)):
    record = {}
    m = re.search('\d\d\d_\d\d\d_[A-Z]{1,6}.*\.csv$', file)
    record['short_id'] = int(file[m.start()+4:m.start()+7])
    record['recording_num'] = int(file[m.start():m.start()+3])
    
    if (record['recording_num'] >= first_recording 
        and record['recording_num'] <= last_recording):
      
      record['data'] = pd.read_csv(file)
      record['file'] = file
      
      record['tag'] = ''
      if (len(record['data']) > 0):
        all_data.append(record)
        
      try:
        meta_file = (record['file'][0:-3] + "meta").replace("synced", "downloaded", 1)
        file  = open(meta_file, "r")
        file.readline() 
        file.readline() 
        file.readline() 
        record['model'] = file.readline()[8:-1]
        file.close()
      except:
        pass

all_data = sorted(all_data, key=itemgetter('file'))

names = []
for ind, data in enumerate(all_data):
  m = re.search('_\d\d\d_\d\d\d_[A-Z]{1,6}.*', data['file'])
  names.append(data['file'][m.start()+1:m.end()])

min_stamp = []
for ind, record in enumerate(all_data):
  min_stamp.append(record['data'].iloc[0, 0])
min_stamp = np.min(min_stamp)

for ind, record in enumerate(all_data):
    plt.plot(([record['data'].iloc[0, 0], record['data'].iloc[-1, 0]] - min_stamp) / 60000, np.array([ind, ind]) + 0.0)
    #plt.plot((record['data'].iloc[:, 0] - min_stamp) / 60000, np.ones((len(record['data'].iloc[:, 0]))) * ind, 'x')
    
plt.ylim(plt.ylim()[0] -1, plt.ylim()[1] +1)
plt.yticks(range(len(all_data)), names)
plt.xlabel('Time in minutes')

plt.subplots_adjust(left=0.25)
plt.title('Recording times starting from earliest timestamp')


#%% Plot notes

notes = pd.read_csv(note_file, header=None)
ylimits = plt.ylim()
xlimits = plt.xlim()
for index, row in notes.iterrows():
    row_time = (row[0] - min_stamp)/ 60000
    if (row_time > xlimits[0] and row_time < xlimits[1]):
        plt.plot((row_time, row_time), ylimits, 'k--')
        plt.text(row_time, ylimits[0], row[2], rotation='vertical', va='bottom', ha='right')

#%% Showing the plots

plt.show()

