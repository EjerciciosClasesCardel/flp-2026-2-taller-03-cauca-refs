#lang eopl
;Autores: Juan Eduardo Calderon Jaramillo 2611001-3743

#|
  Taller 3 — Cauca con referencias y tipos.
  TAD referencia y almacén (Parte 1).

  El módulo no requiere ningún otro: el almacén guarda valores
  cualesquiera y no necesita la gramática.

  Representación:
    - referencia : tipo abstracto con una sola variante, (a-ref pos).
      No es un entero desnudo: un programa de Cauca no puede fabricar una
      referencia a partir de un número ni hacer aritmética con posiciones.
    - almacén : lista de valores; la celda de posición k es el elemento k
      de la lista (se cuenta desde 0). Vive en la variable global the-store.
      Es el único lugar del curso donde se usa set!.

  Invariante que las operaciones preservan (se demuestra en la Parte 5):
    1. toda referencia entregada por newref! apunta a una celda existente
    2. el almacén solo crece por newref!
    3. setref! cambia una celda y deja las demás intactas
    4. deref sobre una referencia fuera de rango levanta eopl:error
|#

;; referencia
;; Contrato: tipo de dato con una variante, (a-ref pos), pos entero.
;; Propósito: nombra una celda del almacén por su posición, sin exponer
;; la posición como número a los programas de Cauca.
(define-datatype referencia referencia?
  (a-ref (pos integer?)))

;; empty-store : -> almacen
;; Propósito: el almacén sin celdas (la lista vacía).
(define empty-store
  (lambda ()
    '()))

;; the-store : almacen
;; Propósito: variable global con el almacén actual. Solo la modifican
;; initialize-store!, newref! y setref!.
(define the-store (empty-store))

;; initialize-store! : -> void
;; Propósito: deja el almacén vacío. Se llama al empezar cada programa.
(define initialize-store!
  (lambda ()
    (set! the-store (empty-store))))

;; posicion-valida? : integer -> boolean
;; Propósito: #t si pos nombra una celda existente, es decir, si
;; 0 <= pos < longitud del almacén.
(define posicion-valida?
  (lambda (pos)
    (and (>= pos 0) (< pos (length the-store)))))

;; reemplazar-celda : lista x integer x valor -> lista
;; Propósito: retorna una lista nueva igual a lst pero con el elemento de
;; la posición pos cambiado por val. No modifica nada (es funcional);
;; la longitud y los demás elementos quedan idénticos.
(define reemplazar-celda
  (lambda (lst pos val)
    (cond
      [(null? lst) '()]
      [(= pos 0) (cons val (cdr lst))]
      [else (cons (car lst) (reemplazar-celda (cdr lst) (- pos 1) val))])))

;; newref! : valor -> referencia
;; Propósito: agrega una celda al final del almacén con el valor dado y
;; retorna la referencia que la nombra. La nueva posición es la longitud
;; anterior, así que las celdas existentes no se mueven.
(define newref!
  (lambda (val)
    (let ((pos (length the-store)))
      (set! the-store (append the-store (list val)))
      (a-ref pos))))

;; deref : referencia -> valor
;; Propósito: lee la celda nombrada por la referencia sin modificar el
;; almacén. Si la referencia está fuera de rango, levanta eopl:error.
(define deref
  (lambda (ref)
    (cases referencia ref
      (a-ref (pos)
        (if (posicion-valida? pos)
            (list-ref the-store pos)
            (eopl:error 'deref
                        "Referencia fuera de rango: ~s (el almacen tiene ~s celdas)"
                        pos (length the-store)))))))

;; setref! : referencia x valor -> void
;; Propósito: escribe el valor en la celda nombrada y deja las demás
;; intactas; la longitud del almacén no cambia. Si la referencia está
;; fuera de rango, levanta eopl:error.
(define setref!
  (lambda (ref val)
    (cases referencia ref
      (a-ref (pos)
        (if (posicion-valida? pos)
            (set! the-store (reemplazar-celda the-store pos val))
            (eopl:error 'setref!
                        "Referencia fuera de rango: ~s (el almacen tiene ~s celdas)"
                        pos (length the-store)))))))

(provide (all-defined-out))