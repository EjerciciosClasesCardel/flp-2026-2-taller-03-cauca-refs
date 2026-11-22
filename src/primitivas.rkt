#lang eopl
;Autores: Aura Maria Pelaez Luna 2459422, Valentina Valencia Lopez 2459626

;; Taller 3 — Cauca con referencias y tipos.
;; Las primitivas del lenguaje y las verificaciones de tipo y de
;; cantidad de argumentos que cada una exige. Requiere sintaxis.rkt.
;;
;; Aridades: +, -, *, / son n-arias; add1, sub1, not y abs son unarias;
;; las relacionales, and, or, xor e implica son binarias; entre es
;; ternaria; mcd y mcm son n-arias sobre enteros con al menos dos
;; argumentos; promedio es n-aria sobre números con al menos uno.

(require "sintaxis.rkt")

;; exigir-numeros : lista x symbol -> boolean
;; Retorna #t si todos los argumentos son números; si no, levanta
;; eopl:error a nombre de quien hizo la verificación.
(define exigir-numeros
  (lambda (args quien)
    (cond
      ((null? args)#t)
      ((number? (car args))
       (exigir-numeros(cdr args)quien))
       (else(eopl:error quien "Todos los argumentos deben ser numeros, lo que recibi fue: ~s" args))
      )))

;; exigir-enteros : lista x symbol -> boolean
;; Retorna #t si todos los argumentos son enteros; si no, levanta error.
(define exigir-enteros
  (lambda (args quien)
    (cond
      ((null? args)#t)
      ((and (integer? (car args)) (exact? (car args))) (exigir-enteros (cdr args) quien))
      (else(eopl:error quien "Todos los argumentos deben ser enteros, lo que recibi fue: ~s" args))
      )))

;; exigir-booleanos : lista x symbol -> boolean
;; Retorna #t si todos los argumentos son booleanos; si no, levanta error.
(define exigir-booleanos
  (lambda (args quien)
    (cond
      ((null? args)#t)
      ((boolean? (car args)) (exigir-booleanos(cdr args)quien))
       (else(eopl:error quien "Todos los argumentos deben ser booleanos, lo que recibi fue: ~s" args))
      )))

;; exigir-cantidad : lista x int x symbol -> boolean
;; Retorna #t si llegaron exactamente n argumentos; si no, levanta error.
(define exigir-cantidad
  (lambda (args n quien)
    (if (=(length args)n)
        #t
        (eopl:error quien "Se esperaban ~s argumentos, recibi ~s" n (length args)))
      ))

;; exigir-minimo : lista x int x symbol -> boolean
;; Retorna #t si llegaron al menos n argumentos; si no, levanta error.
(define exigir-minimo
  (lambda (args n quien)
    (if(>=(length args)n)
       #t
       (eopl:error quien "Se esperaban al menos ~s argumentos, recibi ~s" n (length args))
       )))


;; hay-cero? : lista de números -> boolean
;; Retorna #t si algún elemento de la lista es igual a cero.
(define hay-cero?
  (lambda (lista)
    (cond
      ((null? lista) #f)
      ((= (car lista) 0) #t)
      (else (hay-cero? (cdr lista))))
    ))
;; evaluar-primitiva : primitiva x lista de valores -> valor
;; Verifica la cantidad y el tipo de los argumentos y aplica la
;; primitiva. Se resuelve con cases sobre el datatype primitiva.

(define evaluar-primitiva
  (lambda (prim args)

    (cases primitiva prim
      ;; n-arias (+, -,*,/)
      (sum-prim() 
          (exigir-minimo args 2 '+)(exigir-numeros args '+)
          (apply + args))
      (minus-prim()
           (exigir-minimo args 2 '-)(exigir-numeros args '-)
           (apply - args))
      (mult-prim()
           (exigir-minimo args 2'*)(exigir-numeros args '*)
           (apply * args))
      (div-prim()
           (exigir-minimo args 2 '/)(exigir-numeros args '/)
           (cond
             ((hay-cero? (cdr args))
              (eopl:error '/ "No se puede dividir por cero"))
             (else (apply / args))))
      ;;unarias  (add1, sub1, not, abs)
      (add-prim()
          (exigir-cantidad args 1 'add1)(exigir-numeros args 'add1)
          (+(car args)1))
      (sub-prim()
          (exigir-cantidad args 1 'sub1)(exigir-numeros args 'sub1)
          (-(car args)1))
      (not-prim()
           (exigir-cantidad args 1 'not)(exigir-booleanos args 'not)
           (not(car args)))
      (abs-prim()
          (exigir-cantidad args 1 'abs)(exigir-numeros args 'abs)
          (abs(car args)))
      ;;binarias:relacionales
      (mayor-prim()
           (exigir-cantidad args 2 '>)(exigir-numeros args '>)
           (>(car args)(cadr args)))
      (mayorigual-prim()
           (exigir-cantidad args 2 '>=)(exigir-numeros args '>=)
           (>=(car args)(cadr args)))
      (menor-prim()
           (exigir-cantidad args 2 '<)(exigir-numeros args '<)
           (<(car args)(cadr args)))
      (menorigual-prim()
           (exigir-cantidad args 2 '<=)(exigir-numeros args '<=)
           (<=(car args)(cadr args)))
      (igual-prim()
           (exigir-cantidad args 2 '==)(exigir-numeros args '==)
           (=(car args)(cadr args)))
      ;;binarias: and, or, xor, implica
      
      (and-prim ()
           (exigir-cantidad args 2 'and)(exigir-booleanos args 'and)
           (and (car args) (cadr args)))
      (or-prim ()
           (exigir-cantidad args 2 'or)(exigir-booleanos args 'or)
           (or (car args) (cadr args)))
      (xor-prim ()
           (exigir-cantidad args 2 'xor)(exigir-booleanos args 'xor)
           (not (eq? (car args) (cadr args))))
      (implica-prim ()
           (exigir-cantidad args 2 'implica)(exigir-booleanos args 'implica)
        (or (not (car args)) (cadr args)))
      ;;ternaria(entre)
            (entre-prim ()
           (exigir-cantidad args 3 'entre)(exigir-numeros args 'entre)
           (and (<= (cadr args) (car args))(<= (car args) (caddr args))))
      ;;n-arias sobre enteros, mínimo 2 (mcd, mcm
      (mcd-prim ()
           (exigir-minimo args 2 'mcd)(exigir-enteros args 'mcd)
           (apply gcd args))
      (mcm-prim ()
           (exigir-minimo args 2 'mcm)(exigir-enteros args 'mcm)
           (apply lcm args))
      ;;n-aria sobre números, mínimo 1 (promedio)
      (promedio-prim ()
           (exigir-minimo args 1 'promedio)(exigir-numeros args 'promedio)
           (/ (apply + args) (length args)))

      )))
               

(provide (all-defined-out))