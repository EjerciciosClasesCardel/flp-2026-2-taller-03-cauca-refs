#lang eopl
;Autores: Juan Eduardo Calderon Jaramillo 2611001-3743

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

  Decisiones de diseño:
    - El orden de evaluación es de izquierda a derecha en todas partes
      (operandos, argumentos, begin, setref, swap). Con el almacén ese
      orden es observable, por eso las listas se evalúan con
      evaluar-lista, que lo fija con let en vez de depender de map.
    - apply-procedure NO copia: recibe los valores ya preparados. apply
      (app-exp) le pasa copias hechas con copia-por-valor; applyref
      (app-ref-exp) le pasa las referencias originales. Así los dos
      mecanismos comparten una sola función de ligadura y la diferencia
      queda en un único lugar visible.
    - let no copia: let otro = celda comparte la celda (alias).
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

;; evaluar-lista : (list-of expresion) x ambiente -> (list-of valor)
;; Propósito: evalúa las expresiones de izquierda a derecha y retorna la
;; lista de sus valores. El let fija el orden: el primer elemento se
;; evalúa (con sus efectos sobre el almacén) antes que el resto.
(define evaluar-lista
  (lambda (exps env)
    (if (null? exps)
        '()
        (let ((primero (evaluar-expresion (car exps) env)))
          (cons primero (evaluar-lista (cdr exps) env))))))

;; evaluar-secuencia : expresion x (list-of expresion) x ambiente -> valor
;; Propósito: evalúa primero y luego cada expresión de resto, en orden, y
;; retorna el valor de la última. Es el cuerpo de begin-exp.
(define evaluar-secuencia
  (lambda (primero resto env)
    (let ((valor (evaluar-expresion primero env)))
      (if (null? resto)
          valor
          (evaluar-secuencia (car resto) (cdr resto) env)))))

;; exigir-referencia : valor x symbol -> referencia
;; Propósito: retorna val si es una referencia; si no, levanta eopl:error
;; a nombre de quien lo pidió.
(define exigir-referencia
  (lambda (val quien)
    (if (referencia? val)
        val
        (eopl:error quien "Se esperaba una referencia, se recibio: ~s" val))))

;; exigir-procedimiento : valor x symbol -> procval
;; Propósito: retorna val si es un procedimiento; si no, levanta
;; eopl:error a nombre de quien lo pidió.
(define exigir-procedimiento
  (lambda (val quien)
    (if (procval? val)
        val
        (eopl:error quien "Se esperaba un procedimiento, se recibio: ~s" val))))

;; buscar-referencias : (list-of symbol) x ambiente -> (list-of referencia)
;; Propósito: busca cada identificador en el ambiente y verifica que su
;; valor sea una referencia. Si alguno no lo es, levanta eopl:error: el
;; paso por referencia exige variables ligadas a referencias.
(define buscar-referencias
  (lambda (ids env)
    (if (null? ids)
        '()
        (let ((val (apply-env env (car ids))))
          (if (referencia? val)
              (cons val (buscar-referencias (cdr ids) env))
              (eopl:error 'applyref
                          "El paso por referencia exige variables ligadas a referencias: ~s no lo esta"
                          (car ids)))))))

;; elegir-caso : number x (list-of number) x (list-of expresion)
;;               x expresion -> expresion
;; Propósito: retorna la acción del primer valor de la lista que sea igual
;; a x, o default si ninguno coincide.
(define elegir-caso
  (lambda (x valores acciones default)
    (cond
      [(null? valores) default]
      [(= x (car valores)) (car acciones)]
      [else (elegir-caso x (cdr valores) (cdr acciones) default)])))

;; apply-procedure : procval x lista de valores -> valor
;; Verifica la aridad y evalúa el cuerpo en el ambiente de la clausura
;; extendido con los parámetros. Liga los parámetros a los valores tal
;; cual los recibe: quien llama decide si son copias (apply) o las mismas
;; referencias (applyref).
(define apply-procedure
  (lambda (proc args)
    (cases procval proc
      (cerradura (ids body env)
        (if (= (length ids) (length args))
            (evaluar-expresion body (ambiente-extendido ids args env))
            (eopl:error 'apply-procedure
                        "El procedimiento espera ~s argumentos y recibio ~s"
                        (length ids) (length args)))))))

;; evaluar-expresion : expresion x ambiente -> valor
;; Una cláusula por variante de la gramática. La condición de un if se
;; verifica con boolean? antes de ramificar.
(define evaluar-expresion
  (lambda (exp env)
    (cases expresion exp
      ;; --- lenguaje base ---
      (lit-exp (dato) dato)
      (var-exp (id) (apply-env env id))
      (true-exp () #t)
      (false-exp () #f)
      (prim-exp (prim rands)
        (evaluar-primitiva prim (evaluar-lista rands env)))
      (if-exp (test-exp true-branch false-branch)
        (let ((cond-val (evaluar-expresion test-exp env)))
          (if (boolean? cond-val)
              (if cond-val
                  (evaluar-expresion true-branch env)
                  (evaluar-expresion false-branch env))
              (eopl:error 'if "La condicion del if debe ser booleana, se recibio: ~s"
                          cond-val))))
      (let-exp (ids rands body)
        ;; let NO copia: liga los nombres a los valores tal cual, de modo
        ;; que ligar una referencia crea un alias de la misma celda.
        (evaluar-expresion body
                           (ambiente-extendido ids (evaluar-lista rands env) env)))
      (proc-exp (ids tipos body)
        (cerradura ids body env))
      (letrec-exp (tipos-res proc-names idss tipos-args bodies body)
        (evaluar-expresion body
                           (ambiente-recursivo proc-names idss bodies env)))
      (case-exp (control valores acciones default)
        (let ((x (evaluar-expresion control env)))
          (if (number? x)
              (evaluar-expresion (elegir-caso x valores acciones default) env)
              (eopl:error 'case "El control del case debe ser un numero, se recibio: ~s"
                          x))))

      ;; --- aplicación por valor ---
      (app-exp (rator rands)
        (let* ((f (exigir-procedimiento (evaluar-expresion rator env) 'apply))
               (args (evaluar-lista rands env)))
          ;; cada argumento entra por copia-por-valor
          (apply-procedure f (map copia-por-valor args))))

      ;; --- Parte 1: almacén ---
      (newref-exp (e)
        (newref! (evaluar-expresion e env)))
      (deref-exp (e)
        (let ((r (evaluar-expresion e env)))
          (deref (exigir-referencia r 'deref))))
      (setref-exp (ref-exp val-exp)
        ;; izquierda a derecha; primero se evalúan las dos y después se
        ;; verifica que la primera sea una referencia
        (let* ((r (evaluar-expresion ref-exp env))
               (v (evaluar-expresion val-exp env)))
          (exigir-referencia r 'setref)
          (setref! r v)
          1))
      (swap-exp (ref1-exp ref2-exp)
        (let* ((r1 (evaluar-expresion ref1-exp env))
               (r2 (evaluar-expresion ref2-exp env)))
          (exigir-referencia r1 'swap)
          (exigir-referencia r2 'swap)
          ;; se leen los dos contenidos ANTES de escribir, para no perder
          ;; el original de la primera celda (y para que r1 = r2 funcione)
          (let ((v1 (deref r1))
                (v2 (deref r2)))
            (setref! r1 v2)
            (setref! r2 v1)
            ;; el valor que quedó en la primera = contenido anterior de la segunda
            v2)))
      (begin-exp (primera resto)
        (evaluar-secuencia primera resto env))

      ;; --- Parte 2: paso por referencia ---
      (app-ref-exp (rator ids)
        (let* ((f (exigir-procedimiento (evaluar-expresion rator env) 'applyref))
               (refs (buscar-referencias ids env)))
          ;; sin copia: los parámetros quedan ligados a las MISMAS
          ;; referencias; apply-procedure verifica la aridad
          (apply-procedure f refs))))))

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
    ((sllgen:make-rep-loop "--> "
                           evaluar-programa
                           (sllgen:make-stream-parser especificacion-lexica
                                                      especificacion-gramatical)))))

(provide (all-defined-out))