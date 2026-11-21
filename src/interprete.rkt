#lang eopl
;Autores: Nombre1 Codigo1, Nombre2 Codigo2

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

;; evaluar-lista : lista de expresion x ambiente -> lista de valores
;; Evalúa cada expresión en orden, de izquierda a derecha.
(define evaluar-lista
  (lambda (exps env)
    (if (null? exps)
        '()
        (let ((v (evaluar-expresion (car exps) env)))
          (cons v (evaluar-lista (cdr exps) env))))))

;; apply-procedure : procval x lista de valores -> valor
;; Verifica la aridad y evalúa el cuerpo en el ambiente de la clausura
;; extendido con los parámetros.
(define apply-procedure
  (lambda (proc args)
    (cases procval proc
      (closure (ids body env)
        (if (= (length ids) (length args))
            (evaluar-expresion body
                               (ambiente-extendido ids
                                                   (map copia-por-valor args)
                                                   env))
            (eopl:error 'apply-procedure
                        "El procedimiento espera ~s argumentos y recibio ~s"
                        (length ids) (length args)))))))

;; evaluar-expresion : expresion x ambiente -> valor
;; Una cláusula por variante de la gramática. La condición de un if se
;; verifica con boolean? antes de ramificar.
(define evaluar-expresion
  (lambda (exp env)
    (cases expresion exp

      ;; ---------- Taller 2 ----------
      (lit-exp (n) n)
      (var-exp (id) (apply-env env id))
      (true-exp () #t)
      (false-exp () #f)

      (prim-exp (prim rands)
        (evaluar-primitiva prim (evaluar-lista rands env)))

      (if-exp (c t e)
        (let ((v (evaluar-expresion c env)))
          (if (boolean? v)
              (if v (evaluar-expresion t env) (evaluar-expresion e env))
              (eopl:error 'if "La condicion debe ser booleana, se recibio ~s" v))))

      (let-exp (ids exps body)
        (evaluar-expresion body
                           (ambiente-extendido ids (evaluar-lista exps env) env)))

      (proc-exp (ids tipos body)
        (closure ids body env))

      (app-exp (rator rands)
        (let ((proc (evaluar-expresion rator env)))
          (if (procval? proc)
              (apply-procedure proc (evaluar-lista rands env))
              (eopl:error 'apply "Se intento aplicar algo que no es un procedimiento: ~s" proc))))

      (letrec-exp (tipos-res proc-names idss tipos-args bodies body)
        (evaluar-expresion body
                           (ambiente-recursivo proc-names idss bodies env)))

      (case-exp (e nums exps default)
        (let ((v (evaluar-expresion e env)))
          (if (number? v)
              (let ((pos (posicion v nums)))
                (if pos
                    (evaluar-expresion (list-ref exps pos) env)
                    (evaluar-expresion default env)))
              (eopl:error 'case "La expresion del case debe ser numerica, se recibio ~s" v))))

      ;; ---------- Parte 1: almacén ----------
      (newref-exp (e)
        (newref! (evaluar-expresion e env)))

      (deref-exp (e)
        (let ((r (evaluar-expresion e env)))
          (if (referencia? r)
              (deref r)
              (eopl:error 'deref "Se esperaba una referencia, se recibio ~s" r))))

      (setref-exp (e1 e2)
        (let* ((r (evaluar-expresion e1 env))
               (v (evaluar-expresion e2 env)))
          (if (referencia? r)
              (begin (setref! r v) 1)
              (eopl:error 'setref "Se esperaba una referencia, se recibio ~s" r))))

      (swap-exp (e1 e2)
        (let* ((r1 (evaluar-expresion e1 env))
               (r2 (evaluar-expresion e2 env)))
          (if (and (referencia? r1) (referencia? r2))
              (let ((v1 (deref r1))
                    (v2 (deref r2)))
                (setref! r1 v2)
                (setref! r2 v1)
                v2)
              (eopl:error 'swap "Se esperaban dos referencias, se recibio ~s y ~s" r1 r2))))

      (begin-exp (e es)
        (letrec ((recorrer (lambda (ultimo resto)
                             (if (null? resto)
                                 ultimo
                                 (recorrer (evaluar-expresion (car resto) env)
                                           (cdr resto))))))
          (recorrer (evaluar-expresion e env) es)))

      ;; ---------- Parte 2: paso por referencia ----------
      (app-ref-exp (rator ids)
        (let ((proc (evaluar-expresion rator env)))
          (if (procval? proc)
              (let ((refs (map (lambda (id) (apply-env env id)) ids)))
                (if (todos? referencia? refs)
                    (cases procval proc
                      (closure (params body cenv)
                        (if (= (length params) (length refs))
                            (evaluar-expresion body
                                               (ambiente-extendido params refs cenv))
                            (eopl:error 'applyref
                                        "El procedimiento espera ~s argumentos y recibio ~s"
                                        (length params) (length refs)))))
                    (eopl:error 'applyref
                                "El paso por referencia exige variables ligadas a referencias")))
              (eopl:error 'applyref "Se intento aplicar algo que no es un procedimiento: ~s" proc)))))))

;; evaluar-programa : programa -> valor
;; Deja el almacén vacío y evalúa el cuerpo en el ambiente inicial.
(define evaluar-programa
  (lambda (pgm)
    (initialize-store!)
    (cases programa pgm
      (a-program (body)
        (evaluar-expresion body (ambiente-inicial))))))

;; interpretar : string -> valor
;; Analiza el texto con el parser y lo evalúa.
(define interpretar
  (lambda (texto)
    (evaluar-programa (parser texto))))

;; interpretador : -> void
;; El ciclo de lectura, con sllgen:make-rep-loop sobre evaluar-programa.
(define interpretador
  (lambda ()
    (sllgen:make-rep-loop "--> "
                          evaluar-programa
                          (sllgen:make-stream-parser especificacion-lexica
                                                     especificacion-gramatical))))

(provide (all-defined-out))
