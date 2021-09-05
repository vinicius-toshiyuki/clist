%option nounput noinput noyywrap
%{
#include <string.h>
#include <parser.h>
#include <tree.h>
#include <util.h>
#include <syntax/value.h>
#include <stdio.h>
%}

NDIGIT [1-9]
DIGIT 0|{NDIGIT}

TYPE "int"|"float"
ID ([_[:alpha:]][_[:alnum:]]*)

INT {NDIGIT}{DIGIT}*

WS [ \t\n]+

%%

{WS} /* skip */

{INT} {
    syn_val_t *val = new_syn_val(SYN_EXP, strdup(yytext));
    val->exp.dtype = SYN_INT;
    val->exp.lval = FALSE;
    yylval = T.new(val);
    return TINT;
}

{TYPE} {
    syn_val_t *val = new_syn_val(SYN_DTYPE, strdup(yytext));
    yylval = T.new(val);
    return TTYPE;
}
{ID} {
    syn_val_t *val = new_syn_val(SYN_ID, strdup(yytext));
    yylval = T.new(val);
    return TID;
}

"=" return '=';
"*" return '*';
"/" return '/';
"+" return '+';
"-" return '-';
"(" return '(';
")" return ')';
";" return ';';

. { fprintf(stderr, "> (%s)\n", yytext); perror("Unexpected char"); return TERROR; }
