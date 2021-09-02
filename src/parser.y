%define lr.type canonical-lr
%define api.value.type { char * }

%{
#include <stdio.h>
#include <stdlib.h>
#include <lexer.h>
#include <list.h>

int yyerror(char *msg);
int yylex();
%}

%token TINT TTYPE TID

%%

prog: declr_list
    ;

declr:
    TTYPE TID ';' {
        printf("type: %s, id: %s\n", $1, $2);
        free($1);
        free($2);
    }
    ;

declr_list:
    declr
    | declr_list declr
    ;

%%

int yyerror(char *msg) {
    printf("%s\n", msg);
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        exit(EXIT_FAILURE);
    }
    yyin = fopen(argv[1], "r");
    yyparse();
    fclose(yyin);
    yylex_destroy();
    return 0;
}
