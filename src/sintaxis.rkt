#lang eopl
;Autores: Oliver De Jesus Arboleda Baez 2459684, Maria Fernanda Betancourt Montoya 2459510, Kevin Andres Rosero Romo 2459554

#|
  Taller 3 — Cauca con referencias y tipos.
  Especificación léxica y gramatical.

  Aquí van los tokens, las producciones con las anotaciones de tipo, los
  datatypes que SLLGEN genera a partir de ellas (programa, expresion,
  tipo, primitiva), el scanner y el parser.

  El módulo no requiere ningún otro: lo requieren los cinco del
  intérprete y los dos del chequeador, de modo que la gramática se
  escribe una sola vez y los dos lados recorren el mismo árbol.

  La gramática es la del Taller 2 con los dos cambios de la sección
  «Especificación de Cauca con referencias y tipos» del enunciado:
    1. expresiones nuevas: newref, deref, setref, swap, begin, applyref
    2. anotaciones de tipo en proc y letrec (el intérprete las ignora,
       solo las usa el chequeador)
|#

;;; 1. Especificación léxica
;;; ==========================================================
;; Espacios en blanco y comentarios (// hasta fin de línea) se ignoran.
;; identificador: letra seguida de letras, dígitos, "_" o "?"
;; numero: entero o flotante, positivo o negativo

(define especificacion-lexica
  '((espacio-blanco (whitespace) skip)
    (comentario ("//" (arbno (not #\newline))) skip)
    (identificador (letter (arbno (or letter digit "_" "?"))) symbol)
    (numero (digit (arbno digit)) number)
    (numero ("-" digit (arbno digit)) number)
    (numero (digit (arbno digit) "." digit (arbno digit)) number)
    (numero ("-" digit (arbno digit) "." digit (arbno digit)) number)))


;;; 2. Especificación gramatical
;;; ==========================================================
;; Cuatro no terminales: programa, expresion, tipo y primitiva.

(define especificacion-gramatical
  '((programa (expresion) a-program)

    
    (expresion (numero) lit-exp)
    (expresion (identificador) var-exp)
    (expresion ("true") true-exp)
    (expresion ("false") false-exp)
    (expresion (primitiva "(" (separated-list expresion ",") ")") prim-exp)
    (expresion ("if" expresion "then" expresion "else" expresion "end") if-exp)
    (expresion ("let" (arbno identificador "=" expresion) "in" expresion "end")
               let-exp)
    (expresion ("apply" expresion "(" (separated-list expresion ",") ")")
               app-exp)
    ;; SLLGEN representa las ramas con arbno para conservar los cuatro campos
    ;; de case-exp; parser valida después que haya al menos una rama.
    (expresion ("case" expresion
                (arbno "of" numero "=>" expresion)
                "otherwise" "=>" expresion "end")
               case-exp)

    ;; ---------- Ligadores anotados con tipo
    ;; proc-exp(ids, tipos, body)
    (expresion ("proc" "(" (separated-list identificador ":" tipo ",") ")"
                expresion "end")
               proc-exp)
    ;; letrec-exp(tipos-res, proc-names, idss, tipos-args, bodies, body)
    ;; El tipo que antecede al nombre es el tipo del resultado.
    (expresion ("letrec"
                (arbno tipo identificador
                       "(" (separated-list identificador ":" tipo ",") ")"
                       "=" expresion)
                "in" expresion "end")
               letrec-exp)

    ;; ---------- Parte 1: almacén 
    (expresion ("newref" "(" expresion ")") newref-exp)
    (expresion ("deref" "(" expresion ")") deref-exp)
    (expresion ("setref" "(" expresion "," expresion ")") setref-exp)
    (expresion ("swap" "(" expresion "," expresion ")") swap-exp)
    (expresion ("begin" expresion (arbno ";" expresion) "end") begin-exp)

    ;; ---------- Parte 2: paso por referencia 
    (expresion ("applyref" expresion "(" (separated-list identificador ",") ")")
               app-ref-exp)

    ;; ---------- Tipos
    (tipo ("num") num-tipo)
    (tipo ("bool") bool-tipo)
    (tipo ("refto" "(" tipo ")") ref-tipo)
    (tipo ("(" (separated-list tipo "*") "->" tipo ")") proc-tipo)

    (primitiva ("+") sum-prim)
    (primitiva ("-") minus-prim)
    (primitiva ("*") mult-prim)
    (primitiva ("/") div-prim)
    (primitiva ("add1") add-prim)
    (primitiva ("sub1") sub-prim)
    (primitiva (">") mayor-prim)
    (primitiva (">=") mayorigual-prim)
    (primitiva ("<") menor-prim)
    (primitiva ("<=") menorigual-prim)
    (primitiva ("==") igual-prim)
    (primitiva ("not") not-prim)
    (primitiva ("and") and-prim)
    (primitiva ("or") or-prim)
    (primitiva ("abs") abs-prim)
    (primitiva ("mcd") mcd-prim)
    (primitiva ("mcm") mcm-prim)
    (primitiva ("promedio") promedio-prim)
    (primitiva ("xor") xor-prim)
    (primitiva ("implica") implica-prim)
    (primitiva ("entre") entre-prim)))


;;; 3. Datatypes, scanner y parser
;;; ==========================================================

(sllgen:make-define-datatypes especificacion-lexica especificacion-gramatical)

;; mostrar-datatypes : -> void
;; Imprime los define-datatype que SLLGEN generó a partir de la gramática.
(define mostrar-datatypes
  (lambda () (sllgen:list-define-datatypes especificacion-lexica especificacion-gramatical)))

;; scanner : string -> lista de tokens
;; Convierte el texto de un programa en la lista de sus tokens.
(define scanner
  (sllgen:make-string-scanner especificacion-lexica especificacion-gramatical))

;; parser-sllgen : string -> programa
;; Convierte el texto de un programa en su AST usando el parser de SLLGEN.
(define parser-sllgen
  (sllgen:make-string-parser especificacion-lexica especificacion-gramatical))

;; case-con-ramas? : expresion -> boolean
;; Recorre una expresión completa y verifica que cada case tenga al menos una
;; rama of; así también se rechazan los case inválidos que estén anidados.
(define case-con-ramas?
  (lambda (exp)
    (letrec ((lista-valida?
              (lambda (exps)
                (if (null? exps)
                    #t
                    (and (expresion-valida? (car exps))
                         (lista-valida? (cdr exps))))))
             (expresion-valida?
              (lambda (una-exp)
                (cases expresion una-exp
                  (lit-exp (dato) #t)
                  (var-exp (id) #t)
                  (true-exp () #t)
                  (false-exp () #t)
                  (prim-exp (prim rands)
                    (lista-valida? rands))
                  (if-exp (test-exp true-exp false-exp)
                    (and (expresion-valida? test-exp)
                         (expresion-valida? true-exp)
                         (expresion-valida? false-exp)))
                  (let-exp (ids rands body)
                    (and (lista-valida? rands)
                         (expresion-valida? body)))
                  (proc-exp (ids tipos body)
                    (expresion-valida? body))
                  (app-exp (rator rands)
                    (and (expresion-valida? rator)
                         (lista-valida? rands)))
                  (letrec-exp (tipos-res proc-names idss tipos-args bodies body)
                    (and (lista-valida? bodies)
                         (expresion-valida? body)))
                  (case-exp (control valores acciones default)
                    (and (not (null? valores))
                         (expresion-valida? control)
                         (lista-valida? acciones)
                         (expresion-valida? default)))
                  (newref-exp (exp1)
                    (expresion-valida? exp1))
                  (deref-exp (exp1)
                    (expresion-valida? exp1))
                  (setref-exp (ref exp1)
                    (and (expresion-valida? ref)
                         (expresion-valida? exp1)))
                  (swap-exp (ref1 ref2)
                    (and (expresion-valida? ref1)
                         (expresion-valida? ref2)))
                  (begin-exp (exp1 exps)
                    (and (expresion-valida? exp1)
                         (lista-valida? exps)))
                  (app-ref-exp (rator ids)
                    (expresion-valida? rator))))))
      (expresion-valida? exp))))

;; parser : string -> programa
;; Convierte el texto de un programa en su AST y rechaza los case sin ramas
;; of, que no pertenecen al lenguaje Cauca.
(define parser
  (lambda (texto)
    (let ((ast (parser-sllgen texto)))
      (cases programa ast
        (a-program (exp)
          (if (case-con-ramas? exp)
              ast
              (eopl:error 'parser
                          "el case debe tener al menos una rama of")))))))

(provide (all-defined-out))
