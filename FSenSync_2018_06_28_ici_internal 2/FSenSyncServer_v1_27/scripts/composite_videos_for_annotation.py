#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jun 26 14:55:52 2017

@author: Klaus Förger / Förger Analytics
@version: 1.02
"""

import glob
import re
import pandas as pd
import os
import math
import matplotlib.pyplot as plt
import numpy as np
import sys
import subprocess
import os.path
from operator import itemgetter
import shlex

#%% General settings

# Note: This script will work only on Linux and Mac computers.
# Note: ffmpeg must be installed and working from command-line.

only_simulate = False
print_commands = True
debug_timing_plots = False 

#%% Reading command-line arguments

# These are default values that are overriden by arguments.
# Change these manually if you are running the script without arguments.
synced_folder = "/home/klaus/FSenSyncExp/vi_anno_t8/synced"
downloaded_folder = "/home/klaus/FSenSyncExp/vi_anno_t8/downloaded"
ffmpeg_exec = "ffmpeg"
ffprobe_exec = "ffprobe"
first_recording = 2
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
  if (sys.argv[ind_arg] == "-binpath"):
    try:
      ffmpeg_exec = sys.argv[ind_arg + 1] + '/' + 'ffmpeg'
      ffprobe_exec = sys.argv[ind_arg + 1] + '/' + 'ffprobe'
    except:
      pass
  ind_arg += 2
  
ffmpeg_exec = shlex.quote(ffmpeg_exec)
ffprobe_exec = shlex.quote(ffprobe_exec)

if (ffmpeg_exec != "ffmpeg" and os.path.isfile(ffmpeg_exec) == False):
  print('Could not find ffmpeg from:' + ffmpeg_exec, flush=True)
  exit()
if (ffprobe_exec != "ffprobe" and os.path.isfile(ffmpeg_exec) == False):
  print('Could not find ffprobe from:' + ffprobe_exec, flush=True)
  exit()
  
  
#%% Listing all video files and reading metadata
  
vid_files_pattern = synced_folder + "/*_VID.csv"

video_file_list = []

# Finding all recordings
recording_groups = []
for ind_all_recordings, this_file in enumerate(glob.glob(vid_files_pattern)):
  
  m = re.search('\d\d\d_\d\d\d_[A-Z]{1,6}.*\.csv$', this_file)
  this_rec_number = int(this_file[m.start():m.start()+3])
  
  if (this_rec_number >= first_recording and this_rec_number <= last_recording):
    
    record = {}
    record['data'] = pd.read_csv(this_file)
    m = re.search('\d\d\d_[A-Z]{1,6}\.csv$', this_file)
    record['short_id'] = int(this_file[m.start():m.start()+3])
    record['file'] = this_file
    record['tag1'] = ''
    record['tag2'] = ''
    record['tag3'] = ''
    record['model'] = ''
    
    record['rec_number'] = this_rec_number
    
    meta_file = (record['file'][0:-3] + "meta").replace("synced", "downloaded", 1)
    file  = open(meta_file, "r")
    lines = file.readlines()
    file.close()
    
    for ind, line in enumerate(lines):
      if (line.startswith("Server tag 1:")):
        record['tag1'] = line.replace("Server tag 1:", '').strip()
      if (line.startswith("Server tag 2:")):
        record['tag2'] = line.replace("Server tag 2:", '').strip()
      if (line.startswith("Server tag 3:")):
        record['tag3'] = line.replace("Server tag 3:", '').strip()
      if (line.startswith("Device: ")):
        record['model'] = line.replace("Device: ", '').strip()
    
    record['sorting_id'] = str(this_rec_number) +  ', ' + record['tag1']
    
    video_file_list.append(record)
    
    recording_groups.append(record['sorting_id'])
    

recording_groups = np.unique(recording_groups)


#%%

for rec_group in recording_groups:

  print('\nProcessing recording: ' + str(rec_group))
  
  this_group = []
  
  for ind, record in enumerate(video_file_list):
    if (record['sorting_id'] == rec_group):
      this_group.append(record)
  
  this_group = sorted(this_group, key=itemgetter('tag2'))
    
  if (len(this_group) > 0):
    
    millis = []
    for ind in range(len(this_group)):
      
      video_file = (this_group[ind]['file'][0:-3] + "mp4").replace("synced", "downloaded", 1)
      c1 = ffprobe_exec + " -loglevel 8"
      c1 = c1 + ' -select_streams v:0 -read_intervals "%+#300" -show_frames ' + shlex.quote(video_file)
      c1 = c1 + ' | grep pkt_duration_time= | sed s/pkt_duration_time=// > temp_video_frame_durations.txt'
      print(c1, flush=True)
      if (os.path.isfile("./temp_video_frame_durations.txt")):
        c0 = 'rm ./temp_video_frame_durations.txt'
        p0 = subprocess.Popen(c0, shell=True)
        p0.wait()
      p1 = subprocess.Popen(c1, shell=True)
      p1.wait()
      
      vid_ffprobe = pd.read_csv('./temp_video_frame_durations.txt', header=None)
      vid_data = this_group[ind]['data']
      
      frame_stamps = np.zeros(len(vid_data.iloc[:-1, 2]))
      for ind2, row in enumerate(vid_data.iloc[:-1, 2]):
        frame_stamps[ind2] = (vid_data.iloc[ind2+1, 2] - vid_data.iloc[ind2, 2]) / 1000000000
        
      stamps_diffs =  np.zeros(len(vid_data.iloc[:-1, 0]))
      for ind2, row in enumerate(vid_data.iloc[:-1, 0]):
        stamps_diffs[ind2] = (vid_data.iloc[ind2+1, 0] - vid_data.iloc[ind2, 0]) / 1000
      
      if (debug_timing_plots):
        plt.figure(100+ind)
        plt.clf()
        plt.plot(stamps_diffs, 'g-*')
        plt.plot(frame_stamps, 'r-o')
        plt.plot(vid_ffprobe, 'b-x')
        plt.title(this_group[ind]['model'])
        plt.legend(['server stamps', 'frame stamps', 'ffprobe'])
      
      mean_offset_stamp_framestamp = np.mean(vid_data.iloc[:, 0] - (vid_data.iloc[:, 2] / 1000000))
  
      diffs = np.zeros(10)
      for offset in range(len(diffs)):
        min_len = np.min([len(vid_ffprobe)-1, len(frame_stamps)-1-offset])
        diffs[offset] = np.mean(np.abs(vid_ffprobe.iloc[1:min_len-offset, 0] - frame_stamps[1+offset:min_len]))
      min_offset = diffs.argmin(0)
      
      #print(min_offset, flush=True)
      #print("\n", flush=True)
      
      constant_video_lag = 95
      lag_from_stuttering_first_frame = ((vid_ffprobe.iloc[0].values - frame_stamps[min_offset]) * 1000)
      real_start_time = (vid_data.iloc[min_offset, 2] / 1000000) + (
                          mean_offset_stamp_framestamp 
                          - constant_video_lag 
                          - lag_from_stuttering_first_frame)
      
      millis.append(real_start_time)
      #print(record['model'], flush=True)
    
    if (len(this_group) > 0):
      delays = max(millis) - millis
      offsets = millis - min(millis) 
      
      print("Offsets of videos in milliseconds:", flush=True)
      print(offsets, flush=True)
      
      #% Composite creation
      
      cut_video_files = []
      
      for ind, record in enumerate(this_group):
        offsets_this = int(offsets[ind])
        t_hours = math.floor(offsets_this / (1000*60*60))
        t_minutes = math.floor((offsets_this % (1000*60*60)) / (1000*60))
        t_seconds = math.floor((offsets_this % (1000*60)) / (1000))
        t_millis = offsets_this % 1000
        orig_video_file = (this_group[ind]['file'][0:-3] + "mp4").replace("synced", "downloaded", 1)
        cut_video_files.insert(ind, orig_video_file[0:-4] + "_cut_" + str(int(np.min(millis))) + ".mp4")
        
        c = ffmpeg_exec + " -loglevel 8 -y -itsoffset "
        c = c + str(t_hours).zfill(2) + ":" + str(t_minutes).zfill(2)
        c = c  + ":" + str(t_seconds).zfill(2) + "." + str(t_millis).zfill(3)
        c = c + " -i " + shlex.quote(orig_video_file)
        c = c + " -vf scale=-2:450 -preset superfast -an " + shlex.quote(cut_video_files[ind])
        
        if (print_commands):
          print(c, flush=True)
        if (only_simulate == False):
          p0 = subprocess.Popen(c, shell=True)
          p0.wait()
      
      c2 = ffmpeg_exec + " -loglevel 8"
      c_filter = " -y -vcodec libx264 -x264-params keyint=30 "
      orig_video_file = (this_group[0]['file'][0:-3] + "mp4").replace("synced", "downloaded", 1)
      group_name = record['tag1'].replace(' ', '-')
      group_name = re.sub('[^a\w-]', '', group_name)
      output_file = orig_video_file[0:-11] + "annotation_" + group_name + '_' +  str(int(np.min(millis))) + ".mp4"
      
      if (len(cut_video_files) == 1): # Case: one input video
        c2 = c2 + " -i " + shlex.quote(cut_video_files[0])
        c2 = c2 + c_filter + " -an -r 30 -preset superfast " + shlex.quote(output_file)
      
      if (len(cut_video_files) == 2): # Case: two input videos
        c_filter = c_filter + "-filter_complex \""
        for ind, vid in enumerate(cut_video_files):
          c2 = c2 + " -i " + shlex.quote(vid)
          c_filter = c_filter + "[" + str(ind) + ":v]"
        c_filter = c_filter + "hstack=inputs=" + str(len(cut_video_files)) + "[v]\""
        c2 = c2 + c_filter + " -map \"[v]\" -an -r 30 -preset superfast " + shlex.quote(output_file)
      
      if (len(cut_video_files) > 2): # Case: three or more input videos
        column_count = np.ceil(np.sqrt(len(cut_video_files)))
        row_count = np.ceil(len(cut_video_files) / column_count)
        c_filter = c_filter + "-filter_complex \""
        for ind, vid in enumerate(cut_video_files):
          c2 = c2 + " -i " + shlex.quote(vid)
          if (ind == 0):
            c_filter = c_filter + '[0:v:0]pad=' + str(int(column_count*600)) + ':' + str(int(row_count*450)) + '[vid0]'
          if (ind > 0):
            this_row = np.floor(ind / column_count)
            this_column = ind - (this_row * column_count)
            #print('row: ' + str(this_row) + ' col: ' + str(this_column))
            c_filter = c_filter + '; [vid' + str(ind-1) + '][' + str(ind) + ':v:0]'
            c_filter = c_filter + 'overlay=' + str(int(this_column*600)) + ':' + str(int(this_row*450))
            c_filter = c_filter + '[vid' + str(ind) + ']'
        c2 = c2 + c_filter + "\" -map \"[vid" + str(ind) + "]\" -an -r 30 -preset superfast " + shlex.quote(output_file)
      
      if (print_commands):
        print(c2, flush=True)
      if (only_simulate == False):
        p0 = subprocess.Popen(c2, shell=True)
        p0.wait()

if (os.path.isfile("./temp_video_frame_durations.txt")):
  os.system('rm ./temp_video_frame_durations.txt')
