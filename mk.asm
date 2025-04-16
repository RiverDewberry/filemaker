%macro createFile 0	;makes file from const char* in rdi
	mov rax, 2
	mov rsi, 64
	mov rdx, 0o644
	syscall		;creates file from path

	mov rdx, rax	;stores rax

	cmp rax, 0xffff_ffff_ffff_efff
	ja _fileErr

	mov rsi, [mode]
	mov rax, 90
	syscall		;sets perms

	mov rax, rdx	;restores rdx

	mov rdi, rax
	mov rax, 3
	syscall		;closes the file
%endmacro

%macro checkOctal 1	;checks if char at offset is valid octal, if it is, shifts into rdx
	mov al, [%1 + rdi + rcx]
	cmp al, 0x30
	jl _optErr
	cmp al, 0x37
	jg _optErr	;checks if char at offset is valid octal
	
	shl rdx, 3
	sub al, 0x30
	or dl, al	;adds val to dl
%endmacro

%macro parseOptions 0	;parses command line args
%%parseNextArg:
	xor rcx, rcx	;sets rcx to 0
	mov rdi, [rsp]	;gets the val of the first non path arg
	mov al, [rdi]	;sets al to the first byte of the possible options arg
	
	cmp al, '-'	
	jne %%endParse ;stops parsing if normal arg

	pop rdi
	dec rbx		;updates arg counter

	mov al, [1 + rdi]
		;sets al to the first byte to parse args

	cmp al, '-'
	je %%parseStrOpt;parses options that need str comparison

	cmp al, 'v'
	je %%versionShort;parses options that need str comparison

%%parseNextOpt:

	mov al, [1 + rdi + rcx]
			;sets al to the next byte of the options

	cmp al, 'e'
	je %%endArgs	;stops parsing if -e

	cmp al, 'p'
	je %%octalPerms	;parses permissions

	cmp al, 'm'
	je %%octalMode	;parses mode

	jmp _optErr	;if arg is not a valid option

%%parseStrOpt:		;parses options starting with --

	mov rax, helpOpt
	call _strCmp
	cmp rax, 1
	je %%helpMsg	;checks for --help

	mov rax, versionOpt
	call _strCmp
	cmp rax, 1
	je %%version	;checks for --version

	jmp _optErr

%%octalMode:

	checkOctal 2
	checkOctal 3
	checkOctal 4
	checkOctal 5	;checks if all octal vals are valid

	mov [mode], rdx	;sets mode to rdx

	mov al, [6 + rdi + rcx]
	cmp al, 0
	jz %%parseNextArg
			;parses next arg if nothing after -mOOOO
	
	add rcx, 5
	jmp %%parseNextOpt
			;parses next opt

%%octalPerms:

	checkOctal 2
	checkOctal 3
	checkOctal 4	;checks if all octal vals are valid

	mov [mode], rdx;sets mode to rdx

	mov al, [5 + rdi + rcx]
	cmp al, 0
	jz %%parseNextArg
			;parses next arg if nothing after -pOOO
	
	add rcx, 4
	jmp %%parseNextOpt
			;parses next opt

%%versionShort:

	mov al, [2 + rdi]
	cmp al, 0
	jnz _optErr	;if anything is after -v

%%version:		;prints the version num

	mov rax, 1
	mov rdi, 1
	mov rsi, versionNum
	mov rdx, 7
	syscall

	jmp _exit

%%helpMsg:		;prints the help msg and exits
	
	mov rax, 1
	mov rdi, 1
	mov rsi, helpMsg
	mov rdx, 379
	syscall
	jmp _exit

%%endArgs:		;stops parsing args

	mov al, [2 + rdi + rcx]
	cmp al, 0
	jne _optErr	;errors if anything after -e

%%endParse:
%endmacro

section .data
	
	optionError db "mk: invalid options.",0x0a,"Try 'mk --help' for a list of valid options.",0x0a
	noOperandError db "mk: no operand.",0x0a,"Try 'mk --help' for more information.",0x0a
	fileErr db "mk: cannot create file '"
	fileErrEnd db "'.",0x0a
	helpMsg db "Usage: [OPTION]... FILENAME...",0x0a,"Create FILENAME(S), if they do not already exist",0x0a,0x0a,"Options:",0x0a,"  -pOOO set file perms on created files to the octal OOO",0x0a,"  -mOOOO set file mode on created files to the octal value OOOO",0x0a,"  -e mark end of OPTION(s), useful if you want to make a file that starts with '-'",0x0a,"  -v --version print version number and exit",0x0a,"  --help display this help msg and exit",0x0a
	versionNum db "mk 1.0",0x0a
	
	mode dd 0o644

	helpOpt db "--help",0
	versionOpt db "--version",0


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
	mov rdx, 54
	syscall		;prints error mesage
	jmp _err	;exits with error

_optErr:		;if invalid options
	mov rax, 1
	mov rdi, 1
	mov rsi, optionError
	mov rdx, 66
	syscall		;prints error mesage

_err:			;exits with an error
	mov rax, 60
	mov rdi, 1
	syscall		;exits with error 1

_strCmp:		;compares 2 null terminated strings (in rax and rdi)
			;rax = 1 if the strings are equal, otherwise, rax = 0
	
	push rbx
	push rcx
	push rdx	;stores used registers

	xor rbx, rbx	;sets rdx to 0

_strCmpLoop:
	mov cl, [rax + rbx]
	mov dl, [rdi + rbx]
	inc rbx		;gets next chars of the strings
	
	cmp cl, dl
	jne _strNE	;jumps to strNE if the strings are not equal

	cmp cl, 0
	je _strEQ	;if the strings terminate

	jmp _strCmpLoop ;loops

_strNE:			;if the strings are not equal
	
	xor rax, rax	;sets rax to 0

	pop rdx
	pop rcx
	pop rbx		;restores registers

	ret
_strEQ:			;if the strings are equal
	
	mov rax, 1	;sets rax to 1

	pop rdx
	pop rcx
	pop rbx		;restores registers

	ret
