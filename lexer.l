%option noyywrap yylineno

%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>

extern int yylineno;
extern YYSTYPE yylval;

void yyerror(const char *s);
%}

DIGIT   [0-9]
ID      [a-zA-Z_][a-zA-Z0-9_]*
WS      [ \t]+
EOL     (\r\n|\n|\r)

%%

{EOL}     { /* satır sonu, yok say */ }

"--".*    { /* Yorum satırını tamamen yok say */ }

"fun"                  { return FUN; }
"print"                { return PRINT; }
"return"               { return RETURN; }
"if"                   { return IF; }
"else"                 { return ELSE; }
"while"                { return WHILE; }
"draw_circle"          { return DRAW_CIRCLE; }
"key_pressed"          { return KEY_PRESSED; }
"UP"                   { return TUS_UP; }
"DOWN"                 { return TUS_DOWN; }
"LEFT"                 { return TUS_LEFT; }
"RIGHT"                { return TUS_RIGHT; }
[ \t]+                 { /* Boşlukları es geç */ }

"<-"                   { return ASSIGN; }

"=="                   { return EQ; }
"!="                   { return NEQ; }
"<="                   { return LEQ; }
">="                   { return GEQ; }
"<"                    { return LT; }
">"                    { return GT; }

"&&"                   { return AND; }
"||"                   { return OR; }
"!"                    { return NOT; }

"+"                    { return PLUS; }
"-"                    { return MINUS; }
"*"                    { return MUL; }
"/"                    { return DIV; }
"%"                    { return MOD; }
"^"                    { return POW; }

"("                    { return LPAREN; }
")"                    { return RPAREN; }
"{"                    { return LBRACE; }
"}"                    { return RBRACE; }
","                    { return COMMA; }
";"                    { return SEMICOLON; }

{ID}                   { yylval.str = strdup(yytext); return IDENTIFIER; }
{DIGIT}+("."{DIGIT}*)? { yylval.fval = atof(yytext); return NUMBER; }

{WS}                   { /* boşlukları yoksay */ }

.                      { 
                       yyerror("Gecersiz karakter");
                       return UNKNOWN_CHAR; 
                      }

%%
