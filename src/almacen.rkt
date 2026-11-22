#lang eopl
;Autores: Aura Maria Pelaez Luna 2459422, Valentina Valencia Lopez 2459626

#|
  Taller 3 — Cauca con referencias y tipos.
  TAD referencia y almacén (Parte 1).

  El módulo no requiere ningún otro: el almacén guarda valores
  cualesquiera y no necesita la gramática.

  El almacén es una lista de celdas indexadas por posición, guardada en
  una variable global. Es el único lugar del curso donde se usa set!.

  Invariante que las operaciones preservan (se demuestra en la Parte 5):
    1. toda referencia entregada por newref! apunta a una celda existente
    2. el almacén solo crece por newref!
    3. setref! cambia una celda y deja las demás intactas
    4. deref sobre una referencia fuera de rango levanta eopl:error
|#

;; referencia : TAD abstracto. Una referencia no es un número desnudo:
;; el programa de Cauca no puede hacer aritmética con posiciones.
(define-datatype referencia referencia?
  (a-ref (pos integer?)))

;; the-store : almacen
;; Variable global con las celdas del almacén.
(define the-store 'sin-inicializar)

;; empty-store : -> almacen
;; El almacén sin celdas.
(define empty-store
  (lambda () '()))

;; initialize-store! : -> void
;; Deja el almacén vacío. Se llama al empezar cada programa.
(define initialize-store!
  (lambda ()
    (set! the-store (empty-store))))

;; get-store : -> almacen
;; Retorna el almacén actual (sirve para inspeccionarlo en pruebas y trazas).
(define get-store
  (lambda () the-store))

;; posicion-valida? : integer -> boolean
;; #t si la posición existe en el almacén actual.
(define posicion-valida?
  (lambda (pos)
    (and (>= pos 0) (< pos (length the-store)))))

;; reemplazar-celda : lista x integer x valor -> lista
;; La misma lista con la celda de la posición dada cambiada por el valor.
(define reemplazar-celda
  (lambda (lst pos val)
    (cond
      ((null? lst) '())
      ((= pos 0) (cons val (cdr lst)))
      (else (cons (car lst) (reemplazar-celda (cdr lst) (- pos 1) val))))))

;; newref! : valor -> referencia
;; Agrega una celda con el valor al final del almacén y retorna la
;; referencia que la nombra. Es la única operación que cambia su longitud.
(define newref!
  (lambda (val)
    (let ((siguiente (length the-store)))
      (set! the-store (append the-store (list val)))
      (a-ref siguiente))))

;; deref : referencia -> valor
;; Lee la celda. Si la referencia está fuera de rango, levanta eopl:error.
(define deref
  (lambda (ref)
    (cases referencia ref
      (a-ref (pos)
        (if (posicion-valida? pos)
            (list-ref the-store pos)
            (eopl:error 'deref "Referencia fuera de rango: ~s" pos))))))

;; setref! : referencia x valor -> void
;; Escribe el valor en la celda y deja las demás intactas. Si la
;; referencia está fuera de rango, levanta eopl:error.
(define setref!
  (lambda (ref val)
    (cases referencia ref
      (a-ref (pos)
        (if (posicion-valida? pos)
            (set! the-store (reemplazar-celda the-store pos val))
            (eopl:error 'setref! "Referencia fuera de rango: ~s" pos))))))

(provide (all-defined-out))