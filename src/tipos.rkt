#lang eopl
;Autores: Adriana Milena Noscue Dagua 2477336, Sebastian Cucalon Astorquiza 2477344
;Santiago Torres Rojas 2380301, Nicolle Camila Hoyos Puin 2380608

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

;;string-join : list-of-string x string -> string
;;proposito: une una lista de cadenas con un separador.
(define string-join
  (lambda (strs sep)
    (cond
      [(null? strs)""]
      [(null? (cdr strs)) (car strs)]
      [else (string-append (car strs) sep (string-join (cdr strs) sep ))])))

;; tipo->texto : tipo -> string
;; La forma en que los tipos aparecen en los mensajes de error:
;; "num", "bool", "refto(num)", "(num * num -> bool)".
(define tipo->texto
  (lambda (t)
    (cases tipo t
    (num-tipo () "num")
    (bool-tipo () "bool")
    (ref-tipo (t-elem)
              (string-append "refto(" (tipo->texto t-elem) ")"))
    (proc-tipo (arg-types res-type)
               (string-append "("
                              (string-join (map tipo->texto arg-types) " * ")
                              " -> "
                              (tipo->texto res-type)
                              ")")))))

;; tipos-iguales? : tipo x tipo -> boolean
;; Compara dos tipos por estructura, no por identidad.
(define tipos-iguales?
  (lambda (t1 t2)
    (equal? t1 t2)))

;;Datatype del ambiente de tipos

(define-datatype tenv tenv?
  (tenv-vacio)
  (tenv-extendido
   (ids (list-of symbol?))
   (tipos (list-of tipo?))
   (tenv-old tenv?))
  (tenv-recursivo
   (proc-names (list-of symbol?))
   (idss (list-of (list-of symbol?)))
   (tipos-args (list-of (list-of tipo?)))
   (tipos-res (list-of tipo?))
   (tenv-old tenv?)))

; extend-tenv : list-of-symbol x list-of-tipo x tenv -> tenv
(define extend-tenv
  (lambda (ids tipos env)
    (tenv-extendido ids tipos env)))

; extend-tenv-recursively : list-of-symbol x list-of-list-of-symbol x list-of-list-of-tipo x list-of-tipo x tenv -> tenv
(define extend-tenv-recursively
  (lambda (proc-names idss tipos-args tipos-res env)
    (tenv-recursivo proc-names idss tipos-args tipos-res env)))

; posicion : symbol x list-of-symbol -> integer or #f
(define posicion
  (lambda (sym list)
    (let loop ([l list] [idx 0])
      (cond
        [(null? l) #f]
        [(eqv? sym (car l)) idx]
        [else (loop (cdr l) (+ idx 1))]))))

;; apply-tenv : tenv x symbol -> tipo
;; Busca el tipo del identificador. Si no está declarado levanta
;; eopl:error con «Variable no declarada: <x>».
(define apply-tenv
  (lambda (amb id)
    (cases tenv amb
      (tenv-vacio ()
                  (eopl:error 'apply-tenv "Variable no declarada: ~a" id))
      (tenv-extendido (ids tipos tenv-old)
                  (let ([pos (posicion id ids)])
                    (if pos
                        (list-ref tipos pos)
                        (apply-tenv tenv-old id))))
      (tenv-recursivo (proc-names idss tipos-args tipos-res tenv-old)
                      (let ([pos (posicion id proc-names)])
                        (if pos
                            (proc-tipo (list-ref tipos-args pos) (list-ref tipos-res pos))
                            (apply-tenv tenv-old id)))))))

;; tenv-inicial : -> tenv
;; Declara como num las cinco variables del ambiente inicial.
(define tenv-inicial
  (lambda ()
    (extend-tenv '(n m p q r)
                 (list (num-tipo) (num-tipo) (num-tipo) (num-tipo) (num-tipo))
                 (tenv-vacio))))

;; tipo-de-primitiva : primitiva x lista de tipos -> tipo
;; Lo que cada primitiva exige de sus argumentos y lo que retorna: las
;; aritméticas retornan num; las relacionales, las booleanas y entre
;; retornan bool.

(define verificar-prims-num
  (lambda (tipos)
    (for-each (lambda (t)
                (unless (tipos-iguales? t (num-tipo))
                  (eopl:error 'tipo-de-primitiva "Las primitivas aritmeticas/relacionales esperan num")))
              tipos)))

(define verificar-prims-bool
  (lambda (tipos)
    (for-each (lambda (t)
                (unless (tipos-iguales? t (bool-tipo))
                  (eopl:error 'tipo-de-primitiva "Las primitivas booleanas esperan bool")))
              tipos)))


(define tipo-de-primitiva
  (lambda (prim tipos-args)
    (cases primitiva prim
      (sum-prim () (verificar-prims-num tipos-args) (num-tipo))
      (sub-prim () (verificar-prims-num tipos-args) (num-tipo))
      (mult-prim () (verificar-prims-num tipos-args) (num-tipo))
      (add1-prim () (verificar-prims-num tipos-args) (num-tipo))
      (sub1-prim () (verificar-prims-num tipos-args) (num-tipo))
      (equal-prim () (verificar-prims-num tipos-args) (bool-tipo))
      (greater-prim () (verificar-prims-num tipos-args) (bool-tipo))
      (greater-equal-prim () (verificar-prims-num tipos-args) (bool-tipo))
      (less-prim () (verificar-prims-num tipos-args) (bool-tipo))
      (less-equal-prim () (verificar-prims-num tipos-args) (bool-tipo))
      (and-prim () (verificar-prims-bool tipos-args) (bool-tipo))
      (or-prim () (verificar-prims-bool tipos-args) (bool-tipo))
      (not-prim () (verificar-prims-bool tipos-args) (bool-tipo)))))

(provide (all-defined-out))
