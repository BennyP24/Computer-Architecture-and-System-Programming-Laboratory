section .data

section .rodata

	format_float:db "%0.2f" ,0
	format_comma:db ",", 0
	format_new_line: db "", 10, 0
	format_integer: db "%d", 0

section .bss

	fResult: rest 1
	STKSZ equ 16*1024			;; co-routine stack size
	CODEP equ 0					;; offset of pointer to co-routine function in co-routine struct
	SPP equ 4					;; offset of pointer to co-routine stack in co-routine struct
	idOffset equ 8				;; offset of id to co-routines drones
	xOffset equ 12				;; offset of x to co-routines drones
	yOffset equ 22				;; offset of y to co-routines drones
	angleOffset equ 32			;; offset of beta (angle) to co-routines drones
	scoreOffset equ 42			;; offset of co-routines score counter
	nextDrone equ 46			;; offset to next drone in CORS

section .text

align 16
	global printer_func
	extern resume
	extern printf
	extern free
	extern malloc
	extern sscanf
	extern printer
	extern target
	extern schedular
	extern CORS
	extern SPMAIN
	extern CURR
	extern N
	extern K
	extern T	

						;;;;;;;;;;;;;;;;;;;;; macros ;;;;;;;;;;;;;;;;;;;;;;;

%macro startFunc 0				;; macro for beginning of a function
	
	push ebp
	mov ebp, esp

%endmacro						


%macro endFunc 0				;;  macro for ending of a function

	mov esp, ebp
	pop ebp

%endmacro	

%macro print_float 0			;; macro for printing tword floating numbers 
	
	push format_float
	call printf
	add esp, 12

%endmacro

%macro print_comma 0			;; macro for printing ','
	
	push format_comma
	call printf
	add esp, 4

%endmacro

%macro print_integer 1			;; macro for printing decimal values
	
	push	 %1
	push format_integer
	call printf
	add esp, 8

%endmacro

%macro print_new_line 0			;; macro for going to a new line
	
	push format_new_line
	call printf
	add esp, 4

%endmacro


						;;;;;;;;;;;;;;;;;;;; end of macros ;;;;;;;;;;;;;;;;;

printer_func:
	startFunc
	pushfd
	pushad
	
	;;; printing targets cordinates

	finit
	fld tword [target + 8]							;; float stack ( st(0) ) holds the x value
	sub esp, 8										;; creating space in stack for printing the float number
	fstp qword [esp]
	print_float 
	print_comma
	fld tword [target + 18]							;; float stack ( st(0) ) holds the y value
	sub esp, 8										;; creating space in stack for printing the float number
	fstp qword [esp]
	print_float 
	print_new_line					

	;;; printing drones data

	mov eax, 0
	mov ecx, 0
	mov edx, 0
	mov ebx, dword [CORS]							;; ebx points to the beginning of the CORS (first co-routine struct)
	print_drones:
		cmp edx, dword [N]								;; check if we printed all of the drones contents
		je end_print
		mov ecx, dword [ebx + eax + idOffset]			;; ecx holds the id of the current co-routine
		pushad
		print_integer ecx
		print_comma
		popad
		fld tword [ebx + eax + xOffset]					;; loading the x value of the current co-routine
		pushad
		sub esp, 8										;; creating space in stack for printing the float number
		fstp qword [esp]
		print_float 
		print_comma
		popad


		fld tword [ebx + eax + yOffset]					;; loading the y value of the current co-routine
		pushad
		sub esp, 8										;; creating space in stack for printing the float number
		fstp qword [esp]
		print_float 
		print_comma
		popad
		fld tword [ebx + eax + angleOffset]				;; loading the angle value of the current co-routine
		pushad
		sub esp, 8										;; creating space in stack for printing the float number
		fstp qword [esp]
		print_float
		print_comma
		popad
		pushad
		mov ecx ,dword [ebx + eax + scoreOffset]
		print_integer dword [ebx + eax + scoreOffset]	;; printing the score counter for the current co-routine
		print_new_line
		popad
		add eax, nextDrone								;; eax holds the offset to the next drone 
		inc edx											;; increment edx
		jmp print_drones

	end_print:
		popad
		popfd
		ffree
		mov ebx, schedular
		call resume
		jmp printer_func
		endFunc
