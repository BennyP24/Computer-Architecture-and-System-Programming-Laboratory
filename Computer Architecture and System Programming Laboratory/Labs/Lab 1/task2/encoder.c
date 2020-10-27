#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h> 
#include <fcntl.h>

int main(int argc, char **argv) {
  char c, diff,pre;
  char* key = 0;
  int debug = 0, offset = 0, length = 0;
  int i, mode = 0;
  FILE* input = stdin;
  FILE* output = stdout;
  diff = 'a' - 'A';

  for(i=1; i<argc; i++){
    if(strcmp(argv[i],"-D")==0) {
      fprintf(stderr, "-D\n");
      debug = 1;
    } else if(strncmp(argv[i],"+e" , 2)==0) {
      length = strlen(argv[i] + 2);
      key = argv[i]+2;
      mode = 1;
    } else if(strncmp(argv[i],"-e" , 2)==0) {
      length = strlen(argv[i] + 2);
      key = argv[i]+2;
      mode = 2;
    } else if(strncmp(argv[i],"-i" , 2)==0) {
      input = fopen(argv[i] + 2, "r");
      if( input == NULL){
        input = stdin;
        fprintf(stderr, "fail opening file\n");
      }
    } else if(strncmp(argv[i],"-o" , 2)==0) {
      output = fopen(argv[i] + 2, "w");
      if( output == NULL){
        output = stdout;
        fprintf(stderr, "fail opening file\n");
      }
    } 
  }
  c = fgetc(input);

  while (c != EOF) {
    pre = c;
    if(debug == 1) {
      fprintf(stderr, "0x%x\t", c);
    }
    if( mode == 0 ){
      if (c >= 'A' && c <= 'Z') {
        c += diff;
      } 
    } else{
      char curkey = *(key + (offset % length));
      if (mode == 1){
        c += curkey;
      }else{
        c -= curkey;
      }
      offset += 1;
    } 
    if (debug == 1) {
      fprintf(stderr, "0x%x\n", c);
    }

    fputc(c, output);
    if( pre == '\n'){
      fputc('\n', output);
      offset = 0;
    }
    c = fgetc(input);
  }
  if(input != stdin){
    fclose(input);
  }
  if(output != stdout){
    fclose(output);
  }
  return 0;
}
