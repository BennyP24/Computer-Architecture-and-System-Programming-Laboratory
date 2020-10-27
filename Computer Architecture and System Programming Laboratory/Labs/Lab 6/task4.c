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
#include <stdarg.h>

#define STDIN 0
#define STDOUT 1

int debugMode = 0;
char buffer[PATH_MAX];
pid_t numberOfPids[2];


typedef struct variable {
	char * name;
	char * value;
	struct variable * next;
	
} variable;

void execute(cmdLine *pCmdLine, int debugMode);
void execute_pipe(cmdLine * pCmdLine);
void varsToValues(variable ** list, cmdLine * cmd);
void printVariablesList(variable** list);
variable * findVariable(variable ** list, char * name);
void addVar(variable ** list, cmdLine * cmd);
void freeVariableList(variable ** list);
void setVariable(variable ** list, cmdLine * cmd);
void quit();

variable* list_global = NULL;

int main(int argc, char **argv) {
	char userInput[2048];
	char* path;

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
			quit();
		}
		cmdLine* parseCommand = parseCmdLines(userInput);
		varsToValues(&list_global, parseCommand);
		if (parseCommand != NULL){
			execute(parseCommand, debugMode);
			freeCmdLines(parseCommand);
		}else{
			printf("nothing to parse \n");
		}

	}
}



variable * findVariable(variable ** list, char * name) {
	variable * var = *list;
	while (var != NULL) {
		if (strcmp(var->name, name) == 0)
			break;
		var = var->next;
	}
	return var;
}

void addVar(variable ** list, cmdLine * cmd) {
	variable * var = (variable*) malloc (sizeof(variable));
	var->name = strdup(cmd->arguments[1]);
	var->value = strdup(cmd->arguments[2]);
	var->next = *list;
	*list = var;
}




void quit() {
	freeVariableList(list_global);
	exit(0);
}


void execute_pipe(cmdLine * pCmdLine) {
	int pipefd[2], value;
    pid_t firstPid, secondPid, helperPid;

	if(debugMode == 1){
		fprintf(stderr, "(parent_process>forking…)\n");
	}
	if(pipe(pipefd) == -1){
		perror("pipe error");
		exit(EXIT_FAILURE);
	}
	helperPid =fork();
	if(helperPid == -1){
		perror("fork error");
		exit(EXIT_FAILURE);
	}
	firstPid = helperPid;
	if (firstPid == 0){
		if(debugMode == 1){
			fprintf(stderr, "(child1>redirecting stdout to the write end of the pipe…)\n");
		}
		close(STDOUT);
		dup(pipefd[1]);
        close(pipefd[1]);

		if(debugMode == 1){
			fprintf(stderr, "(child1>going to execute cmd: %d)\n", (int)(pCmdLine-> arguments[0]) );
		}
		value = execvp(pCmdLine -> arguments[0] ,pCmdLine -> arguments);
		if(value == -1){
			perror("error with executing");
     		_exit(0);
		}
	}
	if(debugMode == 1){
		fprintf(stderr, "(parent_process>created process with id:%d)\n",firstPid);
		fprintf(stderr, "(parent_process>closing the write end of the pipe…)\n");
	}
	close(pipefd[1]);
	
	if(debugMode == 1){
		fprintf(stderr, "(parent_process>forking…)\n");
	}
	helperPid =fork();
	if(helperPid == -1){
		perror("fork error");
		exit(EXIT_FAILURE);
	}
	secondPid = helperPid;
	if (secondPid == 0){
		if(debugMode == 1){
			fprintf(stderr, "(child2>redirecting stdin to the read end of the pipe…)\n");
		}
		close(STDIN);
		dup(pipefd[0]);
        close(pipefd[0]);

		if(debugMode == 1){
			fprintf(stderr, "(child2>going to execute cmd: %d)\n", (int)(pCmdLine -> next -> arguments[0]) );
		}
		value = execvp(pCmdLine ->next -> arguments[0] ,pCmdLine ->next -> arguments);
		if(value == -1){
			perror("error with executing");
     		_exit(0);
		}  
	}
	if(debugMode == 1){
		fprintf(stderr, "(parent_process>created process with id:%d )\n", secondPid);
		fprintf(stderr, "(parent_process>closing the read end of the pipe…)\n");
	}
	close(pipefd[0]);
	if(debugMode == 1){
		fprintf(stderr, "(parent_process>waiting for child processes to terminate…)\n");
	}
	waitpid(firstPid, NULL, 0);
	waitpid(secondPid, NULL, 0);

	if(debugMode == 1){
		fprintf(stderr, "(parent_process>exiting…)\n");
	}
	numberOfPids[0] = firstPid;
    numberOfPids[1] = secondPid;

}

void execute(cmdLine *pCmdLine, int debugMode){
	int pid;
	int value;
	int stat;
	int pipefd[2];
	char* path2;
	if (strcmp(pCmdLine->arguments[0], "cd") == 0) {
		if (strncmp(pCmdLine->arguments[1], "~", 1) == 0)
			replaceCmdArg(pCmdLine, 1, getenv("HOME"));
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
	else if (strcmp(pCmdLine->arguments[0], "vars") == 0){
		printVariablesList(&list_global);
	}
	else if (strcmp(pCmdLine->arguments[0], "set") == 0){
		setVariable(&list_global, pCmdLine);
	}
	else if (strcmp(pCmdLine->arguments[0], "delete") == 0){
		deleteVar(&list_global, pCmdLine);
	}
	else{
		if(pCmdLine -> next){
			execute_pipe(pCmdLine);
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
}
