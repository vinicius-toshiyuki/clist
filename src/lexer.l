%option nounput noinput noyywrap yylineno
%{
#include <string.h>
#include <parser.h>
#include <tree.h>
#include <util.h>
#include <syntax/value.h>
#include <stdio.h>
#include <slist.h>

void yyerror(char *msg);

int yycolumn = 1;

#define YY_USER_ACTION                                           \
    yylloc.first_line = yylloc.last_line = yylineno;             \
    yylloc.first_column = yycolumn;                              \
    if (yylloc.lines->size == 0) {                               \
        SL.insert(strdup(""), 1, yylloc.lines);                  \
    }                                                            \
    if (yytext[0] == '\n') {                                     \
        yycolumn =  1;                                           \
        SL.insert(strdup(yytext + 1), yylineno, yylloc.lines);   \
    } else {                                                     \
        yycolumn += yyleng;                                      \
        char *line_cur = SL.get(yylineno, yylloc.lines);         \
        size_t line_len = strlen(line_cur) + strlen(yytext) + 1; \
        char *line_cat = (char *)calloc(line_len, sizeof(char)); \
        strcat(line_cat, line_cur);                              \
        strcat(line_cat, yytext);                                \
        free(line_cur);                                          \
        SL.update(line_cat, yylineno, yylloc.lines);             \
    }                                                            \
    yylloc.last_column = yycolumn - 1;

%}

NDIGIT [1-9]
DIGIT 0|{NDIGIT}

TYPE "int"|"float"
ID ([_[:alpha:]][_[:alnum:]]*)

INT ({NDIGIT}{DIGIT}*|{DIGIT})

WS [ \t]+

%%

"\n"|{WS} /* skip */

"return" {
    syn_val_t *val = new_syn_val(SYN_STMT, strdup(yytext));
    yylval.node = T.new(val);
    return TRETURN;
}

"if" {
    syn_val_t *val = new_syn_val(SYN_STMT, strdup(yytext));
    yylval.node = T.new(val);
    return TIF;
}

"else" return TELSE;

"for" {
    syn_val_t *val = new_syn_val(SYN_STMT, strdup(yytext));
    yylval.node = T.new(val);
    return TFOR;
}

"while" {
    syn_val_t *val = new_syn_val(SYN_STMT, strdup(yytext));
    yylval.node = T.new(val);
    return TWHILE;
}

"do" return TDO;

"=" return '=';
"*" return '*';
"/" return '/';
"%" return '%';
"+" return '+';
"-" return '-';

"++" return TINC;
"--" return TDEC;

"!" return '!';
"==" return TEQ;
"!=" return TNEQ;
">" return '>';
"<" return '<';
"<=" return TLE;
">=" return TGE;
"||" return TOR;
"&&" return TAND;

"~" return '~';
"|" return '|';
"&" return '&';
"^" return '^';

"(" return '(';
")" return ')';
"[" return '[';
"]" return ']';
"{" return '{';
"}" return '}';
"," return ',';
";" return ';';

{INT} {
    syn_val_t *val = new_syn_val(SYN_EXP, strdup(yytext));
    val->exp.dtype = SYN_INT;
    val->exp.lval = FALSE;
    yylval.node = T.new(val);
    return TINT;
}

{TYPE} {
    syn_val_t *val = new_syn_val(SYN_DTYPE, strdup(yytext));
    yylval.node = T.new(val);
    return TTYPE;
}

{ID} {
    syn_val_t *val = new_syn_val(SYN_ID, strdup(yytext));
    yylval.node = T.new(val);
    return TID;
}

. { 
    yyerror("lexical error");
    return YYerror;
}
