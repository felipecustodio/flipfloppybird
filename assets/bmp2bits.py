'''
Show bitmap image in binary representation
'''

import os
import sys
from scipy import misc

if (len(sys.argv) < 2):
	print("Usage: bmp2bits.py image_file")
	exit()

path = sys.argv[1]
image = misc.imread(path, flatten = 1)

for line in image:
	for bit in line:
		if (bit == 0):
			print(1, end='')
		if (bit == 255):
			print(0, end='')
	print('')

