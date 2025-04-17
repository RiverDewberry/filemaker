AS=nasm
FLAGS=-felf64 -o ${NAME}.o
NAME=mk
MAIN=./src/main.asm
INCLUDE=./src/

all: clean build

clean:
	rm -f ${NAME}
	rm -f ${INCLUDE}*.o
build:
	${AS} -felf64 ${MAIN} -i ${INCLUDE} -o ${NAME}.o
	ld ${NAME}.o -o ${NAME}
	rm ${NAME}.o
