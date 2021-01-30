all:
	make 32bit
	make 64bit 

32bit:
	mkdir -p tmp
	mkdir -p bin
	cc -m32 -std=c99 -c -o tmp/main32.o src/main.c
	nasm -f elf32 -o tmp/module32.o src/module32.asm
	cc -m32 -o bin/flip32 tmp/module32.o tmp/main32.o

64bit:
	mkdir -p tmp
	mkdir -p bin
	cc -std=c99 -c -o tmp/main64.o src/main.c
	nasm -f elf64 -o tmp/module64.o src/module64.asm
	cc -o bin/flip64 tmp/module64.o tmp/main64.o
	