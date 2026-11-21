#lang eopl
;Autores: Nombre1 Codigo1, Nombre2 Codigo2

#|
  Taller 3 — Cauca con referencias y tipos.
  Primitivas del lenguaje.

  evaluar-primitiva recibe la primitiva del árbol y la lista de valores
  ya evaluados, revisa la cantidad y el tipo de los argumentos y produce
  el resultado. Solo necesita la gramática, no el evaluador.

  Las verificaciones de cantidad y de tipo van aquí, junto a la
  primitiva que las exige, y levantan eopl:error con un mensaje que
  nombre la primitiva.
|#

(require "sintaxis.rkt")


;; todos? : (valor -> boolean) x lista -> boolean
;; #t si todos los elementos de lst cumplen pred?.
(define todos?
  (lambda (pred? lst)
    (cond ((null? lst) #t)
          ((pred? (car lst)) (todos? pred? (cdr lst)))
          (else #f))))

;; verificar-aridad : symbol x lista x entero -> #t
;; Error si la cantidad de argumentos no es exactamente n.
(define verificar-aridad
  (lambda (nombre args n)
    (if (= (length args) n)
        #t
        (eopl:error nombre "espera ~s argumentos y recibio ~s" n (length args)))))

;; verificar-minimo : symbol x lista x entero -> #t
;; Error si hay menos de n argumentos.
(define verificar-minimo
  (lambda (nombre args n)
    (if (>= (length args) n)
        #t
        (eopl:error nombre "espera al menos ~s argumentos y recibio ~s" n (length args)))))

;; verificar-tipos : symbol x lista x predicado x symbol -> #t
;; Error si algún argumento no cumple pred?. tipo solo se usa en el mensaje.
(define verificar-tipos
  (lambda (nombre args pred? tipo)
    (if (todos? pred? args)
        #t
        (eopl:error nombre "los argumentos deben ser ~s, se recibio ~s" tipo args))))

;; reducir : (valor x valor -> valor) x lista no vacía -> valor
;; Combina los elementos de lst con f, de derecha a izquierda.
(define reducir
  (lambda (f lst)
    (if (null? (cdr lst))
        (car lst)
        (f (car lst) (reducir f (cdr lst))))))

;; num-variadica : symbol x lista x procedimiento -> num
;; Aritmética con 2 o más argumentos numéricos.
(define num-variadica
  (lambda (nombre args f)
    (verificar-minimo nombre args 2)
    (verificar-tipos nombre args number? 'num)
    (reducir f args)))

;; num-binaria : symbol x lista x procedimiento -> valor
;; Exactamente dos argumentos numéricos (aritmética o relacional).
(define num-binaria
  (lambda (nombre args f)
    (verificar-aridad nombre args 2)
    (verificar-tipos nombre args number? 'num)
    (f (car args) (cadr args))))

;; num-unaria : symbol x lista x procedimiento -> num
;; Exactamente un argumento numérico.
(define num-unaria
  (lambda (nombre args f)
    (verificar-aridad nombre args 1)
    (verificar-tipos nombre args number? 'num)
    (f (car args))))

;; bool-variadica : symbol x lista x procedimiento -> bool
;; Booleana con 2 o más argumentos booleanos.
(define bool-variadica
  (lambda (nombre args f)
    (verificar-minimo nombre args 2)
    (verificar-tipos nombre args boolean? 'bool)
    (reducir f args)))

;; evaluar-primitiva : primitiva x lista de valores -> valor
;; Una cláusula por primitiva de la gramática, con cases.
(define evaluar-primitiva
  (lambda (prim args)
    (cases primitiva prim
      (sum-prim ()          (num-variadica '+ args +))
      (mul-prim ()          (num-variadica '* args *))
      (res-prim ()          (num-binaria '- args -))
      (add1-prim ()         (num-unaria 'add1 args (lambda (x) (+ x 1))))
      (sub1-prim ()         (num-unaria 'sub1 args (lambda (x) (- x 1))))
      (mayor-prim ()        (num-binaria '> args >))
      (menor-prim ()        (num-binaria '< args <))
      (mayor-igual-prim ()  (num-binaria '>= args >=))
      (menor-igual-prim ()  (num-binaria '<= args <=))
      (igual-prim ()        (num-binaria '== args =))
      (and-prim ()          (bool-variadica 'and args (lambda (a b) (and a b))))
      (or-prim ()           (bool-variadica 'or args (lambda (a b) (or a b))))
      (not-prim ()
        (verificar-aridad 'not args 1)
        (verificar-tipos 'not args boolean? 'bool)
        (not (car args)))
      (entre-prim ()
        (verificar-aridad 'entre args 3)
        (verificar-tipos 'entre args number? 'num)
        (and (<= (cadr args) (car args))
             (<= (car args) (caddr args)))))))

(provide (all-defined-out))
