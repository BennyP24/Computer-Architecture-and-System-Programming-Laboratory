#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <elf.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>

struct fun_desc{
    char* name;
    void (*fun)();
};
void toggleDebug();
void examine();
void quit();
void print_sections();
void print_symbols();
void link_check();
void raw_relocation();
void semantic_relocation();
char *get_type(int type);
int debug_mode = 0;
char buffer[100] = "";
char *buff = NULL;
void *map_start; /* will point to the start of the memory mapped file */
struct stat fd_stat; /* this is needed to  the size of the file */
Elf32_Ehdr *header; /* this will point to the header structure */
int Currentfd = -1;
Elf32_Shdr* sections_ptr;
FILE *file;

int main(int argc, char **argv){
    struct fun_desc menu[9] = {{"Toggle Debug Mode", &toggleDebug}, 
    {"Examine ELF File", &examine},{"Print Section Names", &print_sections}, {"Print Symbols", &print_symbols},
     {"Link check", &link_check}, {"Relocation Tables - raw format", &raw_relocation}, {"Relocation tables - semantic format", &semantic_relocation},
      {"Quit", &quit}, {NULL, NULL}};
    int option = 0;
    while(1){
        for(int i = 0; i <= 7; i++)
            printf("%d) %s\n", i, menu[i].name);
        fscanf(stdin, "%d", &option);
        if(option >= 0 && option < 8)
            menu[option].fun();
    }
    return 0;
}

void toggleDebug(){
    printf("in toggle\n");
    if (debug_mode == 0){
        debug_mode = 1;
        printf("Debug flag now on\n");
    }
    else{
        debug_mode = 0;
        printf("Debug flag now off\n");
    }
}

void examine(){
    printf("Enter an ELF file name\n");
    scanf("%s", buffer);
    if (Currentfd != -1){
        fclose(file);
        Currentfd = -1;
    }
    file = fopen(buffer, "r+");
    if (file == NULL){
        perror("Cannot open the filename given");
        Currentfd = -1;
        return;
    }
    Currentfd = fileno(file);
    if( fstat(Currentfd, &fd_stat) != 0 ) {
        perror("stat failed");
        exit(-1);
    }
    if ( (map_start = mmap(0, fd_stat.st_size, PROT_READ | PROT_WRITE , MAP_SHARED, Currentfd, 0)) == MAP_FAILED ) {
        perror("mmap failed");
        exit(-4);
    }
    printf("Magic Bytes 1,2,3 are: %c %c %c\n", *(char *)(map_start + 1), *(char *)(map_start + 2), *(char *)(map_start + 3));
    printf("Entry point address: %#02x\n", *(int *)(map_start + 24));
    /* now, the file is mapped starting at map_start.
    * all we need to do is tell *header to point at the same address:
    */

    header = (Elf32_Ehdr *) map_start;
    printf("Magic Bytes 1,2,3 are: %c %c %c\n", *(char *)(map_start + 1), *(char *)(map_start + 2), *(char *)(map_start + 3));
    if (*(char *)(map_start + 1) != 'E' && *(char *)(map_start + 2) != 'L' && *(char *)(map_start + 3) != 'F'){
        printf("Not an ELF file, returning");
        return;
    }
    int data_encoding = header->e_ident[5];
    switch (data_encoding){
        case 0: {
            printf("Data: Invalid data encoding\n");
            break;
        }
        case 1: {
            printf("Data: 2's complement. Little endian\n");
            break;
        }
        case 2: {
            printf("Data: 2's complement. Big endian\n");
            break;
        }
    }
    printf("Entry point adress: %#02x\n", header->e_entry);
    printf("Section header table offset is: %d\n", header->e_shoff);
    printf("Number of section headers is: %d\n", header->e_shnum);
    printf("Size of section header entry is: %d\n", header->e_shentsize);
    printf("Program header table offset is: %d\n", header->e_phoff);
    printf("The number of Provoid print_symbols()gram header entries is: %d\n", header->e_phnum);
    printf("Size of Program header entry is: %d\n", header->e_phentsize);
}
void print_sections(){
    if (Currentfd == -1){
        perror("No valid file to print\n");
        return;
    }
    Elf32_Shdr *curr = (Elf32_Shdr *)(map_start + header->e_shoff);
    char *curr_name;
    int i;
    sections_ptr=(Elf32_Shdr*) (map_start + header->e_shoff + header->e_shstrndx * header->e_shentsize); 
    curr_name = (char *)(map_start + sections_ptr->sh_offset + curr->sh_name);
    printf("[Nr] %20s %20s %10s %10s %10s\n", "Name", "Type", "Addr", "Off", "Size");
    for(i = 0; i < header->e_shnum ; i++){
        printf("[ %d] %20s %20s %10x %10x %10x\n", i , curr_name + curr->sh_name, get_type(curr->sh_type), curr->sh_addr, curr->sh_offset , curr->sh_size);
        curr++;
    }
}

char *get_type(int type){
    switch(type) {
        case 0:{
            return "NULL";
        }
        case 1:{
            return "PROGBITS";
        }
        case 2:{
            return "SYMTAB";
        }
        case 3:{
            return "STRTAB";
        }
        case 4:{
            return "RELA";
        }
        case 5:{
            return "HASH";
        }
        case 6:{
            return "DYNAMIC";
        }
        case 7:{
            return "NOTE";
        }
        case 8:{
            return "NOBITS";
        }
        case 9:{
            return "REL";
        }
        case 10:{
            return "SHLIB";
        }
        case 11:{
            return "DYNSYM";
        }
        case 14:{
            return "INIT_ARRAY";
        }
        case 15:{
            return "FINI_ARRAY";
        }
        case 16:{
            return "PREINIT_ARRAY";
        }
        case 17:{
            return "GROUP";
        }
        case 18:{
            return "SYMTAB_SHNDX";
        }
        case 19:{
            return "NUM";
        }
        case SHT_LOOS:{
            return "LOOS";
        }
        case SHT_GNU_LIBLIST:{
            return "GNU_LIBLIST";
        }
        case SHT_CHECKSUM:{
            return"CHECKSUM";
        }
        case SHT_LOSUNW:{
            return "LOSUNW";
        }
        //case SHT_SUNW_move:{
        //    return "SUNW_move";
        //}
        case SHT_SUNW_COMDAT:{
            return "SUNW_COMDAT";
        }
        case SHT_SUNW_syminfo:{
            return "SUNW_syminfo";
        }
        case SHT_GNU_verdef:{
            return "GNU_verdef";
        }
        case SHT_GNU_verneed:{
            return "GNU_verneed";
        }
        case SHT_GNU_versym:{
            return "GNU_versym";
        }
        //case SHT_HISUNW:{
            //return "HISUNW";
        //}
        //case SHT_HIOS:{
        //    return "HIOS";
        //}
        case SHT_LOPROC:{
            return "LOPROC";
        }
        case SHT_HIPROC:{
            return "HIPROC";
        }
        case SHT_LOUSER:{
            return "LOUSER";
        }
        case SHT_HIUSER:{
            return "HIUSER";
        }
        default:{
            return "NULL";
        }
    }
}
void print_symbols(){
    if (Currentfd == -1){
        perror("No valid file to print\n");
        return;
    }
    int i;
    Elf32_Shdr *curr = (Elf32_Shdr *)(map_start + header->e_shoff);
    char *section_name;
    int sym_entries;
    Elf32_Sym *symtab;
    char *symbol_string;
    char *section_header = (char *)(map_start + curr[header->e_shstrndx].sh_offset);
    for (i = 0; i < header->e_shnum; i++){
        if (curr[i].sh_type == SHT_SYMTAB) {
            symbol_string = (char *)(map_start + curr[curr[i].sh_link].sh_offset);
            symtab = (Elf32_Sym*)((char *)map_start + curr[i].sh_offset);
            sym_entries = (((Elf32_Shdr)curr[i]).sh_size)/(((Elf32_Shdr)curr[i]).sh_entsize);
        }
    }
    printf("[index]%-5s%20s%20s%20s\n", "value", "section_index", "section name", "symbol_name");
    for (i = 0; i < sym_entries; i++) {
        if (symtab[i].st_shndx == SHN_ABS)
            section_name = "ABS";
        else if (symtab[i].st_shndx == SHN_UNDEF)
            section_name = "UND";
        else if (symtab[i].st_shndx == SHN_COMMON)
            section_name = "COM";
        else
            section_name = (char*)(section_header + curr[symtab[i].st_shndx].sh_name);
        char *symbol_name = (char *)(symbol_string + symtab[i].st_name);
        printf("[%d]\t%-8x\t%-8d\t%-20s%-20s\n", i, symtab[i].st_value, symtab[i].st_shndx, section_name, symbol_name);
    }
}

void link_check(){
    exit(0);
}

void raw_relocation(){
    if (Currentfd == -1){
        perror("No valid file to print\n");
        return;
    }
    Elf32_Shdr *curr = (Elf32_Shdr *)(map_start + header->e_shoff);
    Elf32_Rel *relocation_table;
    int entries = 0;
    for (int i = 0; i < header->e_shnum; i++){
        if (curr->sh_type == SHT_REL){
            printf("Offset\t\tInfo\n"); 
            relocation_table = (Elf32_Rel *)(map_start + curr->sh_offset);
            entries = (curr->sh_size)/(curr->sh_entsize);
            for (int j = 0; j < entries; j++){
                printf("%08x\t\t%08x\n", relocation_table->r_offset, relocation_table->r_info);
                relocation_table++;
            }
        }
        curr++;
    }
}

void semantic_relocation(){
    if (Currentfd == -1){
        perror("No valid file to print\n");
        return;
    }
    Elf32_Shdr *curr = (Elf32_Shdr *)(map_start + header->e_shoff);
    Elf32_Shdr *sections_ptr=(Elf32_Shdr*)(map_start+header->e_shoff);
    Elf32_Rel *relocation_table;
    Elf32_Sym *symtab;
    char *symbol_string = NULL;
    int entries = 0;
    for (int i = 0; i < header->e_shnum; i++){
        if (curr->sh_type == SHT_REL){
            printf("Offset\t\tInfo\t\tType\tSym.Value\tSym.name\n");
            symtab = (Elf32_Sym *)(map_start + sections_ptr[curr->sh_link].sh_offset);
            symbol_string = (char *)(map_start + sections_ptr[sections_ptr[curr->sh_link].sh_link].sh_offset);
            relocation_table = (Elf32_Rel *)(map_start + curr->sh_offset);
            entries = (curr->sh_size)/(curr->sh_entsize);
            for (int j = 0; j < entries; j++){
                int symbol_name = ELF32_R_SYM(relocation_table->r_info);
                int rel_type = ELF32_R_TYPE(relocation_table->r_info);
                printf("%08x\t%08x\t%d\t%08x\t%-20s\n", relocation_table->r_offset, relocation_table->r_info,
                rel_type, symtab->st_value, (symbol_string + symtab[symbol_name].st_name));
                relocation_table++;
            }
            printf("\n");
        }
        curr++;
    }
}

void quit(){
    munmap(map_start, fd_stat.st_size);
    if (Currentfd != -1)
        fclose(file);
    exit(0);
}