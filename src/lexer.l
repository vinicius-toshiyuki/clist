%option nounput noinput noyywrap yylineno
%{
#include <string.h>
#include <parser.h>
#include <tree.h>
#include <util.h>
#include <syntax/value.h>
#include <stdio.h>

int yycolumn = 1;

#define YY_USER_ACTION \
    yylloc.first_line = yylloc.last_line = yylineno; \
    yylloc.first_column = yycolumn; \
    if (yytext[0] == '\n') yycolumn =  1; \
    else yycolumn += yyleng; \
    yylloc.last_column = yycolumn - 1;

%}

NDIGIT [1-9]
DIGIT 0|{NDIGIT}

TYPE "int"|"float"
ID ([_[:alpha:]][_[:alnum:]]*)

INT {NDIGIT}{DIGIT}*

WS [ \t]+

%%

"\n"|{WS} /* skip */

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

"=" return '=';
"*" return '*';
"/" return '/';
"+" return '+';
"-" return '-';
"(" return '(';
")" return ')';
"{" return '{';
"}" return '}';
"," return ',';
";" return ';';

. { fprintf(stderr, "> (%s)\n", yytext); perror("Unexpected char"); return YYerror; }
