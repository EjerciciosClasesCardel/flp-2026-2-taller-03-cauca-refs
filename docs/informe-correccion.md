# Informe de corrección — Taller 3: Memoria y disciplina

**Curso:** Fundamentos de Interpretación y Compilación de Lenguajes
de Programación — Universidad del Valle, Sede Tuluá.

**Integrantes del grupo:**

| Nombre | Código | Correo institucional |
|--------|--------|----------------------|
| Aura Maria Pelaez Luna | 2459422 | aura.pelaez@correounivalle.edu.co |
| Valentina Valencia Lopez | 2459626 | valentina.valencia.lopez@correounivalle.edu.co |

---

## 1. Marco formal

### 1.1 Corrección de programas recursivos

Sea $f : A \to B$ una función y $A$ un conjunto definido
recursivamente. Sea $P_f$ un programa recursivo en Racket que
pretende calcular $f$. Decimos que $P_f$ es correcto con respecto a
su especificación si se cumple:

$$
\forall a \in A \,:\, P_f(a) = f(a)
$$

La estrategia de demostración es la **inducción estructural**
sobre $A$:

- **Caso base:** para cada valor básico $a_0 \in A$ se verifica
  $P_f(a_0) = f(a_0)$.
- **Caso inductivo:** asumiendo la **hipótesis de inducción**
  $P_f(a') = f(a')$ para las subestructuras $a'$ que forman $a$, se
  demuestra $P_f(a) = f(a)$.

### 1.2 Corrección de programas iterativos

Para un programa iterativo se formalizan un estado $s$, un estado
inicial $s_0$, un predicado $\text{es-final?}(s)$, una **invariante**
$\text{Inv}(s)$ y una transformación $\text{transformar}(s)$. La
corrección se argumenta demostrando que $\text{Inv}(s_0)$ se cumple al
inicio, que $\text{Inv}$ se conserva en cada paso, que en un estado final
$\text{Inv}$ implica la respuesta correcta y que el proceso termina (cota
estrictamente decreciente en $\mathbb{N}$). En este taller no hay
programas iterativos: las funciones del almacén se definen por recursión
sobre listas.

### 1.3 Modelo formal del almacén

Un almacén es una secuencia finita de valores
$\sigma = (v_0, v_1, \ldots, v_{n-1})$ con longitud $|\sigma| = n$. La
referencia $\ell_i$ es `(a-ref i)`; es **válida** en $\sigma$ si
$0 \le i < |\sigma|$. Se escribe $\sigma(\ell_i) = v_i$. Las operaciones
de `src/almacen.rkt` son:

- $\text{newref!}(\sigma, v) = (\sigma \cdot v,\ \ell_{|\sigma|})$, donde
  $\sigma \cdot v$ agrega $v$ al final.
- $\text{deref}(\sigma, \ell_i) = \sigma(\ell_i)$ si $\ell_i$ es válida; si no,
  `eopl:error`.
- $\text{setref!}(\sigma, \ell_i, v) = \sigma'$ con $\sigma'(\ell_i) = v$ y
  $\sigma'(\ell_j) = \sigma(\ell_j)$ para $j \ne i$, si $\ell_i$ es válida; si
  no, `eopl:error` y $\sigma$ queda intacto.

Sea $R$ el conjunto de referencias que `newref!` ha entregado desde que
el almacén se vació. `initialize-store!` deja $\sigma = ()$ y $R = \emptyset$.

---

## 2. Funciones analizadas

### 2.1 El almacén preserva su invariante (Parte 5.1)

**Invariante.** Las cuatro condiciones del enunciado se formalizan como
una propiedad $\text{Inv}(\sigma, R)$ sobre el estado y como una
postcondición de cada operación:

$$
\text{Inv}(\sigma, R) \;\equiv\; \forall \ell_i \in R \,:\; 0 \le i < |\sigma| \qquad \text{(C1)}
$$

- **(C1)** toda referencia entregada por `newref!` apunta a una celda existente: es $\text{Inv}(\sigma, R)$.
- **(C2)** el almacén solo crece por `newref!`: $|\text{setref!}(\sigma, \ell, v)| = |\sigma|$, $\text{deref}$ no cambia $\sigma$ y, si $(\sigma', \ell') = \text{newref!}(\sigma, v)$, entonces $|\sigma'| = |\sigma| + 1$.
- **(C3)** `setref!` modifica exactamente una celda: $\sigma'(\ell) = v$ y $\sigma'(\ell') = \sigma(\ell')$ para todo $\ell' \ne \ell$.
- **(C4)** `deref` y `setref!` sobre una referencia fuera de rango levantan `eopl:error`.

El invariante completo del enunciado es la conjunción $\text{C1} \land \text{C2} \land \text{C3} \land \text{C4}$: C1 es una propiedad del estado $(\sigma, R)$ y C2–C4 son lo que cada operación le garantiza a ese estado. «Preservar $\text{Inv}$» significa que, partiendo de un estado que cumple C1, cada operación lo deja en un estado que también lo cumple y satisface su parte de C2–C4.

**Código.**

```racket
(define reemplazar-celda
  (lambda (lst pos val)
    (cond
      ((null? lst) '())
      ((= pos 0) (cons val (cdr lst)))
      (else (cons (car lst) (reemplazar-celda (cdr lst) (- pos 1) val))))))

(define newref!
  (lambda (val)
    (let ((siguiente (length the-store)))
      (set! the-store (append the-store (list val)))
      (a-ref siguiente))))

(define setref!
  (lambda (ref val)
    (cases referencia ref
      (a-ref (pos)
        (if (posicion-valida? pos)
            (set! the-store (reemplazar-celda the-store pos val))
            (eopl:error 'setref! "Referencia fuera de rango: ~s" pos))))))
```

**Lema (`reemplazar-celda`).** Para toda lista $L$ y toda posición
$0 \le i < |L|$, si $L' = \text{reemplazar-celda}(L, i, v)$ entonces
$|L'| = |L|$, $L'(i) = v$ y $L'(j) = L(j)$ para $j \ne i$.

*Demostración* por inducción sobre $i$.

- **Caso base** ($i = 0$): $L'$ = `(cons v (cdr L))`. Tiene la longitud de $L$, su primer elemento es $v$ y el resto es el de $L$.
- **Caso inductivo** ($i > 0$): $L'$ = `(cons (car L) (reemplazar-celda (cdr L) (- i 1) v))`. Por hipótesis de inducción sobre `(cdr L)`, la cola tiene la misma longitud, vale $v$ en su posición $i-1$ (es decir, en la posición $i$ de $L'$) y coincide con la de $L$ en las demás. La cabeza no cambia. ∎

*Terminación:* la posición $i$ decrece en 1 en cada llamada y se detiene en 0. Como $i < |L|$, la lista nunca se vacía antes de llegar a 0.

**Demostración de que cada operación preserva $\text{Inv}$.**

- **Inicio.** Tras `initialize-store!`, $R = \emptyset$ y $\text{Inv}$ se cumple por vacuidad.

- **`newref!`.** Sea $n = |\sigma|$, $\sigma' = \sigma \cdot v$ y $R' = R \cup \{\ell_n\}$.
  - Agrega exactamente una celda: $|\sigma'| = n + 1$ (C2).
  - Retorna una referencia válida: $0 \le n < n + 1 = |\sigma'|$.
  - No altera las existentes: para $j < n$, $\sigma'(\ell_j) = \sigma(\ell_j)$, porque `append` conserva el prefijo.
  - $\text{Inv}(\sigma', R')$: para $\ell_i \in R$, $i < n < |\sigma'|$ por $\text{Inv}(\sigma, R)$; para $\ell_n$ ya se probó.

- **`setref!`.** Sea $\ell_i$ válida y $\sigma'$ el resultado.
  - Por el lema, $|\sigma'| = |\sigma|$ (C2), $\sigma'(\ell_i) = v$ y $\sigma'(\ell_j) = \sigma(\ell_j)$ para $j \ne i$ (C3). Esto es la condición formal del enunciado.
  - $R' = R$ y la longitud no cambia, así que $\text{Inv}(\sigma', R)$ se mantiene.
  - Si $\ell_i$ no es válida, la verificación `posicion-valida?` ocurre *antes* del `set!`: se levanta el error y $\sigma$ queda intacto (C4).

- **`deref`.** No contiene ningún `set!`, así que $\sigma' = \sigma$ y $R' = R$; $\text{Inv}$ se conserva trivialmente. Retorna $\sigma(\ell_i)$ si $\ell_i$ es válida y levanta error si no (C4).

**Conclusión.** Las tres operaciones preservan $\text{Inv}$ y cumplen C2–C4; como el único estado inicial posible es el vacío, $\text{Inv}$ vale en todo momento de la ejecución de un programa. La longitud solo cambia en `newref!`.

---

### 2.2 Corrección de `swap-exp` (Parte 5.2)

**Especificación.**

- **Tipo:** `swap-exp : expresion x expresion x ambiente -> valor` (dentro de `evaluar-expresion`).
- **Pre-condición:** las expresiones evalúan, de izquierda a derecha, a dos referencias $\ell_1$ y $\ell_2$ válidas en el almacén $\sigma$ que queda después de evaluarlas (evaluar los operandos puede reservar celdas, por ejemplo `swap(newref(1), newref(2))`).
- **Post-condición:** si $\sigma'$ es el almacén después y $r$ el valor retornado,

$$
\sigma'(\ell_1) = \sigma(\ell_2), \qquad \sigma'(\ell_2) = \sigma(\ell_1), \qquad \sigma'(\ell) = \sigma(\ell) \ \ \forall \ell \notin \{\ell_1, \ell_2\}, \qquad r = \sigma(\ell_2).
$$

**Código.**

```racket
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
```

**Estrategia de demostración:** análisis de casos sobre si $\ell_1 = \ell_2$, usando la propiedad C3 de `setref!` (sección 2.1). No hay recursión propia, así que no hay inducción ni problema de terminación: `swap` hace dos lecturas y dos escrituras.

**Demostración.** Sean $i$ y $j$ las posiciones de $\ell_1$ y $\ell_2$. Se leen $v_1 = \sigma(\ell_1)$ y $v_2 = \sigma(\ell_2)$ **antes** de escribir, y `let*` los guarda en variables. Luego $\sigma_1 = \text{setref!}(\sigma, \ell_1, v_2)$ y $\sigma' = \text{setref!}(\sigma_1, \ell_2, v_1)$.

**El valor original de la primera celda no se pierde.** $v_1$ queda guardado en una variable local antes de la primera escritura, que sobrescribe $\ell_1$; la segunda escritura usa esa variable y no relee la celda. Si `swap` hiciera `(setref! ref1 (deref ref2))` seguido de `(setref! ref2 (deref ref1))`, la segunda lectura vería ya el valor nuevo y los dos contenidos quedarían iguales.

- **Caso $\ell_1 \ne \ell_2$** ($i \ne j$). Por C3 aplicado a $\sigma_1$: $\sigma_1(\ell_1) = v_2$ y $\sigma_1(\ell) = \sigma(\ell)$ para $\ell \ne \ell_1$. Por C3 aplicado a $\sigma'$:
  - $\sigma'(\ell_2) = v_1 = \sigma(\ell_1)$ ✓
  - $\sigma'(\ell_1) = \sigma_1(\ell_1) = v_2 = \sigma(\ell_2)$ (se usa $i \ne j$ para que la segunda escritura no pise la primera) ✓
  - para $\ell \notin \{\ell_1, \ell_2\}$: $\sigma'(\ell) = \sigma_1(\ell) = \sigma(\ell)$ ✓

- **Caso $\ell_1 = \ell_2$** ($i = j$, intercambio de una referencia consigo misma). La especificación pide $\sigma'(\ell_1) = \sigma(\ell_2) = \sigma(\ell_1)$, o sea que la celda conserva su contenido, y que todas las demás queden igual: es decir $\sigma' = \sigma$. En la implementación $v_1 = v_2 = \sigma(\ell_1)$, así que $\sigma_1(\ell_1) = v_2 = \sigma(\ell_1)$ y $\sigma'(\ell_1) = v_1 = \sigma(\ell_1)$; las demás celdas no cambian por C3. Entonces $\sigma' = \sigma$ ✓. Se comprueba con el programa `let a = newref(8) in begin swap(a, a); deref(a) end end`, que evalúa a 8.

- **Valor retornado.** La función retorna `v2`, que se leyó de $\ell_2$ antes de cualquier escritura: $r = v_2 = \sigma(\ell_2)$. Es el contenido anterior de la segunda celda, que ahora es el contenido de la primera: $r = \sigma'(\ell_1)$. ✓

- **Operandos que no son referencias.** Si alguno falla `referencia?`, se levanta `eopl:error` antes de cualquier `setref!`, y $\sigma$ queda intacto.

**Conclusión.** `swap-exp` cumple la especificación para todo par de referencias válidas, incluido $\ell_1 = \ell_2$, y retorna el contenido anterior de la segunda celda. Además preserva $\text{Inv}$ porque solo usa `deref` y `setref!` (sección 2.1). ∎

---

## 3. Propiedades adicionales

### 3.1 Solidez del chequeador (Parte 5.3)

**Fragmento sin referencias.** Se considera Cauca con literales, booleanos,
variables, primitivas, `if`, `let`, `proc`, `apply`, `letrec` y `case`.

**Valores de cada tipo.** Se define $[\![ t ]\!]$ por recursión sobre $t$:

- $[\![ \text{num} ]\!]$ = los números; $[\![ \text{bool} ]\!] = \lbrace \text{true}, \text{false} \rbrace$.
- $[\![ t_1 * \cdots * t_n \to t ]\!]$ = las clausuras `(cerradura xs c ρ_c)` con $|xs| = n$ para las cuales existe $\Gamma_c$ tal que $\rho_c \models \Gamma_c$ y $\Gamma_c[x_i \mapsto t_i] \vdash c : t$.

**Concordancia entre $\rho$ y $\Gamma$.** El ambiente de valores $\rho$ *concuerda* con el de tipos $\Gamma$, escrito $\rho \models \Gamma$, si para todo identificador $x$ declarado en $\Gamma$ el ambiente $\rho$ también lo liga y $\rho(x) \in [\![ \Gamma(x) ]\!]$. Se busca siempre la ligadura más reciente en ambos, así que $\rho$ y $\Gamma$ se extienden en paralelo, y de esto sale el **lema de extensión**:

$$
\rho \models \Gamma \ \land\ v_i \in [\![ t_i ]\!] \ \Longrightarrow\ \rho[x_i \mapsto v_i] \models \Gamma[x_i \mapsto t_i].
$$

(el shadowing es el mismo en los dos lados). El ambiente inicial concuerda con `tenv-inicial`: las cinco variables valen números.

**Enunciado.**

$$
\Gamma \vdash e : t \ \land\ \rho \models \Gamma \ \land\ \rho \vdash e \Downarrow v \ \Longrightarrow\ v \in [\![ t ]\!]
$$

donde $\rho \vdash e \Downarrow v$ significa que `(value-of e ρ)` termina con valor $v$. La solidez no promete terminación (un `letrec` puede divergir) ni descarta errores que no son de tipo (como la división por cero). Lo que promete es que, si la evaluación termina, el valor tiene el tipo $t$ y que **no se disparan los errores de tipo del evaluador**: condición de `if` no booleana, operador que no es procedimiento o aridad incorrecta, primitiva con operandos del tipo equivocado.

**Estrategia.** Inducción sobre la derivación de la evaluación $\rho \vdash e \Downarrow v$, con análisis por la última regla de tipado de $e$. Para `if` esa derivación tiene la misma forma que la de tipos. Para `apply` no se puede inducir sobre la derivación de tipos: el cuerpo de la clausura no es una subderivación de la de `apply`. La evaluación sí contiene la del cuerpo como subderivación, y por eso se induce sobre ella.

**Caso `if`.** La derivación de tipos termina con $\Gamma \vdash e_1 : \text{bool}$, $\Gamma \vdash e_2 : t$ y $\Gamma \vdash e_3 : t$. La evaluación empieza con $\rho \vdash e_1 \Downarrow v_1$. Por hipótesis de inducción, $v_1 \in [\![ \text{bool} ]\!]$, así que el `boolean?` del evaluador se cumple y no se levanta el error de condición. Si $v_1 = \#t$, se evalúa solo $e_2$ con $\rho \vdash e_2 \Downarrow v$ y por hipótesis de inducción $v \in [\![ t ]\!]$. Si $v_1 = \#f$, igual con $e_3$. En los dos casos el resultado es de tipo $t$ porque *ambas* ramas tienen el mismo tipo $t$. Esa es la razón de la regla: el chequeador no sabe cuál rama se ejecutará. ∎

**Caso `apply`.** La derivación termina con $\Gamma \vdash f : (t_1 * \cdots * t_n \to t)$ y $\Gamma \vdash e_i : t_i$ para $1 \le i \le n$. La evaluación empieza con $\rho \vdash f \Downarrow c$ y $\rho \vdash e_i \Downarrow v_i$.

1. Por hipótesis de inducción, $c \in [\![ t_1 * \cdots * t_n \to t ]\!]$. Entonces $c$ es una clausura (el chequeo `procval?` pasa) `(cerradura xs body ρ_c)` con $|xs| = n$ (el chequeo de aridad de `apply-procedure` pasa) y existe $\Gamma_c$ con $\rho_c \models \Gamma_c$ y $\Gamma_c[x_i \mapsto t_i] \vdash body : t$.
2. Por hipótesis de inducción, $v_i \in [\![ t_i ]\!]$. En el fragmento sin referencias, `copia-por-valor` es la identidad (un número, un booleano o un procedimiento se copian como ellos mismos), así que los argumentos que entran son los mismos $v_i$.
3. Por el lema de extensión, $\rho_c[x_i \mapsto v_i] \models \Gamma_c[x_i \mapsto t_i]$.
4. El cuerpo se evalúa en ese ambiente, $\rho_c[x_i \mapsto v_i] \vdash body \Downarrow v$, y esa evaluación es una subderivación de la de `apply`. Por hipótesis de inducción con $\Gamma_c[x_i \mapsto t_i] \vdash body : t$, se obtiene $v \in [\![ t ]\!]$. ∎

Los demás casos que alimentan al de `apply`: en `proc`, $\Gamma \vdash \text{proc}(x_i : t_i)\ c : (t_1 * \cdots \to t)$ con $\rho \models \Gamma$ produce la clausura `(cerradura xs c ρ)`, que está en $[\![ t_1 * \cdots \to t ]\!]$ tomando $\Gamma_c = \Gamma$. En `letrec`, `apply-env` construye la clausura con el ambiente recursivo $\rho'$, y la regla de `letrec` ($\Gamma' \,[x_{ji} \mapsto t_{ji}] \vdash c_j : r_j$) es justo la condición que necesita esa clausura. Aquí hay una circularidad: $\rho' \models \Gamma'$ pide que cada $f_j$ sea una clausura bien tipada, y esa clausura se construye con $\rho'$. Se resuelve extendiendo la concordancia al ambiente recursivo por definición: $\rho' \models \Gamma'$ vale cuando cada $f_j$ resuelve a la clausura de $c_j$ en $\rho'$ y se cumple la premisa de la regla. Para $[\![ \cdot ]\!]$ esto es una definición coinductiva, o por inducción sobre el número de llamadas, y por eso en el fragmento sin referencias la demostración detallada se limita a `if` y `apply`, que son los casos que pide el enunciado.

**Qué se rompe al agregar referencias.** Con `newref`, `deref`, `setref!` y `swap` el valor de $e$ ya no depende solo de $\rho$: depende del almacén $\sigma$, y evaluar lo cambia. La evaluación pasa a ser $(\rho, \sigma) \vdash e \Downarrow (v, \sigma')$ y el enunciado `value-of(e, ρ)` pierde sentido. Además, el valor `(a-ref 3)` no es de tipo $\text{refto}(\text{num})$ por sí mismo: lo es solo si la celda 3 contiene un número *en ese almacén*, de modo que $[\![ \text{refto}(t) ]\!]$ depende de $\sigma$. En el caso `deref` no se puede demostrar $v \in [\![ t ]\!]$ solo con $\rho \models \Gamma$: hay que saber que lo guardado en la celda es de tipo $t$.

La propiedad correcta lleva un **tipo de almacén** $\Sigma$ (las posiciones con el tipo que cada celda promete) y una concordancia $\sigma \models \Sigma$ entre el almacén y ese tipo:

$$
\Gamma \vdash e : t \ \land\ \rho \models_\Sigma \Gamma \ \land\ \sigma \models \Sigma \ \land\ (\rho, \sigma) \vdash e \Downarrow (v, \sigma') \ \Longrightarrow\ \exists \Sigma' \supseteq \Sigma \,:\ v \in [\![ t ]\!]_{\Sigma'} \ \land\ \sigma' \models \Sigma'
$$

$\Sigma'$ puede ser mayor que $\Sigma$ porque `newref` agrega celdas, y los valores bien tipados antes siguen bien tipados después. Las reglas de `setref` y `swap` ($e_2 : t$ cuando $e_1 : \text{refto}(t)$) son las que garantizan $\sigma' \models \Sigma'$: escribir en una celda un valor del tipo que la celda prometía no rompe la concordancia, y por eso una celda no puede cambiar de tipo a mitad de ejecución.

---

### 3.2 Paso por valor frente a paso por referencia

**Propiedad.** Con `applyref`, el parámetro queda ligado a la misma referencia del argumento, así que una escritura dentro del procedimiento se observa fuera. Con `apply`, `copia-por-valor` reserva una celda nueva con el mismo contenido, así que no.

**Demostración.** Sea $\sigma$ el almacén y $\ell$ la referencia del argumento.

- `applyref`: `buscar-referencias` entrega $\ell$ y `apply-procedure` extiende el ambiente con el parámetro ligado a $\ell$; todo `setref!` sobre el parámetro escribe en $\ell$, por lo que $\sigma'(\ell)$ cambia.
- `apply`: `copia-por-valor` reserva $\ell'$ con $\text{newref!}(\sigma, \sigma(\ell)) = (\sigma \cdot \sigma(\ell), \ell_{|\sigma|})$; el parámetro queda ligado a $\ell' \ne \ell$ y toda escritura va a $\ell'$. Por C3 la celda $\ell$ no cambia.

El programa del `swap` separa los dos mecanismos: $-7$ con `applyref` y $7$ con `apply` (ver el anexo del informe de AST).

---

## 4. Referencias

- Friedman, D. P., & Wand, M. *Essentials of Programming Languages*,
  3.ª ed., MIT Press, 2008. Sección 4.2 (EXPLICIT-REFS, Figura 4.3),
  sección 4.3 (paso por referencia) y capítulo 7 (chequeo de tipos,
  secciones 7.1 a 7.3).
- Pierce, B. C. *Types and Programming Languages*, MIT Press, 2002.
  Capítulos 8 (tipos y seguridad) y 13 (referencias).