#lang eopl
;Autores: Juan Sebastian Navarrete 202459562, Samuel Garcia Parra 202459476

#|
  Taller 3 — Cauca con referencias y tipos.
  El tipo y el ambiente de tipos (Parte 3).

  El datatype tipo lo genera la gramática, porque las anotaciones se
  escriben dentro del programa. Aquí van la comparación estructural de
  dos tipos, el texto con que un tipo aparece en los mensajes de error y
  el ambiente de tipos.

  El ambiente de tipos tiene las mismas tres variantes del ambiente de
  valores: tenv-vacio, tenv-extendido y tenv-recursivo. La recursiva
  guarda el tipo declarado de cada procedimiento, que es lo que permite
  chequear el cuerpo de un letrec sin evaluarlo.

  El módulo requiere sintaxis.rkt y ningún otro del intérprete.
|#

(require "sintaxis.rkt")

;;; ==========================================================
;;; 1. Tipos: texto y comparación
;;; ==========================================================

;; unir-textos : lista de string x string -> string
;; Pega los textos de la lista poniendo sep entre cada par. Lista vacía
;; da la cadena vacía.
(define unir-textos
  (lambda (textos sep)
    (cond ((null? textos) "")
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
      (ref-tipo (s) (string-append "refto(" (tipo->texto s) ")"))
      (proc-tipo (args res)
        (string-append "("
                       (unir-textos (map tipo->texto args) " * ")
                       (if (null? args) "-> " " -> ")
                       (tipo->texto res)
                       ")")))))

;; tipos-iguales-lista? : lista de tipo x lista de tipo -> boolean
;; #t si las listas tienen la misma longitud y son iguales elemento a elemento.
(define tipos-iguales-lista?
  (lambda (l1 l2)
    (cond ((and (null? l1) (null? l2)) #t)
          ((or (null? l1) (null? l2)) #f)
          (else (and (tipos-iguales? (car l1) (car l2))
                     (tipos-iguales-lista? (cdr l1) (cdr l2)))))))

;; tipos-iguales? : tipo x tipo -> boolean
;; Compara dos tipos por estructura, no por identidad.
(define tipos-iguales?
  (lambda (t1 t2)
    (cases tipo t1
      (num-tipo ()
        (cases tipo t2 (num-tipo () #t) (else #f)))
      (bool-tipo ()
        (cases tipo t2 (bool-tipo () #t) (else #f)))
      (ref-tipo (s1)
        (cases tipo t2
          (ref-tipo (s2) (tipos-iguales? s1 s2))
          (else #f)))
      (proc-tipo (args1 res1)
        (cases tipo t2
          (proc-tipo (args2 res2)
            (and (tipos-iguales-lista? args1 args2)
                 (tipos-iguales? res1 res2)))
          (else #f))))))

;;; ==========================================================
;;; 2. Ambiente de tipos
;;; ==========================================================

(define-datatype tenv tenv?
  (tenv-vacio)
  (tenv-extendido
   (ids   (list-of symbol?))
   (tipos (list-of tipo?))
   (amb   tenv?))
  (tenv-recursivo
   (proc-names (list-of symbol?))
   (tipos-proc (list-of tipo?))
   (amb        tenv?)))

;; posicion-en : symbol x lista -> entero o #f
;; Índice de id en lst, o #f si no está.
(define posicion-en
  (lambda (id lst)
    (letrec ((buscar (lambda (l i)
                       (cond ((null? l) #f)
                             ((eqv? (car l) id) i)
                             (else (buscar (cdr l) (+ i 1)))))))
      (buscar lst 0))))

;; apply-tenv : tenv x symbol -> tipo
;; Busca el tipo del identificador. Si no está declarado levanta
;; eopl:error con «Variable no declarada: <x>».
(define apply-tenv
  (lambda (amb id)
    (cases tenv amb
      (tenv-vacio ()
        (eopl:error 'apply-tenv "Variable no declarada: ~a" id))
      (tenv-extendido (ids tipos amb-ext)
        (let ((pos (posicion-en id ids)))
          (if pos
              (list-ref tipos pos)
              (apply-tenv amb-ext id))))
      (tenv-recursivo (proc-names tipos-proc amb-ext)
        (let ((pos (posicion-en id proc-names)))
          (if pos
              (list-ref tipos-proc pos)
              (apply-tenv amb-ext id)))))))

;; tenv-inicial : -> tenv
;; Declara como num las cinco variables del ambiente inicial.
(define tenv-inicial
  (lambda ()
    (tenv-extendido '(n m p q r)
                    (list (num-tipo) (num-tipo) (num-tipo) (num-tipo) (num-tipo))
                    (tenv-vacio))))

;;; ==========================================================
;;; 3. Tipos de las primitivas
;;; ==========================================================

;; nombre-primitiva : primitiva -> symbol
;; El nombre con que la primitiva aparece en el texto del programa.
(define nombre-primitiva
  (lambda (prim)
    (cases primitiva prim
      (sum-prim () '+)
      (res-prim () '-)
      (mul-prim () '*)
      (add1-prim () 'add1)
      (sub1-prim () 'sub1)
      (mayor-prim () '>)
      (menor-prim () '<)
      (mayor-igual-prim () '>=)
      (menor-igual-prim () '<=)
      (igual-prim () '==)
      (and-prim () 'and)
      (or-prim () 'or)
      (not-prim () 'not)
      (entre-prim () 'entre))))

;; exigir-cantidad : symbol x lista x entero -> #t
;; Error si la primitiva no recibe exactamente n argumentos.
(define exigir-cantidad
  (lambda (nombre tipos n)
    (if (= (length tipos) n)
        #t
        (eopl:error 'type-of "La primitiva ~a espera ~a argumentos y recibio ~a"
                    nombre n (length tipos)))))

;; exigir-minimo : symbol x lista x entero -> #t
;; Error si la primitiva recibe menos de n argumentos.
(define exigir-minimo
  (lambda (nombre tipos n)
    (if (>= (length tipos) n)
        #t
        (eopl:error 'type-of "La primitiva ~a espera al menos ~a argumentos y recibio ~a"
                    nombre n (length tipos)))))

;; exigir-todos : symbol x lista de tipo x tipo -> #t
;; Error si algún argumento no tiene el tipo esperado. El mensaje dice
;; cuál argumento falló.
(define exigir-todos
  (lambda (nombre tipos esperado)
    (letrec ((revisar (lambda (ts i)
                        (cond ((null? ts) #t)
                              ((tipos-iguales? (car ts) esperado) (revisar (cdr ts) (+ i 1)))
                              (else
                               (eopl:error 'type-of
                                           "El argumento ~a de ~a debe ser ~a, se encontro ~a"
                                           i nombre
                                           (tipo->texto esperado)
                                           (tipo->texto (car ts))))))))
      (revisar tipos 1))))

;; tipo-de-primitiva : primitiva x lista de tipos -> tipo
;; Lo que cada primitiva exige de sus argumentos y lo que retorna: las
;; aritméticas retornan num; las relacionales, las booleanas y entre
;; retornan bool. La cantidad de argumentos es la misma que exige el
;; intérprete, para que el chequeador rechace lo que el intérprete rechazaría.
(define tipo-de-primitiva
  (lambda (prim tipos)
    (let ((nombre (nombre-primitiva prim)))
      (cases primitiva prim
        (sum-prim ()
          (exigir-minimo nombre tipos 2) (exigir-todos nombre tipos (num-tipo)) (num-tipo))
        (mul-prim ()
          (exigir-minimo nombre tipos 2) (exigir-todos nombre tipos (num-tipo)) (num-tipo))
        (res-prim ()
          (exigir-cantidad nombre tipos 2) (exigir-todos nombre tipos (num-tipo)) (num-tipo))
        (add1-prim ()
          (exigir-cantidad nombre tipos 1) (exigir-todos nombre tipos (num-tipo)) (num-tipo))
        (sub1-prim ()
          (exigir-cantidad nombre tipos 1) (exigir-todos nombre tipos (num-tipo)) (num-tipo))
        (mayor-prim ()
          (exigir-cantidad nombre tipos 2) (exigir-todos nombre tipos (num-tipo)) (bool-tipo))
        (menor-prim ()
          (exigir-cantidad nombre tipos 2) (exigir-todos nombre tipos (num-tipo)) (bool-tipo))
        (mayor-igual-prim ()
          (exigir-cantidad nombre tipos 2) (exigir-todos nombre tipos (num-tipo)) (bool-tipo))
        (menor-igual-prim ()
          (exigir-cantidad nombre tipos 2) (exigir-todos nombre tipos (num-tipo)) (bool-tipo))
        (igual-prim ()
          (exigir-cantidad nombre tipos 2) (exigir-todos nombre tipos (num-tipo)) (bool-tipo))
        (and-prim ()
          (exigir-minimo nombre tipos 2) (exigir-todos nombre tipos (bool-tipo)) (bool-tipo))
        (or-prim ()
          (exigir-minimo nombre tipos 2) (exigir-todos nombre tipos (bool-tipo)) (bool-tipo))
        (not-prim ()
          (exigir-cantidad nombre tipos 1) (exigir-todos nombre tipos (bool-tipo)) (bool-tipo))
        (entre-prim ()
          (exigir-cantidad nombre tipos 3) (exigir-todos nombre tipos (num-tipo)) (bool-tipo))))))

(provide (all-defined-out))