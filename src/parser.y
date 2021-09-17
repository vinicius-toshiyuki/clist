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

void yyerror(char *msg);
int yylex();

#define yyerror_details(loc, range, msg) {                                                    \
    fprintf(stderr, msg " \033[90m(@%d:%d,%d:%d)\033[0m\n",                                   \
        loc.first_line, loc.first_column, loc.last_line, loc.last_column);                    \
    slist_map({                                                                               \
        if (SL.pos > range.last_line) break;                                                  \
        if (SL.pos >= range.first_line)                                                       \
        if (SL.pos == loc.first_line) {                                                       \
            fprintf(stderr, "%4lu | %.*s\033[31;4;1m%.*s\033[0m%.*s\033[90m%s\033[0m\n",      \
                SL.pos, loc.first_column - 1, (char *)SL.val,                                 \
                SL.pos == loc.last_line ?                                                     \
                    loc.last_column - loc.first_column + 1:                                   \
                    (int) strlen(SL.val) - (loc.first_column - 1),                            \
                ((char *)SL.val) + loc.first_column - 1,                                      \
                                                                                              \
                SL.pos == loc.last_line ? (int) strlen(SL.val) - loc.last_column : 0,         \
                ((char *)SL.val) + loc.last_column, SL.pos == loc.last_line ? "..." : "↴"     \
                );                                                                            \
        } else if (SL.pos == loc.last_line) {                                                 \
            fprintf(stderr, "%4lu | \033[31;4;1m%.*s\033[0m%s\033[90m...\033[0m\n",           \
                SL.pos, loc.last_column, (char *)SL.val, ((char *)SL.val) + loc.last_column); \
        } else {                                                                              \
            fprintf(stderr, "%4lu | \033[31;4;1m%s\033[0m\033[90m↴\033[0m\n",                 \
                SL.pos, (char *)SL.val);                                                      \
        }                                                                                     \
    }, yylloc.lines);                                                                         \
    yyerrok;                                                                                  \
}

#define EXP_BIN(tag, first, last, res)                      \
    {                                                       \
        syn_val_t *val = new_syn_val(SYN_EXP, strdup(tag)); \
        res = T.new(val);                                   \
        T.join(first, res);                                 \
        T.join(last, res);                                  \
    }
#define EXP_BIN_ERR(tag, msg, loc, range, last, res)        \
    {                                                       \
        yyerror_details(loc, range, msg);                   \
        syn_val_t *val = new_syn_val(SYN_EXP, strdup(tag)); \
        res = T.new(val);                                   \
        T.join(last, res);                                  \
    }

#define EXP_UNI(tag, first, res)                            \
    {                                                       \
        syn_val_t *val = new_syn_val(SYN_EXP, strdup(tag)); \
        res = T.new(val);                                   \
        T.join(first, res);                                 \
    }

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
    size_t ival;
}

%destructor {
    tree_preorder({
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
        tree_preorder({
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

%destructor { }<*>

%token<node> TINT TTYPE TID
%token<node> TRETURN "return"
%token<node> TIF "if"
%token<node> TFOR "for" TWHILE "while"
%token TELSE "else" TDO "do"

%token TEQ "==" TNEQ "!=" TLE "<=" TGE ">=" TOR "||" TAND "&&"
%token TINC "++" TDEC "--"

%type<node> type
%type<ival> type.depth
%type<node> stmt stmt.block stmt.return stmt.cond stmt.loop
%type<node> stmt.loop.for stmt.loop.for.arg.first stmt.loop.for.arg
%type<node> stmt.loop.while stmt.loop.while.do
%type<node> exp exp.basic exp.binary exp.unary exp.postfix exp.call
%type<node> declr declr.fn param

%type<list> declr.seq
%type<list> stmt.seq
%type<list> param.seq param.seq.opt
%type<list> exp.seq   exp.seq.opt

%right '='
%left "||"
%left "&&"
%left '|'
%left '^'
%left '&'
%left "==" "!="
%left '<' "<=" '>' ">="
%left '+' '-'
%left '*' '/' '%'
%right TUNI '!' '~' "++" "--"
%left TPOST '[' ']'

%precedence "if"
%precedence "else"

%%

prog:
    declr.seq {
        int arr[1000];
        list_map({ tree_preorder({
            syn_val_t *val = T.val;
            if (T.lvl) {
                if (__tree_order_current == __tree_order_current->top->branches->tail->val)
                    arr[T.lvl] = 0;
                else
                    arr[T.lvl] = 1;
                for (int i = 0; i < T.lvl; i++) {
                    printf("%s", i && arr[i] ? "│ " : "  ");
                    // printf("%lu ", i ? arr[i] : 0lu);
                }
                char *branch = NULL;
                if (__tree_order_current == __tree_order_current->top->branches->tail->val)
                    branch = "└─%s──○ "; else
                    branch = "├─%s──○ ";
                printf(branch, __tree_order_current->branches ? "┬" : "─");
            } else {
                printf("──%s● ", __tree_order_current->branches ? "┬" : "─");
            }
            if (T.val) {
                printf("%s", val->base.tag);
                if (val->base.type == SYN_DTYPE && val->dtype.depth) {
                    printf(" (depth %lu)", val->dtype.depth);
                }
                printf("\n");
                free(val->base.tag);
                free(val);
            } else {
                printf("(error)\n");
            }
        }, L.val); T.del(L.val); }, $1);
        L.del($1);
    }
    ;

stmt:
     declr ';'
     | exp ';'
     | stmt.return ';'
     | stmt.block
     | stmt.cond
     | stmt.loop
     | ';' { $$ = T.new(new_syn_val(SYN_STMT, strdup("empty"))); }
     | error ';' {
        yyerror_details(@1, @$, "expected a statement");
        $$ = T.new(NULL);
     }
     ;

stmt.return:
    TRETURN exp { $$ = $1; T.join($2, $$); }
    | TRETURN error {
        $$ = $1;
        yyerror_details(@2, @$, "expected an expression to return");
    }
    ;

stmt.cond:
    "if" '(' exp ')' stmt %prec "if" {
        $$ = $1;
        T.join($3, $$);
        T.join($5, $$);
    }
    | "if" '(' exp ')' stmt "else" stmt %prec "else" {
        $$ = $1;
        T.join($3, $$);
        T.join($5, $$);
        T.join($7, $$);
    }
    | "if" '(' error ')' stmt %prec "if" {
        yyerror_details(@3, @$, "expected an expression inside if");
        $$ = $1;
        T.join($5, $$);
    }
    | "if" '(' error ')' stmt "else" stmt %prec "else" {
        yyerror_details(@3, @$, "expected an expression inside if");
        $$ = $1;
        T.join($5, $$);
        T.join($7, $$);
    }
    ;

stmt.loop:
    stmt.loop.for
    | stmt.loop.while
    ;

stmt.loop.while:
    "while" '(' exp ')' stmt {
        $$ = $1;
        T.join($3, $$);
        T.join($5, $$);
    }
    | "while" '(' error ')' stmt {
        $$ = $1;
        T.join($5, $$);
    }
    | stmt.loop.while.do
    ;

stmt.loop.while.do:
    "do" stmt "while" '(' exp ')' ';' {
        $$ = $3;
        syn_val_t *val = $$->val;
        free(val->base.tag);
        val->base.tag = strdup("while.do");
        T.join($5, $$);
        T.join($2, $$);
    }
    | "do" stmt "while" '(' error ')' ';' {
        $$ = $3;
        syn_val_t *val = $$->val;
        free(val->base.tag);
        val->base.tag = strdup("while.do");
        T.join($2, $$);
    }
    ;

stmt.loop.for:
    "for" '(' stmt.loop.for.arg.first ';' stmt.loop.for.arg ';' stmt.loop.for.arg ')' stmt {
        $$ = $1;
        T.join($3, $$);
        T.join($5, $$);
        T.join($7, $$);
        T.join($9, $$);
    }
    ;

stmt.loop.for.arg:
    %empty {
        syn_val_t *val = new_syn_val(SYN_FOR_ARG, strdup("for.arg"));
        $$ = T.new(val);
    }
    | exp {
        syn_val_t *val = new_syn_val(SYN_FOR_ARG, strdup("for.arg"));
        $$ = T.new(val);
        T.join($1, $$);
    }
    | error {
        syn_val_t *val = new_syn_val(SYN_FOR_ARG, strdup("(error)"));
        $$ = T.new(val);
        yyerror_details(@1, @$, "invalid for argument");
    }
    ;

stmt.loop.for.arg.first:
    stmt.loop.for.arg
    | declr
    ;

stmt.block:
    '{' stmt.seq '}' {
        syn_val_t *val = new_syn_val(SYN_BLOCK, strdup("block"));
        $$ = T.new(val);
        list_map(T.join(L.val, $$), $2);
        L.del($2);
    }
    ;

type:
    TTYPE
    | TTYPE type.depth {
        syn_val_t *val = ($$ = $1)->val;
        val->dtype.depth = $2;
    }
    ;

type.depth:
    '*' { $$ = 1; }
    | type.depth '*' { $$ = $1 + 1; }
    ;

declr:
    type TID {
        syn_val_t *val = new_syn_val(SYN_DECLR, strdup("declr"));
        $$ = T.new(val);
        T.join($1, $$);
        T.join($2, $$);
    }
    | error TID {
        syn_val_t *val = new_syn_val(SYN_DECLR, strdup("declr"));
        $$ = T.new(val);
        T.join($2, $$);
    }
    ;

declr.fn:
    type TID '(' param.seq.opt ')' stmt.block {
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
     type TID {
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
   | exp.binary
   | exp.unary
   | exp.postfix
   | exp.call
   | '(' exp ')' { $$ = $2; }
   | '(' error ')' {
        $$ = T.new(NULL);
        yyerror_details(@2, @$, "expected an expression");
   }
   ;

exp.call:
   TID '(' exp.seq.opt ')' {
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
        yyerror_details(@3, @$, "invalid arguments");
   }
   ;

exp.postfix:
      exp   '[' exp ']' %prec TPOST { EXP_BIN("access", $1, $3, $$) }
    | error '[' exp ']' %prec TPOST { EXP_BIN_ERR("access", "invalid array expression", @1, @$, $3, $$) }
    | exp '[' error ']' %prec TPOST { EXP_BIN_ERR("access", "invalid array index expression", @3, @$, $1, $$) }
    | exp "++" %prec TPOST { EXP_UNI("inc.post", $1, $$); }
    | exp "--" %prec TPOST { EXP_UNI("dec.post", $1, $$); }
    ;

exp.unary:
      '+' exp %prec TUNI  { EXP_UNI("plus"   , $2, $$); }
    | '-' exp %prec TUNI  { EXP_UNI("minus"  , $2, $$); }
    | '!' exp %prec TUNI  { EXP_UNI("neg"    , $2, $$); }
    | '~' exp %prec TUNI  { EXP_UNI("neg.bit", $2, $$); }
    | '*' exp %prec TUNI  { EXP_UNI("deref"  , $2, $$); }
    | "++" exp %prec TUNI { EXP_UNI("inc"    , $2, $$); }
    | "--" exp %prec TUNI { EXP_UNI("dec"    , $2, $$); }
    ;

exp.binary:
     exp '%'  exp { EXP_BIN("mod"         , $1, $3, $$); }
   | exp '/'  exp { EXP_BIN("div"         , $1, $3, $$); }
   | exp '*'  exp { EXP_BIN("mul"         , $1, $3, $$); }
   | exp '-'  exp { EXP_BIN("sub"         , $1, $3, $$); }
   | exp '+'  exp { EXP_BIN("add"         , $1, $3, $$); }
   | exp ">=" exp { EXP_BIN("gte"         , $1, $3, $$); }
   | exp '>'  exp { EXP_BIN("gt"          , $1, $3, $$); }
   | exp "<=" exp { EXP_BIN("lte"         , $1, $3, $$); }
   | exp '<'  exp { EXP_BIN("lt"          , $1, $3, $$); }
   | exp "!=" exp { EXP_BIN("neq"         , $1, $3, $$); }
   | exp "==" exp { EXP_BIN("eq"          , $1, $3, $$); }
   | exp '&'  exp { EXP_BIN("and.bit"     , $1, $3, $$); }
   | exp '^'  exp { EXP_BIN("or.exclusive", $1, $3, $$); }
   | exp '|'  exp { EXP_BIN("or.bit"      , $1, $3, $$); }
   | exp "&&" exp { EXP_BIN("and"         , $1, $3, $$); }
   | exp "||" exp { EXP_BIN("or"          , $1, $3, $$); }
   | exp '='  exp { EXP_BIN("assign"      , $1, $3, $$); }
   | error '%'  exp { EXP_BIN_ERR("mod"         , "expected an expression", @1, @$, $3, $$); }
   | error '/'  exp { EXP_BIN_ERR("div"         , "expected an expression", @1, @$, $3, $$); }
   | error '*'  exp { EXP_BIN_ERR("mul"         , "expected an expression", @1, @$, $3, $$); }
   | error '-'  exp { EXP_BIN_ERR("sub"         , "expected an expression", @1, @$, $3, $$); }
   | error '+'  exp { EXP_BIN_ERR("add"         , "expected an expression", @1, @$, $3, $$); }
   | error ">=" exp { EXP_BIN_ERR("gte"         , "expected an expression", @1, @$, $3, $$); }
   | error '>'  exp { EXP_BIN_ERR("gt"          , "expected an expression", @1, @$, $3, $$); }
   | error "<=" exp { EXP_BIN_ERR("lte"         , "expected an expression", @1, @$, $3, $$); }
   | error '<'  exp { EXP_BIN_ERR("lt"          , "expected an expression", @1, @$, $3, $$); }
   | error "!=" exp { EXP_BIN_ERR("neq"         , "expected an expression", @1, @$, $3, $$); }
   | error "==" exp { EXP_BIN_ERR("eq"          , "expected an expression", @1, @$, $3, $$); }
   | error '&'  exp { EXP_BIN_ERR("and.bit"     , "expected an expression", @1, @$, $3, $$); }
   | error '^'  exp { EXP_BIN_ERR("or.exclusive", "expected an expression", @1, @$, $3, $$); }
   | error '|'  exp { EXP_BIN_ERR("or.bit"      , "expected an expression", @1, @$, $3, $$); }
   | error "&&" exp { EXP_BIN_ERR("and"         , "expected an expression", @1, @$, $3, $$); }
   | error "||" exp { EXP_BIN_ERR("or"          , "expected an expression", @1, @$, $3, $$); }
   | error '='  exp { EXP_BIN_ERR("assign"      , "expected an expression", @1, @$, $3, $$); }
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
        yyerror_details(@1, @$, "invalid expression");
    }
    ;

exp.seq.opt:
    %empty { $$ = L.new(); }
    | exp.seq
    ;

%%

void yyerror(char *msg) {
    fprintf(stderr, "\033[33;1m%s\033[0m: ", msg);
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
