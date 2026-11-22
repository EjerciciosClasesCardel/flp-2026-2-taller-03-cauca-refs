#lang eopl
;Autores: Aura Maria Pelaez Luna 2459422, Valentina Valencia Lopez 2459626

#|
  Taller 3 — Cauca con referencias y tipos.
  El tipo y el ambiente de tipos (Parte 3).

  El datatype tipo lo genera la gramática, porque las anotaciones se
  escriben dentro del programa. Aquí van la comparación estructural de
  dos tipos, el texto con que un tipo aparece en los mensajes de error y
  el ambiente de tipos, con las mismas tres variantes del ambiente de
  valores:

    tenv-vacio()
    tenv-extendido(ids, tipos, tenv)
    tenv-recursivo(proc-names, tipos-proc, tenv)

  La recursiva guarda el tipo declarado de cada procedimiento, que es lo
  que permite chequear el cuerpo de un letrec sin evaluarlo.

  El módulo requiere sintaxis.rkt y ningún otro del intérprete.
|#

(require "sintaxis.rkt")

(define-datatype tenv tenv?
  (tenv-vacio)
  (tenv-extendido
   (ids (list-of symbol?))
   (tipos (list-of tipo?))
   (amb tenv?))
  (tenv-recursivo
   (proc-names (list-of symbol?))
   (tipos-proc (list-of tipo?))
   (amb tenv?)))

;; unir-textos : lista de string x string -> string
;; Pega los textos de la lista poniendo el separador entre cada par.
(define unir-textos
  (lambda (textos sep)
    (cond
      ((null? textos) "")
      ((null? (cdr textos)) (car textos))
      (else (string-append (car textos) sep (unir-textos (cdr textos) sep))))))

;; tipo->texto : tipo -> string
;; La forma en que los tipos aparecen en los mensajes de error:
;; "num", "bool", "refto(num)", "(num * num -> bool)".
(define tipo->texto
  (lambda (t)
    (cases tipo t
      (num-tipo () "num")
      (bool-tipo () "bool")
      (ref-tipo (interno) (string-append "refto(" (tipo->texto interno) ")"))
      (proc-tipo (args res)
        (string-append "("
                       (unir-textos (tipos->textos args) " * ")
                       (if (null? args) "-> " " -> ")
                       (tipo->texto res)
                       ")")))))

;; tipos->textos : lista de tipo -> lista de string
;; Aplica tipo->texto a cada tipo de la lista.
(define tipos->textos
  (lambda (ts)
    (if (null? ts)
        '()
        (cons (tipo->texto (car ts)) (tipos->textos (cdr ts))))))

;; tipos-iguales? : tipo x tipo -> boolean
;; Compara dos tipos por estructura, no por identidad.
(define tipos-iguales?
  (lambda (t1 t2)
    (cases tipo t1
      (num-tipo ()
        (cases tipo t2 (num-tipo () #t) (else #f)))
      (bool-tipo ()
        (cases tipo t2 (bool-tipo () #t) (else #f)))
      (ref-tipo (i1)
        (cases tipo t2
          (ref-tipo (i2) (tipos-iguales? i1 i2))
          (else #f)))
      (proc-tipo (args1 res1)
        (cases tipo t2
          (proc-tipo (args2 res2)
            (and (listas-de-tipos-iguales? args1 args2)
                 (tipos-iguales? res1 res2)))
          (else #f))))))

;; listas-de-tipos-iguales? : lista de tipo x lista de tipo -> boolean
;; #t si tienen la misma longitud y son iguales posición a posición.
(define listas-de-tipos-iguales?
  (lambda (ts1 ts2)
    (cond
      ((and (null? ts1) (null? ts2)) #t)
      ((or (null? ts1) (null? ts2)) #f)
      (else (and (tipos-iguales? (car ts1) (car ts2))
                 (listas-de-tipos-iguales? (cdr ts1) (cdr ts2)))))))

;; buscar-posicion-tenv : symbol x (list-of symbol) -> número o #f
;; El índice de id dentro de ids, o #f si no está.
(define buscar-posicion-tenv
  (lambda (id ids)
    (cond
      ((null? ids) #f)
      ((eqv? id (car ids)) 0)
      (else
       (let ((resto (buscar-posicion-tenv id (cdr ids))))
         (if resto (+ resto 1) #f))))))

;; apply-tenv : tenv x symbol -> tipo
;; Busca el tipo del identificador. Si no está declarado levanta
;; eopl:error con «Variable no declarada: <x>».
(define apply-tenv
  (lambda (amb id)
    (cases tenv amb
      (tenv-vacio ()
        (eopl:error 'apply-tenv "Variable no declarada: ~s" id))
      (tenv-extendido (ids tipos amb-padre)
        (let ((pos (buscar-posicion-tenv id ids)))
          (if pos
              (list-ref tipos pos)
              (apply-tenv amb-padre id))))
      (tenv-recursivo (proc-names tipos-proc amb-padre)
        (let ((pos (buscar-posicion-tenv id proc-names)))
          (if pos
              (list-ref tipos-proc pos)
              (apply-tenv amb-padre id)))))))

;; tenv-inicial : -> tenv
;; Declara como num las cinco variables del ambiente inicial.
(define tenv-inicial
  (lambda ()
    (tenv-extendido '(n m p q r)
                    (list (num-tipo) (num-tipo) (num-tipo) (num-tipo) (num-tipo))
                    (tenv-vacio))))

;; exigir-tipo-todos : lista de tipo x tipo x string -> void
;; Verifica que todos los tipos de la lista sean iguales al esperado; si
;; alguno no lo es, levanta eopl:error a nombre de la primitiva.
(define exigir-tipo-todos
  (lambda (tipos esperado nombre)
    (cond
      ((null? tipos) #t)
      ((tipos-iguales? (car tipos) esperado)
       (exigir-tipo-todos (cdr tipos) esperado nombre))
      (else
       (eopl:error 'tipo-de-primitiva
                   "La primitiva ~a exige argumentos de tipo ~a, se encontro ~a"
                   nombre (tipo->texto esperado) (tipo->texto (car tipos)))))))

;; exigir-aridad : lista x int x int-o-#f x string -> void
;; Verifica que la cantidad de argumentos esté entre minimo y maximo
;; (maximo #f significa sin tope); si no, levanta eopl:error.
(define exigir-aridad
  (lambda (tipos minimo maximo nombre)
    (let ((k (length tipos)))
      (if (or (< k minimo) (and maximo (> k maximo)))
          (eopl:error 'tipo-de-primitiva
                      "La primitiva ~a recibio ~a argumentos, esperaba ~a"
                      nombre k
                      (cond ((not maximo) (string-append "al menos " (number->string minimo)))
                            (else (number->string minimo))))
          #t))))

;; tipo-de-primitiva : primitiva x lista de tipos -> tipo
;; Lo que cada primitiva exige de sus argumentos y lo que retorna: las
;; aritméticas retornan num; las relacionales, las booleanas y entre
;; retornan bool.
(define tipo-de-primitiva
  (lambda (prim tipos)
    (let ((num (num-tipo)) (bool (bool-tipo)))
      (cases primitiva prim
        (sum-prim () (exigir-aridad tipos 2 #f "+")
                  (exigir-tipo-todos tipos num "+") num)
        (minus-prim () (exigir-aridad tipos 2 #f "-")
                   (exigir-tipo-todos tipos num "-") num)
        (mult-prim () (exigir-aridad tipos 2 #f "*")
                  (exigir-tipo-todos tipos num "*") num)
        (div-prim () (exigir-aridad tipos 2 #f "/")
                    (exigir-tipo-todos tipos num "/") num)
        (add-prim () (exigir-aridad tipos 1 1 "add1")
                  (exigir-tipo-todos tipos num "add1") num)
        (sub-prim () (exigir-aridad tipos 1 1 "sub1")
                  (exigir-tipo-todos tipos num "sub1") num)
        (abs-prim () (exigir-aridad tipos 1 1 "abs")
                  (exigir-tipo-todos tipos num "abs") num)
        (mcd-prim () (exigir-aridad tipos 2 #f "mcd")
                  (exigir-tipo-todos tipos num "mcd") num)
        (mcm-prim () (exigir-aridad tipos 2 #f "mcm")
                    (exigir-tipo-todos tipos num "mcm") num)
        (promedio-prim () (exigir-aridad tipos 1 #f "promedio")
                  (exigir-tipo-todos tipos num "promedio") num)
        (mayor-prim () (exigir-aridad tipos 2 2 ">")
                     (exigir-tipo-todos tipos num ">") bool)
        (mayorigual-prim () (exigir-aridad tipos 2 2 ">=")
                   (exigir-tipo-todos tipos num ">=") bool)
        (menor-prim () (exigir-aridad tipos 2 2 "<")
                  (exigir-tipo-todos tipos num "<") bool)
        (menorigual-prim () (exigir-aridad tipos 2 2 "<=")
                         (exigir-tipo-todos tipos num "<=") bool)
        (igual-prim () (exigir-aridad tipos 2 2 "==")
                    (exigir-tipo-todos tipos num "==") bool)
        (entre-prim () (exigir-aridad tipos 3 3 "entre")
                    (exigir-tipo-todos tipos num "entre") bool)
        (not-prim () (exigir-aridad tipos 1 1 "not")
                  (exigir-tipo-todos tipos bool "not") bool)
        (and-prim () (exigir-aridad tipos 2 2 "and")
                  (exigir-tipo-todos tipos bool "and") bool)
        (or-prim () (exigir-aridad tipos 2 2 "or")
                 (exigir-tipo-todos tipos bool "or") bool)
        (xor-prim () (exigir-aridad tipos 2 2 "xor")
                  (exigir-tipo-todos tipos bool "xor") bool)
        (implica-prim () (exigir-aridad tipos 2 2 "implica")
                      (exigir-tipo-todos tipos bool "implica") bool)))))

(provide (all-defined-out))