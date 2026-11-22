#lang eopl
;Autores: Aura Maria Pelaez Luna 2459422, Valentina Valencia Lopez 2459626

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
;;; Pruebas del grupo
;;; ==========================================================


(define saldo-original
  "let saldo = newref(100)
in
  let retirar = proc (cuenta : refto(num), monto : num)
                  if >=(deref(cuenta), monto)
                  then begin
                         setref(cuenta, -(deref(cuenta), monto));
                         deref(cuenta)
                       end
                  else deref(cuenta)
                  end
                end
  in
    begin
      applyref retirar (saldo, q);
      deref(saldo)
    end
  end
end")

(define saldo-corregido
  "let saldo = newref(100)
in
  let retirar = proc (cuenta : refto(num), monto : refto(num))
                  if >=(deref(cuenta), deref(monto))
                  then begin
                         setref(cuenta, -(deref(cuenta), deref(monto)));
                         deref(cuenta)
                       end
                  else deref(cuenta)
                  end
                end
  in
    let retiro = newref(q)
    in
      begin
        applyref retirar (saldo, retiro);
        deref(saldo)
      end
    end
  end
end")

;;; ==========================================================
;;; Interprete
;;; ==========================================================

(define almacen-grupo
  (test-suite
   "Almacen, alias y errores"
   (test-case "swap de una referencia consigo misma"
              (check-equal? (corre "let a = newref(8)
in
  begin
    swap(a, a);
    deref(a)
  end
end") 8))
   (test-case "newref reserva celdas distintas"
              (check-equal? (corre "let a = newref(1)
    b = newref(1)
in
  begin
    setref(a, 50);
    deref(b)
  end
end") 1))
   (test-case "una referencia puede guardar otra referencia"
              (check-equal? (corre "let r = newref(newref(3))
in deref(deref(r))
end") 3))
   (test-case "setref evalua de izquierda a derecha"
              (check-equal? (corre "let c = newref(0)
in
  begin
    setref(c, begin setref(c, 1); 2 end);
    deref(c)
  end
end") 2))
   (test-case "los casos de error del interprete"
              (check-exn exn:fail? (lambda () (corre "if 1 then 2 else 3 end")))
              (check-exn exn:fail? (lambda () (corre "begin 1; deref(2) end")))
              (check-exn exn:fail? (lambda () (corre "swap(newref(1), 2)"))))
   (test-case "deref y setref! fuera de rango levantan error"
              (initialize-store!)
              (check-exn exn:fail? (lambda () (deref (a-ref 3))))
              (check-exn exn:fail? (lambda () (setref! (a-ref 0) 1))))
   (test-case "solo newref! hace crecer el almacen"
              (initialize-store!)
              (newref! 10)
              (newref! 20)
              (setref! (a-ref 0) 99)
              (check-equal? (get-store) '(99 20)))))

(define paso-por-referencia-grupo
  (test-suite
   "Paso por referencia"
   (test-case "alias con applyref"
              (check-equal? (corre "let c = newref(5)
in
  let d = c
  in
    let inc = proc (u : refto(num))
                setref(u, add1(deref(u)))
              end
    in
      begin
        applyref inc (d);
        applyref inc (c);
        deref(c)
      end
    end
  end
end") 7))
   (test-case "apply copia la celda y applyref la comparte"
              (check-equal? (corre "let c = newref(0)
in
  let f = proc (u : refto(num))
            begin setref(u, 7); deref(u) end
          end
  in +(apply f (c), deref(c))
  end
end") 7)
              (check-equal? (corre "let c = newref(0)
in
  let f = proc (u : refto(num))
            begin setref(u, 7); deref(u) end
          end
  in +(applyref f (c), deref(c))
  end
end") 14))
   (test-case "applyref con menos argumentos que parametros"
              (check-exn exn:fail?
                         (lambda () (corre "let a = newref(1)
in
  let f = proc (u : refto(num), v : refto(num))
            deref(u)
          end
  in applyref f (a)
  end
end"))))
   (test-case "el programa de saldo corregido retira 2"
              (check-equal? (corre saldo-corregido) 98))))

;;; ==========================================================
;;; Chequeador
;;; ==========================================================

(define bien-tipados-grupo
  (test-suite
   "Programas bien tipados"
   (test-case "if con entre"
              (check-equal? (tipo-de "if entre(n, 1, 20) then 1 else 2 end") "num"))
   (test-case "primitivas booleanas"
              (check-equal? (tipo-de "and(>(n, m), not(false))") "bool"))
   (test-case "letrec con recursion mutua"
              (check-equal? (tipo-de "letrec bool par (k : num) =
                                        if ==(k, 0) then true else apply impar (sub1(k)) end
                                      bool impar (k : num) =
                                        if ==(k, 0) then false else apply par (sub1(k)) end
                                      in apply par (4) end") "bool"))
   (test-case "procedimiento que recibe referencias"
              (check-equal? (tipo-de "proc (u : refto(num), v : refto(num)) swap(u, v) end")
                            "(refto(num) * refto(num) -> num)"))
   (test-case "el programa de saldo corregido"
              (check-equal? (tipo-de saldo-corregido) "num"))))

(define mal-tipados-grupo
  (test-suite
   "Mensajes de error adicionales"
   (test-case "el programa de saldo original no pasa el chequeador"
              (check-true (contiene? (mensaje-de saldo-original)
                                     "applyref exige identificadores de tipo refto(t); q tiene tipo num")))
   (test-case "swap con celdas de distinto tipo"
              (check-true (contiene? (mensaje-de "swap(newref(1), newref(true))")
                                     "swap exige celdas del mismo tipo")))
   (test-case "case con control que no es num"
              (check-true (contiene? (mensaje-de "case true of 1 => 1 otherwise => 2 end")
                                     "La expresion del case debe ser num, se encontro bool")))
   (test-case "case con ramas distintas"
              (check-true (contiene? (mensaje-de "case n of 1 => true otherwise => 2 end")
                                     "Las ramas del case deben coincidir: bool vs num")))
   (test-case "primitiva con argumento de tipo equivocado"
              (check-true (contiene? (mensaje-de "+(1, true)")
                                     "La primitiva + exige argumentos de tipo num, se encontro bool")))
   (test-case "applyref con tipo de celda distinto al del parametro"
              (check-true (contiene? (mensaje-de "let c = newref(true)
in
  let f = proc (u : refto(num)) deref(u) end
  in applyref f (c)
  end
end")
                                     "El argumento 1 debe ser refto(num), se encontro refto(bool)")))))

(define fallidas-grupo
  (+ (run-tests almacen-grupo)
     (run-tests paso-por-referencia-grupo)
     (run-tests bien-tipados-grupo)
     (run-tests mal-tipados-grupo)))

(eopl:printf "~%==========================================~%")
(eopl:printf "  pruebas fallidas del grupo: ~s~%" fallidas-grupo)
(eopl:printf "==========================================~%")