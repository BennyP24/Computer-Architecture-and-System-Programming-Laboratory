#include <stdio.h>
#include <stdlib.h>

int digit_cnt(char *input);

int main(int argc, char **argv){
    //printf("Num of digits: %d\n", digit_cnt(argv[1]));
    return 0;
}

int digit_cnt(char *input){
    int digits = 0;
    for (int i =0; input[i] != '\0'; i++){
        if (input[i] >= '0' && input[i] <= '9')
            digits++;
    }
    return digits;
}