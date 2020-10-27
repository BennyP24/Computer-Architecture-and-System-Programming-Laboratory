extern may_destroy
extern endCo  
global convert_degree_to_radian
global convert_radian_to_degree

section .data

	angle_scale: dd 120
	distance_scale: dd 50
	sixty: dd 60
	radian_180: dd 180
	new_a: dt 0.0
	distance: dt 0.0
	zero: dt 0.0
	sin_alpha: dt 0.0

section .rodata
	
	format_float:db "%0.2f" ,0
	format_comma:db ",", 0
	format_new_line: db "", 10, 0
	format_integer: db "%d", 0

	winner_format : db "drone id <%d>: I am a winner" ,10, 0

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
	global drone_func
	extern resume
	extern printf
	extern free
	extern malloc
	extern sscanf
	extern printer
	extern target
	extern schedular
	extern random
	extern CORS
	extern SPMAIN
	extern CURR
	extern seed
	extern N
	extern K
	extern T
	extern MAXINT
	extern HUN
	extern angle_limit
	extern free_drones
	

						;;;;;;;;;;;;;;;;;;;;; macros ;;;;;;;;;;;;;;;;;;;;;;;

%macro startFunc 0				;; macro for beginning of a function
	
	push ebp
	mov ebp, esp

%endmacro						;; result holds the random number between 0-100


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

drone_func:
	startFunc
	;; calculate new alpha

	push dword [seed]
	call random
	add esp ,4
	mov dword [seed], eax
	push eax
	call scale_a						;; need to send to scale in degrees - do helper func to convert to deg from radians
	add esp ,4
	fstp tword [new_a]					;; new_a = new alpha
	ffree

	;; old a + new a = updated a
	mov ebx, dword [CURR]

	finit
	fld tword [ebx + angleOffset] 		;; load old alpha 
	fld tword [new_a]					;; load new alpha
	faddp								;; add old with new -> st(0) = old alpha + new alpha					
	fstp tword [ebx + angleOffset] 		;; update alpha in the drone
	ffree

	pushad
	call check_limit_angle
	popad

	;; random d and check if(0 < d < 50)

	push dword [seed]
	call random
	add esp ,4
	mov dword [seed], eax				
	push eax
	call float_convert_distance
	add esp ,4
	fstp tword [distance]				;; got distance in float
	ffree

	;; converting drone alpha to radian

	mov ebx, dword [CURR]
	call convert_degree_to_radian

	;; change drones x and y to new location

	finit
	fld tword [ebx + angleOffset] 		;; upload the drones alpha into x87 stack
	fsincos 							;; put cos in the top f the stack and sin second
	fld tword [distance]
	fmulp   							;; cos*d = in the top f the stack theres new x
	fld tword [ebx + xOffset]
	faddp 								;; new x + old x = updated x in the top of the stack
	fstp tword [ebx + xOffset] 			;; insert the uptated x : st(0) -> drones.x
	fstp tword [sin_alpha]				;; st(0) = sinAlpha -> sin_alpha
	ffree

	call check_limit_X

	fld tword [sin_alpha]				;; st(1) = sin_alpha
	fld tword [distance] 				;; st(0) = distance
	fmulp 								;; now the sin*d is in the top of the stack. d*sin = new y
	fld tword [ebx + yOffset]			;; st(0) = drones Y
	faddp 								;; new y + old y = updated y in the top of the stack
	fstp tword [ebx + yOffset]
	ffree
	call check_limit_Y

	;; calling mayDestroy

	call may_destroy					;; calling may_destroy function -> eax will have the answer (1->yes || 0->no)
	
	;; converting the radian alpha to degree

	mov ebx, dword [CURR]
	call convert_radian_to_degree
	cmp eax, 1									;; check if target is destroyed
	jne end_drones_func
	add dword [ebx + scoreOffset], 1			;; increment the drones score counter
	mov esi, dword [T]
	cmp dword [ebx + scoreOffset], esi			;; check if current drone is the winner
	jb resume_target

	;; in this case we found a winner so we will print and quit from main

	push dword [ebx + idOffset]
	push winner_format
	call printf
	add esp, 8
	call endCo

	resume_target:

		mov ebx, target
		call resume							;; call resume with target for creating a new target
		jmp drone_func

	end_drones_func:

		mov ebx, schedular
		call resume							;; call resume to get back to schedular co-routine
		jmp drone_func
		endFunc

scale_a:					;;; make sure the int num is in scale of [-60,60] and is float num

	startFunc
	finit								;; initialize the floating point stack
	fild dword [ebp + 8]				;; load the seed random number to the floating point stack
	fidiv dword [MAXINT]				;; divide the seed number by 65535 (MAXINT) and store the result in st(0)
	fimul dword [angle_scale]			;; multiplicate the result by 120 and store the result in st(0)
	fisub dword [sixty]					;; sub 60 in order to get [-60,60]
	endFunc
	ret			

float_convert_distance:		;;; make sure the int num is in scale of [0,50] and is float num

	startFunc
	finit								;; initialize the floating point stack
	fild dword [ebp + 8]				;; load the seed random number to the floating point stack
	fidiv dword [MAXINT]				;; divide the seed number by 65535 (MAXINT) and store the result in st(0)
	fimul dword [distance_scale]		;; multiplicate the result by 50 and store the result in st(0)

	endFunc
	ret			

check_limit_angle:

	startFunc
	finit
	fild dword [angle_limit]			;; push 360 to st(1)
	fld tword [ebx + angleOffset] 		;; take the drones angle to st(0)
	fcomi 								;; compare 360 with the angle 
	ja sub_angle						;; if the angle is above 360 -> st(0)>360
	je end_check_limit_angle			;; in case the angle is equal to 360  st(0)=360
	fstp st1							;; clean st0
	fstp st0							;; clean st1

	;;in case the angle is beneath 360 st(0) < 360
	
	fld tword [zero]					;; insert st(1) = 0 -> check if not beneath 0
	fld tword [ebx + angleOffset] 		;; take the angle to st(0)
	fcomi 								;; compare 0 with angle st(0) < st(1)
	jb add_angle
	jmp end_check_limit_angle			;; if equal

	add_angle:				;;; if the angle is smaller than 0 -> st(0) < 0

		fstp st1 							;; clean st0 from the angle
		fstp st0							;; clean st1 from 0
		fld tword [ebx + angleOffset]		;; st(1)
		fild dword [angle_limit]			;; put 360 into st0	
		faddp 								;; Add ST(0) = (360) with ST(1) = (angle), store result in ST(1), and pop the register stack(360).
		fstp tword [ebx + angleOffset]		;;insert the new value after the add in to the angle
		jmp end_check_limit_angle

	sub_angle: 				;;; if the angle is above 360 -> st(0)>360

		fsubp								;; Subtract ST(0) from ST(1), store result in ST(1), and pop register stack -> st(0) = 360- angle 
		fabs								;; return the top of the stack to absulte value ||
		fstp tword [ebx + angleOffset]		;; insert the new value 

	end_check_limit_angle:

		ffree
		endFunc
		ret



check_limit_X:

	startFunc
	finit
	fild dword [HUN]					;; push 100 st(1)
	fld tword [ebx + xOffset] 			;; take the x st(0)
	fcomi 								;; compare 100 with x st(0) vrs st(1)
	ja sub_X							;; if x is above 100 -> st(0)>st(1)
	je end_check_limit_X				;; in case the x is equal to 100
	fstp st1							;; clean st0 in case the x is beneth 100
	fstp st0
	fld tword [zero]					;; insert st1 0
	fld tword [ebx + xOffset] 			;; take the x st(0)
	fcomi 								;; compare 0 with x st(1) 
	jb add_X							;; st(0)<st(1)
	jmp end_check_limit_X				;; if equal x =0

	add_X:

		fstp st1 							;; clean st0 from x
		fstp st0							;; clean st0 from 100
		fld tword [ebx + xOffset] 			;; take the x st(1)
		fild dword [HUN]					;; put 100 into st0	
		faddp 								;; Add ST(0)(100) to ST(1)(x), store result in ST(1)(x), and pop the register stack(100).
		fstp tword [ebx + xOffset]			;; insert the new value after the add in to the x
		jmp end_check_limit_X

	sub_X:

		fsubp								;; Subtract ST(0)(x) from ST(1)(100), store result in ST(1) = 100-x, and pop register stack.
		fabs								;; return the top of the stack to absulte value ||
		fstp tword [ebx + xOffset]			;; insert the new value 

	end_check_limit_X:

		ffree
		endFunc
		ret



check_limit_Y:

	startFunc
	finit
	fild dword [HUN]					;; push 100 st(1)
	fld tword [ebx + yOffset] 			;; take the y st(0)
	fcomi 								;; compare 100 with y st(0) vrs st(1)
	ja sub_Y							;; if y is above 100	st(0)>st(1)
	je end_check_limit_Y				;; in case the y is equal to 100
	fstp st1							;; clean st0 
	fstp st0							;; clean st1
	fld tword [zero]					;; insert st1 0
	fld tword [ebx + yOffset] 			;; take the y st(0)
	fcomi 								;; compare 0 with y st(1) 
	jb add_Y							;; st(0)<st(1)  y<0
	jmp end_check_limit_Y				;; if equal y=0

	add_Y:

		fstp st1 							;; clean st0 from y
		fstp st0							;; clean st0 from 100
		fld tword [ebx + yOffset] 			;; take the y st(1)
		fild dword [HUN]					;; put 100 into st0	
		faddp 								;; Add ST(0)(100) to ST(1)(x), store result in ST(1)(x), and pop the register stack(100).
		fstp tword [ebx + yOffset]			;; insert the new value after the add in to the x
		jmp end_check_limit_Y

	sub_Y:

		fsubp								;; Subtract ST(0)(y) from ST(1)(100), store result in ST(1) = 100-y, and pop register stack.
		fabs								;; return the top of the stack to absulte value ||
		fstp tword [ebx + yOffset]			;; insert the new value 

	end_check_limit_Y:

		ffree
		endFunc
		ret

convert_degree_to_radian:			;; function for converting degree to radian

	startFunc
	finit
	fld tword [ebx + angleOffset]		;; load drone alpha
	fldpi 								;; load pi
	fmulp								;; st(0) = alpha*pie
	fidiv dword [radian_180]			;; st(0) = (alpha*pie/180) -> st(0) = alpha in radian
	fstp tword [ebx + angleOffset]		;; drones alpha is now saved as radian and not degree
	ffree
	endFunc
	ret

convert_radian_to_degree:			;; function for converting radian to degree

	startFunc
	finit
	fldpi								;; st(1) = pi
	fld tword [ebx + angleOffset]		;; load drones alpha
	fimul dword [radian_180]			;; st(0) = alpha*180
	fdiv								;; st(0) = alpha*180/pi -> st(0) = alpha in degree
	fstp tword [ebx + angleOffset]		;; drones alpha is now saved as degree and not radian
	ffree
	endFunc
	ret