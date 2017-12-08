import string

alphabet = string.ascii_lowercase
i = 65
for letter in alphabet:
	binary = bin(i)
	print(letter, end=': ')
	print(binary)
	i += 1
