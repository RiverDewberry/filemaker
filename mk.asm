%macro createFile 0	;makes file from const char* in rdi
	mov rax, 2
	mov rsi, 64
	mov rdx, 0o644
	syscall		;creates file from path

	mov rdx, rax	;stores rax

	mov rsi, [perms]
	mov rax, 90
	syscall		;sets perms

	mov rax, rdx	;restores rdx

	mov rdi, rax
	mov rax, 3
	syscall		;closes the file
%endmacro

%macro parseOptions 0	;parses command line args
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

	mov al, [rdi + 1]
	cmp al, 0x30
	jl _err
	cmp al, 0x37
	jg _err		;checks if first char is valid octal

	sub al, 0x30
	or dl, al	;adds val to dl
	
	mov al, [rdi + 2]
	cmp al, 0x30
	jl _err
	cmp al, 0x37
	jg _err		;checks if next char is valid octal

	shl rdx, 3
	sub al, 0x30
	or dl, al	;adds val to dl
	
	mov al, [rdi + 3]
	cmp al, 0x30
	jl _err
	cmp al, 0x37
	jg _err		;checks if final char is valid octal

	shl rdx, 3
	sub al, 0x30
	or dl, al	;adds val to dl

	mov al, [rdi + 4]
	cmp al, 0
	jne _err	;errors if anything after -OOO

	mov [perms], rdx;sets perms to rdx

	jmp %%endParse

%%version:		;prints the version num
	mov al, [rdi + 2]
	cmp al, 0
	jne _err	;errors if anything after -v

	mov rax, 1
	mov rdi, 1
	mov rsi, versionNum
	mov rdx, 7
	syscall
	jmp _exit

%%helpmsg:		;prints the help msg and exits
	
	mov al, [rdi + 2]
	cmp al, 0
	jne _err	;errors if anything after -h

	mov rax, 1
	mov rdi, 1
	mov rsi, helpMsg
	mov rdx, 214
	syscall
	jmp _exit

%%endParse:
%endmacro

section .data
	argError db "mk: Arguments invalid. Use -h for help.",0x0a
	helpMsg db "Usage: [OPTION] FILENAME...",0x0a,"Create FILENAME(S), if they do not already exist",0x0a,0x0a,"Options:",0x0a,"  -OOO set file perms on created files to the octal OOO",0x0a,"  -h display this help msg and exit",0x0a,"  -v print version number and exit",0x0a
	versionNum db "mk 0.0",0x0a
	perms dw 0o644

section .text
	global _start

_start:

	pop rbx		;argc into rbx
	pop rdi		;removes path arg
	dec rbx		;sets counter to new number of args

	cmp rbx, 1
	jl _err		;ends program if 0 args

	parseOptions	;parses options (if any)

	cmp rbx, 1
	jl _err		;ends program if 0 file args

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

_err:			;exits with an error
	mov rax, 1
	mov rdi, 1
	mov rsi, argError
	mov rdx, 40
	syscall		;prints error mesage

	mov rax, 60
	mov rdi, 1
	syscall		;exits with err 1
