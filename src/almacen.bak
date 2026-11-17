#lang eopl
;Autores: Nombre1 Codigo1, Nombre2 Codigo2

#|
  Taller 3 — Cauca con referencias y tipos.
  TAD referencia y almacén (Parte 1).

  El módulo no requiere ningún otro: el almacén guarda valores
  cualesquiera y no necesita la gramática.

  Falta el datatype de la referencia, que es un tipo abstracto y no un
  entero desnudo:

    (define-datatype referencia referencia?
      (a-ref (pos integer?)))

  Falta también la variable global con el almacén. Es el único lugar
  del curso donde se usa set!.

  Invariante que las operaciones tienen que preservar, y que se demuestra
  en la Parte 5:
    1. toda referencia entregada por newref! apunta a una celda existente
    2. el almacén solo crece por newref!
    3. setref! cambia una celda y deja las demás intactas
    4. deref sobre una referencia fuera de rango levanta eopl:error
|#

;; empty-store : -> almacen
;; El almacén sin celdas.
(define empty-store
  (lambda ()
    (eopl:error 'empty-store "Sin implementar")))

;; initialize-store! : -> void
;; Deja el almacén vacío. Se llama al empezar cada programa.
(define initialize-store!
  (lambda ()
    (eopl:error 'initialize-store! "Sin implementar")))

;; newref! : valor -> referencia
;; Agrega una celda con el valor y retorna la referencia que la nombra.
(define newref!
  (lambda (val)
    (eopl:error 'newref! "Sin implementar")))

;; deref : referencia -> valor
;; Lee la celda. Si la referencia está fuera de rango, levanta eopl:error.
(define deref
  (lambda (ref)
    (eopl:error 'deref "Sin implementar")))

;; setref! : referencia x valor -> void
;; Escribe el valor en la celda y deja las demás intactas.
(define setref!
  (lambda (ref val)
    (eopl:error 'setref! "Sin implementar")))

(provide (all-defined-out))
