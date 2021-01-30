all:
	mkdir -p tmp 
	mkdir -p bin
	cc -m32 -std=c99 -c -o tmp/main.o src/main.c
	nasm -f elf32 -o tmp/func.o src/func.asm 
	cc -m32 -o bin/app tmp/func.o tmp/main.o 
	