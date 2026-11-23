#lang eopl
;Autores: Oliver De Jesus Arboleda Baez 2459684, Maria Fernanda Betancourt Montoya 2459510, Kevin Andres Rosero Romo 2459554

#|
  Taller 3 — Cauca con referencias y tipos.
  TAD referencia y almacén (Parte 1).

  El módulo no requiere ningún otro: el almacén guarda valores
  cualesquiera y no necesita la gramática.

  La referencia es un tipo abstracto y no un entero desnudo: así un
  programa de Cauca no puede hacer aritmética con posiciones de memoria
  ni leer celdas que nunca le pertenecieron.

  El almacén es una lista de valores; la posición de cada valor en la
  lista es la posición de su celda. Vive en una variable global, que es el
  único lugar del curso donde se usa set!.

  Invariante que las operaciones tienen que preservar, y que se demuestra
  en la Parte 5:
    1. toda referencia entregada por newref! apunta a una celda existente
    2. el almacén solo crece por newref!
    3. setref! cambia una celda y deja las demás intactas
    4. deref sobre una referencia fuera de rango levanta eopl:error
|#

;; referencia
;; TAD de las referencias: a-ref guarda la posición de la celda.
(define-datatype referencia referencia?
  (a-ref (pos integer?)))

;; the-store
;; Variable global con el almacén actual (lista de valores). Solo la
;; modifican initialize-store!, newref! y setref!
(define the-store '())

;; empty-store : -> almacen
;; El almacén sin celdas.
(define empty-store
  (lambda () '()))

;; initialize-store! : -> void
;; Deja el almacén vacío. Se llama al empezar cada programa.
(define initialize-store!
  (lambda ()
    (set! the-store (empty-store))))

;; posicion-valida? : integer -> boolean
;; Indica si pos es la posición de una celda existente del almacén actual.
(define posicion-valida?
  (lambda (pos)
    (and (>= pos 0) (< pos (length the-store)))))

;; newref! : valor -> referencia
;; Agrega una celda con el valor al final del almacén y retorna la
;; referencia que la nombra. No altera las celdas existentes.
(define newref!
  (lambda (val)
    (let ((pos (length the-store)))
      (set! the-store (append the-store (list val)))
      (a-ref pos))))

;; deref : referencia -> valor
;; Lee la celda. Si la referencia está fuera de rango, levanta eopl:error.
;; No modifica el almacén.
(define deref
  (lambda (ref)
    (cases referencia ref
      (a-ref (pos)
        (if (posicion-valida? pos)
            (list-ref the-store pos)
            (eopl:error 'deref "Referencia fuera de rango: s" pos))))))

;; setref! : referencia x valor -> void
;; Escribe el valor en la celda y deja las demás intactas. Si la referencia
;; está fuera de rango, levanta eopl:error y no cambia el almacén.
(define setref!
  (lambda (ref val)
    (cases referencia ref
      (a-ref (pos)
        (if (posicion-valida? pos)
            (letrec ((reemplazar
                      (lambda (celdas i)
                        (if (= i 0)
                            (cons val (cdr celdas))
                            (cons (car celdas)
                                  (reemplazar (cdr celdas) (- i 1)))))))
              (set! the-store (reemplazar the-store pos)))
            (eopl:error 'setref! "Referencia fuera de rango: s" pos))))))

(provide (all-defined-out))
