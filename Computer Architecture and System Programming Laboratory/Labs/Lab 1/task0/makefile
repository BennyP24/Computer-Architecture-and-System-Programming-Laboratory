build: main.o add.o numbers.o
	gcc -m32 -g -Wall -o  lab1 add.o main.o numbers.o

add.o:
	nasm -g -f elf -w+all -o add.o add.s

main.o:
	gcc -m32 -g -Wall -c -o main.o main.c 

numbers.o:
	gcc -m32 -g -Wall -c -o numbers.o numbers.c

clean:
	rm numbers.o main.o add.o lab1