%ifdef MSG_ASM
;do nothing
%else
%define MSG_ASM

section .data
	optionError db "mk: invalid options.",0x0a,"Try 'mk --help' for a list of valid options.",0x0a
	noOperandError db "mk: no operand.",0x0a,"Try 'mk --help' for more information.",0x0a
	fileErr db "mk: cannot create file '"
	verboseFileMsg db "Creating file '",0
	fileMsgEnd db "'.",0x0a,0
	helpMsg db "Usage: [OPTION]... FILENAME...",0x0a,"Create FILENAME(S), if they do not already exist",0x0a,0x0a,"Options:",0x0a,"  -pOOO set file perms on created files to the octal OOO",0x0a,"  -mOOOO set file mode on created files to the octal value OOOO",0x0a,"  -v explain what is being done",0x0a,"  -e --end mark end of OPTION(s), useful if you want to make a file that starts with '-'",0x0a,"  --version print version number and exit",0x0a,"  --help display this help msg and exit",0x0a
	versionNum db "mk 1.1",0x0a

	global optionErr
	global noOperandError
	global fileErr
	global fileErrEnd
	global helpMsg
	global versionNum

%endif
