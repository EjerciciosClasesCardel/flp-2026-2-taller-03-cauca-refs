#lang eopl
;Autores: Nombre1 Codigo1, Samuel Garcia Parra 202459476

#|
  Taller 3 — Cauca con referencias y tipos.
  Reglas de tipado y chequeo del programa (Parte 3).

  type-of recorre el árbol con cases sobre un ambiente de tipos y no
  evalúa nada: una regla por variante de expresión, tal como están
  escritas en el cuadro del enunciado.

  Los mensajes de error se distinguen uno de otro. Son los nueve del
  cuadro «Mensajes de error», con ese texto. Las situaciones que el
  cuadro no cubre (case, swap, applyref, primitivas) tienen mensajes
  propios con el mismo estilo.

  El módulo requiere sintaxis.rkt y tipos.rkt, y ningún otro módulo del
  intérprete: el árbol que recorre es el que produjo el parser, con las
  anotaciones de tipo adentro.
|#

(require "sintaxis.rkt")
(require "tipos.rkt")

;;; ==========================================================
;;; Auxiliares
;;; ==========================================================

;; error-de-tipos : string -> (no retorna)
;; Levanta eopl:error con el mensaje ya armado.
(define error-de-tipos
  (lambda (mensaje)
    (eopl:error 'type-of "~a" mensaje)))

;; type-of-lista : lista de expresion x tenv -> lista de tipo
;; Los tipos de las expresiones, de izquierda a derecha.
(define type-of-lista
  (lambda (exps amb)
    (if (null? exps)
        '()
        (let ((t (type-of (car exps) amb)))
          (cons t (type-of-lista (cdr exps) amb))))))

;; exigir-tipo : tipo x tipo x string -> #t
;; Verifica que el tipo hallado sea igual al esperado; si no, levanta
;; error con el mensaje dado.
(define exigir-tipo
  (lambda (hallado esperado mensaje)
    (if (tipos-iguales? hallado esperado)
        #t
        (error-de-tipos mensaje))))

;; revisar-argumentos : lista de tipo x lista de tipo x entero -> #t
;; Compara el tipo de cada argumento con el del parámetro, de izquierda a
;; derecha; i es la posición (desde 1) del primer elemento.
(define revisar-argumentos
  (lambda (esperados hallados i)
    (cond ((null? esperados) #t)
          ((tipos-iguales? (car esperados) (car hallados))
           (revisar-argumentos (cdr esperados) (cdr hallados) (+ i 1)))
          (else
           (error-de-tipos
            (string-append "El argumento " (number->string i)
                           " debe ser " (tipo->texto (car esperados))
                           ", se encontro " (tipo->texto (car hallados))))))))

;; revisar-aridad : lista de tipo x lista -> #t
;; Error si la cantidad de parámetros declarados no coincide con la de
;; argumentos recibidos.
(define revisar-aridad
  (lambda (parametros argumentos)
    (if (= (length parametros) (length argumentos))
        #t
        (error-de-tipos
         (string-append "El procedimiento espera " (number->string (length parametros))
                        " argumentos y recibio " (number->string (length argumentos)))))))

;; contenido-de-ref : tipo x string -> tipo
;; Si t es refto(s) retorna s; si no, error «<operacion> espera refto(t),
;; se encontro <t>».
(define contenido-de-ref
  (lambda (t operacion)
    (cases tipo t
      (ref-tipo (s) s)
      (else
       (error-de-tipos
        (string-append operacion " espera refto(t), se encontro " (tipo->texto t)))))))

;; tipos-de-procs : lista de lista de tipo x lista de tipo -> lista de tipo
;; Arma el tipo (t1 * ... * tn -> r) de cada procedimiento de un letrec a
;; partir de los tipos de sus parámetros y de su resultado.
(define tipos-de-procs
  (lambda (tipos-args tipos-res)
    (if (null? tipos-args)
        '()
        (cons (proc-tipo (car tipos-args) (car tipos-res))
              (tipos-de-procs (cdr tipos-args) (cdr tipos-res))))))

;; revisar-cuerpos : lista de symbol x lista de lista de symbol x lista de
;;   lista de tipo x lista de tipo x lista de expresion x tenv -> #t
;; Para cada procedimiento del letrec chequea el cuerpo bajo Γ' extendido
;; con sus parámetros y verifica que dé el tipo de resultado declarado.
(define revisar-cuerpos
  (lambda (nombres idss tipos-args tipos-res bodies amb-rec)
    (if (null? nombres)
        #t
        (let ((tipo-cuerpo (type-of (car bodies)
                                    (tenv-extendido (car idss) (car tipos-args) amb-rec))))
          (if (tipos-iguales? tipo-cuerpo (car tipos-res))
              (revisar-cuerpos (cdr nombres) (cdr idss) (cdr tipos-args)
                               (cdr tipos-res) (cdr bodies) amb-rec)
              (error-de-tipos
               (string-append "El procedimiento " (symbol->string (car nombres))
                              " declara " (tipo->texto (car tipos-res))
                              " y su cuerpo da " (tipo->texto tipo-cuerpo))))))))

;; revisar-ramas-case : lista de expresion x tipo x tenv -> #t
;; Cada rama del case debe tener el tipo t del caso por defecto.
(define revisar-ramas-case
  (lambda (exps t amb)
    (if (null? exps)
        #t
        (let ((ta (type-of (car exps) amb)))
          (if (tipos-iguales? ta t)
              (revisar-ramas-case (cdr exps) t amb)
              (error-de-tipos
               (string-append "Las ramas del case deben coincidir: "
                              (tipo->texto ta) " vs " (tipo->texto t))))))))

;; revisar-ref-args : lista de symbol x lista de tipo x tenv x entero -> #t
;; Para applyref: cada identificador debe tener tipo refto(s) y ese tipo
;; debe ser igual al del parámetro correspondiente.
(define revisar-ref-args
  (lambda (ids parametros amb i)
    (if (null? ids)
        #t
        (let ((tx (apply-tenv amb (car ids))))
          (cases tipo tx
            (ref-tipo (s)
              (if (tipos-iguales? tx (car parametros))
                  (revisar-ref-args (cdr ids) (cdr parametros) amb (+ i 1))
                  (error-de-tipos
                   (string-append "El argumento " (number->string i)
                                  " debe ser " (tipo->texto (car parametros))
                                  ", se encontro " (tipo->texto tx)))))
            (else
             (error-de-tipos
              (string-append "applyref exige variables de tipo refto(t), "
                             (symbol->string (car ids)) " es " (tipo->texto tx)))))))))

;;; ==========================================================
;;; Regla por variante
;;; ==========================================================

;; type-of : expresion x tenv -> tipo
;; El tipo de la expresión bajo el ambiente de tipos, o eopl:error con
;; el mensaje que explique el conflicto.
(define type-of
  (lambda (exp amb)
    (cases expresion exp

      ;; ---------- Literales e identificadores ----------
      (lit-exp (n) (num-tipo))
      (true-exp () (bool-tipo))
      (false-exp () (bool-tipo))
      (var-exp (id) (apply-tenv amb id))

      ;; ---------- Primitivas ----------
      (prim-exp (prim rands)
        (tipo-de-primitiva prim (type-of-lista rands amb)))

      ;; ---------- if: la condición es bool y las ramas coinciden ----------
      (if-exp (c t e)
        (let ((tc (type-of c amb)))
          (if (tipos-iguales? tc (bool-tipo))
              (let ((t1 (type-of t amb))
                    (t2 (type-of e amb)))
                (if (tipos-iguales? t1 t2)
                    t1
                    (error-de-tipos
                     (string-append "Las ramas del if deben coincidir: "
                                    (tipo->texto t1) " vs " (tipo->texto t2)))))
              (error-de-tipos
               (string-append "La condicion del if debe ser bool, se encontro "
                              (tipo->texto tc))))))

      ;; ---------- let: cada xi toma el tipo de su ei ----------
      (let-exp (ids exps body)
        (type-of body (tenv-extendido ids (type-of-lista exps amb) amb)))

      ;; ---------- proc: el tipo sale de las anotaciones ----------
      (proc-exp (ids tipos body)
        (proc-tipo tipos
                   (type-of body (tenv-extendido ids tipos amb))))

      ;; ---------- apply: operador procedimiento, aridad y argumentos ----------
      (app-exp (rator rands)
        (let ((tf (type-of rator amb))
              (targs (type-of-lista rands amb)))
          (cases tipo tf
            (proc-tipo (parametros res)
              (revisar-aridad parametros rands)
              (revisar-argumentos parametros targs 1)
              res)
            (else
             (error-de-tipos
              (string-append "Se intento aplicar un valor de tipo " (tipo->texto tf)))))))

      ;; ---------- letrec: Γ' conoce todos los procedimientos antes de chequear ----------
      (letrec-exp (tipos-res proc-names idss tipos-args bodies body)
        (let ((amb-rec (tenv-recursivo proc-names
                                       (tipos-de-procs tipos-args tipos-res)
                                       amb)))
          (revisar-cuerpos proc-names idss tipos-args tipos-res bodies amb-rec)
          (type-of body amb-rec)))

      ;; ---------- case: selector num, ramas y defecto del mismo tipo ----------
      (case-exp (e nums exps default)
        (let ((te (type-of e amb)))
          (if (tipos-iguales? te (num-tipo))
              (let ((t (type-of default amb)))
                (revisar-ramas-case exps t amb)
                t)
              (error-de-tipos
               (string-append "La expresion del case debe ser num, se encontro "
                              (tipo->texto te))))))

      ;; ---------- Referencias ----------
      (newref-exp (e)
        (ref-tipo (type-of e amb)))

      (deref-exp (e)
        (contenido-de-ref (type-of e amb) "deref"))

      (setref-exp (e1 e2)
        (let* ((t1 (type-of e1 amb))
               (t2 (type-of e2 amb))
               (guardado (contenido-de-ref t1 "setref")))
          (exigir-tipo t2 guardado
                       (string-append "La celda guarda " (tipo->texto guardado)
                                      " y se intento escribir " (tipo->texto t2)))
          (num-tipo)))

      (swap-exp (e1 e2)
        (let* ((t1 (type-of e1 amb))
               (t2 (type-of e2 amb))
               (c1 (contenido-de-ref t1 "swap"))
               (c2 (contenido-de-ref t2 "swap")))
          (exigir-tipo c1 c2
                       (string-append "swap exige celdas del mismo tipo: "
                                      (tipo->texto c1) " vs " (tipo->texto c2)))
          c1))

      (begin-exp (e es)
        (let ((tipos (type-of-lista (cons e es) amb)))
          (list-ref tipos (- (length tipos) 1))))

      ;; ---------- Paso por referencia ----------
      (app-ref-exp (rator ids)
        (let ((tf (type-of rator amb)))
          (cases tipo tf
            (proc-tipo (parametros res)
              (revisar-aridad parametros ids)
              (revisar-ref-args ids parametros amb 1)
              res)
            (else
             (error-de-tipos
              (string-append "Se intento aplicar un valor de tipo " (tipo->texto tf))))))))))

;; type-of-program : programa -> tipo
;; Chequea el programa en el ambiente de tipos inicial.
(define type-of-program
  (lambda (pgm)
    (cases programa pgm
      (a-program (body) (type-of body (tenv-inicial))))))

;; tipo-de-texto : string -> string
;; Analiza el texto, lo chequea y describe el tipo resultante.
(define tipo-de-texto
  (lambda (texto)
    (tipo->texto (type-of-program (parser texto)))))

(provide (all-defined-out))