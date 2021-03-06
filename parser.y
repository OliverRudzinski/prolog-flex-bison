%{
  #define _GNU_SOURCE
	#include <stdio.h>
  #include <stdlib.h>
  #include <stdbool.h>
  #include <string.h>
  #include "y.tab.h"

  typedef struct clause {
    char *name;
    int term_count;
    struct literal *next_literal;
    struct clause *next;
  } clause_t;

  typedef struct literal {
    char *text;
    struct literal *next_literal;
    struct symbol *next_symbol;
  } literal_t;

  typedef struct symbol {
    char * text;
    struct symbol *next_symbol;
  } symbol_t;

	int main(void);
  void add_clause();
  void add_literal();
  void add_symbol();
  void print_symboltable();
  char* concat(const char *s1, const char *s2);
  bool symbol_exists(char * symbol);
  void yyerror(char*);
	int yylex();

  clause_t * symbol_table;

%}

%union {
  char *ch;
}

%token <ch> atom variable numeral dot def com op cp ob cb vert is
%type <ch> FACT RULE TERM TERM_L OPERAND COMP ARITH LIST LITERAL LITERAL_L FUNCTION

%left <ch> lt lte st ste eq eqeq neq neqeq plus minus times divby

%start S_L

%%

S_L: S_L S	{ ; }
	| S	      { ; }
	;

S: FACT  { add_clause($1); }
	|	RULE { add_clause($1); }
	;

FACT:	LITERAL dot { asprintf(&$$, "%s %s", $1, $2); }
	;

RULE:	LITERAL def LITERAL_L dot { asprintf(&$$,"%s %s %s %s", $1, $2, $3, $4); }
	;

LITERAL: atom op TERM_L cp  { asprintf(&$$, "%s %s %s %s", $1, $2, $3, $4); add_literal($$); }
  | ARITH                   { $$ = $1; add_literal($1); }
  | COMP                    { $$ = $1; add_literal($1); }
	| atom                    { $$ = $1; add_literal($1); }
  | variable is OPERAND     { add_symbol($1); asprintf(&$$,"%s %s %s", $1, $2, $3); add_literal($$); }
	;

LITERAL_L: LITERAL com LITERAL_L  { asprintf(&$$, "%s %s %s", $1, $2, $3); }
	| LITERAL                       { $$ = $1; }
	;

TERM_L: TERM_L com TERM { asprintf(&$$, "%s %s %s", $1, $2, $3); }
	| TERM                { $$ = $1; }
	;

TERM: ARITH   { $$ = $1; }
  | FUNCTION  { $$ = $1; }
  | LIST      { $$ = $1; }
  | COMP      { $$ = $1; } 
  | atom      { $$ = $1; }
  | numeral   { $$ = $1; }
  ;

FUNCTION: atom op TERM_L cp { asprintf(&$$, "%s %s %s %s", $1, $2, $3, $4); }
  ;

ARITH: OPERAND plus OPERAND { asprintf(&$$, "%s %s %s", $1, $2, $3); }
  | OPERAND minus OPERAND   { asprintf(&$$, "%s %s %s", $1, $2, $3); }
  | OPERAND times OPERAND   { asprintf(&$$, "%s %s %s", $1, $2, $3); }
  | OPERAND divby OPERAND   { asprintf(&$$, "%s %s %s", $1, $2, $3); }
  | op ARITH cp             { asprintf(&$$, "%s %s %s", $1, $2, $3); }
  ;

COMP: OPERAND lt OPERAND  { asprintf(&$$, "%s %s %s", $1, $2, $3); }
  | OPERAND lte OPERAND   { asprintf(&$$, "%s %s %s", $1, $2, $3); }
  | OPERAND st OPERAND    { asprintf(&$$, "%s %s %s", $1, $2, $3); }
  | OPERAND ste OPERAND   { asprintf(&$$, "%s %s %s", $1, $2, $3); }
  | OPERAND eq OPERAND    { asprintf(&$$, "%s %s %s", $1, $2, $3); }
  | OPERAND eqeq OPERAND  { asprintf(&$$, "%s %s %s", $1, $2, $3); }
  | OPERAND neq OPERAND   { asprintf(&$$, "%s %s %s", $1, $2, $3); }
  | OPERAND neqeq OPERAND { asprintf(&$$, "%s %s %s", $1, $2, $3); }
  ; 

OPERAND: ARITH { $$ = $1; } 
  | variable   { $$ = $1; add_symbol($$); }
  | numeral    { $$ = $1; }
  ;

LIST:	ob TERM_L vert LIST cb  { asprintf(&$$, "%s %s %s %s %s", $1, $2, $3, $4, $5); }
	| ob TERM_L cb              { asprintf(&$$, "%s %s %s",$1, $2, $3); }
	|	ob cb                     { asprintf(&$$, "%s %s", $1, $2); }
	|	variable                  { add_symbol($$); }
  ;

%%

int main(void) {
  symbol_table = (clause_t *) malloc(sizeof(clause_t)); 	
  
  yyparse();
  print_symboltable();

  return 0;
}

void add_clause() {
  clause_t *old_clause = symbol_table;
  symbol_table = (clause_t *) malloc(sizeof(clause_t));
  symbol_table->next = old_clause;
}

bool symbol_exists(char * symbol) {
  if (symbol_table == NULL) return false;
  if (symbol_table->next_literal == NULL) return false;

  symbol_t *current_symbol = symbol_table->next_literal->next_symbol;
  while (current_symbol) {
    if (strcmp(current_symbol->text, symbol) == 0) return true;
    current_symbol = current_symbol->next_symbol;
  }
  return false;
}

void add_symbol(char* text) {
  if (symbol_exists(text)) return;

  if (symbol_table->next_literal == NULL) symbol_table->next_literal = (literal_t *) malloc(sizeof(literal_t));

  symbol_t *old_symbol = (symbol_t *) symbol_table->next_literal->next_symbol;
  symbol_t *new_symbol =  (symbol_t *)  malloc(sizeof(symbol_t)); 
  new_symbol->text = text;
  new_symbol->next_symbol = old_symbol;
  symbol_table->next_literal->next_symbol = new_symbol;
}

void add_literal(char* text) {
   if (symbol_table->next_literal) {
    // after creation of first literal by add_symbol 
    if (symbol_table->next_literal->text == NULL) {
        symbol_table->next_literal->text = malloc(255 * sizeof(char));
        if (text) strcpy(symbol_table->next_literal->text, text);
        literal_t *new_literal = (literal_t *) malloc(sizeof(literal_t));
        new_literal->next_literal = symbol_table->next_literal; 
        symbol_table->next_literal = new_literal;       
        return;
    }
  }
  literal_t *old_literal = (literal_t *) symbol_table->next_literal; // save current literal list pointer
  literal_t *new_literal = (literal_t *) malloc(sizeof(literal_t)); // allocate new list element
  
  new_literal->text = malloc(255 * sizeof(char));
  new_literal->next_literal =  old_literal;

  if (text) {
    strcpy(new_literal->text, text);
  } else {
    strcpy(new_literal->text, "error");
  }
  symbol_table->next_literal = new_literal;
}


char* concat(const char *s1, const char *s2)
{
    char *result = malloc(strlen(s1) + strlen(s2) + 1); // +1 for the null-terminator
    strcpy(result, s2);
    strcat(result, s1);
    return result;
}

void print_symboltable() {
  printf("########                  SYMBOL TABLE                  ########\n================================================================\n- Clause:\n");
  int counter = 1;
  char *str = "";
  char *clause_tmp = malloc(500*sizeof(char));
  char *symbol_tmp = malloc(500*sizeof(char));
  char *literal_tmp = malloc(500*sizeof(char));

  clause_t* current = symbol_table;

  while (current) {          
    literal_t * current_literal = current->next_literal;
    while (current_literal) {
      symbol_t * current_symbol = current_literal->next_symbol;
      while (current_symbol) {
        asprintf(&clause_tmp,"     └╴  %s\n",current_symbol->text);
        str=concat(str,clause_tmp);
        current_symbol=current_symbol->next_symbol;
      }

      if(current_literal->text) {
        asprintf(&clause_tmp,"  └╴ %s\n",current_literal->text);
        str = concat(str,clause_tmp);
      }
      
      current_literal = current_literal->next_literal;
    }

    if (current->next) str = concat(str,"----------------------------------------------------------------\n- Clause:\n");
      

    current = current->next;
    counter += 1;
  }

  int len = strlen(str);
  str[len-11] = '\0';

  printf("%s\n",str);
}

void yyerror(char *err) {
	printf("%s",err);
}
