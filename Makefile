all:
	nasm -g -f elf64 print.asm -o print.o
	gcc -g app.c print.o -o app -no-pie

