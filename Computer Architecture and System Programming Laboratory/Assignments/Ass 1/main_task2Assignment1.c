#include <stdio.h>
#define	MAX_LEN 34


extern void assFunc(int x, int y);
char c_checkValidity(int x, int y);

int main(int argc, char** argv)
{
    int x, y;
    scanf("%d", &x);
    scanf("%d", &y);
    assFunc(x, y);
    
    return 0;
}

char c_checkValidity(int x, int y){
    char validity; // 0 = false, 1 = true
    if(x < 0 || y <= 0 || y > 32768){
        validity = 0;
    }
    else{
        validity = 1;
    }
    
    return validity;
}

