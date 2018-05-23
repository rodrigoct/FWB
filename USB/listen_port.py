#!/usr/bin/env python
# execute : python t.py serial@/dev/ttyUSB0:115200
import sys
sys.path.insert(0, 'sdk/python/')
import tos
import os
import time

class Write_File(object):
	"""docstring for Write_File"""
	def __init__(self):
		
		self.way = sys.argv[1]		
		print "wah", self.way
		self.write()
			
	def write(self):
		
		f = open("arquivo" +'.txt', 'a')
		am = tos.AM()
		
		while True:
			p = am.read()
		   	f.write(str(p))
		   	
		    #print p
		


def main():
	run = Write_File()

if __name__ == '__main__':
    main()

