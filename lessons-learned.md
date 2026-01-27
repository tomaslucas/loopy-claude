# Lessons Learned

## Plan
<!-- Max 20 items. Managed by post-mortem. -->

## Build
<!-- Max 20 items. Managed by post-mortem. -->

- **Evitar:** Commitear directorios vacíos | **Usar:** Agregar .gitkeep o esperar al archivo real | **Razón:** Git no rastrea directorios vacíos, falla con "nothing to commit" (2026-01-26)
- **Evitar:** Re-leer plan.md después de errores | **Usar:** Cachear contenido leído o verificar antes de actuar | **Razón:** Re-leer duplica tokens innecesariamente (2026-01-26)
- **Evitar:** Llamadas a ./loop.sh sin error handling | **Usar:** Agregar || log "mensaje" | **Razón:** set -e causa exit si falla subprocess (2026-01-26)
- **Evitar:** Analizar logs en ejecución con tail | **Usar:** Buscar logs completados con grep "Loop finished" | **Razón:** tail muestra output de sesión actual, no log histórico (2026-01-26)
- **Evitar:** Sobre-analizar cuando no hay ejecuciones | **Usar:** Verificar timeline de commits vs logs primero | **Razón:** Código puede ser correcto pero no ejecutado aún (2026-01-26)
- **Evitar:** Llamadas subprocess sin error handling + set -e | **Usar:** Agregar || true o || log "error msg" | **Razón:** Subprocess failures terminan script padre prematuramente (2026-01-26)

## Validate
<!-- Max 20 items. Managed by post-mortem. -->

- **Evitar:** Analizar 400+ líneas antes de verificar hipótesis simple | **Usar:** Verificar primero si feature fue testeada | **Razón:** Over-investigation consume tokens sin valor (2026-01-26)
- **Evitar:** Re-leer mismo log file múltiples veces | **Usar:** View una vez, cachear en memoria | **Razón:** 10+ reads del mismo archivo duplica trabajo (2026-01-26)
- **Evitar:** grep repetido del mismo patrón | **Usar:** Combinar búsquedas o cachear resultado | **Razón:** Comandos redundantes ralentizan validación (2026-01-26)

## Reverse
<!-- Max 20 items. Managed by post-mortem. -->
