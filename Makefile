all:
	bison -Wcounterexamples --defines=include/parser.h -o src/parser.c src/parser.y
	flex --header-file=include/lexer.h -o src/lexer.c src/lexer.l
	gcc -c src/**/*.c src/*.c -Iinclude -g
	gcc -o main *.o -Iinclude -g

valgrind: all
	valgrind --leak-check=full --show-leak-kinds=all ./main teste/test.clist
