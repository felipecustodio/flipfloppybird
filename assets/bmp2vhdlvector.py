'''
Convert bitmap image into STD_LOGIC_VECTORs

Copying to clipboard:
python bmp2vhdlvector.py image | xclip -selection c  
'''

import os
import sys
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
		if (bit == 0):
			lines[i].append(1)
		if (bit == 255):
			lines[i].append(0)
	i += 1

# declare vectors
for line in lines:
	print("map_line%d: std_logic_vector(%d downto 0);" % (line, len(lines[line])))

# fill vectors
for line in lines:
	value = str(''.join(map(str,lines[line])))
	print("map_line%d <= \"%s\"""" % (line, value))