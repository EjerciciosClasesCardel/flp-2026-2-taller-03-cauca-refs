#lang eopl
;Autores: Nombre1 Codigo1, Nombre2 Codigo2

#|
  Taller 3 — Cauca con referencias y tipos.
  TAD ambiente y valor procedimiento.

  Las dos definiciones van en el mismo módulo porque se nombran entre
  sí: el campo del ambiente dentro de una clausura pide ambiente?, y
  apply-env construye una clausura cuando resuelve un nombre ligado por
  letrec. Separarlas deja uno de los dos campos sin predicado.

  Faltan los dos datatypes:
    - ambiente, con las variantes ambiente-vacio, ambiente-extendido y
      ambiente-recursivo
    - procval, con la variante de la clausura: los parámetros, el cuerpo
      y el ambiente donde se creó

  El cuerpo de una clausura es una expresion?, que viene de sintaxis.rkt.
|#

(require "sintaxis.rkt")

;; apply-env : ambiente x symbol -> valor
;; Busca la ligadura del identificador. Sobre el ambiente vacío levanta
;; eopl:error; sobre el recursivo construye la clausura del procedimiento.
(define apply-env
  (lambda (env id)
    (eopl:error 'apply-env "Sin implementar")))

;; ambiente-inicial : -> ambiente
;; El del enunciado: n = 10, m = 3, p = 7, q = 2, r = 5.
(define ambiente-inicial
  (lambda ()
    (eopl:error 'ambiente-inicial "Sin implementar")))

(provide (all-defined-out))
