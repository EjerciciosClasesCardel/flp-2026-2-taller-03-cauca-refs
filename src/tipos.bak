#lang eopl
;Autores: Nombre1 Codigo1, Nombre2 Codigo2

#|
  Taller 3 — Cauca con referencias y tipos.
  El tipo y el ambiente de tipos (Parte 3).

  El datatype tipo lo genera la gramática, porque las anotaciones se
  escriben dentro del programa. Aquí van la comparación estructural de
  dos tipos, el texto con que un tipo aparece en los mensajes de error y
  el ambiente de tipos.

  Falta el datatype del ambiente de tipos, con las mismas tres variantes
  del ambiente de valores: tenv-vacio, tenv-extendido y tenv-recursivo.
  La recursiva guarda el tipo declarado de cada procedimiento, que es lo
  que permite chequear el cuerpo de un letrec sin evaluarlo.

  El módulo requiere sintaxis.rkt y ningún otro del intérprete.
|#

(require "sintaxis.rkt")

;; tipo->texto : tipo -> string
;; La forma en que los tipos aparecen en los mensajes de error:
;; "num", "bool", "refto(num)", "(num * num -> bool)".
(define tipo->texto
  (lambda (t)
    (eopl:error 'tipo->texto "Sin implementar")))

;; tipos-iguales? : tipo x tipo -> boolean
;; Compara dos tipos por estructura, no por identidad.
(define tipos-iguales?
  (lambda (t1 t2)
    (eopl:error 'tipos-iguales? "Sin implementar")))

;; apply-tenv : tenv x symbol -> tipo
;; Busca el tipo del identificador. Si no está declarado levanta
;; eopl:error con «Variable no declarada: <x>».
(define apply-tenv
  (lambda (amb id)
    (eopl:error 'apply-tenv "Sin implementar")))

;; tenv-inicial : -> tenv
;; Declara como num las cinco variables del ambiente inicial.
(define tenv-inicial
  (lambda ()
    (eopl:error 'tenv-inicial "Sin implementar")))

;; tipo-de-primitiva : primitiva x lista de tipos -> tipo
;; Lo que cada primitiva exige de sus argumentos y lo que retorna: las
;; aritméticas retornan num; las relacionales, las booleanas y entre
;; retornan bool.
(define tipo-de-primitiva
  (lambda (prim tipos)
    (eopl:error 'tipo-de-primitiva "Sin implementar")))

(provide (all-defined-out))
