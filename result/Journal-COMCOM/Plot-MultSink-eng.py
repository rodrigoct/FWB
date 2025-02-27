"""
Demo of the errorbar function
"""
# -*- coding: utf-8 -*-
from pylab import *
import numpy
import matplotlib.pyplot as plt


# Dual
x = (0,1,2)
#	 Single 	 Dual
y = [59.10000, 63.300000, 70.50000 ]  # media
yerr = [1.920937, 1.004988, 1.8000]  # desvio padrao
width = 0.15 

fig = plt.figure()
plt.rcParams["font.family"] = "Times New Roman"
bar1 = plt.bar(x[0], y[0], width=0.60,color='#fbbc04',  label='1-Sink Node',  yerr=yerr[0], hatch="\\")
plt.errorbar(x[0], y[0], yerr=yerr[0],capsize=8, color='#000000')
bar2 = plt.bar(x[1], y[1], width=0.60,  color='dimgrey',label='2-Sink Nodes',  yerr=yerr[1], hatch="/")
plt.errorbar(x[1], y[1], yerr=yerr[1],capsize=8, color='#000000')

bar3 = plt.bar(x[2], y[2], width=0.60,  color='mediumblue',label='3-Sink Nodes',  yerr=yerr[2], hatch="\/")
plt.errorbar(x[2], y[2], yerr=yerr[2],capsize=8, color='#000000')

plt.ylabel('Packets received per second (pkts/s)',fontsize=16)
plt.xticks(x, ('Sink Node', 'Sink Node', 'Sink Node'),fontsize=16)
plt.legend(fontsize=14)

plt.show()