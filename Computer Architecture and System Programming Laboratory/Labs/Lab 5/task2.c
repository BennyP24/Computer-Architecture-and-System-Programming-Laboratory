#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>
#include <errno.h>
#include "LineParser.h"
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>

#define TERMINATED  -1
#define RUNNING 1
#define SUSPENDED 0

typedef struct process{
    cmdLine* cmd;                         /* the parsed command line*/
    pid_t pid; 		                  /* the process id that is running the command*/
    int status;                           /* status of the process: RUNNING/SUSPENDED/TERMINATED */
    struct process *next;	                  /* next process in chain */
} process;

char buffer[PATH_MAX];
process * process_list = NULL;

void execute(cmdLine *pCmdLine, int debugMode);
void addProcess(cmdLine* cmd, pid_t pid);
void printProcessList();
void freeProcessList();
void updateProcessList();
void updateProcessStatus(int pid, int status);


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
			freeProcessList();
			exit(0);
		}
		cmdLine* parseCommand = parseCmdLines(userInput);
		if (parseCommand != NULL){
			execute(parseCommand, debugMode);
		}else{
			printf("nothing to parse \n");
		}

	}
}
void execute(cmdLine *pCmdLine, int debugMode){
	int pid;
	pid_t signal_pid;
	int value, kill_stat;
	int stat;
	char* stir;
	char* path2;
	if (strcmp(pCmdLine->arguments[0], "suspend") == 0){
    	stir = (pCmdLine -> arguments[1]);
    	signal_pid = atoi (stir);
    	kill_stat = kill(signal_pid, SIGTSTP);
    	if(kill_stat == 0){
    		printf("signal was sent succesfully \n");
    		updateProcessStatus(signal_pid, 0);
    	}else{
    		perror("error, signal wasnt sent\n");
    	}
    	freeCmdLines(pCmdLine);
    	return;
	}
	if (strcmp(pCmdLine->arguments[0], "wake") == 0){
    	stir = (pCmdLine -> arguments[1]);
    	signal_pid = atoi (stir);
    	kill_stat = kill(signal_pid, SIGINT);
    	if(kill_stat == 0){
    		printf("signal was sent succesfully \n");
    		updateProcessStatus(signal_pid, 1);
    	}else{
    		perror("error, signal wasnt sent\n");
    	}
    	freeCmdLines(pCmdLine);
    	return;
	}
	if (strcmp(pCmdLine->arguments[0], "kill") == 0){
		stir = (pCmdLine -> arguments[1]);
    	signal_pid = atoi (stir);
    	kill_stat = kill(signal_pid, SIGCONT);
    	if(kill_stat == 0){
    		printf("signal was sent succesfully \n");
    		updateProcessStatus(signal_pid, -1);
    	}else{
    		perror("error, signal wasnt sent\n");
    	}
    	freeCmdLines(pCmdLine);
    	return;
	}
	if (strcmp(pCmdLine->arguments[0], "procs") == 0){
    	printProcessList();
    	freeCmdLines(pCmdLine);
    	return;
	}
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
		freeCmdLines(pCmdLine);
		return;
	}
	pid = fork();
	if(debugMode == 1){
		fprintf(stderr, "the id is: %d \n", pid);
	}
	if(pid == 0){
		value = execvp(pCmdLine -> arguments[0] ,pCmdLine -> arguments);
		if(value == -1){
			perror(pCmdLine->arguments[0]);
     		_exit(0);
		}
	}
	addProcess(pCmdLine, pid);
	if (pCmdLine -> blocking){
		waitpid(pid, &stat, 0);
	}
}

void addProcess(cmdLine* cmd, pid_t pid){
	process * Current = (process*) malloc (sizeof(process));
	Current->cmd = cmd;
	Current->pid = pid;
	Current->status = RUNNING;
	Current->next = NULL;

	if (process_list != NULL){
		process * pointer_process = process_list;
		while (pointer_process->next != NULL){
			pointer_process = pointer_process->next;
		}
		pointer_process->next = Current;
	}
	else {
		process_list = Current;
	}
}


void printProcessList(){
	updateProcessList();
	process * pointer_process = process_list;
    process * pointer_prev = process_list;
	while (pointer_process != NULL) {
		printf("%d\t%s\t%s\n", pointer_process->pid,
		    pointer_process->cmd->arguments[0],
		    pointer_process->status == RUNNING ? "Running" :
		    pointer_process->status == SUSPENDED ? "Suspended" : "Terminated");
        if (pointer_process->status == TERMINATED) {
            pointer_process = pointer_process -> next;
            freeCmdLines(pointer_prev -> cmd);
            free (pointer_prev);
            process_list = pointer_process;
            pointer_prev = pointer_process;
        }
        else {
            pointer_process = pointer_process->next;
        }
	}
	while (pointer_process != NULL) {
            printf("%d\t%s\t%s\n", pointer_process->pid,
		    pointer_process->cmd->arguments[0],
		    pointer_process->status == RUNNING ? "Running" :
		    pointer_process->status == SUSPENDED ? "Suspended" : "Terminated");
        	if (pointer_process->status == TERMINATED) {
                pointer_process = pointer_process->next;
                freeCmdLines(pointer_prev -> cmd);
                free (pointer_prev->next);
                pointer_prev->next = pointer_process;
            }
            else {
                pointer_prev = pointer_process;
                pointer_process = pointer_process->next;
            }
    }
}

void freeProcessList(){
	process* p = process_list;
	process* clean =process_list;
	while(p != NULL){
		p = p -> next;
		freeCmdLines(clean -> cmd);
		free(clean);
		clean = p;
	}
}

void updateProcessList(){
	int status;
    pid_t endID;
	process * p = process_list;
	while(p != NULL){
		endID = waitpid(p -> pid, &status, WNOHANG);
		if(endID == -1){
			perror("waitpid error");
		}
		else if(endID == 0){
			printf("process is still running");
		}
		else if(endID == p -> pid){
			printf("process ended");
		}
		p = p-> next;
	
	}
}


void updateProcessStatus(int pid, int status){
	process* p = process_list;
	while( p != NULL){
		if(p -> pid == pid){
			p -> status = status;
		}
		p = p -> next;
	}
}