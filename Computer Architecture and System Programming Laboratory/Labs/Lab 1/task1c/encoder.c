#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
  char c, diff, pre;
  char* key = 0;
  int debug = 0, offset = 0, length = 0;
  int i, mode = 0;
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
    }
  }
  c = getchar();

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
    putchar(c);
    if(pre == '\n'){
      putchar('\n');
      offset = 0;
    }
    c = getchar();
  }
  return 0;
}
