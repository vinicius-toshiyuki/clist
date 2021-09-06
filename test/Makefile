all:
	gcc -c src/list.c src/tree.c src/slist.c test/main.c -Iinclude -g -Wall
	gcc main.o list.o tree.o slist.o -Iinclude
	./a.out
