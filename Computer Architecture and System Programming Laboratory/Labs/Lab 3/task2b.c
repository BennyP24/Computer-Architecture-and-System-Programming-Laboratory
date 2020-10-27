#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h> 
#include <fcntl.h>

typedef struct virus {
    unsigned short SigSize;
    char virusName[16];
    char sig[];
}virus;

typedef struct link {
    struct link *nextVirus;
    virus *vir;
}link;

struct fun_desc {
  char *name;
  void (*fun)();
};

struct link* list_append(link* virus_list, virus* data);
void list_print(link *virus_list);
void list_free(link *virus_list);
void PrintHex (char* buffer, long length);
struct virus* readVirus(FILE* p);
void printVirus(struct virus* virusStruct);
void detetctV();
void detect_virus(char *buffer, unsigned int size);
void fix();
void kill_virus(char *fileName, int signitureOffset, int signitureSize);
void loadSignatures();
void printSignatures();
void quit ();

struct link* virus_list = 0;
char name[50] = "";
char buffer[10000];

void quit(){
	list_free(virus_list);
	fflush(stdin);
  	exit(0);
}
//global varibles



int main(int argc, char **argv) {
	struct fun_desc menu[] = { {"Load Signatures", loadSignatures}, { "printSignatures", printSignatures},{"Detect viruses", detetctV},{"Fix File", fix}, { "Quit", quit } , {NULL, NULL}};
    int length = sizeof(menu)/sizeof(menu[0]);
    int option;

    while(1) {
    	printf("Please choose a function:\n");
    	for(int i = 1; i < length; i++) {
      		printf("%d %s\n", i, menu[i-1].name);
    	}
   	 	printf("Option: ");
    	scanf("%d", &option);
    	fgetc(stdin);
    	if(option >= length || option <= 0) {
      	printf("Not within bounds\n");
      	quit('a');
    	}
    	printf("Within bounds\n");
    	menu[option-1].fun();
    	
  	}
  

 	return 0;
}

struct link* list_append(link* virus_link, virus* data){
	if(data == NULL){
		return virus_link;
	}
	struct link* helper = virus_link;
	struct link* newLink = malloc(sizeof(link));
	newLink->nextVirus = 0;
	newLink->vir = data;
	if(helper != NULL){
		while(helper->nextVirus){
			helper = helper->nextVirus;
		}
		helper->nextVirus = newLink;
		return virus_link;
	}
	return newLink;
}

void list_print(link *virus_link){
	link* helper = virus_link;
	while (helper != NULL){
		printVirus(helper->vir);
		helper = helper->nextVirus;
	}
}

void list_free(link *virus_list){
	while(virus_list != NULL){
		link* helper = virus_list;
		virus_list = helper->nextVirus;
		free(helper->vir);
		free(helper);
	}
}

void loadSignatures(){
	char fileName[50] ="";
	fgets(fileName ,50 ,stdin);
	sscanf(fileName,"%s\n",fileName);
	FILE* p = NULL;

	struct virus* virusStruct;
	struct link* newLink = 0;
	p = fopen(fileName ,"rb");

	do {
		virusStruct = readVirus(p);
		newLink = list_append(newLink, virusStruct);
	} while(virusStruct != 0);
	virus_list = newLink;

	fclose(p);
}

void printSignatures(){
	if(virus_list == NULL){
		return;
	}
	list_print(virus_list);
}

struct virus* readVirus(FILE* p) {
	struct virus* virusStruct;
	unsigned short size = 0;

	if (0 == fread(&size, sizeof(char), 2, p)) {
		return 0;
	}

	fseek(p, -2, SEEK_CUR);
	virusStruct = malloc(size);
	fread(virusStruct, sizeof(char),size , p);

	return virusStruct;
}

void printVirus(struct virus* virusStruct) {
	unsigned short n = virusStruct->SigSize - 18;
	printf("Virus name : %s \nVirus size : %d\n" ,virusStruct->virusName, n);
	printf("signature :\n");
	PrintHex(virusStruct->sig, n);
	printf("\n");
}

void detetctV(){
	
	fgets(name ,50 ,stdin);
	sscanf(name,"%s\n",name);
	FILE* t = NULL;
	t = fopen(name, "rb");
	fseek(t,0,SEEK_END);
	unsigned int storage = ftell(t);
	rewind(t);
	fread(buffer,1,storage, t);
	fclose(t);
	detect_virus(buffer, storage);
}

void detect_virus(char *buffer, unsigned int size){
	struct link* pointer = virus_list;
	while(pointer != NULL ){
		int k = 0;
		while ( k < size){
			if(pointer->vir->SigSize + k - 18 <= size){ //if error\segmention fault delete =
				if(memcmp(pointer->vir->sig, buffer+k, pointer->vir->SigSize - 18) == 0){
					printf ("the starting point: %d\n", k);
					printf("the virus name: %s\n", pointer->vir->virusName);
					printf("the signature size: %d\n", pointer->vir->SigSize - 18);	
				}	
			}
			k++;
		}
	pointer = pointer->nextVirus;
	}
}	

void fix(){
	int signitureOffset = 0, signitureSize = 0;
	printf("starting byte for virus: ");
   	scanf("%d", &signitureOffset);
   	fgetc(stdin);
   	printf("Size of the virus: ");
   	scanf("%d", &signitureSize);
   	fgetc(stdin);
   	kill_virus(name, signitureOffset, signitureSize);
}

void kill_virus(char* name, int signitureOffset, int signitureSize){
	FILE* t = NULL;
	t = fopen(name, "rb");
	fseek(t, signitureOffset, SEEK_CUR);
	char str[signitureSize];
	for (int i = 0; i < signitureSize; ++i)
	{
		str[i] = 0x90;
	}
	fwrite(str, 1, signitureSize, t);
	fclose(t);
}

void PrintHex (char* buffer, long length){ 
	for(int i=0; i < length; i++){
		printf("%x ", buffer[i] & 0xff);
	}
}
