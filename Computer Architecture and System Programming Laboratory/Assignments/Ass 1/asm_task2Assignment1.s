section	.rodata	                ; we define (global) read-only variables in .rodata section
	format_integer: db "%d", 10, 0	; format string
    format_string: db "illegal input", 10, 0
section .bss
    validity: resd 1

section .text
        global assFunc
        extern c_checkValidity
        extern printf

assFunc:
        push ebp
        mov ebp, esp
        pushad
        
        push dword [ebp+12]   ; get argument y
        push dword [ebp+8]    ; get argument x
        call c_checkValidity  ; call c function 
        add esp, 8            ; clean stack after call function

        cmp eax, 0            ; check if eax = 0, if so then arguments not valid
        je not_valid ; change to: PRINT("ILLEGAL INPUT")
        mov eax, 0              
        add eax, dword [ebp+12] ; add argument y to eax
        add eax, dword [ebp+8]  ; add argument x to eax
        push eax                ; push 2 arguments to printf
        push format_integer
        call printf
        add esp, 8              ; clean stack after function call
        jmp finish
not_valid:
        push format_string      
        call printf
        add esp, 4              ; clean stack after fucntion call, 4 because only one push
finish:
        popad
        mov esp, ebp
        pop ebp 
        ret
