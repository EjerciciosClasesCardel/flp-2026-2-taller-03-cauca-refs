# Informe de corrección — {{Nombre del taller / entrega}}

> **Plantilla de entrega.** Copie este archivo a
> `docs/informe-correccion.md` dentro del repositorio del grupo y
> reemplace los marcadores `{{...}}` con su contenido.
> **No elimine las secciones obligatorias.** No se aceptan PDF, DOCX
> ni imágenes insertadas: todo el documento debe ser Markdown, las
> fórmulas en LaTeX (`$...$` / `$$...$$`) y los diagramas en Mermaid.

**Curso:** Fundamentos de Interpretación y Compilación de Lenguajes
de Programación — Universidad del Valle, Sede Tuluá.

**Integrantes del grupo:**

| Nombre | Código | Correo institucional |
|--------|--------|----------------------|
| Juan Eduardo Calderon Jaramillo | 2611001-3743 | juan.eduardo.calderon@correounivalle.edu.co |
| {{Nombre 2}} | {{Código 2}} | {{correo2@correounivalle.edu.co}} |

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

Para un programa iterativo se formalizan:

- Un estado $s$ con componentes relevantes.
- Un estado inicial $s_0$.
- Un estado final reconocido por un predicado $\text{es-final?}(s)$.
- Una **invariante** $\text{Inv}(s)$ que se mantiene entre pasos.
- Una transformación $\text{transformar}(s)$.

La corrección se argumenta demostrando:

1. $\text{Inv}(s_0)$ se cumple al inicio.
2. $\text{Inv}(s) \,\land\, \lnot\text{es-final?}(s)\Rightarrow
   \text{Inv}(\text{transformar}(s))$.
3. $\text{Inv}(s) \,\land\, \text{es-final?}(s)\Rightarrow
   \text{respuesta}(s) = f(\text{entrada})$.
4. El proceso termina (argumentar una función de cota estrictamente
   decreciente sobre $\mathbb{N}$).

---

## 2. Funciones analizadas

> Complete **una subsección por cada función pedida en el enunciado**.
> Copie la plantilla de subsección tantas veces como sea necesario.

### 2.1 Corrección de las operaciones del almacén (enunciado 5.1)

**Modelo.** Un almacén es una secuencia finita de valores
$\sigma = \langle v_0, \ldots, v_{n-1} \rangle$ con $|\sigma| = n$. Una
referencia $\ell = \texttt{(a-ref } k\texttt{)}$ nombra la celda $k$, y se
escribe $\sigma(\ell) = v_k$ cuando $0 \le k < n$. En el código el
almacén es la lista `the-store` de `src/almacen.rkt`, y `empty-store`
es `'()`. Sea $E$ el conjunto de referencias que `newref!` ha entregado
desde el último `initialize-store!`. Esas son las únicas referencias que
existen: el TAD no deja que un programa de Cauca fabrique una
`a-ref` a partir de un número.

**Invariante.** El par $(\sigma, E)$ cumple $\text{Inv}(\sigma, E)$ si:

1. **(Sin huecos)** las celdas de $\sigma$ son exactamente las posiciones
   $0, \ldots, |\sigma|-1$.
2. **(Referencias válidas)** $\forall\, \texttt{(a-ref } k\texttt{)} \in E:\ 0 \le k < |\sigma|$.

A esto se suman las tres condiciones sobre las operaciones, que son
parte de su contrato y se demuestran abajo:

3. **(Crecimiento)** $|\sigma'| = |\sigma| + 1$ si la operación es
   `newref!`, y $|\sigma'| = |\sigma|$ en cualquier otro caso.
4. **(Localidad)** si $\sigma' = \texttt{setref!}(\sigma, \ell, v)$, entonces
   $\sigma'(\ell) = v$ y $\sigma'(\ell') = \sigma(\ell')$ para todo
   $\ell' \neq \ell$.
5. **(Rango)** `deref` y `setref!` sobre $\ell = \texttt{(a-ref } k\texttt{)}$ con
   $k \notin [0, |\sigma|)$ levantan `eopl:error`.

**Estado inicial.** `initialize-store!` hace
$\sigma := \langle\rangle$ y $E := \emptyset$. Las dos partes del
invariante se cumplen por vacuidad, así que $\text{Inv}(\langle\rangle, \emptyset)$.

**Lema (`reemplazar-celda`).** Sea $\texttt{lst}$ una lista y
$0 \le k < |\texttt{lst}|$. Si $\texttt{lst}' = \texttt{(reemplazar-celda lst } k\ v\texttt{)}$, entonces
$|\texttt{lst}'| = |\texttt{lst}|$, $\texttt{lst}'(k) = v$ y
$\texttt{lst}'(i) = \texttt{lst}(i)$ para todo $i \neq k$.

*Demostración, por inducción sobre $k$.*

- **Caso base** ($k = 0$). El código retorna `(cons v (cdr lst))`. La
  longitud es $1 + (|\texttt{lst}|-1) = |\texttt{lst}|$. La posición $0$ vale $v$,
  y para $i \ge 1$ la posición $i$ de `(cons v (cdr lst))` es la $i-1$ de
  `(cdr lst)`, que es $\texttt{lst}(i)$.
- **Caso inductivo** ($k > 0$). Como $k < |\texttt{lst}|$, la lista no es vacía y el
  código retorna `(cons (car lst) (reemplazar-celda (cdr lst) (- k 1) v))`.
  Como $k - 1 < |\texttt{(cdr lst)}|$, la hipótesis de inducción aplica a
  `(cdr lst)`: el resultado de la llamada recursiva tiene la misma
  longitud, vale $v$ en $k-1$ y coincide con `(cdr lst)` en el resto.
  Al anteponer `(car lst)` la longitud no cambia respecto a `lst`, la
  posición $0$ sigue siendo $\texttt{lst}(0)$ (y $0 \neq k$), la posición
  $k$ vale $v$ y cada $i \ge 1$, $i \neq k$, vale $\texttt{lst}(i)$. $\blacksquare$

**(a) `newref!` preserva $\text{Inv}$.** Con $n = |\sigma|$, el código toma
`pos` $= n$, hace $\sigma' = \sigma \mathbin{+\!\!+} \langle v \rangle$ con
`append` y retorna $\ell_{\text{new}} = \texttt{(a-ref } n\texttt{)}$.

- **Celdas existentes intactas:** $\sigma'(i) = \sigma(i)$ para $i < n$,
  porque `append` solo agrega al final. Además $\sigma'(n) = v$.
- **Crecimiento (3):** $|\sigma'| = n + 1$, es decir, crece exactamente en una celda.
- **Sin huecos (1):** las posiciones de $\sigma'$ son $0, \ldots, n$.
- **Referencias válidas (2):** $E' = E \cup \{\ell_{\text{new}}\}$. Las
  de $E$ cumplían $k < n < n+1$, y la nueva cumple $n < n+1$.
  La referencia entregada apunta a una celda existente.

Por lo tanto $\text{Inv}(\sigma', E')$.

**(b) `setref!` preserva $\text{Inv}$.** Sea $\ell = \texttt{(a-ref } k\texttt{)}$.

- **$k$ fuera de rango.** `posicion-valida?` es falsa y el `if` levanta
  `eopl:error` antes del `set!`. El almacén no se toca y se cumple (5).
- **$k$ en rango.** El código hace
  $\sigma' = \texttt{(reemplazar-celda } \sigma\ k\ v\texttt{)}$. Por el lema:
  $|\sigma'| = |\sigma|$, $\sigma'(\ell) = v$ y $\sigma'(\ell') = \sigma(\ell')$
  para todo $\ell' \neq \ell$. Eso es la localidad (4). Como la longitud
  y $E$ no cambian, (1) y (2) siguen valiendo. La condición (3) se cumple
  porque el almacén no crece.

Por lo tanto $\text{Inv}(\sigma', E)$.

**(c) `deref` preserva $\text{Inv}$.** El código es un `cases` seguido de
`list-ref`. No ejecuta ningún `set!`, así que $\sigma' = \sigma$ y $E' = E$,
y el invariante se conserva trivialmente, con $|\sigma'| = |\sigma|$ (3).
Si $k \notin [0, |\sigma|)$ levanta `eopl:error` (5); si no, retorna
$\sigma(\ell)$.

**Conclusión.** Todo programa empieza con `initialize-store!` (lo hace
`evaluar-programa`), y las únicas operaciones que tocan `the-store` son
`newref!`, `setref!` e `initialize-store!`. Por inducción sobre la
longitud de la secuencia de operaciones ejecutadas, $\text{Inv}(\sigma, E)$
vale en todo estado alcanzable, y las condiciones (3), (4) y (5) valen
para cada operación. Es decir, el almacén solo crece por `newref!`,
`setref!` modifica exactamente una celda, y `deref` fuera de rango falla.

---

### 2.2 Corrección de `swap-exp` (enunciado 5.2)

**Especificación.** Sean $\ell_1, \ell_2$ referencias válidas en $\sigma$
(es decir, $\ell_1, \ell_2 \in \text{dom}(\sigma)$). Si la evaluación de
$\texttt{swap}(\ell_1, \ell_2)$ deja el almacén $\sigma'$ y retorna $r$,
entonces:

$$
\sigma'(\ell_1) = \sigma(\ell_2), \qquad
\sigma'(\ell_2) = \sigma(\ell_1), \qquad
\sigma'(\ell) = \sigma(\ell)\ \ \forall\, \ell \notin \{\ell_1, \ell_2\}, \qquad
r = \sigma(\ell_2).
$$

Además $|\sigma'| = |\sigma|$. Si $\ell_1$ o $\ell_2$ no es una referencia,
la evaluación levanta `eopl:error` sin modificar el almacén.

**Código** (cláusula de `swap-exp` en `src/interprete.rkt`):

```racket
(swap-exp (ref1-exp ref2-exp)
  (let* ((r1 (evaluar-expresion ref1-exp env))
         (r2 (evaluar-expresion ref2-exp env)))
    (exigir-referencia r1 'swap)
    (exigir-referencia r2 'swap)
    (let ((v1 (deref r1))
          (v2 (deref r2)))
      (setref! r1 v2)
      (setref! r2 v1)
      v2)))
```

**Demostración.** Sean $v_1 = \sigma(\ell_1)$ y $v_2 = \sigma(\ell_2)$, los
valores que leen los dos `deref` del `let`. Estos se evalúan sobre
$\sigma$ sin modificarlo (sección 2.1, (c)). Sean
$\sigma_1 = \texttt{setref!}(\sigma, \ell_1, v_2)$ y
$\sigma_2 = \texttt{setref!}(\sigma_1, \ell_2, v_1)$. Entonces
$\sigma' = \sigma_2$. Por localidad (sección 2.1, (4)):

- $\sigma_1(\ell_1) = v_2$ y $\sigma_1(\ell) = \sigma(\ell)$ para $\ell \neq \ell_1$.
- $\sigma_2(\ell_2) = v_1$ y $\sigma_2(\ell) = \sigma_1(\ell)$ para $\ell \neq \ell_2$.

*Caso $\ell_1 \neq \ell_2$.*

- $\sigma'(\ell_1) = \sigma_2(\ell_1) = \sigma_1(\ell_1) = v_2 = \sigma(\ell_2)$. La
  segunda igualdad usa $\ell_1 \neq \ell_2$.
- $\sigma'(\ell_2) = \sigma_2(\ell_2) = v_1 = \sigma(\ell_1)$.
- Para $\ell \notin \{\ell_1, \ell_2\}$: $\sigma'(\ell) = \sigma_1(\ell) = \sigma(\ell)$.

*El valor original de la primera celda no se pierde.* $v_1$ se guardó en
una variable local antes de que `setref!` sobrescribiera $\ell_1$, y es
lo que se escribe en $\ell_2$. Por eso la implementación lee las dos celdas
antes de escribir ninguna. La variante ingenua
`(setref! r1 (deref r2))` seguida de `(setref! r2 (deref r1))` falla: la
segunda lectura ya vería $v_2$ en $\ell_1$ y dejaría las dos celdas con
$\sigma(\ell_2)$, perdiendo $v_1$.

*Caso $\ell_1 = \ell_2 = \ell$.* La especificación exige
$\sigma'(\ell) = \sigma(\ell)$ por cualquiera de sus dos primeras
ecuaciones (coinciden), y que el resto quede igual; o sea, $\sigma' = \sigma$.
En la implementación $v_1 = v_2 = \sigma(\ell) =: x$. Entonces
$\sigma_1(\ell) = x$, y $\sigma_1 = \sigma$ por localidad. Después
$\sigma_2(\ell) = v_1 = x$ y $\sigma_2 = \sigma_1 = \sigma$. El almacén
queda igual, como exige la especificación. Esto se cumple porque las dos
lecturas se hicieron antes de escribir: aquí no hay nada que perder, pero la
cláusula no necesita un caso aparte.

*Valor retornado.* El `let` retorna $v_2 = \sigma(\ell_2)$, el contenido
anterior de la segunda celda. Como $\sigma'(\ell_1) = \sigma(\ell_2)$ en
ambos casos, también es el valor que quedó en la primera referencia, como
pide el enunciado. Con $\ell_1 = a$, $\sigma(a) = 7$ y $\ell_2 = b$,
$\sigma(b) = 2$, `swap(a, b)` retorna $2$, que es lo que prueba
`swap(a, b)` en `pruebas-cauca-refs.rkt`.

*Errores sin escrituras parciales.* `exigir-referencia` se ejecuta sobre
las dos referencias antes de cualquier `setref!`, y los dos `deref` se
ejecutan antes de ellos. Si $\ell_1$ o $\ell_2$ no es una referencia, o
está fuera de rango, `eopl:error` se levanta antes de la primera
escritura, y el almacén queda como estaba.

*Invariante.* `swap-exp` solo usa `deref` y `setref!`, que preservan
$\text{Inv}$ (sección 2.1). Aquí $|\sigma'| = |\sigma|$ porque ninguna
llama a `newref!`.

**Conclusión:** la cláusula de `swap-exp` satisface la especificación,
incluido el caso $\ell_1 = \ell_2$ y el valor retornado.

---

### 2.3 Corrección de `{{nombre-funcion-3}}`

{{Repetir la misma estructura.}}

---

## 3. Propiedades adicionales (si aplica)

Incluya en esta sección cualquier propiedad adicional que el
enunciado exija demostrar, por ejemplo:

- **Shadowing de ambientes** (`apply-env`): la ligadura más reciente
  tiene prioridad sobre las anteriores.
- **Secuencialidad de `let*`**: cada ligadura se evalúa en un
  ambiente que incluye las anteriores.
- **Equivalencia semántica** entre dos implementaciones (por ejemplo,
  representación basada en listas vs. basada en procedimientos de un
  mismo TAD).
- **Invariante del almacén**: si $\sigma' = \text{setref!}(\sigma, \ell, v)$,
  entonces $\sigma'(\ell) = v$ y $\sigma'(\ell') = \sigma(\ell')$ para todo
  $\ell' \neq \ell$. La operación que reserva una celda es la única que
  cambia la longitud del almacén.
- **Invariante de la transacción**: sea $\sigma_0$ el almacén al entrar a
  un bloque `atomic` y $\sigma$ el almacén en el momento de abortar. Si
  el registro de la transacción guarda, para cada celda $\ell$ escrita
  dentro del bloque, el valor $\sigma_0(\ell)$ que tenía al entrar, y la
  longitud $|\sigma_0|$, entonces revertir devuelve exactamente
  $\sigma_0$: las celdas registradas recuperan su valor, las que no se
  escribieron nunca cambiaron, y las creadas adentro (posiciones
  $\geq |\sigma_0|$) desaparecen. Demostrar por inducción sobre el
  número de escrituras del bloque, y tratar aparte el caso de una
  transacción hija que confirmó antes de que la padre abortara.
- **Paso por referencia**: el parámetro queda ligado a la misma
  referencia del argumento, de modo que una escritura dentro del
  procedimiento se observa fuera. Contrastar con el paso por valor
  sobre el mismo programa.
- **Solidez de un chequeador de tipos**: si $\Gamma \vdash e : t$ y el
  ambiente de valores $\rho$ concuerda con el ambiente de tipos
  $\Gamma$, entonces $\text{value-of}(e, \rho)$ es un valor de tipo
  $t$. Precisar primero qué significa la concordancia entre $\rho$ y
  $\Gamma$.

Cada propiedad debe enunciarse formalmente y demostrarse con el
mismo rigor que las funciones anteriores.

---

## 4. Referencias

- Friedman, D. P., & Wand, M. *Essentials of Programming Languages*,
  3.ª ed., MIT Press, 2008. Secciones {{…}}.
