%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <locale.h>
#include "parser.tab.h"

extern int yylex(void);
extern int yylineno;
extern FILE *yyin;

void yyrestart(FILE *input_file);
void yyerror(const char *s);

typedef struct Var {
    char *name;
    double value;
    struct Var *next;
} Var;

Var *var_list = NULL;
int had_error = 0;

double get_var_value(const char *name) {
    Var *v = var_list;
    while (v) {
        if (strcmp(v->name, name) == 0)
            return v->value;
        v = v->next;
    }
    fprintf(stderr, "[UYARI] Tanimsiz degisken '%s', 0.0 olarak varsayiliyor\n", name);
    return 0.0;
}

void set_var_value(const char *name, double value) {
    Var *v = var_list;
    while (v) {
        if (strcmp(v->name, name) == 0) {
            v->value = value;
            return;
        }
        v = v->next;
    }
    Var *new_var = malloc(sizeof(Var));
    new_var->name = strdup(name);
    new_var->value = value;
    new_var->next = var_list;
    var_list = new_var;
}

void print_vars() {
    Var *v = var_list;
    printf("\n[DEBUG] Degisken Tablosu:\n");
    while (v) {
        printf("  %s = %f\n", v->name, v->value);
        v = v->next;
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "[HATA] Satir %d: %s\n", yylineno, s);
    had_error = 1;
    while (yylex() != SEMICOLON && yylex() != 0);
}
%}

%union {
    char *str;
    double fval;
}

%type <fval> expression statement matched unmatched print_statement assignment block while_statement statements draw_command key_pressed_check function_definition
%token SEMICOLON
%token UNKNOWN_CHAR
%token <str> IDENTIFIER
%token <fval> NUMBER
%token PRINT
%token FUN RETURN IF ELSE WHILE
%token EQ NEQ LEQ GEQ LT GT
%token PLUS MINUS MUL DIV MOD POW
%token DRAW_CIRCLE 
%token KEY_PRESSED TUS_UP TUS_DOWN TUS_LEFT TUS_RIGHT
%token ASSIGN
%token AND OR NOT
%token LPAREN RPAREN LBRACE RBRACE COMMA 

%left OR
%left AND
%left EQ NEQ
%left LT GT LEQ GEQ
%left PLUS MINUS
%left MUL DIV MOD
%right POW
%right NOT
%right UMINUS

%start program

%%

program:
    /* empty */
    | program statement
    | program error { yyerrok; yyclearin; }
    ;

statement:
    matched
    | unmatched
    ;

matched:
      IF LPAREN expression RPAREN matched ELSE matched
        {
            if ($3) { $$ = $5; } else { $$ = $7; }
        }
    | expression SEMICOLON { $$ = $1; }
    | print_statement SEMICOLON { $$ = $1; }
    | assignment SEMICOLON { $$ = $1; }
    | draw_command SEMICOLON { $$ = $1; }
    | key_pressed_check SEMICOLON { $$ = $1; }
    | function_definition { $$ = $1; }
    | block { $$ = $1; }
    | while_statement { $$ = $1; }
    ;

unmatched:
      IF LPAREN expression RPAREN statement
        {
            if ($3) { $$ = $5; } else { $$ = 0; }
        }
    | IF LPAREN expression RPAREN matched ELSE unmatched
        {
            if ($3) { $$ = $5; } else { $$ = $7; }
        }
    ;

block:
    LBRACE statements RBRACE { $$ = $2; }
    ;

statements:
    /* empty */ { $$ = 0; }
    | statements statement { $$ = $2; }
    ;

assignment:
    IDENTIFIER ASSIGN expression {
        set_var_value($1, $3);
        printf("[DEBUG] Atama: %s = %f\n", $1, $3);
        free($1);
        $$ = $3;
    }
    ;

function_definition:
    FUN IDENTIFIER LPAREN RPAREN block {
        printf("Fonksiyon tanimi: %s\n", $2);
        free($2);
        $$ = 0;
    }
    ;

draw_command:
    DRAW_CIRCLE LPAREN expression COMMA expression COMMA expression RPAREN {
        printf("Cember ciz: x=%.2f, y=%.2f, r=%.2f\n", $3, $5, $7);
        $$ = 0;
    }
    ;

key_pressed_check:
    KEY_PRESSED LPAREN TUS_UP RPAREN {
        printf("Tus kontrol: YUKARI basili mi?\n");
        $$ = 0;
    }
    | KEY_PRESSED LPAREN TUS_DOWN RPAREN {
        printf("Tus kontrol: ASAGI basili mi?\n");
        $$ = 0;
    }
    | KEY_PRESSED LPAREN TUS_LEFT RPAREN {
        printf("Tus kontrol: SOL basili mi?\n");
        $$ = 0;
    }
    | KEY_PRESSED LPAREN TUS_RIGHT RPAREN {
        printf("Tus kontrol: SAG basili mi?\n");
        $$ = 0;
    }
    ;

while_statement:
    WHILE LPAREN expression RPAREN statement {
        while ($3) {
            $$ = $5;
        }
    }
    ;

print_statement:
    PRINT LPAREN expression RPAREN {
        printf(">> PRINT: %f\n", $3);
        $$ = 0;
    }
    ;

expression:
    expression PLUS expression { $$ = $1 + $3; }
    | expression MINUS expression { $$ = $1 - $3; }
    | expression MUL expression { $$ = $1 * $3; }
    | expression DIV expression {
        if ($3 == 0) {
            yyerror("Sifira bolme hatasi");
            $$ = 0;
        } else {
            $$ = $1 / $3;
        }
    }
    | expression MOD expression { $$ = fmod($1, $3); }
    | expression POW expression { $$ = pow($1, $3); }
    | expression EQ expression { $$ = $1 == $3; }
    | expression NEQ expression { $$ = $1 != $3; }
    | expression LT expression { $$ = $1 < $3; }
    | expression GT expression { $$ = $1 > $3; }
    | expression LEQ expression { $$ = $1 <= $3; }
    | expression GEQ expression { $$ = $1 >= $3; }
    | expression AND expression { $$ = $1 && $3; }
    | expression OR expression { $$ = $1 || $3; }
    | NOT expression { $$ = !$2; }
    | MINUS expression %prec UMINUS { $$ = -$2; }
    | LPAREN expression RPAREN { $$ = $2; }
    | NUMBER { $$ = $1; }
    | IDENTIFIER { $$ = get_var_value($1); free($1); }
    ;

%%

int main(int argc, char **argv) {
    setlocale(LC_ALL, "en_US.UTF-8");

    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Dosya acilamadi: %s\n", argv[1]);
            return 1;
        }
    } else {
        yyin = stdin;
    }

    printf("Parser baslatiliyor...\n");
    int result = yyparse();

    if (had_error || result != 0) {
        printf("\n[SONUC] Kod analizi BASARISIZ - %d hata bulundu\n", had_error);
    } else {
        printf("\n[SONUC] Kod gramer kurallarina UYGUN\n");
    }

    Var *v = var_list, *tmp;
    while (v) {
        tmp = v;
        v = v->next;
        free(tmp->name);
        free(tmp);
    }
    var_list = NULL;

    if (yyin != stdin) fclose(yyin);
    return had_error;
}