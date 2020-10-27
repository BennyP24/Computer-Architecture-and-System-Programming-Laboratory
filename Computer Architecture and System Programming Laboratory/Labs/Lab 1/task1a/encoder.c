#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
  char c, diff;
  diff = 'a' - 'A';

  c = getchar();

  while (c != EOF) {
    if (c >= 'A' && c <= 'Z'){
      c += diff;
    }
    putchar(c);
    c = getchar();
  }
  return 0;
}
