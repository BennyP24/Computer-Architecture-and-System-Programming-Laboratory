#include "util.h"

#define SYS_GETDENTS 141
#define SYS_WRITE 4
#define STDIN 0
#define STDOUT 1
#define STDERR 2
#define SYS_LSEEK 19
#define SYS_OPEN 5
#define SYS_READ 3
#define SYS_CLOSE 6

int system_call(int sysNum, ...);

char* type(char prefixT);

typedef struct dirent {
    unsigned long d_Inode;
    unsigned long d_offset;
    unsigned short d_Length;
    char d_buf[1];
}dirent;


int main (int argc , char* argv[], char* envp[])
{
  char buf[8192];
  int debug = 0, size = 0, file = 0, bufferLength = 0, i;
  int modeP = 0;
  char* direntName;
  char* direntSize;
  char* prefix;
  char prefixType;
  int counter = 0, prefixLength;
  struct dirent* current;

  file = system_call(SYS_OPEN, ".", 0);
  if (file < 0){
    system_call (SYS_WRITE, STDOUT, "Error opening the directory\n", 28);
    system_call (STDOUT, 0x55);
  }
  bufferLength = system_call(SYS_GETDENTS, file, buf, 8192);
  if (bufferLength < 0) {
        system_call (SYS_WRITE, STDOUT, "Error opening the directory\n", 28);
        system_call (STDOUT, 0x55);
  }
  for(i=1; i<argc; i++){
    if(strcmp(argv[i],"-D")==0) {
      system_call(SYS_WRITE, STDOUT,"-D\n", 3);
      debug = 1;
    }if(strncmp(argv[i], "-p", 2)==0){
        prefix = argv[i]+2;
        prefixLength= strlen(prefix);
        modeP = 1;
    }
  }
  while(counter < bufferLength){
    current = (dirent*)(buf + counter);
    size = current->d_Length;
    prefixType = *(buf + counter + current->d_Length - 1);
    char *prefixTypeStr = type(prefixType);
    direntName = current->d_buf;
    if(modeP == 1){
      if(strncmp(prefix, direntName, prefixLength) == 0){
        system_call(SYS_WRITE, STDOUT, direntName, strlen(direntName));
        system_call(SYS_WRITE, STDOUT, " ", 1);
        system_call(SYS_WRITE, STDOUT, prefixTypeStr, strlen(prefixTypeStr));
        system_call(SYS_WRITE, STDOUT, " ", 1);
      }
    }else{
      system_call(SYS_WRITE, STDOUT, direntName, strlen(direntName));
      system_call(SYS_WRITE, STDOUT, " ", 1);
    } 
    if(debug == 1){
      direntSize = itoa(size);
      system_call(SYS_WRITE, STDOUT, direntSize, strlen(direntSize));
      system_call(SYS_WRITE, STDOUT, " ", 1);
    }
    counter = counter + size;
  }
  system_call(SYS_WRITE, STDOUT, "\n", 1);
  system_call(SYS_CLOSE, file);
  return 0;
}  

char* type(char prefixT){
  char* string;
  if(prefixT == 8){
    return string = "regular\n";
  }else if(prefixT == 0){
    return string = "unknown\n";
  }else if(prefixT == 1){
    return string = "fifo\n";
  }else if(prefixT == 2){
    return string = "character\n";
  }else if(prefixT == 4){
    return string = "directory\n";
  }else if(prefixT == 6){
    return string = "block\n";
  }else if(prefixT == 10){
    return string = "link\n";
  }else if(prefixT == 12){
    return string = "socket\n";
  }else if(prefixT == 14){
    return string = "wht\n";
  }
  return 0;
}
