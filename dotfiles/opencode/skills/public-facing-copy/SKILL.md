---
name: public-facing-copy
description: >
  Texto que lee gente que no conoce el proyecto: GitHub releases, changelogs,
  notas de versión, descripciones de PR e issues y textos de tiendas de apps.
  Use cuando pida "release notes", "changelog", "descripción para usuarios",
  "GitHub release", "app store description" o vaya a publicar texto de una app.
  Solo efectos visibles para el usuario; nada de información interna.
---

# Texto para el público

Escribes para alguien que nunca ha visto el repo y no sabe qué tecnología usa. Solo necesita saber qué cambió para él.

## Qué va

- Lo que ahora puede hacer, lo que dejó de fallar, lo que se ve distinto.
- Frases cortas y palabras corrientes. Un cambio por línea.
- Si hay varios cambios, agrúpalos en "Novedades" y "Correcciones". Si son dos o menos, escribe las líneas sin agrupar.
- Descripciones de tienda: qué hace la app, qué trae esta versión, para quién es. Dos o tres frases.
- El idioma que pida el usuario para el texto publicado. Por defecto, español.

## Qué no va

- Rutas de archivos, nombres de funciones, clases, variables, dependencias, ramas, hashes de commit ni números de issue.
- Arquitectura, refactors, CI, tests, scripts de build, flags de config ni comandos de desarrollo.
- Apodos internos del proyecto ni nombres de módulos.
- Cifras de benchmarks ni detalles de implementación.
- Frases de relleno del tipo "mejoras generales", "optimizaciones internas", "actualización de dependencias" o "robusto", "integral", "de vanguardia".
- La línea de cierre de ponytail sobre qué se omitió o qué riesgo hay. Eso es texto de chat, no texto publicado.

Si un cambio solo existe por dentro y no produce ningún efecto visible, se omite. No se escribe "se refactorizó el módulo X".

## Límite

No inventes efectos. Usa solo lo que sale del diff o del contexto que tengas. Si no sabes qué verá el usuario, pregunta una vez o deja el cambio fuera.
