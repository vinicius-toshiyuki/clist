all:
	bison --defines=include/parser.h -o src/parser.c src/parser.y
	flex --header-file=include/lexer.h -o src/lexer.c src/lexer.l
	gcc -c src/*.c -Iinclude
	gcc -o main *.o -Iinclude
