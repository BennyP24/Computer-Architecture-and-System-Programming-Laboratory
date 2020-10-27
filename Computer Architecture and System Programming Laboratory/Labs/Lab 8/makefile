# All Targets
all: myELF

# Tool invocations
myELF: task3.o
	gcc -m32 -g -Wall -o myELF task3.c

# Depends on the source and header files
task3.o: task3.c
	gcc -g -Wall -m32 -c -o task3.o task3.c 

#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o myELF
