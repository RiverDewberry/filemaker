AS=nasm
FLAGS=-felf64 -o ${NAME}.o
NAME=mk
SOURCE=mk.asm

all: clean build

clean:
	rm -f ${NAME}
build:
	${AS} -felf64 ${SOURCE} 
	ld ${NAME}.o -o ${NAME}
	rm ${NAME}.o
