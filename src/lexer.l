%option nounput noinput noyywrap
%{
#include <string.h>
#include <parser.h>
%}

NDIGIT [1-9]
DIGIT 0|{NDIGIT}

TYPE "int"|"float"
ID ([_[:alpha:]][_[:alnum:]]*)

INT {NDIGIT}{DIGIT}*

WS [ \t\n]+

%%

{WS} /* skip */

{INT} { yylval = strdup(yytext); return TINT; }

{TYPE} { yylval = strdup(yytext); return TTYPE; }
{ID} { yylval = strdup(yytext); return TID; }

. { return yytext[0]; }
