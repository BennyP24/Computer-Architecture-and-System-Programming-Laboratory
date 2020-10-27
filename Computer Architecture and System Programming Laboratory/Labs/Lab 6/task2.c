#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>
#include <errno.h>
#include "LineParser.h"
#include <sys/types.h>
#include <sys/wait.h>
#include <fcntl.h>


char buffer[PATH_MAX];
void execute(cmdLine *pCmdLine, int debugMode);


int main(int argc, char **argv) {
	char userInput[2048];
	char* path;
	int debugMode = 0;
	if(argc > 1 && strcmp("-d", argv[1]) == 0) {
	   debugMode = 1; 
	}
	
	while (1){
		path = getcwd (buffer, PATH_MAX);
		if(path == NULL){
			perror ("error with path size \n");
		}
		else{
			printf("Current directory is:%s \n", path);
		}
		fgets(userInput, 2048, stdin);
		if(debugMode == 1){
			fprintf(stderr, "%s\n", userInput);
		}
		
		if(strcmp(userInput,"quit\n") ==0) {
			exit(0);
		}
		cmdLine* parseCommand = parseCmdLines(userInput);
		if (parseCommand != NULL){
			execute(parseCommand, debugMode);
			freeCmdLines(parseCommand);
		}else{
			printf("nothing to parse \n");
		}

	}
}
void execute(cmdLine *pCmdLine, int debugMode){
	int pid;
	int value;
	int stat;
	int pipefd[2];
	char* path2;
	if (strcmp(pCmdLine->arguments[0], "cd") == 0) {
		if (chdir(pCmdLine->arguments[1])){
			perror("Error");
		}
		else{
			path2 = getcwd (buffer, PATH_MAX);
			if(path2 == NULL){
				perror ("error with path size \n");
			}
			else{
				printf("Current directory is:%s \n", path2);
			}
		}
		return;
	}
	if (pipe(pipefd) == -1) {
		perror("Pipe error");
	}

	pid = fork();
	if(pid == 0){
		if(debugMode == 1){
			fprintf(stderr, "the id is: %d \n", pid);
		}
		if(pCmdLine -> inputRedirect){
			close(0);
			fopen(pCmdLine->inputRedirect, "r");
		}
		if (pCmdLine->outputRedirect) {
			close(1);
			fopen(pCmdLine->outputRedirect, "w");
		}
		value = execvp(pCmdLine -> arguments[0] ,pCmdLine -> arguments);
		if(value == -1){
			perror(pCmdLine->arguments[0]);
     		_exit(0);
		}
	}
	if (pCmdLine -> blocking){
			waitpid(pid, &stat, 0);
	}
}
