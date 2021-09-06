%define lr.type canonical-lr
%define api.location.type { location_t }

%{
#include <stdio.h>
#include <stdlib.h>
#include <lexer.h>
#include <list.h>
#include <util.h>
#include <syntax/value.h>
#include <slist.h>

int yyerror(char *msg);
int yylex();
%}

%initial-action {
    @$.first_line = 1;
    @$.first_column = 1;
    @$.last_line = 1;
    @$.last_column = 1;
    @$.lines = SL.new();
}

%code requires {
#include <tree.h>
#include <slist.h>

typedef struct location {
    int first_line;
    int first_column;
    int last_line;
    int last_column;
    slist_t lines;
} location_t;
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

%token<node> TINT TTYPE TID

%type<node> stmt stmt.block
%type<node> exp exp.basic
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

prog:
    declr.seq {
        list_map({
            tree_inorder({
                syn_val_t *val = T.val;
                if (T.lvl) {
                    for (int i = 0; i < T.lvl; i++)
                        printf("  ");
                    printf("└─○ ");
                } else {
                    printf("──● ");
                }
                if (T.val) {
                    printf("%s\n", val->base.tag);
                    free(val->base.tag);
                    free(val);
                } else {
                    printf("(error)\n");
                }
            }, L.val);
            T.del(L.val);
        }, $1);
        L.del($1);
    }
    ;

stmt:
     declr ';'
     | exp ';'
     | stmt.block
     | ';' { $$ = T.new(new_syn_val(SYN_STMT, strdup("empty"))); }
     | error ';' {
        fprintf(stderr, "expected a statement (@%d:%d,%d:%d)\n",
            @$.first_line, @$.first_column, @$.last_line, @$.last_column);
        slist_map({
            if (SL.pos > @$.last_line) break;
            if (SL.pos >= @$.first_line) {
                fprintf(stderr, "%lu | %s\n", SL.pos, (char *)SL.val);
            }
        }, yylloc.lines);
        $$ = T.new(NULL);
     }
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

exp.basic:
    TID
    | TINT
    ;

exp:
   exp.basic
   | '(' exp ')' { $$ = $2; }
   | '(' error ')' {
        $$ = T.new(NULL);
        fprintf(stderr, "expected an expression (@%d:%d,%d:%d)\n",
            @2.first_line, @2.first_column, @2.last_line, @2.last_column);
        slist_map({
            if (SL.pos > @$.last_line) break;
            if (SL.pos >= @$.first_line) {
                fprintf(stderr, "%lu | %s\n", SL.pos, (char *)SL.val);
            }
        }, yylloc.lines);
   }
   | TID '(' exp.seq.opt ')' {
        syn_val_t *val = new_syn_val(SYN_EXP, strdup("fn"));
        $$ = T.new(val);
        T.join($1, $$);
        node_t args = T.add(new_syn_val(SYN_DECLR, strdup("exp.seq")), $$);
        list_map(T.join(L.val, args), $3);
        L.del($3);
   }
   | TID '(' error ')' {
        syn_val_t *val = new_syn_val(SYN_EXP, strdup("fn"));
        $$ = T.new(val);
        T.join($1, $$);
        T.add(NULL, $$);
        fprintf(stderr, "invalid arguments (@%d:%d,%d:%d)\n",
            @3.first_line, @3.first_column, @3.last_line, @3.last_column);
        slist_map({
            if (SL.pos > @$.last_line) break;
            if (SL.pos >= @$.first_line) {
                fprintf(stderr, "%lu | %s\n", SL.pos, (char *)SL.val);
            }
        }, yylloc.lines);
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
    | error ',' exp {
        $$ = L.new(); L.append($3, $$);
        fprintf(stderr, "invalid expression (@%d:%d,%d:%d)\n",
            @1.first_line, @1.first_column, @1.last_line, @1.last_column);
        slist_map({
            if (SL.pos > @$.last_line) break;
            if (SL.pos >= @$.first_line) {
                fprintf(stderr, "%lu | %s\n", SL.pos, (char *)SL.val);
            }
        }, yylloc.lines);
    }
    ;

exp.seq.opt:
    %empty { $$ = L.new(); }
    | exp.seq
    ;

%%

int yyerror(char *msg) {
    fprintf(stderr, "%s: ", msg);
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
    slist_map(free(SL.val), yylloc.lines);
    SL.del(yylloc.lines);
    return 0;
}
