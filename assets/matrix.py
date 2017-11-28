'''
Print screen positions
'''
screen = 30 * 40
cols = 0
for i in range(0,screen):
	print("%d " % (i), end='')
	cols += 1
	if (cols >= 41):
		print('')
		cols = 0
