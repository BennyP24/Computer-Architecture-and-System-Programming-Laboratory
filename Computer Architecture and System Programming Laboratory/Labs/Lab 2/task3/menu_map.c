#include <stdio.h>
#include<stdlib.h>
#include <string.h>

char censor(char c) {
  if(c == '!')
    return '.';
  else
    return c;
}

char* map(char *array, int array_length, char (*f) (char)){
  char* mapped_array = (char*)(malloc(array_length*sizeof(char)));
  if(mapped_array == NULL){
    fprintf(stdout, "no allocation....quiting");
    exit(0);
  }
  for(int i = 0; i < array_length; i++)
  {
    mapped_array[i] = f(array[i]);
  }
  return mapped_array;
}

struct fun_desc {
  char *name;
  char (*fun)(char);
};

char my_get(char c) {
  return fgetc(stdin);
}

char encrypt(char c){
  if(c >= 0x20 && c <= 0x7E ){
    return c + 3;
  }
  return c;
}

char xprt(char c){
  fprintf(stdout, "0x%x\n", c);
  return c;
}

char decrypt(char c){
  if(c >= 0x20 && c <= 0x7E ){
    return c - 3;
  }
  return c;
}

char cprt(char c){
  if(c >= 0x20 && c <= 0x7E ){
    fprintf(stdout, "%c\n", c);
  }
  else{
    fprintf(stdout, "%c\n", '.');
  }
  return c;
}

char quit(char c){
  exit(0);
}

int main(int argc, char **argv){
  char *carray ="     ";
  struct fun_desc menu[] = { {"censor", censor}, { "my_get", my_get }, { "encrypt", encrypt }, { "xprt", xprt }, {"decrypt", decrypt}, {"cprt", cprt}, {"quit", quit}, { NULL, NULL} };
  int length = sizeof(menu)/sizeof(menu[0]);
  int option;

  while(1) {
    printf("Please choose a function:\n");
    for(int i = 0; i < length-1; i++) {
      printf("%d) %s\n", i, menu[i].name);
    }
    printf("Option: ");
    scanf("%d", &option);
    fgetc(stdin);
    if(option >= length - 1 || option < 0) {
      printf("Not within bounds\n");
      quit('a');
    }
    printf("Within bounds\n");
    carray = map(carray, 5, menu[option].fun);
    printf("%s\n", carray);
  }
}

