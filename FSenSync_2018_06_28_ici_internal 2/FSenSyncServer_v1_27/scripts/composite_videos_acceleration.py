#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jun 26 14:55:52 2017

@author: Klaus Förger / Förger Analytics
@version: 1.02
"""

import matplotlib
matplotlib.use('TkAgg')
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
import time
from matplotlib import animation
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
synced_folder = "/Users/loupvuarnesson/Downloads/ya/tate_2/synced"
downloaded_folder = "/Users/loupvuarnesson/Downloads/ya/tate_2/downloaded"
ffmpeg_exec = "ffmpeg"
ffprobe_exec = "ffprobe"
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
if (ffprobe_exec != "ffprobe" and os.path.isfile(ffprobe_exec) == False):
  print('Could not find ffprobe from:' + ffprobe_exec, flush=True)
  exit()
  
#%%

def new_figure(fig_with_multiplier):
  plt.close('all')
  plt.figure(num=1, figsize=(8 * fig_with_multiplier,2), dpi=100)
  plt.clf()
  plt.subplots_adjust(top=0.82,bottom=0.21,
                      left=0.10,right=0.96,
                      hspace=0.2,wspace=0.2)
  

def animate_plot_time(start_time_seconds, end_time_seconds, frame_length, fps, filename):
    ylimits = plt.ylim()
    f = plt.gcf()
    ax = plt.gca()
    line, = ax.plot([], [], 'b-')
    #plt.xticks([], [])
    #plt.yticks([], [])
    frames = int(round((end_time_seconds - start_time_seconds) / frame_length))
    global time_last
    time_last = time.time()
    def init():
        line.set_data([], [])
        return line,
    def animate(i):
        global time_last
        if (time_last < time.time() - 1.0 or i==frames-1):
            time_last = time.time()
            print("\r" + str(i+1) + "/" + str(frames), end='', flush=True)
        offset = i*frame_length
        line.set_data([start_time_seconds + offset, start_time_seconds + offset], ylimits)
        return line,
    print(str(0) + "/" + str(frames), end='')
    anim = animation.FuncAnimation(f, animate, init_func=init,
                                   frames=frames, interval=1, blit=True,
                                   repeat=False)
    anim.save(filename, fps=fps, extra_args=['-vcodec', 'libx264', '-r', '30'])
    print("")
  
  
#%%
  
vid_files = synced_folder + "/*_VID.csv"

# Finding all recordings
all_recordings = []
for ind_all_recordings, file_all_recordings in enumerate(glob.glob(vid_files)):
  
  m = re.search('\d\d\d_\d\d\d_[A-Z]{1,6}.*\.csv$', file_all_recordings)
  this_rec_number = int(file_all_recordings[m.start():m.start()+3])
  
  if (this_rec_number >= first_recording and this_rec_number <= last_recording):
    all_recordings.append(this_rec_number)

all_recordings = np.unique(all_recordings)

for rec_num in all_recordings:

  print('\nProcessing recording ' + str(rec_num) + ':')

  if (rec_num >= first_recording and rec_num <= last_recording):

    rec_str = str(rec_num).zfill(3)
    
    data_file = synced_folder + "/*_" + rec_str + "_*_VID.csv"
    
    # Reading data
    all_data = []
    millis = []
    total_durations = []
    for ind, file in enumerate(glob.glob(data_file)):
      record = {}
      record['data'] = pd.read_csv(file)
      m = re.search('\d\d\d_[A-Z]{1,6}\.csv$', file)
      record['short_id'] = int(file[m.start():m.start()+3])
      record['file'] = file
      record['tag'] = ''
      
      meta_file = (record['file'][0:-3] + "meta")
      file  = open(meta_file, "r")
      file.readline() 
      file.readline() 
      file.readline() 
      record['model'] = file.readline()[8:-1]
      file.close()
      
      all_data.append(record)
    
      if (len(all_data) > 0):
        
        video_file = (all_data[ind]['file'][0:-3] + "mp4").replace("synced", "downloaded", 1)
        video_file = shlex.quote(video_file)
        c1 = ffprobe_exec + " -loglevel 8"
        c1 = c1 + ' -select_streams v:0 -read_intervals "%+#300" -show_frames ' + video_file
        c1 = c1 + ' | grep pkt_duration_time= | sed s/pkt_duration_time=// > temp_video_frame_durations.txt'
        print(c1, flush=True)
        if (os.path.isfile("./temp_video_frame_durations.txt")):
          c0 = 'rm ./temp_video_frame_durations.txt'
          p0 = subprocess.Popen(c0, shell=True)
          p0.wait()
        p1 = subprocess.Popen(c1, shell=True)
        p1.wait()
        
        vid_ffprobe = pd.read_csv('./temp_video_frame_durations.txt', header=None)
        vid_data = all_data[ind]['data']
        
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
          plt.title(all_data[ind]['model'])
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
      
    if (len(all_data) > 0):
      delays = max(millis) - millis
      offsets = millis - min(millis) 
      
      print("Offsets of videos in milliseconds:", flush=True)
      print(offsets, flush=True)
      
      #% Composite creation
      
      cut_video_files = []
      
      for ind, record in enumerate(all_data):
        offsets_this = int(offsets[ind])
        t_hours = math.floor(offsets_this / (1000*60*60))
        t_minutes = math.floor((offsets_this % (1000*60*60)) / (1000*60))
        t_seconds = math.floor((offsets_this % (1000*60)) / (1000))
        t_millis = offsets_this % 1000
        orig_video_file = (all_data[ind]['file'][0:-3] + "mp4").replace("synced", "downloaded", 1)
        new_cut_name = orig_video_file[0:-4] + "_cut_" + str(int(np.min(millis))) + ".mp4"
        new_cut_name = new_cut_name.replace("downloaded", "synced", 1)
        cut_video_files.insert(ind, new_cut_name)
        
        c = ffmpeg_exec + " -loglevel 8 -y -itsoffset "
        c = c + str(t_hours).zfill(2) + ":" + str(t_minutes).zfill(2)
        c = c  + ":" + str(t_seconds).zfill(2) + "." + str(t_millis).zfill(3)
        c = c + " -i " + shlex.quote(orig_video_file)
        c = c + " -vf scale=-2:600 -preset superfast -an " + shlex.quote(cut_video_files[ind])
        
        if (print_commands):
          print(c, flush=True)
        if (only_simulate == False):
          p0 = subprocess.Popen(c, shell=True)
          p0.wait()
      
      if (len(cut_video_files) > 1):
        c2 = ffmpeg_exec + " -loglevel 8"
        c_filter = " -y -filter_complex \""
        orig_video_file = (all_data[0]['file'][0:-3] + "mp4").replace("synced", "downloaded", 1)
        output_file = orig_video_file[0:-11] + "composite_" + str(int(np.min(millis))) + ".mp4"
        output_file = output_file.replace("downloaded", "synced", 1)
        for ind, vid in enumerate(cut_video_files):
          c2 = c2 + " -i " + shlex.quote(vid)
          c_filter = c_filter + "[" + str(ind) + ":v]"
        c_filter = c_filter + "hstack=inputs=" + str(len(cut_video_files)) + "[v]\""
        c2 = c2 + c_filter + " -map \"[v]\" -an -preset superfast " + shlex.quote(output_file)
        if (print_commands):
          print(c2, flush=True)
        if (only_simulate == False):
          p0 = subprocess.Popen(c2, shell=True)
          p0.wait()
      else:
        orig_video_file = (all_data[0]['file'][0:-3] + "mp4").replace("synced", "downloaded", 1)
        output_file = orig_video_file[0:-11] + "composite_" + str(int(np.min(millis))) + ".mp4"
        output_file = output_file.replace("downloaded", "synced", 1)
        c2 = "cp -f " + cut_video_files[ind] + " " + output_file
        if (print_commands):
          print(c2, flush=True)
        if (only_simulate == False):
          p0 = subprocess.Popen(c2, shell=True)
          p0.wait()
        
      video_start_time = int(np.min(millis))
      output_file_name = orig_video_file[0:-11]
      output_file_name = output_file_name.replace("downloaded", "synced", 1)
      composite_video_name = output_file
        
      #%% Acceleration plot
      acc_data_file = synced_folder + "/*_" + rec_str + "_*_ACC.csv"
      acc_data = []
      
      acc_video_files = []
      
      
      for ind, file in enumerate(glob.glob(acc_data_file)):
        record = {}
        record['data'] = pd.read_csv(file)
        m = re.search('\d\d\d_\d\d\d_([^\W^_]{12})?_?[A-Z]{1,6}\.csv$', file)
        record['short_id'] = int(file[m.start()+4:m.start()+7])
        record['file'] = file
        record['tag'] = ''
        
        acc_data.append(record)
        
        new_figure(len(millis)) # Adjusting width to be same as whole width of videos
        
        data_this = record['data']
        plt.plot((data_this['Timestamp(milliseconds)'] - video_start_time) / 1000, data_this['Xacceleration'])
        plt.plot((data_this['Timestamp(milliseconds)'] - video_start_time) / 1000, data_this['Yacceleration'])
        plt.plot((data_this['Timestamp(milliseconds)'] - video_start_time) / 1000, data_this['Zacceleration'])
        
        plt.ylabel('Acceleration')
        plt.xlabel('Time in seconds')
        acc_end_time = np.max(data_this['Timestamp(milliseconds)'])
        seconds_duration = (acc_end_time-video_start_time)/1000
        plt.xlim([0, seconds_duration])
        file_name_acc = output_file_name + str(int(video_start_time)) + "_" + str(ind) + "_acc.mp4"
        file_name_acc = file_name_acc.replace("downloaded", "synced", 1)
        acc_video_files.append(file_name_acc)
        animate_plot_time(0, seconds_duration, 1/20, 20, file_name_acc)
      
      
      command = 'ffmpeg -loglevel 8 -y'
      command = command + ' -i ' + shlex.quote(composite_video_name)
      for ind, acc_vid_file in enumerate(acc_video_files):
        command = command + ' -i ' + shlex.quote(acc_vid_file)
      command = command + ' -filter_complex '
      
      
      command = command + '"'
      command = command + '[0:v:0]pad=iw:ih+' + str(200*len(acc_video_files)) + '[a0]; '
      
      for ind, acc_vid_file in enumerate(acc_video_files):
        if (ind < len(acc_video_files) - 1):
          command = command + '[a' + str(ind) + '][' + str(ind+1) + ':v:0]overlay=0:' + str(600+(ind*200)) + '[a' + str(ind+1) + ']; '
        else:
          command = command + '[a' + str(ind) + '][' + str(ind+1) + ':v:0]overlay=0:' + str(600+(ind*200))
      
      command = command + '"'
      
      command = command + ' -preset superfast'
      #command = command + ' -an'
      #command = command + ' -to ' + to_string
      command = command + ' ' + shlex.quote(output_file_name + "composite_with_acceleration.mp4")
      
      print(command, flush=True)
      
      os.system(command)
            
        
      
      
      #%%

if (os.path.isfile("./temp_video_frame_durations.txt")):
  os.system('rm ./temp_video_frame_durations.txt')

