#lang eopl
;Autores: Aura Maria Pelaez Luna 2459422, Valentina Valencia Lopez 2459626

#|
  Taller 3 — Cauca con referencias y tipos.
  TAD ambiente y valor procedimiento.

  Las dos definiciones van en el mismo módulo porque se nombran entre
  sí: el campo del ambiente dentro de una clausura pide ambiente?, y
  apply-env construye una clausura cuando resuelve un nombre ligado por
  letrec.

    ambiente: ambiente-vacio, ambiente-extendido, ambiente-recursivo
    procval:  cerradura(ids, body, env)

  El cuerpo de una clausura es una expresion?, que viene de sintaxis.rkt.
  Las anotaciones de tipo de proc y letrec no se guardan aquí: el
  intérprete las ignora.
|#

(require "sintaxis.rkt")

(define-datatype ambiente ambiente?
  (ambiente-vacio)
  (ambiente-extendido
   (ids (list-of symbol?))
   (valores list?)
   (env ambiente?))
  (ambiente-recursivo
   (proc-names (list-of symbol?))
   (idss list?)
   (bodies (list-of expresion?))
   (env ambiente?)))

(define-datatype procval procval?
  (cerradura
   (ids (list-of symbol?))
   (body expresion?)
   (env ambiente?)))

;; buscar-posicion : symbol x (list-of symbol) -> número o #f
;; El índice (desde 0) de id dentro de ids, o #f si no está.
(define buscar-posicion
  (lambda (id ids)
    (cond
      ((null? ids) #f)
      ((eqv? id (car ids)) 0)
      (else
       (let ((resto (buscar-posicion id (cdr ids))))
         (if resto (+ resto 1) #f))))))

;; apply-env : ambiente x symbol -> valor
;; Busca la ligadura del identificador respetando el shadowing. Sobre el
;; ambiente vacío levanta eopl:error; sobre el recursivo construye la
;; clausura del procedimiento con el propio ambiente recursivo.
(define apply-env
  (lambda (env id)
    (cases ambiente env
      (ambiente-vacio ()
        (eopl:error 'apply-env "La variable no esta ligada: ~s" id))
      (ambiente-extendido (ids valores env-padre)
        (let ((posicion (buscar-posicion id ids)))
          (if posicion
              (list-ref valores posicion)
              (apply-env env-padre id))))
      (ambiente-recursivo (proc-names idss bodies env-padre)
        (let ((posicion (buscar-posicion id proc-names)))
          (if posicion
              (cerradura (list-ref idss posicion)
                         (list-ref bodies posicion)
                         env)
              (apply-env env-padre id)))))))

;; ambiente-inicial : -> ambiente
;; El del enunciado: n = 10, m = 3, p = 7, q = 2, r = 5.
(define ambiente-inicial
  (lambda ()
    (ambiente-extendido '(n m p q r) '(10 3 7 2 5) (ambiente-vacio))))

(provide (all-defined-out))