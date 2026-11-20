#lang eopl
;Autores: Nombre1 Codigo1, Nombre2 Codigo2

#|
  Taller 3 — Cauca con referencias y tipos.
  TAD ambiente y valor procedimiento.

  Las dos definiciones van en el mismo módulo porque se nombran entre
  sí: el campo del ambiente dentro de una clausura pide ambiente?, y
  apply-env construye una clausura cuando resuelve un nombre ligado por
  letrec. Separarlas deja uno de los dos campos sin predicado.

  Los valores denotados son los mismos que los expresados (números,
  booleanos, procedimientos y referencias), así que el ambiente liga cada
  identificador directamente a su valor: let no reserva celdas, y por eso
  `let otro = celda` comparte la celda.

  Las anotaciones de tipo las ignora el intérprete: la clausura no guarda
  los tipos de los parámetros.

  El cuerpo de una clausura es una expresion?, que viene de sintaxis.rkt.
|#

(require "sintaxis.rkt")

;; procval
;; Valor procedimiento. La clausura guarda los parámetros, el cuerpo y el
;; ambiente donde se creó.
(define-datatype procval procval?
  (clausura
   (ids (list-of symbol?))
   (body expresion?)
   (env ambiente?)))

;; Ambiente de valores con tres variantes:
;;   ambiente-vacio      sin ligaduras
;;   ambiente-extendido  ids ligados a vals sobre un ambiente
;;   ambiente-recursivo  procedimientos de un letrec: nombres, parámetros y
;;                       cuerpos de cada uno, sobre el ambiente exterior

(define-datatype ambiente ambiente?
  (ambiente-vacio)
  (ambiente-extendido
   (ids (list-of symbol?))
   (vals list?)
   (env ambiente?))
  (ambiente-recursivo
   (proc-names (list-of symbol?))
   (idss (list-of (list-of symbol?)))
   (bodies (list-of expresion?))
   (env ambiente?)))

;; posicion-de : symbol x lista de symbol -> integer | #f
;; Retorna el índice (desde 0) de la primera aparición del identificador en
;; la lista, o #f si no está.
(define posicion-de
  (lambda (id ids)
    (letrec ((buscar
              (lambda (lst i)
                (cond ((null? lst) #f)
                      ((eqv? (car lst) id) i)
                      (else (buscar (cdr lst) (+ i 1)))))))
      (buscar ids 0))))

;; apply-env : ambiente x symbol -> valor
;; Busca la ligadura del identificador. Sobre el ambiente vacío levanta
;; eopl:error; sobre el recursivo construye la clausura del procedimiento.
(define apply-env
  (lambda (env id)
    (cases ambiente env
      (ambiente-vacio ()
        (eopl:error 'apply-env "Identificador no ligado: s" id))
      (ambiente-extendido (ids vals saved-env)
        (let ((pos (posicion-de id ids)))
          (if pos
              (list-ref vals pos)
              (apply-env saved-env id))))
      (ambiente-recursivo (proc-names idss bodies saved-env)
        (let ((pos (posicion-de id proc-names)))
          (if pos
              (clausura (list-ref idss pos) (list-ref bodies pos) env)
              (apply-env saved-env id)))))))

;; ambiente-inicial : -> ambiente
;; n = 10, m = 3, p = 7, q = 2, r = 5.
(define ambiente-inicial
  (lambda ()
    (ambiente-extendido '(n m p q r) '(10 3 7 2 5) (ambiente-vacio))))

(provide (all-defined-out))