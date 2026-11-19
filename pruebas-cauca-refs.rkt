#lang eopl
;Autores: Nombre1 Codigo1, Nombre2 Codigo2

#|
  Pruebas del interpretador con referencias y del chequeador de tipos.

  Se ejecuta con:  racket pruebas-cauca-refs.rkt
|#

(require rackunit)
(require rackunit/text-ui)
(require (only-in racket/base exn:fail? with-handlers exn-message))
(require "interprete-cauca-refs.rkt")
(require "checker-cauca.rkt")

(define corre (lambda (texto) (interpretar texto)))
(define tipo-de (lambda (texto) (tipo-de-texto texto)))

;; mensaje-de : string -> string
;; El mensaje que produce el chequeador, para comprobarlo textualmente.
(define mensaje-de
  (lambda (texto)
    (with-handlers ((exn:fail? (lambda (e) (exn-message e))))
      (string-append "sin error: " (tipo-de texto)))))

;; contiene? : string x string -> boolean
(define contiene?
  (lambda (texto fragmento)
    (letrec ((desde (lambda (i)
                      (cond ((> (+ i (string-length fragmento)) (string-length texto)) #f)
                            ((string=? (substring texto i (+ i (string-length fragmento)))
                                       fragmento) #t)
                            (else (desde (+ i 1)))))))
      (desde 0))))

;;; ==========================================================
;;; Interprete
;;; ==========================================================

(define almacen
  (test-suite
   "Parte 1: almacen y expresiones nuevas"
   (test-case "newref y deref"
              (check-equal? (corre "deref(newref(42))") 42)
              (check-equal? (corre "deref(newref(true))") #t))
   (test-case "setref escribe y retorna 1"
              (check-equal? (corre "setref(newref(1), 2)") 1)
              (check-equal? (corre "let c = newref(1) in begin setref(c, 9); deref(c) end end") 9))
   (test-case "el contador sobrevive entre llamadas"
              (check-equal? (corre "let contador = newref(0)
in
  begin
    setref(contador, add1(deref(contador)));
    setref(contador, add1(deref(contador)));
    setref(contador, add1(deref(contador)));
    deref(contador)
  end
end") 3))
   (test-case "swap intercambia el contenido y retorna el nuevo valor de la primera"
              (check-equal? (corre "let a = newref(7)
    b = newref(2)
in
  begin
    swap(a, b);
    +(deref(a), *(10, deref(b)))
  end
end") 72)
              (check-equal? (corre "let a = newref(7) b = newref(2) in swap(a, b) end") 2))
   (test-case "begin evalua de izquierda a derecha y retorna la ultima"
              (check-equal? (corre "begin 1; 2; 3 end") 3)
              (check-equal? (corre "let c = newref(0)
                                    in begin setref(c, 5); setref(c, 6); deref(c) end end") 6))
   (test-case "alias: dos nombres, una sola celda"
              (check-equal? (corre "let celda = newref(5)
in
  let otro = celda
  in
    begin
      setref(otro, 99);
      deref(celda)
    end
  end
end") 99))
   (test-case "el almacen arranca vacio en cada programa"
              (check-equal? (corre "deref(newref(1))") 1)
              (check-equal? (corre "deref(newref(1))") 1))
   (test-case "los casos de error del almacen"
              (check-exn exn:fail? (lambda () (corre "deref(5)")))
              (check-exn exn:fail? (lambda () (corre "setref(1, 2)")))
              (check-exn exn:fail? (lambda () (corre "swap(1, newref(2))"))))))

(define paso-por-referencia
  (test-suite
   "Parte 2: paso por referencia"
   (test-case "applyref deja que el procedimiento escriba en la celda del que llama"
              (check-equal? (corre "let x = newref(11)
    y = newref(4)
in
  let intercambiar = proc (u : refto(num), v : refto(num))
                       swap(u, v)
                     end
  in
    begin
      applyref intercambiar (x, y);
      -(deref(x), deref(y))
    end
  end
end") -7))
   (test-case "el mismo programa con apply no toca las celdas del que llama"
              (check-equal? (corre "let x = newref(11)
    y = newref(4)
in
  let intercambiar = proc (u : refto(num), v : refto(num))
                       swap(u, v)
                     end
  in
    begin
      apply intercambiar (x, y);
      -(deref(x), deref(y))
    end
  end
end") 7))
   (test-case "applyref sobre una sola celda"
              (check-equal? (corre "let c = newref(1)
                                    in let poner = proc (u : refto(num)) setref(u, 100) end
                                       in begin applyref poner (c); deref(c) end end end") 100))
   (test-case "applyref con dos celdas independientes"
              (check-equal? (corre "let a = newref(1)
    b = newref(2)
in let sumar = proc (u : refto(num), v : refto(num))
                 setref(u, +(deref(u), deref(v)))
               end
   in begin applyref sumar (a, b); *(deref(a), deref(b)) end
end end") 6))
   (test-case "apply si comparte el procedimiento, no la celda"
              (check-equal? (corre "let c = newref(1)
                                    in let poner = proc (u : refto(num)) setref(u, 100) end
                                       in begin apply poner (c); deref(c) end end end") 1))
   (test-case "applyref exige variables ligadas a referencias"
              (check-exn exn:fail?
                         (lambda () (corre "let z = 1
                                            in let f = proc (u : refto(num)) deref(u) end
                                               in applyref f (z) end end"))))
   (test-case "applyref exige un procedimiento como operador"
              (check-exn exn:fail?
                         (lambda () (corre "let z = newref(1) in applyref 5 (z) end"))))))

;;; ==========================================================
;;; Chequeador
;;; ==========================================================

(define bien-tipados
  (test-suite
   "Parte 3: programas bien tipados"
   (test-case "procedimiento anotado"
              (check-equal? (tipo-de "proc (a : num, b : num) +(a, b) end") "(num * num -> num)"))
   (test-case "celda con lectura y escritura"
              (check-equal? (tipo-de "let celda = newref(0)
in
  begin
    setref(celda, 42);
    deref(celda)
  end
end") "num"))
   (test-case "newref anida los tipos"
              (check-equal? (tipo-de "newref(newref(true))") "refto(refto(bool))"))
   (test-case "swap devuelve el tipo de la celda"
              (check-equal? (tipo-de "let a = newref(1) b = newref(2) in swap(a, b) end") "num"))
   (test-case "letrec recursivo"
              (check-equal? (tipo-de "letrec num fact (k : num) =
                                        if ==(k, 0) then 1 else *(k, apply fact (sub1(k))) end
                                      in apply fact (5) end") "num"))
   (test-case "applyref con una celda"
              (check-equal? (tipo-de "let x = newref(1)
                                      in let f = proc (u : refto(num)) deref(u) end
                                         in applyref f (x) end end") "num"))
   (test-case "case con ramas del mismo tipo"
              (check-equal? (tipo-de "case n of 1 => 10 of 2 => 20 otherwise => 0 end") "num"))
   (test-case "procedimiento de orden superior"
              (check-equal? (tipo-de "proc (f : (num -> num), x : num) apply f (x) end")
                            "((num -> num) * num -> num)"))))

(define mal-tipados
  (test-suite
   "Parte 3: cada mensaje de error"
   (test-case "la condicion del if no es booleana"
              (check-true (contiene? (mensaje-de "if n then 1 else 2 end")
                                     "La condicion del if debe ser bool, se encontro num")))
   (test-case "las ramas del if no coinciden"
              (check-true (contiene? (mensaje-de "if >(n, m) then 1 else false end")
                                     "Las ramas del if deben coincidir: num vs bool")))
   (test-case "se aplica algo que no es procedimiento"
              (check-true (contiene? (mensaje-de "apply 5 (1)")
                                     "Se intento aplicar un valor de tipo num")))
   (test-case "aridad incorrecta"
              (check-true (contiene? (mensaje-de "let f = proc (a : num, b : num) +(a, b) end
                                                  in apply f (1) end")
                                     "El procedimiento espera 2 argumentos y recibio 1")))
   (test-case "argumento de tipo equivocado"
              (check-true (contiene? (mensaje-de "let f = proc (a : num) a end
                                                  in apply f (true) end")
                                     "El argumento 1 debe ser num, se encontro bool")))
   (test-case "deref sobre algo que no es referencia"
              (check-true (contiene? (mensaje-de "deref(5)")
                                     "deref espera refto(t), se encontro num")))
   (test-case "setref con tipos incompatibles"
              (check-true (contiene? (mensaje-de "let celda = newref(0)
                                                  in setref(celda, true) end")
                                     "La celda guarda num y se intento escribir bool")))
   (test-case "el cuerpo del letrec no da el tipo declarado"
              (check-true (contiene? (mensaje-de "letrec num f (k : num) = true
                                                  in apply f (1) end")
                                     "El procedimiento f declara num y su cuerpo da bool")))
   (test-case "identificador no declarado"
              (check-true (contiene? (mensaje-de "z") "Variable no declarada: z")))
   (test-case "applyref con una variable que no es referencia"
              (check-exn exn:fail?
                         (lambda () (tipo-de "let z = 1
                                              in let f = proc (u : refto(num)) deref(u) end
                                                 in applyref f (z) end end"))))))

(define fallidas
  (+ (run-tests almacen)
     (run-tests paso-por-referencia)
     (run-tests bien-tipados)
     (run-tests mal-tipados)))

(eopl:printf "~%==========================================~%")
(eopl:printf "  pruebas fallidas en total: ~s~%" fallidas)
(eopl:printf "==========================================~%")

;;; ==========================================================
;;; Pruebas adicionales del interprete: almacen y paso por referencia
;;; (Juan Eduardo Calderon Jaramillo 2611001-3743)
;;; Las de arriba no se tocan; estas se agregan a continuacion.
;;; ==========================================================

;; posicion-de : referencia -> integer
;; La posicion que nombra una referencia (solo para comprobar el TAD).
(define posicion-de
  (lambda (r)
    (cases referencia r
      (a-ref (pos) pos))))

(define almacen-adicional
  (test-suite
   "Parte 1 (adicional): TAD y operaciones del almacen"
   (test-case "newref! entrega posiciones consecutivas y el almacen solo crece por newref!"
              (initialize-store!)
              (check-equal? (length the-store) 0)
              (let* ((r0 (newref! 10))
                     (r1 (newref! 20)))
                (check-equal? (posicion-de r0) 0)
                (check-equal? (posicion-de r1) 1)
                (check-equal? (length the-store) 2)
                (setref! r0 99)
                (check-equal? (length the-store) 2)
                (deref r0)
                (check-equal? (length the-store) 2)))
   (test-case "setref! cambia una sola celda y deja las demas intactas"
              (initialize-store!)
              (let* ((r0 (newref! 1))
                     (r1 (newref! 2))
                     (r2 (newref! 3)))
                (setref! r1 50)
                (check-equal? (deref r0) 1)
                (check-equal? (deref r1) 50)
                (check-equal? (deref r2) 3)))
   (test-case "deref y setref! fuera de rango levantan error"
              (initialize-store!)
              (newref! 1)
              (check-exn exn:fail? (lambda () (deref (a-ref 5))))
              (check-exn exn:fail? (lambda () (deref (a-ref -1))))
              (check-exn exn:fail? (lambda () (setref! (a-ref 1) 0))))
   (test-case "newref y deref anidados"
              (check-equal? (corre "deref(deref(newref(newref(8))))") 8))
   (test-case "setref evalua de izquierda a derecha y el orden de begin se observa"
              (check-equal? (corre "let c = newref(1)
                                    in begin
                                         setref(c, *(deref(c), 10));
                                         setref(c, +(deref(c), 3));
                                         deref(c)
                                       end
                                    end") 13)
              (check-equal? (corre "begin 7 end") 7))
   (test-case "swap de una referencia consigo misma no pierde el valor"
              (check-equal? (corre "let a = newref(5) in begin swap(a, a); deref(a) end end") 5)
              (check-equal? (corre "let a = newref(5) in swap(a, a) end") 5))
   (test-case "swap retorna el contenido anterior de la segunda celda"
              (check-equal? (corre "let a = newref(1) b = newref(2)
                                    in +(swap(a, b), *(10, deref(a))) end") 22))
   (test-case "alias encadenado: tres nombres, una sola celda"
              (check-equal? (corre "let a = newref(1)
                                    in let b = a
                                       in let c = b
                                          in begin setref(c, 42); +(deref(a), deref(b)) end
                                          end
                                       end
                                    end") 84))
   (test-case "dos newref distintos no son alias"
              (check-equal? (corre "let a = newref(1) b = newref(1)
                                    in begin setref(a, 9); deref(b) end end") 1))
   (test-case "errores: operando que no es referencia, condicion no booleana"
              (check-exn exn:fail? (lambda () (corre "deref(true)")))
              (check-exn exn:fail? (lambda () (corre "setref(true, 1)")))
              (check-exn exn:fail? (lambda () (corre "swap(newref(1), 2)")))
              (check-exn exn:fail? (lambda () (corre "if 1 then 2 else 3 end"))))
   (test-case "copia-por-valor: valores simples iguales, referencia a celda nueva"
              (initialize-store!)
              (check-equal? (copia-por-valor 3) 3)
              (check-equal? (copia-por-valor #t) #t)
              (let* ((r (newref! 5))
                     (c (copia-por-valor r)))
                (check-false (= (posicion-de r) (posicion-de c)))
                (check-equal? (deref c) 5)
                (setref! c 77)
                (check-equal? (deref r) 5)))))

(define paso-por-referencia-adicional
  (test-suite
   "Parte 2 (adicional): applyref"
   (test-case "un contador incrementado por applyref tres veces"
              (check-equal? (corre "let c = newref(0)
                                    in let inc = proc (r : refto(num)) setref(r, add1(deref(r))) end
                                       in begin
                                            applyref inc (c);
                                            applyref inc (c);
                                            applyref inc (c);
                                            deref(c)
                                          end
                                       end
                                    end") 3))
   (test-case "applyref con la misma celda en los dos parametros hace alias"
              (check-equal? (corre "let c = newref(1)
                                    in let f = proc (u : refto(num), v : refto(num))
                                                 begin setref(u, 10); deref(v) end
                                               end
                                       in applyref f (c, c) end
                                    end") 10))
   (test-case "apply con la misma celda en los dos parametros no hace alias"
              (check-equal? (corre "let c = newref(1)
                                    in let f = proc (u : refto(num), v : refto(num))
                                                 begin setref(u, 10); deref(v) end
                                               end
                                       in apply f (c, c) end
                                    end") 1))
   (test-case "applyref dentro de un procedimiento recursivo"
              (check-equal? (corre "let c = newref(5)
                                    in letrec num bajar (r : refto(num)) =
                                         if ==(deref(r), 0)
                                         then 0
                                         else begin setref(r, sub1(deref(r))); applyref bajar (r) end
                                         end
                                       in begin applyref bajar (c); deref(c) end
                                       end
                                    end") 0))
   (test-case "error: aridad incorrecta en applyref"
              (check-exn exn:fail?
                         (lambda () (corre "let c = newref(1)
                                            in let f = proc (u : refto(num), v : refto(num)) 0 end
                                               in applyref f (c) end
                                            end"))))
   (test-case "error: un identificador del ambiente inicial no es una referencia"
              (check-exn exn:fail?
                         (lambda () (corre "let f = proc (u : refto(num)) deref(u) end
                                            in applyref f (n) end"))))))

(define fallidas-adicionales
  (+ (run-tests almacen-adicional)
     (run-tests paso-por-referencia-adicional)))

(eopl:printf "~%==========================================~%")
(eopl:printf "  pruebas adicionales fallidas: ~s~%" fallidas-adicionales)
(eopl:printf "==========================================~%")
