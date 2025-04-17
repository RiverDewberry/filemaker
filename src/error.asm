%ifdef ERR_ASM
;do nothing
%else
%define ERR_ASM
%include "./messages.asm"

section .text

	global _fileErr
	global _optErr
	global _noOpErr

_fileErr:		;if file can not be created

	xor rax, rax

_fileErrLoop:
	inc rax
	mov byte dl, [rdi + rax]
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

%endif
