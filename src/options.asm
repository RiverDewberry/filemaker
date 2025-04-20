%ifdef OPT_ASM
;do nothing
%else
%define OPT_ASM
%include "./messages.asm"

%macro checkOctal 1	;checks if char at offset is valid octal, if it is, shifts into rdx
	mov byte al, [%1 + rdi + rcx]
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
	cmp rbx, 0
	je _noOpErr	;ends program if 0 args left

	xor rcx, rcx	;sets rcx to 0
	mov qword rdi, [rsp]	;gets the val of the first non path arg
	mov byte al, [rdi]	;sets al to the first byte of the possible options arg
	
	cmp al, '-'	
	jne %%endParse ;stops parsing if normal arg

	pop rdi
	dec rbx		;updates arg counter

	mov byte al, [1 + rdi]
		;sets al to the first byte to parse args

	cmp al, '-'
	je %%parseStrOpt;parses options that need str comparison

%%parseNextOpt:

	mov byte al, [1 + rdi + rcx]
			;sets al to the next byte of the options

	cmp al, 'v'
	je %%verbose	;checks for -v

	cmp al, 'e'
	je %%endArgs	;stops parsing if -e

	cmp al, 'p'
	je %%octalPerms	;parses permissions

	cmp al, 'm'
	je %%octalMode	;parses mode

	cmp al, 'd'
	je %%dirs	;parses dirs

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

	mov rax, endOpt
	call _strCmp
	cmp rax, 1
	je %%endParse	;checks for --end

	jmp _optErr

%%octalMode:
	cmp byte [modeset], 1
	je _optErr	;errors if mode already set

	mov byte [modeset], 1

	checkOctal 2
	checkOctal 3
	checkOctal 4
	checkOctal 5	;checks if all octal vals are valid

	mov [mode], rdx	;sets mode to rdx

	mov byte al, [6 + rdi + rcx]
	cmp al, 0
	jz %%parseNextArg
			;parses next arg if nothing after -mOOOO
	
	add rcx, 5
	jmp %%parseNextOpt
			;parses next opt

%%octalPerms:
	cmp byte [modeset], 1
	je _optErr	;errors if mode already set

	mov byte [modeset], 1

	checkOctal 2
	checkOctal 3
	checkOctal 4	;checks if all octal vals are valid

	mov [mode], rdx;sets mode to rdx

	mov byte al, [5 + rdi + rcx]
	cmp al, 0
	jz %%parseNextArg
			;parses next arg if nothing after -pOOO
	
	add rcx, 4
	jmp %%parseNextOpt
			;parses next opt

%%verbose:
	cmp byte [verbose], 1
	je _optErr	;errors if already verbose

	mov byte [verbose], 1
			;sets verbose to true

	mov byte al, [2 + rdi + rcx]
	cmp al, 0
	jz %%parseNextArg

	add rcx, 1
	jmp %%parseNextOpt

%%dirs:
	cmp byte [dirs], 1
	je _optErr	;errors if already dirs

	mov byte [dirs], 1
			;sets dirs to true

	mov byte al, [2 + rdi + rcx]
	cmp al, 0
	jz %%parseNextArg

	add rcx, 1
	jmp %%parseNextOpt

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
	mov rdx, 471
	syscall
	jmp _exit

%%endArgs:		;stops parsing args

	mov byte al, [2 + rdi + rcx]
	cmp al, 0
	jne _optErr	;errors if anything after -e

%%endParse:
%endmacro

section .data
	helpOpt db "--help",0
	versionOpt db "--version",0
	endOpt db "--end",0
	mode dd 0o644
	modeset db 0	;if mode has been set
	verbose db 0
	dirs db 0

	global dirs
	global verbose
	global modeset
	global mode
	global helpOpt
	global versionOpt

section .text
	
	global _strCmp

_strCmp:		;compares 2 null terminated strings (in rax and rdi)
			;rax = 1 if the strings are equal, otherwise, rax = 0
	
	push rbx
	push rcx
	push rdx	;stores used registers

	xor rbx, rbx	;sets rdx to 0

_strCmpLoop:
	mov byte cl, [rax + rbx]
	mov byte dl, [rdi + rbx]
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
%endif
