%define lr.type canonical-lr
%define api.value.type { node_t }

%{
#include <stdio.h>
#include <stdlib.h>
#include <lexer.h>
#include <list.h>
#include <util.h>
#include <syntax/value.h>

int yyerror(char *msg);
int yylex();
%}

%code requires {
#include <tree.h>
}

%token TERROR
%token TINT TTYPE TID

%right '='
%left '-'
%left '+'
%left '/'
%left '*'

%%

prog: stmt
    ;

stmt:
     declr ';'
     | exp ';' {
        tree_postorder({
            printf("%s\n", ((syn_val_t *)T.val)->base.tag);
            free(((syn_val_t *)T.val)->base.tag);
            free(T.val);
        }, $1);
        T.del($1);
     }
     | ';'
     ;

declr:
    TTYPE TID {
        syn_val_t *val = new_syn_val(SYN_DECLR, strdup("declr"));
        $$ = T.new(val);
        T.join($1, $$);
        T.join($2, $$);
    }
    ;

exp:
   TID
   | TINT
   | '(' exp ')' { $$ = $2; }
   | exp '*' exp {
        syn_val_t *val = new_syn_val(SYN_EXP, strdup("mul"));
        $$ = T.new(val);
        T.join($1, $$);
        T.join($3, $$);
   }
   | exp '/' exp {
        syn_val_t *val = new_syn_val(SYN_EXP, strdup("div"));
        $$ = T.new(val);
        T.join($1, $$);
        T.join($3, $$);
   }
   | exp '+' exp {
        syn_val_t *val = new_syn_val(SYN_EXP, strdup("add"));
        $$ = T.new(val);
        T.join($1, $$);
        T.join($3, $$);
   }
   | exp '-' exp {
        syn_val_t *val = new_syn_val(SYN_EXP, strdup("sub"));
        $$ = T.new(val);
        T.join($1, $$);
        T.join($3, $$);
   }
   | exp '=' exp {
        syn_val_t *val = new_syn_val(SYN_EXP, strdup("assign"));
        // NOTE: isso é coisa do sintático?
        // val->exp.dtype = deref($1->val, syn_val_t).exp.data_type;
        // val->exp.lval = TRUE;
        $$ = T.new(val);
        T.join($1, $$);
        T.join($3, $$);
   }
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
