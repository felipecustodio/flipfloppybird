# '''
# Convert bitmap image into video memory mif file

# Copying to clipboard:
# python bmp2vhdlvector.py image | xclip -selection c  
# '''

import os
import sys
import math
from scipy import misc

if (len(sys.argv) < 2):
	print("Usage: bmp2bits.py image_file")
	exit()

path = sys.argv[1]
image = misc.imread(path, flatten = 0)

# color positions
yellow = []
white = []

position = 0
for line in image:
	for col in line:
		if col[0] == 143:
			yellow.append(hex(position))
		if col[0] == 255:
			white.append(hex(position))						
		position += 1

index = 0
for value in yellow:
	print("MOUNTAIN_VECTOR(%d) <= x\"%s\";" % (index,value[2:]))
	index += 1

index = 0
for value in white:
	print("CLOUD_VECTOR(%d) <= x\"%s\";" % (index,value[2:]))
	index += 1
