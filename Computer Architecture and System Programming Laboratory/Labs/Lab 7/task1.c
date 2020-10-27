#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

typedef struct {
  char debug_mode;
  char file_name[128];
  int unit_size;
  unsigned char mem_buf[10000];
  size_t mem_count;
  /*
   .
   .
   Any additional fields you deem necessary
  */
} state;

struct fun_desc{
    char* name;
    void (*fun)(state *s);
};

void quit(state *s);
void toggleDebug(state *s);
void setFileName(state *s);
void setUnitSize(state *s);
void load(state *s);
void display(state *s);
void print_units(FILE* output, char* buffer, int count);
char* unit_to_format(int unit);
char* unit_to_format_decimal(unsigned int unit);
void print_from_memory(char *buffer, int u, int *addr);
void save(state *s);
void modify(state *s);

int MAX_SIZE = 100;
state *state_global = NULL;
char buffer[100] = "";

int main(int argc, char **argv){
    struct fun_desc menu[9] = {{"Toggle Debug Mode", &toggleDebug}, 
    {"Set File Name", &setFileName}, {"Set Unit Size", &setUnitSize}, {"Load Into Memory", &load},
    {"Memory Display", &display}, {"Save Into File", &save}, {"File Modify", &modify}, {"Quit", &quit}, {NULL, NULL}};
    int option = 0;
    state_global = malloc(sizeof(state));
    state_global->debug_mode = 0;
    state_global->unit_size = 1;
    while(1){
        if (state_global->debug_mode == 1){
            printf("Unit size is: %d\n", state_global->unit_size);
            printf("File name is: %s\n", state_global->file_name);
            printf("Memory count is: %d\n", state_global->mem_count);
        }
        for(int i = 0; i <= 7; i++)
            printf("%d) %s\n", i, menu[i].name);
        char optionNum[2];
        fgets(optionNum, sizeof(optionNum), stdin);
        fgetc(stdin);
        sscanf(optionNum, "%d", &option);
        if(option >= 0 && option < 8)
            menu[option].fun(state_global);
    }
    return 0;
}

void toggleDebug(state *s){
    printf("in toggle\n");
    if (s->debug_mode == 0){
        s->debug_mode = 1;
        printf("Debug flag now on\n");
    }
    else{
        s->debug_mode = 0;
        printf("Debug flag now off\n");
    }
}

void setFileName(state *s){
    memset(buffer, 0, sizeof(buffer));
    printf("Please enter a file name, no longer than 100 characters\n");
    fgets(buffer, sizeof(buffer), stdin);
    if (s->debug_mode == 1){
        printf("Debug: file name set to %s\n", buffer);
    }
    strcpy(s->file_name, buffer);
    strtok(s->file_name, "\n");
}

void setUnitSize(state *s){
    printf("Please enter a number\n");
    int size = 0;
    char sizeNum[2];
    fgets(sizeNum, sizeof(sizeNum), stdin);
    fgetc(stdin);
    sscanf(sizeNum, "%d", &size);
    if (size == 1 || size ==2 || size ==4){
        s->unit_size = size;
        if (s->debug_mode == 1)
            printf("Debug: set size to %d\n", size);
    }
    else{
        printf("Error: size isn't valid\n");
    }  
}

void quit(state *s){
    if (s->debug_mode  == 1)
        printf("quitting\n");
    free(s);
    exit(0);
}

void load(state *s){
    if (s->file_name == NULL){
        printf("Error: file_name is NULL\n");
        return;
    }
    else{
        FILE *fp;
        fp = fopen(s->file_name, "r");
        if (fp == NULL){
            printf("Error: %s couldn't be opened for reading\n", s->file_name);
            return;
        }
        else{
            int location, length = 0;
            printf("Enter <location> and <length>\n");
            fgets(buffer, sizeof(buffer), stdin);
            sscanf(buffer, "%x %d", &location, &length);
            if (s->debug_mode == 1){
                printf("File name is: %s\n", s->file_name);
                printf("Location is: %X\n", location);
                printf("Length is: %d\n", length);
            }
            fseek(fp, location, SEEK_SET);
            fread(s->mem_buf, length, s->unit_size, fp);
            fclose(fp);
            printf("Loaded %d bytes into memory\n", length);
        }
    }
}

void display(state *s){
    unsigned int u = 0;
    int addr = 0;
    volatile unsigned char* addr_ptr = NULL;
    printf("Enter number of units to display and the address to display from\n");
    fgets(buffer, sizeof(buffer), stdin);
    sscanf(buffer, "%d %d", &u, &addr);
    printf("Decimal   Hexadecimal\n");
    printf("=============\n");
    if (addr == 0)
        print_units(stdout, (char*)state_global->mem_buf, u);
    else{
        int i, j = 0;
        while (i < (u*s->unit_size)){
            while (j < s->unit_size){
                addr_ptr = (volatile unsigned char*) (addr + i + j);
                printf("%d", *addr_ptr);
                
                j++;
            }
            printf("\t");
            j = 0;
            while (j < s->unit_size){
                addr_ptr = (volatile unsigned char*) (addr + i + j);
                printf("%X", *addr_ptr);
                j++;
            }
            printf("\n");
            i += s->unit_size;
        }
    }
}


/* Prints the buffer to screen by converting it to text with printf */
void print_units(FILE* output, char* buffer, int count) {
    char* end = buffer + state_global->unit_size*count;
    while (buffer < end) {
        //print ints
        int var = *((int*)(buffer));
        fprintf(output, unit_to_format_decimal(state_global->unit_size), var);
        fprintf(output, unit_to_format(state_global->unit_size), var);
        buffer += state_global->unit_size;
    }
}

char* unit_to_format(int unit) {
    static char* formats[] = {"%#hhX\n", "%#hX\n", "No such unit", "%#X\n"};
    return formats[state_global->unit_size-1];
}

char* unit_to_format_decimal(unsigned int unit) {
    static char* formats[] = {"%#hhd\t", "%#hd\t", "No such unit", "%#d\t"};
    return formats[state_global->unit_size-1];
}

void save(state *s){
    int length = 0;
    int source = 0;
    int target = 0;
    volatile unsigned char* addr_ptr = NULL;
    printf("Please enter <source-address> <target-location> <length>\n");
    fgets(buffer, sizeof(buffer), stdin);
    sscanf(buffer, "%d %x %d", &source, &target, &length); 
    FILE* fp  = fopen(s->file_name, "r+");
    if (fp == NULL){
        printf("Error: %s couldn't be opened for reading\n", s->file_name);
        return;
    }
    else{
        if (s->debug_mode == 1){
                printf("File name is: %s\n", s->file_name);
                printf("Source address is: %d\n", source);
                printf("Target location is: %X\n", target);
                printf("Length is: %d\n", length);
        }
        fseek(fp, 0, SEEK_END);
        int size = ftell(fp);
        if (target > size){
            printf("Error: target location is bigger than %s size\n", s->file_name);
            return;
        }
        fseek(fp, target, SEEK_SET);
        if (source == 0)
            fwrite(s->mem_buf, s->unit_size, length, fp);
        else{
            int i = 0;
            while (i < (length*s->unit_size)){
                    addr_ptr = (volatile unsigned char*) (source + i);
                    fwrite((void *)addr_ptr, 1, s->unit_size, fp);
                    i += s->unit_size;
            }
        }
    }
    fclose(fp);
}


void modify(state *s){
    char overWrite[s->unit_size];
    int location, val = 0;
    printf("Please enter <location> <val>\n");
    fgets(buffer, sizeof(buffer), stdin);
    sscanf(buffer, "%x %x", &location, &val); 
    if (s->debug_mode == 1){
        printf("Location is: %X\n", location);
        printf("Value is: %X\n", val);
    }
    FILE* fp  = fopen(s->file_name, "r+");
    if (fp == NULL){
        printf("Error: %s couldn't be opened for reading\n", s->file_name);
        return;
    }
    else {
        fseek(fp, 0, SEEK_END);
        int size = ftell(fp);
        if (location > size){
            printf("Error: target location is bigger than %s size\n", s->file_name);
            return;
        }
        switch (s->unit_size){
            case 1 : {
                overWrite[0] = (val & 0xFF);
                break;
            }
            
            case 2 : {
                overWrite[0] = ((val >> 8) & 0xFF);
                overWrite[1] = (val & 0xFF);
                break;
            }

            case 4 : {
                overWrite[0] = ((val >> 24) & 0xFF);
                overWrite[1] = ((val >> 16) & 0xFF);
                overWrite[2] = ((val >> 8) & 0xFF);
                overWrite[3] = (val & 0xFF);
                break;
            }
        }
        fseek(fp, location, SEEK_SET);
        fwrite(overWrite, s->unit_size, 1, fp);
        fclose(fp);
    }
}




