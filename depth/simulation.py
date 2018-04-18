#! /usr/bin/python
import sys

from TOSSIM import *
#from RequestTopo import *


def simul():
	t = Tossim([])
	r = t.radio()
	f = open("topo2c.txt", "r")
	n = 7


	for line in f:
	  s = line.split()
	  if s:
	    print " ", s[0], " ", s[1], " ", s[2]
	    r.add(int(s[0]), int(s[1]), float(s[2]))

	t.addChannel("Boot", sys.stdout)
	#t.addChannel("RequestTopo", sys.stdout)
	#t.addChannel("RequestData", sys.stdout)
	#t.addChannel("Receive", sys.stdout)
	t.addChannel("Matrix", sys.stdout)
	saida = open("saida_simulacao.txt", "w")
	#saidaP = open("saidaSink.txt", "w")
	t.addChannel("RequestTopo", saida)
	t.addChannel("RequestTopo", sys.stdout)
	t.addChannel("Time", sys.stdout)
	#t.addChannel("Matrix", saida)
	#t.addChannel("Vazao", saida)
	#t.addChannel("Vazao2", saidaP)


	noise = open("meyer-light.txt", "r")
	for line in noise:
	  str1 = line.strip()
	  if str1:
	    val = int(str1)
	    for i in range(0, n):
	      t.getNode(i).addNoiseTraceReading(val)

	for i in range(0, n):
	  print ("Creating noise model for ",i)
	  t.getNode(i).createNoiseModel()
	  t.getNode(i).bootAtTime(1001)


	for i in range(100000):
	  t.runNextEvent()




def main():
	simul()

if __name__ == '__main__':
	main()
