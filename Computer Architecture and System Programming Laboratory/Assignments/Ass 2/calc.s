
;; Benny Peresetsky & Shir Ben Harush ;;
;; Assignment2 ;;

section .data
    
    stack_location: dd 0                    ;; cureent slot in opStack
    duplicate_location: dd 0                ;; slot for duplicate in opStack
    last_link: dd 0                         ;; address of the last link created
    reminder_link:dd 0                      ;; address of the reminder link created
    reminder_previous_link: dd 0            ;; address of the previous reminder link
    reminder_first_link: dd 0               ;; address of the first reminder_link 
    previous_link: dd 0                     ;; address of the privous link
    current_link: dd 0                      ;; address of the current link
    opCounter: dd 0                         ;; counter for total operations
    debugMode: db 0                         ;; flag for debug mode
    ones: db 0                              ;; counter for 1-bits
    value: dd 0                             ;; value for shl_real
    loopCounter: db 0                       ;; counter for shift left loop
    carryBit: db 0                          ;; flag for carry
    shiftRight_first:db 0                   ;; helper to shift right


section .rodata
    
    sizeOpStack: equ 5                                                                  ; static array with 5 slots
    error_overflow: db "Error: Operand Stack Overflow", 10, 0                           ; format for overflow error
    error_insufficient: db "Error: Insufficient Number of Arguments on Stack", 10, 0    ; format for Insufficient error
    error_y: db "wrong Y value", 10, 0                                                  ; format for Y > 200 error
    calc_format: db "calc: ", 0                                                         ; format for calc(input)
    format_string: db "%s", 0                                                           ; format string
    format_hexa: db "%X", 0                                                             ; format hexa
    format_hexa_zeroes: db "%02X", 0                                                    ; format hexa with zeroes
    new_line: db "", 10, 0                                                              ; format for new line

section .bss

    buffer: resb 80                             ;; buffer for input, max 80 charecters
    opStack: resb 4*sizeOpStack                 ;; operand stack

section .text

align 16
    global main 
    extern printf
    extern fprintf 
    extern fflush
    extern malloc 
    extern calloc 
    extern free  
    extern fgets 
    extern getchar
    extern getc
    extern stdin
    extern stderr
    extern exit

                            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;beginning of macros;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%macro print_debug 3                        ;; macro for fprintf to sderr (DEBUG)
    pushad                     
    pushfd

    push %1
    push %2
    push %3
    call fprintf
    add esp, 12

    popfd
    popad
%endmacro

%macro print 2                              ;; macro for printf with 2 arguments (stdout)
    pushad                                  ;; clean the stack after the call to printf 
    pushfd                                  ;; saving the registers and restoring them
    
    push %2
    push %1
    call printf
    add esp, 8

    popfd
    popad
%endmacro

%macro print 1                              ;; macro for printf with solo argument (stdout)
    pushad
    pushfd

    push %1
    call printf
    add esp, 4

    popfd
    popad
%endmacro

%macro input 3                              ;; macro for reading the input with fgets(3 arguments)
    pushad
    pushfd

    push %3
    push %2
    push %1
    call fgets
    add esp, 12

    popfd
    popad
%endmacro

%macro check 2                              ;; macro for checking if its one of the operands and if so jump to its function

    cmp byte [buffer], %1
    je %2

%endmacro

%macro num_or_letter 1                      ;; macro for converting number or letter to hexa values

    cmp byte [buffer + ecx], 0x39                   ;; check if bit is above 9 = (letter)
    ja %%lett
    mov %1, byte [buffer + ecx]
    sub %1, '0'                                     ;; put value of number
    jmp %%numEnd 
        %%lett:
            mov %1, byte [buffer + ecx]             
            sub %1, 55                              ;; put value of hexa letter
        %%numEnd:
%endmacro

%macro create_link_for_zero 0                     ;; macro for creating link if number == 0

    mov byte [eax], 0                              ;; data in link created holds zeroes
    mov edx, dword [stack_location]
    mov ebx, opStack
    mov dword [ebx + edx*4], eax                    ;; stack is pointing ti the link created
    mov dword [eax + 1], 0
    mov dword [last_link], eax
    add esp, 4

%endmacro

%macro create_first_link 0                  ;; macro for creating first link in case of even number length
    pushad
    pushfd

    push sizeOpStack
    call malloc                                     ;; eax holds the address for the new link in the heap
    mov byte [eax], bh                              ;; add the number to the data of the link 
    mov edx, dword [stack_location]                     
    mov ebx, opStack
    mov dword [ebx + edx*4], eax                    ;; the opStack is pointing to the last link created in memory
    mov dword [eax + 1], 0
    mov dword [last_link], eax                  ;; saced the address of the last link created
    add esp, 4                                      ;; clean stack after malloc
    
    popfd
    popad
%endmacro

%macro create_to_linkList 0                 ;; macro for continuing the linked list
    pushad
    pushfd
    
    push sizeOpStack
    call malloc                                     ;; creating space in memory for a new link (eax holds the address)
    mov byte [eax], bh                              ;; put the number inside the data in the link
    mov edx, dword [stack_location]
    mov ebx, opStack
    mov dword [ebx + edx*4], eax                    ;; slot in opStack pointer to the new link
    mov ecx , dword [last_link]                 
    mov dword [eax + 1], ecx                        ;; the new link is pointing to the last link created
    mov dword [last_link], eax                  ;; save the address of the last link created
    add esp, 4
    
    popfd
    popad
%endmacro

                            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;end of macros;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

main:                       ;;;;;;;;;;;;;;;;;;;;;;;;beginning of main program;;;;;;;;;;;;;;;;;;;;;;;;

    push ebp                                  ;; push ebp old value
    mov ebp, esp
    pushad                                    ;; save all registers
    mov ecx, [ebp + 8]                        ;; put number of arguments in ecx(argc)
    cmp ecx, 1
    je noDebug                                ;; no "-d" (debug mode)
    mov ecx, dword [ebp + 12]                 ;; put pointer to the first argument(argv) in ecx
    mov ecx, [ecx + 4]                        ;; put argv[1] in ecx
    cmp byte [ecx], 0x2D                      ;; ? == '-'
    jne noDebug                               ;; no "-d" (debug mode)
    inc ecx
    cmp byte [ecx], 0x64                      ;; ? == 'd'
    jne noDebug
    add byte [debugMode], 1                   ;; debug mode is on
                              
noDebug:

    call my_calc                              ;; go to my_calc function

    popad                                     ;; restore all registers
    mov esp, ebp
    pop ebp
    push 0
    call exit
    
my_calc:                     ;;;;;;;;;;;;;;;;;;;;;;beginning of my_calc function;;;;;;;;;;;;;;;;;;;;;;

    push ebp                                   ;; save ebp old value(main)
    mov ebp, esp    

inputLoop:
    pushad
    pushfd
    print calc_format                          ;; print "calc: " to stdout

    input buffer, 80, dword[stdin]             ;; reading input from stdin 

    check 'q', end                             ;; check if the user typed 'q'                            
    check '+', addNumbers                      ;; check if the user typed '+'
    check 'p', popAndPrint                     ;; check if the user typed 'p'
    check 'd', duplicate                       ;; check if the user typed 'd'
    check '^', shiftLeft                       ;; check if the user typed '^'
    check 'v', shiftRight                      ;; check if the user typed 'v'
    check 'n', numbersOfOne                    ;; check if the user typed 'n'

    cmp byte [debugMode], 1                    ;; debugMode ==? 1
    jne checking
    print_debug buffer, format_string, dword[stderr]                ;; printing the number typed from user to stderr(DEBUG) 

checking:

    call insert_number                         ;; if the user typed a number, push it to the opStack 

 
    popfd
    popad
    jmp inputLoop                              ;; jump back to get more input from user

popAndPrint:                     ;;;;;;;;;;;;;;;;;;;;;;label for 'p' operand;;;;;;;;;;;;;;;;;;;;;;;

    cmp dword [stack_location], 0              ;; check if the stack is empty
    jne popAndPrint_real
    print error_insufficient                   ;; prine Insufficient error
    add dword [opCounter], 1                   ;; increment operations counter
    popfd
    popad
    jmp inputLoop                              ;; restore the previous conditions and get input again                           
popAndPrint_real:
    add dword [opCounter], 1                   ;; increment the operations counter
    sub dword [stack_location], 1              ;; go back and point to the last slot we used in opStack
    mov edx, dword [stack_location]
    mov ebx, opStack
    mov esi, dword [ebx + edx*4]               ;; esi now holds the address of the first link  
    pushad                                  
    pushfd              
    push esi
    call popAndPrint_stack                     ;; calling recursive function for popAndPrint with the first link given
    add esp, 4
    popfd
    popad
    print new_line                             
    jmp inputLoop

numbersOfOne:                    ;;;;;;;;;;;;;;;;;;;;;;;;label for 'n' operand;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    cmp dword [stack_location], 0               ;; check if the stack is empty
    jne numbersOfOne_real
    print error_insufficient                    ;; print Insufficient error
    add dword [opCounter], 1                    ;; increment the operations counter
    popfd
    popad
    jmp inputLoop
numbersOfOne_real:
    mov byte [ones], 0                          ;; reset the one bits counter
    add dword [opCounter], 1                    ;; increment the operations counter
    sub dword [stack_location], 1               ;; one slot back to go to the last number
    mov edx, dword [stack_location]
    mov ebx, opStack
    mov esi, dword [ebx + edx*4]                ;; esi holds the address of the first link in the linked list
    pushad
    pushfd
    push esi
    call numbersOfOne_stack                     ;; call numbersOfOne recursive function
    add esp, 4
    popfd
    popad
    push sizeOpStack
    call malloc                                 ;; eax now holds the address of the link created
    mov ebx, 0
    mov bl, byte [ones]                         ;; bl holds the sum of how many ones bits
    cmp byte [debugMode], 0
    je noDebug_numbersOfones
    print_debug ebx, format_hexa, dword [stderr]    ;; print to sderr the number of one-bits (DEBUG)
    print new_line
noDebug_numbersOfones:  
    mov byte [eax], bl                          ;; eax (the new link) will hold the numbersOfOne answer
    mov dword [eax + 1], 0                      ;; next link == 0
    mov edx, dword [stack_location]
    mov ebx, opStack
    mov dword [ebx + edx*4], eax                ;; stack is pointing to the link created
    mov dword [last_link], eax
    add dword [stack_location], 1               ;; increment the stack slot
    add esp, 4
    popfd
    popad
    jmp inputLoop                               ;; go back to get more input from user

duplicate:                         ;;;;;;;;;;;;;;;;;;;;;;;;;label for 'd' operand;;;;;;;;;;;;;;;;;;;;;;;;;;

    cmp dword [stack_location], 0
    jne another_one
    print error_insufficient                    ;; print Insufficient error
    add dword [opCounter], 1
    popfd
    popad
    jmp inputLoop
another_one:
    cmp dword [stack_location], 5
    jne duplicate_real
    print error_overflow                        ;; print overflow error
    add dword [opCounter], 1                    ;; increment the operations counter
    popfd
    popad
    jmp inputLoop
duplicate_real:
    mov ecx, dword [stack_location]             ;; save the slot where to duplicate
    mov dword [duplicate_location], ecx
    add dword [opCounter], 1                    ;; increment the operations counter
    sub dword [stack_location], 1       
    mov ecx, dword[stack_location]              ;; ecx points to the last linked list created
    mov ebx, opStack
    mov esi, dword [ebx + ecx*4]                ;; esi now points to the first link we need duplicate  
    pushad
    push sizeOpStack
    call malloc
    mov dword [current_link], eax               ;; save the new link created in current_link
    mov dword [last_link], eax              ;; save the first link in the last linked list on opStack
    add esp, 4
    popad
    mov edx, dword [current_link]               ;; edx holds the new linke created
    mov ecx, dword [duplicate_location]
    mov ebx, opStack
    mov dword [ebx + ecx*4], edx                ;; stack is now duplicated the first link

duplicate_loop:
    mov ecx, dword [current_link]
    mov dh, byte [esi]                          ;; dh holds the data in the link we wwant to duplicate
    mov byte [ecx], dh                          ;; copy the data in the link
    cmp dword [esi + 1], 0                      ;; check if there is a next link(condition for loop)
    je finish_duplicate
    pushad
    push sizeOpStack
    call malloc
    mov dword [current_link], eax
    add esp, 4
    popad
    mov edx, dword [current_link]
    mov dword [ecx + 1], edx                    ;; edx(/the new link created) will be next link to ecx(holds the last link)
    mov esi, dword [esi + 1]                    ;; ebx gets the next link in the linkes list
    mov ecx, dword [ecx + 1]                    ;; ecx gets the next link in the duplicate linked list
    mov dword [current_link], ecx
    jmp duplicate_loop
finish_duplicate:
    add dword [stack_location], 2
    mov dword [ecx + 1], 0                      ;; next link in last link in the duplicate is null
    cmp byte [debugMode], 1                     ;; check if debugMode is on, if so print the value
    jne finish_duplicate_noDebug
    mov eax, dword [last_link]
    push eax
    call print_last_result
    add esp, 4
    print new_line
finish_duplicate_noDebug:
    popfd
    popad
    jmp inputLoop


addNumbers:                         ;;;;;;;;;;;;;;;;;;;;;;label for '+' operand;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    cmp dword [stack_location], 0               ;; check if the stack is empty
    jne addNumbers_cont
    print error_insufficient
    add dword [opCounter], 1                    ;; increment the operations counter
    popfd
    popad
    jmp inputLoop                               ;; go back to inputLoop to get more input from user
addNumbers_cont:
    sub dword [stack_location], 1               ;; go to the last number in the stack
    cmp dword [stack_location], 0               ;; check if there was only one number in stack
    jne addNumbers_real
    print error_insufficient
    add dword [stack_location], 1               ;; go back to the same situation like before
    add dword [opCounter], 1                    ;; increment the operations counter
    popfd
    popad
    jmp inputLoop
addNumbers_real:
    add dword [opCounter], 1                    ;; increment the operations counter
    call addition_numbers                       ;; call the addition function
    cmp byte [debugMode], 1                     ;; check if debugMode is on
    jne end_addNumbers
    mov eax, dword [last_link]              ;; put in eax the first link in the last linked list on stack
    push eax
    call print_last_result                      ;; print to sderr the last number (DEBUG)
    add esp, 4
    print new_line
end_addNumbers:
    add dword [stack_location], 1
    popfd
    popad
    jmp inputLoop

shiftLeft:                          ;;;;;;;;;;;;;;;;;;;;;;label for '^' operand;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    cmp dword [stack_location], 0               ;; check if the stack is empty
    jne shiftLeft_contChecking
    print error_insufficient
    add dword [opCounter], 1
    popfd
    popad
    jmp inputLoop
shiftLeft_contChecking:
    sub dword [stack_location], 1
    mov ebx, dword [stack_location]
    mov esi, dword [opStack + ebx*4]            ;; esi holds the first link of the last number
    cmp dword [stack_location], 0               ;; check if there was only one number on opStack
    jne shiftLeft_Y1
    print error_insufficient
    add dword [opCounter], 1
    add dword [stack_location], 1
    popfd
    popad
    jmp inputLoop
shiftLeft_Y1:
    mov bl, byte [esi]                          ;; al holds the data for Y
    mov edx, dword [esi + 1]                    ;; edx holds the next link of the last number
    cmp edx, 0                                  ;; check if next link exists, is so Y>200
    je shiftLeft_Y2
    print error_y
    add dword [opCounter], 1
    add dword [stack_location],1 
    popfd
    popad
    jmp inputLoop
shiftLeft_Y2:
    cmp bl, 200                                 ;; check if Y>200, if so go back to get more input and throw error
    jbe shiftLeft_real
    print error_y
    add dword [opCounter], 1
    add dword [stack_location], 1
    popfd
    popad
    jmp inputLoop
shiftLeft_real:
    mov byte [loopCounter], bl                  ;; loopCounter has the y data
    mov edi, esi
    pushad
    push edi
    call free
    add esp, 4
    popad
    sub dword [stack_location], 1
    mov ebx, dword [stack_location]
    mov ecx, dword [opStack + ebx*4]            ;; ecx holds the first link of the second last number
shiftLeft_real_loop:
    mov dword [previous_link], 0
    cmp byte [loopCounter], 0
    je end_shiftLeft_real
    pushad
    push 0
    push ecx
    call shl_real                               ;; call the recursive function for shiftLeft
    add esp, 8
    popad
    dec byte [loopCounter]
    jmp shiftLeft_real_loop
end_shiftLeft_real:
    add dword [opCounter], 1
    cmp byte [debugMode], 1
    jne fin_shl
    mov ebx, dword [stack_location]
    mov eax, [opStack + ebx*4]
    push eax
    call print_last_result
    add esp, 4
    print new_line
fin_shl:
    add dword [stack_location], 1
    popfd
    popad
    jmp inputLoop


shiftRight:                           ;;;;;;;;;;;;;;;;;;;;label for 'v' operand;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    cmp dword [stack_location], 0               ;; check if the stack is empty
    jne shiftRight_contChecking
    print error_insufficient
    add dword [opCounter], 1
    popfd
    popad
    jmp inputLoop
shiftRight_contChecking:
    sub dword [stack_location], 1
    mov ebx, dword [stack_location]
    mov esi, dword [opStack + ebx*4]            ;; esi holds the first link of the last number
    cmp dword [stack_location], 0               ;; check if there was only one number on opStack
    jne shiftRight_Y1
    print error_insufficient
    add dword [opCounter], 1
    add dword [stack_location], 1
    popfd
    popad
    jmp inputLoop
shiftRight_Y1:
    mov bl, byte [esi]                          ;; al holds the data for Y
    mov edx, dword [esi + 1]                    ;; edx holds the next link of the last number
    cmp edx, 0                                  ;; check if next link exists, is so Y>200
    je shiftRight_Y2
    print error_y
    add dword [opCounter], 1
    add dword [stack_location],1 
    popfd
    popad
    jmp inputLoop
shiftRight_Y2:
    cmp bl, 200                                 ;; check if Y>200, if so go back to get more input and throw error
    jbe shiftRight_real
    print error_y
    add dword [opCounter], 1
    add dword [stack_location], 1
    popfd
    popad
    jmp inputLoop
shiftRight_real:
    mov byte [loopCounter], bl                  ;; loopCounter has the y data
    mov edi, esi
    pushad
    push edi
    call free
    add esp, 4
    popad
    sub dword [stack_location], 1
shiftRight_real_loop:
    mov ebx, dword [stack_location]
    mov ecx, dword [opStack + ebx*4]            ;; ecx holds the first link of the second last number
    mov dword [reminder_link], 0
    mov dword [reminder_previous_link], 0
    mov dword [reminder_first_link], 0
    mov dword [previous_link], 0
    cmp byte [loopCounter], 0
    je after_removeLeadZero
    mov byte [shiftRight_first], 1
    pushad
    push ecx
    call shr_real                               ;; call the recursive function for shiftLeft
    add dword [stack_location], 1
    mov ebx, dword [stack_location]
    mov ecx, dword [reminder_first_link]
    mov dword [opStack + ebx*4], ecx
    jmp end_shiftRight_real
cont_loop_shr:
    pushad
    call addition_numbers                       ;; the addition function increment the operations counter
    popad
    add esp, 4
    popad
    dec byte [loopCounter]
    jmp shiftRight_real_loop
end_shiftRight_real:
    cmp byte [ecx], 0
    jne cont_loop_shr
    cmp dword [ecx + 1], 0
    je cont_loop_shr
    mov edi, ecx
    mov ecx, dword [ecx + 1]
    mov dword [opStack + ebx*4], ecx
    pushad
    push edi
    call free
    add esp, 4
    popad
    jmp end_shiftRight_real
after_removeLeadZero:
    add dword [stack_location], 1 
    popfd
    popad
    jmp inputLoop

end:                                ;;;;;;;;;;;;;;;;;;;;;;label for 'q' operand;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    print format_hexa, dword [opCounter]        ;; printing the operations counter in the end of program
    print new_line
    popfd
    popad                                       ;; restore all registers
    mov esp, ebp
    pop ebp
    ret


addition_numbers:                   ;;;;;;;;;;;;;;;;;;;beginning of addition_numbers function;;;;;;;;;;;;;;;;;;;;;;;

    push ebp
    mov ebp, esp
    pushad
    pushfd
    mov ecx, dword [stack_location]
    mov ebx, opStack
    mov esi, dword [ebx + ecx*4]                ;; esi holds the first link of the last number on stack
    sub dword [stack_location], 1               ;; decrement the stack_location to get the second last number
    mov edx, dword [stack_location]
    mov ecx, dword [ebx + edx*4]                ;; ecx holds the first link of the second last number needed to add
    pushad
    push sizeOpStack
    call malloc
    mov dword [current_link], eax
    mov dword [last_link], eax
    add esp, 4 
    popad
    mov edx, dword [current_link]               ;; edx holds the link created
    mov dword [edx + 1], 0
    mov ebx, dword [stack_location]
    mov edi, opStack
    mov dword [edi + ebx*4], edx                ;; opstack is pointing to the link created, part of the linked list of the sum
    mov al, byte [ecx]                          
    add al, byte [esi]                          ;; ah holds the sum of the first two links
    jnc no_add_carry
    jmp add_carry

loop_add_carry:
    mov al, byte [ecx]
    add byte [carryBit], 255                    ;; check if there a carry from the last sum of numbers (carry flag will be on if so)
    adc al, byte [esi]
    jnc no_add_carry          
add_carry:
    mov byte [carryBit], 1
    jmp cont_carryOrNo
no_add_carry:
    mov byte [carryBit], 0
cont_carryOrNo:
    mov edx, dword [current_link] 
    mov byte [edx], al                          ;; mov the sum to the link created data
    mov edi, esi
    mov ebx, ecx
    mov esi, dword [esi + 1]                    ;; esi holds the next link of the last number on stack
    mov ecx, dword [ecx + 1]                    ;; ecx holds the next link of the second last number on stack
    pushad
    push edi
    call free                                   ;; clean the link of the last number
    add esp, 4
    popad
    pushad
    push ebx
    call free                                   ;; clean the link of the second last number
    add esp, 4 
    popad


                                                ;;;;;; checking if one of the next links empty or not ;;;;;;


    cmp ecx, 0                                  ;; check if the link of the second last number is empty   
    je last_number                              ;; if so, jump to add only the last number on opStack
    cmp esi, 0                                  ;; check if the link of the last number is empty
    je second_last_number                       ;; if so, jump to add only the last number on opStack
    pushad
    push sizeOpStack
    call malloc
    mov ecx, dword [current_link]
    mov dword [ecx + 1], eax                    ;; make sure the new link is the last on the new sum linked list
    mov dword [current_link], eax
    add esp, 4
    popad
    jmp loop_add_carry

last_number:
    cmp esi, 0                                  ;; check if both of the numbers are empty
    je finish_addNumbers
    pushad
    push sizeOpStack
    call malloc
    mov edx, dword [current_link]
    mov dword [edx + 1], eax                    ;; new link is the last link of the sum linked list
    mov dword [current_link], eax               ;; current_link is holding new link address
    add esp, 4
    popad
    mov al, byte [esi]                          ;; get the data of the link
    add al, byte [carryBit]                     ;; add the carry
    mov edx, dword [current_link]
    mov byte [edx], al                          ;; new link is holding the sum of the links
    mov dword [edx + 1], 0
    mov edi, esi
    mov esi, dword [esi + 1]                    ;; esi holds the next link of the last number on opStack
    pushad
    push edi
    call free
    add esp, 4
    popad
    mov byte [carryBit], 0
    jnc last_number
    mov byte [carryBit], 1
    jmp last_number

second_last_number:
    cmp ecx, 0                                  ;; check if both of the numbers are empty
    je finish_addNumbers
    pushad
    push sizeOpStack
    call malloc
    mov edx, dword [current_link]
    mov dword [edx + 1], eax                    ;; new link is the last link of the sum linked list
    mov dword [current_link], eax
    add esp, 4
    popad
    mov al, byte [ecx]                          ;; get the data of the link
    add al, byte [carryBit]                     ;; add the carry
    mov edx, dword[current_link]
    mov byte [edx], al                          ;; get the sum to the new link data
    mov dword [edx + 1], 0   

    mov ebx, ecx
    mov ecx, dword [ecx + 1]                    ;; ecx holds the next link of the second lat number linked list
    pushad
    push ebx
    call free
    add esp, 4
    popad
    mov byte [carryBit], 0
    jnc second_last_number
    mov byte [carryBit], 1
    jmp second_last_number   
finish_addNumbers:
    cmp byte [carryBit], 1
    je addNumbers_newLink
    popfd
    popad
    mov esp, ebp
    pop ebp
    ret
addNumbers_newLink:
    pushad
    push sizeOpStack
    call malloc
    mov edx, dword [current_link]
    mov dword [edx + 1], eax
    mov dword [current_link], eax
    add esp, 4
    popad
    mov edx, dword [current_link]
    mov dword [edx + 1], 0
    mov byte [edx], 1
    popfd
    popad
    mov esp, ebp
    pop ebp
    ret


shl_real:                            ;;;;;;;;;;;;;;;;;;beginning of shiftLeft recursive function;;;;;;;;;;;;;;;;;;;;

    push ebp
    mov ebp, esp
    pushad
    pushfd
    mov byte [carryBit], 0
    mov ecx, [ebp + 8]                           ;; ecx holds the link for the second last number
    mov dword [current_link], ecx
    mov esi, [ebp + 12]                          ;; edx holds the carry from the last recursive loop
    cmp ecx, 0
    jne shl_real_cont
    cmp esi, 0
    jne carry_ButNoLInk
    popfd
    popad
    mov esp, ebp
    pop ebp
    ret
carry_ButNoLInk:
    pushad
    push sizeOpStack
    call malloc
    mov esi, dword [previous_link]
    mov dword [esi + 1], eax
    mov byte [eax], 1                           ;; creating a new link with 1 in data because of the carry
    mov dword [eax + 1], 0
    mov dword [current_link], eax
    add esp, 4
    popad
    mov eax, dword [current_link]
    popfd
    popad
    mov esp, ebp
    pop ebp
    ret
shl_real_cont:
    mov al, byte [ecx]                        ;; al holds the link data
    mov bl, 2
    mul bl                                    ;; multipie al by 2
    mov edx, esi
    add ax, dx
    cmp ah, 1                                 ;; check if the (number*2 + carry) > 255(max)
    jne finish_shl_real
    mov byte [carryBit], 1
finish_shl_real:
    mov byte [ecx], al                        ;; if so, put in the link (number*2 + carry) - 256
    mov dword [previous_link], ecx
    mov ecx, dword [ecx + 1]
    movzx ebx, byte [carryBit]
    push ebx
    push ecx
    call shl_real
    add esp, 8
    mov eax, dword [current_link]
    popfd
    popad
    mov esp, ebp
    pop ebp
    ret


shr_real:                            ;;;;;;;;;;;;;;;;;;beginning of shiftRight recursive function;;;;;;;;;;;;;;;;;;;;

    push ebp
    mov ebp, esp
    pushad
    pushfd
    mov ecx, [ebp + 8]                           ;; ecx holds the link for the second last number
    mov dword [current_link], ecx
    cmp ecx, 0
    jne shr_real_cont 
    popfd
    popad
    mov esp, ebp
    pop ebp
    ret
shr_real_cont:
    movzx ax, byte [ecx]                        ;; al holds the link data
    mov bl, 2
    div bl                                      ;; divide al by 2
    mov byte [ecx], al
    cmp byte [shiftRight_first], 1
    je finish_shr_real
    mov edi, dword [reminder_link]
    mov dword [reminder_previous_link], edi
    pushad
    push sizeOpStack
    call malloc
    mov dword [reminder_link], eax
    add esp, 4
    popad
    cmp dword [reminder_first_link], 0
    jne no_first
    mov esi, dword [reminder_link]
    mov dword [reminder_first_link], esi
    mov byte [esi], 0
    jmp no_first_reminder
no_first:
    mov esi, dword [reminder_link]
    mov byte [esi], 0
    mov edx, dword [reminder_previous_link]
    mov dword [edx + 1], esi
no_first_reminder:
    cmp ah, 0
    je finish_shr_real
    mov byte [esi], 0x80    
finish_shr_real:
    mov dword [previous_link], ecx
    mov ecx, dword [ecx + 1]
    mov byte [shiftRight_first], 0
    push ecx
    call shr_real
    add esp, 4
    popfd
    popad
    mov esp, ebp
    pop ebp
    ret


numbersOfOne_stack:                  ;;;;;;;;;;;;;;;;;;beginning of numbersOfOne recursive function;;;;;;;;;;;;;;;;;
    push ebp
    mov ebp, esp
    pushad
    pushfd
    mov esi, [ebp + 8]                          ;; esi is the last link created
    mov ecx, dword [esi + 1]                    ;; ecx gets the next link
    cmp ecx, dword 0                            ;; check if the next link == null
    mov eax, 0
    movzx eax, byte [esi]                       ;; eax will hold the data in the link
    je finNumbersOfOne                          ;; if next link == null --> finNumbersOfOne
    pushad
    pushfd
    push ecx
    call numbersOfOne_stack                     ;; recursive call with the next link (if exists)
    add esp, 4
    popfd
    popad

finNumbersOfOne:
    cmp al, 0                                   ;; condition for loop ==> ax == 0??
    je finishNumbersOfOne
    mov ecx, 2
    div ecx                                     ;; divide by 2 each time
    add byte[ones], dl                          ;; dl holds the remenant, add it to the answer of ones
    jmp finNumbersOfOne
finishNumbersOfOne:
    pushad
    push esi
    call free                                   ;; clean the link after calculating the one bits in the data 
    add esp, 4
    popad
    popfd
    popad
    mov esp, ebp
    pop ebp
    ret


popAndPrint_stack:                   ;;;;;;;;;;;;;;;beginning of popAndPrint recursive function;;;;;;;;;;;;;;;;;;;
    push ebp
    mov ebp, esp
    pushad 
    pushfd
    mov esi, [ebp + 8]                                ;; esi is the last link created
    mov ecx, dword [esi + 1]                          ;; ecx gets the next link
    mov edx, 0
    cmp ecx, dword 0                                  ;; check if its the link == null
    je finishPop
    
    pushad
    pushfd                  
    push ecx
    call popAndPrint_stack                            ;; recursive call to print all links
    add esp, 4
    popfd
    popad
finishPop:
    mov ebx, format_hexa_zeroes
    cmp ecx, 0
    jne finishPop_notLast
    mov ebx, format_hexa 
finishPop_notLast:
    movzx edx, byte [esi]                             ;; edx will hold the data in the link
    print ebx, edx                            ;; print the data
    pushad
    push esi
    call free                                         ;; clean the link
    add esp, 4
    popad
    popfd
    popad
    mov esp, ebp
    pop ebp
    ret

print_last_result:          ;;;;;;;;;;;;;;;;;;;;beginning of recursive function for debug print;;;;;;;;;;;;;;;;;;;;;

    push ebp
    mov ebp, esp
    pushad
    pushfd
    mov eax, [ebp + 8]                                ;; eax holda the argument we got (first link)
    mov ecx, dword [eax + 1]                          ;; ecx holds the next link
    cmp ecx, 0                                        ;; check if there is any next link
    je start_print
    pushad
    pushfd
    push ecx
    call print_last_result                            ;; recursive call to the next link
    add esp, 4
    popfd
    popad
start_print:
    mov ebx, format_hexa_zeroes
    cmp ecx, 0
    jne start_print_notLast
    mov ebx, format_hexa
start_print_notLast:
    mov edx, 0
    movzx edx, byte [eax]                             ;; edx have the data from link
    print_debug edx, ebx, dword [stderr]      ;; print the value to stderr (DEBUG)
    popfd
    popad
    mov esp, ebp
    pop ebp
    ret


insert_number:                 ;;;;;;;;;;;;;;beginning of function for reaciving a number;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push ebp
    mov ebp, esp
    pushad
    pushfd
    cmp dword [stack_location], 5                     ;; check for overflow
    jne notOverflow
    print error_overflow                              ;; print overflow error

input_Again:
    cmp dword [stack_location], 5                     ;; in case of stack full we dont inc the stack_location
    je in_Again
    add dword [stack_location], 1                     ;; move to the next slot in stack
in_Again:                                                   
    popfd
    popad
    mov esp, ebp
    pop ebp
    ret                                               ;; return to my_calc function to get more input

notOverflow:
    mov ecx, 0
    cmp byte [buffer + ecx], 0xA                      ;; check if we got an empty line
    je in_Again

delete_Zeroes:
    cmp byte [buffer + ecx], 0x30                     ;; check for leading zeroes
    jne check_length                                  ;; no leading zeroes
    inc ecx                                           ;; increment the ecx counter
    jmp delete_Zeroes                                 ;; go back to delete_Zeroes loop
check_length:
    mov edx, ecx                                      ;; edx will point to the first number != 0
cont:                                                
    cmp byte [buffer + ecx], 0xA                      ;; ecx got to the end of the string  || we got a string of zeroes so the number == 0
    je end_length                                       
    inc ecx                                           ;; point to the next char in buffer
    jmp cont
end_length:
    sub ecx, edx                                      ;; ecx will now hold the length of the number
    cmp ecx, 0                                        ;; string of zeroes ?????
    je  zero_link
    and ecx, 1                                        
    cmp ecx, 0                                        ;; check if the length is even or odd                       
    je even
    mov ecx, edx                                      ;; ecx point to the the first char !=0
    mov edx, 0
    push sizeOpStack
    call malloc                                       ;; eax holds the address for the new link 
    mov ecx, 0                                
    num_or_letter bl                                  ;; check the bit and put correct value in reg bl
    mov byte [eax], bl                                ;; move the number to the data of the link created
    mov edx, dword [stack_location]
    mov ebx, opStack
    mov dword [ebx + edx*4], eax                      ;; the opStack is pointing to the last link created
    mov dword [eax + 1], 0                  
    mov dword [last_link], eax                    ;; save pointer to the last link created
    add esp, 4                                        ;; clean stack after malloc
    inc ecx
    jmp add_linkedList                                ;; continue adding numbers to links(if there are any numbers left)
zero_link:
    push sizeOpStack
    call malloc                                       ;; eax holds the address of the link created
    create_link_for_zero                             
    jmp input_Again
even:
    mov ecx, edx
    mov edx, 0
    num_or_letter bh                                  ;; put correct value in bh
    shl bh, 4                                         ;; multipate by 16
    inc ecx                                           ;; pointer to the right bit of the 2 chars
    num_or_letter dl                                  ;; put correct value in dl
    add bh, dl                                        ;; add the 2 numbers into bh
    create_first_link                                
    inc ecx
add_linkedList:
    cmp byte [buffer + ecx], 0xA                      ;; condition for stopping = char is '/n'
    je input_Again
    num_or_letter bh                                 
    shl bh, 4
    inc ecx
    num_or_letter dl
    add bh, dl
    create_to_linkList                                ;; adding a new link to the linked list
    inc ecx
    jmp add_linkedList
