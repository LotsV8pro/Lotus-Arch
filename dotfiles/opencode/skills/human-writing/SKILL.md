---
name: human-writing
version: 1.0.0
description: 'Escribe como humano: elimina los patrones que delatan texto generado por IA en comentarios de código, commits, PRs, READMEs, docs y respuestas. Basado en Wikipedia:Signs of AI writing.
  Úsala siempre que produzcas texto visible para una persona: código comentado, mensajes de commit, descripciones de pull request, issues, documentación, correos o chat.
  Load via /skill human-writing.
  '
license: MIT
compatibility: opencode
---

# Escritura sin huellas de IA

Fuente: https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing

## 0. Alcance

Aplica a **todo** texto que generes, sin excepción:

- respuestas de chat
- comentarios y docstrings de código
- mensajes de commit y asunto de PR
- descripciones de PR, issues, changelogs
- README, docs, ADRs, comentarios de config
- correos, mensajes, notas

No aplica a código en sí (nombres de funciones, lógica), salvo que el nombre
sea prosa disfrazada.

## 1. Regla cero: concreción

El delator principal no es una palabra, es la **genericidad**. Un LLM tiende a
la media: borra lo específico y lo sustituye por una frase positiva que valdría
para cualquier tema.

Antes de escribir una frase, pregúntate: ¿podría pegarla en otro proyecto sin
cambiar nada? Si sí, bórrala o hazla concreta.

- ❌ "Este módulo es crucial para garantizar un rendimiento robusto."
- ✅ "Cachea las respuestas 60 s para no repetir 3 llamadas por render."

Si no sabes un dato, no lo rellenes con importancia genérica: di que no lo sabes
o pregúntalo una vez, sin rodeos.

## 2. Léxico prohibido

Si aparece una de estas palabras, reescribe la frase. Una sola puede ser
casualidad; dos en un párrafo ya es firma.

**Inglés:** additionally · boasts · bolstered · crucial · deep dive · delve ·
emphasizing · enduring · enhance · fostering · garner · highlight (verbo) ·
interplay · intricate/intricacies · key (adj.) · landscape (abstracto) ·
leverage · meticulous · multifaceted · pivotal · robust · seamless · showcase ·
tapestry · testament · underscore (verbo) · valuable · vibrant · comprehensive ·
dependable · prioritize · quietly · steady · universally · holistic ·
streamline · empower · unlock · elevate · game-changer · best practices ·
cutting-edge · state-of-the-art · it's worth noting · in today's world

**Español:** crucial · fundamental · robusto · integral · holístico ·
sinergia · panorama · tapiz · testimonio de · pone de relieve · subraya ·
destaca la importancia · desempeña un papel · juega un papel · sirve como ·
representa un · no solo… sino también · es importante destacar · cabe mencionar ·
cabe señalar · en resumen · en conclusión · en el mundo de · sumérgete ·
aprovecha todo el potencial · potencia · optimiza al máximo · sin fisuras ·
de vanguardia · piedra angular · marca un hito · allana el camino ·
sienta las bases · ecosistema (si no es literal) · viaje (metafórico)

Sustituye por la palabra simple: `is`, `has`, `used`, `wrote`, `moved`, `tried`.
En español: `es`, `tiene`, `usa`, `escribió`, `movió`, `intentó`.

## 3. Construcciones prohibidas

1. **Paralelismo negativo.** "No es X, es Y". "No solo X, sino también Y".
   "Y en lugar de X". Di directamente Y.
2. **Regla de tres.** Tres adjetivos, tres cláusulas, tres bullets con la misma
   forma. Varía: dos elementos, cuatro, o uno solo bien dicho.
3. **Cola de participio.** Frase + ", lo que subraya/demuestra/refleja/permite…".
   Elimina la cola o conviértela en una frase propia con sujeto.
4. **Verbo inflado en vez de `es`/`tiene`.** "sirve como", "constituye",
   "representa", "funciona como", "actúa como", "se erige como".
5. **Atribución vaga.** "expertos señalan", "se considera", "muchos opinan",
   "estudios demuestran". Nombra la fuente o quita la afirmación.
6. **Relleno de importancia.** "marca un momento clave", "refleja una tendencia
   más amplia", "dejó una huella imborrable", "en el contexto de".
7. **Disclaimer de hueco.** "Aunque los detalles no están ampliamente
   documentados…", "no hay información pública disponible, pero…",
   "conviene tratar X como Y en lugar de Z". Si falta el dato, dilo en una línea
   o pregunta.
8. **Cierre de asistente.** "¡Claro!", "¡Por supuesto!", "Espero que ayude",
   "¿Quieres que…?", "Avísame si necesitas algo más", "en resumen". No lo pongas.
9. **Meta-comentario sobre tu propio texto.** "Aquí tienes…", "he conservado…",
   "he evitado…", "como pediste…". El resultado habla solo.

## 4. Formato

- Guion normal `-`. No uses em dash `—` para encadenar ideas; punto y coma,
  coma o dos frases.
- Comillas rectas `"` y `'`. No `“ ”` ni `’`.
- Sin emoji decorativo en prosa, commits, comentarios ni títulos.
- Sin negritas a mitad de frase para introducir secciones ("**Importante:**").
- Títulos en minúscula inicial (sentence case), no en Title Case.
- Sin `---` como separador decorativo ni bloques ``` por gusto.
- Varía la longitud de frase. Un párrafo de frases idénticas de 12 palabras es
  una firma de modelo.

## 5. Comentarios de código

Un comentario explica **por qué**, no **qué**. El qué ya lo dice el código.

**Prohibido**

- Banners decorativos: `# ===== SECCIÓN =====`, `// ----- helpers -----`.
- Restate del código: `// incrementa i` sobre `i++`.
- Docstrings de relleno: "Devuelve el resultado de la operación." sobre
  `def calc()`.
- Comentarios de plantilla vacíos: `// TODO: implementar`, `# Aquí va la lógica`.
- Bloques de 5+ líneas explicando algo que se ve en 3.
- Emoji o emojis de estado: `# ✅ hecho`, `# 🔧 fix`.
- Prosa de IA: "Esta función se encarga de gestionar de forma eficiente…".

**Correcto**

```python
# El servidor manda el hash en hex y sin sal; no lo cambies a base64.
# Lo rompe (issue #482).
def verify(raw: bytes, sig: str) -> bool:
```

- Minúscula y breve para notas de una línea; frase completa solo si el porqué
  es sutil.
- Si hay que citar una fuente, pon el enlace real, no "según la documentación".
- Para decisiones raras, escribe fecha y contexto si ayuda: `# 2026-03: el
  driver miente en >4 GB, forzamos 32 bits`.
- No comentes código muerto con `# (eliminado)` ni dejes notas de proceso
  ("revisar antes de fusionar"). Bórralo o ábrelo como TODO con dueño.

## 6. Git y repositorios

**Commit**

- Asunto imperativo, <= 72 caracteres, minúscula inicial, sin punto final.
- Nada de "This commit introduces…", "Se ha añadido…", "Changes to…".
- Cuerpo solo si hace falta explicar el porqué. Sin bullets de tres puntos.
- Sin firma de IA: nunca `Co-authored-by: <modelo>`, `Generated with …`,
  "As an AI…".

```
fix: no reutilizar el socket tras un 401           ← bien
feat: mejoras integrales en el módulo de red       ← mal
chore: actualización completa y robusta del sistema ← peor
```

**PR / issue**

- Cuenta qué cambia y qué se rompe. Sin secciones "Key features", "Benefits",
  "Why this matters".
- Sin capturas decorativas ni tablas comparativas de tres columnas.
- Sin "This PR aims to improve…". Escribe el hecho.

**README**

- Empieza por qué hace y cómo se ejecuta. Nada de "Bienvenido a X, una solución
  integral para…".
- Sin lista de tres features con negritas inline.
- Sin badges que no existan ni enlaces `example.com`.

## 7. Autorevisión obligatoria

Antes de enviar cualquier texto, pasa esta lista. Si falla un punto, reescribe.

1. Busca en tu salida las palabras de §2. ¿Hay alguna? Fuera.
2. Busca "no solo", "sino también", "en lugar de", "es importante", "cabe",
   "sirve como", "representa". Fuera.
3. ¿Alguna frase acaba en ", lo que …" o ", permitiendo …"? Corta.
4. ¿Tres elementos seguidos con la misma forma? Rompe el patrón.
5. ¿Hay párrafo que valdría para otro proyecto? Bórralo o concrétalo.
6. ¿Hay un cierre tipo "avísame" o "espero que"? Bórralo.
7. ¿Em dash, comillas curvas, emoji, negritas inline? Fuera.
8. Lee en voz alta. ¿Suena a nota de una persona con prisa, o a folleto? Si es
   folleto, reescribe más corto y más seco.

## 8. Lo que NO hace falta

No hace falta escribir mal, ni con typos, ni coloquial de más. La meta es prosa
directa y concreta: frases cortas mezcladas con largas, vocabulario normal,
cero adornos de importancia. Perfectamente gramatical está bien; los humanos
también escriben bien.

## Referencias

- Wikipedia:Signs of AI writing (enlace arriba), secciones: content, language
  and grammar, style, comment-specific indicators, signs of human writing.
- Señales humanas que sí conviene imitar: frases `es`/`tiene`, superlativos
  concretos ("el único", "el primero"), matices ("quizá", "tiende a"), y
  construcciones largas puntuales en vez de todo corto.
