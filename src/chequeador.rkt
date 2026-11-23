#lang eopl
;Autores: Oliver De Jesus Arboleda Baez 2459684, Maria Fernanda Betancourt Montoya 2459510, Kevin Andres Rosero Romo 2459554

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
    (letrec ((tipos-de
              (lambda (exps)
                (map (lambda (una-exp) (type-of una-exp amb)) exps)))
             (verificar-argumentos
              (lambda (esperados recibidos posicion)
                (if (null? esperados)
                    #t
                    (if (tipos-iguales? (car esperados) (car recibidos))
                        (verificar-argumentos (cdr esperados)
                                               (cdr recibidos)
                                               (+ posicion 1))
                        (eopl:error 'type-of
                                    "El argumento ~s debe ser ~a, se encontro ~a"
                                    posicion
                                    (tipo->texto (car esperados))
                                    (tipo->texto (car recibidos)))))))
             (todos-referencias?
              (lambda (tipos)
                (or (null? tipos)
                    (cases tipo (car tipos)
                      (ref-tipo (tipo-interno)
                        (todos-referencias? (cdr tipos)))
                      (else #f)))))
             (tipos-de-procedimientos
              (lambda (tipos-args tipos-res)
                (if (null? tipos-args)
                    '()
                    (cons (proc-tipo (car tipos-args) (car tipos-res))
                          (tipos-de-procedimientos (cdr tipos-args)
                                                  (cdr tipos-res))))))
             (verificar-cuerpos-letrec
              (lambda (nombres idss tipos-args tipos-res cuerpos amb-rec)
                (if (null? nombres)
                    #t
                    (let ((tipo-cuerpo
                           (type-of (car cuerpos)
                                    (tenv-extendido (car idss)
                                                    (car tipos-args)
                                                    amb-rec))))
                      (if (tipos-iguales? tipo-cuerpo (car tipos-res))
                          (verificar-cuerpos-letrec (cdr nombres)
                                                     (cdr idss)
                                                     (cdr tipos-args)
                                                     (cdr tipos-res)
                                                     (cdr cuerpos)
                                                     amb-rec)
                          (eopl:error 'type-of
                                      "El procedimiento ~s declara ~a y su cuerpo da ~a"
                                      (car nombres)
                                      (tipo->texto (car tipos-res))
                                      (tipo->texto tipo-cuerpo)))))))
             (ultimo
              (lambda (tipos)
                (if (null? (cdr tipos))
                    (car tipos)
                    (ultimo (cdr tipos)))))
             (verificar-ramas-case
              (lambda (tipos-ramas tipo-default)
                (if (null? tipos-ramas)
                    #t
                    (if (tipos-iguales? (car tipos-ramas) tipo-default)
                        (verificar-ramas-case (cdr tipos-ramas) tipo-default)
                        (eopl:error 'type-of
                                    "Las ramas del case deben coincidir: ~a vs ~a"
                                    (tipo->texto (car tipos-ramas))
                                    (tipo->texto tipo-default)))))))
      (cases expresion exp
        (lit-exp (dato) (num-tipo))
        (var-exp (id) (apply-tenv amb id))
        (true-exp () (bool-tipo))
        (false-exp () (bool-tipo))
        (prim-exp (prim rands)
          (tipo-de-primitiva prim (tipos-de rands)))
        (if-exp (test-exp true-exp false-exp)
          (let ((tipo-test (type-of test-exp amb)))
            (if (tipos-iguales? tipo-test (bool-tipo))
                (let ((tipo-true (type-of true-exp amb)))
                  (let ((tipo-false (type-of false-exp amb)))
                    (if (tipos-iguales? tipo-true tipo-false)
                        tipo-true
                        (eopl:error 'type-of
                                    "Las ramas del if deben coincidir: ~a vs ~a"
                                    (tipo->texto tipo-true)
                                    (tipo->texto tipo-false)))))
                (eopl:error 'type-of
                            "La condicion del if debe ser bool, se encontro ~a"
                            (tipo->texto tipo-test)))))
        (let-exp (ids rands body)
          (type-of body
                   (tenv-extendido ids (tipos-de rands) amb)))
        (proc-exp (ids tipos body)
          (proc-tipo tipos
                     (type-of body (tenv-extendido ids tipos amb))))
        (app-exp (rator rands)
          (let ((tipo-rator (type-of rator amb)))
            (cases tipo tipo-rator
              (proc-tipo (tipos-params tipo-res)
                (let ((tipos-rands (tipos-de rands)))
                  (if (= (length tipos-params) (length tipos-rands))
                      (begin
                        (verificar-argumentos tipos-params tipos-rands 1)
                        tipo-res)
                      (eopl:error 'type-of
                                  "El procedimiento espera ~s argumentos y recibio ~s"
                                  (length tipos-params)
                                  (length tipos-rands)))))
              (else
               (eopl:error 'type-of
                           "Se intento aplicar un valor de tipo ~a"
                           (tipo->texto tipo-rator))))))
        (letrec-exp (tipos-res proc-names idss tipos-args bodies body)
          (let ((tipos-procs (tipos-de-procedimientos tipos-args tipos-res)))
            (let ((amb-rec (tenv-recursivo proc-names tipos-procs amb)))
              (begin
                (verificar-cuerpos-letrec proc-names idss tipos-args tipos-res
                                           bodies amb-rec)
                (type-of body amb-rec)))))
        (case-exp (control valores acciones default)
          (let ((tipo-control (type-of control amb)))
            (if (tipos-iguales? tipo-control (num-tipo))
                (let ((tipo-default (type-of default amb)))
                  (let ((tipos-ramas (tipos-de acciones)))
                    (begin
                      (verificar-ramas-case tipos-ramas tipo-default)
                      tipo-default)))
                (eopl:error 'type-of
                            "La expresion de control de case debe ser num, se encontro ~a"
                            (tipo->texto tipo-control)))))
        (newref-exp (exp1)
          (ref-tipo (type-of exp1 amb)))
        (deref-exp (exp1)
          (let ((tipo-exp (type-of exp1 amb)))
            (cases tipo tipo-exp
              (ref-tipo (tipo-interno) tipo-interno)
              (else
               (eopl:error 'type-of
                           "deref espera refto(t), se encontro ~a"
                           (tipo->texto tipo-exp))))))
        (setref-exp (ref exp1)
          (let ((tipo-ref (type-of ref amb)))
            (let ((tipo-valor (type-of exp1 amb)))
              (cases tipo tipo-ref
                (ref-tipo (tipo-celda)
                  (if (tipos-iguales? tipo-celda tipo-valor)
                      (num-tipo)
                      (eopl:error 'type-of
                                  "La celda guarda ~a y se intento escribir ~a"
                                  (tipo->texto tipo-celda)
                                  (tipo->texto tipo-valor))))
                (else
                 (eopl:error 'type-of
                             "setref espera refto(t), se encontro ~a"
                             (tipo->texto tipo-ref)))))))
        (swap-exp (ref1 ref2)
          (let ((tipo-ref1 (type-of ref1 amb)))
            (let ((tipo-ref2 (type-of ref2 amb)))
              (cases tipo tipo-ref1
                (ref-tipo (tipo-celda1)
                  (cases tipo tipo-ref2
                    (ref-tipo (tipo-celda2)
                      (if (tipos-iguales? tipo-celda1 tipo-celda2)
                          tipo-celda1
                          (eopl:error 'type-of
                                      "swap exige referencias al mismo tipo")))
                    (else
                     (eopl:error 'type-of
                                 "swap espera refto(t), se encontro ~a"
                                 (tipo->texto tipo-ref2)))))
                (else
                 (eopl:error 'type-of
                             "swap espera refto(t), se encontro ~a"
                             (tipo->texto tipo-ref1)))))))
        (begin-exp (exp1 exps)
          (ultimo (tipos-de (cons exp1 exps))))
        (app-ref-exp (rator ids)
          (let ((tipo-rator (type-of rator amb)))
            (cases tipo tipo-rator
              (proc-tipo (tipos-params tipo-res)
                (let ((tipos-ids (map (lambda (id) (apply-tenv amb id)) ids)))
                  (if (todos-referencias? tipos-ids)
                      (if (= (length tipos-params) (length tipos-ids))
                          (begin
                            (verificar-argumentos tipos-params tipos-ids 1)
                            tipo-res)
                          (eopl:error 'type-of
                                      "El procedimiento espera ~s argumentos y recibio ~s"
                                      (length tipos-params)
                                      (length tipos-ids)))
                      (eopl:error 'type-of
                                  "El paso por referencia exige variables ligadas a referencias"))))
              (else
               (eopl:error 'type-of
                           "Se intento aplicar un valor de tipo ~a"
                           (tipo->texto tipo-rator))))))))))

;; type-of-program : programa -> tipo
;; Chequea el programa en el ambiente de tipos inicial.
(define type-of-program
  (lambda (pgm)
    (cases programa pgm
      (a-program (exp)
        (type-of exp (tenv-inicial))))))

;; tipo-de-texto : string -> string
;; Analiza el texto, lo chequea y describe el tipo resultante.
(define tipo-de-texto
  (lambda (texto)
    (tipo->texto (type-of-program (parser texto)))))

(provide (all-defined-out))
