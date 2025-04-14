%macro createFile 0	;makes file from const char* in rdi
	mov rax, 2
	mov rsi, 64
	mov rdx, 0o644
	syscall		;creates file from path

	mov rdx, rax	;stores rax

	cmp rax, 0xffff_ffff_ffff_efff
	jg _fileErr

	mov rsi, [perms]
	mov rax, 90
	syscall		;sets perms

	mov rax, rdx	;restores rdx

	mov rdi, rax
	mov rax, 3
	syscall		;closes the file
%endmacro

%macro checkOctal 1	;checks if char at offset is valid octal, if it is, shifts into rdx
	mov al, [rdi + %1]
	cmp al, 0x30
	jl _optErr
	cmp al, 0x37
	jg _optErr	;checks if char at offset is valid octal
	
	shl rdx, 3
	sub al, 0x30
	or dl, al	;adds val to dl
%endmacro

%macro parseOptions 0	;parses command line args
%%parseNext:
	mov rdi, [rsp]	;gets the val of the first non path arg
	mov al, [rdi]	;sets al to the first byte of the possible options arg
	
	cmp al, '-'	
	jne %%endParse ;stops parsing if normal arg

	pop rdi
	dec rbx		;updates arg counter
	
	mov al, [rdi + 1]
			;sets al to the next byte of the options
	
	cmp al, 'h'
	je %%helpmsg	;prints help if -h

	cmp al, 'v'
	je %%version	;prints version if -v

	cmp al, 'i'
	je %%ignore	;stops parsing if -i

	checkOctal 1
	checkOctal 2
	checkOctal 3	;checks if all octal vals are valid

	mov al, [rdi + 4]
	cmp al, 0
	jne _optErr	;errors if anything after -OOO

	mov [perms], rdx;sets perms to rdx

	jmp %%parseNext	;parses next arg

%%version:		;prints the version num
	mov al, [rdi + 2]
	cmp al, 0
	jne _optErr	;errors if anything after -v

	mov rax, 1
	mov rdi, 1
	mov rsi, versionNum
	mov rdx, 7
	syscall
	jmp _exit

%%helpmsg:		;prints the help msg and exits
	
	mov al, [rdi + 2]
	cmp al, 0
	jne _optErr	;errors if anything after -h

	mov rax, 1
	mov rdi, 1
	mov rsi, helpMsg
	mov rdx, 300
	syscall
	jmp _exit

%%ignore:		;stops parsing args

	mov al, [rdi + 2]
	cmp al, 0
	jne _optErr	;errors if anything after -i

%%endParse:
%endmacro

section .data
	
	optionError db "mk: invalid options.",0x0a,"Try 'mk -h' for a list of valid options.",0x0a
	noOperandError db "mk: no operand.",0x0a,"Try 'mk -h' for more information.",0x0a
	fileErr db "mk: cannot create file '"
	fileErrEnd db "'.",0x0a
	helpMsg db "Usage: [OPTION]... FILENAME...",0x0a,"Create FILENAME(S), if they do not already exist",0x0a,0x0a,"Options:",0x0a,"  -OOO set file perms on created files to the octal OOO",0x0a,"  -h display this help msg and exit",0x0a,"  -v print version number and exit",0x0a,"  -i mark end of OPTION(s), useful if you want to make a file that starts with '-'",0x0a
	versionNum db "mk 0.1",0x0a
	
	perms dw 0o644

section .text
	global _start

_start:

	pop rbx		;argc into rbx
	pop rdi		;removes path arg
	dec rbx		;sets counter to new number of args

	cmp rbx, 1
	jl _noOpErr	;ends program if 0 args

	parseOptions	;parses options (if any)

	cmp rbx, 1
	jl _noOpErr	;ends program if 0 file args

_argLoop:		;loops through all args
	pop rdi		;file to be created

	createFile	;makes file

	dec rbx
	cmp rbx, 0
	jnz _argLoop	;ends program if 0 file args

_exit:
	mov rax, 60
	mov rdi, 0
	syscall		;exits program with err 0

_fileErr:		;if file can not be created
	
	xor rax, rax

_fileErrLoop:
	inc rax
	mov dl, [rdi + rax]
	cmp dl, 0
	jne _fileErrLoop;finds size of file name
	
	mov rbx, rax	;stores name length
	mov r8, rdi	;stores name ptr

	mov rax, 1
	mov rdi, 1
	mov rsi, fileErr
	mov rdx, 24
	syscall

	mov rax, 1
	mov rdi, 1
	mov rsi, r8
	mov rdx, rbx
	syscall

	mov rax, 1
	mov rdi, 1
	mov rsi, fileErrEnd
	mov rdx, 3
	syscall		;prints error

	jmp _err

_noOpErr:		;if no operand if given
	mov rax, 1
	mov rdi, 1
	mov rsi, noOperandError
	mov rdx, 50
	syscall		;prints error mesage
	jmp _err	;exits with error

_optErr:		;if invalid options
	mov rax, 1
	mov rdi, 1
	mov rsi, optionError
	mov rdx, 62
	syscall		;prints error mesage

_err:			;exits with an error
	mov rax, 60
	mov rdi, 1
	syscall		;exits with err 1
