#lang eopl
;Autores: Oliver De Jesus Arboleda Baez 2459684, Maria Fernanda Betancourt Montoya 2459510, Kevin Andres Rosero Romo 2459554

#|
  Taller 3 — Cauca con referencias y tipos.
  Primitivas del lenguaje.

  evaluar-primitiva recibe la primitiva del árbol y la lista de valores
  ya evaluados, revisa la cantidad y el tipo de los argumentos y produce
  el resultado. Solo necesita la gramática, no el evaluador.

  Las verificaciones de cantidad y de tipo van aquí, junto a la
  primitiva que las exige, y levantan eopl:error con un mensaje que
  nombre la primitiva.

  Los booleanos son #t y #f; los números, los de Racket. Una referencia
  nunca es un número ni un booleano, así que ninguna primitiva la acepta.
|#

(require "sintaxis.rkt")

;; nombre-primitiva : primitiva -> string
;; El símbolo con que la primitiva se escribe en Cauca; sirve para los
;; mensajes de error.
(define nombre-primitiva
  (lambda (prim)
    (cases primitiva prim
      (sum-prim () "+")
      (minus-prim () "-")
      (mult-prim () "*")
      (div-prim () "/")
      (add-prim () "add1")
      (sub-prim () "sub1")
      (mayor-prim () ">")
      (mayorigual-prim () ">=")
      (menor-prim () "<")
      (menorigual-prim () "<=")
      (igual-prim () "==")
      (not-prim () "not")
      (and-prim () "and")
      (or-prim () "or")
      (abs-prim () "abs")
      (mcd-prim () "mcd")
      (mcm-prim () "mcm")
      (promedio-prim () "promedio")
      (xor-prim () "xor")
      (implica-prim () "implica")
      (entre-prim () "entre"))))

;; todos? : (valor -> boolean) x lista -> boolean
;; Indica si todos los elementos de la lista cumplen el predicado.
(define todos?
  (lambda (pred lst)
    (or (null? lst)
        (and (pred (car lst))
             (todos? pred (cdr lst))))))

;; exigir-cantidad : string x lista x integer -> void
;; Verifica que haya exactamente n argumentos; si no, levanta eopl:error.
(define exigir-cantidad
  (lambda (nombre args n)
    (if (= (length args) n)
        #t
        (eopl:error 'evaluar-primitiva
                    "~a espera ~s argumentos y recibio ~s"
                    nombre n (length args)))))

;; exigir-minimo : string x lista x integer -> void
;; Verifica que haya al menos n argumentos; si no, levanta eopl:error.
(define exigir-minimo
  (lambda (nombre args n)
    (if (>= (length args) n)
        #t
        (eopl:error 'evaluar-primitiva
                    "~a espera al menos ~s argumentos y recibio ~s"
                    nombre n (length args)))))

;; exigir-numeros : string x lista -> void
;; Verifica que todos los argumentos sean números.
(define exigir-numeros
  (lambda (nombre args)
    (if (todos? number? args)
        #t
        (eopl:error 'evaluar-primitiva
                    "~a exige argumentos numericos, recibio ~s"
                    nombre args))))

;; exigir-booleanos : string x lista -> void
;; Verifica que todos los argumentos sean booleanos.
(define exigir-booleanos
  (lambda (nombre args)
    (if (todos? boolean? args)
        #t
        (eopl:error 'evaluar-primitiva
                    "~a exige argumentos booleanos, recibio ~s"
                    nombre args))))

;; exigir-enteros : string x lista -> void
;; Verifica que todos los argumentos sean números enteros.
(define exigir-enteros
  (lambda (nombre args)
    (if (todos? integer? args)
        #t
        (eopl:error 'evaluar-primitiva
                    "~a exige argumentos enteros, recibio ~s"
                    nombre args))))

;; plegar-izquierda : (valor x valor -> valor) x lista -> valor
;; Combina los elementos de izquierda a derecha: (f (f a1 a2) a3) ...
;; Exige una lista no vacía.
(define plegar-izquierda
  (lambda (f lst)
    (letrec ((plegar
              (lambda (acc resto)
                (if (null? resto)
                    acc
                    (plegar (f acc (car resto)) (cdr resto))))))
      (plegar (car lst) (cdr lst)))))

;; dividir : number x number -> number
;; División de Cauca: error si el divisor es cero; si el cociente no es
;; entero lo entrega como flotante.
(define dividir
  (lambda (a b)
    (if (= b 0)
        (eopl:error 'evaluar-primitiva "/ no puede dividir por cero")
        (let ((q (/ a b)))
          (if (integer? q) q (exact->inexact q))))))

;; mcd-de : integer x integer -> integer
;; Máximo común divisor (Euclides), siempre no negativo.
(define mcd-de
  (lambda (a b)
    (if (= b 0)
        (abs a)
        (mcd-de b (remainder a b)))))

;; mcm-de : integer x integer -> integer
;; Mínimo común múltiplo, no negativo; 0 si alguno de los dos es 0.
(define mcm-de
  (lambda (a b)
    (if (or (= a 0) (= b 0))
        0
        (quotient (abs (* a b)) (mcd-de a b)))))

;; evaluar-primitiva : primitiva x lista de valores -> valor
;; Una cláusula por primitiva de la gramática, con cases. Verifica la
;; cantidad y el tipo de los argumentos antes de calcular.
;;   + - * /         al menos 2 números, se combinan de izquierda a derecha
;;   add1 sub1 abs   1 número
;;   > >= < <= ==    2 números -> booleano
;;   not             1 booleano
;;   and or          al menos 2 booleanos
;;   xor implica     2 booleanos
;;   mcd mcm         2 enteros
;;   promedio        al menos 1 número
;;   entre           3 números (x, inferior, superior) -> booleano
(define evaluar-primitiva
  (lambda (prim args)
    (let ((nombre (nombre-primitiva prim)))
      (cases primitiva prim
        (sum-prim ()
          (exigir-minimo nombre args 2) (exigir-numeros nombre args)
          (plegar-izquierda + args))
        (minus-prim ()
          (exigir-minimo nombre args 2) (exigir-numeros nombre args)
          (plegar-izquierda - args))
        (mult-prim ()
          (exigir-minimo nombre args 2) (exigir-numeros nombre args)
          (plegar-izquierda * args))
        (div-prim ()
          (exigir-minimo nombre args 2) (exigir-numeros nombre args)
          (plegar-izquierda dividir args))
        (add-prim ()
          (exigir-cantidad nombre args 1) (exigir-numeros nombre args)
          (+ (car args) 1))
        (sub-prim ()
          (exigir-cantidad nombre args 1) (exigir-numeros nombre args)
          (- (car args) 1))
        (abs-prim ()
          (exigir-cantidad nombre args 1) (exigir-numeros nombre args)
          (abs (car args)))
        (mayor-prim ()
          (exigir-cantidad nombre args 2) (exigir-numeros nombre args)
          (> (car args) (cadr args)))
        (mayorigual-prim ()
          (exigir-cantidad nombre args 2) (exigir-numeros nombre args)
          (>= (car args) (cadr args)))
        (menor-prim ()
          (exigir-cantidad nombre args 2) (exigir-numeros nombre args)
          (< (car args) (cadr args)))
        (menorigual-prim ()
          (exigir-cantidad nombre args 2) (exigir-numeros nombre args)
          (<= (car args) (cadr args)))
        (igual-prim ()
          (exigir-cantidad nombre args 2) (exigir-numeros nombre args)
          (= (car args) (cadr args)))
        (not-prim ()
          (exigir-cantidad nombre args 1) (exigir-booleanos nombre args)
          (not (car args)))
        (and-prim ()
          (exigir-minimo nombre args 2) (exigir-booleanos nombre args)
          (todos? (lambda (b) b) args))
        (or-prim ()
          (exigir-minimo nombre args 2) (exigir-booleanos nombre args)
          (not (todos? not args)))
        (xor-prim ()
          (exigir-cantidad nombre args 2) (exigir-booleanos nombre args)
          (not (eqv? (car args) (cadr args))))
        (implica-prim ()
          (exigir-cantidad nombre args 2) (exigir-booleanos nombre args)
          (or (not (car args)) (cadr args)))
        (mcd-prim ()
          (exigir-cantidad nombre args 2) (exigir-enteros nombre args)
          (mcd-de (car args) (cadr args)))
        (mcm-prim ()
          (exigir-cantidad nombre args 2) (exigir-enteros nombre args)
          (mcm-de (car args) (cadr args)))
        (promedio-prim ()
          (exigir-minimo nombre args 1) (exigir-numeros nombre args)
          (dividir (plegar-izquierda + args) (length args)))
        (entre-prim ()
          (exigir-cantidad nombre args 3) (exigir-numeros nombre args)
          (and (<= (cadr args) (car args))
               (<= (car args) (caddr args))))))))

(provide (all-defined-out))
