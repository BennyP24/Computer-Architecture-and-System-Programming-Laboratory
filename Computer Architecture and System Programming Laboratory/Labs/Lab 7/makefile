# All Targets
all: task1 task4

# Tool invocations
task1: task1.o
	gcc -m32 -g -Wall -fno-pie -o task1 task1.c

task4: task4.o
	gcc -m32 -g -Wall -fno-pie -o task4 task4.c

# Depends on the source and header files
task1.o: task1.c
	gcc -g -Wall -m32 -fno-pie -c -o task1.o task1.c

task4.o: task4.c
	gcc -g -Wall -m32 -fno-pie -c -o task4.o task4.c 

#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o task1 task4
