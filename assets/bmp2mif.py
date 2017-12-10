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
image = misc.imread(path, flatten = 1)

# get bits
lines = {}
i = 0
for line in image:
	lines[i] = []
	for bit in line:
		bit = math.floor(bit[0])

		if (bit == 139):
			lines[i].append(3)
		if (bit == 255):
			lines[i].append(15)
		if (bit == 174):
			lines[i].append(14)
	i += 1

# find bit value for each memory address
memory = {}
index = 0
for line in lines:
	value = str(''.join(map(str,lines[line])))
	for bit in value:
		memory[index] = int(bit)
		index += 1

print("CONTENT BEGIN")
flag = False
current = []
for index in memory:
	if (not flag):
		if (memory[index] == 0):
			current.append(index)
		if (memory[index] == 1):
			flag = True
			if (len(current) > 1):
				print("[%d..%d] : 0" % (current[0], current[len(current)-1]))
			else:
				print("%d : 0" % (current[0]))
			current.clear()
			current.append(index)
	if (flag):
		if (memory[index] == 1):
			if (index != current[0]):
				current.append(index)
		if (memory[index] == 0):
			flag = False
			if (len(current) > 1):
				print("[%d..%d] : 1" % (current[0], current[len(current)-1]))
			else:
				print("%d : 1" % (current[0]))
			current.clear()
			current.append(index)
print("END;")
