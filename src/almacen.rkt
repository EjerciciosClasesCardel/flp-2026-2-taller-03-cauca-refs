#lang eopl
;Autores: Juan Sebastian Navarrete 202459562, Samuel Garcia Parra 202459476

#|
  Taller 3 — Cauca con referencias y tipos.
  TAD referencia y almacén (Parte 1).

  El módulo no requiere ningún otro: el almacén guarda valores
  cualesquiera y no necesita la gramática.

  Invariante que las operaciones tienen que preservar, y que se demuestra
  en la Parte 5:
    1. toda referencia entregada por newref! apunta a una celda existente
    2. el almacén solo crece por newref!
    3. setref! cambia una celda y deja las demás intactas
    4. deref sobre una referencia fuera de rango levanta eopl:error
|#

(define-datatype referencia referencia?
  (a-ref (pos integer?)))

;; empty-store : -> almacen
;; El almacén sin celdas.
(define empty-store
  (lambda ()
    '()))

(define the-store (empty-store))

;; initialize-store! : -> void
;; Deja el almacén vacío. Se llama al empezar cada programa.
(define initialize-store!
  (lambda ()
    (set! the-store (empty-store))))

;; newref! : valor -> referencia
;; Agrega una celda con el valor y retorna la referencia que la nombra.
(define newref!
  (lambda (val)
    (let ((next-pos (length the-store)))
      (set! the-store (append the-store (list val)))
      (a-ref next-pos))))

;; replace-nth : lista x entero x valor -> lista
;; Retorna una lista igual a lst salvo en la posición n, que queda con val.
(define replace-nth
  (lambda (lst n val)
    (if (= n 0)
        (cons val (cdr lst))
        (cons (car lst) (replace-nth (cdr lst) (- n 1) val)))))

;; deref : referencia -> valor
;; Lee la celda. Si la referencia está fuera de rango, levanta eopl:error.
(define deref
  (lambda (ref)
    (cases referencia ref
      (a-ref (pos)
        (if (and (>= pos 0) (< pos (length the-store)))
            (list-ref the-store pos)
            (eopl:error 'deref "Referencia fuera de rango: ~s" pos))))))

;; setref! : referencia x valor -> void
;; Escribe el valor en la celda y deja las demás intactas.
(define setref!
  (lambda (ref val)
    (cases referencia ref
      (a-ref (pos)
        (if (and (>= pos 0) (< pos (length the-store)))
            (set! the-store (replace-nth the-store pos val))
            (eopl:error 'setref! "Referencia fuera de rango: ~s" pos))))))

(provide (all-defined-out))
