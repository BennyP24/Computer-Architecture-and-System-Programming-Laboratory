	global printer
	global target
	global schedular
	global CORS
	global SPMAIN
	global CURR
	global resume
	global random
	global float_convert
	global seed
	global N
	global K
	global T
	global B
	global d
	global MAXINT
	global HUN
	global angle_limit
	global endCo
	global free_drones

section .data
	
	printer:	dd printer_func			;; struct of printer co-routine
		    	dd STK1 + STKSZ
	target:		dd target_func			;; struct of target co-routine
		    	dd STK2 + STKSZ
				dt 0.0					;; x
				dt 0.0					;; y
	schedular:  dd schedular_func		;; struct of schedular co-routine
		    	dd STK3 + STKSZ
	CORS : 		dd 0 					;; array for the drones


	N: dd 0					;; Number of drones
	T: dd 0					;; Number of targets need to destroy in order to win the game
	K: dd 0					;; How many drones steps between game board winnings 
	B: dd 0					;; angle of drones field of view
	d: dd 0					;; Maximum distance that allows to destroy a target
	seed: dd 0				;; seed for initalization of LSFR shift register
	MAXINT: dd 65535		;; size of the max integer for the random
	HUN: dd 100
	angle_limit: dd 360
	drones_max: dd 0
	stack_helper: dd 0

section .rodata

	format_dec_num: db "%d" , 0				;; format for printing decimal numbers
	format_float_num: db "%f" , 0			;; format for printing floating numbers

section .bss
	
	CURR: resd 1			;; current co-routine struct
	SPT: resd 1				;; temporary stack pointer
	SPMAIN: resd 1			;; stack pointer of main
	STKSZ equ 16*1024		;; co-routine stack size
	CODEP equ 0				;; offset of pointer to co-routine function in co-routine struct
	SPP equ 4				;; offset of pointer to co-routine stack in co-routine struct
	idOffset equ 8			;; offset of id to co-routines drones
	xOffset equ 12			;; offset of x to co-routines drones
	yOffset equ 22			;; offset of y to co-routines drones
	angleOffset equ 32		;; offset of beta (angle) to co-routines drones
	scoreOffset equ 42		;; offset of co-routines score counter
	nextDrone equ 46		;; offset to next drone in CORS		
	STK1: resb STKSZ
	STK2: resb STKSZ
	STK3: resb STKSZ

section .text

align 16

	global main
	extern printf
	extern free
	extern calloc
	extern malloc
	extern sscanf
	extern schedular_func
	extern printer_func
	extern target_func
	extern drone_func
	extern conver_degree_to_radian


										;;;;;;;;;;;;;;;;;;;;;;;;;; macros ;;;;;;;;;;;;;;;;;;;;;;;;;

%macro startFunc 0				;; macro for beginning of a function
	
	push ebp
	mov ebp, esp

%endmacro

%macro endFunc 0				;;  macro for ending of a functionmov si, word [seed]

	mov esp, ebp
	pop ebp

%endmacro

%macro random_generator 1		;; macro for generating co-routines x or y points

	pushad
	push dword [seed]
	call random
	mov dword [seed], eax				;; seed is now updated with the next randomly number
	add esp, 4		
	popad			
	push dword [seed]
	call float_convert					;; call float_convert function to make the random number float
	fstp %1								;; insert to co-routines x or y the random floating point number		
	ffree
	add esp, 4
	

%endmacro

%macro random_generator_angle 1		;; macro for generating co-routines angle point

	pushad
	push dword [seed]
	call random
	mov dword [seed], eax				;; seed is now updated with the next randomly number
	add esp, 4		
	popad			
	push dword [seed]
	call float_convert_angle			;; call float_convert function to make the random number float
	fstp %1								;; insert to co-routines angle the random floating point number	
	
	ffree
	add esp, 4

%endmacro


%macro func_start_ret_val 0
    push ebp
    mov ebp, esp
    sub esp,4
    pushad
	pushfd
%endmacro
    
%macro func_end_ret_val 0
	popfd
	popad
	mov eax,[ebp-4]
	add esp,4
	mov esp, ebp	
	pop ebp
	ret
%endmacro


%macro sscanf_func_dec 2		;; macro for getting decimal inputs
	pushad
	pushfd

	push %1 						;; enter the args to the global veriable
	push format_dec_num
	push %2 						;; enter the args 
	call sscanf
	add esp ,12

	popfd
	popad
%endmacro


%macro sscanf_func_float 2		;; macro for getting float inputs
	pushad
	pushfd

	push %1 						;; enter the args to the global veriable
	push format_float_num
	push %2 						;; enter the args 
	call sscanf
	add esp ,12

	popfd
	popad
%endmacro

%macro initCoStatic 1			;; macro for initialization co-routines
	
	mov esi, %1
	mov eax, [esi + CODEP] 			;; get initial EIP value – pointer to COi function
	mov [SPT], esp 					;; save ESP value
	mov esp, [esi + SPP] 			;; get initial ESP value – pointer to COi stack
	push eax 						;; push initial “return” address
	pushfd 							;; push flags
	pushad 							;; push all other registers
	mov [esi + SPP], esp 			;; save new SPi value (after all the pushes)
	mov esp, [SPT] 					;; restore ESP value

%endmacro


										;;;;;;;;;;;;;;;;;;;;;;;;;; end of macros ;;;;;;;;;;;;;;;;;;;;;;;;

main:
	startFunc
	pushad
	pushfd
	mov ebx, dword [ebp + 12]				;;ebx now holds the address of argv
	sscanf_func_dec N , dword [ebx+4]  	    ;; insert the number of drones
	sscanf_func_dec T , dword [ebx+8]		;; insert the number of targets
	sscanf_func_dec K , dword [ebx+12]	    ;; insert steps between printing
	sscanf_func_dec B , dword [ebx+16]		;; insert angle of drones
	sscanf_func_dec d , dword [ebx+20]		;; insert Maximum distance
	sscanf_func_dec seed, dword [ebx+24]	;; insert seed

	loop_initCo:
		initCoStatic printer				;; initialize the printer struct
		initCoStatic target					;; initialize the target struct
		pushad
		push dword [seed]
		call random
		mov dword [seed], eax				;; seed is now updated with the next randomly number
		add esp, 4		
		popad			
		push dword [seed]
		call float_convert					;; call float_convert function to make the random number float
		fstp tword [target + 8]				;; insert to targets x the random floating point number		
		ffree
		add esp, 4
		pushad
		push dword [seed]
		call random
		mov dword [seed], eax				;; seed is now updated with the next randomly number
		add esp, 4
		popad
		push dword [seed]
		call float_convert
		fstp tword [target + 18]			;; insert to targets y the random floating point number
		ffree
		add esp, 4
		initCoStatic schedular				;; initialize the schedular struct
	init_drones:
		mov eax, 0
		mov edx, 0
		mov ecx, 0
		mov eax, 46							;; eax holds 46 for 46 bytes(drone struct)
		mov ecx, dword [N]					;; ecx holds the number of drones in program
		mul ecx								;; eax now holds the answer for this multification	
		pushad
		push eax
		call malloc
		mov dword [CORS], eax				;; cors now points to the address of the new allocated memory space for drones
		add esp, 4
		popad
		pushad				
		call initCoDynamic					;; calling initCoDynamic for initializing the drones
		popad
	startCo:
		pushad
		pushfd								;; restore registers of main()
		mov [SPMAIN], esp					;; save ass3.s main esp value
		mov ebx, schedular					;; ebx points to schedular struct	
		jmp do_resume
		endFunc

	resume:
		pushfd
		pushad
		mov edx, [CURR]						;; edx points to the current co-routine
		mov [edx + SPP], esp				;; save current esp 
	do_resume:
		mov esp, [ebx + SPP]				;; esp now points to the next co-routines stack
		mov [CURR], ebx						;; CURR holds the next co-routines sruct
		popad 								;; restore resumed co-routine state
		popfd		
		ret 								;; "return" to resumed co-routine function

	
	endCo:
		mov esp, [SPMAIN] 					;; restore esp of main()	
		;call free_drones		
		popfd								;; restore registers of main()
		popad 						
		endFunc
		ret


initCoDynamic:						;;;;;;;;;;;;;;;; function for initialization of dynamic co-routines structs ;;;;;;;;;;;;;;;;

	startFunc
	mov eax, 0
	mov edx, 0
	mov ecx, 0
	mov esi, 0
	mov eax, 46												;; eax holds 46 for 46 bytes(drone struct)
	mov ecx, dword [N]										;; ecx holds the number of drones in program
	mul ecx													;; eax now holds the answer for this multification ( size of drones memory array) for the loop 
	mov dword [drones_max], eax
	mov ecx, 0
	mov ebx, dword [CORS]									;; ebx holds the drones memory array address

	initCoDynamic_loop:

		mov eax, 46
		mul ecx													;; eax holds the offset to the nextdrone
		xor edx, edx											;; reset edx ( = 0 )
		mov edx, drone_func										
		mov dword [ebx + CODEP + eax ], edx						;; get initial EIP value – pointer to COi function
		mov dword [stack_helper], eax
		pushad
		push STKSZ
		call malloc
		add esp, 4
		mov ecx, dword [stack_helper]
		add eax , STKSZ
		mov dword [ebx + SPP + ecx], eax						;; initialize current drones stack (eax = new stack allocated)
		popad
		mov edi, dword [ebx + SPP + eax]
		mov [SPT], esp 											;; save current co-routines ESP value
		mov esp, edi 											;; get initial ESP value – pointer to COi stack
		push edx 												;; push initial “return” address
		pushfd 													;; push flags
		pushad 													;; push all other registers
		mov dword [ebx + SPP + eax], esp 						;; save new SPi value (after all the pushes)
		mov esp, [SPT] 											;; restore ESP value
		inc ecx
		mov dword [ebx + idOffset + eax], ecx 					;; get drone id
		dec ecx
		random_generator tword[ebx + xOffset + eax]				;; drones x gets its float randomized value
		random_generator tword[ebx + yOffset + eax]				;; drones y gets its float randomized value
		random_generator_angle tword[ebx + angleOffset + eax]	;; drones angle gets its float randomized value
		mov dword[ebx +scoreOffset +eax] , 0
		add esi, nextDrone 										;; increment esi to deal with next drone ( + 46)
		inc ecx													;; increment the id counter
		cmp esi, dword [drones_max]								;; stop condition for loop (in beginning esi == 0)
		jnz initCoDynamic_loop

		end_initcoDynamic_loop:
			endFunc
			ret


random:			 			;;;; function for randomzing number (int seed as argument)

	startFunc
	mov edx, 0
	mov ecx, 0
	mov eax, 0
	mov ebx, 0
	mov dx, 16
	mov si, [ebp + 8]					;; si holds the seed number
	random_loop:

		mov bx, si						;; bx holds the seed initial number
		and bx, 1						;; bx now points to the 16th bit
		mov cx, si						;; cx holds the seed initial number
		shr cx, 2						;; msb now is the 14th bit
		and cx, 1						;; cx now points to the 14th bit
		xor bx, cx						;; bx holds the xor result of the 16th bit and the 14th bit
		mov cx, si						;; cx holds the seed
		shr cx, 3						;; msb is the 13th bit
		and cx, 1						;; cx noe points to the 13th bit
		xor bx, cx						;; bx holds the xor result of the 13th 14th and 16th bits
		mov cx, si						;; cx hodls the seed initial number
		shr cx, 5						;; msb is the 11th bit
		and cx, 1						;; cx now points to the 11th bit
		xor bx, cx						;; bx holds the xor result of the 11th 3th 14th and 16th bits
		mov cx, si						;; cx hodls the seed
		shr cx, 1						;; cx now holds the seed initial number/2
		shl bx, 15						;; bx now has the xor result as the 16th bit
		add bx, cx						;; bx now holds the new randomly number
		mov si, bx						
		dec dx							;; decrement dx
		cmp dx, 0
		jne random_loop
		mov ax, si						;; ax holds the result of resume function
		endFunc
		ret

float_convert:				;;;; function for x or y converting decimal to float (int randomly number as argument)

	startFunc
	finit								;; initialize the floating point stack
	fild dword [ebp + 8]				;; load the seed random number to the floating point stack
	fidiv dword [MAXINT]				;; divide the seed number by 65535 (MAXINT) and store the result in st(0)
	fimul dword [HUN]					;; multiplicate the result by 100 and store the result in st(0)
	endFunc
	ret							

float_convert_angle:		;;;; function for alpha converting decimal to float (int randomly number as argument)

	startFunc
	finit								;; initialize the floating point stack
	fild dword [ebp + 8]				;; load the seed random number to the floating point stack
	fidiv dword [MAXINT]				;; divide the seed number by 65535 (MAXINT) and store the result in st(0)
	fimul dword [angle_limit]			;; multiplicate the result by 360 and store the result in st(0)
	endFunc
	ret								

free_drones:				;;;; function for freeing the allocated memory space

	startFunc
	mov ecx, 1
	mov eax, 0
	mov eax, nextDrone
	mov ebx, dword [CORS]				;; ebx points to the beginning of the drones array

	free_drones_loop:
		mul ecx							;; eax holds the offset to the next drone
		pushad
		push dword [ebx + eax + SPP]
		call free
		add esp ,4
		popad
		inc ecx							;; increment ecx
		cmp ecx, dword [N]				;; compare if we went through all of the drones
		jne free_drones_loop
		push dword [CORS]				;; pushing drones array for free function
		call free
		add esp, 4
		endFunc
		ret	
						
