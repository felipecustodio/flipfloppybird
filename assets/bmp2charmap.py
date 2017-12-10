'''
Show bitmap image in charmap representation

Copying to clipboard:
python bmp2charmap.py image | xclip -selection c  
'''

import os
import sys
from scipy import misc

if (len(sys.argv) < 3):
	print("Usage: bmp2charmap.py image_file start_index")
	exit()

path = sys.argv[1]
image = misc.imread(path, flatten = 1)

start_index = int(sys.argv[2])
for line in image:
	print("%d  :   " % (start_index), end='')
	for bit in line:
		if (bit == 0):
			print(0, end='')
		if (bit == 255):
			print(1, end='')
	print(';')
	start_index += 1

