#lang eopl
;Autores: Aura Maria Pelaez Luna 2459422, Valentina Valencia Lopez 2459626

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

  deref-exp, setref-exp y swap-exp verifican con referencia? antes de
  tocar el almacén; si el valor no es una referencia, levantan eopl:error.
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

;; copiar-todos : lista de valores -> lista de valores
;; Aplica copia-por-valor a cada valor, de izquierda a derecha.
(define copiar-todos
  (lambda (vals)
    (if (null? vals)
        '()
        (let ((primero (copia-por-valor (car vals))))
          (cons primero (copiar-todos (cdr vals)))))))

;; apply-procedure : procval x lista de valores -> valor
;; Verifica la aridad y evalúa el cuerpo en el ambiente de la clausura
;; extendido con los parámetros ligados a los argumentos recibidos.
(define apply-procedure
  (lambda (proc args)
    (cases procval proc
      (cerradura (ids body env-clausura)
        (if (not (= (length ids) (length args)))
            (eopl:error 'apply-procedure "Se esperaban ~s argumentos, recibi ~s"
                        (length ids) (length args))
            (evaluar-expresion body (ambiente-extendido ids args env-clausura)))))))

;; evaluar-rands : lista de expresiones x ambiente -> lista de valores
;; Evalúa los operandos de izquierda a derecha en el mismo ambiente.
(define evaluar-rands
  (lambda (rands env)
    (if (null? rands)
        '()
        (let ((valor-actual (evaluar-expresion (car rands) env)))
          (cons valor-actual (evaluar-rands (cdr rands) env))))))

;; evaluar-secuencia : expresion x lista de expresiones x ambiente -> valor
;; Evalúa la primera y luego las demás de izquierda a derecha; retorna
;; el valor de la última. Es el cuerpo de begin-exp.
(define evaluar-secuencia
  (lambda (primera resto env)
    (let ((valor (evaluar-expresion primera env)))
      (if (null? resto)
          valor
          (evaluar-secuencia (car resto) (cdr resto) env)))))

;; buscar-referencias : lista de symbol x ambiente -> lista de referencias
;; Busca cada identificador en el ambiente y verifica que su valor sea
;; una referencia; si alguno no lo es, levanta eopl:error. Es el paso 2
;; de la semántica de applyref.
(define buscar-referencias
  (lambda (ids env)
    (if (null? ids)
        '()
        (let ((valor (apply-env env (car ids))))
          (if (referencia? valor)
              (cons valor (buscar-referencias (cdr ids) env))
              (eopl:error 'applyref
                          "El paso por referencia exige variables ligadas a referencias; ~s no lo esta"
                          (car ids)))))))

;; evaluar-expresion : expresion x ambiente -> valor
;; Una cláusula por variante de la gramática.
(define evaluar-expresion
  (lambda (exp env)
    (cases expresion exp
      ;; literales y variables
      (lit-exp (dato) dato)
      (var-exp (id) (apply-env env id))
      (true-exp () #t)
      (false-exp () #f)

      ;; primitiva: operandos de izquierda a derecha
      (prim-exp (prim rands)
        (evaluar-primitiva prim (evaluar-rands rands env)))

      ;; if: la condición debe ser booleana; solo se evalúa una rama
      (if-exp (test rama-then rama-else)
        (let ((test-value (evaluar-expresion test env)))
          (cond
            ((not (boolean? test-value))
             (eopl:error 'if "La condicion debe ser booleana, recibi: ~s" test-value))
            (test-value (evaluar-expresion rama-then env))
            (else (evaluar-expresion rama-else env)))))

      ;; let: ligaduras evaluadas en el ambiente actual; no copian
      (let-exp (ids rands body)
        (let ((valores (evaluar-rands rands env)))
          (evaluar-expresion body (ambiente-extendido ids valores env))))

      ;; letrec: ambiente recursivo; las anotaciones de tipo se ignoran
      (letrec-exp (tipos-res proc-names idss tipos-args bodies body)
        (evaluar-expresion body (ambiente-recursivo proc-names idss bodies env)))

      ;; proc: cerradura con el ambiente de definición
      (proc-exp (ids tipos body)
        (cerradura ids body env))

      ;; apply: paso por valor; cada argumento entra copiado
      (app-exp (rator rands)
        (let ((proc (evaluar-expresion rator env)))
          (if (not (procval? proc))
              (eopl:error 'apply "El operador no es un procedimiento: ~s" proc)
              (let ((args (evaluar-rands rands env)))
                (apply-procedure proc (copiar-todos args))))))

      ;; case: selección por valor sobre un número
      (case-exp (control valores acciones default)
        (let ((valor-control (evaluar-expresion control env)))
          (if (not (number? valor-control))
              (eopl:error 'case "El valor de control debe ser un numero, recibi: ~s" valor-control)
              (let buscar ((vs valores) (as acciones))
                (cond
                  ((null? vs) (evaluar-expresion default env))
                  ((= valor-control (car vs)) (evaluar-expresion (car as) env))
                  (else (buscar (cdr vs) (cdr as))))))))

      ;; newref: reserva una celda nueva con el valor y retorna su referencia
      (newref-exp (e)
        (newref! (evaluar-expresion e env)))

      ;; deref: verifica que sea referencia y lee la celda
      (deref-exp (e)
        (let ((ref (evaluar-expresion e env)))
          (if (referencia? ref)
              (deref ref)
              (eopl:error 'deref "Se esperaba una referencia, recibi: ~s" ref))))

      ;; setref: evalúa de izquierda a derecha, escribe y retorna 1
      (setref-exp (e1 e2)
        (let* ((ref (evaluar-expresion e1 env))
               (val (evaluar-expresion e2 env)))
          (if (referencia? ref)
              (begin (setref! ref val) 1)
              (eopl:error 'setref "Se esperaba una referencia, recibi: ~s" ref))))

      ;; swap: intercambia el contenido de las dos celdas y retorna el
      ;; contenido anterior de la segunda (el nuevo de la primera)
      (swap-exp (e1 e2)
        (let* ((ref1 (evaluar-expresion e1 env))
               (ref2 (evaluar-expresion e2 env)))
          (if (and (referencia? ref1) (referencia? ref2))
              (let* ((v1 (deref ref1))
                     (v2 (deref ref2)))
                (setref! ref1 v2)
                (setref! ref2 v1)
                v2)
              (eopl:error 'swap "Se esperaban dos referencias, recibi: ~s y ~s" ref1 ref2))))

      ;; begin: izquierda a derecha, retorna la última
      (begin-exp (primera resto)
        (evaluar-secuencia primera resto env))

      ;; applyref: paso por referencia; el parámetro queda ligado a la
      ;; misma referencia del argumento, sin copia
      (app-ref-exp (rator ids)
        (let ((proc (evaluar-expresion rator env)))
          (if (not (procval? proc))
              (eopl:error 'applyref "El operador no es un procedimiento: ~s" proc)
              (apply-procedure proc (buscar-referencias ids env))))))))

;; evaluar-programa : programa -> valor
;; Deja el almacén vacío y evalúa el cuerpo en el ambiente inicial.
(define evaluar-programa
  (lambda (pgm)
    (cases programa pgm
      (a-program (exp)
        (begin
          (initialize-store!)
          (evaluar-expresion exp (ambiente-inicial)))))))

;; interpretar : string -> valor
;; Analiza el texto con el parser y lo evalúa.
(define interpretar
  (lambda (texto)
    (evaluar-programa (parser texto))))

;; interpretador : -> void
;; El ciclo de lectura, con sllgen:make-rep-loop sobre evaluar-programa.
(define interpretador
  (lambda ()
    ((sllgen:make-rep-loop "-->" evaluar-programa
                           (sllgen:make-stream-parser especificacion-lexica
                                                      especificacion-gramatical)))))

(provide (all-defined-out))