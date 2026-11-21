#lang eopl
;Autores: Nombre1 Codigo1, Nombre2 Codigo2

#|
  Taller 3 — Cauca con referencias y tipos.
  Evaluación y punto de entrada.

  evaluar-expresion recorre el árbol con cases y apply-procedure liga
  los parámetros de una clausura antes de evaluar su cuerpo. Las dos se
  llaman mutuamente, así que comparten módulo, y con ellas la copia por
  valor de los argumentos, que describe cómo entra un valor a apply y no
  cómo está hecha la clausura.

  El evaluador ignora las anotaciones de tipo: las lee el parser, quedan
  en el árbol y solo las usa el chequeador.

  Las cláusulas de newref-exp, deref-exp, setref-exp, swap-exp y
  begin-exp van en evaluar-expresion, junto a las demás variantes.
  Las tres que verifican con referencia? antes de tocar el almacén son
  deref-exp, setref-exp y swap-exp; si el valor no es una referencia,
  levantan eopl:error.
|#

(require "sintaxis.rkt")
(require "almacen.rkt")
(require "ambiente.rkt")
(require "primitivas.rkt")

;; copia-por-valor : valor -> valor
;; El paso por valor entrega una copia del argumento. Para un número, un
;; booleano o un procedimiento la copia es el mismo valor; para una
;; referencia es una celda nueva con el mismo contenido. applyref no usa
;; esta función: ahí el parámetro queda ligado a la misma celda.
(define copia-por-valor
  (lambda (val)
    (eopl:error 'copia-por-valor "Sin implementar")))

;; apply-procedure : procval x lista de valores -> valor
;; Verifica la aridad y evalúa el cuerpo en el ambiente de la clausura
;; extendido con los parámetros.
(define apply-procedure
  (lambda (proc args)
    (eopl:error 'apply-procedure "Sin implementar")))

;; evaluar-expresion : expresion x ambiente -> valor
;; Una cláusula por variante de la gramática. La condición de un if se
;; verifica con boolean? antes de ramificar.
(define evaluar-expresion
  (lambda (exp env)
    (eopl:error 'evaluar-expresion "Sin implementar")))

;; evaluar-programa : programa -> valor
;; Deja el almacén vacío y evalúa el cuerpo en el ambiente inicial.
(define evaluar-programa
  (lambda (pgm)
    (eopl:error 'evaluar-programa "Sin implementar")))

;; interpretar : string -> valor
;; Analiza el texto con el parser y lo evalúa.
(define interpretar
  (lambda (texto)
    (eopl:error 'interpretar "Sin implementar")))

;; interpretador : -> void
;; El ciclo de lectura, con sllgen:make-rep-loop sobre evaluar-programa.
(define interpretador
  (lambda ()
    (eopl:error 'interpretador "Sin implementar")))

(provide (all-defined-out))
