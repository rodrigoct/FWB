#!/usr/bin/env python
# execute : python t.py serial@/dev/ttyUSB0:115200
import sys
import tos



name = sys.argv[2]
caminho = sys.argv[3]
print name
am = tos.AM()
f = open("/opt/tinyos-2.1.2/files_users/"+str(name) + str(caminho) + '.txt', 'wb')
while True:
    p = am.read()
    if p:
    	f.write(str(p))

        print p
f.close()
