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
y = [26.700000, 59.50000 ]  # media
yerr = [1.004988, 3.640055]  # desvio padrao
width = 0.15 

fig = plt.figure()
plt.rcParams["font.family"] = "Times New Roman"

bar1 = plt.bar(x[0], y[0], width=0.60,color='#fbbc04',  label='Single BW',  yerr=yerr[0], hatch="/")
plt.errorbar(x[0], y[0], yerr=yerr[0],capsize=8, color='#000000')
bar2 = plt.bar(x[1], y[1], width=0.60,  color='dimgrey',label='Wider BW',  yerr=yerr[1], hatch="\\")
plt.errorbar(x[1], y[1], yerr=yerr[1],capsize=8, color='#000000')

plt.ylabel(r"$y$",fontsize=16)
plt.ylabel('Packets received per second (pkts/s)')
plt.xticks(x, ('Sink Node', 'Sink Node'), fontsize=16)
plt.legend(fontsize=14)

plt.show()