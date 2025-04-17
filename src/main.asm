%include "./error.asm"
%include "./options.asm"

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
