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
| {{Nombre 1}} | {{Código 1}} | {{correo1@correounivalle.edu.co}} |
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

### 2.1 Corrección de `{{nombre-funcion-1}}`

**Especificación.**

- **Tipo:** `{{nombre-funcion-1}} : {{Tipo de entrada}} -> {{Tipo de salida}}`
- **Pre-condición:** $\text{Pre}(a) \equiv \{{\ldots}\}$.
- **Post-condición:** $\text{Post}(a, r) \equiv r = f(a)$, donde
  $f$ es {{descripción matemática de la función}}.

**Código.**

```racket
; {{nombre-funcion-1}} : {{contrato}}
; Propósito: {{...}}
(define ({{nombre-funcion-1}} ...)
  ...)
```

**Estrategia de demostración:** {{recursión estructural sobre ... /
iteración con invariante ...}}.

**Demostración.**

- **Caso base** ($a = {{\ldots}}$):

  $$
  P_f({{\ldots}}) \to {{\ldots}} \quad \land \quad f({{\ldots}}) = {{\ldots}}
  $$

  Por lo tanto $P_f({{\ldots}}) = f({{\ldots}})$.

- **Caso inductivo** ($a = {{\ldots}}$): asumimos la hipótesis de
  inducción $P_f(a') = f(a')$ para {{las subestructuras de $a$}}.

  $$
  P_f(a) \to {{\ldots (aplicar una evaluación) \ldots}}
  $$

  Usando la hipótesis de inducción:

  $$
  \quad = {{\ldots}} = f(a).
  $$

- **Terminación.** {{Identifique la medida que decrece estrictamente
  en cada llamada recursiva — por ejemplo, la longitud de la lista o
  el tamaño del AST — y argumente que está acotada inferiormente.}}

**Conclusión:** $\forall a \in A \,:\, P_f(a) = f(a)$, por lo tanto
`{{nombre-funcion-1}}` es correcta respecto a su especificación.

---

### 2.2 Corrección de `{{nombre-funcion-2}}`

**Especificación.**

- **Tipo:** `{{...}}`
- **Pre-condición:** $\{{\ldots}\}$.
- **Post-condición:** $\{{\ldots}\}$.

**Código.**

```racket
(define ({{nombre-funcion-2}} ...)
  ...)
```

**Demostración.** {{Siga el mismo esquema: casos base, caso
inductivo con hipótesis de inducción y terminación. Para casos de
error explícitos —por ejemplo `eopl:error` cuando una condición no
es booleana— demuestre que el programa levanta el error en ese caso y
sólo en ese caso.}}

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
- {{Otras referencias que hayan consultado.}}
