import os
import sys
import math
from scipy import misc

if (len(sys.argv) < 3):
	print("Usage: image_file")
	exit()

path = sys.argv[1]
image = misc.imread(path, flatten = 0)
name = sys.argv[2]
# color positions
white = []

position = 0
for line in image:
	for col in line:
		#if col[0] == 143:
		#	yellow.append(hex(position))
		if col[0] == 255:
			white.append(hex(position))						
		position += 1

#index = 0
#for value in yellow:
	#print("MOUNTAIN_VECTOR(%d) <= x\"%s\";" % (index,value[2:]))
	#index += 1

index = 0
for value in white:
	print("%s(%d) <= x\"%s\";" % (name, index,value[2:]))
	index += 1
