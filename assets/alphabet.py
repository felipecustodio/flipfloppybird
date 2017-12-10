import sys
import string

alphabet = string.ascii_lowercase
i = 65 # charmap letters start here
# get charmap codes for each letter
codes = {}
for letter in alphabet:
	binary = list(str(bin(i)))
	if (binary[1] == "b"):
		binary.remove("b")
	binary = "".join(binary)
	codes[letter] = binary
	i += 1
codes[" "] = "00000000" # space

# get word
word = input("Word: ")
word = list(word)
i = 0
# print word codes
print("-- INITIALIZE %s" % ("".join(word)))
for char in word:
	print("VECTOR(%d) <= \"%s\" -- %s" % (i, codes[char], char))
	i += 1
