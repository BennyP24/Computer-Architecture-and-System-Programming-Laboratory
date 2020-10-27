all: task1 task2 task3

task3: task3.o
	ld -m elf_i386 task3.o -o task3

task3.o: task3.s
	nasm -f elf task3.s -o task3.o
	
task2: task2.o
	ld -m elf_i386 task2.o -o task2

task2.o: task2.s
	nasm -f elf task2.s -o task2.o
	
task1: task1.o
	ld -m elf_i386 task1.o -o task1

task1.o: task1.s
	nasm -f elf task1.s -o task1.o

clean:
	rm *.o task1 task2 task3
