#lang eopl
;Autores: Aura Maria Pelaez Luna 2459422, Valentina Valencia Lopez 2459626

#|
  Taller 3 — Cauca con referencias y tipos.
  Reglas de tipado y chequeo del programa (Parte 3).

  type-of recorre el árbol con cases sobre un ambiente de tipos y no
  evalúa nada: una regla por variante de expresión, tal como están
  escritas en el cuadro del enunciado.

  Los mensajes de error se distinguen uno de otro. Son los nueve del
  cuadro «Mensajes de error», con ese texto, más tres propios para los
  casos que el cuadro no cubre (condición de case, ramas de case y
  swap/applyref con operandos que no son referencias).

  El módulo requiere sintaxis.rkt y tipos.rkt, y ningún otro módulo del
  intérprete.
|#

(require "sintaxis.rkt")
(require "tipos.rkt")

;; types-of-list : lista de expresiones x tenv -> lista de tipos
;; El tipo de cada expresión, de izquierda a derecha, en el mismo ambiente.
(define types-of-list
  (lambda (exps amb)
    (if (null? exps)
        '()
        (let ((t (type-of (car exps) amb)))
          (cons t (types-of-list (cdr exps) amb))))))

;; tipos-de-procs : lista de (lista de tipo) x lista de tipo -> lista de tipo
;; Arma el tipo (t1 * ... * tn -> r) de cada procedimiento de un letrec
;; a partir de los tipos de sus argumentos y de su resultado.
(define tipos-de-procs
  (lambda (tipos-args tipos-res)
    (if (null? tipos-args)
        '()
        (cons (proc-tipo (car tipos-args) (car tipos-res))
              (tipos-de-procs (cdr tipos-args) (cdr tipos-res))))))

;; chequear-argumentos : lista de tipo x lista de tipo x int -> void
;; Compara posición a posición los tipos esperados con los recibidos;
;; el primero que no coincide levanta «El argumento <i> debe ser ...».
(define chequear-argumentos
  (lambda (esperados recibidos i)
    (cond
      ((null? esperados) #t)
      ((tipos-iguales? (car esperados) (car recibidos))
       (chequear-argumentos (cdr esperados) (cdr recibidos) (+ i 1)))
      (else
       (eopl:error 'type-of "El argumento ~a debe ser ~a, se encontro ~a"
                   i (tipo->texto (car esperados)) (tipo->texto (car recibidos)))))))

;; chequear-letrec-cuerpos : lista x lista x lista x lista x lista x tenv -> void
;; Para cada procedimiento declarado, chequea su cuerpo en el ambiente
;; recursivo extendido con sus parámetros y compara con el resultado
;; declarado.
(define chequear-letrec-cuerpos
  (lambda (nombres idss tipos-args tipos-res bodies amb-rec)
    (if (null? nombres)
        #t
        (let ((t-cuerpo (type-of (car bodies)
                                 (tenv-extendido (car idss) (car tipos-args) amb-rec))))
          (if (tipos-iguales? t-cuerpo (car tipos-res))
              (chequear-letrec-cuerpos (cdr nombres) (cdr idss) (cdr tipos-args)
                                       (cdr tipos-res) (cdr bodies) amb-rec)
              (eopl:error 'type-of "El procedimiento ~a declara ~a y su cuerpo da ~a"
                          (car nombres)
                          (tipo->texto (car tipos-res))
                          (tipo->texto t-cuerpo)))))))

;; chequear-ramas-case : lista de expresiones x tipo x tenv -> void
;; Cada acción del case debe tener el mismo tipo que la rama otherwise.
(define chequear-ramas-case
  (lambda (acciones t-default amb)
    (if (null? acciones)
        #t
        (let ((t (type-of (car acciones) amb)))
          (if (tipos-iguales? t t-default)
              (chequear-ramas-case (cdr acciones) t-default amb)
              (eopl:error 'type-of "Las ramas del case deben coincidir: ~a vs ~a"
                          (tipo->texto t) (tipo->texto t-default)))))))

;; chequear-ids-referencia : lista de symbol x lista de tipo x tenv x int -> void
;; Para applyref: cada identificador debe tener tipo refto(s) y ese tipo
;; debe coincidir con el del parámetro correspondiente.
(define chequear-ids-referencia
  (lambda (ids esperados amb i)
    (if (null? ids)
        #t
        (let ((t-id (apply-tenv amb (car ids))))
          (cases tipo t-id
            (ref-tipo (interno)
              (if (tipos-iguales? (car esperados) t-id)
                  (chequear-ids-referencia (cdr ids) (cdr esperados) amb (+ i 1))
                  (eopl:error 'type-of "El argumento ~a debe ser ~a, se encontro ~a"
                              i (tipo->texto (car esperados)) (tipo->texto t-id))))
            (else
             (eopl:error 'type-of
                         "applyref exige identificadores de tipo refto(t); ~a tiene tipo ~a"
                         (car ids) (tipo->texto t-id))))))))

;; type-of : expresion x tenv -> tipo
;; El tipo de la expresión bajo el ambiente de tipos, o eopl:error con
;; el mensaje que explique el conflicto.
(define type-of
  (lambda (exp amb)
    (cases expresion exp
      ;; Γ ⊢ n : num
      (lit-exp (dato) (num-tipo))
      ;; Γ(x) = t  ⟹  Γ ⊢ x : t
      (var-exp (id) (apply-tenv amb id))
      ;; Γ ⊢ true : bool,  Γ ⊢ false : bool
      (true-exp () (bool-tipo))
      (false-exp () (bool-tipo))
      ;; primitivas: el tipo lo fija tipo-de-primitiva
      (prim-exp (prim rands)
        (tipo-de-primitiva prim (types-of-list rands amb)))

      ;; if: condición bool y ramas del mismo tipo
      (if-exp (test rama-then rama-else)
        (let ((t-test (type-of test amb)))
          (if (not (tipos-iguales? t-test (bool-tipo)))
              (eopl:error 'type-of "La condicion del if debe ser bool, se encontro ~a"
                          (tipo->texto t-test))
              (let* ((t1 (type-of rama-then amb))
                     (t2 (type-of rama-else amb)))
                (if (tipos-iguales? t1 t2)
                    t1
                    (eopl:error 'type-of "Las ramas del if deben coincidir: ~a vs ~a"
                                (tipo->texto t1) (tipo->texto t2)))))))

      ;; let: se tipan las expresiones y con esos tipos se tipa el cuerpo
      (let-exp (ids rands body)
        (let ((tipos (types-of-list rands amb)))
          (type-of body (tenv-extendido ids tipos amb))))

      ;; proc: se tipa el cuerpo con los parámetros anotados; el tipo es (t1 * ... * tn -> tipo del cuerpo)
      (proc-exp (ids tipos body)
        (let ((t-cuerpo (type-of body (tenv-extendido ids tipos amb))))
          (proc-tipo tipos t-cuerpo)))

      ;;; apply: el operador debe ser un procedimiento y cada argumento debe tener el tipo de su parámetro; el resultado es el tipo de retorno
      (app-exp (rator rands)
        (let ((t-rator (type-of rator amb))
              (t-rands (types-of-list rands amb)))
          (cases tipo t-rator
            (proc-tipo (t-params t-res)
              (if (not (= (length t-params) (length t-rands)))
                  (eopl:error 'type-of "El procedimiento espera ~a argumentos y recibio ~a"
                              (length t-params) (length t-rands))
                  (begin
                    (chequear-argumentos t-params t-rands 1)
                    t-res)))
            (else
             (eopl:error 'type-of "Se intento aplicar un valor de tipo ~a"
                         (tipo->texto t-rator))))))

      ;; applyref: igual que apply, pero los argumentos son identificadores que deben ser refto(...) del mismo tipo que su parámetro
      (app-ref-exp (rator ids)
        (let ((t-rator (type-of rator amb)))
          (cases tipo t-rator
            (proc-tipo (t-params t-res)
              (if (not (= (length t-params) (length ids)))
                  (eopl:error 'type-of "El procedimiento espera ~a argumentos y recibio ~a"
                              (length t-params) (length ids))
                  (begin
                    (chequear-ids-referencia ids t-params amb 1)
                    t-res)))
            (else
             (eopl:error 'type-of "Se intento aplicar un valor de tipo ~a"
                         (tipo->texto t-rator))))))

      ;; case: control num; acciones y otherwise del mismo tipo
      (case-exp (control valores acciones default)
        (let ((t-control (type-of control amb)))
          (if (not (tipos-iguales? t-control (num-tipo)))
              (eopl:error 'type-of "La expresion del case debe ser num, se encontro ~a"
                          (tipo->texto t-control))
              (let ((t-default (type-of default amb)))
                (chequear-ramas-case acciones t-default amb)
                t-default))))

      ;; letrec: primero se declaran los tipos de todos los procedimientos,
      ;; luego se revisa que cada cuerpo dé el tipo que prometió y al final
      ;; se tipa el cuerpo del letrec
      (letrec-exp (tipos-res proc-names idss tipos-args bodies body)
        (let ((amb-rec (tenv-recursivo proc-names
                                       (tipos-de-procs tipos-args tipos-res)
                                       amb)))
          (chequear-letrec-cuerpos proc-names idss tipos-args tipos-res bodies amb-rec)
          (type-of body amb-rec)))

      ;;newref: si e es de tipo t, newref(e) es refto(t)
      (newref-exp (e)
        (ref-tipo (type-of e amb)))

      ;;deref: e tiene que ser refto(t) y el resultado es t
      (deref-exp (e)
        (let ((t (type-of e amb)))
          (cases tipo t
            (ref-tipo (interno) interno)
            (else (eopl:error 'type-of "deref espera refto(t), se encontro ~a"
                              (tipo->texto t))))))

      ;; setref: e1 es refto(t), e2 debe ser t (lo que la celda ya guardaba) y el resultado es num
      (setref-exp (e1 e2)
        (let ((t1 (type-of e1 amb)))
          (cases tipo t1
            (ref-tipo (interno)
              (let ((t2 (type-of e2 amb)))
                (if (tipos-iguales? interno t2)
                    (num-tipo)
                    (eopl:error 'type-of "La celda guarda ~a y se intento escribir ~a"
                                (tipo->texto interno) (tipo->texto t2)))))
            (else (eopl:error 'type-of "setref espera refto(t), se encontro ~a"
                              (tipo->texto t1))))))

      ;; swap: las dos tienen que ser refto del mismo t y el resultado es t
      (swap-exp (e1 e2)
        (let ((t1 (type-of e1 amb))
              (t2 (type-of e2 amb)))
          (cases tipo t1
            (ref-tipo (i1)
              (cases tipo t2
                (ref-tipo (i2)
                  (if (tipos-iguales? i1 i2)
                      i1
                      (eopl:error 'type-of "swap exige celdas del mismo tipo: ~a vs ~a"
                                  (tipo->texto t1) (tipo->texto t2))))
                (else (eopl:error 'type-of "swap espera refto(t), se encontro ~a"
                                  (tipo->texto t2)))))
            (else (eopl:error 'type-of "swap espera refto(t), se encontro ~a"
                              (tipo->texto t1))))))

      ;; begin: el tipo es el de la última expresión
      (begin-exp (primera resto)
        (let ((tipos (types-of-list (cons primera resto) amb)))
          (list-ref tipos (- (length tipos) 1)))))))

;; type-of-program : programa -> tipo
;; Chequea el programa en el ambiente de tipos inicial.
(define type-of-program
  (lambda (pgm)
    (cases programa pgm
      (a-program (exp) (type-of exp (tenv-inicial))))))

;; tipo-de-texto : string -> string
;; Analiza el texto, lo chequea y describe el tipo resultante.
(define tipo-de-texto
  (lambda (texto)
    (tipo->texto (type-of-program (parser texto)))))

(provide (all-defined-out))