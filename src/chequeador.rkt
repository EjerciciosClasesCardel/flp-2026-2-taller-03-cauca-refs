#lang eopl
;Autores: Nombre1 Codigo1, Nombre2 Codigo2

#|
  Taller 3 — Cauca con referencias y tipos.
  Reglas de tipado y chequeo del programa (Parte 3).

  type-of recorre el árbol con cases sobre un ambiente de tipos y no
  evalúa nada: una regla por variante de expresión, tal como están
  escritas en el cuadro del enunciado.

  Los mensajes de error se distinguen uno de otro. Son los nueve del
  cuadro «Mensajes de error», con ese texto.

  El módulo requiere sintaxis.rkt y tipos.rkt, y ningún otro módulo del
  intérprete: el árbol que recorre es el que produjo el parser, con las
  anotaciones de tipo adentro.
|#

(require "sintaxis.rkt")
(require "tipos.rkt")

;; type-of : expresion x tenv -> tipo
;; El tipo de la expresión bajo el ambiente de tipos, o eopl:error con
;; el mensaje que explique el conflicto.
(define type-of
  (lambda (exp amb)
    (eopl:error 'type-of "Sin implementar")))

;; type-of-program : programa -> tipo
;; Chequea el programa en el ambiente de tipos inicial.
(define type-of-program
  (lambda (pgm)
    (eopl:error 'type-of-program "Sin implementar")))

;; tipo-de-texto : string -> string
;; Analiza el texto, lo chequea y describe el tipo resultante.
(define tipo-de-texto
  (lambda (texto)
    (eopl:error 'tipo-de-texto "Sin implementar")))

(provide (all-defined-out))
