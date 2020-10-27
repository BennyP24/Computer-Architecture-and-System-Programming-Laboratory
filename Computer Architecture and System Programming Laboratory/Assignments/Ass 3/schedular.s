global CURR
section .data

	counter_print_steps: dd 0 	;; counter to know how many steps acurred in the game

section .rodata

section .bss

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
	global schedular_func
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


							;;;;;;;;;;;;;;;;;;;; end of macros ;;;;;;;;;;;;;;;;;


schedular_func:
	startFunc
	pushad
	pushfd
	round_robin:
		mov ecx, 0
		mov eax, 0
		round_robin_loop:
			cmp ecx, dword [N] 											;; check if reached to last drone = the last drone
			je round_robin
			mov esi, dword [counter_print_steps]						
			cmp esi, dword [K]											;; check if we did k steps, if so do_resume printer
			je go_printer_go
			mov eax, nextDrone
			mul ecx														;; eax has the result (offset to the next drone struct)
			mov ebx, dword [CORS] 										;; ebx points to the drones array struct
			add ebx, eax 												;; ebx points to the next drone struct
			call resume
			add dword [counter_print_steps], 1							
			inc ecx														;; increment ecx
			jmp round_robin_loop
		go_printer_go:
			mov ebx , printer											;; ebx points to the printer struct
			call resume
			mov dword [counter_print_steps], 0							;; reset round_robin_loop stop condition
			jmp round_robin_loop
	popfd
	popad
	endFunc


