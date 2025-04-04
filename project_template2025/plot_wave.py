"""
Plots the content of a WAV file.
Adapted from https://stackoverflow.com/questions/18625085/how-to-plot-a-wav-file
"""

import argparse
from scipy.io.wavfile import read
import matplotlib.pyplot as plt
from os.path import basename

# Command line argument parsing
description = "Plots the content of a WAV file."
parser = argparse.ArgumentParser(description=description)
# Positional argument: WAV file relative path
parser.add_argument("filename", help="WAV file relative path")
args = parser.parse_args()

# read audio samples
input_data = read(args.filename)
audio = input_data[1]

# plot the first 1024 samples
plt.plot(audio)

# label the axes
plt.ylabel("Amplitude")
plt.xlabel("Time")

# set the title  
plt.title(basename(args.filename))

# display the plot
plt.show()
