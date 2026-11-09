#lang eopl
;Autores: Adriana Milena Noscue Dagua 2477336, Sebastian Cucalon Astorquiza 2477344
;Santiago Torres Rojas 2380301, Nicolle Camila Hoyos Puin 2380608

#|
  Taller 3 — Cauca con referencias y tipos.
  Especificación léxica y gramatical.

  Aquí van los tokens, las producciones con las anotaciones de tipo, los
  datatypes que SLLGEN genera a partir de ellas (programa, expresion,
  tipo, primitiva), el scanner y el parser.

  El módulo no requiere ningún otro: lo requieren los cinco del
  intérprete y los dos del chequeador, de modo que la gramática se
  escribe una sola vez y los dos lados recorren el mismo árbol.

  Lo que hay ahora es una producción por no terminal, lo mínimo para
  que los módulos carguen. La gramática completa es la del Taller 2 con
  los dos cambios de la sección «Especificación de Cauca con
  referencias y tipos» del enunciado.
|#

;;; ==========================================================
;;; 1. Especificación léxica
;;; ==========================================================
;; Los comentarios de línea, los identificadores y los números.

(define especificacion-lexica
  '((white-sp (whitespace) skip)
    (comentario ("//" (arbno (not #\newline))) skip)
    (identificador (letter (arbno (or letter digit "_" "?"))) symbol)
    (numero (digit (arbno digit)) number)))

;;; ==========================================================
;;; 2. Especificación gramatical
;;; ==========================================================
;; Cuatro no terminales: programa, expresion, tipo y primitiva.
;;
;; Faltan, con los nombres de constructor que fija el enunciado:
;;   - las expresiones del Taller 2: var-exp, true-exp, false-exp,
;;     if-exp, let-exp, proc-exp, app-exp, letrec-exp, case-exp
;;   - las de la Parte 1: newref-exp, deref-exp, setref-exp, swap-exp,
;;     begin-exp
;;   - la de la Parte 2: app-ref-exp
;;   - los tipos: num-tipo, bool-tipo, ref-tipo, proc-tipo
;;   - las primitivas del Taller 2
;;
;; proc-exp y letrec-exp llevan las anotaciones de tipo. El tipo que
;; antecede al nombre en letrec es el del resultado del procedimiento.

(define especificacion-gramatical
  '((programa (expresion) a-program)

    ;; Literales y Identificadores
    (expresion (numero) lit-exp)
    (expresion ("true") true-exp)
    (expresion ("false") false-exp)
    (expresion (identificador) var-exp)
    (expresion (primitiva "(" (separated-list expresion ",") ")") prim-exp)

    ;; Control de flujo
    (expresion ("if" expresion "then" expresion "else" expresion "end") if-exp)
    (expresion ("let" (arbno identificador "=" expresion) "in" expresion "end") let-exp)
    (expresion ("case" expresion "of" (arbno numero "=>" expresion) "else" expresion "end") case-exp)

    ;; Procedimientos
    (expresion ("proc" "(" (separated-list identificador ":" tipo ",") ")" expresion "end") proc-exp)
    (expresion ("apply" expresion "(" (separated-list expresion ",") ")") app-exp)
    (expresion ("applyref" expresion "(" (separated-list identificador ",") ")") app-ref-exp)
    (expresion ("letrec" (arbno tipo identificador "(" (separated-list identificador ":" tipo ",") ")" "=" expresion) "in" expresion "end") letrec-exp)

    ;; Expresiones de la Parte 1: El almacén
    (expresion ("newref" "(" expresion ")") newref-exp)
    (expresion ("deref" "(" expresion ")") deref-exp)
    (expresion ("setref" "(" expresion "," expresion ")") setref-exp)
    (expresion ("swap" "(" expresion "," expresion ")") swap-exp)
    (expresion ("begin" expresion (arbno ";" expresion) "end") begin-exp)
    
    ;; Gramática de Tipos (Sección 3.3)
    (tipo ("num") num-tipo)
    (tipo ("bool") bool-tipo)
    (tipo ("refto" "(" tipo ")") ref-tipo)
    (tipo ("(" (separated-list tipo "*") "->" tipo ")") proc-tipo)
    
    ;;Primitivas
    (primitiva ("+") sum-prim)
    (primitiva ("-") sub-prim)
    (primitiva ("*") mult-prim)
    (primitiva ("add1") add1-prim)
    (primitiva ("sub1") sub1-prim)
    (primitiva ("==") equal-prim)
    (primitiva (">") greater-prim)
    (primitiva (">=") greater-equal-prim)
    (primitiva ("<") less-prim)
    (primitiva ("<=") less-equal-prim)
    (primitiva ("and") and-prim)
    (primitiva ("or") or-prim)
    (primitiva ("not") not-prim)
    ))

;;; ==========================================================
;;; 3. Datatypes, scanner y parser
;;; ==========================================================

(sllgen:make-define-datatypes especificacion-lexica especificacion-gramatical)

;; mostrar-datatypes : -> void
;; Imprime los define-datatype que SLLGEN generó a partir de la gramática.
(define mostrar-datatypes
  (lambda () (sllgen:list-define-datatypes especificacion-lexica especificacion-gramatical)))

;; scanner : string -> lista de tokens
(define scanner
  (sllgen:make-string-scanner especificacion-lexica especificacion-gramatical))

;; parser : string -> programa
(define parser
  (sllgen:make-string-parser especificacion-lexica especificacion-gramatical))

(provide (all-defined-out))
