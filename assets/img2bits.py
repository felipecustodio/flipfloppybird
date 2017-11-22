'''
Helper script to convert an 8x8 image
to bits for use in charmaps
'''
import sys

if (len(sys.argv) < 2):
	print("Usage: python img2bits.py 'image name'")
	exit()

import os
from scipy import misc
path = sys.argv[1]
image= misc.imread(path, flatten= 0)
print(image)

