#include "util.h"

#define SYS_WRITE 4
#define STDIN 0
#define STDOUT 1
#define STDERR 2
#define SYS_LSEEK 19
#define SYS_OPEN 5
#define SYS_READ 3
#define SYS_CLOSE 6

int system_call(int sysNum, ...);

int main (int argc , char* argv[], char* envp[])
{
  char c;
  char diff;
  char *print = 0, *file = 0;
  int input = 0, output = 1, debug = 0;
  int i, value, mode = 0;
  diff = 'a' - 'A';
  
  for(i=1; i<argc; i++){
    if(strcmp(argv[i],"-D")==0) {
      system_call(SYS_WRITE, STDERR,"-D\n", 3);
      debug = 1;
    }else if(strncmp(argv[i],"-i" , 2)==0) {
      mode = 1;
      file = argv[i]+2;
      input = system_call(SYS_OPEN, file, 0, 0777);
    }else if(strncmp(argv[i],"-o" , 2)==0) {
      print = argv[i] + 2;
      output = system_call(SYS_OPEN, print, 64 | 2, 0777);
    }
  }

  value = system_call(SYS_READ, input, &c, 1);

  while(c != '\n'){ 
    if(value != 0){
      if(debug == 1){
        if(mode == 0){
          system_call(SYS_WRITE, STDERR, "stdin", 5);
        }
        system_call(SYS_WRITE, STDERR, "ID: ", 4);
        system_call(SYS_WRITE, STDERR, itoa(3), 1);
        system_call(SYS_WRITE, STDERR, ", return code: ", strlen(", return code: "));
        system_call(SYS_WRITE, STDERR, itoa(value), 1);
        system_call(SYS_WRITE, STDERR, "\n", 1);
      }
  	  if (c >= 'A' && c <= 'Z') {
      	c += diff;
      } 
      if(debug == 1) {
        if(mode == 0){
          system_call(SYS_WRITE, STDERR, "stdout", 6);
        }
        system_call(SYS_WRITE, STDERR, "ID: ", 4);
        system_call(SYS_WRITE, STDERR, itoa(4), 1);
        system_call(SYS_WRITE, STDERR, ", return code: ", strlen(", return code: "));
        system_call(SYS_WRITE, STDERR, itoa(value), 1);
        system_call(SYS_WRITE, STDERR, "\n", 1);
  	  }
      system_call(SYS_WRITE, output, &c, 1);
      value = system_call(SYS_READ, input, &c, 1);
    }
  }
  if(input != 0){
    system_call(SYS_CLOSE, input);
  }
  if(output != 1){
    system_call(SYS_CLOSE, output);
  }
  system_call(SYS_WRITE, STDOUT, "\n", 1);
  return 0;
}  

