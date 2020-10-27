global may_destroy

section .data

gamma: dt 0.0
result_gamma_alpha: dt 0.0
flag_angle: dd 0
flag_coordinates: dd 0
result_tmpY: dt 0.0
result_tmpX: dt 0.0
tmp_final_result_coordinates: dt 0.0
new_beta: dt 0.0
radian_180: dd 180
compare_alpha: dd 0

section .rodata
	format_float:db "%0.2f" ,0
	format_comma:db ",", 0
	format_new_line: db "", 10, 0
	format_integer: db "%d", 0
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
	global target_func
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
	extern B
	extern d
	extern seed
	extern random
	extern float_convert
	extern convert_degree_to_radian
	extern convert_radian_to_degree


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


target_func:

	startFunc
	push dword [seed]
	call random
	mov dword [seed], eax					;; seed is now updated with the next randomly number
	add esp, 4
	push dword [seed]
	call float_convert						;; call float_convert function to make the random number float
	fstp tword [target + 8]					;; insert to targets x the random floating point number		
	ffree
	add esp, 4
	pushad
	push dword [seed]
	call random
	mov dword [seed], eax					;; seed is now updated with the next randomly number
	add esp, 4
	popad
	push dword [seed]
	call float_convert
	fstp tword [target + 18]				;; insert to targets y the random floating point number
	ffree
	add esp, 4
	mov ebx, schedular						;; ebx now points to schedular struct
	call resume
	jmp target_func
	endFunc

may_destroy:

	startFunc
	mov ebx, dword [CURR]
	mov dword [flag_angle], 0				;; reset the flags
	mov dword [flag_coordinates], 0			;; reset the flags

	call caculate_gamma					 
	call check_angle 						;; check (abs(alpha-gamma) < beta) , if so changes flag_angle to 1
	call check_coordinates

	mov eax ,dword [flag_angle]
	mov ebx ,dword [flag_coordinates]
	and eax , ebx							;; if the terms apply eax will hold 1 else 0 
	endFunc
	ret

caculate_gamma:			;;; function for calulating gamma -> arctan((y2-y1)/(x2-x1))

	startFunc
	finit



	fld tword [ebx + yOffset]				;; st(1) = y1 = drone y	-> st(2) = x2-x1
	fld tword [target + 18]					;; st(0) = y2 = target y   
	fsubp									;; st(0)-st(1) = y2-y1 , save the result in st(1) = y2-y1 and pop st(0)

	fld tword [ebx + xOffset]  				;; st(1) = x1 = drone x	
	fld tword [target + 8]					;; st(0) = x2 = target x
	fsubp									;; st(0)-st(1) , save the result in st(1) = x2-x1 and pop st(0)

	;; the stack contain st(0) = x2-x1 , st(1) = y2-y1

	fpatan 								;;Replace ST(1) with arctan(ST(1)/ST(0)) and pop the register stack.
	fstp tword [gamma]
	;fld tword [gamma]
	;fldpi
	;fmulp
	;fidiv dword [radian_180]
	;fstp tword [gamma]
	ffree
	endFunc
	ret

check_angle: 			;;; function for checking (abs(alpha-gamma) < beta) , if so changes flag_angle to 1 

	startFunc
	finit
	fld tword [gamma]						;; upload gamma st(1)
	fld tword [ebx + angleOffset]			;; upload alpha st(0)
	fcomi
	jb gamma_check_angle
	mov dword [compare_alpha], 0
	jmp next_check_angle
	gamma_check_angle:
		mov dword [compare_alpha], 1
	next_check_angle:
		fsubp 									;; st(0)-st(1) = alpha-gamma , save the result in st(1)= alpha-gamma and pop st(0)
		fabs									;; return the top of the stack to absulte value ||
	
		;; compare angle and pie
	
		fldpi									;; st(0) = pi
		fcomip									;; check if pi is greater than angle
		ja check_beta
		fstp tword [result_gamma_alpha]			;; holds abs(alpha-gamma)
		ffree
		finit
		fldpi
		fldpi
		faddp									;; st(0) = 2*pi
		cmp dword [compare_alpha], 1
		jne add_alpha_pie
		fld tword [gamma]
		faddp									;; st(0) = gamma + pi
		fstp tword [gamma]
		jmp before_check_beta
		add_alpha_pie:
			fld tword [ebx + angleOffset]
			faddp								;; st(0) = alpha + pi
			fstp tword [ebx + angleOffset]	
				before_check_beta:
					fld tword [gamma]
					fld tword [ebx + angleOffset]
					fsubp
					fabs
	
					check_beta:
						fstp tword [result_gamma_alpha]
						ffree
						call convert_beta_radian
						finit	
						fld tword [result_gamma_alpha]
						fld tword [new_beta] 					;; upload beta as radian to st(1)
						fcomip 									;; compare abs(alpha-gamma) between beta -> compare (st(0) < st(1))
						fstp tword [result_gamma_alpha]			;; just to clear st(0)
						ja change_flag_angle					;; if abs(alpha-gamma)<beta
						jmp end_check_angle						;; any other case dont change the flag 

							change_flag_angle:

								mov dword [flag_angle] , 1			;; the term abs(alpha-gamma)<beta is true
								
							end_check_angle:
								ffree
								endFunc
								ret

check_coordinates: 		;;; check sqrt((y2-y1)^2+(x2-x1)^2) < d , if so changes flag_coordinates

	startFunc
	finit

	fld tword [target + 18]					;; st(0) = y2 = target y 
	fld tword [ebx + yOffset]				;; st(1) = y1 = drone y
	fsubp									;; st(1)-st(0)=y2-y1 , save the result in st(1)= y2-y1 and pop st(0)
	fstp tword [result_tmpY]				;; store y2-y1
	fld tword [result_tmpY]
	fld tword [result_tmpY]
	fmulp									;; st(0) = y2-y1 ^2
	fstp tword [result_tmpY]				;; holds now (y2-y1) ^2

	;; stack x87 needs to be empty
		
	
	fld tword [target + 8]					;; st(0) = x2 = target x
	fld tword [ebx + xOffset]  				;; st(1) = x1 = drone x
	fsubp									;; st(1)-st(0), save the result in st(1) = x2-x1 and pop st(0)
	fstp tword [result_tmpX]				;; store x2-x1
	fld tword [result_tmpX]	
	fld tword [result_tmpX]
	fmulp									;; st(0) = (x2-x1)^2
	fstp tword [result_tmpX]				;; holds now x2-x1^2
		
	;; stack x87 needs to be empty
		
	fld tword [result_tmpX]
	fld tword [result_tmpY]
	faddp
	fsqrt										;; st(0) = ((y2-y1)^2) + ((x2-x1)^2)
	fstp tword [tmp_final_result_coordinates] 	;; now holds sqrt(((y2-y1)^2) + ((x2-x1)^2))
	
	;; stack x87 needs to be empty
		
	fild dword [d]								;; upload the maximum detection diatance - d from the start st(1)
	fld tword [tmp_final_result_coordinates] 	;; upload sqrt((y2-y1)^2+(x2-x1)^2) in st(0)
	fcomip										;; compare sqrt((y2-y1)^2+(x2-x1)^2) < d -> compare st(0) < st(1)
	jb change_flag_coordinates
	jmp end_check_coordinates

		change_flag_coordinates:

			mov dword [flag_coordinates] , 1	;; the term sqrt((y2-y1)^2+(x2-x1)^2) < d is true

		end_check_coordinates:
			ffree
			endFunc
			ret

convert_beta_radian:
	startFunc
	finit
	fild dword [B]						;; load B
	fldpi 								;; load pi
	fmulp								;; st(0) = B*pie
	fidiv dword [radian_180]			;; st(0) = (B*pie/180) -> st(0) = B in radian
	fstp tword [new_beta]				;; B is now saved as radian and not degree
	ffree
	endFunc
	ret