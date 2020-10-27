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

char my_get(char c){
  c = fgetc(stdin);
  return c;
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
  int base_len = 5;
  quit('a');
  char arr1[base_len];
  char* arr2 = map(arr1, base_len, my_get);
  char* arr3 = map(arr2, base_len, encrypt);
  char* arr4 = map(arr3, base_len, xprt);
  char* arr5 = map(arr4, base_len, decrypt);
  char* arr6 = map(arr5, base_len, cprt);
  free(arr2);
  free(arr3);
  free(arr4);
  free(arr5);
  free(arr6);
}
