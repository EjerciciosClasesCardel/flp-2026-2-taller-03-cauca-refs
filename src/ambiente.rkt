#lang eopl
;Autores: Juan Sebastian Navarrete 202459562, Samuel Garcia Parra 202459476

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
;; cualquier-valor? : any -> boolean
;; Predicado que acepta cualquier valor. El ambiente guarda números,
;; booleanos, procvals y referencias; la referencia vive en almacen.rkt,
;; que este módulo no requiere, así que no podemos nombrarla aquí.
(define cualquier-valor?
  (lambda (v) #t))

(define-datatype ambiente ambiente?
  (ambiente-vacio)
  (ambiente-extendido
   (ids  (list-of symbol?))
   (vals (list-of cualquier-valor?))
   (env  ambiente?))
  (ambiente-recursivo
   (proc-names (list-of symbol?))
   (idss       (list-of (list-of symbol?)))
   (bodies     (list-of expresion?))
   (env        ambiente?)))

(define-datatype procval procval?
  (closure
   (ids  (list-of symbol?))
   (body expresion?)
   (env  ambiente?)))

;; posicion : symbol x lista -> entero o #f
;; Índice de id en lst, o #f si no está.
(define posicion
  (lambda (id lst)
    (letrec ((buscar (lambda (l i)
                       (cond ((null? l) #f)
                             ((eqv? (car l) id) i)
                             (else (buscar (cdr l) (+ i 1)))))))
      (buscar lst 0))))

;; apply-env : ambiente x symbol -> valor
;; Busca la ligadura del identificador. Sobre el ambiente vacío levanta
;; eopl:error; sobre el recursivo construye la clausura del procedimiento.
(define apply-env
  (lambda (env id)
    (cases ambiente env
      (ambiente-vacio ()
        (eopl:error 'apply-env "Variable no ligada: ~s" id))
      (ambiente-extendido (ids vals env-ext)
        (let ((pos (posicion id ids)))
          (if pos
              (list-ref vals pos)
              (apply-env env-ext id))))
      (ambiente-recursivo (proc-names idss bodies env-ext)
        (let ((pos (posicion id proc-names)))
          (if pos
              (closure (list-ref idss pos) (list-ref bodies pos) env)
              (apply-env env-ext id)))))))

;; ambiente-inicial : -> ambiente
;; El del enunciado: n = 10, m = 3, p = 7, q = 2, r = 5.
(define ambiente-inicial
  (lambda ()
    (ambiente-extendido '(n m p q r)
                        '(10 3 7 2 5)
                        (ambiente-vacio))))

(provide (all-defined-out))