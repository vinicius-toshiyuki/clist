%define lr.type canonical-lr

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

%union {
    node_t node;
    list_t list;
}

%destructor {
    tree_inorder({
        syn_val_t *val = T.val;
        if (val) {
            free(val->base.tag);
            free(val);
        }
    }, $$);
    T.del($$);
}<node>

%destructor {
    list_map({
        tree_inorder({
            syn_val_t *val = T.val;
            if (val) {
                free(val->base.tag);
                free(val);
            }
        }, L.val);
        T.del(L.val);
    }, $$);
    L.del($$);
}<list>

%token TERROR
%token<node> TINT TTYPE TID

%type<node> stmt stmt.block
%type<node> exp
%type<node> declr declr.fn param

%type<list> declr.seq
%type<list> stmt.seq
%type<list> param.seq param.seq.opt
%type<list> exp.seq   exp.seq.opt

%right '='
%left '-'
%left '+'
%left '/'
%left '*'

%%

prog: declr.seq {
        list_map({
            printf("=== declr %lu ===\n", L.pos);
            tree_postorder({
                syn_val_t *val = T.val;
                if (T.val) {
                    printf("%s\n", val->base.tag);
                    free(val->base.tag);
                    free(val);
                }
            }, L.val);
            T.del(L.val);
            printf("=== === === ===\n");
        }, $1);
        L.del($1);
    }
    ;

stmt:
     declr ';'
     | exp ';'
     | stmt.block
     | ';' { $$ = T.new(NULL); }
     ;

stmt.block:
    '{' stmt.seq '}' {
        syn_val_t *val = new_syn_val(SYN_BLOCK, strdup("block"));
        $$ = T.new(val);
        list_map(T.join(L.val, $$), $2);
        L.del($2);
    }
    ;

declr:
    TTYPE TID {
        syn_val_t *val = new_syn_val(SYN_DECLR, strdup("declr"));
        $$ = T.new(val);
        T.join($1, $$);
        T.join($2, $$);
    }
    ;

declr.fn:
    TTYPE TID '(' param.seq.opt ')' stmt.block {
        syn_val_t *val = new_syn_val(SYN_DECLR, strdup("declr.fn"));
        $$ = T.new(val);
        T.join($1, $$);
        T.join($2, $$);
        node_t params = T.add(new_syn_val(SYN_DECLR, strdup("param.seq")), $$);
        list_map(T.join(L.val, params), $4);
        L.del($4);
        T.join($6, $$);
    }
    ;

param:
     TTYPE TID {
        syn_val_t *val = new_syn_val(SYN_DECLR, strdup("param"));
        $$ = T.new(val);
        T.join($1, $$);
        T.join($2, $$);
     }
     ;

exp:
   TID
   | TINT
   | '(' exp ')' { $$ = $2; }
   | TID '(' exp.seq.opt ')' {
        syn_val_t *val = new_syn_val(SYN_EXP, strdup("fn"));
        $$ = T.new(val);
        T.join($1, $$);
        node_t args = T.add(new_syn_val(SYN_DECLR, strdup("exp.seq")), $$);
        list_map(T.join(L.val, args), $3);
        L.del($3);
   }
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

stmt.seq:
    %empty { $$ = L.new(); }
    | stmt.seq stmt { $$ = $1; L.append($2, $$); }
    ;

param.seq:
    param { $$ = L.new(); L.append($1, $$); }
    | param.seq ',' param { $$ = $1; L.append($3, $$); }
    ;

param.seq.opt:
    %empty { $$ = L.new(); }
    | param.seq
    ;

declr.seq:
    %empty { $$ = L.new(); }
    | declr.seq declr ';' { $$ = $1; L.append($2, $$); }
    | declr.seq declr.fn { $$ = $1; L.append($2, $$); }
    ;

exp.seq:
    exp { $$ = L.new(); L.append($1, $$); }
    | exp.seq ',' exp { $$ =$1; L.append($3, $$); }
    ;

exp.seq.opt:
    %empty { $$ = L.new(); }
    | exp.seq
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
