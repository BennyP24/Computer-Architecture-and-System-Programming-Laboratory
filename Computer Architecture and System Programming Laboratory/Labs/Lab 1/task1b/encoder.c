#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
  char c, diff;
  int debug = 0;
  int i;
  diff = 'a' - 'A';

  for(i=1; i<argc; i++){
    if(strcmp(argv[i],"-D")==0) {
      fprintf(stderr, "-D\n");
      debug = 1;
    }
  }
  c = getchar();

  while (c != EOF) {
    if(debug == 1) {
      fprintf(stderr, "0x%x\t", c);
    }

    if (c >= 'A' && c <= 'Z') {
      c += diff;
    } 

    if (debug == 1) {
      fprintf(stderr, "0x%x\n", c);
    }

    putchar(c);
    c = getchar();
  }
  return 0;
}
