#lang eopl
;Autores: Oliver De Jesus Arboleda Baez 2459684, Maria Fernanda Betancourt Montoya 2459510, Kevin Andres Rosero Romo 2459554

#|
  Taller 3 — Cauca con referencias y tipos.
  Evaluación y punto de entrada.

  evaluar-expresion recorre el árbol con cases y apply-procedure liga
  los parámetros de una clausura antes de evaluar su cuerpo. Las dos se
  llaman mutuamente, así que comparten módulo, y con ellas la copia por
  valor de los argumentos, que describe cómo entra un valor a apply y no
  cómo está hecha la clausura.

  El evaluador ignora las anotaciones de tipo: las lee el parser, quedan
  en el árbol y solo las usa el chequeador.

  Las cláusulas de newref-exp, deref-exp, setref-exp, swap-exp y
  begin-exp van en evaluar-expresion, junto a las demás variantes.
  Las tres que verifican con referencia? antes de tocar el almacén son
  deref-exp, setref-exp y swap-exp; si el valor no es una referencia,
  levantan eopl:error.
|#

(require "sintaxis.rkt")
(require "almacen.rkt")
(require "ambiente.rkt")
(require "primitivas.rkt")

;; copia-por-valor : valor -> valor
;; El paso por valor entrega una copia del argumento. Para un número, un
;; booleano o un procedimiento la copia es el mismo valor; para una
;; referencia es una celda nueva con el mismo contenido. applyref no usa
;; esta función: ahí el parámetro queda ligado a la misma celda.
(define copia-por-valor
  (lambda (val)
    (if (referencia? val)
        (newref! (deref val))
        val)))

;; apply-procedure : procval x lista de valores -> valor
;; Verifica la aridad y evalúa el cuerpo en el ambiente de la clausura
;; extendido con los parámetros.
(define apply-procedure
  (lambda (proc args)
    (cases procval proc
      (clausura (ids body saved-env)
        (if (= (length ids) (length args))
            (evaluar-expresion
             body
             (ambiente-extendido ids (map copia-por-valor args) saved-env))
            (eopl:error 'apply-procedure
                        "El procedimiento espera ~s argumentos y recibio ~s"
                        (length ids)
                        (length args)))))))

;; evaluar-expresion : expresion x ambiente -> valor
;; Una cláusula por variante de la gramática. La condición de un if se
;; verifica con boolean? antes de ramificar.
(define evaluar-expresion
  (lambda (exp env)
    (cases expresion exp
      (lit-exp (dato) dato)
      (var-exp (id) (apply-env env id))
      (true-exp () #t)
      (false-exp () #f)
      (prim-exp (prim rands)
        (evaluar-primitiva prim
                            (map (lambda (rand)
                                   (evaluar-expresion rand env))
                                 rands)))
      (if-exp (test-exp true-exp false-exp)
        (let ((test-val (evaluar-expresion test-exp env)))
          (if (boolean? test-val)
              (if test-val
                  (evaluar-expresion true-exp env)
                  (evaluar-expresion false-exp env))
              (eopl:error 'evaluar-expresion
                          "La condicion del if debe ser booleana"))))
      (let-exp (ids rands body)
        (evaluar-expresion
         body
         (ambiente-extendido
          ids
          (map (lambda (rand) (evaluar-expresion rand env)) rands)
          env)))
      (proc-exp (ids tipos body)
        (clausura ids body env))
      (app-exp (rator rands)
        (let ((proc (evaluar-expresion rator env)))
          (if (procval? proc)
              (apply-procedure
               proc
               (map (lambda (rand) (evaluar-expresion rand env)) rands))
              (eopl:error 'evaluar-expresion
                          "Se intento aplicar un valor que no es un procedimiento"))))
      (letrec-exp (tipos-res proc-names idss tipos-args bodies body)
        (evaluar-expresion
         body
         (ambiente-recursivo proc-names idss bodies env)))
      (case-exp (control valores acciones default)
        (let ((control-val (evaluar-expresion control env)))
          (if (number? control-val)
              (letrec ((buscar-rama
                        (lambda (nums exps)
                          (if (null? nums)
                              (evaluar-expresion default env)
                              (if (= control-val (car nums))
                                  (evaluar-expresion (car exps) env)
                                  (buscar-rama (cdr nums) (cdr exps)))))))
                (buscar-rama valores acciones))
              (eopl:error 'evaluar-expresion
                          "La expresion de control de case debe ser numerica"))))
      (newref-exp (exp1)
        (newref! (evaluar-expresion exp1 env)))
      (deref-exp (exp1)
        (let ((ref (evaluar-expresion exp1 env)))
          (if (referencia? ref)
              (deref ref)
              (eopl:error 'evaluar-expresion
                          "deref espera una referencia"))))
      (setref-exp (ref-exp val-exp)
        (let ((ref (evaluar-expresion ref-exp env)))
          (let ((val (evaluar-expresion val-exp env)))
            (if (referencia? ref)
                (begin
                  (setref! ref val)
                  1)
                (eopl:error 'evaluar-expresion
                            "setref espera una referencia")))))
      (swap-exp (ref1-exp ref2-exp)
        (let ((ref1 (evaluar-expresion ref1-exp env)))
          (let ((ref2 (evaluar-expresion ref2-exp env)))
            (if (referencia? ref1)
                (if (referencia? ref2)
                    (let ((val1 (deref ref1)))
                      (let ((val2 (deref ref2)))
                        (begin
                          (setref! ref1 val2)
                          (setref! ref2 val1)
                          val2)))
                    (eopl:error 'evaluar-expresion
                                "swap espera referencias"))
                (eopl:error 'evaluar-expresion
                            "swap espera referencias")))))
      (begin-exp (exp1 exps)
        (letrec ((evaluar-secuencia
                  (lambda (secuencia)
                    (if (null? (cdr secuencia))
                        (evaluar-expresion (car secuencia) env)
                        (begin
                          (evaluar-expresion (car secuencia) env)
                          (evaluar-secuencia (cdr secuencia)))))))
          (evaluar-secuencia (cons exp1 exps))))
      (app-ref-exp (rator ids)
        (let ((proc (evaluar-expresion rator env)))
          (if (procval? proc)
              (let ((refs (map (lambda (id) (apply-env env id)) ids)))
                (if (letrec ((todas-referencias?
                              (lambda (vals)
                                (or (null? vals)
                                    (and (referencia? (car vals))
                                         (todas-referencias? (cdr vals)))))))
                      (todas-referencias? refs))
                    (cases procval proc
                      (clausura (params body saved-env)
                        (if (= (length params) (length refs))
                            (evaluar-expresion
                             body
                             (ambiente-extendido params refs saved-env))
                            (eopl:error 'evaluar-expresion
                                        "El procedimiento espera ~s argumentos y recibio ~s"
                                        (length params)
                                        (length refs)))))
                    (eopl:error 'evaluar-expresion
                                "El paso por referencia exige variables ligadas a referencias")))
              (eopl:error 'evaluar-expresion
                          "Se intento aplicar un valor que no es un procedimiento")))))))

;; evaluar-programa : programa -> valor
;; Deja el almacén vacío y evalúa el cuerpo en el ambiente inicial.
(define evaluar-programa
  (lambda (pgm)
    (initialize-store!)
    (cases programa pgm
      (a-program (exp)
        (evaluar-expresion exp (ambiente-inicial))))))

;; interpretar : string -> valor
;; Analiza el texto con el parser y lo evalúa.
(define interpretar
  (lambda (texto)
    (evaluar-programa (parser texto))))

;; interpretador : -> void
;; El ciclo de lectura, con sllgen:make-rep-loop sobre evaluar-programa.
(define interpretador
  (lambda ()
    ((sllgen:make-rep-loop
      "--> "
      evaluar-programa
      (sllgen:make-stream-parser especificacion-lexica
                                 especificacion-gramatical)))))

(provide (all-defined-out))
