section .data
        counter dd 32           ; counter for changing the bits if the num is negative
        mode dd 0               ; indicator for negative or posotive nums
section	.rodata	                ; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	; format string

section .bss			; we define (global) uninitialized variables in .bss section
	an: resb 12		; enough to store integer in [-2,147,483,648 (-2^31) : 2,147,483,647 (2^31-1)]

section .text
	global convertor
	extern printf

convertor:
        push ebp
        mov ebp, esp
        pushad
        mov eax, dword [ebp+8]	; get function argument (pointer to string)
        mov edx, dword [ebp+8]  ; another pointer to string
        xor ecx,ecx
        cmp byte [eax], 0x71    ; check if  ='q', exit the program
        je finish
countBits:
        cmp byte [eax], 0xA     ; check if  ='\n', if so its the end of the input line
        je convertBits
        add cl, 1               ; the counter for how many bits the input is
        inc eax                 ; Pointer for bit counting
        jmp countBits
back:
        mov edx, dword [ebp+8]  ; put pointer to the the beggining of the string again
        mov [mode], dword 1     ; mode = 1 -> negative number
convertBits:
        cmp cl, 32              ; check if the number is 32 bit long
        je posORneg
        cmp byte [edx], 0x31    ; check if ='1' 
        je add                  
        cmp byte [edx], 0xA     ; check if we finished the coneversion
        je string
        dec cl                  ; dec bit counter cl
        inc edx                 ; point to the next bit on the string
        jmp convertBits
negative:
        cmp [counter], dword 0  ; condition for the loop
        je back
        cmp byte[edx], 0x31     ; if bit ='1' change to '0'
        je change0
        mov byte[edx], 0x31     ; else change bit to '1'
        inc edx                 ; point to the next bit on the string
        sub [counter], dword 1  
        jmp negative
change0:
        mov byte[edx], 0x30     ; change bit to '0'
        inc edx                 ; point to the next bit on the string
        sub [counter], dword 1  ; reducing counter
        jmp negative
posORneg:
        cmp byte[edx], 0x31      ; check if the first bit is '1'
        je negative
        inc edx                  ; point to the next bit on the string
        dec cl                   ; dec cl bit counter
        jmp convertBits
add:                            
        mov ebx, 1              
        dec cl
        shl ebx, cl              ; calculating 2^cl for each bit thats = '1'            
        add [an], ebx            ; adding the results in an
        inc edx                  ; pointing to the next bit on the string
        jmp convertBits
string:
        cmp [mode], dword 0     ; checking if the number is negative or posotive
        je continue
        add [an], dword 1       ; if number is negative add 1 to the number after fliiping the bits
continue:
        mov edx , 0             
        mov eax , [an]          ; eax holds the answer thats in an
        mov ebx , an            ; ebx points to the beggining of the answer. holds the address
        add ebx , 11            ; go to the last bit in an
        mov byte [ebx], 0       ; put 0 in the last bit in an so it will be null terminated
        mov ecx , 10            
loop:
        cmp eax,0               ; condition for the loop
        je finish
        div ecx                 ; divide the answer by 10 every time. remnant is in dl
        add edx,'0'             ; put ascii values in dl
        dec ebx                 ; dec ebx so he will point to the bit behind him
        mov byte[ebx], dl       ; put remnant ascii value in the bit ebx is pointing to
        mov edx,0               ; dl = 0 so we could divide again
        jmp loop
addSign:
        dec ebx                 ; point one bit back
        mov byte[ebx], '-'      ; put '-' before the number so it will show negative
        sub [mode], dword 1     
finish:
        cmp [mode], dword 1     ; check if number is negative
        je addSign
        mov [counter], dword 32 
	mov eax ,ebx
	push eax                ; call printf with 2 arguments -  
	push format_string	; pointer to str and pointer to format string
	call printf
        mov [an], dword 0
	add esp, 8		; clean up stack after call

        popad	
	mov esp, ebp
	pop ebp
	ret
