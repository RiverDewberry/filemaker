%include "./error.asm"
%include "./options.asm"

%macro createFile 0	;makes file from const char* in rdi
	cmp byte [verbose], 0
	je %%nonVerbose

	mov rax, verboseFileMsg
	call _printStr

	mov rax, rdi
	call _printStr

	mov rax, fileMsgEnd
	call _printStr

%%nonVerbose:

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

_printStr:		;prints the null terminated string in rax
	push rcx
	push rdx
	push rdi
	push rsi	;stores registers

	xor rdx, rdx

_printLoop:
	inc rdx
	mov byte cl, [rax + rdx]
	cmp cl, 0
	jnz _printLoop	;loop finds strlen and puts it in rbx

	mov rsi, rax
	mov rax, 1
	mov rdi, 1
	syscall		;prints

	pop rsi
	pop rdi
	pop rdx
	pop rcx		;restores registers
	ret
