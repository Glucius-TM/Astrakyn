# ASTRAKYN Online — Agent Charter

Este archivo es el punto de entrada operativo para cualquier agente que trabaje sobre ASTRAKYN Online. No duplica el
contrato técnico del proyecto: su función es indicar **qué leer, qué autoridad tiene cada fuente y cómo validar un
cambio**.

## Orden obligatorio de lectura

1. Lee `CONSTITUTION.md`. Es la única fuente normativa viva de producto, arquitectura, gameplay, datos, seguridad,
   mundo, arte, tooling, QA y operaciones.
2. Lee `ESTADO_ACTUAL.md`. Es la única fuente del estado observado: implementación real, evidencia ejecutada, blockers,
   release readiness y feature matrix.
3. Inspecciona código, definitions, manifests, configuración y tests antes de modificar una responsabilidad existente.
4. Consulta `CHANGELOG.md` solo para contexto histórico curado. Git conserva el historial exhaustivo.
5. Cuando el cambio toque una surface de Roblox, revalida la documentación oficial vigente antes de implementar.

Si una afirmación de estado contradice evidencia ejecutable, se corrige `ESTADO_ACTUAL.md`. Si la implementación
contradice `CONSTITUTION.md`, la implementación es deuda/defecto salvo que una decisión explícita cambie primero el
contrato.

## Baseline oficial de Roblox

Empieza por `https://create.roblox.com/docs/llms.txt` y sigue las rutas exactas del índice. Para cada surface afectada:

1. revisa la guía conceptual y la API Reference aplicables;
2. comprueba security, privacy, policy, performance y publishing implications cuando correspondan;
3. comprueba el inventario oficial de APIs deprecated;
4. confirma si la capability es estable, beta o experimental y sus restricciones actuales;
5. distingue Engine API (`game:GetService()` dentro del experience) de Open Cloud HTTP externo;
6. registra en `ESTADO_ACTUAL.md` cualquier drift observado entre el snapshot y el baseline vigente.

Creator Hub/API Reference actual prevalece sobre memoria del agente, snippets antiguos, posts históricos o supuestos
heredados. No extrapoles URLs de documentación: usa el índice/search oficial.

## Clasificación obligatoria de decisiones

Antes de convertir una recomendación en regla, identifica su origen:

- **Roblox baseline** — requisito, comportamiento o recomendación documentada por Roblox y sujeta a revalidación cuando
  cambie la plataforma.
- **ASTRAKYN contract** — decisión deliberada del proyecto, aunque sea más estricta que Roblox.
- **Observed state** — hecho comprobado del snapshot o resultado de una validación; pertenece a `ESTADO_ACTUAL.md`, no a
  la Constitución.

No presentes una convención interna como mandato de Roblox ni un ejemplo de Roblox como obligación universal si la
propia documentación lo describe como opción o punto de partida.

## Workflow de cambio

Trabaja sobre el repositorio real, no sobre una arquitectura imaginada. Antes de borrar, mover, renombrar o reemplazar
una responsabilidad, localiza consumidores y tests, migra referencias, actualiza contratos/validators, valida y solo
entonces elimina la implementación sustituida. Git es el historial; no dejes copias legacy "por seguridad".

No crees documentación paralela. Una regla permanente
va a `CONSTITUTION.md`; un hecho/evidencia presente a `ESTADO_ACTUAL.md`; un hito ya cerrado a `CHANGELOG.md`.

## Evidencia y comandos canónicos

```bash
rokit install
lune setup
lune run tools/schema/check.luau
lune run tools/build/build_place.luau --verify
lune run tools/build/build_place.luau --release --manifest
stylua src tests tools
```

La toolchain vive fuera del repositorio y queda fijada en `rokit.toml`: Rojo construye/sincroniza el DataModel, Lune es
el runtime canónico del tooling propio, StyLua formatea Luau, Selene aplica lint y Luau-LSP realiza el análisis estático.
No existe una segunda toolchain Python/Pyright para automatización. `tools/` es Luau ejecutable con Lune y debe pasar el mismo estándar estricto que producto/tests: `--!strict`, cero `any` explícito, cero directivas de supresión y `luau-lsp analyze` real; compilar sintaxis no cuenta como typecheck. El quality gate
compila sintácticamente todos sus `.luau` antes de continuar. Tras instalar o cambiar la versión fijada de Lune, ejecuta
`lune setup`: materializa los typedefs `@lune/*` fuera del repositorio bajo `~/.lune/.typedefs/<version>/` y mantiene el
alias `lune` de `.luaurc` que Luau-LSP necesita para resolverlos en el editor. El snapshot no usa dependencias Luau externas ni package
manager: no añadas Wally, otro gestor, `wally.toml`, lockfiles o `Packages/` vacíos. La primera dependencia externa aprobada
activa la reevaluación y el contrato reproducible definido en `CONSTITUTION.md`.

Editor y batch fijan el nivel Roblox `None`; el gate usa `luau-lsp analyze`, obtiene la versión activa desde el pin
exacto de `rokit.toml` y cachea fuera del workspace, en el directorio temporal del sistema, únicamente
`globalTypes.None.d.luau` cuyo Git blob está verificado para esa versión. Una definition file externa nunca se escribe
bajo `.build`; cualquier caché heredada `.build/luau-lsp` se elimina. No se consume una definición mutable `latest`.
El subcomando `analyze` es la prueba real de ejecutabilidad. Si un launcher de Rokit bajo `~/.rokit/bin` devuelve en
Windows la firma conocida `(os error 3)`, el gate ejecuta como máximo una vez `rokit install` y reintenta exactamente el
mismo análisis; ningún otro error activa reparación automática ni se silencia.

`lune run tools/build/build_place.luau --verify` conserva la salida completa en
`.build/logs/build_place_verify.log`, sobrescribiéndola en cada ejecución. El builder delega build/sourcemap en Rojo;
con `--verify` reutiliza el único sourcemap ampliado producto+tests dejado por el quality gate; todo sourcemap se genera con `--include-non-scripts` para preservar el árbol DataModel tipado, y después
valida el place mediante `@lune/roblox.deserializePlace`, inspeccionando el `DataModel` en vez de implementar un parser o
emisor XML propio. `--verify` ejecuta el quality gate normal y permite atlas aún no publicados; `--release` implica verify
y exige los IDs reales de publicación. `--manifest` emite tamaño, SHA-256 y sourcemap del artefacto.

StyLua es el único formatter de Luau y cubre `src`, `tests` y `tools`. El gate lo ejecuta siempre primero en modo escritura y después con `--check`: cualquier diff de formato se autocorrige automáticamente antes del lint/typecheck y el segundo paso exige idempotencia. Existe un solo proyecto Rojo versionado,
`default.project.json`, y un solo `sourcemap.json` efímero en la raíz del workspace para editor y batch. El typecheck
genera primero ese mapa desde el producto y analiza `src`; para `tests` crea `.astrakyn-test.project.json` temporalmente en la raíz del workspace mediante
`tools/test/project.luau`, reutiliza el mismo sourcemap, analiza conjuntamente `src` y `tests` contra ese overlay y al finalizar elimina el overlay dejando la vista producto+tests que también consume Cursor. `tools/test/sourcemap.luau` es el generatorCommand de Luau-LSP para mantener esa misma topología en el editor. `.luaurc` strict y `.vscode/settings.json` son las únicas configuraciones compartidas de Luau-LSP. El único
log ignorado es el warning exacto de `didChangeWatchedFiles` emitido por el CLI standalone; cualquier otro warning de
Luau-LSP falla el gate.
