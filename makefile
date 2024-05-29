all: main

main:
	fasm main.asm
	ld main.o -o server
