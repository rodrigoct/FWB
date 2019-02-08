"""
Demo of the errorbar function
"""
# -*- coding: utf-8 -*-
from pylab import *
import numpy
import matplotlib.pyplot as plt


# Dual
x = (0,1)
#	 Single 	 Dual
y = [21, 112 ]  # media
yerr = [1.26491, 3.66]  # desvio padrao
width = 0.15 

fig = plt.figure()
#ax = plt.axes()
#fig, ax = plt.subplots()
plt.rcParams["font.family"] = "Times New Roman"
#plt.xticks(np.arange(min(x), max(x)+1, 1.0), x)
# standard error bars
bar1 = plt.bar(x[0], y[0], width=0.60,color='#fbbc04',  label='Single BW',  yerr=yerr[0], hatch="/")
plt.errorbar(x[0], y[0], yerr=yerr[0],capsize=8, color='#000000')
bar2 = plt.bar(x[1], y[1], width=0.60,  color='dimgrey',label='Wider BW',  yerr=yerr[1], hatch="\\")
plt.errorbar(x[1], y[1], yerr=yerr[1],capsize=8, color='#000000')

#plt.yticks(labelsize=40)
plt.ylabel(r"$y$",fontsize=14)
#plt.xlabel(r"$y$",fontsize=12)

#plt.xlabel('Node ID')
plt.ylabel('Packets received per second (pkts/s)',fontsize=16)
plt.xticks(x, ('Sink Node', 'Sink Node'),fontsize=16)
plt.legend(fontsize=14)

plt.show()