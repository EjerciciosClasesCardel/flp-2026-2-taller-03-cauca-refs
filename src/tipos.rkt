#lang eopl
;Autores: Oliver De Jesus Arboleda Baez 2459684, Maria Fernanda Betancourt Montoya 2459510, Kevin Andres Rosero Romo 2459554

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

;; tenv
;; Ambiente de tipos. La variante recursiva liga cada nombre de un letrec
;; con el tipo completo de procedimiento declarado antes de revisar cuerpos.
(define-datatype tenv tenv?
  (tenv-vacio)
  (tenv-extendido
   (ids (list-of symbol?))
   (tipos (list-of tipo?))
   (ambiente tenv?))
  (tenv-recursivo
   (proc-names (list-of symbol?))
   (proc-tipos (list-of tipo?))
   (ambiente tenv?)))

;; tipo->texto : tipo -> string
;; La forma en que los tipos aparecen en los mensajes de error:
;; "num", "bool", "refto(num)", "(num * num -> bool)".
(define tipo->texto
  (lambda (t)
    (letrec ((lista->texto
              (lambda (tipos)
                (if (null? tipos)
                    ""
                    (if (null? (cdr tipos))
                        (tipo->texto (car tipos))
                        (string-append (tipo->texto (car tipos))
                                       " * "
                                       (lista->texto (cdr tipos))))))))
      (cases tipo t
        (num-tipo () "num")
        (bool-tipo () "bool")
        (ref-tipo (tipo-interno)
          (string-append "refto(" (tipo->texto tipo-interno) ")"))
        (proc-tipo (tipos-args tipo-res)
          (string-append "(" (lista->texto tipos-args) " -> "
                         (tipo->texto tipo-res) ")"))))))

;; tipos-iguales? : tipo x tipo -> boolean
;; Compara dos tipos por estructura, no por identidad.
(define tipos-iguales?
  (lambda (t1 t2)
    (letrec ((listas-iguales?
              (lambda (ts1 ts2)
                (cond ((null? ts1) (null? ts2))
                      ((null? ts2) #f)
                      ((tipos-iguales? (car ts1) (car ts2))
                       (listas-iguales? (cdr ts1) (cdr ts2)))
                      (else #f)))))
      (cases tipo t1
        (num-tipo ()
          (cases tipo t2
            (num-tipo () #t)
            (else #f)))
        (bool-tipo ()
          (cases tipo t2
            (bool-tipo () #t)
            (else #f)))
        (ref-tipo (tipo1)
          (cases tipo t2
            (ref-tipo (tipo2) (tipos-iguales? tipo1 tipo2))
            (else #f)))
        (proc-tipo (args1 res1)
          (cases tipo t2
            (proc-tipo (args2 res2)
              (and (listas-iguales? args1 args2)
                   (tipos-iguales? res1 res2)))
            (else #f)))))))

;; apply-tenv : tenv x symbol -> tipo
;; Busca el tipo del identificador. Si no está declarado levanta
;; eopl:error con «Variable no declarada: <x>».
(define apply-tenv
  (lambda (amb id)
    (letrec ((posicion-de
              (lambda (nombre nombres indice)
                (cond ((null? nombres) #f)
                      ((eqv? nombre (car nombres)) indice)
                      (else (posicion-de nombre (cdr nombres)
                                         (+ indice 1)))))))
      (cases tenv amb
        (tenv-vacio ()
          (eopl:error 'apply-tenv "Variable no declarada: ~s" id))
        (tenv-extendido (ids tipos ambiente)
          (let ((pos (posicion-de id ids 0)))
            (if pos
                (list-ref tipos pos)
                (apply-tenv ambiente id))))
        (tenv-recursivo (proc-names proc-tipos ambiente)
          (let ((pos (posicion-de id proc-names 0)))
            (if pos
                (list-ref proc-tipos pos)
                (apply-tenv ambiente id))))))))

;; tenv-inicial : -> tenv
;; Declara como num las cinco variables del ambiente inicial.
(define tenv-inicial
  (lambda ()
    (tenv-extendido '(n m p q r)
                    (list (num-tipo)
                          (num-tipo)
                          (num-tipo)
                          (num-tipo)
                          (num-tipo))
                    (tenv-vacio))))

;; tipo-de-primitiva : primitiva x lista de tipos -> tipo
;; Lo que cada primitiva exige de sus argumentos y lo que retorna: las
;; aritméticas retornan num; las relacionales, las booleanas y entre
;; retornan bool.
(define tipo-de-primitiva
  (lambda (prim tipos)
    (letrec ((todos-del-tipo?
              (lambda (tipos-recibidos tipo-esperado)
                (or (null? tipos-recibidos)
                    (and (tipos-iguales? (car tipos-recibidos) tipo-esperado)
                         (todos-del-tipo? (cdr tipos-recibidos)
                                           tipo-esperado)))))
             (exigir-cantidad
              (lambda (cantidad)
                (if (= (length tipos) cantidad)
                    #t
                    (eopl:error 'tipo-de-primitiva
                                "La primitiva espera ~s argumentos y recibio ~s"
                                cantidad (length tipos)))))
             (exigir-minimo
              (lambda (cantidad)
                (if (>= (length tipos) cantidad)
                    #t
                    (eopl:error 'tipo-de-primitiva
                                "La primitiva espera al menos ~s argumentos y recibio ~s"
                                cantidad (length tipos)))))
             (exigir-tipo
              (lambda (tipo-esperado)
                (if (todos-del-tipo? tipos tipo-esperado)
                    #t
                    (eopl:error 'tipo-de-primitiva
                                "La primitiva recibio argumentos de tipos incompatibles")))))
      (cases primitiva prim
        (sum-prim ()
          (exigir-minimo 2) (exigir-tipo (num-tipo)) (num-tipo))
        (minus-prim ()
          (exigir-minimo 2) (exigir-tipo (num-tipo)) (num-tipo))
        (mult-prim ()
          (exigir-minimo 2) (exigir-tipo (num-tipo)) (num-tipo))
        (div-prim ()
          (exigir-minimo 2) (exigir-tipo (num-tipo)) (num-tipo))
        (add-prim ()
          (exigir-cantidad 1) (exigir-tipo (num-tipo)) (num-tipo))
        (sub-prim ()
          (exigir-cantidad 1) (exigir-tipo (num-tipo)) (num-tipo))
        (abs-prim ()
          (exigir-cantidad 1) (exigir-tipo (num-tipo)) (num-tipo))
        (mayor-prim ()
          (exigir-cantidad 2) (exigir-tipo (num-tipo)) (bool-tipo))
        (mayorigual-prim ()
          (exigir-cantidad 2) (exigir-tipo (num-tipo)) (bool-tipo))
        (menor-prim ()
          (exigir-cantidad 2) (exigir-tipo (num-tipo)) (bool-tipo))
        (menorigual-prim ()
          (exigir-cantidad 2) (exigir-tipo (num-tipo)) (bool-tipo))
        (igual-prim ()
          (exigir-cantidad 2) (exigir-tipo (num-tipo)) (bool-tipo))
        (not-prim ()
          (exigir-cantidad 1) (exigir-tipo (bool-tipo)) (bool-tipo))
        (and-prim ()
          (exigir-minimo 2) (exigir-tipo (bool-tipo)) (bool-tipo))
        (or-prim ()
          (exigir-minimo 2) (exigir-tipo (bool-tipo)) (bool-tipo))
        (xor-prim ()
          (exigir-cantidad 2) (exigir-tipo (bool-tipo)) (bool-tipo))
        (implica-prim ()
          (exigir-cantidad 2) (exigir-tipo (bool-tipo)) (bool-tipo))
        (mcd-prim ()
          (exigir-cantidad 2) (exigir-tipo (num-tipo)) (num-tipo))
        (mcm-prim ()
          (exigir-cantidad 2) (exigir-tipo (num-tipo)) (num-tipo))
        (promedio-prim ()
          (exigir-minimo 1) (exigir-tipo (num-tipo)) (num-tipo))
        (entre-prim ()
          (exigir-cantidad 3) (exigir-tipo (num-tipo)) (bool-tipo))))))

(provide (all-defined-out))
