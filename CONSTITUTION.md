# ASTRAKYN Online — Production Constitution

Contrato normativo vivo de producto, arquitectura, runtime, gameplay, datos, seguridad, mundo, arte, tooling, QA y
operaciones. No contiene estado de implementación ni historial de migraciones: esos hechos pertenecen a
`ESTADO_ACTUAL.md` y `CHANGELOG.md`.

---

# CONTEXTO Y ALCANCE

Trabajas sobre **ASTRAKYN Online**, un MMORPG original construido sobre Roblox.

El objetivo es desarrollar un MMORPG persistente, social y masivo con una profundidad sistémica comparable o superior a
los grandes MMORPGs comerciales como World of Warcraft, sin copiar su propiedad intelectual, contenido, estética
identificable, UI, nombres, clases, razas, quests, bosses, mapas, código, música, iconografía o diseños propietarios.

La comparación con grandes MMORPGs representa exclusivamente:

- amplitud sistémica;
- coherencia;
- profundidad;
- persistencia;
- escalabilidad;
- PvE;
- PvP;
- economía;
- social;
- profesiones;
- progresión;
- coleccionismo;
- dungeons;
- raids;
- endgame;
- operaciones en vivo;
- calidad audiovisual;
- robustez de plataforma.

ASTRAKYN debe tener identidad propia.

## Interpretación normativa

Este contrato distingue tres clases de afirmaciones:

- **Roblox baseline**: comportamiento, requisito o recomendación documentada por Roblox. Debe revalidarse contra la
  documentación oficial vigente cuando se toque esa surface.
- **ASTRAKYN contract**: decisión propia del proyecto. Puede ser deliberadamente más estricta que la recomendación de
  Roblox y no debe presentarse como mandato de la plataforma.
- **Observed state**: hechos del snapshot, resultados de tests o blockers. No pertenecen a este documento; viven en
  `ESTADO_ACTUAL.md`.

Una guía oficial que diga "recommended", "consider" o presente un ejemplo se conserva con ese nivel de fuerza; no se
convierte automáticamente en obligación universal. Una API beta/experimental tampoco se vuelve requisito crítico solo
por existir.

---

# 1. PRINCIPIOS SOBRE EL REPOSITORIO

No supongas que el proyecto es una hoja en blanco.

Trabaja siempre sobre el estado real del repositorio existente y evalúa cada componente antes de decidir si debe
conservarse, modificarse, moverse, fusionarse, reestructurarse o eliminarse.

Reutiliza aquello que sea correcto, coherente, mantenible, seguro y alineado con la arquitectura objetivo.

Refactoriza aquello que tenga valor pero presente problemas de:

- estructura;
- acoplamiento;
- nomenclatura;
- responsabilidades;
- mantenibilidad;
- escalabilidad;
- seguridad;
- rendimiento;
- integración;
- organización;
- documentación.

Reestructura cualquier carpeta, archivo, módulo, sistema o responsabilidad que esté ubicado de forma incorrecta o que
impida mantener una arquitectura clara y escalable.

Fusiona implementaciones redundantes cuando representen la misma responsabilidad.

Elimina completamente aquello que sea:

- redundante;
- duplicado;
- histórico;
- provisional;
- experimental;
- obsoleto;
- deprecated;
- inseguro;
- no utilizado;
- innecesario;
- incompatible con la arquitectura final;
- ruido de repositorio;
- código muerto;
- documentación obsoleta;
- tooling sustituido;
- compatibilidad legacy que ya no tenga consumidores reales.

No conserves archivos, sistemas o código únicamente para mantener compatibilidad histórica.

No mantengas múltiples implementaciones paralelas de una misma responsabilidad salvo que exista una necesidad productiva
real y documentada.

No utilices nombres o carpetas como:

- `legacy`;
- `old`;
- `deprecated`;
- `backup`;
- `temp`;
- `experimental`;
- `v1`;
- `v2`;
- `final_old`;

como mecanismo permanente para conservar implementaciones sustituidas.

Cuando una implementación nueva sustituya una anterior:

1. migra los consumidores;
2. actualiza referencias;
3. actualiza tests;
4. actualiza documentación;
5. valida la nueva implementación;
6. elimina la implementación sustituida.

Git es el historial.

El repositorio principal debe contener exclusivamente:

- código vivo;
- configuración viva;
- documentación viva;
- assets fuente necesarios;
- tooling vigente;
- tests vigentes;
- manifests vigentes;
- migraciones todavía necesarias;
- infraestructura necesaria para construir, validar y operar el producto.

No almacenes dentro del repositorio principal copias históricas que Git ya puede recuperar.

La estructura del repositorio debe representar claramente la arquitectura real del producto.

Cada carpeta debe existir porque representa una responsabilidad concreta.

Cada archivo debe tener un propósito claro.

Cada módulo debe tener una responsabilidad definida.

Cada sistema debe tener un único ownership arquitectónico.

No crear carpetas vacías, niveles de anidación innecesarios ni estructuras artificiales únicamente por estética
organizativa.

La estructura final debe optimizar:

- claridad;
- descubribilidad;
- ownership;
- separación de responsabilidades;
- dependency direction;
- escalabilidad;
- mantenibilidad;
- testing;
- tooling;
- colaboración entre disciplinas.

No permitas duplicación conceptual entre:

- documentación;
- código;
- configuración;
- manifests;
- catálogos;
- definitions;
- tooling.

Debe existir una única fuente de verdad para cada concepto importante.

Cuando haya varias fuentes contradictorias, consolídalas y elimina las redundantes.

El repositorio final debe quedar limpio, coherente y orientado exclusivamente a producción, sin ruido, legacy
innecesario, versiones abandonadas, duplicados, archivos huérfanos ni documentación contradictoria.

---

# 2. MISIÓN

Actúa simultáneamente como:

Game Director, Technical Director, Principal Roblox Engineer, Principal Luau Architect, MMORPG Systems Architect,
Distributed Systems Engineer, Data Engineer, Security Engineer, Multiplayer Engineer, Performance Engineer, Combat
Designer, Progression Designer, Economy Designer, Quest Designer, Encounter Designer, Dungeon Designer, Raid Designer,
PvP Designer, World Designer, Level Designer, AI Engineer, Technical Art Director, Blender Pipeline Engineer, Character
Technical Artist, Animation TD, VFX Technical Artist, UI/UX Director, Accessibility Designer, Audio Designer, Studio
Plugin Engineer, Tools Engineer, QA Lead, Release Engineer, LiveOps Engineer, Analytics Engineer y Operations Engineer.

Tu trabajo no consiste en producir ejemplos.

Tu trabajo consiste en **terminar el producto correctamente**.

---

# 3. REGLA SUPREMA: UN ÚNICO RUNTIME DE PRODUCCIÓN

ASTRAKYN no tendrá runtimes paralelos seleccionados por entorno, propósito de tooling o fase de entrega. Existe únicamente:

`PRODUCTION RUNTIME`.

Desarrollo, testing, profiling, migraciones y tooling operan alrededor de ese producto como procesos externos o overlays efímeros; no alteran la identidad del runtime publicable.

Admin, GM, Moderadores, Support, Security, LiveOps y jugadores normales son **principales con diferentes capacidades
dentro del mismo runtime de producción**.

No son entornos diferentes.

No son modos diferentes.

No se puede cambiar el comportamiento de autoridad o seguridad mediante una variable `Environment`.

---

# 4. TESTING NO ES UN MODO DEL JUEGO

La ausencia de modos runtime NO significa ausencia de testing.

Tests, profiling, validadores, simuladores y fixtures viven fuera del artefacto publicado.

Existe un único proyecto Rojo versionado:

`default.project.json`

Describe exactamente el DataModel del producto publicable y es la única configuración Rojo canónica del repositorio. Los tests no mantienen un segundo proyecto versionado. Cuando el gate necesita resolver `script`/DataModel para `tests/`, Lune genera temporalmente `.astrakyn-test.project.json` junto a `default.project.json`, derivado de este sin rebasar sus `$path`, y añade `TestService.Tests` desde `tests`; compartir la raíz con `sourcemap.json` mantiene una única base de rutas para Rojo y Luau-LSP. El overlay se elimina al terminar y nunca se publica.

Existe igualmente un único sourcemap de trabajo:

`sourcemap.json`

Está ignorado por Git y representa la vista de análisis producto+tests cuando el gate termina; el artefacto publicable sigue definido exclusivamente por `default.project.json`. Todo sourcemap se genera con `--include-non-scripts` para que servicios, folders y demás nodos intermedios necesarios para resolver el DataModel formen parte del árbol tipado. El análisis batch genera primero ese mapa desde `default.project.json` para `src/`; durante el análisis de tests reutiliza temporalmente el mismo archivo con el overlay efímero y analiza conjuntamente `src/` y `tests/` para que el grafo de dependencias productivas requerido por los specs esté indexado. No existen sourcemaps productivo/test paralelos: se reutiliza el mismo `sourcemap.json`; el gate valida primero `src/` con la vista productiva y termina con la vista ampliada producto+tests que necesita el editor.

El artefacto publicado NO contiene:

- `TestService.Tests`;
- harness;
- fixtures;
- mocks;
- fake players;
- test currencies;
- test commands;
- environment switching.

---

# 5. PROHIBICIÓN DE CONFIGURACIONES PARALELAS

El repositorio mantiene una sola configuración runtime (`config/runtime.json`), un solo proyecto Rojo versionado (`default.project.json`) y un solo sourcemap efímero (`sourcemap.json`). No se versionan variantes alternativas por entorno, artefactos paralelos, resolvers de entorno, reglas de autoridad condicionadas por modo, ni una segunda configuración persistente de Luau-LSP.

Los tests, fixtures, mocks, profiling y simulación permanecen fuera del artefacto publicable. Cuando una herramienta necesite una vista ampliada del DataModel, debe derivarla de las fuentes canónicas como artefacto efímero ignorado por Git, usarla solo durante la operación concreta y eliminarla después. Si ese artefacto contiene `$path` que alimentan un `sourcemap.json` de raíz, debe compartir la misma raíz de resolución para no desplazar rutas relativas.

`ASTRAKYN.rbxlx`, `sourcemap.json`, `.astrakyn-test.project.json` y cualquier otro output reproducible son artefactos efímeros ignorados por Git, nunca source-of-truth.

---

# 6. HISTORIA Y VERSIONES

Git, tags, releases y los números de versión representan evolución temporal del mismo producto canónico; no crean un segundo entorno ni una implementación paralela.

No mantener:

`SystemV1`

`SystemV2`

`SystemOld`

`Legacy`

`Backup`

`FinalFinal`

`Deprecated`

como implementaciones paralelas.

Cuando una implementación sustituya otra:

migrar;

actualizar consumidores;

actualizar tests;

actualizar documentación;

borrar implementación sustituida.

Las únicas versiones que deben permanecer son versiones semánticamente necesarias:

`SchemaVersion`

`ProtocolVersion`

`ContentVersion`

`GeneratorVersion`

`BuildVersion`

y migraciones de datos todavía necesarias para usuarios reales.

---

# 7. ESTRUCTURA FINAL DEL REPOSITORIO

La arquitectura física canónica del repositorio es la siguiente. Este árbol define **namespaces de ownership**, no una
obligación de materializar carpetas vacías: un namespace se crea únicamente cuando contiene implementación, tests,
assets o tooling reales. La ausencia temporal de un namespace todavía no implementado es correcta; crear una carpeta
vacía para "parecer completo" no lo es.

```text
ASTRAKYN Online/
├── AGENTS.md
├── CONSTITUTION.md
├── ESTADO_ACTUAL.md
├── CHANGELOG.md
├── default.project.json
├── rokit.toml
├── selene.toml
├── astrakyn.yml
├── stylua.toml
├── .luaurc
├── .markdownlint.json
├── .gitignore
├── .gitattributes
│
├── .vscode/
│   ├── settings.json
│   └── extensions.json
│
├── .github/
│   └── workflows/
│       ├── quality.yml
│       └── release-validation.yml
│
├── config/
│   └── runtime.json
│
├── art/
│   ├── source/
│   │   ├── blender/
│   │   ├── textures/
│   │   ├── concept/
│   │   └── audio/
│   └── manifests/
│
├── assets/
│   ├── manifests/
│   │   └── atlas_assets.json
│   └── UI/
│       └── Icons/
│
├── src/
│   ├── Shared/
│   │   ├── Constants/
│   │   ├── Types/
│   │   ├── Protocols/
│   │   ├── Validation/
│   │   ├── Serialization/
│   │   ├── Utility/
│   │   └── World/
│   │
│   ├── Definitions/
│   │   ├── ContentIdIndex.luau
│   │   ├── Abilities/
│   │   ├── Art/
│   │   ├── Characters/
│   │   ├── Combat/
│   │   ├── Effects/
│   │   ├── Encounters/
│   │   ├── Economy/
│   │   ├── Items/
│   │   ├── LiveOps/
│   │   ├── NPCs/
│   │   ├── Places/
│   │   ├── Progression/
│   │   ├── Quests/
│   │   ├── Social/
│   │   ├── Staff/
│   │   ├── UI/
│   │   └── World/
│   │
│   ├── Server/
│   │   ├── Bootstrap/
│   │   ├── Platform/
│   │   │   ├── Config/
│   │   │   ├── Persistence/
│   │   │   ├── Transactions/
│   │   │   ├── Networking/
│   │   │   ├── CrossServer/
│   │   │   ├── Teleport/
│   │   │   ├── Chat/
│   │   │   ├── Commerce/
│   │   │   ├── Analytics/
│   │   │   ├── Localization/
│   │   │   ├── Security/
│   │   │   ├── Staff/
│   │   │   ├── Observability/
│   │   │   └── Scheduling/
│   │   │
│   │   ├── Domains/
│   │   │   ├── Character/
│   │   │   ├── Stats/
│   │   │   ├── Combat/
│   │   │   ├── Macro/
│   │   │   ├── Progression/
│   │   │   ├── Items/
│   │   │   ├── Economy/
│   │   │   ├── Quest/
│   │   │   ├── Social/
│   │   │   ├── Guild/
│   │   │   ├── Matchmaking/
│   │   │   ├── Instances/
│   │   │   ├── PvP/
│   │   │   ├── World/
│   │   │   ├── Settlement/
│   │   │   └── LiveOps/
│   │   │
│   │   └── AI/
│   │
│   └── Client/
│       ├── init.client.luau
│       ├── Bootstrap/
│       ├── Runtime/
│       ├── Input/
│       ├── Camera/
│       ├── Presentation/
│       │   ├── Animation/
│       │   ├── VFX/
│       │   ├── SFX/
│       │   ├── Lighting/
│       │   └── Cinematics/
│       ├── UI/
│       │   ├── DesignSystem/
│       │   ├── HUD/
│       │   ├── Character/
│       │   ├── Inventory/
│       │   ├── Quest/
│       │   ├── Social/
│       │   ├── Guild/
│       │   ├── Economy/
│       │   ├── PvP/
│       │   ├── Map/
│       │   └── Staff/
│       └── Domains/
│
├── tests/
│   ├── Bootstrap.luau
│   ├── HarnessApi.luau
│   ├── unit/
│   ├── integration/
│   ├── contracts/
│   ├── persistence/
│   ├── transactions/
│   ├── security/
│   ├── networking/
│   ├── cross-server/
│   ├── gameplay/
│   ├── world/
│   ├── migrations/
│   └── fixtures/
│
└── tools/
    ├── build/
    ├── validation/
    │   └── simulation/
    ├── schema/
    ├── test/
    ├── migration/
    ├── operations/
    ├── art/
    ├── blender/
    └── studio/
```

`.build/` es exclusivamente output local/CI reproducible y está ignorado por Git; no forma parte del source-of-truth. Puede contener el place y logs reproducibles, pero no configuraciones persistentes que dupliquen las fuentes versionadas del repositorio. El project overlay de tests vive temporalmente en la raíz del workspace porque sus `$path` deben compartir base con `sourcemap.json`; está ignorado por Git y se elimina inmediatamente después de generar el mapa. Existe un único `sourcemap.json` en la raíz del workspace, ignorado por Git y compartido por editor y gate. Luau-LSP lo autogenera mediante `lune run tools/test/sourcemap.luau`, por lo que la vista estable del editor incluye producto+tests. El gate valida primero `src/` contra un mapa productivo generado desde `default.project.json` y después reemplaza el mismo archivo por la vista producto+tests; el build productivo siempre usa exclusivamente `default.project.json`.

`assets/manifests/atlas_assets.json` es la única fuente versionada de IDs publicados de los atlas. Los PNG bajo `assets/UI/Icons/` son source art de autoría y no se montan en el DataModel productivo. No existe mirror Luau ni generator de sincronización JSON→Luau; Rojo expone el JSON canónico cuando el runtime lo necesita. IDs vacíos o placeholders bloquean validación de release.

La documentación viva del repositorio queda limitada exactamente a cuatro archivos raíz:

- `AGENTS.md` — instrucciones operativas breves para cualquier agente;
- `CONSTITUTION.md` — contrato completo y autoritativo de producto/arquitectura;
- `ESTADO_ACTUAL.md` — estado real, evidencia, blockers y feature matrix;
- `CHANGELOG.md` — registro curado de cambios relevantes.

No crear `docs/`, `.cursor/`, READMEs locales, reglas `.mdc` ni documentación paralela. La información específica de
implementación debe vivir en código, tipos, definitions, manifests, tests y configuración, no replicarse en documentos
secundarios.

Reglas de ownership estructural:

- `Shared` contiene contratos/utilidades realmente agnósticos de dominio y runtime.
- `Definitions` contiene data/definitions declarativas y no depende de services runtime.
- `Server/Platform` posee capacidades transversales de plataforma; no gameplay.
- `Server/Domains` posee comportamiento de gameplay/negocio por dominio.
- `Server/Bootstrap` solo compone, registra y cablea; no absorbe lógica de dominio.
- `Client/Presentation` contiene presentación audiovisual; `Client/UI` contiene UI; `Client/Domains` contiene
  controllers/estado cliente que no son presentación pura.
- Los protocolos compartidos viven en `Shared/Protocols`; no existe `Definitions/Remotes`.
- Tests se organizan por tipo de evidencia (`unit`, `integration`, `contracts`, etc.) y pueden subdividirse por dominio.
- Tooling se organiza por responsabilidad; simuladores son tooling de validación y viven bajo
  `tools/validation/simulation`.

No crear carpetas vacías por estética. Cada carpeta debe existir porque contiene responsabilidad real. Cuando una
responsabilidad todavía no está implementada —por ejemplo `Platform/Transactions`, `Platform/CrossServer`,
`Definitions/Places`, `art/source/blender` o tests específicos todavía inexistentes— el namespace permanece ausente y
`ESTADO_ACTUAL.md` registra el blocker correspondiente.

El validator de layout debe fallar si reaparece una capa sustituida (`Infrastructure`, `Services`, `Systems`, `Engines`,
`Client/Hero`, `Definitions/Remotes`, etc.) o si se introduce un directorio de primer nivel fuera de estos namespaces
canónicos.

---

# 8. REGLAS DE DEPENDENCIA

La dirección principal es:

```text
Shared
   ↑
Definitions
   ↑
Platform
   ↑
Server Domains
   ↑
Bootstrap
```

Client puede consumir:

`Shared`

`Definitions`

`Protocols`

y sus propios módulos.

Client jamás requiere módulos server.

Platform no depende de dominios de gameplay.

Definitions no dependen de services runtime.

No circular dependencies.

No global mutable singletons ocultos.

Usar el `ServiceContainer` existente como base de dependency injection server-side y evolucionarlo, no sustituirlo por
otro framework arbitrario. Los acoplamientos cross-domain que cerrarían un ciclo estático se componen en `Bootstrap`/el
composition root mediante interfaces/callbacks estrechos; no se resuelven haciendo `require` circular entre domains ni
relajando el typecheck. El validator de layout debe proteger las boundaries críticas que ya hayan causado ciclos reales.

---

# 9. CORAZÓN DEL GAMEPLAY

Preservar la dirección conceptual válida ya existente:

```text
STAT ENGINE
    ↓
ABILITY ENGINE
    ↓
EFFECT / AURA ENGINE
    ↓
COMBAT ENGINE
    ↓
MACRO COMMAND LAYER
```

No introducir un segundo motor de stats, combat, effects o abilities.

Eliminar cualquier duplicación.

---

# 10. LUAU

Todo Luau vivo bajo `src/`, `tests/` y `tools/`:

`--!strict` obligatorio.

`any` explícito está prohibido. Para datos no confiables o dinámicos usar `unknown` y estrecharlo mediante validación antes de acceder a su contenido. No se permiten `--!nocheck`, `--!nonstrict` ni suppressions equivalentes para ocultar errores.

Usar tipos exportados para contratos públicos.

Preferir funciones puras para resolvers.

Módulos pequeños con responsabilidad clara.

No god modules.

No magic strings cuando exista un ID catalogado.

No `loadstring`.

No ejecución de código suministrado por usuarios.

No `require(assetId)` determinado por cliente.

Usar `task.*` para scheduling explícito; no introducir nuevas dependencias en APIs legacy/deprecated cuando exista un
reemplazo vigente.

Diseñar handlers compatibles con `Workspace.SignalBehavior = Deferred`: no depender de reentrancia inmediata de eventos
ni de orden accidental entre señales.

Native code generation y Parallel Luau son optimizaciones selectivas: solo se aplican a workloads medidos, compatibles y
con evidencia before/after. No convertir todo el código indiscriminadamente.

`Script Capabilities`/sandboxing se evalúa para terceros o código no confiable cuando la feature sea adecuada, pero
mientras Roblox la marque experimental/beta no puede ser la única barrera de seguridad de una feature productiva.

No crear módulos propios cuyo nombre exacto colisione con un Service nativo de Roblox. Si existe
`game:GetService("X")`, el boundary ASTRAKYN usa un nombre inequívoco como `TelemetryService`, `RuntimeConfigService`,
`PurchaseCoordinator`, `ActivityMatchmakingCoordinator`, `SocialDomainService` o `PlayerModerationService`.

---

# 11. CONFIGURACIÓN FINAL

Existe un único archivo versionado de bootstrap productivo:

`config/runtime.json`.

NO tiene campo `environment`.

Contiene únicamente configuración productiva **no secreta y relativamente estática**. Puede incluir defaults inmutables del release —por ejemplo feature flags o multiplicadores de balance que formen parte del contrato versionado—, pero esos defaults no son un mecanismo de live tuning y no se mutan durante la sesión. La configuración mutable cross-server usa las capacidades de plataforma definidas más abajo.

Entre los campos que pueden formar parte de este contrato están:

- UniverseId real;
- PlaceIds reales;
- IDs de productos y passes;
- identificadores de Experience Configs;
- versiones activas;
- referencias de catálogos;
- nombres de DataStores;
- políticas estáticas que deban formar parte del release.

Todos los IDs obligatorios deben ser reales.

`0`, `TODO`, IDs falsos o placeholders provocan fallo del build cuando el campo sea requerido para el artefacto
objetivo.

Configuración mutable cross-server, feature flags, tuning y rollout NO se implementan mutando `runtime.json` durante el
runtime ni con memoria local del servidor: utilizar las capacidades vigentes de **Experience Configs** y el
`ConfigService` nativo cuando sean apropiadas.

El módulo ASTRAKYN actualmente encargado del bootstrap/config local debe llamarse `RuntimeConfigService` o equivalente,
nunca `ConfigService`, para no colisionar con el Service nativo.

Secretos, API keys, passwords y tokens no pertenecen a `runtime.json`, DataStores ni source control. Usar el **Secrets
Store** de Roblox/Open Cloud o el mecanismo oficial equivalente vigente, con permisos mínimos y dominio restringido.

---

# 12. STUDIO JAMÁS ACCEDE AL DATASTORE PRODUCTIVO

No existe `AllowStudioDataStores` dentro del runtime productivo.

El universe productivo debe mantener deshabilitado el acceso de Studio a API Services/DataStores salvo una intervención
operativa excepcional, explícitamente autorizada y auditada.

Los tests automatizados reciben adapters in-memory mediante dependency injection.

Cuando sea necesario validar integración real con DataStore/MemoryStore/Teleport u otros servicios que Studio no puede
simular de forma segura, utilizar una **experiencia/universe privado de prueba separado** con IDs y datos no
productivos.
Esto es aislamiento de tooling/validación, no un segundo runtime dentro del producto.

No existe flag runtime para desactivar esta protección.

---

# 13. FEATURE FLAGS Y LIVE CONFIG

Feature flags no son entornos.

Para configuración global mutable, rollout y live tuning, preferir **Experience Configs** y el `ConfigService` nativo
vigente de Roblox cuando cubra el caso de uso.

Mantener:

- defaults/release contract versionado cuando sea necesario;
- configs publicadas con historial/versionado de plataforma;
- live updates explícitos;
- kill switches;
- rollout controlado;
- rollback;
- ownership y auditabilidad operativa.

`ConfigSnapshot` representa un punto en el tiempo y **no se actualiza automáticamente**. Cuando un cambio deba entrar
en vigor durante la sesión, usar `ConfigSnapshot.UpdateAvailable` y decidir el momento seguro para llamar
`ConfigSnapshot:Refresh()`; reaccionar a claves concretas mediante `GetValueChangedSignal()` cuando sea útil. Tratar
`ConfigSnapshot.Error`/`Outdated` y fallos de carga explícitamente, con defaults versionados o degradación segura según
la criticidad. Evitar polling cuando la plataforma ya expone estas señales.

Ningún `AdminService:SetFlag()` puede cambiar únicamente memoria del servidor actual y pretender ser global.

Un override global fuera de Experience Configs, si existe por una razón justificada, debe persistir, tener versión,
propagarse, ser auditable, poseer owner y caducar cuando sea temporal.

---

# 14. TOPOLOGÍA FINAL DE PLACES

ASTRAKYN utiliza una arquitectura híbrida.

## WORLD PLACES

Cada continente productivo importante dispone de un Place:

`World_<ContinentId>`.

El continente actual se convierte en:

`World_Kynfall`.

World Places contienen:

- continentes;
- regiones;
- zonas;
- capitales;
- ciudades;
- mundo abierto;
- world events;
- world bosses;
- gathering;
- exploration.

Instance Streaming habilitado y configurado con las recomendaciones vigentes de Roblox como baseline y con profiling
real para cualquier desviación.

## INSTANCE RUNTIME

Un Place productivo:

`Instance_Runtime`

ejecuta reserved servers para:

- dungeons;
- raids;
- scenarios;
- otras instancias PvE cerradas.

El contenido exacto se decide por `InstanceDefinition`.

## PVP RUNTIME

Un Place productivo:

`PvP_Runtime`

ejecuta reserved servers para:

- battlegrounds;
- arenas;
- modalidades PvP instanciadas.

## CHARACTER ENTRY

No crear un Place lobby adicional salvo decisión de producto explícita que demuestre necesidad real.

Character roster/selection ocurre antes de materializar el personaje en el World Place actual.

Si el personaje pertenece a otro continente, ejecutar secure transfer al Place correspondiente.

## ACCESS CONTROL

Todo subplace restringido/progression-gated debe utilizar **Secure within universe only** o el control de acceso oficial
vigente equivalente, de modo que el cliente no pueda iniciar directamente el teleport y recibir contenido antes de la
validación server-side.

Contenido confidencial, pruebas privadas y material unreleased que no deba replicarse jamás a jugadores live vive en un
universe privado separado; no se introduce dentro del universe productivo antes de su activación.

---

# 15. PLACE CATALOG

Crear:

`Definitions/Places/PlaceCatalog.luau`.

Cada registro:

```text
PlaceKey
PlaceId
Role
ContinentId?
SupportsPublicServers
SupportsReservedServers
MaxPartyTransfer
ContentVersion
```

No dispersar PlaceIds.

---

# 16. INSTANCE TRANSFER

Crear `InstanceTransferService`.

Pipeline:

```text
SOURCE VALIDATION
→ SAVE
→ CREATE TRANSFER TICKET
→ MARK PROFILE TRANSFER-PENDING
→ TELEPORT
→ DESTINATION VALIDATION
→ DESTINATION LEASE CLAIM
→ CONSUME TICKET
→ SPAWN
```

El transporte usa `TeleportService:TeleportAsync()` como API general vigente.

Para reserved servers, utilizar `TeleportOptions.ShouldReserveServer` cuando baste con reservar y transferir, o
`TeleportService:ReserveServerAsync()` + `ReservedServerAccessCode` cuando ASTRAKYN necesite gestionar explícitamente el
access code. No introducir nuevos usos de `TeleportToPrivateServer`, `TeleportPartyAsync`, `TeleportToPlaceInstance` u
otras APIs de teleport deprecadas.

TeleportService no se considera validado mediante playtest de Studio: los flows reales de teleport requieren experiencia
publicada/privada adecuada y prueba cliente-servidor real.

Transfer ticket:

- identificador opaco generado server-side; no asumir que un UUID/GUID aporta por sí solo autorización o una garantía
  criptográfica no documentada;
- TTL corto;
- single-use/consumo idempotente;
- UserId;
- CharacterId;
- source;
- destination;
- activity;
- party/instance ID;
- expected session generation.

En destino, validar el ticket contra estado server-side y comprobar `Player:GetJoinData()`/sus campos de origen cuando
aplique. Aunque Roblox valida ciertas propiedades de origen para `GetJoinData()`, `TeleportData` continúa siendo datos
transportados vía cliente y nunca sustituye el ticket autoritativo.

`TeleportData` contiene únicamente referencias no sensibles necesarias.

Nunca contiene como verdad autoritativa:

- currency;
- inventory;
- permissions;
- rewards;
- staff role;
- profile data.

---

# 17. TELEPORT FAILURE

Gestionar:

`TeleportInitFailed`;

retry acotado;

partial group transfer;

destination unavailable;

player disconnect;

source recovery.

Un party no debe quedar permanentemente dividido por un fallo sin estado recuperable.

---

# 18. CROSS-SERVER PLATFORM

Crear adaptadores explícitos:

`MemoryCoordinationService`

`CrossServerBusService`

`InstanceTransferService`

`PresenceService`

`ActivityMatchmakingCoordinator`

`AuctionIndexService`.

`MemoryCoordinationService` encapsula `MemoryStoreService`.

`CrossServerBusService` encapsula `MessagingService`.

`ActivityMatchmakingCoordinator` representa matchmaking de **actividades** de ASTRAKYN (dungeon/raid/PvP queues) y no
se llama `MatchmakingService`, porque Roblox expone un Service nativo con ese nombre.

Para selección/asignación de servidores públicos, evaluar primero las **custom matchmaking configurations** y señales de
matchmaking nativas de Roblox. Para colas de actividades y reserved-instance allocation, MemoryStore sigue siendo válido
cuando sus semánticas encajan.

Ningún dominio llama directamente a MemoryStore/Messaging sin pasar por el boundary correspondiente salvo una excepción
arquitectónica documentada y validada.

---

# 19. MEMORY STORE

Uso adecuado:

- matchmaking/activity queues;
- server directory;
- presence;
- transfer tickets;
- distributed short-lived leases;
- temporary auction search/index;
- temporary instance membership;
- ephemeral world-event coordination.

Usar la estructura adecuada (`Queue`, `SortedMap`, `HashMap`) según semántica.

Asignar siempre el TTL **más corto razonable** para el dato. Aunque Roblox permita expiraciones largas/defaults,
ASTRAKYN no utiliza MemoryStore como almacenamiento duradero.

Eliminar entries procesadas cuando corresponda. Usar patrones de keys/nombres estáticos y deterministas, preferir
`UpdateAsync` cuando exista contención, aplicar backoff con jitter y shardear hot keys/estructuras únicamente cuando
observabilidad y límites reales lo justifiquen. Vigilar Memory Store Observability/alerts antes de ampliar capacidad.

Nunca es source-of-truth de:

- player progression;
- inventory;
- currency;
- guild state;
- auction ownership;
- staff roles;
- durable transaction state.

---

# 20. MESSAGING SERVICE

`MessagingService` es transporte best-effort y se encapsula mediante `CrossServerBusService`.

Usarlo para:

- invalidaciones de caché;
- cross-server notifications no críticas;
- presence hints;
- world-event announcements;
- guild state invalidation;
- auction index invalidation;
- LiveOps/config propagation cuando corresponda.

Todo consumidor debe asumir pérdida, duplicación, retraso y reorder cuando el diseño lo permita.

Un mensaje perdido jamás puede causar:

- duplicación durable;
- pérdida de item;
- pérdida de moneda;
- autorización incorrecta;
- inconsistencia permanente.

Estado crítico se reconcilia siempre desde su source-of-truth durable.

---

# 21. PRESENCE

Presence entry contiene únicamente información efímera:

```text
UserId
CharacterId
PlaceId
JobId
ContinentId
ZoneId
Activity
PartyId?
GuildId?
HeartbeatAt
```

Con TTL.

No almacenar Presence permanentemente.

---

# 22. PERSISTENCIA PRODUCTIVA

Crear un pequeño conjunto fijo de stores:

```text
ASTRAKYN_PlayerProfiles
ASTRAKYN_Mailboxes
ASTRAKYN_GuildCore
ASTRAKYN_GuildBank
ASTRAKYN_Transactions
ASTRAKYN_AuctionListings
ASTRAKYN_WorldState
ASTRAKYN_StaffDirectory
ASTRAKYN_StaffAudit
ASTRAKYN_SupportTickets
```

Rankings usan OrderedDataStores separados por season/category cuando ese acceso ordenado sea realmente necesario.

No crear un DataStore por jugador.

Preferir una o pocas keys cohesivas por agregado cuando deban actualizarse atómicamente y el tamaño/throughput lo
permitan; no fragmentar datos solo por estética.

Toda llamada DataStore puede fallar y se ejecuta con handling explícito de errores/transient outcomes.

Para escrituras donde varios servidores puedan competir, usar `UpdateAsync`/control de versión y no confiar en
`SetAsync` como mecanismo de concurrencia.

El callback/transform de `UpdateAsync` es una región **no-yield**: no llamar desde él a `task.wait()`, HTTP, DataStore,
MemoryStore, Messaging ni a ninguna otra API que pueda ceder. Precomputar fuera cualquier contexto externo, mantener la
transformación limitada al valor/metadata recibidos y ejecutar retry/backoff fuera del callback; devolver `nil` cancela
la escritura.

Si una key usa associated user IDs o metadata de DataStore, el callback recibe `DataStoreKeyInfo` y debe preservar o
actualizar explícitamente esas definiciones al escribir. No devolver solo el nuevo value si la key ya depende de
`keyInfo:GetUserIds()`/`keyInfo:GetMetadata()`: la guía vigente advierte que omitir las definiciones de metadata en
`SetAsync`/`IncrementAsync`/`UpdateAsync` puede perder el valor actual. El adapter de persistencia debe exponer esta
semántica y cubrirla con tests antes de adoptar key metadata/user IDs; no esconderla detrás de una transform que solo
pueda devolver un valor.

Respetar los límites vigentes por entrada/metadata y medir el tamaño real del schema. No fragmentar por anticipación,
pero tampoco permitir que un agregado se acerque silenciosamente al límite de plataforma sin métricas, headroom y un
plan de migración/sharding.

Aprovechar versiones de DataStore para inspección/restauración y Data Stores Manager/observabilidad operativa cuando
corresponda.

Un error de escritura no demuestra que el backend no haya aplicado el cambio. Cuando el resultado de una escritura sea
incierto y la corrección dependa de conocer el estado final, reconciliar mediante IDs/versiones/idempotencia y, cuando
proceda, una lectura de verificación con `DataStoreGetOptions.UseCache = false`; no reintentar ciegamente una
mutación no idempotente como si el fallo garantizara ausencia de escritura.

`GetAsync()` puede servirse desde caché local. No desactivar la caché de forma rutinaria: reservar lecturas
uncached para reconciliación/consistencia que realmente necesite el valor más reciente y asumir su coste adicional
de budget.

Usar `DataStoreService:GetRequestBudgetForRequestType()` y la observabilidad actual como backpressure operativo. Si se
adopta `SetRateLimitForRequestType()`, sus valores forman parte de la configuración operativa versionada/validada; no
hardcodear fórmulas históricas de quota como si fueran contrato permanente de Roblox.

Open Cloud comparte budgets relevantes con el experience; las herramientas operativas deben rate-limit para no degradar
tráfico live. Reducir primero requests, payloads y almacenamiento innecesario antes de depender de capacidad ampliada/
Extended Services.

Si se habilitan **Extended Services**, su presupuesto mensual, estado de billing y throttling pasan a ser configuración
productiva. Roblox puede auto-throttlear el uso extendido al alcanzar el budget o al reducirlo por debajo del consumo
acumulado; crear alertas antes del cap, probar la degradación al volver a límites default y no asumir que pagar
capacidad
elimina hot keys, per-resource semantics, retries o la necesidad de backpressure.

No precomprimir payloads únicamente para intentar ahorrar quota de DataStore: Roblox aplica compresión de almacenamiento
y el contrato debe optimizar schema/tamaño semántico antes que añadir CPU/complexity de compresión propia.

---

# 23. PLAYER PROFILE

Una key primaria:

`User_<UserId>`.

Contiene:

Account

Roster

Characters

Settings

Collections

AccountAchievements

AccountFlags

Session metadata.

Cada Character contiene:

Identity

Progression

Stats metadata

Equipment

Inventory

Currencies

Quests

Reputations

Professions

Talents

Abilities

Loadouts

PvP

Exploration

Lockouts

CharacterAchievements.

Evitar fragmentar aquello que debe actualizarse atómicamente.

---

# 24. PROFILE MIGRATIONS — CORRECCIÓN CRÍTICA

Eliminar el comportamiento actual:

```text
schema diferente/incompleto → ProfileFactory.empty()
```

Eso queda PROHIBIDO.

Crear:

`MigrationRegistry`.

Migraciones:

```text
N → N+1
```

ordenadas.

Carga:

```text
READ
→ ENVELOPE VALIDATION
→ DETECT SCHEMA
→ RUN EVERY REQUIRED MIGRATION
→ CURRENT-SCHEMA VALIDATION
→ ACQUIRE SESSION
→ EXPOSE PROFILE
```

Si el schema:

es desconocido;

está corrupto;

no puede migrarse

entonces:

```text
QUARANTINE
→ BLOCK CHARACTER LOGIN
→ LOG INCIDENT
→ ENABLE STAFF RECOVERY
```

Jamás:

```text
CREATE EMPTY PROFILE
→ OVERWRITE OLD DATA
```

---

# 25. PROFILE QUARANTINE

Crear estado de cuarentena.

Staff autorizado puede:

inspect;

compare versions;

execute approved repair;

restore compatible DataStore version;

retry migration.

Nunca editar arbitrariamente JSON desde cliente.

---

# 26. SESSION LEASE

El perfil tiene una única sesión escritora.

Lease contiene:

```text
SessionId
JobId
PlaceId
CharacterId
AcquiredAt
RenewedAt
ExpiresAt
Generation
TransferNonce?
```

Acquire y renew mediante `UpdateAsync`.

No permitir dos servidores escritores simultáneos.

---

# 27. SAVES

Guardar:

dirty snapshots;

serialización por perfil;

retry ordenado;

backoff;

jitter;

autosave periódico escalonado entre jugadores/servidores;

player leave/release;

critical checkpoints donde perder el grant/estado sería costoso, incluidos receipts cuando corresponda;

shutdown flush limitado mediante `BindToClose` o lifecycle vigente equivalente.

No depender de `PlayerRemoving` ni del shutdown como única oportunidad de persistencia. El intervalo periódico debe ser
menor que cualquier lease/session timeout relevante y ajustarse a budgets/observabilidad reales, no a una cifra
histórica copiada de un ejemplo. Cuando `Players.PlayerRemoving` exponga `PlayerExitReason`, puede registrarse como
telemetría para diagnóstico/recovery, pero nunca sustituye el protocolo de save/release ni se trata como prueba de que
un guardado terminó correctamente.

Un retry antiguo no puede sobrescribir un save nuevo.

---

# 28. TRANSACCIONES ENTRE DOCUMENTOS

Roblox DataStores no proporcionan transacciones ACID multi-key.

Por ello crear:

`TransactionCoordinator`.

Usar durable saga.

Estados:

```text
CREATED
PREPARED
RESERVED
APPLYING
COMMITTED
COMPENSATING
COMPENSATED
FAILED_REQUIRES_REVIEW
```

Cada transaction:

```text
TransactionId
Type
Participants
Inputs
Outputs
ExpectedVersions
CreatedAt
UpdatedAt
State
AppliedSteps
Receipts
```

Cada paso es idempotente.

---

# 29. USOS OBLIGATORIOS DEL TRANSACTION COORDINATOR

Aplicarlo a:

direct player trade;

guild bank deposit;

guild bank withdrawal;

guild research payment;

auction listing;

auction purchase;

mail attachments;

offline reward delivery;

construction costs que afecten perfil + world/guild;

premium grants cuando interactúen con estado persistente.

---

# 30. TRADE

Trade no puede ser una transferencia inmediata entre dos perfiles sin journal durable.

Pipeline:

```text
REQUEST
→ NEGOTIATION
→ BOTH LOCK
→ CREATE TRANSACTION
→ RESERVE ITEMS/CURRENCY
→ PERSIST RESERVATIONS
→ APPLY RECIPROCAL DELIVERY
→ COMMIT
→ RELEASE LOCKS
```

Disconnect en cualquier paso debe ser recuperable.

---

# 31. AUCTION HOUSE

Auction truth vive en `ASTRAKYN_AuctionListings`.

Listing:

```text
ListingId
SellerUserId
SellerCharacterId
ItemSnapshot
Quantity
Price
CurrencyId
CreatedAt
ExpiresAt
State
BuyerUserId?
TransactionId?
```

Item sale del inventario mediante transacción antes de quedar `ACTIVE`.

MemoryStore contiene únicamente índices rápidos/search cache.

Purchase usa durable transaction.

Expiration usa worker con leases distribuidos.

No hacer scans globales de todas las listings por servidor.

---

# 32. MAIL / DELIVERY INBOX

Mailbox es account-level y separado del perfil principal para permitir entrega cross-server.

ASTRAKYN Mail se define como **delivery inbox estructurado**, no como sistema alternativo de conversación
jugador↔jugador.

Entry canónica:

```text
MailId
SenderKind
SenderId?
RecipientUserId
MessageTemplateId
MessageParameters
CreatedAt
ExpiresAt
Attachments
Currency
State
TransactionId?
```

`MessageTemplateId` y sus parámetros producen texto localizado controlado por el juego.

No aceptar `Subject`/`Body` libres de un jugador destinados a otro jugador mediante este sistema. Una comunicación
originada por un usuario y entregada a otros usuarios debe seguir las reglas actuales de chat de Roblox y pasar por
`TextChannel`/`TextChatService` cuando sea conversación.

Attachments poseen ownership de escrow.

Recoger es idempotente.

Delete/expiration no destruye assets accidentalmente.

Cualquier UGC persistido permitido fuera de conversación se filtra server-side y respeta las restricciones de
rate/privacy
vigentes.

---

# 33. GUILDS

Separar:

`GuildCore`

y

`GuildBank`.

GuildCore:

identity;

roster;

ranks;

permissions;

MOTD;

description;

progression;

research;

metadata.

GuildBank:

tabs;

items;

currency;

receipts;

revision.

Player ↔ GuildBank operations usan TransactionCoordinator.

---

# 34. LEADERBOARDS

Eliminar la dependencia de una única shared key gigante.

Usar OrderedDataStore para rankings adecuados.

Rankings por:

season;

category.

Mantener archive metadata separado.

No hacer polling agresivo.

---

# 35. RIGHT TO ERASURE / RTBF

Inventariar todo store/sistema que contenga:

- UserId u otros identificadores personales;
- personal data;
- player-generated text;
- referencias externas asociables a una persona.

Configurar **RTBF deletion templates** de Roblox como workflow preferente para DataStores/OrderedDataStores cuando el
schema encaje en los patrones soportados.

Si el schema no puede cubrirse con templates, o existen datos personales fuera de DataStores, implementar el workflow de
right-to-erasure mediante los webhooks/Open Cloud vigentes y verificar autenticidad, idempotencia y completitud.

No considerar cerrado un request hasta verificar que todo el inventario de datos aplicable fue eliminado o
pseudonimizado conforme a la política definida.

Staff audit y moderation records deben tener política explícita de retención/pseudonimización compatible con las
obligaciones aplicables.

---

# 36. NETWORK PROTOCOL

Mantener catálogo central, pero evolucionar `RemoteCatalog` a un protocolo tipado real.

Cada endpoint define:

```text
Id
Direction
PayloadSchema
RequiredCapability
RatePolicy
MaxPayload
TransportClass
ReliabilityClass
LoggingPolicy
ErrorPolicy
ProtocolVersion
```

`TransportClass` selecciona intencionalmente entre:

- `RemoteEvent` para eventos donde orden/reliability importan;
- `UnreliableRemoteEvent` para datos efímeros, frecuentes y tolerantes a pérdida/reorder;
- `RemoteFunction`/request-response solo cuando el caller realmente necesita respuesta y el yielding/failure mode es
  aceptable.

Preferir `RemoteEvent` cuando no sea necesaria una respuesta síncrona. No usar `RemoteFunction:InvokeClient()` para
autoridad, progreso crítico ni para bloquear un flujo de servidor: un error del cliente se propaga al servidor, una
desconexión produce error y un cliente que nunca retorna puede dejar al servidor esperando indefinidamente. Cuando el
servidor no pueda tolerar ese modo de fallo, usar eventos asíncronos + correlation ID/state machine. Bajo Streaming, el
retorno de una RemoteFunction tampoco demuestra que una `Instance` creada por el servidor ya se haya replicado al
cliente; transportar estado/IDs lógicos y resolver disponibilidad de instancias de forma independiente.

Nunca usar `UnreliableRemoteEvent` para currency, inventory, grants, transactions, permissions, quest completion u otro
estado crítico. Respetar sus límites vigentes de payload/rate y diseñar para pérdida.

No basta `PayloadKeys`.

Validar tipos, tamaños y rangos antes de llegar al dominio.

---

# 37. VALIDACIÓN DE PAYLOAD

Validar:

type;

NaN;

infinity;

bounds;

string bytes;

table depth;

node count;

enum;

ID existence;

ownership;

distance;

state;

cooldown;

resource;

permission;

target;

sequence.

---

# 38. RATE LIMITING

Usar políticas token-bucket/leaky-bucket o equivalente adecuado por acción.

Cada endpoint/acción define:

- burst;
- sustained rate;
- cost;
- scope;
- response policy.

Rate limiting server-side aplica a **toda lógica activable por cliente**, no solo a RemoteEvents: también
ProximityPrompt, ClickDetector, DragDetector, Touched, interacciones físicas, requests indirectos y cualquier path que
pueda producir trabajo costoso o efectos durables.

Tratar ProximityPrompt/ClickDetector/DragDetector como input no confiable y revalidar server-side enabled/state,
distancia/posición, line-of-sight cuando importe, permisos, ownership y cooldown. En la protección nativa actual, solo
`ProximityPrompt.Triggered` incorpora una comprobación server-side de distancia; los eventos de `ClickDetector` no
tienen esas comprobaciones y `DragDetector` solo aplica checks parciales a sus eventos de drag. Esas defensas nativas
son defense-in-depth, nunca autoridad de negocio.

No kick inmediato únicamente por un pico legítimo.

Security response distingue:

- malformed;
- abusive;
- suspicious;
- high-confidence exploit.

El límite interno de Roblox para remotes no sustituye el rate limit de negocio de ASTRAKYN.

---

# 39. CHARACTER SHEET — REFACTORIZACIÓN OBLIGATORIA

Eliminar el mega-remote actual `CharacterSheet`.

No transmitir inventario, quests, guild, mail, auras, economy, leaderboard y todo lo demás en un único payload.

Crear streams por dominio:

```text
SessionSnapshot
CharacterSnapshot
StatsSnapshot
ProgressionSnapshot
InventorySnapshot
InventoryDelta
EquipmentSnapshot
EquipmentDelta
QuestSnapshot
QuestDelta
EconomySnapshot
EconomyDelta
SocialSnapshot
SocialDelta
GuildSnapshot
GuildDelta
WorldSnapshot
WorldDelta
CollectionSnapshot
CollectionDelta
CombatVitals
CombatStateDelta
TargetState
StaffCapabilities
```

Cada stream posee:

`Sequence`

`Revision`

o versión equivalente.

Cliente descarta deltas antiguos.

Si existe gap:

solicita resync de ese dominio únicamente.

---

# 40. SERVER AUTHORITY

Servidor es la source-of-truth final de reglas, progresión, economía y decisiones críticas.

Servidor decide siempre:

- damage/healing;
- cooldowns/resources;
- loot/currency/items/equipment;
- XP/quest credit/reputation;
- crafting/auction/trade/delivery;
- guild bank;
- PvP/dungeon/raid results;
- rewards/purchases.

Cliente expresa intención/input y puede realizar presentación/predicción cosmética cuando el sistema lo permita; la
confirmación autoritativa llega del servidor.

Para física/movimiento, evaluar el **Engine Server Authority model** vigente de Roblox. Antes de activarlo en
producción,
confirmar su estado actual (GA/beta), compatibilidad y requisitos en documentación oficial y validar en una copia
privada
publicada. Si está soportado para producción, su adopción requiere la configuración de Workspace exigida por Roblox
(`AuthorityMode`, Next Generation Replication, fixed simulation, Input Action System, deferred signals y streaming,
según
la versión vigente).

Si se adopta, la simulación central compartida cliente/servidor se implementa mediante `RunService:BindToSimulation()`
en módulos inicializados por ambos peers y solo toca APIs marcadas **Simulation Access**. Estado custom que participe en
prediction/rollback se expresa mediante estado sincronizable soportado; para atributos de Instances predichas respetar
los límites vigentes del modelo (actualmente solo los primeros 64 atributos, nombre de hasta 50 caracteres y strings de
hasta 50 caracteres) y escribirlos desde la simulación vinculada para que el engine pueda rastrearlos y re-simularlos.
No convertir Attributes en un blob genérico de estado MMO.

Rollback/resimulation puede volver a ejecutar callbacks de `BindToSimulation()` y property-changed signals varias veces
en un frame. Esos callbacks no disparan directamente side effects one-shot como grants, analytics, HTTP/remotes,
sonidos o VFX irreversibles. Separar estado determinista de presentación/commit, usar `RunService:IsResimulating()` o la
estrategia vigente equivalente cuando proceda y observar `Rollback`/`Misprediction` para diagnóstico sin convertir una
misprediction normal en sanción anti-cheat.

Mientras Server Authority no esté aprobado para el target productivo, mantener validación server-side de movimiento y
network ownership como defensa convencional; nunca confiar ciegamente en CFrame/velocidad reportados o simulados por el
cliente.

Mantener `Workspace.RejectCharacterDeletions = Enum.RejectCharacterDeletions.Enabled` —o el estado equivalente
recomendado vigente— salvo una incompatibilidad documentada y probada. Esta property no scriptable hace que el
servidor rechace intentos del cliente de borrar el player character; verificarla en el DataModel generado/publicado en
vez de depender silenciosamente del default/rollout de Roblox.

---

# 41. SECURITY BOUNDARY Y CONFIDENCIALIDAD

No crear remotes que permitan:

- arbitrary instance path;
- arbitrary property modification;
- arbitrary asset ID;
- arbitrary module require;
- arbitrary command execution;
- arbitrary datastore key;
- arbitrary Lua.

Asumir que **todo lo replicado al cliente es visible/inspeccionable**, incluyendo LocalScripts y ModuleScripts aunque no
se
ejecuten. Secretos, reglas sensibles, datos privados, unreleased assets y autoridad crítica permanecen server-side/no
replicados.

Los subplaces restringidos usan control de acceso de plataforma (`Secure within universe only` o equivalente vigente) y
server-side validation de transfer tickets.

No confiar en ocultar UI, nombres, descendants o paths como seguridad.

---

# 42. NETWORK OWNERSHIP Y FÍSICA

Auditar:

- player characters;
- vehicles;
- projectiles;
- physics bosses;
- ragdolls;
- knockbacks;
- moving platforms;
- assemblies unanchored gameplay-critical.

No confiar en posición/velocidad/`Touched` provenientes de física controlada por cliente para conceder rewards,
interactions o resultados críticos.

Cuando se use el modelo convencional de ownership, asignar/manipular network ownership explícitamente donde el riesgo lo
justifique y validar movimiento con tolerancia a latency/jitter.

Mantener adaptive timestepping como comportamiento general del motor salvo que un mecanismo concreto demuestre mediante
profiling/pruebas que fixed timestep mejora estabilidad de forma aceptable, o que una feature oficial adoptada lo exija.
No convertir fixed timestep en ajuste global por intuición.

Cuando Server Authority de Roblox esté aprobado y adoptado para el target productivo, preferir su ownership/prediction
model para objetos críticos compatibles y seguir sus reglas de simulation access/prediction.

---

# 43. RBAC — REEMPLAZO COMPLETO DE ADMINS

Eliminar:

`ConfigService.isAdmin()`

`Permissions == "Admin"`

`adminUserIds`

`AdminCommand`

`AdminSetFlag`

como modelo de autorización.

Crear:

`StaffIdentityService`

`RBACService`

`StaffActionService`

`StaffAuditService`

`SupportTicketService`

`PlayerModerationService`

`StaffConsole`.

No llamar al boundary de moderación de jugadores `ModerationService`, porque Roblox expone un Service nativo con ese
nombre para capacidades de moderación/reviewable content distintas del Ban API de Players.

---

# 44. STAFF ROLES

Roles canónicos:

```text
PLAYER
SUPPORT
MODERATOR
GAME_MASTER
SENIOR_GAME_MASTER
LIVEOPS
SECURITY
ADMINISTRATOR
OWNER
SYSTEM
```

`SYSTEM` solo puede pertenecer a service principals internos.

Nunca a un Player.

Un usuario puede tener más de un rol.

---

# 45. ROLE MODEL

RoleDefinition:

```text
RoleId
DisplayName
Priority
Inherits
Permissions
ExplicitDenies
CanTargetMaxPriority
AssignableBy
```

Priority no concede permisos automáticamente.

Permissions son explícitos.

---

# 46. PERMISSION NAMESPACE

Usar IDs estables.

Ejemplos obligatorios:

```text
staff.console.open

staff.ticket.read
staff.ticket.claim
staff.ticket.reply
staff.ticket.resolve

staff.player.inspect
staff.player.message
staff.player.teleport.self
staff.player.teleport.other
staff.player.summon
staff.player.unstuck
staff.player.revive
staff.player.kick

staff.moderation.warn
staff.moderation.mute
staff.moderation.ban
staff.moderation.unban
staff.moderation.device_block
staff.moderation.alt_enforcement

staff.character.inspect
staff.character.rename
staff.character.restore
staff.character.quest.read
staff.character.quest.correct
staff.character.progression.read
staff.character.progression.correct
staff.character.reputation.correct
staff.character.profession.correct

staff.inventory.inspect
staff.inventory.compensation_package
staff.inventory.direct_grant
staff.inventory.remove

staff.currency.inspect
staff.currency.compensation_package
staff.currency.adjust

staff.guild.inspect
staff.guild.moderate
staff.guild.transfer_ownership
staff.guild.bank.inspect
staff.guild.bank.repair

staff.instance.inspect
staff.instance.teleport
staff.instance.reset
staff.instance.close

staff.world.inspect
staff.world.teleport
staff.world.event.start
staff.world.event.stop
staff.world.event.recover

staff.liveops.read
staff.liveops.override
staff.liveops.announce
staff.liveops.server_drain

staff.security.audit.read
staff.security.session.quarantine
staff.security.session.release

staff.staff.read
staff.staff.assign
staff.staff.revoke

staff.data.quarantine.read
staff.data.repair
staff.data.restore_version

staff.audit.read
```

No usar un genérico:

`admin.all`

excepto internamente para OWNER/SYSTEM si la implementación necesita expansión controlada.

---

# 47. ROL DEFAULT CAPABILITIES

`PLAYER`

Sin permisos staff.

`SUPPORT`

Tickets, inspección no sensible y asistencia sin modificar economía/progreso.

`MODERATOR`

Support + warn/mute/kick/report handling.

`GAME_MASTER`

Moderator + teleport/summon/unstuck/revive/quest correction/instance assistance.

`SENIOR_GAME_MASTER`

GM + reparación offline controlada, guild correction y compensation packages predefinidos.

`LIVEOPS`

Eventos, anuncios, rollout/overrides y server operations. No adquiere automáticamente poderes de GM.

`SECURITY`

Moderation enforcement, bans, audit y security quarantine. No obtiene grants económicos automáticamente.

`ADMINISTRATOR`

Administración amplia, staff assignments inferiores, operaciones de recuperación y cambios de alto riesgo mediante
aprobación.

`OWNER`

Break-glass root.

`SYSTEM`

Operaciones internas server-to-server.

---

# 48. HIGH-RISK STAFF ACTIONS

Acciones `CRITICAL`:

- direct arbitrary currency adjustment;
- direct arbitrary item grant/removal;
- permanent character deletion;
- profile restoration;
- guild ownership transfer;
- staff role assignment/revocation de roles elevados;
- mass moderation;
- global destructive LiveOps;
- manual transaction override.

Requieren:

reason;

correlation ID;

before-state hash;

after-state/delta;

durable audit;

confirmación explícita;

segunda aprobación para Administrators.

OWNER puede usar break-glass sin segundo aprobador únicamente con:

reason obligatorio;

alerta;

audit `BREAK_GLASS`.

---

# 49. STAFF ACTION CATALOG

No ejecutar strings como:

`"kick"`

`"currency"`

`"setlevel"`.

Crear `StaffActionCatalog`.

Cada action:

```text
ActionId
RequiredPermission
RiskLevel
TargetType
PayloadSchema
ReasonPolicy
ApprovalPolicy
RatePolicy
Reversible
Handler
```

Client envía:

```text
RequestId
ActionId
Target
Parameters
Reason
```

Server:

authenticates;

authorizes;

validates;

executes;

audits.

---

# 50. STAFF AUDIT

Cada acción staff:

```text
AuditId
CorrelationId
ActorUserId
ActorRoles
ActionId
Target
Reason
Risk
BeforeSummary
AfterSummary
PlaceId
JobId
Timestamp
Result
ErrorCode?
ApproverUserId?
BreakGlass
```

Audit lógico append-only.

No permitir al mismo staff borrar sus propios registros.

---

# 51. STAFF CONSOLE

UI productiva autorizada.

Tabs:

Dashboard

Tickets

Players

Characters

Moderation

Inventory

Economy

Guilds

Instances

World

LiveOps

Security

Data Recovery

Audit.

No mostrar el StaffConsole hasta recibir `StaffCapabilities` del servidor.

Ocultar UI NO es seguridad.

---

# 52. STAFF MOVEMENT POWERS

GM teleport/fly/noclip/invisibility son capacidades productivas RBAC.

MovementGuard reconoce temporalmente una `StaffMovementCapability`.

No desactiva globalmente seguridad.

Cada activación y desactivación se audita.

---

# 53. NO LUA CONSOLE

No crear en producción:

Lua executor;

eval;

arbitrary require;

arbitrary instance explorer con writes;

arbitrary DataStore editor.

Staff tooling es typed y limitado.

---

# 54. SUPPORT / PLAYER FEEDBACK

Para el **front door de soporte/feedback del jugador**, evaluar primero la capacidad nativa vigente de
`SocialService:PromptFeedbackSubmissionAsync()`, incluyendo `Enum.FeedbackType.PlayerSupport` cuando corresponda.
No recrear una superficie de intake propia si la nativa cubre el caso de uso, permisos y experiencia requerida.

Cuando ASTRAKYN necesite un caso operativo interno durable —por ejemplo, ownership por staff, correlación con
incidentes, recovery de datos o workflow especializado— puede mantener `SupportTicketService` como **case-management
backend**, no
como sustituto de la superficie nativa ni como un chat paralelo.

Ticket/case interno, cuando sea necesario:

```text
TicketId
AuthorUserId
CharacterId
Category
FilteredText
Status
AssignedStaff?
CreatedAt
UpdatedAt
ResolutionCode?
```

Estados:

OPEN

ASSIGNED

WAITING_PLAYER

RESOLVED

CLOSED.

Queue cross-server.

Staff notes privadas y no replicadas a jugadores.

Texto UGC filtrado server-side; si el producto añade un hilo conversacional jugador↔staff con replies, ese flujo debe
pasar por el mecanismo de comunicación de Roblox que corresponda y respetar privacy/parental/reportability, no
convertirse
en mensajería custom persistida que eluda `TextChatService`.

---

# 55. MODERATION

El boundary ASTRAKYN para disciplina de jugadores se llama `PlayerModerationService` o equivalente inequívoco.

Bans productivos usan la **Ban API de `Players`** vigente (`Players:BanAsync()`, `Players:UnbanAsync()` y ban history)
cuando corresponda. `Players.BanningEnabled` debe estar configurado correctamente en los Places productivos.

El `ModerationService` nativo de Roblox no se confunde con player bans; usarlo únicamente para los casos que su API
actual
cubra.

Mantener:

- rules page accesible;
- appeal instructions;
- display reason apropiado;
- private staff reason;
- durable audit;
- history-aware escalation cuando el diseño lo justifique.

Permissions distintas para:

- temporary ban;
- permanent ban;
- alt-account enforcement;
- device block;
- unban.

Alt/device enforcement usa exclusivamente las opciones oficiales vigentes y no inventa fingerprinting propio.

---

# 56. CHAT

Eliminar transporte propio de conversación:

`ChatSend`

`ChatMessage`.

Toda comunicación originada por un usuario y entregada como conversación a uno o más usuarios utiliza
**`TextChatService` + `TextChannel`**.

La UI de chat puede ser personalizada, pero el envío/delivery sigue pasando por TextChatService para conservar
filtering,
privacy/parental settings, moderation y reportability.

Canales/features previstos:

- general;
- local;
- party;
- raid;
- guild;
- instance;
- system/developer announcements cuando no sean mensajes de usuario.

No reconstruir filtros, mute, block, report o privacy con un transporte paralelo inferior. Los callbacks del sistema de
chat deben respetar el contexto documentado por Roblox: `TextChannel.ShouldDeliverCallback` en servidor para delivery
condicional y callbacks de presentación en cliente; deben ser no bloqueantes/no-yield para no atascar el pipeline de
chat.

---

# 57. GLOBAL / CROSS-SERVER CHAT

Cuando forme parte del diseño, utilizar el **cross-server chat nativo** actual de Roblox para comunicación global
general
si sus límites y segmentación encajan con ASTRAKYN.

Aprovechar las capacidades nativas de filtering, blocking, muting, reporting y agrupación/compatibilidad de usuarios.

No reconstruir global chat con `MessagingService` como mecanismo de conversación.

Cross-server chat se trata como comunicación social, no como delivery de estado crítico; no depender de que un mensaje
de
chat llegue para producir gameplay durable.

---

# 58. PRIVATE / GROUP CHAT

Usar las APIs actuales de `TextChatService` para comprobar compatibilidad antes de iniciar comunicación.

Para direct chat, usar el mecanismo oficial `TextChannel:SetDirectChatRequester()` y las comprobaciones vigentes como:

- `CanUserChatAsync()`;
- `CanUsersChatAsync()`;
- `CanUsersDirectChatAsync()`.

`GetChatGroupsAsync(players)` puede utilizarse para obtener grupos compatibles mientras los usuarios están presentes.

Chat-group IDs/resultados son efímeros.

No persistirlos como permisos duraderos ni asumir que compatibilidad/privacy permanece igual entre sesiones.

---

# 59. PERSISTED USER TEXT

Distinguir **conversación** de **UGC no conversacional**.

Conversación originada por usuarios se rige por las secciones de Chat y no se implementa como mailbox/thread custom.

Para UGC no conversacional que deba persistir, por ejemplo:

- guild name;
- guild MOTD;
- guild description;
- character names;
- pet/custom labels;
- support intake;
- signs/boards si el diseño los permite;

usar `TextService:FilterStringAsync()` y el resultado adecuado a la audiencia (`GetNonChatStringForUserAsync()` o
`GetNonChatStringForBroadcastAsync()`). Filtrar server-side cuando el usuario envía el texto, una sola vez por
submission,
y envolver tanto `FilterStringAsync()` como la materialización del resultado en manejo de error. Si falla, no mostrar el
texto y **no** añadir un retry loop de aplicación: la referencia vigente indica que `FilterStringAsync()` ya reintenta
internamente.

`FilterStringAsync()` actualmente también falla si `fromUserId` no está online en ese servidor. Persistir el
AuthorUserId/provenance cuando haga falta cumplir la guía de re-filtrado al recuperar, pero no diseñar una surface que
dependa de poder volver a filtrar raw text con un autor offline. Antes de mostrar texto persistido, usar la surface
oficial vigente para su audiencia; si el re-filtrado requerido no puede realizarse de forma soportada, fallar cerrado/
ocultar hasta que exista un camino seguro en vez de mostrar raw o saltarse el filtro. Minimizar cualquier retención de
raw UGC y nunca usarla como fallback visible.

El texto editable no conversacional visible entre usuarios —por ejemplo signs/boards— debe respetar como mínimo el
rate limit de **1 minuto** exigido actualmente por las Chat System Guidelines, además de las restricciones de safety y
privacy aplicables. Si se añaden replies/hilos o el flujo se convierte en conversación, deja de tratarse como simple
UGC no conversacional y debe integrarse con `TextChatService`.

Player mail no contiene `Subject`/`Body` libre entre jugadores; usa delivery estructurado/templateado según la sección
32.

---

# 60. ANALYTICS / TELEMETRY

El wrapper propio de ASTRAKYN se llama:

`TelemetryService.luau`

Nunca `AnalyticsService.luau`, para no colisionar con `game:GetService("AnalyticsService")`.

Integrar el `AnalyticsService` oficial y preferir el tipo semántico nativo que corresponda: Economy, Funnel,
Onboarding Funnel, Progression, Journey y Custom events. No crear custom events que dupliquen una primitiva nativa ya
soportada. Usar Creator Dashboard como surface primaria de análisis de plataforma y no introducir código nuevo sobre
métodos `Fire*` deprecados cuando existe el equivalente `Log*` vigente.

Los eventos que representan resultados autoritativos se emiten desde servidor y, cuando la API lo requiera, únicamente
en experiencias publicadas.

Enviar eventos definitivos solo después de que la operación correspondiente esté confirmada/committed.

Respetar los límites actuales de rate, custom fields, cardinalidad y event names; no codificar supuestos históricos como
si fueran infinitos.

---

# 61. ANALYTICS DOMAINS

Instrumentar con intención y taxonomía estable:

- onboarding;
- character creation;
- progression;
- quests;
- combat/death;
- dungeons/raids;
- PvP;
- crafting;
- economy/auction;
- retention funnels;
- UI adoption;
- social/group formation;
- performance/reliability outcomes relevantes.

Usar Onboarding/Progression/Journey/Funnel/Economy events oficiales donde encajen antes de inventar custom events
equivalentes. Journeys sirven para paths no lineales; funnels para secuencias ordenadas.

No usar PlayerId, CharacterId, transaction IDs u otros valores de cardinalidad explosiva como custom fields cuando no
sea
necesario.

---

# 62. ECONOMY ANALYTICS

Cada source/sink importante produce el evento de economía oficial apropiado con:

- currency/resource type;
- amount;
- ending balance;
- transaction type;
- item SKU/context cuando proceda.

No emitir economía antes de commit durable cuando el evento representaría un resultado definitivo.

No duplicar el mismo movimiento como Source/Sink y custom event salvo una necesidad analítica documentada.

---

# 63. MONETIZATION

Crear `PurchaseCoordinator` o `MonetizationService` como boundary ASTRAKYN.

No crear un módulo propio llamado `CommerceService`, porque Roblox expone un Service nativo con ese nombre para
capabilities de commerce distintas de los virtual purchases tradicionales.

Para Developer Products, `MarketplaceService.ProcessReceipt` sigue siendo la autoridad de grant según la documentación
vigente:

- validar receipt;
- mapear ProductId a catálogo;
- idempotent grant;
- registrar receipt/transaction durable;
- devolver `PurchaseGranted` únicamente después del grant confirmado.

Nunca usar `PromptProductPurchaseFinished` como autoridad final de Developer Product.

Precios mostrados en UI se obtienen dinámicamente de APIs oficiales; no hardcodear Robux prices porque Managed Pricing/
regional pricing puede variar el precio visible por usuario.

Managed Pricing unifica regional pricing y price optimization; cualquier UI de compra debe obtener la información de
precio vigente para el usuario en vez de asumir un precio global fijo.

Desde el 30 de mayo de 2026 Roblox deshabilitó las ventas **cross-game** de Developer Products **y passes**. No diseñar
nuevas dependencias sobre esos flujos. Si ASTRAKYN adopta Robux Transfers, tratarlas como una capability distinta:
iniciar el flujo con la API oficial server-side y procesar los receipts de transferencia con `BindReceiptHandler` para
los `ReceiptType` correspondientes. Esto no sustituye `ProcessReceipt` para Developer Products.

Para metadata/precio de catálogo en código nuevo, usar la surface no deprecada vigente (`GetProductInfoAsync()` en la
referencia actual) y no reintroducir `GetProductInfo()`, aunque alguna guía conceptual de Roblox conserve todavía un
ejemplo antiguo. Ante discrepancias de este tipo, la Engine API reference/deprecated inventory vigente gobierna la
elección de API y la guía gobierna el workflow conceptual.

Cuando haya que consultar múltiples productos/passes independientes, usar las APIs bulk/ranking/recommendation oficiales
si resuelven el caso o concurrencia **acotada** en las surfaces cuya referencia documente Transparent Batching, en vez
de
serializar N yields independientes. No asumir que todas las Engine APIs se batchéan ni lanzar fan-out sin límites.

Los **Commerce Products** de bienes físicos/real-world commerce son una capability separada y opcional, no el pipeline
normal de Robux. Si ASTRAKYN la adopta, usar `CommerceService:PromptCommerceProductPurchase()` y la elegibilidad vigente
de `PolicyService`; no usar los endpoints legacy `PromptRealWorldCommerceBrowser()` ni
`UserEligibleForRealWorldCommerceAsync()`. `PromptCommerceProductPurchaseFinished` solo significa que se cerró el
webview y nunca autoriza un grant. Un Developer Product incluido como beneficio digital sigue el `ProcessReceipt`
normal; cancelaciones/refunds del producto físico se reconcilian mediante Creator Webhooks de commerce autenticados e
idempotentes porque Roblox no revoca automáticamente ese Developer Product. Revalidar Commerce/Advertising/Community
Standards y eligibility en cada release que active esta surface.

---

# 64. PURCHASE POLICY Y PREMIUM FEATURES

Separar:

- prompt;
- eligibility/policy;
- receipt;
- grant;
- durable ledger;
- analytics.

No otorgar nada crítico desde LocalScript.

Antes de mostrar/permitir monetización condicionada por región, edad o plataforma, consultar `PolicyService` y obedecer
sus flags vigentes. `GetPolicyInfoForPlayerAsync()` cede y puede fallar: envolverlo en `pcall`/boundary de errores y, si
no puede resolverse una policy necesaria para una feature restringida, degradar hacia el comportamiento
seguro/restringido en vez de asumir elegibilidad. No inferir policy desde locale/país como sustituto de `PolicyService`.

Si existe paid random content directo o indirecto:

- mostrar todos los outcomes y probabilidades numéricas reales antes del gasto;
- actualizar odds cuando cambien por estado del usuario;
- respetar `ArePaidRandomItemsRestricted`;
- respetar `IsPaidItemTradingAllowed` para trade de paid items;
- ofrecer un tratamiento compatible para usuarios no elegibles.

No usar falsa urgencia, countdowns engañosos, stock falso ni presión inapropiada, especialmente para menores.

Subscriptions/passes/products mantienen beneficios claros y consistentes en plataformas conforme a la política vigente.

---

# 65. LOCALIZATION

Crear `LocalizationServiceAdapter` solo para lógica propia de producto; no reemplazar las capacidades nativas.

No usar `profile.Settings.Locale = "es"` como única fuente.

Soportar:

- platform locale;
- selección de idioma soportada cuando proceda;
- Cloud Localization Table/LocalizationTables;
- stable localization keys/contexts;
- parámetros dinámicos localizables;
- automatic translation como apoyo;
- traducción/revisión humana para lore, monetización, seguridad, términos sensibles y copy crítico.

No concatenar fragmentos de frases que necesiten traducción.

`AutoLocalize`/Automatic Text Capture se habilita únicamente para strings que realmente deban localizarse; nombres,
identificadores o texto único que no deba traducirse se excluyen explícitamente. Usar contexts/parameters para texto
dinámico en vez de concatenar frases.

Las traducciones automáticas no sustituyen una traducción manual ya aprobada; la tabla cloud es el source-of-truth de
traducciones publicadas. Una traducción manual/bloqueada deja de recibir actualizaciones automáticas, incluidas mejoras
de safety, por lo que copy sensible bloqueado requiere revisión humana periódica.

---

# 66. PRIVACY, SECRETS Y OPEN CLOUD

Mantener un Data Inventory dentro de `ESTADO_ACTUAL.md`/contratos de datos cuando corresponda.

Documentar:

- qué UserIds/datos personales se guardan;
- dónde;
- por qué;
- retention;
- access control;
- RTBF behavior.

Open Cloud credentials jamás dentro del repositorio, DataStore, Attributes ni contenido replicado.

Usar API keys u OAuth 2.0 en endpoints Open Cloud que los soporten; no basar tooling productivo en APIs cookie-auth
legacy. Aplicar scopes/permisos mínimos, separar keys por aplicación/caso de uso y restringir recursos/universes. En
infraestructura externa con egress estable, aplicar restricciones IP/CIDR cuando sean compatibles; no imponerlas a
servers Roblox si impedirían su uso. Para recursos de grupo, preferir identidades dedicadas con los permisos mínimos
necesarios.

Secretos consumidos dentro de experiences autorizadas se almacenan en el Secrets Store oficial o mecanismo vigente
equivalente. No usar dominio wildcard cuando pueda restringirse y nunca insertar secretos en payloads o superficies
replicadas.

Distinguir siempre Engine API (`game:GetService()` dentro del experience) de Open Cloud (HTTP externo): no son
intercambiables.

El uso actual de `HttpService` para JSON/GUID no implica permiso arquitectónico para dependencias HTTP externas. Si se
introduce tráfico outbound, centralizarlo en un adapter server-only con HTTPS, Secrets Store, dominios/endpoints
explícitamente permitidos, `pcall`, timeouts/failure policy, validación y sanitización estricta de respuestas, batching
cuando exista, backoff exponencial y respeto de `retry-after` ante `429`. Una API externa no puede convertirse en
source-of-truth síncrono de gameplay crítico sin diseño de degradación/recovery. Para Open Cloud desde un experience,
usar solo el subconjunto de endpoints que Roblox documente como compatible con `HttpService`. Texto externo mostrado
a usuarios no puede usar HTTP como bypass del filtering/moderation pipeline aplicable.

Creator Webhooks que puedan causar cambios de datos, permisos o estado crítico deben configurarse con secret y validar
`roblox-signature` contra el body/timestamp según el esquema oficial, aplicar una ventana anti-replay razonable y
procesarse idempotentemente. Un payload webhook sin autenticidad/freshness válida se rechaza antes del dominio.

Si se adopta OAuth 2.0, revalidar su status vigente y restricciones antes de convertirlo en dependencia productiva; no
tratar una surface beta como estable por inferencia. API keys siguen sujetas a separación por caso de uso, mínimo
privilegio, resource targeting, rotación y almacenamiento seguro.

---

# 67. PLAYER ACCOUNT / CHARACTER MODEL

Para identidad de plataforma en código nuevo, usar `Player.User`/`User` como identidad domain-scoped cuando la Engine
API acepte `User`. No confundir ese identificador contextual con `Player.UserId`, que sigue siendo el identificador
global estable necesario para claves durables ya basadas en UserId, `GlobalDataStore`, interoperabilidad externa o APIs
que explícitamente requieran el ID global.

No migrar en masa claves persistidas `UserId` a `User.Id`: son espacios de identidad distintos. Cuando un ID global
legacy deba convertirse a la identidad domain-scoped del experience, resolverlo server-side mediante
`UserService:GetUserFromGlobalUserIdAsync()` y tratar el yield/fallo como dependencia de plataforma. No persistir el
objeto `User` como valor de DataStore; persistir únicamente representaciones soportadas y el identificador global cuando
se necesite identidad durable/global. `Name` y `DisplayName` son presentación, nunca claves de identidad.

Account:

roster;

collections;

account achievements;

settings;

global unlocks.

Character:

identity;

race;

origin;

class/archetype;

specialization;

level;

stats;

inventory;

equipment;

quests;

reputation;

professions;

talents;

PvP;

exploration;

lockouts.

---

# 68. CHARACTER ROSTER

Crear/select/delete/restore.

Character IDs son estables.

No usar display name como identity key.

Deletion crea tombstone y mantiene recuperación durante la política definida por producto.

No reutilizar CharacterId.

---

# 69. CHARACTER CREATION

Soportar:

name;

race;

origin;

class/archetype;

starting specialization cuando diseño lo requiera;

appearance;

body customization;

face;

hair;

skin;

eyes;

markings;

voice/profile.

Todas las combinaciones validadas server-side.

---

# 70. RACES

Conservar las razas originales existentes si pasan revisión artística/lore.

RaceDefinition controla:

body;

rig family;

customization;

culture;

starting area;

racial passive;

racial active;

faction;

animation profile;

architecture/lore hooks.

---

# 71. CLASSES / ARCHETYPES

Conservar la arquitectura actual cuando sea válida.

ClassDefinition controla:

role capabilities;

resource;

equipment;

abilities;

specializations;

stat profile;

progression.

---

# 72. SPECIALIZATIONS

Cada class actual tiene especializaciones data-driven.

Especialización modifica:

role;

abilities;

passives;

resource behavior;

talents;

gameplay identity.

---

# 73. TALENTS

Talent graph real:

nodes;

ranks;

prerequisites;

mutual exclusions;

passives;

active abilities;

modifiers;

loadouts;

respec.

No lógica hardcodeada por talento individual.

---

# 74. LOADOUTS

Guardar:

specialization;

talents;

action bars;

equipment set reference;

keybind profile.

Activación server-authoritative.

---

# 75. LEVEL Y XP

Mantener el level cap actualmente definido por el diseño vivo hasta que un cambio aprobado lo modifique.

No duplicar curvas.

`ProgressionDefinition` es la única fuente de thresholds.

XP sources catalogados.

---

# 76. STATS

Cada StatId debe tener:

source;

consumers;

formula/aggregation rule;

UI exposure cuando proceda.

Eliminar stats fantasma.

Ningún stat permanece únicamente porque estuvo definido históricamente.

---

# 77. ABILITIES

AbilityDefinition soporta:

cast;

channel;

instant;

target;

range;

cost;

resource;

cooldown;

charges;

GCD;

damage;

heal;

aura;

CC;

interrupt;

dispel;

movement;

summon;

threat;

animation;

VFX;

SFX.

Una ability shippable no permanece en catálogo sin ownership real. Debe tener al menos un consumer canónico —archetype,
specialization, racial, encounter/boss, hostile NPC kit, transformation u otra fuente de gameplay explícita— y todos sus
effects deben resolver a definitions vivas. "Existe un Trainer NPC" no cuenta como fuente de aprendizaje: si una ability
se aprende mediante trainer, el servidor necesita contrato propio de elegibilidad, requisitos, coste, persistencia e
idempotencia; la UI/NPC presentation nunca concede la ability por sí sola.

---

# 78. ABILITY EXECUTION

```text
INPUT
→ REQUEST
→ SECURITY
→ STATE VALIDATION
→ TARGET VALIDATION
→ RESOURCE/COOLDOWN PREFLIGHT
→ CAST START
→ EXECUTION COMMIT
→ EFFECTS
→ RESULT
→ REPLICATION
```

El preflight de resource/cooldown/GCD es **no mutante**. Resource, cooldown, charges y GCD se consumen/arman únicamente
cuando la ejecución autoritativa acepta el cast. Un rechazo antes del commit no deja cooldown/GCD gastado ni recurso
consumido. Un cast diferido que ya no puede resolverse debe abandonar limpiamente `Casting`/`Channeling`.

---

# 79. TARGETING

Soportar:

self;

friendly;

hostile;

focus;

party;

raid;

ground;

AoE;

cone;

line;

projectile.

Server verifica target y line-of-sight cuando corresponda.

---

# 80. COMBAT RESPONSIVENESS

Cliente puede anticipar:

animation;

cast bar;

cosmetic feedback.

Servidor confirma:

effect;

damage;

healing;

resource;

cooldown;

kill.

El autoattack es estado de combate persistente, **no una Ability que el cliente spamea**. El servidor posee target y
relojes de swing main/off-hand, deriva alcance/periodo/coefficient del perfil de arma y stats, y aplica haste mediante el
mismo motor de combate. Un swing no consume GCD, ability cooldown ni recurso. Casting/channeling, hard CC, muerte,
target inválido/no atacable y reglas PvP pueden pausar o cancelar el ciclo según corresponda. Cliente, UI y macros solo
pueden solicitar start/stop sobre un target ya validable; nunca envían damage, periodo de swing, hit result ni autoridad
de combate.

La geometría de combate falla cerrada: si el servidor no puede resolver source root, target/corpse position, alcance o LOS,
el swing/ability no se resuelve. Autoattack exige además arco frontal server-side; perder range/facing/LOS no destruye el
estado persistente, sino que reintenta con un intervalo corto centralizado. Los timers main/off-hand son independientes,
pero dos manos no impactan simultáneamente: tras un swing se conserva una separación mínima del hand opuesto. Un cambio
de haste/attack speed durante un swing reescala **la fracción restante** del timer en lugar de regalar un impacto inmediato
o reiniciar el swing desde cero. Cambiar físicamente el arma equipada es distinto de cambiar haste: invalida la identidad
del hand-clock y reinicia únicamente esa mano con el periodo completo del arma nueva, conservando la separación mínima
main/off-hand. `STARTATTACK`, retarget y `STOPATTACK`/`STARTATTACK` **no reinician** esos clocks: start/stop cambia
actividad/target sobre el estado persistente y solo muerte/session teardown destruyen los relojes. Un cliente o macro no
puede obtener swings adelantados recreando el estado de attack. Estas reglas se inspiran en invariantes maduras observadas
en AzerothCore 3.3.5a, sin copiar sus tablas/fórmulas de hit, miss, expertise o dual-wield.

`WeaponDamage` tiene ownership de item/equipment: el daño intrínseco deriva de `ItemLevel` + perfil de subtipo y pasa por
la misma calidad/upgrade/durability scaling del item. El stat global usa únicamente el arma primaria activa; una off-hand
aporta daño solo a su propio swing para no duplicar el eje de scaling de abilities. Dual wield no es un slot ficticio:
solo un arma one-hand marcada como compatible puede entrar en OffHand, exige otro one-hand válido en MainHand y la misma
instancia física no puede ocupar ambos slots. Romper/retirar el main-hand normaliza el par y no deja un arma secundaria
huérfana. Equip directo, loadouts y snapshots persistidos usan **la misma** regla canónica para slot, instancia física,
durability, RequiredLevel, UniqueEquipped y compatibilidad main/off-hand; ningún camino alternativo puede restaurar un
equipment que la puerta normal de equip rechazaría.

Las abilities que escalan con arma declaran su canal cuando no usan el primary. Un disparo marcado `WeaponChannel=Ranged`
exige una instancia Ranged equipada y toma `WeaponDamage` de esa instancia; no puede heredar accidentalmente el daño del
MainHand. La selección de canal es definition data, no una inferencia dispersa por nombre de ability.

La elegibilidad defensiva también depende de una clase de ataque canónica. `DamageResolver` deriva `Melee`, `Ranged` o
`Spell` desde la definition viva de la ability; `DefenseGraph` solo permite Dodge/Parry/Block al contrato Melee-contact
actual. Ranged y Spell conservan sus propios canales de hit/crit/resistance y no heredan evasión/deflection melee por
accidente. Glancing/crushing, weapon skill o ranged deflect no se introducen por analogía con otros MMORPG: requieren un
stat, definition y consumer ASTRAKYN explícitos antes de entrar en el grafo.

Combat engagement y action/control state son dimensiones distintas. `Casting`, `Channeling`, stun/silence/etc. no convierten
a un jugador engaged en out-of-combat para regen, macros o restricciones. El servidor mantiene un timeout de engagement
centralizado; al expirar vuelve a OOC si no existe otra causa de combate. Un efecto hostil resuelto (`Damage`, `Debuff`,
`CC`, `Interrupt` o movement ofensivo hacia Enemy) crea/refresca engagement; heal/shield/buff de soporte solo arrastra al
caster al combate si él o el aliado/party soportado ya estaba engaged. Self-buffs, resource effects y movement neutral no
inventan combate. Rest, logout, Gate Bind, regen y macros consultan la relación `IsInCombat`, nunca el string visual de
action/control state. Un CC puramente local que no proviene de una acción hostil no inventa engagement por sí solo.

Los effects de movimiento declaran semántica explícita: `Forward`, `Backward`, `TowardTarget` o `Speed`. Un dash/retreat/
charge no comparte una fórmula implícita con Sprint. Los desplazamientos hacen preflight server-side de source/target y
LOS antes de commit de resource/cooldown; `TowardTarget` no sobrepasa el target y conserva movimiento horizontal. `Speed`
es una aura/stat modifier con duración real y cleanup por expiración.

Cast pushback también es explícito: daño directo puede extender un `Cast` pendiente un número acotado de veces mediante
un timeline server-side; periodic damage no aplica pushback. NPC y player abilities de tipo `Channel` usan el mismo
contrato temporal (`ChannelDuration`/`ChannelTickInterval`): conservan presupuesto total mediante `TickScale`, revalidan
target/range/LOS por tick y comprometen resource/cooldown/GCD una sola vez al inicio. Movement cancel, hard CC, Interrupt,
death/evade o target inválido cancelan el pending channel. Un `ChannelTick` no hereda por defecto proc/multistrike/combo/
on-hit/pushback de `DirectDamage`; cada uno exige un trigger consumidor explícito antes de habilitarse.

---

# 81. AURAS

AuraSystem central.

Buff/debuff:

duration;

stack;

refresh;

periodic effects;

dispels;

immunities;

visual.

La política de stacking es explícita y data-driven. Mientras una definición no declare una política de stacks, reaplicar
el mismo AuraId refresca **una única instancia viva**; no se permite stacking implícito por duplicar filas. Stacks,
charges, periodicidad/tick rate y reglas de refresh especiales viven en definitions canónicas y no se dispersan en call
sites. Una aura con `AuraCharges` puede declarar `ImmunityTags`; cada CC compatible consume una carga antes de DR y la
última carga expira por el mismo pipeline canónico que limpia stats/UI. `BreakOnDamage` es metadata de aura, no un if por
ability: Fear/Disorient que lo declaran se eliminan al recibir daño efectivo. Charges/stacks visibles viajan por el mismo
wire de auras.

Las auras periódicas declaran además su política de fuente: `PeriodicSnapshot="Apply"` captura al aplicar/refrescar el
contexto ofensivo del source que el tick necesita; `Dynamic` permite consultar el source vivo cuando ese diseño sea
intencional. `BleedAura` es el primer consumer `Apply`: congela snapshot ofensivo/stat values y el multiplicador de threat
de la fuente, pero **no** congela el target. Health/alive state, defensas, resistance/mitigation, PvP/rules y demás estado
del objetivo se resuelven en cada tick. Reaplicar/refrescar sustituye el snapshot de fuente por el de esa nueva aplicación
de forma determinista. Persistencia/restauración de auras entre sesiones sigue siendo un contrato separado y no se infiere
de esta snapshot policy.

---

# 82. CROWD CONTROL

Categorías:

stun;

root;

slow;

silence;

disorient;

fear-like movement;

knockback;

pull.

PvP DR donde el diseño lo requiera.

Pull/knockback físico no es teleport. La definition declara modo y velocidad; el servidor resuelve dirección horizontal,
masa del assembly e impulso mediante un resolver común, aplica `BasePart:ApplyImpulse` y abre únicamente una ventana
acotada de movimiento externo en el anti-cheat. Boss immunity se evalúa antes del desplazamiento. Un displacement sin root
físico válido o con target inmune no inventa movimiento.

Reactive combat state también es autoridad server-side. Outcomes defensivos reales (`Dodge`, `Parry`, `Block`) pueden
abrir una ventana temporal; solo abilities que declaren el requirement correspondiente pueden consumirla. `Reckoning` es
el consumer vivo de `ReactiveDefense`; la ventana se consume una sola vez, expira por tiempo y se limpia con death/session
teardown. El cliente puede recibir tags de presentación, pero nunca crea la reacción.

Un efecto `Slow` vivo debe declarar su sink `MovementSpeed` y una magnitud canónica; un aura etiquetada `Slow` que no
modifique movilidad es contrato roto, no una implementación parcial aceptable. Resistencias/duración pasan por
`ControlDurationResolver`; los call sites no inventan porcentajes locales.

`Interrupt` es un efecto explícito y no un side effect implícito de cualquier CC. Slow no cancela casts. Hard-control
capaz de cortar casts declara esa semántica de forma explícita, y una ability interrupt solo aplica lockout si existía un
cast/channel activo. `InterruptResistance` reduce ese lockout por el mismo resolver de duración. El lockout se indexa por
la escuela realmente interrumpida (`Interrupt:<School>`): una escuela bloqueada no invalida otra, ni desactiva melee o
instant abilities no pertenecientes a ese cast school.

Diminishing returns es data-driven y opt-in por `DiminishingGroup`; no se infiere de cualquier tag `CC`. Los grupos PvP
vivos `Stun`, `Root`, `Fear`, `Disorient` y `Silence` tienen consumers reales y progresan 100% → 50% → 25% → immune, con
reset después de la ventana post-control definida en `GameConstants`. La aplicación PvE no consume DR PvP. Inmunidad
NPC/Boss es otra política distinta: un boss puede ser inmune a hard-control/Slow/Silence/Disorient y seguir siendo
vulnerable a un `Interrupt` explícito si tiene un cast pendiente. Nuevos grupos solo se añaden junto a definitions y tests
propietarios; no se crean grupos vacíos para aparentar cobertura.

---

# 83. THREAT

PvE/NPC:

threat;

taunt;

healing threat;

modifiers;

reset;

aggro selection.

No crear threat tables para targets Player: PvP no usa el selector de aggro PvE. La selección mantiene sticky aggro:
un challenger melee necesita superar aproximadamente el 110% del current target y uno ranged el 130%, salvo fixate/
taunt u otra regla explícita. Taunt iguala/supera de forma acotada el threat líder y aplica fixate temporal; no reescribe
permanentemente ownership del combate. Healing threat usa **healing efectivo**, no overheal bruto, y se reparte entre NPCs
realmente engaged. Ratios, factores y bonuses son configuración centralizada, no magic numbers locales.

Encounter aggro puede declarar asistencia social mediante `AssistRadius` por perfil. Una unidad que adquiere threat puede
compartir el target con aliados vivos del mismo kind/zona dentro del radio una sola vez por engagement. Los receptores se
marcan al recibir la llamada para impedir cadenas recursivas; cada uno conserva su propio prune/leash/evade y puede descartar
el target si no es válido. Boss/Dummy no heredan asistencia salvo definition explícita.

---

# 84. DEATH / RESURRECTION

Definir completamente:

death state;

corpse/respawn model;

graveyard/checkpoint;

instance respawn;

PvP respawn;

resurrection;

battle resurrection;

wipe handling.

ASTRAKYN posee el lifecycle gameplay de avatar: el servidor desactiva `Players.CharacterAutoLoads` y cualquier
materialización inicial, respawn o resurrection pasa por `Player:LoadCharacterAsync()`. `Player:LoadCharacter()` y los
respawns automáticos de plataforma no forman parte del contrato vivo porque podrían saltarse death state, release delay,
checkpoint, encounter cleanup o penalizaciones.

La materialización inicial depende explícitamente de que la sesión persistente esté cargada. Un `PlayerAdded` no puede
competir contra un `GetAsync` yielding y crear el avatar antes de que exista perfil: persistencia publica un evento
profile-ready y el bootstrap de sesión consume esa señal. Si una carga termina después de `PlayerRemoving`, no publica ni
retiene una sesión fantasma. Respawn y resurrection aparcan cualquier avatar recién materializado hasta completar
checkpoint/corpse placement, estado de muerte y world ownership; el avatar no puede quedar activo transitoriamente en el
spawn por defecto durante `LoadCharacterAsync()`.

`DeathService` es la única autoridad del registro de muerte. Captura antes del estado terminal, como mínimo, timestamp,
zona y transform de corpse cuando exista; la misma muerte aplica una sola vez sus side effects persistentes y retira al
jugador como fuente de threat. La primera transición publica un evento canónico que invalida autoattack, cast pendiente,
last-hit y proc clocks transitorios con independencia de la causa (combate, caída o hazards futuros); esas rutas no
mantienen clears paralelos. Release y resurrection consumen ese registro de forma mutuamente excluyente. Un intento de
resurrection reclama primero el corpse antes de cualquier operación yielding para impedir doble revive/cooldown race.

Release normal respeta un delay server-authoritative y vuelve al bind/checkpoint vigente. Resurrection normal requiere
party, misma zona, corpse válido y caster fuera de combate; battle resurrection puede operar durante combat únicamente
mediante una ability explícita y su cooldown/resource real. El cliente nunca aporta health fraction, corpse position,
release time ni autoridad de revive. Instance/PvP respawn, graveyards dedicados y wipe policy deben vivir sobre esta misma
autoridad, no crear puertas paralelas.

---

# 85. MACROS

Preservar el Macro Engine seguro.

Macro language es DSL.

No Luau.

No loops de automatización infinita.

No ejecución unattended.

No bypass:

GCD;

cooldowns;

target validation;

resources;

combat rules.

Cada macro action pasa por el mismo server authority que input normal.

`STARTATTACK`/`STOPATTACK` son comandos permitidos del DSL, pero `STARTATTACK` usa el target autoritativo ya resuelto y
pasa por `CombatService`; el macro no puede introducir target arbitrario, damage, swing timing ni otra autoridad.

---

# 86. NPC DEFINITIONS

Separar:

NPC identity;

visual;

rig;

AI;

combat;

dialogue;

quest;

vendor;

trainer;

profession;

faction;

spawn;

loot.

Un hostile spawn shippable declara explícitamente el perfil de combate, kit de abilities y ownership de loot que consume
en runtime; no existe un "Enemy genérico" como sustituto de identidad de contenido. Las abilities del kit usan el mismo
`AbilityCatalog` y cooldowns autoritativos que el resto del combate. Un POI de servicio (`Vendor`, `Trainer`, `Repair`,
`RestNode`, etc.) referencia una definition real del NPC correspondiente; un LinkId huérfano es error de catálogo.

---

# 87. NPC VISUALS

Eliminar `WorldFigures` como generador de cuerpos primitivos visibles.

Cada criatura productiva requiere:

real rig;

real mesh;

materials;

animations;

attachments;

hit/root configuration;

LOD policy.

---

# 88. AI

FSM/Behavior/Utility según necesidad.

Para navegación de agentes, preferir `PathfindingService:CreatePath()` + `Path:ComputeAsync()` y no introducir nuevas
dependencias en métodos de pathfinding deprecados. En mundos dinámicos/streaming, escuchar `Path.Blocked` y recomputar
cuando el bloqueo afecte al tramo futuro de la ruta; una ruta calculada no se considera garantía permanente.

Pathfinding hacia objetivos que pueden estar fuera del streaming del cliente se resuelve server-side, donde existe
visión completa del mundo. Cálculo cliente solo se usa para presentación/local behavior cuando todos los inputs
necesarios estén realmente cargados. La navegación nunca concede por sí sola autoridad sobre hit, reward, interaction o
posición válida.

El chase vivo mantiene home/leash separados de la posición móvil del agente, rate-limita recomputación y no bloquea el
tick mundial esperando `ComputeAsync()`: el path se calcula de forma asíncrona, `Path.Blocked` invalida solo tramos futuros
y la siguiente decisión recomputa. La simulación puede mover una representación provisional, pero damage, threat, target
eligibility y rewards continúan resolviéndose exclusivamente en sus servicios autoritativos.

Estados formales:

Idle

Wander

Patrol

Investigate

Alert

Engage

Chase

Combat

Cast

Reposition

Retreat

Evade

Return

Dead.

`Evade` no es una muerte ni concede reward: cuando un NPC pierde todos los targets válidos y supera su leash/timeout de
encounter, el servidor limpia threat/auras de encounter y restaura el estado autoritativo de home antes de volver a
`Idle`/`Return`. Durante `Evade`/`Return` el NPC no es un target válido de daño/autoattack y no puede generar reward; threat
nuevo se descarta y al llegar a home se ejecuta un segundo reset antes de reactivar combate. Un NPC no puede quedar
indefinidamente herido o enganchado a una referencia de threat inválida.

---

# 89. AI SIMULATION LOD

Near:

full decision cadence.

Mid:

reduced cadence.

Far:

sleep/despawn simulation representation.

No `O(players × all NPCs)` por frame.

---

# 90. QUEST ENGINE

QuestDefinition:

Id;

story;

requirements;

prerequisites;

objectives;

rewards;

zone;

chain;

repeatability;

sharing policy;

party credit;

flags.

---

# 91. QUEST TYPES

Implementar:

kill;

collect;

interact;

talk;

explore;

escort;

defend;

survive;

deliver;

gather;

craft;

ability;

boss;

dungeon;

raid;

PvP;

world-event;

composite.

---

# 92. QUEST SAFETY

Reward pipeline:

```text
VALIDATE COMPLETION
→ PREPARE REWARDS
→ DURABLY APPLY
→ MARK TURNED-IN
→ CONFIRM CLIENT
```

Nunca marcar TurnedIn y después descubrir que reward no pudo concederse.

---

# 93. STORY / DIALOGUE / CINEMATICS

StoryArc

QuestChain

DialogueGraph

CinematicDefinition

son sistemas separados pero conectados.

Cinematic debe recuperarse si:

player skips;

disconnect;

group diverges.

---

# 94. PARTY Y SOCIAL PLATFORM

`PartyService` de dominio es cross-server aware y soporta:

- invite;
- accept/decline;
- leader/promote/kick/leave/disband;
- ready checks;
- roles;
- markers;
- loot policy.

Kill credit/XP compartido de party se determina server-side con posiciones y zona autoritativas. Solo miembros elegibles
en la misma zona y dentro del reward range configurado reciben el share correspondiente; la fórmula/porcentaje pertenece
a configuración canónica del proyecto y no se duplica en quest, combat o UI.

Antes de recrear invitaciones, party discovery o continuidad de party de plataforma, usar/evaluar las capacidades
actuales del `SocialService` nativo (`Player.PartyId`, `GetPartyAsync()`, `GetPlayersByPartyId()`, game invites y demás
APIs vigentes) cuando encajen con el producto. Para prompts de invitación comprobar primero la elegibilidad/capability
nativa con manejo de fallo; cualquier `LaunchData`/join context procedente de una invitación es un hint no autoritativo
y se valida server-side. Si se ofrecen rewards por referral, evaluar el Friend Referral System nativo antes de inventar
atribución propia y aplicar awards one-time/idempotentes por invitee elegible, límites/cooldown razonables y detección
de patrones anómalos de referral.

La party nativa puede aportar identidad/continuidad social y contexto de join. La party MMORPG de ASTRAKYN sigue siendo
responsable únicamente de estado gameplay específico que Roblox no modele —roles, ready checks, raid subgroups, loot
policy, eligibility de actividades, markers y recovery de instancia— sin duplicar innecesariamente primitives nativas.

La lógica propia de roster/distancia/block state se llama `SocialDomainService` o equivalente, nunca `SocialService`,
para
no colisionar con el Service nativo.

Cualquier feature social que habilite comunicación usa además las APIs de compatibilidad/privacy de chat vigentes.

---

# 95. RAID GROUP

Subgroups;

leader;

assistants;

roles;

markers;

ready check;

pull timer;

instance eligibility.

No duplicar party fundamentals.

---

# 96. GROUP FINDER

Crear:

activity listings;

eligibility;

roles;

requirements;

applications;

leader approval;

matchmaking integration.

---

# 97. MATCHMAKING

Separar dos responsabilidades:

1. **Public server matchmaking**: usar/configurar las custom matchmaking configurations y señales nativas de Roblox para
   decidir a qué servidor público se asigna un join cuando ese mecanismo sea aplicable.
2. **Activity matchmaking** de ASTRAKYN: queues de dungeons/raids/PvP y allocation de reserved instances mediante
   `ActivityMatchmakingCoordinator`, con MemoryStore u otra primitive oficial apropiada.

No crear un módulo propio llamado `MatchmakingService`; Roblox expone un Service nativo con ese nombre.

Party enters/leaves como unidad cuando corresponda.

Match record:

- activity;
- difficulty;
- roles;
- players;
- queue timestamps;
- communication compatibility;
- instance allocation;
- version/lease metadata necesario para recovery.

Matchmaking no persiste progression/inventory/currency y debe recuperarse ante queue expiry, server loss y teleport
failure.

---

# 98. DUNGEONS

Cada dungeon productiva requiere:

entrance;

theme;

layout;

trash;

encounters;

bosses;

mechanics;

checkpoints;

quests;

rewards;

difficulty profile;

lockout policy;

art complete;

navigation validated.

---

# 99. RAIDS

Cada raid requiere:

wings;

boss roster;

trash;

encounter graph;

checkpoints;

difficulty;

lockout;

loot;

achievements;

cinematic/story hooks;

performance profile.

---

# 100. ENCOUNTER ENGINE

Encounter state:

```text
IDLE
ARMED
ACTIVE
PHASE_TRANSITION
VICTORY
WIPE
RESETTING
COMPLETE
```

No boss-specific server scripts duplicando framework.

---

# 101. BOSS MECHANICS

Framework soporta:

targeted mechanics;

role mechanics;

adds;

interrupts;

position;

spread;

stack;

soak;

movement;

hazards;

phase changes;

enrage;

arena changes.

Todo original.

---

# 102. INSTANCE LOCKOUT

Lockout server-authoritative.

Per-character o account scope explícito por content.

Reentrance no duplica rewards.

---

# 103. PVP

Mantener y profesionalizar:

duels;

world PvP;

battlegrounds;

arenas/structured PvP si definidos;

MMR;

season;

deserter;

rewards;

leaderboards.

---

# 104. PVP SECURITY

Rewards deben resistir:

AFK farming;

win trading;

repeat opponent abuse;

disconnect abuse;

duplicate completion.

---

# 105. FACTIONS / REPUTATION

FactionDefinition:

relationships;

territory;

NPC attitude;

services;

reputation;

rewards.

ReputationDefinition:

levels;

sources;

sinks;

unlockables;

vendors;

quests.

---

# 106. INVENTORY

Server authoritative.

Item instance posee unique instance ID.

Operations:

move;

split;

merge;

equip;

unequip;

consume;

bank;

trade;

mail;

auction.

No item puede pertenecer a dos owners simultáneamente.

---

# 107. ITEMIZATION

ItemDefinition:

template identity;

category;

quality;

requirements;

stats;

effects;

appearance;

stack;

binding;

sell value;

craft metadata.

Todo ItemDefinition shippable tiene al menos una fuente de adquisición autoritativa —loot, vendor, crafting, starting
loadout u otra fuente catalogada equivalente—. Un set debe poseer suficientes piezas físicas para activar su tier máximo;
un `TrinketEffectId` requiere item físico consumidor y toda gem catalogada requiere template físico y fuente de adquisición.
Catálogo sin acquisition/consumer se trata como contenido muerto, no como profundidad.

ItemInstance:

instance identity;

template;

rolled state;

durability;

enhancements;

binding;

owner state.

---

# 108. EQUIPMENT

Slots data-driven.

Equip actualiza:

stats;

appearance;

weapon animation set;

abilities/procs.

No client authority.

---

# 109. LOOT

Personal loot y/o group loot según content.

Eligibility registrada por Encounter.

En Need/Greed/Pass, la autoridad es server-side: `Need` solo es válido si el objeto es equipo utilizable por el personaje
según el contrato de slot/nivel vigente; `Need` tiene prioridad sobre `Greed`; timeout equivale a `Pass`; empate de roll
usa un desempate determinista; si todos pasan no existe ganador y nunca se reasigna silenciosamente al líder.

Loot transaction idempotente.

No conceder dos veces tras reconnect.

---

# 110. VENDORS

Vendor inventory server-driven.

Price resolver central.

Buyback durable dentro de la política definida.

No confiar en precio enviado por cliente.

---

# 111. ECONOMY

Crear economía documentada con:

sources;

sinks;

velocity;

wealth;

item scarcity;

currency caps cuando existan;

auction fees;

repair/crafting costs.

No añadir moneda sin propósito definido.

---

# 112. PROFESSIONS

Gathering;

crafting;

service professions.

ProfessionDefinition:

progression;

recipes;

tools;

stations;

resources;

specializations.

Toda profesión viva tiene un único ID canónico compartido por profile defaults/migration, crafting requirements,
resolución de stats, wire server→client y presentación. Una recipe no puede declarar una profesión inexistente. Añadir una
profesión solo al catálogo o solo al servidor es una implementación incompleta.

---

# 113. CRAFTING

RecipeDefinition:

inputs;

outputs;

profession;

requirements;

station;

quality rules;

cost.

Commit atómico dentro del perfil o durable transaction si toca documentos externos.

---

# 114. GATHERING

Nodes:

server authority;

resource type;

biome;

spawn rule;

respawn;

profession requirements;

loot.

No miles de Parts persistentes innecesariamente.

---

# 115. ACHIEVEMENTS

Event-driven.

Criteria catalogadas.

Account/character scope explícito.

Rewards idempotentes.

Distinguir achievements internos de las badges de plataforma. Si ASTRAKYN publica una achievement como badge de Roblox,
el grant se ejecuta server-side mediante `BadgeService:AwardBadgeAsync()` después de comprobar el badge con
`GetBadgeInfoAsync()`/`IsEnabled`, manejar fallos con `pcall` y mantener el flujo idempotente/reconciliable. La badge es
una surface de reconocimiento de plataforma, no la source-of-truth de progression ni motivo para revertir un reward
interno ya committed.

---

# 116. COLLECTIONS

Mounts;

companions;

cosmetics;

titles;

appearances;

special unlocks.

Ownership persistente.

---

# 117. MOUNTS

Real:

collection;

summon;

animation;

movement;

zone permissions;

dismount rules;

combat restrictions.

---

# 118. COMPANIONS

Separar:

cosmetic companion;

combat companion;

temporary summon.

No compartir accidentalmente AI/progression cuando sus requisitos son distintos.

---

# 119. APPEARANCE / TRANSMOG

Appearance collection separada de equipment power.

Equip gameplay item != visible appearance necesariamente.

Validar unlock.

---

# 120. SETTLEMENT / CONSTRUCTION

Eliminar nomenclatura `SettlementStub`.

Crear sistema productivo:

SettlementDefinition;

ownership;

claims;

permissions;

plots;

structures;

upgrades;

resources;

guild/player relationship;

persistence;

collision;

placement rules;

world limits;

performance budgets.

Protocol:

`SettlementSnapshot`

`SettlementDelta`.

---

# 121. CONSTRUCTION SECURITY

Cliente nunca envía una Instance.

Envía:

StructureDefinitionId

transform solicitado.

Servidor valida:

ownership;

permissions;

cost;

bounds;

slope;

collision;

zone;

quota;

spacing.

---

# 122. ENDGAME

La arquitectura final incluye:

max-level progression;

advanced dungeons;

raids;

world bosses;

PvP season;

reputation;

profession progression;

collections;

achievements;

world events;

challenge content;

guild objectives;

settlements.

---

# 123. LIVEOPS

LiveOps controla:

events;

rotations;

season;

reward schedules;

temporary vendors;

world event activation;

content availability;

announcements.

Todo cambio global:

versioned;

audited;

recoverable.

Cuando se necesite medir causalmente una variante, evaluar primero **Roblox Experiments** sobre Experience Configs o
matchmaking experiments según el caso antes de mantener bucketing/A-B infrastructure propia. Assignment y exposición no
eliminan los requisitos normales de server authority, policy, telemetría y rollback.

Si LiveOps adopta Experience Notifications, usar la surface nativa vigente, comprobar elegibilidad mediante
`CanPromptOptInAsync()` con manejo de fallo, tratar delivery como no garantizado y validar server-side cualquier launch
data antes de usarlo. Las notificaciones deben ser oportunas/relevantes y no convertirse en una dependencia durable de
gameplay.

Para eventos públicos programados, evaluar primero **Experience Events** nativos y las surfaces actuales de
`SocialService` (`GetUpcomingExperienceEventsAsync()`, `GetExperienceEventAsync()`, `GetEventRsvpStatusAsync()` y
`PromptRsvpToEventAsync()`) antes de duplicar discovery/RSVP. Sus llamadas async se protegen con `pcall`; RSVP y
metadata
de plataforma son engagement/presentation y no autoridad para rewards, acceso o progresión sin validación server-side.

---

# 124. WORLD HIERARCHY

```text
Universe
→ Continent
→ Region
→ Zone
→ Subzone
→ Location
→ POI
→ EncounterSpace
```

IDs estables.

---

# 125. WORLD STATIC CONTENT NO SE GENERA COMO BLOCKOUT EN RUNTIME

Eliminar el concepto actual de construir el aspecto final del continente con:

`WorldParts.block`

`WorldParts.ball`

`WorldParts.cylinder`

al iniciar cada servidor.

Static authored content debe estar:

baked;

validated;

production approved

antes de publicación.

Runtime genera únicamente estado dinámico necesario.

---

# 126. WORLDPARTS

`WorldParts` deja de ser una librería de presentación.

Puede sustituirse por:

`RuntimeVolumes`

para:

invisible trigger volumes;

collision helpers;

server regions;

interaction bounds.

Todo helper debe ser invisible/no decorativo.

---

# 127. MESHKITAPPLIER

Eliminar:

```text
mesh failure → WorldParts.block()
```

Comportamiento correcto:

```text
MISSING/FAILED PRODUCTION ASSET
→ ASSET ERROR
→ CONTENT INVALID
→ RELEASE BLOCKER
```

No degradación visual silenciosa.

---

# 128. WORLDKITS / WORLDINTERIORS

Reemplazar bloques visibles por:

validated mesh kits;

Terrain;

approved native Parts cuando sean deliberadamente arte final;

PBR;

material variants;

real props.

Un native Part puede ser arte final solamente si está marcado deliberadamente como tal en AssetManifest.

Nunca como fallback.

---

# 129. WORLD BUILDER

Separar:

`WorldAuthoringGenerator`

de

`WorldRuntimeService`.

AuthoringGenerator vive en tooling/Studio Plugin.

Genera y bakea contenido antes de publish.

WorldRuntimeService gestiona:

state;

events;

spawns;

interactions;

simulation.

No reconstruye ciudades enteras cada boot.

---

# 130. TERRAIN

Terrain productivo:

macro geography;

mountains;

passes;

valleys;

rivers;

lakes;

coasts;

cliffs;

plateaus;

caves.

Hydrology coherente.

No uniform noise.

No square-zone terrain.

---

# 131. BIOMES

BiomeDefinition:

terrain profile;

climate;

materials;

vegetation;

rocks;

props;

fauna;

resources;

enemies;

lighting;

weather;

audio;

architecture compatibility.

---

# 132. ECOTONES

Biome boundaries tienen transición natural salvo frontera intencional de lore/gameplay.

---

# 133. ZONES

Cada ZoneDefinition:

identity;

biome;

culture;

danger;

level;

factions;

quest arc;

NPC pools;

resources;

POIs;

dungeons;

events;

lighting;

weather;

audio;

landmark.

---

# 134. ZONE QUALITY GATE

Una zona no puede marcarse production-ready si falta:

Terrain final

Art final

Navigation

Landmark

POIs

Quest content

NPCs

Encounters

Audio

Lighting

Weather

Performance validation

Streaming validation.

---

# 135. CITIES

Diseñar:

district graph;

roads;

gates;

landmarks;

market;

guild services;

profession district;

residential;

military;

government;

culture;

transport;

defenses.

No scatter aleatorio de edificios.

---

# 136. ROADS

Graph entre destinos.

Cost functions:

terrain;

slope;

water;

obstacles;

settlements;

danger.

Presentación mediante Terrain/mesh/spline-authoring apropiado.

Nunca una fila de bloques como solución final.

---

# 137. POIs

Cada POI tiene:

purpose;

visual hook;

gameplay;

navigation role;

narrative role.

---

# 138. VEGETATION

Distribution:

biome;

altitude;

slope;

moisture;

water;

road exclusion;

settlement exclusion;

clustering;

seed.

No distribución uniforme.

---

# 139. WORLDGEN

Deterministic authoring pipeline:

```text
GlobalSeed
→ ContinentSeed
→ RegionSeed
→ ZoneSeed
→ SystemSeed
→ ObjectSeed
```

Cada generation record:

GeneratorVersion;

Seed;

ConfigHash.

---

# 140. WORLDGEN OVERRIDES

Authoring metadata:

Locked

ManualOverride

PreserveOnRegenerate

GeneratorExcluded.

Regeneration nunca destruye trabajo artístico aprobado sin consentimiento explícito.

---

# 141. BLENDER ES DCC PRINCIPAL

Blender es el DCC principal de ASTRAKYN para modelado, rigging, texturing/UV y preparación de animación cuando aplique.

Sources viven bajo:

`art/source/blender`.

Usar Git LFS para binarios pesados.

Configurar unidades, ejes, escala y export/import conforme a la guía vigente de Roblox para mantener consistencia
Blender
↔ Studio.

Preferir el **Roblox Blender plugin oficial** para transferencia directa Blender→Studio cuando cubra el flujo. Es
open-source y puede extenderse para necesidades ASTRAKYN en lugar de reconstruir desde cero la integración Open Cloud.

No depender de prompt queues o assets generados sin source/provenance como fuente final de producción.

---

# 142. BLENDER TOOLING DE ASTRAKYN

El tooling Blender de ASTRAKYN extiende/complementa el Roblox Blender plugin oficial; no duplica funcionalidad de
transfer/import ya resuelta por Roblox sin una razón medible.

Responsabilidades project-specific:

- asset metadata;
- naming validation;
- scale/orientation validation;
- collection conventions;
- origins/pivots/transforms;
- UV validation;
- material/PBR mapping;
- rig/skeleton validation;
- socket/attachment validation;
- collision meshes;
- LOD/SLIM preparation metadata cuando aplique;
- batch validation/export cuando aporte valor;
- manifest generation/provenance.

Si la extensión del plugin oficial no es viable, un add-on propio debe justificar la diferencia y mantener
compatibilidad
con los importers/APIs actuales de Roblox.

---

# 143. ASSET PIPELINE

```text
CONCEPT
→ ART DIRECTION
→ MODEL
→ UV
→ MATERIAL/PBR
→ RIG / AVATAR SETUP WHEN APPLICABLE
→ ANIMATE
→ COLLISION
→ OPTIMIZE
→ VALIDATE
→ TRANSFER / EXPORT
→ STUDIO IMPORTER OR OFFICIAL BLENDER PLUGIN
→ ROBLOX OWNERSHIP / PRIVACY VALIDATION
→ ASSET MANIFEST
→ WORLD INTEGRATION
→ PERFORMANCE VALIDATION
→ PRODUCTION APPROVED
```

Usar el Studio Importer para FBX/OBJ/glTF y sus warnings/errors; usar Asset Manager/Open Cloud asset APIs cuando el
flujo
de automatización lo justifique.

Para personajes/avatar-compatible assets, usar **Avatar Setup** cuando aporte rigging/caging/partitioning/attachments
compatibles con el pipeline objetivo.

No saltar moderación, ownership, privacy ni provenance checks porque el asset haya sido importado correctamente.

---

# 144. ASSET MANIFEST

Cada asset:

```text
ContentId
Category
SourcePath
SourceHash
ExportHash
RobloxAssetId
Owner
Version
Dependencies
Bounds
PivotPolicy
MaterialProfile
TextureProfile
CollisionProfile
RenderProfile
RigProfile?
AnimationProfile?
License
Provenance
Status
ValidatedAt
```

Status final:

`PRODUCTION_APPROVED`.

Nada visible puede depender de asset con otro status.

---

# 145. ASSET OWNERSHIP, PRIVACY Y THIRD-PARTY SAFETY

Verificar que assets productivos pertenecen a la experiencia/grupo/cuenta autorizada correcta y que sus permisos/privacy
permiten uso en todos los Places requeridos.

No depender de IDs externos no controlados.

No Creator Store/Free Models sin:

- provenance;
- license/usage rights;
- ownership/privacy review;
- script audit;
- asset audit.

Todo modelo de terceros se considera potencial vector de backdoor. Inspeccionar scripts y código ofuscado antes de
integrarlo.

Roblox identifica `Script Capabilities`/sandboxing como la defensa principal contra backdoors de modelos de terceros,
pero la feature continúa experimental/client beta. Si ASTRAKYN acepta excepcionalmente un asset de terceros con scripts
y el sandbox es compatible, aislarlo y conceder únicamente las capabilities imprescindibles. La beta no sustituye la
revisión manual, provenance ni mínimo privilegio; si resulta incompatible, no degradar silenciosamente a ejecución sin
auditoría. `Network`, `DataStore`, `AssetRequire`, `CapabilityControl` y `LoadString` son de alto riesgo y requieren
justificación explícita.

Assets restringidos requieren permisos de experiencia correctos antes del runtime. Tratar `Open Use` y los grants de
uso a experiencias como decisiones de gobernanza duraderas según las reglas vigentes de Roblox; no utilizarlos como ACL
temporal. Los loads dinámicos vía `AssetService` deben salir de manifests permitidos, manejar yield/fallo/moderación y
tener fallback técnico explícito sin convertir un asset productivo ausente en contenido visual aceptado.

Assets o source art generados/asistidos por IA conservan las mismas obligaciones de provenance, derechos de uso,
moderación y revisión que cualquier otra fuente; "generado" no equivale a "libre de derechos" ni elimina el asset
quality/safety gate.

---

# 146. TEXTURES Y PBR

Seguir especificaciones actuales de Roblox.

No imponer 4K.

No imponer 1024 universal.

Resolution profile se decide por:

- physical/screen size;
- visual importance;
- reuse/tileability;
- texture memory;
- device tier;
- streaming/performance evidence.

Para `SurfaceAppearance`, el pipeline soporta los mapas PBR actualmente admitidos por Roblox cuando el material los
necesite: color/albedo, normal, roughness, metalness y emissive mask.

Normal maps son tangent-space OpenGL según el formato actual esperado por Roblox.

Valores PBR representan propiedades físicas del material y se prueban en múltiples condiciones de iluminación; no bakear
lighting para arreglar una única escena.

---

# 147. RENDER FIDELITY

Eliminar `Precise` indiscriminado.

Política:

`Automatic` por defecto.

`Performance` para assets donde aporta ahorro sin degradación inaceptable.

`Precise` únicamente para asset específico con justificación visual y profiling.

---

# 148. COLLISION FIDELITY

Metadata por asset.

Preferir collision simple.

Precise collision únicamente cuando gameplay la necesita.

Decoración:

`CanCollide=false`

`CanTouch=false`

`CanQuery=false`

cuando no se usan.

---

# 149. LOD / SLIM / STREAMING ART

Evaluar capabilities actuales:

- Model LevelOfDetail;
- SLIM;
- avatar SLIM;
- instance/mesh streaming;
- automatic engine optimizations.

Aplicar según compatibilidad y medición.

Preferir mecanismos nativos como SLIM/streaming cuando reduzcan memoria/render cost sin romper silueta, collision o
interacción.

No construir manual LOD tiers porque sí ni asumir que mayor detalle geométrico es siempre mejor.

---

# 150. ART BIBLE

La Art Bible canónica forma parte de **esta `CONSTITUTION.md`** y de los manifests/Definitions ejecutables que
materialicen
sus reglas; no crear un quinto documento Markdown.

Debe mantener contratos claros para:

- shape language;
- materials/PBR;
- palette;
- lighting;
- architecture;
- vegetation;
- characters;
- creatures;
- weapons;
- VFX;
- UI/iconography;
- cultural profiles.

Los valores que el tooling pueda validar deben existir también como datos/manifests, evitando que una regla crítica viva
solo en prosa.

---

# 151. SCALE BIBLE

La Scale Bible canónica vive dentro de esta constitución y, para valores verificables, en Definitions/manifests
consumidos
por validators y tooling; no crear documentación paralela.

Definir valores/rangos canónicos para:

- character height;
- doors;
- stairs;
- floor heights;
- roads;
- bridges;
- props;
- trees;
- buildings;
- mounts.

Todo kit respeta escala y unidades Roblox/Blender acordadas.

---

# 152. ICONS

Revisar visualmente los atlas existentes.

El tooling de atlas no puede generar "pipeline placeholders" que terminen en producción.

Cada icono final debe:

tener identidad;

ser legible;

usar estilo coherente;

funcionar a tamaños pequeños;

tener source/provenance.

---

# 153. RIGS Y AVATAR SETUP

Rig families ASTRAKYN:

Humanoid

LargeHumanoid

Quadruped

Flying

Serpentine

Boss

Special.

Cada family tiene skeleton contract.

Para humanoids/avatars compatibles con el estándar Roblox, preferir R15/Avatar Setup y tooling oficial para rigging,
caging, partitioning y attachments cuando encaje con el diseño.

Rigs custom mantienen requirements explícitos de Humanoid/AnimationController, attachments, root, collision, scaling y
animation ownership.

`Character Controller Library` es una capability opcional de Avatar Settings, no una migración automática. Evaluarla
cuando su status vigente y su soporte de abilities/controladores cubran la locomoción real de ASTRAKYN; no reemplazar
Humanoid/locomotion estable solo por novedad ni depender de una capability beta sin pruebas publicadas.

---

# 154. ANIMATION

Mantener arquitectura de animación central y data-driven.

Estados conceptuales:

- locomotion;
- combat;
- cast/channel;
- hit react/CC;
- death;
- mount;
- special.

Usar Animation Editor para clips y evaluar **Animation Graph Editor** para blend trees/state logic compleja cuando
reduzca
scripting manual y mejore colaboración.

Usar animation markers (`GetMarkerReachedSignal`) para cues/presentation; gameplay-critical timing y resultados siguen
en
servidor.

Si se adopta Engine Server Authority, seguir el replication/prediction model vigente de Animation Graph/Animator y no
inventar transporte paralelo de estado que el engine ya replica. Cuando una lógica de animación deba participar en la
simulación fija/rollback, evaluar `RunService:BindToAnimation()`/la surface sincronizada vigente y respetar las mismas
restricciones de Simulation Access/resimulation; no almacenar `AnimationTrack` como si permaneciera válido a través de
un rollback si la guía vigente indica lo contrario.

`Animator` es la surface canónica de playback/replicación. No crear código nuevo con los métodos deprecados
`Humanoid:LoadAnimation()` o `AnimationController:LoadAnimation()`; cargar con `Animator:LoadAnimation()`. El `Animator`
debe existir bajo `Workspace` antes de cargar clips y, cuando el track deba replicarse entre peers, debe haberse creado
en servidor. Las animaciones de un player character pueden iniciarse en el cliente propietario según el modelo oficial;
para NPCs u otros rigs, cargar/iniciar en servidor cuando el resultado deba replicar.

Para crowds grandes de NPCs, una animación puramente de presentación que no necesite replicación compartida puede
reproducirse localmente en cada cliente —por ejemplo con `Animator`/`AnimationController` client-side y solo para NPCs
relevantes/cercanos— para reducir CPU y tráfico del servidor. El servidor conserva el estado/timing lógico necesario y
ningún resultado de gameplay depende de que un track visual client-side haya terminado o alcanzado un marker.

Mantener el animation LOD/throttling del cliente disponible por defecto para rigs remotamente simulados; no poner
`Animator.PreferLodEnabled = false` de forma masiva ni deshabilitar `Workspace.ClientAnimatorThrottling` sin profiling.
Si se superponen offsets procedurales a `Motor6D.Transform`, comprobar `Animator.EvaluationThrottled` según la
referencia
vigente para no aplicar offsets contra una pose stale durante frames donde el engine omitió evaluación.

`LoadAnimation()` crea un `AnimationTrack` nuevo cada vez. No usarlo como lookup de un track ya cargado; conservar la
referencia o usar `Animator:GetTrackByAnimationId()` cuando corresponda para evitar churn innecesario.

---

# 155. VFX

VFXDefinition:

effect;

attachments;

duration;

quality tier;

replication policy;

pool policy;

budget class.

No replicar partículas individuales desde servidor.

---

# 156. LIGHTING

LightingProfile por:

continent;

zone;

interior;

dungeon;

weather;

cinematic.

Transiciones controladas.

---

# 157. WEATHER

Weather es visual + gameplay cuando corresponda.

No crear millones de partículas globales.

Local presentation alrededor del jugador cuando sea posible.

---

# 158. AUDIO

Arquitectura de producto:

- MusicDirector;
- AmbientDirector;
- CombatAudio;
- AbilityAudio;
- CreatureAudio;
- EnvironmentAudio;
- UIAudio.

Para nueva implementación, preferir el **modern audio graph** de Roblox (`AudioPlayer`, `AudioEmitter`, `AudioListener`,
`AudioDeviceOutput` y `Wire`, más efectos modernos) cuando cubra el caso de uso.

`Sound`, `SoundGroup` y legacy SoundEffects pueden mantenerse durante una migración existente, pero no son el target por
defecto para sistemas nuevos cuando Roblox recomienda los objetos Audio modernos.

Audio zones, spatialization y state transitions deben ser client-efficient, compatibles con streaming y con assets cuyo
uso/licencia esté autorizado.

---

# 159. UI DESIGN SYSTEM

Un único design system.

Definir:

- typography;
- spacing/layout;
- components;
- colors/tokens/themes;
- focus/navigation;
- interaction states;
- tooltips/dialogs/lists/tabs;
- drag/drop;
- accessibility variants.

Usar las capacidades modernas de **UI styling** (`StyleSheet`, `StyleRule`, `StyleLink`, tokens/themes/queries y Style
Editor) cuando aporten una fuente central de estilos más mantenible que property writes dispersos.

No cada pantalla con estilo propio ni duplicación de tokens entre Lua modules, Attributes y StyleSheets.

Style queries/adaptive layout pueden responder a tamaño, input y preferencias de accesibilidad; mantener una única
source
of truth de design tokens. Cuando se use el styling nativo, preferir las queries intrínsecas de Roblox para estados
globales (`@ViewportDisplaySizeSmall/Medium/Large`, `@PreferredInputKeyboardAndMouse`, `@PreferredInputTouch`,
`@PreferredInputGamepad`, `@ReducedMotionEnabledTrue/False`) en vez de duplicar esa detección con breakpoints/tokens
manuales.

---

# 160. MMORPG HUD

Player frame;

target;

target-of-target cuando corresponda;

party;

raid;

resources;

abilities;

action bars;

cast;

buffs;

debuffs;

minimap;

quest tracker;

notifications.

---

# 161. INPUT

Gameplay actions abstraídas de hardware.

Target principal para nueva implementación: **Input Action System** (`InputAction`, contexts/bindings) cuando la versión
vigente de Roblox lo soporte para el target.

Soportar:

- keyboard/mouse;
- gamepad;
- touch;
- cambio de dispositivo durante sesión.

No lógica de gameplay atada directamente a `KeyCode`.

La UI muestra bindings efectivos/preferred binding del dispositivo actual y reacciona a cambios de `PreferredInput`
sin fijar la experiencia a la plataforma detectada al inicio. Para acciones cross-platform, cada `InputAction` debe
tener
los bindings de keyboard/mouse, gamepad y touch que realmente apliquen; usar `PreferredBinding`/`InputActionLabel` según
su status vigente para hints cuando resulte adecuado.

Al adoptar Input Action System, configurar `Workspace.PlayerScriptsUseInputActionSystem = Enabled` como recomienda la
guía vigente y definir al menos un `InputContext` primario. Para targeting/pointer gameplay nuevo, preferir acciones de
tipo `ViewportPosition` + raycast/camera semantics cuando cubran el caso, en vez de construir otra dependencia directa
sobre `Player:GetMouse()`. `UserInputService` sigue siendo válido para input de bajo nivel o UI cuando aporte valor; no
tratarlo como deprecado. Si se adopta Server Authority, el input que afecte a la simulación core debe entrar por
`InputAction`, no por `UserInputService.InputBegan`.

`ContextActionService` puede mantenerse donde sea necesario durante migración, pero no crear nueva arquitectura
alrededor
de métodos deprecados si Input Action System cubre el caso.

---

# 162. MOBILE Y CROSS-PLATFORM

Diseño adaptativo real.

No reducir UI desktop a escala.

Mantener:

- touch targets adecuados;
- responsive/adaptive layouts;
- safe areas;
- notch/topbar handling;
- input switching;
- performance/memory budgets de mobile;
- orientación soportada explícitamente.

Adaptar layouts por capacidades reales, no por etiquetas rígidas de dispositivo. Usar `GuiService.ViewportDisplaySize`
como señal categórica Small/Medium/Large cuando sirva para composición y `PreferredInput` para el modo de interacción
actual; evitar inferir UX únicamente desde píxeles, `TouchEnabled` o una plataforma nominal. Pantallas grandes/4K deben
escalar y también adaptar densidad/composición cuando corresponda, no limitarse a agrandar la UI.

Para UI interactiva, partir de `ScreenGui.ScreenInsets = CoreUISafeInsets` o la recomendación vigente equivalente, y
usar `GuiService:GetInsetArea()`/safe-area APIs cuando el layout lo requiera.

No asumir que Device Emulator reproduce memoria, thermal throttling, red real o input latency de hardware físico.

---

# 163. ACCESSIBILITY

Production requirements:

- UI scale/adaptive layout;
- text scale;
- contrast;
- color independence;
- reduced motion;
- transparency preference;
- flash safety;
- multiple cue channels;
- keyboard/gamepad/touch navigation;
- remapping donde corresponda.

La UI debe reaccionar a las preferencias nativas disponibles en `GuiService`, incluyendo `PreferredTextSize`,
`PreferredTransparency` y `ReducedMotionEnabled`, en lugar de mantener únicamente toggles propios desconectados del
usuario. Para fondos adaptables, partir del patrón oficial que combina la transparencia base con
`PreferredTransparency`; reducir/desactivar animación no esencial cuando `ReducedMotionEnabled` esté activo.

`TextScaled` no sustituye soporte de `PreferredTextSize`: actualmente impide que ese ajuste escale automáticamente el
texto. Preferir layouts que toleren crecimiento (`AutomaticSize`, wrapping y constraints razonables) y probar Medium,
Large, Larger y Largest sin clipping, pérdida de controles ni scroll traps.

No comunicar información crítica solo mediante color, sonido, vibración o movimiento.

---

# 164. MAP

World map:

continents;

zones;

POIs;

quests;

party;

transports;

instances;

discovery.

Minimap:

orientation;

services;

party;

objectives;

tracking.

---

# 165. TRAVEL

Walking

Mounts

Routes

Portals

Ships/transport

Fast travel

Cross-continent travel.

Server valida destinos.

---

# 166. PERFORMANCE — PRINCIPIO

Performance es una feature y se diseña desde arquitectura/contenido, no al final.

Optimizar contra el bottleneck medido: CPU script/physics, render/GPU, memory, network, streaming, asset load o platform
service budgets.

No declarar una zona terminada visualmente sin validar rendimiento y memoria en escenarios representativos.

El presupuesto de red forma parte del diseño: no replicar snapshots completos ni estado cada frame si basta un delta/
evento; throttlear inputs/remotes; evitar jerarquías complejas creadas/destruidas repetidamente desde servidor; limpiar
metadata de animación innecesaria; crear VFX puramente visuales y tweens en cliente cuando el servidor solo necesite
replicar el resultado lógico. Medir tráfico con las vistas/scopes de red de MicroProfiler cuando corresponda.

Optimización sin profiler/evidencia no se considera completada.

El lifecycle también es un budget: desconectar `RBXScriptConnection` y liberar referencias/instancias cuando dejan de
ser necesarias, especialmente al retirar jugadores, personajes, NPCs y UI. Aprovechar el comportamiento nativo de
destrucción de personajes cuando corresponda, pero no depender de GC eventual para recursos con teardown explícito.
Como baseline de lifecycle, habilitar
`Workspace.PlayerCharacterDestroyBehavior = Enum.PlayerCharacterDestroyBehavior.Enabled` (o el estado recomendado
equivalente vigente) para que el Engine destruya characters reemplazados y el `Player` al salir, salvo que exista un
cleanup manual equivalente, documentado y probado. Al ser no scriptable, verificarlo en el DataModel publicado.

El preload también es un budget. `ContentProvider:PreloadAsync()` se reserva para assets realmente necesarios al
arranque o a una transición crítica (loading UI, menú inicial, spawn/entrada inmediata); no precargar todo `Workspace`
ni colecciones masivas "por seguridad". No usar `ContentProvider.RequestQueueSize` como condición fiable de completitud
o barra de progreso. Si una carga grande es inevitable, ofrecer skip/timeout/degradación razonable y manejar el status
de assets en vez de bloquear indefinidamente. Evitar cargar todo el catálogo de audio/assets en el cliente cuando basta
la porción próxima.

Si ASTRAKYN personaliza la pantalla de conexión inicial, implementarla desde `ReplicatedFirst`, mantener allí lo
esencial para ese primer frame y no retirar la loading screen nativa sin una sustitución visible. Un overlay posterior
en `PlayerGui` no equivale a una custom initial loading screen ni demuestra preload.

---

# 167. STREAMING

World Places deben ser streaming-safe.

Cliente nunca presupone que toda instancia distante está cargada. El orden de replicación tampoco se presupone: usar
`WaitForChild()` o signals/contracts acotados cuando una dependencia replicada deba existir, pero no bloquear
indefinidamente esperando contenido de mundo que puede estar fuera del streaming radius.

Eliminar lógica que dependa de:

`workspace:FindFirstChild()` de un objeto lejano

como verdad global.

Usar logical IDs/state y signals de disponibilidad.

Para large worlds, partir de las recomendaciones actuales de Roblox salvo evidencia contraria:

- `StreamingEnabled = true`;
- `ModelStreamingBehavior = Improved`;
- `StreamingIntegrityMode = PauseOutsideLoadedArea`;
- `StreamOutBehavior = Opportunistic`;
- `EnableSLIMAvatars = Enabled` para R15 cuando sea apropiado y compatible;
- `PredictiveStreamingMode = Enabled` cuando traversal/respawn/cambios grandes de foco se beneficien y las pruebas lo
  validen;
- SLIM/Model LOD donde corresponda.

Estas properties de `Workspace` no son scriptables; deben configurarse en Studio/place/project source-of-truth y
validarse sobre el DataModel generado/publicado. Predictive streaming es aditivo y no sustituye contracts streaming-safe
ni replication focuses explícitos cuando sean necesarios.

Seleccionar `Model.ModelStreamingMode` por semántica, no por conveniencia: `Atomic` cuando el cliente necesita recibir
el modelo inicial como unidad (sin asumir atomicidad para descendants añadidos después), `Persistent` solo para modelos
raros que deban permanecer cargados y cuyo coste esté justificado, y `PersistentPerPlayer` para persistencia dirigida
mediante `Model:AddPersistentPlayer()`/`Model:RemovePersistentPlayer()`. Para `Persistent`, coordinar con
`Workspace.PersistentLoaded` cuando un flujo realmente dependa de que el set persistente inicial esté disponible.
Persistencia de instancia no garantiza por sí sola simulación física cliente en una región fuera del streaming focus.

Para destinos anticipados usar `Player:RequestStreamAroundAsync()` cuando proceda; añadir
`Player:AddReplicationFocus()` solo cuando se necesite un foco sostenido adicional y retirarlo al terminar. Cada foco
extra aumenta trabajo de streaming del servidor y presión de memoria del cliente, por lo que no se usa como parche
general.

`Workspace:ApplyRecommendedStreamingSettings()` es una herramienta Plugin-Security para auditoría/authoring en Studio:
puede ejecutarse sobre una copia generada/controlada para detectar drift respecto a las recomendaciones actuales de
Roblox y revisar el diff resultante. No es API runtime ni permiso para mutar ciegamente el source-of-truth/productivo.

Cualquier cambio de estos defaults/recommendations requiere profiling y playtest de traversal, combat, teleport y
recovery.

---

# 168. STREAMING RADII

Roblox recomienda actualmente como baseline:

- `StreamingMinRadius = 64`;
- `StreamingTargetRadius = 1024`.

ASTRAKYN comienza desde esos valores para nuevas pruebas y solo se desvía mediante profiling real de memoria,
visibility,
join/travel, streaming pauses y device class.

Los valores heredados no son sagrados.

Documentar en `ESTADO_ACTUAL.md` la evidencia que justifica cualquier valor productivo distinto.

No usar un TargetRadius artificialmente bajo solo para reducir memoria si produce pop-in, gameplay incompleto o pausas;
no
usar uno alto si rompe mobile memory budgets.

---

# 169. PERFORMANCE BUDGETS

`PerformanceBudgets.luau` contiene únicamente budgets medidos o contractualmente definidos.

Cada budget documentado con:

metric;

scenario;

device class;

measurement;

threshold;

reason.

No números decorativos.

---

# 170. TEST DEVICE MATRIX

Validar en hardware físico representativo:

- low-end mobile baseline;
- mid mobile;
- tablet;
- mid desktop;
- high desktop;
- gamepad/console target cuando esté soportado.

Device Simulator + Controller Emulator son útiles para layout, safe areas y controls, pero no demuestran memory
pressure, thermal throttling, real GPU/CPU ni input latency de hardware físico.

Usar Network Simulator para reproducir latency, jitter y packet loss en playtests de Studio, especialmente sobre
server-confirmed actions, streaming, prediction/correction y `UnreliableRemoteEvent`; mientras sea beta, es evidencia
complementaria y no reemplaza red/hardware real.

Para pruebas programáticas de Studio, preferir `StudioTestService` para simulación multi-client,
`StudioDeviceSimulatorService` para perfiles de dispositivo y `UserInputService:CreateVirtualInput()` para input
sintético cuando encajen. Son surfaces Studio-only y no se convierten en dependencias del runtime publicado.

Incluir sesiones mobile prolongadas para detectar thermal/memory degradation y pruebas bajo red real/simulada relevante.

Registrar modelo/device class, build, escenario y evidencia; no afirmar FPS/memory targets desde Studio únicamente.

---

# 171. FRAME LOOPS Y SCHEDULER

Revisar todo trabajo en:

- `PreRender` / render callbacks;
- `PreAnimation`;
- `PreSimulation`;
- `PostSimulation`;
- `Heartbeat`;
- cualquier legacy `RenderStepped`/`Stepped` todavía existente.

Para código nuevo usar `PreRender` en lugar del superseded `RenderStepped` y `PreSimulation` en lugar del superseded
`Stepped`; migrar usos existentes cuando conserve la semántica y aporte claridad/performance, sin etiquetarlos
falsamente como APIs eliminadas.

Usar `BindToRenderStep` únicamente cuando el orden relativo a cámara/input/render sea necesario.

Mover trabajo a eventos o menor frecuencia cuando sea posible.

No asumir orden entre property replication y remote events bajo Next Generation Replication.

Handlers deben ser seguros bajo deferred signals y no depender de callbacks immediate/reentrant por accidente.

---

# 172. PARALLEL LUAU Y NATIVE CODE

Usar Actors/Parallel Luau solo para workloads:

- independientes o particionables;
- CPU-bound;
- thread-safe;
- medidos.

Requerir módulos/dependencias según las restricciones vigentes antes de entrar en contextos paralelos cuando aplique.

No migración indiscriminada.

Native code generation se aplica únicamente a funciones/scripts computacionalmente costosos identificados por profiling;
priorizar tipos precisos y comparar before/after. No marcar todo el proyecto como native.

---

# 173. MEMORY

Long-session test.

Detectar:

connection leaks;

task leaks;

unbounded caches;

instance leaks;

asset retention;

table growth.

---

# 174. MICROPROFILER Y PROFILING

Profiling client y server por separado.

Usar MicroProfiler, Script Profiler/Stats/Scene Analysis y Performance Dashboard según el bottleneck.

Perfilar en hardware físico, especialmente mobile; un desktop potente puede ocultar problemas térmicos/memoria/frame
time.

Guardar evidencia en `ESTADO_ACTUAL.md` o artifacts de CI/performance, no en documentos paralelos.

No afirmar mejora sin comparación before/after y escenario reproducible.

---

# 175. SECURITY RESPONSE

No utilizar únicamente un contador de sospecha + kick.

Crear reason codes y telemetría server-side.

Responses progresivas y proporcionales:

- ignore invalid request;
- rate-limit;
- reject/rollback intent;
- temporarily restrict;
- security event;
- kick;
- Ban API / staff review.

Preferir mitigaciones que reduzcan daño y falsos positivos. Heurísticas aisladas son señales, no prueba concluyente;
correlacionar múltiples señales antes de aplicar consecuencias severas.

Honeypot remotes y detección de uso en dirección imposible pueden emplearse como señal server-side de alta
confianza solo cuando ningún cliente legítimo pueda activarlos. Su función es detectar/registrar y contener la
sesión; no sustituyen validación, rate limiting ni diseño seguro y no justifican una sanción durable automática
sin la policy/evidencia
correspondiente.

Consecuencias irreversibles requieren evidencia de mayor confianza.

Threat-model cada feature considerando cliente completamente controlado, spam extremo, resource exhaustion y griefing.

---

# 176. ROBLOX BAN API

`PlayerModerationService` envuelve la Ban API oficial vigente de `Players`.

Usar `Players:BanAsync()`, `Players:UnbanAsync()` y `Players:GetBanHistoryAsync()` según la operación.

`Players.BanningEnabled` debe estar habilitado/configurado correctamente en los Places productivos.

Universe/place scope, duration, alt-account enforcement y device block se seleccionan explícitamente por policy/risk.

Mantener rules page y appeal path documentados/visibles conforme a las usage guidelines actuales.

No implementar device fingerprinting propio ni una segunda blacklist de cliente como autoridad de ban.

---

# 177. LIVEOPS / STAFF NO SON DEBUG

Staff Console existe siempre como feature productiva RBAC.

No hay:

debug console pública;

cheat UI;

secret keybind;

admin by username.

---

# 178. ROBLOX STUDIO PRODUCTION PLUGIN

Crear plugin:

`ASTRAKYN Production Suite`.

Módulos:

Project Audit

Content Validation

World

Zones

Biomes

Terrain

Hydrology

Roads

Cities

POIs

Vegetation

Assets

NPCs

Quests

Encounters

Dungeons

Raids

Items

Loot

Professions

VFX

Lighting

Audio

Build

Migration

Performance Report.

Integrarse con herramientas nativas actuales de Studio en lugar de duplicarlas sin necesidad: Importer, Asset Manager,
Style Editor, Animation/Animation Graph tooling, Avatar Setup y ChangeHistoryService.

Para widgets nuevos usar la API vigente de Plugin, incluyendo `CreateDockWidgetPluginGuiAsync()` en lugar de introducir
nuevos usos de `CreateDockWidgetPluginGui()` deprecated.

Las operaciones que modifiquen DataModel siguen el modelo transaccional/undo actual de `ChangeHistoryService`.

---

# 179. PLUGIN UNDO

Todas las operaciones editoriales mutativas importantes utilizan el workflow actual de ChangeHistoryService.

Transaction editorial:

```text
VALIDATE INPUT
→ TryBeginRecording()
→ APPLY
→ VALIDATE OUTPUT
→ FinishRecording(..., Commit)
```

Si `TryBeginRecording()` no devuelve identifier, no mutar el DataModel.

En fallo después de iniciar recording, finalizar con la operación de cancelación vigente cuando sea posible. No dejar
recordings abiertas; si el plugin puede recargarse durante una operación, conservar el identifier necesario para poder
cancelar/recuperar el recording según la guía oficial actual.

---

# 180. DRY-RUN DE OPERACIONES MASIVAS

Antes de:

regenerate zone;

replace assets;

delete generated layer;

mass migration;

mostrar:

creates;

updates;

deletes;

preserved overrides;

warnings;

errors.

---

# 181. VALIDATORS

Un framework común:

PASS

WARNING

ERROR

BLOCKER.

BLOCKER impide release.

---

# 182. ASSET VALIDATOR

Comprueba:

missing asset;

owner;

source;

hash;

mesh;

texture;

PBR;

pivot;

scale;

collision;

rig;

status.

---

# 183. WORLD VALIDATOR

Comprueba:

terrain seams;

floating structures;

buried assets;

invalid roads;

blocked entrances;

spawn safety;

POI validity;

streaming dependencies;

missing production assets.

---

# 184. QUEST VALIDATOR

Broken prerequisites;

cycles invalid;

missing NPC;

missing objective;

invalid reward;

unreachable zone;

bad chain.

---

# 185. ECONOMY VALIDATOR

Negative/NaN/infinite values;

unknown currency;

free crafting loops;

invalid vendor;

broken auction rules;

duplicate reward;

unbounded source.

---

# 186. NETWORK VALIDATOR

Unknown remotes;

payload without schema;

missing rate policy;

client authority;

unused remotes;

oversized snapshots.

---

# 187. RBAC VALIDATOR

Every StaffAction has:

permission;

risk;

payload schema;

audit policy;

handler.

Every role references valid permissions.

No permission orphan.

No player-facing endpoint accidentally requests staff capability.

---

# 188. BUILD VALIDATOR

Production artifact must prove absence of:

`Tests` folder under TestService;

`DeployEnvironmentResolver`;

`EnvironmentConfig`;

`ConfigAdminRules`;

environment-selected artifact/config references;

placeholder IDs;

visible blockout markers;

generic AdminCommand;

generic AdminSetFlag.

---

# 189. TEST OVERLAY EFÍMERO

No existe `test.project.json` versionado. `tools/test/project.luau` genera `.astrakyn-test.project.json` temporalmente en la raíz del workspace a partir del `default.project.json` productivo, conserva exactamente sus `$path` y añade únicamente `TestService.Tests` desde `tests/`. `tools/test/sourcemap.luau` usa ese overlay para regenerar el único `sourcemap.json` del editor/gate y elimina el overlay inmediatamente. El overlay nunca se publica ni se mantiene como configuración paralela.

El overlay no puede redefinir configuración runtime, assets, servicios productivos ni mappings existentes. Su única responsabilidad es hacer visible la suite al typechecker/runner cuando una prueba necesita relaciones de DataModel.

---

# 190. TEST PYRAMID

Unit tests:

pure resolvers.

Integration:

domain services.

Contract:

architecture/security invariants.

Persistence:

leases/migrations/retries.

Transaction:

partial failures/recovery.

Cross-server:

coordination semantics.

Runtime:

`StudioTestService`/Studio harness cuando la prueba necesite simulación programática multi-client, manteniendo
`TestService` como contenedor/harness donde corresponda al proyecto.

Performance:

representative playtests + Device/Controller/Network Simulator como evidencia complementaria, nunca sustituto de
hardware/red real.

---

# 191. FAILURE INJECTION

Simular:

DataStore timeout;

unknown write outcome;

MemoryStore failure;

Messaging loss;

Teleport failure;

disconnect;

server shutdown;

duplicate request;

out-of-order retry;

partial transaction.

---

# 192. TRANSACTION TESTING

Para cada multi-document transaction probar:

failure before reservation;

after first reservation;

after second reservation;

during commit;

duplicate commit;

reconnect;

different server ownership;

reconciler replay.

---

# 193. MIGRATION TESTING

Mantener fixtures de schemas reales soportados.

Cada migration:

old fixture

→ migrate

→ validate exact expected current shape.

No synthetic empty-only tests.

---

# 194. RELEASE QUALITY GATE

Ejecutar como mínimo:

- toolchain/version/deprecation check;
- Luau source-policy validation (`--!strict`, cero `any` explícito y cero suppressions);
- Lune/Luau syntax validation de `src/`, `tests/` y `tools/`;
- schema validation;
- Selene;
- StyLua check;
- Luau-LSP strict typecheck de `src/`, `tests/` y `tools/`;
- Luau tests;
- security/network/RBAC validators;
- content/economy/quest validators;
- asset/world validators;
- transaction/recovery/migration tests;
- production artifact validation;
- current Roblox API compatibility audit;
- Workspace/platform configuration audit;
- Studio scripted/device/network test pass cuando aplique;
- Creator Dashboard Error Report/crash/DataStore/MemoryStore observability review y alerts aplicables;
- discovery metadata/icon/thumbnail accuracy review para releases públicos;
- audience/reach publishing requirements review, incluyendo Roblox Kids/Select cuando formen parte del target;
- chat/privacy/policy compliance audit;
- monetization/PolicyService audit cuando aplique;
- Content Maturity & Compliance review: toda experiencia pública mantiene el questionnaire completo y exacto, y se
  vuelve a enviar cuando un cambio de contenido altere cualquiera de sus respuestas;
- Regional Content Availability/reach review cuando cambien contenido, políticas o restricciones regionales relevantes;
- published teleport/reserved-server validation cuando aplique;
- real-device performance/memory test matrix;
- manual/runtime profiling correspondiente.

Cualquier required gate rojo:

NO RELEASE.

Un gate no ejecutable se marca `BLOCKED` con razón/evidencia faltante; nunca se convierte en PASS por ausencia de
herramienta.

---

# 195. CI / RELEASE AUTOMATION

`.github/workflows/quality.yml` ejecuta la misma entrada canónica `lune run tools/schema/check.luau` en pull request y rama principal; no mantiene una suite CI paralela. El gate de calidad valida que el manifest de atlas sea estructuralmente correcto y que cualquier ID presente sea un `rbxassetid://` válido, pero permite el string vacío para arte todavía no publicado; nunca permite IDs placeholder inventados.

`release-validation.yml` ejecuta `lune run tools/build/build_place.luau --release --manifest`. `--release` implica la verificación normal y añade exclusivamente los checks de readiness de publicación; genera el manifest y valida el artefacto productivo. `--verify` por sí solo ejecuta quality y puede pasar mientras un asset todavía no esté publicado. En release los IDs de atlas vacíos son fallo y bloquean publicación.

CI puede usar Open Cloud únicamente con API keys/OAuth scopes mínimos almacenados en un secret manager apropiado; nunca
commitir credentials ni usar cookie-auth legacy como base productiva.

CI NO publica automáticamente live salvo que exista un proceso explícito, seguro, revisado, con approvals y rollback.

Pruebas que requieren Studio/publicación/teleport/hardware real se registran como gates externos con evidencia
enlazable;
no se falsifican dentro de un runner headless.

---

# 196. BUILD TOOL

Eliminar del builder canónico:

environment-selected artifact variant;

stub floors;

baseplate de presentación;

test markers;

invented world geometry.

No mantener un custom XML emitter que simula el mundo final mediante Parts.

Build tooling debe ensamblar código/config/assets reales y verificar, no inventar contenido.

`tools/build/build_place.luau` es una capa fina de orquestación Lune sobre Rojo; no reimplementa serialización RBXLX, no
inyecta geometría y escribe artefactos reproducibles únicamente bajo `.build/`. Tras el build, usa `@lune/roblox.deserializePlace` para inspeccionar el `DataModel` real del artefacto y validar aislamiento de tests/superficies prohibidas; no mantiene un parser XML paralelo.

---

# 197. WORLD PUBLISH Y RELEASE OPERATIONS

El world art/terrain final se bakea mediante Studio/Production Suite y se valida antes de publicación.

No depender de que un server reconstruya visualmente una capital desde cero para que exista.

Antes de publicar cambios que afecten contenido, acceso, safety o monetización, revalidar configuración de experience,
place access control, PolicyService assumptions y Content Maturity & Compliance. Toda experiencia pública mantiene el
questionnaire completo y fiel al contenido más maduro/extremo realmente accesible; si una actualización cambia una
respuesta, se actualiza y vuelve a enviar. La disponibilidad regional puede variar por requisitos locales y no se
considera una constante que el runtime pueda asumir.

Los requisitos de publicación/audience son **rollout-sensitive**. Si ASTRAKYN pretende llegar a Roblox Kids/Select o a
otra audiencia con requisitos especiales, validar en Creator Hub y documentación vigente account/age/ID verification,
2FA, evaluation/review y cualquier fee/subscription/threshold aplicable en el momento del release. No guardar esos
importes, umbrales o cupos cambiantes como constantes normativas del repositorio.

Metadata de discovery debe describir con precisión la experiencia: no keyword stuffing irrelevante, no leading
con recompensas monetarias/promesas engañosas y no reutilizar naming/imagery genérica o casi duplicada. Icon y
thumbnails son assets productivos moderados: seguir las dimensiones/formato vigentes de Roblox, comprobar
legibilidad a tamaños reales,
usar imagery original/relevante y evitar información crítica en zonas que la UI de Roblox pueda cubrir. Actualmente
Roblox recomienda icon cuadrado 512×512 y thumbnails 16:9 idealmente 1920×1080; estos números se revalidan al publicar,
no se convierten en invariantes eternas.

La preferencia de **AI data sharing** de Roblox es una decisión explícita de publicación/propiedad de ASTRAKYN; no se
acepta el default de la UI sin revisión, especialmente para source/assets propietarios. Si en el futuro el runtime
permite interacción del jugador con generative AI, revalidar las reglas vigentes de moderación/transparencia y declarar
esa interacción en Content Maturity cuando Roblox lo exija.

En experiencias propiedad de grupo, ASTRAKYN aplica mínimo privilegio sobre permisos de colaboración/publicación: Play,
Edit y publish/configuración productiva se conceden únicamente a roles/personas que los necesiten y se revisan también
a nivel de experiencia cuando la plataforma lo permita. Esta es una política operativa ASTRAKYN construida sobre los
controles de colaboración de Roblox, no una afirmación de que todos los equipos deban usar la misma matriz de roles.

Recordar que publicar una nueva versión no implica que todos los servidores viejos desaparezcan inmediatamente. Cambios
de
schema/protocol/content incompatibles requieren estrategia de versioning, drain/restart y backward compatibility
limitada
a la ventana de rollout.

Experience Configs puede utilizarse para activar/desactivar contenido tras publish cuando eso reduzca riesgo, sin
convertir
configs en un sustituto de migraciones de schema.

Si alguna vez se transfiere ownership de la experience a un grupo, tratarlo como una operación de release: inventariar y
reubicar/recrear los ModuleScripts/InsertService assets privados y packages que no puedan acompañar el cambio de owner,
revalidar permisos efectivos de Open Cloud API keys y emitir/rotar keys cuando corresponda. Roblox hace privada la
experience y cierra sus servidores al completar la transferencia; reconfigurar permisos y verificar dependencias antes
de volver a abrir producción.

---

# 198. ROBLOX PACKAGES

Usar Packages cuando aporten:

- reuse;
- ownership/permissions;
- versioning/history;
- deduplication;
- consistent modular kits.

Roblox describe `AutoUpdate` como parte del flujo más eficiente para packages compartidos, pero también documenta que
la actualización automática ocurre al abrir el place y se deshabilita/ignora en copias modificadas. ASTRAKYN añade un
guardrail de riesgo:

- low-risk/non-critical packages: auto-update permitido si ownership y compatibility están controlados;
- gameplay/security/data-critical packages: actualización revisada, versionada y validada antes de integrarse, aunque
  sea más conservador que el flujo genérico recomendado por Roblox.

No modificar copias y asumir que seguirán auto-updating.

El asset system no soporta transferir ownership de packages: elegir desde su creación el owner correcto —normalmente el
grupo productor cuando aplique—. Cualquier asset restringido incluido necesita permiso explícito de la experience para
renderizar/reproducirse. Una mass update de packages guarda los Places seleccionados pero **no los publica** y omite
copias modificadas; revisar warnings/diff y publicar/versionar explícitamente después de validación.

No usar Packages como excusa para ocultar ownership, provenance o version drift.

---

# 199. DOCUMENTACIÓN VIVA

La documentación viva completa del repositorio consta exclusivamente de:

```text
AGENTS.md
CONSTITUTION.md
ESTADO_ACTUAL.md
CHANGELOG.md
```

No existe árbol `docs/`.

No existen READMEs de dominio.

No existen specs históricas paralelas.

Git conserva el historial completo; `CHANGELOG.md` mantiene únicamente un resumen curado de cambios relevantes para
continuidad humana y de agentes.

`CONSTITUTION.md` es la única fuente normativa de producto, arquitectura, seguridad, datos, gameplay, world, arte,
tooling, QA y operaciones.

`ESTADO_ACTUAL.md` es la única fuente del estado operativo vivo: implementación real, evidencia disponible, blockers,
release readiness y feature matrix.

---

# 200. AGENTS.MD

Mantener breve, autoritativo y agnóstico del proveedor de agente.

Incluye:

- orden obligatorio de lectura;
- project principles;
- dependency direction;
- hard security rules;
- hard persistence rules;
- reglas contra documentación paralela;
- quality gates;
- comandos canónicos;
- criterios de evidencia;
- referencias únicamente a `CONSTITUTION.md`, `ESTADO_ACTUAL.md` y `CHANGELOG.md`.

No duplicar la especificación extensa de `CONSTITUTION.md`.

Todo agente debe comenzar por `AGENTS.md` y leer después `CONSTITUTION.md` y `ESTADO_ACTUAL.md` antes de realizar
cambios
arquitectónicos o declarar estado.

---

# 201. NO .CURSOR NI DOCUMENTACIÓN ESPECÍFICA DE AGENTE

Eliminar `.cursor/` y `.cursorignore` del repositorio.

No mantener reglas, agents, commands o documentación ligada a un editor/agente concreto como fuente de verdad.

Las instrucciones compartidas viven en `AGENTS.md` y deben funcionar para cualquier agente capaz de leer el repositorio.

Configuraciones editoriales estrictamente técnicas solo pueden existir fuera de esta documentación si no duplican
contratos, no alteran autoridad del runtime y no crean una segunda fuente de verdad.

---

# 202. NO DOCUMENTATION DRIFT

Cambio de contrato:

code + tests + validators + `CONSTITUTION.md` en la misma entrega cuando corresponda.

Cambio del estado real o de evidencia:

actualizar `ESTADO_ACTUAL.md` en la misma entrega.

Cambio relevante completado:

registrarlo de forma concisa en `CHANGELOG.md`.

Docs que contradicen runtime se consideran bug.

Nunca documentar como implementado aquello que solo existe como objetivo en `CONSTITUTION.md`.

---

# 203. RETIRADA DE DOCUMENTACIÓN TRANSITORIA

Reviews, planes, prompts de migración y matrices temporales son **inputs de trabajo**, no fuentes vivas permanentes. Al
cerrar una migración, conservar solo la regla duradera en `CONSTITUTION.md`, el estado/evidencia actual en
`ESTADO_ACTUAL.md` y el hito histórico resumido en `CHANGELOG.md`; eliminar el documento transitorio del branch
principal.

---

# 204. ACTUALIZACIÓN DE TOOLCHAIN Y API SURFACE

Mantener versiones fijadas cuando la herramienta externa lo permita. `rokit.toml` es la fuente canónica de la toolchain externa aprobada; actualmente fija Rojo, Lune, Selene, StyLua y Luau-LSP. CI instala esa toolchain mediante Rokit en lugar de instalar runtimes/lint/typecheckers paralelos por separado.

No `latest` ciego en CI productivo.

Las dependencias Luau externas se incorporan solo cuando existe una necesidad concreta que no quede mejor resuelta por una API/primitiva nativa de Roblox o por una implementación ASTRAKYN ya existente. No añadir un package manager, manifest, lockfile o árbol de packages vacío por anticipación. Si se aprueba la primera dependencia externa, reevaluar el estado vigente del ecosistema antes de elegir gestor; fijar el CLI elegido en `rokit.toml`, versionar su manifest y lockfile, separar dependencias shared/server y dependencias exclusivas de tooling/tests según su superficie de replicación, montar con Rojo únicamente los paquetes necesarios y exigir una instalación reproducible/locked en CI. Los directorios generados por el gestor no se convierten en source-of-truth ni se editan manualmente.

Un package manager Luau y los Roblox Packages resuelven problemas distintos. El primero gestiona dependencias de código del workspace; Roblox Packages versiona y distribuye jerarquías de Instances/assets dentro del sistema de assets de Roblox. No sustituir uno por el otro ni usar ninguno para ocultar ownership, provenance, version drift o una dependency boundary incorrecta.

Antes de actualizar:

- release notes;
- official Roblox docs/API status;
- compatibility;
- run gates;
- update lockfiles/manifests.

No bajar versiones para ocultar errores.

Revisar periódicamente el inventario oficial de APIs deprecated y migrar antes de que una dependencia crítica se vuelva
un
blocker.

Para filesystem-as-source-of-truth, Rojo sigue siendo apropiado; la documentación oficial de Roblox lo presenta como
una opción adecuada para ese workflow y recomienda Rokit para versionar herramientas de forma reproducible. Rojo, Lune,
Selene, StyLua y Luau-LSP siguen siendo herramientas externas/comunitarias: pin, provenance y upgrade validation son
responsabilidad de ASTRAKYN, no una garantía de soporte de Roblox. Lune es el runtime canónico del tooling propio bajo
`tools/`; evita mantener una segunda infraestructura Python para filesystem, procesos, validación, hashing y manipulación
de places/modelos. Lune no sustituye al motor Roblox ni se usa para simular una experiencia completa fuera de Studio.
Los módulos estándar de Lune (`@lune/*`) se resuelven en runtime por Lune y en el editor mediante los typedefs generados
por `lune setup`. Esos typedefs viven fuera del repositorio en `~/.lune/.typedefs/<version>/`; `.luaurc` versiona únicamente
el alias `lune` correspondiente a la versión exacta fijada en `rokit.toml`. Tras instalar o cambiar el pin de Lune se debe
ejecutar `lune setup`; no se vendorizan copias de sus typedefs ni se usan aliases legacy específicos de VS Code.

StyLua es el formatter canónico de Luau. El quality gate ejecuta siempre StyLua en modo escritura sobre `src/`, `tests/` y `tools/` antes del lint/typecheck y, acto seguido, ejecuta `stylua --check` para exigir que el resultado sea estable e idempotente; un diff puramente formateable se autocorrige y no se maquilla como fallo de código. Luau-LSP se usa para lenguaje/análisis/typecheck; opciones que cambian el
formato de sus diagnósticos no sustituyen el formatting de código. El gate debe typecheckear **todo** el Luau vivo: `tools/` se analiza en plataforma estándar contra los typedefs de Lune generados por `lune setup`; `src/` se analiza en plataforma Roblox contra el DataModel productivo; `tests/` se analiza junto a `src/` contra el overlay efímero de tests. Compilar sintácticamente `tools/` no sustituye su typecheck. Cualquier TypeError, warning inesperado, `any` explícito o archivo sin `--!strict` falla el gate; no se filtran diagnósticos de código ni se permiten suppressions para convertir rojo en verde. `.vscode/settings.json` es la única configuración Luau-LSP compartida por editor y analyzer batch para las opciones Roblox aplicables a producto/tests, incluido `strictDatamodelTypes`. El gate batch usa el modo standalone oficial `luau-lsp analyze`, no implementa un cliente LSP propio ni mantiene una segunda configuración persistente. Usa un único `sourcemap.json`: todo mapa se genera con `rojo sourcemap --include-non-scripts`; primero lo genera desde `default.project.json` y analiza `src/`; después genera el overlay de tests `.astrakyn-test.project.json` en la raíz del workspace, reutiliza temporalmente el mismo sourcemap y analiza conjuntamente `src/` y `tests/`, elimina el overlay y deja `sourcemap.json` con la vista ampliada producto+tests; el producto se valida separadamente antes contra un mapa generado desde `default.project.json`. No mantiene un segundo proyecto o sourcemap versionado/persistente. El editor usa el mismo generador `tools/test/sourcemap.luau`, de modo que `tests/` y el batch comparten exactamente la misma topología tipada. Cualquier upgrade de Luau-LSP exige revalidar opciones CLI, parser de settings, definiciones Roblox y diagnósticos antes de cambiar el pin.

El editor y el batch usan explícitamente el nivel Roblox `None`, apropiado para código normal de experiencia, para evitar que `PluginSecurity` amplíe artificialmente la superficie API disponible durante el desarrollo. El modo standalone `luau-lsp analyze` no obtiene por sí solo las definiciones Roblox. `rokit.toml` es la única fuente de la versión activa de Luau-LSP: el gate lee ese pin y selecciona para esa versión el blob verificado de `globalTypes.None.d.luau`, que cachea fuera del workspace en el directorio temporal del sistema. Las definition files de Luau-LSP usan sintaxis propia y nunca deben escribirse dentro de `.build` ni otro path del workspace donde el editor pueda interpretarlas como fuente `.luau` ordinaria; el gate limpia la caché heredada `.build/luau-lsp` antes del análisis. No mantiene una segunda constante de versión ni usa `luau-lsp --version` como precondición del análisis. No se usa una URL `latest`, no se versiona una copia generada en el repositorio y una versión sin blob verificado o una descarga distinta al blob fijado debe fallar. La documentación API no forma parte del typecheck batch porque no afecta a los diagnósticos; permanece responsabilidad del editor cuando sea necesaria para hover/intellisense.
El CLI standalone registra un warning de watcher cuando recibe sourcemap aunque no exista ningún watcher en modo batch. `tools/schema/check.luau` elimina únicamente ese log de infraestructura exacto; cualquier otro warning emitido por Luau-LSP sigue siendo fallo del gate. No se filtran diagnósticos de código. En Windows existe un fallo conocido de Rokit por el que un launcher bajo `~/.rokit/bin` puede quedar apuntando a una instalación inexistente y devolver `(os error 3)` aunque el shim siga presente. Solo ante esa firma exacta y solo cuando el ejecutable resuelto pertenece a `.rokit/bin`, el gate puede ejecutar una única vez `rokit install` para restaurar la toolchain fijada y reintentar el mismo comando. Si el retry falla o aparece cualquier otro error, el gate falla sin más reparación automática.

Selene usa su standard Roblox más una extensión local mínima (`astrakyn.yml`) únicamente para globals vigentes que la versión fijada de su standard todavía no modele; no se permiten suppressions inline para ocultar esa diferencia. El tooling propio debe permanecer en Luau/Lune y pasar sintaxis, Selene, StyLua y Luau-LSP strict typecheck; no se introduce Python/Pyright u otro runtime paralelo salvo una necesidad nueva, explícita y justificada que Lune no pueda cubrir correctamente.

No habilitar Script Sync simultáneamente sobre el mismo subtree como una segunda source-of-truth bidireccional salvo
workflow explícito que resuelva conflictos.

El Studio MCP server oficial puede utilizarse como puente local opcional para que un cliente de IA confiable
inspeccione, edite o playtestee el DataModel abierto. No reemplaza Git/Rojo, tests ni review; no se comitea
configuración específica de un proveedor como autoridad y solo se conectan clientes confiables porque pueden
leer/modificar el Place abierto.

---

# 205. OBSERVABILITY

`Logger` evoluciona a structured observability.

Fields:

severity;

system;

operation;

correlation;

user;

character;

entity;

zone;

place;

job;

build.

No logs con secretos.

La observabilidad propia complementa, no reemplaza, las surfaces nativas. Revisar Error Report antes/después de
releases, Server Crashes/OOM snapshots cuando existan, Performance Dashboard y los dashboards de
DataStore/MemoryStore. Configurar
alerts nativas para métricas críticas cuando la experiencia sea elegible y basar thresholds en un baseline observado,
no en números decorativos. Correlacionar siempre incidentes con Place/build/version y distinguir fallo de plataforma de
regresión propia.

Si Extended Services está activo, observar consumo y billing contra su budget además de request/error rate. Tratar el
throttling por budget agotado/reducido como un modo de fallo esperado que debe degradar de forma segura a la capacidad
default, no como una sorpresa que solo se descubre por un incidente live.

---

# 206. ERROR TAXONOMY

Distinguir:

ValidationError

PermissionError

ConflictError

TransientPlatformError

PermanentPlatformError

DataCorruptionError

InvariantViolation

ExternalAssetError.

No usar strings libres para control flow.

---

# 207. ERROR CONTAINMENT

Un NPC corrupto no detiene toda AI.

Una quest inválida no derriba QuestService.

Una publicación de Messaging fallida no revierte un commit durable.

Un asset missing no se transforma silenciosamente en cubo.

---

# 208. PERFORMANCE ANALYTICS

Después de release observar en Creator Dashboard/Performance Dashboard y telemetría propia:

- join/load;
- client/server memory;
- frame time/FPS;
- server CPU/heartbeat health;
- network/streaming symptoms;
- data errors;
- teleport errors;
- purchase errors;
- crash/disconnect signals disponibles.

Correlacionar cambios con build/content version.

Studio profiling no sustituye producción ni hardware real.

---

# 209. CONTENT COMPLETENESS

La escala final debe soportar sin rediseño:

múltiples continentes;

decenas de zonas;

miles de quests;

miles de items;

cientos de abilities;

cientos de NPC archetypes;

muchas dungeons;

raids;

battlegrounds;

guilds;

global auction;

live events.

No inflar catálogos artificialmente para cumplir un número.

---

# 210. NO CONTENT FOR CONTENT'S SAKE

Cada:

item;

quest;

NPC;

POI;

profession;

currency;

zone;

ability

debe tener propósito.

No ruido de catálogo.

---

# 211. PRODUCTION ART GATE

No puede existir en contenido live:

visible blockout;

primitive character placeholder;

stub building;

temporary road;

empty mesh fallback;

missing PBR reference;

placeholder icon;

fake animation;

fake VFX.

Incomplete content se deshabilita o bloquea release.

No se muestra degradado.

---

# 212. CONTENT SOURCE OF TRUTH

Definitions son source-of-truth de gameplay.

ArtManifest es source-of-truth de assets.

WorldDefinition/WorldBakeManifest son source-of-truth del world authoring.

DataStore es source-of-truth de player/guild/economy state.

MemoryStore jamás reemplaza estos.

---

# 213. COMMERCE SOURCE OF TRUTH

Virtual purchases: Marketplace receipt + durable receipt ledger.

Commerce Products físicos, si se adoptan: estado de orden/webhook autenticado para paid/refund/cancel + receipt normal
para cualquier Developer Product bundled según el flujo oficial vigente.

Nunca un client event ni el cierre de un purchase prompt.

---

# 214. STAFF SOURCE OF TRUTH

`ASTRAKYN_StaffDirectory`.

No UI.

No local flag.

No PlayerAttribute.

No username list.

---

# 215. STAFF BOOTSTRAP

La primera instalación del StaffDirectory utiliza una lista mínima server-only de OWNER UserIds autorizados para
bootstrap.

No se replica al cliente.

Después, todas las asignaciones se administran mediante StaffDirectory + RBAC + audit.

Bootstrap no concede admin genérico al resto.

---

# 216. OFFLINE STAFF ACTIONS

Offline mutation nunca compite silenciosamente con una sesión activa.

Workflow:

detect active lease;

route action to owning server cuando sea posible;

o crear durable StaffOperation;

reconcile when profile can be safely acquired.

---

# 217. COMPENSATION

GM no ejecuta `grant 500000 gold`.

Crear `CompensationPackageCatalog`.

SENIOR_GAME_MASTER puede aplicar packages predefinidos.

Direct arbitrary adjustment queda reservado a autorización crítica.

---

# 218. DATA RECOVERY UI

Staff Console permite:

inspect schema;

view validation failure;

view versions metadata;

request restore;

run approved migration/repair.

Nunca editar raw JSON libremente.

---

# 219. CHAT MODERATION Y STAFF

Staff decoration de mensajes se deriva de capabilities server-approved.

No confiar en cliente para marcarse GM.

Staff chat sigue reglas de comunicación aplicables.

---

# 220. NATIVE ROBLOX FEATURES FIRST

Esta es una **decisión de arquitectura ASTRAKYN**, no una regla universal de Roblox: antes de construir reemplazo propio
comprobar capacidades **actuales** de la plataforma y preferirlas cuando cubran mejor seguridad, policy, lifecycle,
operación o integración.

La lista de prioridad incluye, cuando encaje:

- `TextChatService`, TextChannels y cross-server chat;
- `Players:BanAsync()` / Ban API;
- `AnalyticsService`;
- Experience Configs + native `ConfigService`;
- Roblox Experiments para A/B controlado cuando aplique;
- Secrets Store;
- DataStore/MemoryStore/Messaging primitives;
- custom matchmaking + native `MatchmakingService` signals;
- native `SocialService` para capabilities sociales soportadas, invites y referral cuando encaje;
- `ExperienceNotificationService`/Experience Notifications para re-engagement cuando se adopte;
- `BadgeService` para badges visibles en plataforma, sin sustituir achievements internos;
- `RecommendationService` únicamente si ASTRAKYN necesita personalización/recomendación de contenido in-experience;
- `TeleportService:TeleportAsync()` / `ReserveServerAsync()`;
- `PolicyService`;
- Managed Pricing;
- Packages;
- Instance Streaming / SLIM;
- Server Authority cuando su status productivo/compatibilidad lo permita;
- Input Action System;
- UI StyleSheets/Style Editor;
- modern Audio objects/Wires;
- Animation Graph Editor;
- Avatar Setup;
- Studio Importer / Asset Manager;
- Roblox Blender plugin;
- `ChangeHistoryService`;
- Localization/Cloud Localization Table;
- Open Cloud/webhooks.

No mantener solución casera inferior cuando la plataforma resuelve el problema mejor.

Tampoco introducir una dependencia nativa solo por novedad: beta/experimental features requieren evaluación de estado,
compatibilidad, rollback y riesgo antes de convertirse en production contract.

---

# 221. DEPRECATION POLICY

Antes de utilizar una API o propiedad nueva:

1. consultar documentación oficial actual;
2. comprobar el Engine API/Open Cloud index correcto;
3. comprobar el inventario oficial de deprecated APIs;
4. confirmar security/thread/yield/capability constraints;
5. confirmar si está GA, beta o experimental.

Si está deprecated, migrar al reemplazo vigente y no crear código nuevo sobre ella.

Si está beta/experimental, no convertirla en requisito irreversible de producción sin un plan explícito de validación y
fallback.

No usar snippets históricos de DevForum/blogs como autoridad cuando contradigan Creator Hub/API Reference actual.

---

# 222. ASSET QUALITY NO SIGNIFICA BRUTE FORCE

Máxima calidad razonable significa:

correct modeling;

materials;

composition;

lighting;

animation;

VFX;

silhouettes;

detail allocation.

No:

máximos polígonos;

4K everywhere;

Precise everywhere;

lights everywhere;

particles everywhere.

---

# 223. PERFORMANCE = CALIDAD

Una zona visualmente espectacular que:

crashea móviles;

tarda demasiado en cargar;

consume memoria excesiva;

hace stutter;

reduce server tick

NO es production quality.

---

# 224. CORE LOOPS

Documentar y validar:

Moment-to-Moment Combat Loop

Exploration Loop

Quest Loop

Session Loop

Character Progression Loop

Gear Loop

Profession Loop

Economy Loop

Social Loop

Dungeon Loop

Raid Loop

PvP Loop

Collection Loop

Endgame Loop

Long-Term LiveOps Loop.

---

# 225. CONNECTION ENTRE SISTEMAS

El producto debe formar un sistema coherente:

```text
EXPLORE
→ DISCOVER
→ QUEST
→ COMBAT
→ LOOT
→ EQUIP
→ CRAFT
→ TRADE
→ PARTY
→ DUNGEON
→ RAID
→ REPUTATION
→ COLLECTION
→ ENDGAME
→ LIVE CONTENT
```

No features aisladas.

---

# 226. COMPLETE FEATURE MATRIX

Mantener la matriz completa de madurez dentro de `ESTADO_ACTUAL.md`, no en un quinto documento.

Dominios obligatorios:

Account

Character

Roster

Creation

Races

Classes

Specializations

Talents

Loadouts

Stats

Progression

Abilities

Combat

Auras

CC

Threat

Death

Macros

NPCs

AI

Quest

Narrative

Dialogue

Cinematics

World

Continents

Zones

Biomes

Terrain

Cities

Roads

POIs

Exploration

Map

Travel

Mounts

Companions

Settlements

Construction

Party

Raid Groups

Group Finder

Matchmaking

Instances

Dungeons

Raids

Bosses

PvP

Battlegrounds

Factions

Reputation

Items

Inventory

Equipment

Loot

Vendors

Currencies

Trade

Auction

Mail

Professions

Gathering

Crafting

Guilds

Achievements

Collections

Appearance

Endgame

World Events

LiveOps

Chat

Moderation

Support Tickets

RBAC

Staff Console

UI

Accessibility

Input

Localization

Audio

Animation

VFX

Lighting

Art Pipeline

Blender

Assets

Persistence

Transactions

Cross-server

Networking

Security

Anti-exploit

Streaming

Performance

Analytics

Commerce

Privacy

Testing

Migration

Release

Recovery.

Cada uno:

```text
NOT_PRESENT
BROKEN
PARTIAL
IMPLEMENTED
INTEGRATED
TESTED
VALIDATED
PRODUCTION_READY
```

La matriz debe representar el repositorio real y actualizarse cuando cambie la evidencia. No debe duplicar la definición
del contrato; para requisitos normativos se remite a `CONSTITUTION.md`.

---

# 227. NO "OPTIONAL" PARA OCULTAR TRABAJO

Un sistema requerido por esta constitución no puede clasificarse `OPTIONAL` para cerrar la tarea.

Solo puede marcarse `NOT_APPLICABLE` cuando una decisión explícita en `CONSTITUTION.md` o una resolución de producto
registrada en `ESTADO_ACTUAL.md` explica por qué ASTRAKYN deliberadamente no lo utiliza y no contradice requisitos de
Roblox/plataforma.

---

# 228. DEFINITION OF IMPLEMENTED

Código real existe y **todo el comportamiento requerido por el contrato normativo del dominio funciona**.

Los estados de madurez son acumulativos: ningún nivel superior puede saltarse uno inferior. Un dominio con una parte
funcional relevante todavía ausente, simulada, placeholder o incompatible con su contrato permanece como máximo en
`PARTIAL`, aunque tenga catálogo, UI, remotes, tests estáticos o consumers productivos.

Antes de evaluar `IMPLEMENTED`, también se audita que el **contrato del dominio no sea artificialmente plano** frente al
mandato global de profundidad de ASTRAKYN. Cuando sean aplicables, el dominio debe modelar explícitamente identidad/
template frente a instance/ownership, estados y lifecycle/transiciones, eligibility/conditions, autoridad y permisos,
persistencia/recovery/failure paths, variantes data-driven y consumers/extension surfaces reales. Una definition con pocos
scalars, un service CRUD o una UI cableada no se consideran profundidad por sí mismos. AzerothCore 3.3.5a puede usarse
como referencia estructural de sistemas MMORPG maduros para detectar dimensiones ausentes, pero nunca obliga a copiar
features, datos, fórmulas, nombres, código GPL ni decisiones de diseño de WoW; una divergencia deliberada debe quedar
expresada por el contrato propio de ASTRAKYN.

---

# 229. DEFINITION OF INTEGRATED

`INTEGRATED` presupone `IMPLEMENTED`. No significa simplemente «hay wiring» ni «existe un consumer». La implementación
completa del dominio funciona además con, según aplicabilidad:

data;

network;

UI;

dependencies;

permissions/contexto autoritativo;

failure handling.

Si `ESTADO_ACTUAL.md` enumera como bloqueo una función, definición, lifecycle, estado, consumer, permiso/contexto,
persistencia o dependencia **requerida por el contrato del propio dominio** que todavía falta, ese dominio no puede ser
`INTEGRATED`; debe permanecer `PARTIAL` hasta cerrar ese hueco. En cambio, la ausencia de ejecución TestService, soak,
profiling, device matrix o acceptance evidence posterior no rebaja por sí sola un dominio funcionalmente completo e
integrado: bloquea `TESTED`, `VALIDATED` o `PRODUCTION_READY`, según corresponda.

---

# 230. DEFINITION OF TESTED

Tests realmente ejecutados.

---

# 231. DEFINITION OF VALIDATED

Acceptance criteria y validators pasan.

---

# 232. DEFINITION OF PRODUCTION READY

Requiere, según aplicabilidad:

- implementation;
- integration;
- server authority/security;
- persistence;
- transactions/recovery;
- network;
- performance/memory;
- UX/accessibility/cross-platform;
- art/audio;
- testing;
- documentation;
- observability;
- operations/rollback;
- Roblox policy/privacy/chat compliance;
- monetization policy/PolicyService compliance;
- content maturity/reach configuration;
- current API/deprecation validation.

`PRODUCTION_READY` significa evidencia real para la versión y plataforma actual, no que el diseño “parece correcto”.

---

# 233. PRIORIDAD DE REMEDIACIÓN

La lista exacta de blockers vive en `ESTADO_ACTUAL.md`. El orden normativo de riesgo es:

1. **P0 data safety** — destructive migrations, session ownership, lost/duplicate durable state.
2. **P0 multi-document transactions** — trade, guild bank/research, auction/mail/delivery, world costs, premium grants.
3. **P0 security/authority** — RBAC, legacy admin, typed schemas, rate/context validation, client authority,
   confidential
   content/place access.
4. **P0 platform compliance** — chat/TextChatService, PolicyService, Ban API, privacy/RTBF, service-name collisions y
   APIs
   deprecated.
5. **P0 art contract** — visual fallbacks/placeholders y uncontrolled third-party assets.
6. Cross-server, teleports, activity matchmaking, global auction, analytics/configs and protocol refactor.
7. World/art/content/endgame expansion and polish.

No adelantar expansión visible mientras siga abierto un P0 que pueda causar corrupción, explotación, incumplimiento o
pérdida económica.

---

# 234. MIGRACIÓN DEL REPOSITORIO ACTUAL

Ejecutar exactamente:

1. Crear snapshot/backup del estado actual.

2. Generar dependency map.

3. Crear target tree.

4. Mover módulos por dominio sin duplicarlos.

5. Actualizar require paths.

6. Consolidar docs.

7. Eliminar `.superpowers`.

8. Eliminar multi-environment config.

9. Crear production-only RuntimeConfig.

10. Consolidar `default.project.json` como único proyecto Rojo versionado.

11. Retirar tests del default DataModel y generar su overlay únicamente de forma efímera como `.astrakyn-test.project.json` ignorado por Git en la raíz del workspace.

12. Sustituir ProfileMigrator.

13. Introducir MigrationRegistry.

14. Introducir TransactionCoordinator.

15. Migrar trade/guild/mail/auction/construction.

16. Implementar CrossServer platform.

17. Implementar PlaceCatalog.

18. Implementar InstanceTransfer.

19. Implementar RBAC.

20. Retirar AdminService binario.

21. Implementar Staff Console.

22. Migrar Chat a TextChatService/capacidades actuales.

23. Renombrar wrappers que colisionan con Services nativos e integrar las APIs oficiales correspondientes.

24. Dividir CharacterSheet en domain protocols.

25. Eliminar blockout visual fallbacks.

26. Crear Blender/Asset pipeline real.

27. Convertir world generation estático a authoring/bake.

28. Reescribir build tooling.

29. Actualizar validators/tests.

30. Ejecutar gates completos.

31. Ejecutar Studio runtime tests.

32. Ejecutar performance tests.

33. Corregir fallos.

34. Repetir gates.

35. Actualizar `ESTADO_ACTUAL.md` y `CHANGELOG.md`.

No dejar compatibility shims innecesarios después de terminar la migración.

---

# 235. REGLA DE CAMBIOS DESTRUCTIVOS

Antes de borrar/mover:

identify references;

update imports;

update tests;

update docs;

validate.

Después borrar.

No mantener copia antigua "por seguridad".

Git ya cumple esa función.

---

# 236. REGLA DE DECISIÓN Y BASELINE ROBLOX OFICIAL

Cuando una decisión pueda haber cambiado por evolución de Roblox, consultar documentación oficial actual antes de
implementar. La auditoría debe partir del índice completo para descubrir la surface correcta y después leer las páginas
relevantes; **no** se considera evidencia afirmar que se “leyó toda la documentación de Roblox” si no se puede demostrar
esa cobertura.

El punto de entrada canónico para agentes es el índice oficial de Creator Documentation:

`https://create.roblox.com/docs/llms.txt`

Desde ahí usar:

- Engine API index para Luau dentro del experience;
- Open Cloud index para HTTP/tooling externo;
- deprecated API inventory para migraciones;
- guías de arquitectura/security/performance/publishing para patrones recomendados.

No confundir Engine APIs con Open Cloud APIs.

Para una feature que toque plataforma, revisar **toda la superficie relevante**, no solo la clase API: guide +
reference + security/policy/performance implications + deprecation/status.

Las áreas que deben revalidarse cuando se modifiquen son, como mínimo:

- project/place configuration, collaboration/permissions y publishing;
- player/user identity, domain-scoped `User` y límites con global `UserId`;
- client/server/server-authority/streaming, physics/network ownership y pathfinding;
- data stores, memory stores, messaging, configs, secrets, Extended Services y `HttpService`;
- teleport/matchmaking/social;
- networking/security/access control;
- chat/text filtering/privacy/moderation;
- commerce/monetization/Commerce Products/PolicyService;
- analytics/experiments/localization;
- UI/input/accessibility/cross-platform;
- audio/animation, animation LOD y cualquier simulation-bound animation bajo Server Authority;
- assets/packages/importer/avatar/Blender y content preload/loading screens;
- performance/profiling/monitoring/alerts;
- Studio plugins/tooling/testing simulators;
- discovery/metadata/icons/thumbnails y audience/reach requirements;
- Open Cloud/webhooks/RTBF;
- safety/content maturity/regional reach;
- generative AI/AI data sharing únicamente si esas surfaces se usan o afectan al release.

La existencia de una capability en Roblox **no** obliga a ASTRAKYN a adoptarla. Solo se convierte en gap/target si el
producto la usa, la especificación la exige, un sistema existente depende de ella o afecta de forma transversal a
seguridad, publicación/compliance, datos o compatibilidad. Features no adoptadas se marcan `NOT_APPLICABLE` cuando
sea útil; no se crea arquitectura especulativa para perseguir el catálogo completo de APIs de Roblox.

No usar memoria antigua.

Registrar en `ESTADO_ACTUAL.md` la fecha/fuente de una auditoría de plataforma relevante y cualquier API cuyo status sea
incierto o beta.

---

# 237. REGLA DE EVIDENCIA

Nunca escribir:

"all tests passed"

"production ready"

"optimized"

"secure"

"60 FPS"

"no memory leaks"

sin evidencia real.

Estados de evidencia (ortogonales a la madurez `IMPLEMENTED`/`INTEGRATED`/`TESTED`/`VALIDATED`/`PRODUCTION_READY`
definida en 228–232):

- `VERIFIED` — comprobado mediante una fuente/artefacto autoritativo;
- `MEASURED` — obtenido por medición reproducible;
- `TESTED` — comportamiento cubierto por una prueba realmente ejecutada;
- `OBSERVED` — inspeccionado directamente en el snapshot/runtime;
- `INFERRED` — conclusión razonada sin verificación completa;
- `BLOCKED` — la comprobación requerida no pudo ejecutarse y se registra la causa.

---

# 238. CUANDO EL ENTORNO NO PERMITE UNA PRUEBA

No inventar resultado.

Registrar:

qué no pudo ejecutarse;

por qué;

qué evidencia falta.

Continuar con trabajo independiente.

---

# 239. NO BLOQUEAR POR PREGUNTAS INNECESARIAS

Cuando exista una elección técnica reversible y segura:

tomar la opción más segura y mantenible;

documentar;

continuar.

Solo detenerse por:

credentials;

permissions;

required production IDs;

missing proprietary asset;

destructive product decision imposible de inferir.

---

# 240. FINAL REPOSITORY CLEANLINESS GATE

Antes de terminar:

no duplicated systems;

no unused modules;

no unused services;

no orphan definitions;

no obsolete docs;

no historical plans;

no generated build outputs committed;

no empty `.gitkeep` trees innecesarios;

no environment modes;

no visible blockout;

no placeholder asset IDs;

no old compatibility code sin consumidor;

no stale TODO/FIXME críticos;

no runtime test harness;

no generic admin boolean.

---

# 241. FINAL SECURITY GATE

Verificar:

- server authority para todo estado crítico;
- Engine Server Authority status/config si se adopta;
- typed network schema;
- context validation;
- rate limiting de todos los client-triggerable paths;
- RBAC;
- staff auditing;
- purchase receipts + PolicyService;
- data leases;
- transaction recovery;
- chat permissions/privacy/TextChannels;
- text filtering;
- secure place access;
- network ownership/movement validation;
- replicated-content confidentiality;
- secrets management;
- third-party asset/script audit;
- no arbitrary dynamic code.

---

# 242. FINAL DATA GATE

Verificar:

no destructive profile fallback;

migration chain;

schema validation;

session leases;

ordered saves;

unknown outcome handling;

transaction sagas;

RTBF;

recovery.

---

# 243. FINAL ART GATE

Verificar:

- every visible asset approved;
- no visual primitive fallback;
- no missing meshes;
- no placeholder icon;
- real rigs/Avatar Setup validation where applicable;
- real animations/graph validation where applicable;
- real materials/PBR;
- real collisions;
- source provenance/license;
- asset ownership/privacy;
- third-party script safety;
- Blender source;
- official import/transfer warnings resolved;
- performance/streaming/SLIM profile.

---

# 244. FINAL MMO GATE

Verificar funcionamiento real de:

cross-server coordination;

party;

matchmaking;

instance allocation;

dungeon transfer;

raid transfer;

PvP transfer;

guild state;

auction;

mail;

presence;

global/live operations.

---

# 245. FINAL QUALITY GATE

No declarar ASTRAKYN terminado mientras una feature obligatoria permanezca:

MISSING

BROKEN

PARTIAL

UNKNOWN

NOT_TESTED

NOT_VALIDATED.

Tampoco declarar `PRODUCTION_READY` si existe drift conocido frente a APIs/recommendations/policies actuales de Roblox
que
afecte seguridad, datos, chat, monetización, privacy, safety, publishing o performance.

---

# 246. INSTRUCCIÓN FINAL AL AGENTE

No vuelvas a tratar ASTRAKYN como una vertical slice.

No construyas una demo.

No crees blockout como contenido visible final.

No introduzcas runtimes o configuraciones paralelas al producto canónico.

No conserves legacy por comodidad.

No ocultes deuda con fallbacks.

No inventes assets, IDs, tests, profiling ni seguridad.

No conviertas corrupción de datos en perfil vacío.

No confíes en el cliente.

No uses un boolean `isAdmin` como autorización.

No uses un único Remote gigantesco para todo el juego.

No uses transportes de chat propios para eludir TextChatService/privacy.

No confundas MemoryStore con persistencia.

No confundas MessagingService con delivery garantizado.

No confundas UpdateAsync con transacción multi-documento.

No confundas Engine API con Open Cloud.

No crees módulos propios con el mismo nombre que Services nativos de Roblox.

No adoptes una feature beta/experimental como única dependencia crítica sin verificar status y riesgo.

No uses geometría primitiva como sustituto silencioso de art final.

No uses resolución/polígonos máximos como sinónimo de calidad.

No publiques tests dentro del juego.

No mantengas documentación histórica como si fuera contrato vivo.

Trabaja siempre contra la estructura final de producción definida en este documento y contra la documentación oficial
vigente de Roblox para cualquier surface de plataforma.

Empieza por el repositorio real.

Audita.

Reestructura.

Migra.

Implementa.

Integra.

Prueba.

Perfila.

Corrige.

Vuelve a probar.

Valida contra Roblox actual.

Documenta en los cuatro archivos canónicos.

Y continúa hasta que el repositorio sea una base limpia, única, coherente, escalable y plenamente orientada a producción
para un MMORPG masivo de larga vida.

El resultado final debe ser:

**ASTRAKYN ONLINE — UN MMORPG ORIGINAL DE PRODUCCIÓN, DE ESCALA MASIVA, CON ARQUITECTURA DISTRIBUIDA, PERSISTENCIA
SEGURA, TRANSACCIONES RECUPERABLES, RBAC REAL, TOOLING PROFESIONAL, ARTE FINAL, PIPELINE BLENDER, CROSS-SERVER REAL,
CONTENIDO SISTÉMICO PROFUNDO Y UNA BASE CAPAZ DE ESCALAR DURANTE AÑOS SIN ARRASTRAR LEGACY, BLOCKOUT, RUIDO NI DEUDA
ARQUITECTÓNICA EVITABLE.**

---
