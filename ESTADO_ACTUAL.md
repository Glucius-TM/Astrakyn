# ASTRAKYN Online — Estado actual

Actualizado: 2026-09-26

## Modelo documental vigente

Orden de autoridad para cualquier agente:

1. `CONSTITUTION.md` — contrato normativo de producto, arquitectura y calidad.
2. `ESTADO_ACTUAL.md` — implementación observada, evidencia ejecutada y blockers vigentes.
3. Código, definitions, manifests, configuración y tests — verdad ejecutable del snapshot.
4. `CHANGELOG.md` — contexto histórico curado.

La evidencia ejecutable prevalece sobre afirmaciones de estado. Git conserva el historial; no se mantienen capas legacy
solo para compatibilidad histórica.

## Fundación vigente

### Tooling — consolidación Lune 2026-09-22

El tooling propio del repositorio utiliza ahora **Luau sobre Lune**. `rokit.toml` fija Rojo, Selene, StyLua, Luau-LSP y
Lune; Python y Pyright dejan de formar parte de la toolchain del repositorio y CI. Los scripts canónicos son
`tools/schema/check.luau` y `tools/build/build_place.luau`, con módulos de validación Luau bajo `tools/schema/`.

El quality gate conserva los contratos que existían para layout, catálogos, content IDs, remotes, runtime config, Rojo y
atlas, pero la extracción de catálogos ya no depende de regex Python globales: `tools/schema/source.luau` separa llamadas
y tablas con delimitadores balanceados. El gate compila sintácticamente todo el Luau vivo, ejecuta Selene y StyLua sobre `src`, `tests` y `tools`, prohíbe `any` explícito y exige `--!strict`, typecheckea `tools/` con Luau-LSP en plataforma estándar/Lune y typecheckea `src`/`tests` en plataforma Roblox reutilizando el único `sourcemap.json` del workspace.

El builder delega build y sourcemap a Rojo. El repositorio tiene ahora **un único proyecto Rojo versionado**,
`default.project.json`, y **un único `sourcemap.json` efímero** en la raíz del workspace. Con `--verify`, el quality gate
genera ese mapa desde el producto y analiza `src`; para analizar `tests` crea temporalmente `.astrakyn-test.project.json` en la raíz del workspace
mediante `tools/test/project.luau`, reutiliza el mismo `sourcemap.json` y elimina el overlay dejando la vista producto+tests que necesita Cursor. `.vscode/settings.json` usa `tools/test/sourcemap.luau` como `generatorCommand`, por lo que editor y gate comparten la misma topología. El build simple mantiene también ese sourcemap de workspace, pero construye el place exclusivamente desde `default.project.json`.
Después del `rojo build`, el builder abre `.build/ASTRAKYN.rbxlx` mediante `@lune/roblox.deserializePlace` y valida el
`DataModel` resultante, incluido el aislamiento de tests y de superficies administrativas prohibidas. El manifest usa
`@lune/serde` para SHA-256. No existe un emisor/parsing XML propio como fuente de verdad del artefacto.

Los tests siguen fuera del DataModel publicable, pero ya no constituyen una segunda configuración del proyecto. La
configuración runtime canónica sigue siendo `config/runtime.json` + `RuntimeConfigService` y los IDs publicados de atlas
viven únicamente en `assets/manifests/atlas_assets.json`.

## Baseline Roblox/tooling revisado — 2026-09-22

Creator Hub documenta Rokit para fijar toolchains de workflows externos y muestra Lune junto a Rojo/Wally como ejemplo
de stack. Esa mención no convierte Lune en una herramienta obligatoria ni mantenida por Roblox; ASTRAKYN la adopta como
decisión de arquitectura porque permite que el tooling propio comparta Luau con el proyecto y ofrece filesystem,
processes, serialización, hashing, networking y manipulación de places/modelos sin mantener Python en paralelo.

Lune queda fijado en `0.10.5`, release estable vigente verificada para esta migración. Rokit permanece en `1.2.0` en CI y
`setup-rokit@v3` instala automáticamente las herramientas de `rokit.toml`.

### Package manager Luau — decisión Wally 2026-09-22

Creator Hub documenta Wally como package manager para dependencias de software Luau comunitarias reproducibles y lo
muestra instalable mediante Rokit. Wally no sustituye a los Packages nativos de Roblox: Wally resuelve dependencias de
código en el workspace (`wally.toml`/`wally.lock`/`Packages`), mientras los Packages de Studio versionan jerarquías de
Instances/assets publicadas en Roblox.

ASTRAKYN **no adopta Wally todavía** porque este snapshot no consume ninguna dependencia Luau externa y no existe una
necesidad concreta que justifique `wally.toml`, `wally.lock` ni un árbol `Packages/`. Introducir un package manager sin
packages violaría el objetivo de mantener el repositorio sin tooling o manifests inertes. El trigger de adopción es la
primera dependencia externa aprobada que aporte más valor que una primitive nativa o una implementación propia ya
existente. En ese momento se debe reevaluar el estado vigente de Wally y alternativas compatibles con Roblox/Luau, fijar
la herramienta elegida mediante Rokit, commitear su lockfile, montar únicamente los realms necesarios con Rojo y hacer
que CI instale en modo reproducible/locked. No se reemplazan primitives o subsistemas existentes solo para justificar un
package manager.

## Evidencia disponible

La pasada actual parte de la v34 auditada y añade el cierre del primer P0 de datos más los primeros consumers durables de transacciones multi-documento.
El source-of-truth queda en **415 archivos Luau bajo `src/`** y **134 specs Luau registrados exactamente una vez** más
los cuatro módulos de harness/helper. Los gates internos `layout`, `catalogs`, `content-ids`, `remotes`,
`runtime-config`, `rojo-map`, `test-suite`, `icon-atlas`, `luau-source-policy` y `luau-syntax` terminan en verde sobre
este snapshot; por tanto los módulos/specs añadidos están registrados, sintácticamente válidos y no violan la policy de
source.

La última vista de require-graph posterior al wiring de persistencia/transacciones/Auction tiene **416 nodos**
(415 fuentes Luau + el manifest de atlas montado) y deja sin incoming productivo únicamente los dos entrypoints legítimos
de Rojo (`src/Server/Bootstrap/init.server.luau` y `src/Client/init.client.luau`). Los nuevos `PersistencePolicy`,
`PersistenceRecord`, `MigrationRegistry`, `TransactionRecord`, `TransactionCoordinator`, `MemoryCoordinationService`,
`AuctionIndexService` y `AuctionListingRecord` tienen consumidores productivos; no se ha añadido arquitectura decorativa. La regla de limpieza permanece igual: un módulo solo
se elimina después de demostrar que no tiene consumers ni contrato documental pendiente.

El build físico actual con Lune 0.10.5 + Rojo 7.7.0 termina con código 0, Lune deserializa el place sin incidencias y
`tools/build/build_place.luau --manifest` produce `.build/ASTRAKYN.rbxlx` de **2.320.769 bytes**, SHA-256
`c4dfe6f6ac6e0f0e98493cdbc737ab97e1e56e7b4a5f8c883a35430125b9177a`. El typecheck standalone de `tools/` con
Luau-LSP 1.70.0 + `tools/schema/types/standard.d.luau` termina con código 0. El segundo `--verify` Windows de v35 confirma
validators, StyLua apply/check, Selene con **0 errores / 0 warnings / 0 parse errors**, typecheck de `tools/` y typecheck
Roblox de producto antes de detenerse en un único diagnóstico del grafo de tests en `ContentConnectivity.spec`. Los
reruns posteriores demostraron que modificar el recorrido de `ability.Effects` no alteraba el diagnóstico. Una reproducción
mínima con Luau-LSP 1.70.0 identificó la causa real: el iterador generalizado `entry.AbilityIds or {}` infería exactamente
la unión `{ string } | {}` reportada por el checker. Este snapshot estrecha primero `AbilityIds ~= nil` y solo después
itera el array, sin casts ni suppressions. Un nuevo rerun Windows con el definitions blob fijado sigue siendo la autoridad para declarar
producto+tests completamente verde; TestService real continúa pendiente.

Comandos canónicos actuales:

```powershell
rokit install
lune setup
lune run tools/schema/check.luau
lune run tools/build/build_place.luau --verify --open
lune run tools/build/build_place.luau --release --manifest
```

El analyzer conserva `globalTypes.None.d.luau` del tag exacto de Luau-LSP 1.70.0, verifica el Git blob
`b578271914ff8c329b1a59d0d1fcfb9369dc8389` y lo cachea fuera del workspace. El workaround conservador del launcher de
Rokit en Windows sigue limitado a la firma conocida `(os error 3)` y a un único `rokit install` + retry.

## Alineación física con la Constitución — 2026-09-24

La auditoría posterior a la limpieza de tests detectó que el código todavía conservaba namespaces físicos sustituidos aunque `CONSTITUTION.md` ya definía `Server/Platform`, `Server/Domains`, `Client/Presentation`, `Client/UI`, `Client/Domains`, `Shared/Protocols` y tests por tipo de evidencia como arquitectura canónica. Esa divergencia se corrigió en implementación, no rebajando el contrato documental.

El árbol vivo ya no contiene `Server/Infrastructure`, `Server/Services`, `Server/Systems`, `Server/Engines`, `Client/Hero`, `Definitions/Remotes`, `Shared/Content`, `Shared/Signals`, `Shared/UI`, los antiguos roots de tests por dominio ni `tools/types`. `default.project.json`, todos los `require`, Bootstrap, tests y validators apuntan a los ownerships canónicos. `layout.luau` mantiene allowlists explícitas por namespace y falla si reaparece una capa sustituida o un directorio inmediato no permitido.

La comprobación de dependencias con `luau-lsp require-graph` sobre el sourcemap productivo deja sin incoming únicamente `Server/Bootstrap/init.server.luau` y `Client/init.client.luau`, ambos entrypoints Rojo legítimos. La vista producto+tests añade únicamente `tests/Runner.server.luau`. El facade `Client/UI/HUD/Inspector/Inspector.luau` era el único ModuleScript productivo sin consumidor y fue eliminado después de confirmar que sus exports reales se consumen directamente desde sus módulos canónicos. No quedan cuerpos Luau duplicados, archivos vacíos, backups temporales, JSON inválidos, helpers de tests sin consumidor ni specs huérfanos.

La batería mantiene **134 specs + 4 módulos de harness/helper**, pero se retiraron assertions globales repetidas o floors históricos que no pertenecían al dominio del spec —especialmente conteos totales de `StatCatalog`, conteos enabled/disabled/edges y ciclos repetidos— dejando esas invariantes en sus tests propietarios. Esto reduce fallos en cascada por cambios legítimos de catálogo sin reducir los casos funcionales únicos.

## Profundidad y conectividad de catalogs — 2026-09-25

La revisión completa de definitions deja una superficie conectada, no solo numerosa: **137 items, 109 abilities, 120 effects,
22 loot tables, 53 vendor offers, 45 recipes, 5 profesiones, 13 sets, 7 trinket effects, 5 gems, 49 NPCs de servicio,
24 hostiles con perfil+kit explícito, 53 quests + 11 dailies, 12 archetypes y 24 specializations**. `ContentConnectivity.spec`
y `tools/schema/catalogs.luau` convierten esa conectividad en gate: todos los items shippables tienen fuente estática; todo
set puede alcanzar su tier máximo; gems/trinket effects tienen item físico; todos los hostiles resuelven profile/kit/loot;
y las 109 abilities/120 effects tienen al menos un consumer vivo.

Los hostiles normales ya no consumen un único comportamiento `Enemy`: `SpawnTableCatalog` define perfiles melee/brute/
skirmisher/ranged/caster/controller/channeler y kits reales por entry; `WorldService` los propaga a la unidad y `EnemyAgent`
rota abilities listas respetando su cooldown canónico, con fallback a basic strike. `CombatService` consume también effects
secundarios de las abilities NPC, por lo que CC, interrupt, resource drain y displacement dejan de ser contenido solo de
jugador/boss. El loot normal se distribuye por tablas temáticas de zona y un entry puede sobrescribir su tabla.

La economía/inventario también gana consumers directos: cada archetype inicia con `SmallBag` en `Bag1`; bags superiores,
reagent/profession/bank bags tienen rutas de vendor/crafting; Alchemy y Latticecraft se suman a Mining/Smithing/Cooking y
se preservan en profile, roster wire, parser y lobby. La auditoría detectó y corrigió seis POIs de servicio con NPC LinkId
inexistente y el set Hide, cuyo tier de seis piezas era inalcanzable porque solo había cinco piezas físicas; `HideMantle`
cierra ese tier y tiene atlas/fuente de adquisición.

Esta pasada **no** declara completo el aprendizaje de skills. `KnownAbilityService` y `profile.Abilities` existen, pero la
creación entrega principalmente kits por archetype/spec y los NPC `Trainer` siguen siendo world/presentation: falta una
autoridad trainer server-side con oferta, requisitos, coste, learn/unlearn y persistencia idempotente. Quest progression
sigue limitada por objetivos simples y la IA todavía necesita roles/targeting/FSM más ricos. Además, el `Reach` del perfil
NPC sigue sirviendo a la vez como preferred combat range y umbral melee de threat; separar `MeleeReach` de cast/ranged
preferred range queda como deuda explícita para una siguiente pasada de AI/threat.

## Fundamentos de combate revisados contra AzerothCore 3.3.5a — 2026-09-24

Se revisaron los contratos de `azerothcore/azerothcore-wotlk` como referencia funcional de un MMORPG maduro, sin copiar
código GPL ni trasladar fórmulas de WoW como requisitos del producto. Los patrones aprovechados son conceptuales: autoattack
como estado persistente con timers de swing, threat con sticky aggro/taunt/healing threat y kill rewards de grupo con
elegibilidad espacial. ASTRAKYN conserva definitions, fórmulas, constantes y autoridad propias.

El combate jugador ya soporta autoattack server-authoritative separado de Ability execution: target y clocks main/off-hand
viven en `CombatService`, perfiles de arma en `WeaponCombatProfiles` y los swings reutilizan el pipeline real de
mitigation/procs/resources/events/threat. La pasada 2026-09-25 completa el contrato de swing con geometría fail-closed,
range/LOS y arco frontal, retry corto sin perder el estado de attack, timers main/off independientes con separación mínima
tras cada impacto y reescalado de la fracción restante cuando cambia haste/attack speed. `WeaponDamage` deja de ser un stat
sin productor de arma: deriva de ItemLevel+subtipo y quality/upgrade/durability; el primary alimenta abilities y cada hand
usa su instance damage para el swing. Dual wield es alcanzable mediante one-hand compatible en OffHand, exige un main-hand
one-hand distinto y equipment normaliza pares inválidos. Cambiar la instancia física de un arma reinicia solo el reloj
de esa mano; los cambios de haste conservan progreso proporcional. Start/retarget/stop preservan esos clocks, por lo que
spamear remoto o macros no adelanta swings; muerte/session teardown son las únicas transiciones que destruyen el estado
temporal. Loadout/equip/persistencia comparten `EquipmentRules`
para slot, instancia, durability, RequiredLevel, UniqueEquipped y pair legality. Las abilities ranged declaran
`WeaponChannel=Ranged`, requieren arma ranged real y toman su daño de esa instancia. Right-click solicita target+start,
errores iniciales vuelven por la UI existente, `Q` cancela cast/macro/autoattack y el DSL seguro mantiene
`STARTATTACK`/`STOPATTACK` sin aceptar damage/timing/target inyectado por cliente. NPC AI aplica el mismo LOS para
adquisición/melee y conserva su swing loop server-side.

Se corrigió además el contrato transaccional de abilities: cooldown/GCD/resource tienen preflight no mutante y commit solo
cuando la resolución es aceptada; un cast diferido fallido abandona correctamente `Casting`/`Channeling`. Combat engagement
queda separado de action/control state: casting o CC ya no convierten falsamente al jugador en OOC para regen/macros y el
timeout vive en un único contrato. Threat deja de
crear tablas inútiles para PvP, distingue `Clear(target)` de `RemoveSource(source)`, mantiene thresholds 110/130, taunt
temporal y healing threat sobre healing efectivo. Party kill credit/shared XP usa zona y distancia autoritativas.

La auditoría de AzerothCore también hizo explícitos huecos que **no se presentan como terminados**. El AuraSystem de
ASTRAKYN usa `AuraService` como registro canónico para Player/NPC/world units, refresca una única instancia por AuraId por
defecto, soporta stacking/charges explícitos, periodic tick definitions, immunity metadata y expone stacks/charges al HUD.
`BleedAura` ya consume snapshot ofensivo apply-time: conserva source combat stats/stat values/threat context aunque cambie
el gear/buff posterior, mientras defensas/rules/health del target siguen resolviéndose por tick. Auras sigue `PARTIAL` por
persistencia/restauración entre sesiones, políticas adicionales solo donde existan consumers y evidencia runtime completa.
`Death`, `Party` y `Quest` siguen `PARTIAL`: el código vivo no satisface todavía, respectivamente, graveyards/instance-PvP
respawn/wipe completos, continuidad cross-server/roles/markers, ni el conjunto de quest types/sharing/reward safety exigido
por la Constitución.

La pasada posterior cerró piezas que ya tienen consumidores reales. `ProcService` aplica un ICD centralizado al proc vivo
`DamageEcho`; `EnemyAgent` usa perfiles NPC con reach/aggro/swing/leash y ahora persigue server-side mediante
`PathfindingService:CreatePath()` + `Path:ComputeAsync()`, con recomputación rate-limited ante `Path.Blocked`, además de
evade/return/home reset. `Evade` marca al NPC no atacable, descarta threat fresco durante el retorno y repite el reset al
llegar a home antes de reactivar combate. `DeathService` captura corpse snapshot/timestamp/zona antes del estado terminal,
aplica una sola vez la penalización de muerte, serializa release frente a resurrection y `CharacterService` posee la
materialización manual con `CharacterAutoLoads=false` + `LoadCharacterAsync()`. El bootstrap de avatar ya no compite con
la carga persistente: `DataService.Loaded` publica profile-ready, `PlayerLifecycle` consume esa señal, una carga que termina
tras `PlayerRemoving` se descarta y respawn/revive mantienen el avatar aparcado hasta placement/estado autoritativos. `Revive`
y `BattleRevive` son consumers reales del mismo pipeline de abilities; normal revive exige party/misma zona/OOC y battle
revive conserva cooldown/resource autoritativos. Need/Greed rechaza `Need` no elegible y all-pass no adjudica silenciosamente.
Los contracts completos de graveyard, instance/PvP respawn y wipe siguen abiertos porque todavía no existe una política final
que los justifique.

La auditoría posterior cerró contratos que parecían completos y no lo estaban. `DamageEcho` no consume su ICD sobre
miss/dodge/full-zero events y ahora declara triggers explícitos (`AutoAttack`/`DirectDamage`) en su propio perfil. Los slows
que siguen siendo slows (`PinningShotSlow`, `TimeWarpSlow`) conservan un sink real de `MovementSpeed`; `ColdBind` y
`VoidSnare` dejaron de fingir root mediante slow y usan Root real, mientras `VoidTouch` usa Fear y `Hex` Disorient.
`ShieldBash` combina Interrupt explícito con Stun corto. Stun/Root/Fear/Disorient/Silence tienen grupos DR PvP vivos y
boss immunity sigue separada de Interrupt.

`IronWillBuff` ya no es solo reducción de daño: consume `AuraCharges=2` con metadata de inmunidad CC, expone charges al HUD
y la última carga expira por el pipeline canónico. Fear/Disorient que declaran `BreakOnDamage` se rompen al recibir daño
efectivo y refrescan inmediatamente action state. Los interrupts aplican lockout por la escuela realmente interrumpida.
NPC `Channel` usa ticks reales con presupuesto total acotado, revalidación por tick y cancelación por death/evade/CC/
Interrupt/lockout. Los channels jugables ya comparten ese timeline autoritativo y no entran en hooks `DirectDamage` sin
un trigger explícito. La pasada actual cierra además el primer snapshot ofensivo periódico (`BleedAura`) y separa la
elegibilidad defensiva por `Melee`/`Ranged`/`Spell`, de modo que magia/disparos no consumen Dodge/Parry/Block melee. El
trabajo pendiente se concentra en aura persistence, más reactive/encounter behaviors y proc events nuevos únicamente
donde existan consumers reales; no se introducen glancing/crushing/weapon-skill/deflect por imitación de WoW.

## Release readiness

El quality gate normal permite IDs de atlas vacíos mientras el arte no esté publicado; cualquier valor presente debe ser
un `rbxassetid://<digits>` válido. `--release` exige los tres IDs reales (`Ability`, `Item`, `Slot`) y por tanto sigue
bloqueado deliberadamente hasta recibir esos datos externos. No se introducen placeholders para simular readiness.

La evidencia local del snapshot actual es coherente: pasan todos los validators internos y la compilación sintáctica
Luau, el typecheck standalone de `tools/` termina con código 0, el require-graph productivo conserva únicamente los dos
entrypoints Rojo sin incoming y el build físico Rojo/Lune deserializa correctamente. No se han encontrado módulos productivos muertos que justifiquen
una eliminación adicional.

La última baseline pinned con `--verify` completamente verde sigue siendo la ejecución Windows de **v28** y se conserva
solo como evidencia histórica. El segundo `--verify` Windows de v35 aportado por el operador ya confirma validators,
StyLua, Selene, tooling y el grafo Roblox de producto; el único bloqueo restante estaba en el typecheck de tests de
`ContentConnectivity.spec`. Los intentos sobre `ability.Effects` no eran causales: la reproducción mínima del mismo error
con Luau-LSP 1.70.0 localizó el patrón exacto en `entry.AbilityIds or {}`. Este snapshot elimina esa unión mediante
narrowing explícito de `AbilityIds` antes de iterar. Hace falta repetir ese mismo gate para
convertir la corrección en evidencia pinned. TestService/failure injection sigue pendiente, por lo que este snapshot no se
etiqueta todavía como full-gate PASS.

## Frontera de trabajo actual

El snapshot tiene una base amplia de gameplay single-server, UI y catálogos, pero **no está cerca de production-ready**
según las definiciones de esta Constitución. La prioridad no es añadir más breadth visible, sino cerrar primero los
contratos P0 y eliminar implementaciones incompatibles con la arquitectura final.

Blockers observados directamente en este snapshot, por orden de riesgo:

1. **P0 multi-document transactions — cierre parcial.** `TransactionCoordinator` y `TransactionRecord` ya existen con
   journal durable, state machine, applied-steps idempotentes, participant receipts, compensation/review terminal y
   reconciliation de resultados inciertos. `TradeService`, `MailService` y `AuctionService` son consumers productivos.
   Auction añade listing durable por key, claims CAS para compra/cancel/expiry, receipts por perfil, replay/compensation y
   recovery; el índice/worker efímero global usa MemoryStore. Guild/settlement siguen siendo el P0 multi-documento
   principal y todavía escriben documentos compartidos fuera de este coordinator.
2. **P0 data safety de perfiles — implementación cerrada, evidencia runtime pendiente.** `DataService` adquiere lease
   durable con generación, usa `UpdateAsync`/revision CAS y `LastWriteId`, renueva/libera ownership, reconcilia writes
   inciertos con `GetAsync(... UseCache=false)`, quarantina raw inválido sin sustituirlo por un profile vacío y aplica
   migraciones registradas N→N+1 sobre clones validados. Producción ya no cae silenciosamente a memoria si falla el
   DataStore. Falta failure injection/TestService para elevar esta superficie a evidencia `TESTED`/`VALIDATED`.
3. **P0 security/operations.** Existe rate limiting y validación básica de keys de remotes, pero faltan RBAC, roles y
   capabilities de staff, staff console, durable audit, Ban API/moderation y schemas completos de tipo/rango/contexto.
4. **P0 platform/privacy/commerce.** No existen `PolicyService`, commerce/receipts, RTBF/erasure, support/moderation ni
   localization. Chat sí usa `TextChatService`, pero no implementa todavía el contrato global/cross-server/staff.
5. **P0 world/art contract.** `WorldService` invoca `WorldBuilder.build()` en runtime y `WorldTerrain` forma parte de ese
   camino. La Constitución exige que el contenido estático final de world/terrain/cities se produzca y bakee antes de
   publicación. Blender/art pipeline productivo y atlas publicados siguen abiertos.
6. **Cross-server e instances reales — base parcial.** `MemoryCoordinationService` ya usa `MemoryStoreService` con
   `UpdateAsync`, retry/backoff y TTL para el índice global de Auction y un lease de worker de expiración compartido entre
   servidores; la listing durable de DataStore sigue siendo la autoridad. Aún no hay `MessagingService`, `TeleportService`,
   presence global, topology de places, reserve/transfer ni coordinación cross-server general para party/guild/PvP/raids.
7. **Observability y performance incompletos.** `AnalyticsService` propio solo escribe funnels al logger; no existe
   integración de analytics/alerts de plataforma. Hay budgets y LOD, pero faltan baselines MicroProfiler, device matrix,
   memory/network measurements y soak a escala MMO.
8. **Evidencia runtime posterior a Lune.** El repositorio contiene 134 specs Luau vivos más 4 módulos de
   harness/helper. Todos los specs están registrados exactamente una vez y el gate `test-suite` impide specs huérfanos,
   referencias inexistentes, cuerpos de spec duplicados y helpers sin consumidor. En este snapshot pasan los validators
   internos, la compilación sintáctica Luau, el typecheck standalone de `tools/`, el require-graph productivo y el build
   físico/deserialización con Lune/Rojo.
   El segundo `--verify` Windows aportado por el operador ejecutó StyLua/Selene sin diagnósticos, dejó limpio el typecheck
   de tooling y producto y aisló un único TypeError en `ContentConnectivity.spec`. Un rerun adicional demostró que el
   recorrido indexado y el helper de `ability.Effects` seguían fallando porque no eran la causa. La reproducción mínima
   identificó `entry.AbilityIds or {}` como origen exacto de la unión `{ string } | {}`; este snapshot hace narrowing
   explícito antes de iterar, sin casts/suppressions, pero el rerun pinned sigue pendiente. También faltan una ejecución TestService completa, failure injection y la
   device/network matrix. La existencia de specs no eleva por sí sola ningún dominio a `TESTED`.
9. **Package manager.** Wally fue evaluado y se mantiene deliberadamente fuera mientras no exista una dependencia Luau
   externa aprobada. El primer package real obliga a reevaluar package manager vigente, lockfile, realms, Rojo y CI.

## Auditoría de honestidad de integración — 2026-09-26

Se revisaron los **101 dominios** de la matriz y, con inspección de código/definitions/consumers sobre los **37 que estaban
marcados `INTEGRATED`**, se aplicó de forma estricta la jerarquía constitucional `PARTIAL → IMPLEMENTED → INTEGRATED`.
El resultado corrige una inflación de madurez: **35 dominios bajan de `INTEGRATED` a `PARTIAL`** porque conservan huecos
funcionales o de integración exigidos por su propio contrato, no porque falte simplemente evidencia runtime. Permanecen
`INTEGRATED` únicamente **Combat y Threat**.

Criterio obligatorio desde esta pasada: un catálogo, service, remote, UI, spec o consumer vivo demuestra wiring, pero no
demuestra completitud. Si falta una operación/lifecycle/estado/definition/permission/failure path requerida por
`CONSTITUTION.md`, el dominio queda como máximo `PARTIAL`. La falta exclusiva de TestService, soak, profiling, device
matrix o acceptance evidence se refleja en los niveles posteriores (`TESTED`/`VALIDATED`/`PRODUCTION_READY`) y no se usa
para degradar artificialmente una integración funcionalmente completa.

AzerothCore 3.3.5a se usa como **referencia estructural de madurez, no como código ni balance a copiar**. La comparación
se centra en fronteras que evitan sistemas planos: estados/lifecycles explícitos, conditions y eligibility, templates
separados de instances/ownership, reglas de grupo/encounter, persistencia/recovery, data-driven definitions y extension
hooks. ASTRAKYN debe expresar profundidad equivalente adaptada a Roblox y a su diseño propio antes de promover un dominio;
la mera cantidad de entries o de archivos no constituye profundidad.

Hallazgos de máxima prioridad de esta auditoría: roster sin tombstone/restore; creation/races/classes/specs/talents/loadouts
con definitions más estrechas que su contrato; progression sin `ProgressionDefinition`; abilities con targeting y trainer
learning incompletos; NPC/world/zones/POIs/map y bosses sin el lifecycle/data model final; PvP single-server y sin security
contract completo; factions/reputation planos; item/inventory/equipment sin stack/owner/presentation/proc contract completo;
loot sin adjudicación durable; vendors sin contexto autoritativo de NPC; currencies sin source/sink contract cerrado; mail
contrario al mailbox estructurado separado; crafting recipe schema reducido; world events locales; UI sin el input/accessibility
contract; persistence global incompleta y migration sin staff recovery. Trade conserva journal/recovery durable, pero su gameplay
actual es una oferta unidireccional y todavía no implementa la negociación bilateral, `BOTH LOCK` ni entrega recíproca exigidas
por §30. La segunda pasada sobre los estados altos encontró además stats con sinks pero sin source real, target ops del macro
DSL sin semántica/validación cerrada, `AuctionListingRecord.Quantity` fijado siempre a 1 mientras inventory carece de stacks,
y caches/jerarquías cliente que todavía no son streaming-safe ante descendants que entran/salen dinámicamente.

Snapshot de madurez de los 101 dominios obligatorios tras la auditoría de profundidad: **2 INTEGRATED**,
**0 IMPLEMENTED**, **84 PARTIAL**, **3 BROKEN**, **12 NOT_PRESENT**, **0 TESTED**, **0 VALIDATED** y
**0 PRODUCTION_READY**. Los estados altos no se infieren por cantidad de código: `TESTED`/`VALIDATED` requieren
evidencia ejecutada y `PRODUCTION_READY` requiere además los gates operativos, de seguridad, datos, arte y plataforma.

---

## Feature matrix completa

Este documento es el inventario canónico del estado funcional de ASTRAKYN Online. No es una lista de deseos ni una
estimación de porcentaje. Un archivo, catálogo o spec existente no convierte por sí solo un dominio en terminado.

Estados permitidos:

- `NOT_PRESENT`: no existe una implementación utilizable del contrato objetivo.
- `BROKEN`: existe implementación, pero contiene un defecto incompatible con producción.
- `PARTIAL`: existe una base relevante, pero faltan contratos, integración o comportamiento requerido.
- `IMPLEMENTED`: todo el comportamiento normativo del dominio existe y funciona; todavía puede faltar evidencia posterior.
- `INTEGRATED`: presupone `IMPLEMENTED` y además funciona con data/network/UI/dependencies/permissions/failure handling aplicables; wiring parcial nunca basta.
- `TESTED`: pruebas relevantes fueron ejecutadas con éxito.
- `VALIDATED`: acceptance criteria y validadores aplicables fueron ejecutados con éxito.
- `PRODUCTION_READY`: cumple implementación, integración, seguridad, datos, rendimiento, UX/arte, pruebas,
  documentación, observabilidad y recuperación aplicables.

| Dominio | Estado | Evidencia actual | Bloqueo principal hacia producción |
| --- | --- | --- | --- |
| Account | `PARTIAL` | `DataService`, profile schema y roster por `UserId`. | Faltan account-level policy/entitlements, Ban API, RTBF y operaciones de cuenta seguras. |
| Character | `PARTIAL` | `CharacterService` mantiene lifecycle manual, perfil activo/roster, sheet push y materialización server-owned. | El agregado constitucional sigue incompleto: faltan exploration state explícito y los contratos pendientes de roster/creation; no puede heredar `INTEGRATED` de un wiring parcial. |
| Roster | `PARTIAL` | Create/select/delete, roster persistido, remotes y lobby UI existen y tienen spec. | `Delete` elimina físicamente el personaje; no existen tombstone ni restore/recovery policy, y `Create` puede conservar un `CharacterId` previo tras reset. §68 exige restore, tombstone y no reutilización de IDs. |
| Creation | `PARTIAL` | `CreateScreen`/`IdentityPicker` llegan a `CharacterService:Create`; servidor valida race/archetype/spec/name y deriva origin. | El contrato de creación no modela appearance, body, face, hair, skin, eyes, markings ni voice/profile; origin tampoco es una elección/definition completa. §69 sigue abierto. |
| Races | `PARTIAL` | `RaceCatalog` aporta identidad, un stat modifier, racial ability y homeland/origin canónico. | `RaceDefinition` no controla body, rig family, customization, culture, faction, animation profile ni architecture/lore hooks requeridos por §70. |
| Classes | `PARTIAL` | `ArchetypeCatalog` define role, primary stats, resource bias, specializations, abilities y signature ability con consumers. | Faltan equipment rules/profiles y progression propios del archetype; `ResourceBias` no equivale al comportamiento completo de resource exigido por §71. |
| Specializations | `PARTIAL` | `SpecializationCatalog` conecta cada spec con extra abilities y un stat bonus. | La spec todavía no modela role mutation, passives, resource behavior, talent ownership ni gameplay identity de §72; es una capa de abilities+stat demasiado plana. |
| Talents | `PARTIAL` | `TalentTreeCatalog`, `ArchetypeTalentCatalog`, `TalentService`, remotes y UI existen. | `TalentService:Learn` solo valida class/points/duplicado: no aplica tiers/tree points, ranks, prerequisites, mutual exclusions ni grants de active abilities/passives. §73 no está implementado completamente. |
| Loadouts | `PARTIAL` | `LoadoutService` guarda/restaura equipment snapshot, talents, masteries y action bars con validación de equipment. | `LoadoutSave` carece de specialization, equipment-set reference y keybind profile requeridos por §74; la activación no representa todavía el loadout contractual completo. |
| Stats | `PARTIAL` | El motor, grafo, formulas, caps/DR, UI exposure y muchos consumers son amplios; `CatalogLiveSinks.spec` mantiene un mapa de sinks para los StatIds enabled. | §76 exige source + consumer por StatId. La auditoría de producers detecta 17 leaf stats con base 0, sin inputs/incoming edge y sin fuente declarativa externa en `src` (`CritSuppression`, `BlockValue`, `LifeSteal`, `EnergyDrain`, `ResourceOnHit`, `ResourceOnCrit`, `ResourceOnKill`, `ControlDurationReduction`, `DispelPower`, `DispelResistance`, `OverhealEfficiency`, `ShieldCapacity`, `ShieldRecharge`, `ShieldOvercharge`, `CarryCapacity`, `MachineHeat`, `AbilityCostReduction`). Tener sink no evita que sean stats fantasma mientras nadie pueda producirlos. |
| Progression | `PARTIAL` | `ProgressionService` maneja XP/level/talent points/rest XP y progression UI/consumers. | No existe `ProgressionDefinition` como fuente única de thresholds ni catálogo de XP sources; `RewardResolver.xpForLevel()` contiene la curva directamente. §75 sigue abierto. |
| Abilities | `PARTIAL` | `AbilityCatalog` tiene consumers vivos y ejecución server-authoritative; `KnownAbilityService`, spellbook/action bars y combat handlers están conectados. | La autoridad trainer/learning exigida por §77 sigue ausente y el targeting contractual de §79 no está completo: `TargetType` no modela focus, raid, line, projectile ni AoE explícito. Wiring no compensa estos huecos funcionales. |
| Combat | `INTEGRATED` | `CombatService` mantiene abilities/autoattack server-authoritative, engagement/action state separados, clocks main/off, movement preflight, cast pushback, school lockouts y channels Player/NPC; `DamageResolver` deriva `Melee`/`Ranged`/`Spell` y `DefenseGraph` reserva Dodge/Parry/Block al contacto Melee actual. | La implementación contractual observada está integrada; faltan soak/performance/security runtime y ejecución completa del quality gate para niveles de evidencia superiores. |
| Auras | `PARTIAL` | `AuraService` unifica refresh/stacking/periodicidad/dispel/charges/immunity/BreakOnDamage; `IronWill`, `PaleEvade` y `Rally` consumen charges, y `BleedAura` consume `PeriodicSnapshot=Apply` para congelar la ofensiva de fuente mientras el target se resuelve por tick. | Falta persistence/restoration semantics completa, más snapshot/charge consumers solo donde el diseño los requiera y evidencia runtime ejecutada en engine. |
| CC | `PARTIAL` | Stun/Root/Fear/Disorient/Silence tienen consumers/DR; Fear/Root poseen behavior real y Lash/Hammerfall consumen Pull/Knockback físico con impulse server-side y anti-cheat acceptance acotada. | Falta ampliar control families/encounters, tuning PvP y evidencia runtime multi-player/física vigente. |
| Threat | `INTEGRATED` | `ThreatService` es PvE/NPC-only y cubre sticky 110/130, taunt/fixate, healing threat, cleanup/prune; `EnemyAgent` añade asistencia social profile-driven, same-kind/zone, one-shot y no recursiva, conservando leash propio. | La implementación contractual observada está integrada; faltan ejecución runtime vigente y soak de encounters sociales a escala para niveles de evidencia superiores. |
| Death | `PARTIAL` | `DeathService` centraliza death record/corpse snapshot, penalización única, release delay y claim de resurrection; `CharacterService` materializa manualmente respawn/revive y `Revive`/`BattleRevive` consumen la misma puerta con party/zona/combat checks. | Faltan graveyards dedicados, instance/PvP respawn policy completa, wipe handling y evidencia runtime multi-player del lifecycle. |
| Macros | `PARTIAL` | Lexer/parser/compiler/runtime, persistencia y UI existen; ABILITY y START/STOPATTACK terminan en `CombatService`. | El lexer expone `TARGET`/`FOCUS`/`SELF`/`PARTY`, pero `MacroValidator` no valida/contabiliza esos comandos y `MacroRuntime` los colapsa al mismo `Target` usando `Args[1]`; `SELF`/`PARTY`/`FOCUS` no tienen semántica real y `CombatService:SetTarget` solo almacena el id. §85 exige que macro no cree una ruta de autoridad paralela ni target arbitrario. |
| NPCs | `PARTIAL` | NPCs de servicio/hostiles, POI links, combat profiles, ability kits y loot tienen consumers runtime. | El NPC shippable de §86-87 sigue incompleto: trainer authority falta y no hay contrato productivo completo de rig/body/mesh/materials/animations/attachments/hit-root/LOD/visual profile. |
| AI | `PARTIAL` | `EnemyAgent` consume perfiles diferenciados y kits por spawn, rota abilities listas con cooldown canónico/fallback strike, además de threat/chase/leash/evade/social assistance y Cast/Channel autoritativos. | Separar melee reach de preferred cast/ranged range, añadir targeting/roles/FSM MMO (wander/patrol/investigate/reposition/retreat/healer-support) y validar pathfinding/escala runtime. |
| Quest | `PARTIAL` | `QuestService`, catálogos, event reactors y log/tracker de cliente cubren objetivos simples como kill/dummy/dungeon/gather/capital. | El schema sigue basado en un `Objective` string y faltan varios quest types, sharing policy formal, composite objectives y reward safety durable end-to-end. |
| Narrative | `PARTIAL` | Existe lore/presentación y texto en quests/identidades. | No hay motor narrativo ni continuidad/estado de historia conforme al target. |
| Dialogue | `NOT_PRESENT` | No existe sistema/catalog de diálogo productivo. | Implementar diálogo seguro/localizable e integración con quests/narrativa. |
| Cinematics | `PARTIAL` | `CinematicDirector` existe y se invoca desde world client. | Actualmente solo aplica lighting; faltan timeline/camera/audio/subtitles y contenido real. |
| World | `BROKEN` | `WorldService` y `WorldBuilder` generan mundo y spawns en runtime. | La Constitución prohíbe reconstruir contenido estático final como blockout runtime; debe bakearse/publicarse. |
| Continents | `PARTIAL` | `ContinentCatalog` tiene un continente canónico y está consumido por zone/world state. | La definition es mínima y su dependencia `World` permanece `BROKEN` frente al pipeline bakeado final; un dominio no puede ser `INTEGRATED` sobre una dependencia productiva incompatible. |
| Zones | `PARTIAL` | `ZoneCatalog` alimenta enter/travel, environment, adjacency, map, PvP mode y world geometry. | `ZoneDefinition` no controla biome, culture, danger/level, factions, quest arc, NPC pools, resources, dungeons, events, weather, audio ni landmark como exige §133. |
| Biomes | `PARTIAL` | `EcologyCatalog` y `ZoneEnvironmentResolver` modelan ecología/entorno. | Falta bioma productivo completo, ecotones, arte y validación visual. |
| Terrain | `BROKEN` | `WorldTerrain` participa en `WorldBuilder` runtime. | El terrain final debe producirse/bakearse como contenido productivo, no reconstruirse por servidor. |
| Cities | `PARTIAL` | Hay settlements/POIs/world kits que representan hubs. | Faltan ciudades productivas bakeadas, art pass, navegación y validación de contenido. |
| Roads | `PARTIAL` | World building contiene geometría/paths de conexión. | Falta red vial productiva bakeada y validación world/art. |
| POIs | `PARTIAL` | `PoiCatalog` y `WorldPoi` conectan servicios, dungeons/raid, gather, bosses y NPC LinkIds con runtime. | La definition solo expresa kind/posición/label/link; no modela explícitamente purpose, visual hook, gameplay contract, navigation role y narrative role de §137, y varios consumers dependen de subsistemas aún parciales. |
| Exploration | `PARTIAL` | World, POIs, map, zones y travel forman una base explorable. | Falta loop de exploración completo, rewards/discovery y world content final. |
| Map | `PARTIAL` | World map/minimap/compass/zone splash muestran zones y POIs y permiten navegación adyacente. | §164 exige overlays/estado de continents, quests, party, transports, instances y discovery, además de minimap objectives/tracking; la implementación actual no cubre esa superficie completa. |
| Travel | `PARTIAL` | `TravelRules`, gate bind y teleports dentro del mismo place. | No existe `TeleportService`/transfer de instancia/multi-place productivo. |
| Mounts | `NOT_PRESENT` | No hay sistema de mounts; `WindowMount` es montaje de UI, no gameplay. | Implementar colección, summon, movement, assets y seguridad. |
| Companions | `NOT_PRESENT` | No hay servicio/catalog/runtime de companions. | Implementar lifecycle, AI, persistencia, UI y contenido. |
| Settlements | `PARTIAL` | `SettlementService`, claims, structures y UI stub están cableados. | Persistencia/transacciones y world art final no cumplen todavía los contratos P0. |
| Construction | `PARTIAL` | `ConstructionService`, validators/resolvers, voxels y remotes existen. | Faltan autoridad/persistencia transaccional, art pipeline y pruebas de abuso/escala. |
| Party | `PARTIAL` | `PartyService`, invites/ready/loot method, UI/frames/chat y kill credit/shared XP por misma zona + reward range server-side funcionan dentro del servidor actual. | La Constitución exige continuidad/cross-server awareness, roles/markers/recovery de instancia y transfer de party; esas piezas aún no existen. |
| Raid Groups | `PARTIAL` | Raid/party paths incluyen ready/loot y `RaidService`. | No existe gestión robusta de raid group multi-party conforme al target. |
| Group Finder | `NOT_PRESENT` | No existe servicio/UI de group finder. | Implementar listing/search/eligibility/moderation y conexión con matchmaking. |
| Matchmaking | `PARTIAL` | `MatchmakingService` tiene colas Echo/Warfield en memoria. | Es single-server; faltan MemoryStore/native signals, teleport/reserved server y failure recovery. |
| Instances | `PARTIAL` | Dungeon/Raid pueden entrar en contextos instanciados lógicos dentro del runtime. | No hay `TeleportService`, reserved servers, transfer contract ni topology real de places. |
| Dungeons | `PARTIAL` | `DungeonService`, `DungeonCatalog`, encounters y cliente están presentes. | No son instancias multi-server reales; faltan transfer/failure/lockout productivos y runtime tests. |
| Raids | `PARTIAL` | `RaidService`, `RaidCatalog`, bosses y lockout paths existen. | Faltan raid groups completos, instance runtime real, scaling/ops y evidencia ejecutada. |
| Bosses | `PARTIAL` | `BossCatalog`, `BossService`, spawning, phase numérica, enrage, stat checks y loot están conectados. | No existe el encounter lifecycle de §100 ni el framework de mechanics de §101: faltan estados IDLE/ARMED/ACTIVE/transition/victory/wipe/reset y mechanics data-driven como adds, interrupts, positioning, soak, hazards/arena changes. |
| PvP | `PARTIAL` | `PvPService` cubre flags, duels, MMR, deserter y rewards; hay queue/UI paths. | Matchmaking usa colas process-local y fallback Echo; faltan battleground/arena lifecycle real, season/leaderboards y las defensas §104 contra AFK farming, win trading, repeat-opponent abuse y disconnect/duplicate rewards. |
| Battlegrounds | `PARTIAL` | Existe ruleset `Battleground` y cola Warfield. | No hay battleground instance/topology/match lifecycle cross-server completo. |
| Factions | `PARTIAL` | Reputation y afinidad de facción aparecen en stats/rewards. | Falta modelo de facciones completo, membership, hostility y contenido. |
| Reputation | `PARTIAL` | `ReputationService` persiste valores por faction y aplica scaling por stats; UI puede mostrar reputación. | No existen `FactionDefinition`/`ReputationDefinition` con relationships, territory, NPC attitude, services, levels, sources/sinks, unlockables, vendors y quests de §105. |
| Items | `PARTIAL` | `ItemCatalog` posee templates, stats, quality, slots, binding, sockets, sets, affixes, trinkets y acquisition connectivity. | `ItemDefinition` carece de stack model/sell value/craft metadata y category/requirements son incompletos; `ItemSave` no representa quantity ni owner state explícito. §107 todavía no está completo. |
| Inventory | `PARTIAL` | `InventoryService` gestiona unique instances, bags/bank, move, consume, equip paths y transfer/restore. | No existen operaciones split/merge y el modelo de item no tiene quantity/stack state; §106 exige ambos además del ownership completo en todos los flujos económicos. |
| Equipment | `PARTIAL` | `EquipmentService` valida slots/instances/level/durability/unique/dual-wield y reconstruye stats, sets, gems, enchants y weapon damage. | Equip solo registra `AppearanceId` como colección; no aplica appearance/avatar ni weapon animation set, y no existe un pipeline general de abilities/procs concedidos por equipment como exige §108. |
| Loot | `PARTIAL` | `LootService` cubre personal/NeedGreed/Pass con Need eligibility, prioridad y timeout server-side. | La elegibilidad no queda registrada por Encounter y la adjudicación/pending loot no es durable e idempotente frente a reconnect/cross-server; §109 exige esas garantías. |
| Vendors | `PARTIAL` | `VendorCatalog`, price resolver, buy/sell/buyback y UI están conectados y el cliente no envía el precio. | La compra remota solo aporta `templateId`: servidor no autoriza vendor/NPC/contexto/proximidad ni inventario por vendor. El wiring de POI es presentación, no permiso/contexto autoritativo de integración; stock/restock tampoco tiene lifecycle propio. |
| Currencies | `PARTIAL` | Perfil/economy manejan Astral, Honor y Conquest con grants/spends y analytics básicos. | No hay CurrencyDefinition/source-sink contract ni ledger durable; `EconomyService` acepta IDs de currency arbitrarios y Conquest tiene source vivo sin sink observado. §111 prohíbe monedas sin propósito económico cerrado. |
| Trade | `PARTIAL` | `TradeService` tiene una base transaccional sólida (`TransactionCoordinator`, journal durable, reservations/receipts, compensation y recovery idempotente), pero el contrato gameplay sigue siendo una oferta unidireccional de un item/Astral aceptada por el receptor. | §30 exige `REQUEST → NEGOTIATION → BOTH LOCK → ... → APPLY RECIPROCAL DELIVERY`: faltan negociación bilateral, ofertas de ambas partes, lock/confirmación de ambos lados y entrega recíproca antes de poder promoverlo a `IMPLEMENTED`/`INTEGRATED`. |
| Auction | `PARTIAL` | `AuctionService` tiene truth durable, CAS claim, transaction journal, escrow/return, fee, cancel/expire y un índice MemoryStore con lease de expiración distribuido. | La listing contractual incluye `Quantity`, pero `AuctionListingRecord.new()` y decode la fuerzan a `1`; `List()` solo acepta una instance y la dependencia Inventory todavía no modela quantity/split/merge. Esa dimensión está cableada como campo pero no implementada, así que §31 no está completo todavía. |
| Mail | `PARTIAL` | `MailService` ya usa transaction journal/receipts/escrow/recovery para attachments/currency y tiene UI. | Viola §32: mailbox sigue dentro de `PlayerProfile`/`CharacterSave` en vez de `ASTRAKYN_Mailboxes`, y player→player acepta/persiste `Body` libre en lugar de `MessageTemplateId` + parámetros estructurados. |
| Professions | `PARTIAL` | Cinco profesiones vivas (Mining, Smithing, Cooking, Alchemy, Latticecraft) tienen stat contract, recipes y persistencia/roster/UI; crafting valida ProfessionId. | Falta progression por rangos, tools/stations/specializations/gathering breadth y balance runtime. |
| Gathering | `PARTIAL` | `MiningResolver` y `GatherNode` cubren una ruta de gathering. | Faltan gathering professions/nodes completos, respawn/ecología y persistence robusta. |
| Crafting | `PARTIAL` | `CraftingService` conecta recipes, professions, stat checks/quality resolver, materials/currency y output grants. | `RecipeDefinition` solo admite un material y un output y no modela inputs/outputs generales, station, requirements ni quality rules como definition data de §113. |
| Guilds | `BROKEN` | `GuildService`, ledger/research/bank/structures y UI/social están presentes. | Los perfiles ya tienen session safety, pero guild registry + perfiles/bank siguen sin `TransactionCoordinator`; P0 multi-documento. |
| Achievements | `PARTIAL` | `AchievementCatalog`, profile/UI y sheet fields existen. | No hay servicio de achievements completo ni BadgeService/plataforma cuando corresponda. |
| Collections | `PARTIAL` | `CollectionCatalog`, profile y UI collections existen. | Falta pipeline completo de adquisición/progreso/rewards y contenido. |
| Appearance | `PARTIAL` | `CosmeticCatalog`, identity presentation y appearance fields existen. | No hay transmog/appearance service completo, preview/equip ownership ni asset pipeline final. |
| Endgame | `PARTIAL` | Raids, lockouts, leaderboards, gear score y live content dan una base. | Falta loop endgame coherente, seasons/rewards/content y operación productiva. |
| World Events | `PARTIAL` | `WorldEventService` rota eventos, aplica modifiers y replica state/UI dentro del servidor. | La rotación/estado es process-local; no usa `ASTRAKYN_WorldState` ni coordinación global/versioned/audited/recoverable. §123 y el target MMO cross-server siguen abiertos. |
| LiveOps | `PARTIAL` | `LiveOpsService`, `LiveOpsCatalog` y runtime flags existen. | No hay Experience Configs/ops rollout/rollback ni orchestration cross-server. |
| Chat | `PARTIAL` | `ChatService` usa `TextChatService`, canales party/guild/zone/whisper y bloqueo. | Faltan global/cross-server chat, staff moderation y validación completa de policy/ops. |
| Moderation | `NOT_PRESENT` | No existe servicio de moderación/Ban API ni workflow de appeals. | Implementar Ban API, enforcement, audit, tooling y policy vigente. |
| Support Tickets | `NOT_PRESENT` | No existe sistema de feedback/tickets productivo. | Implementar intake, privacy, triage, audit y staff permissions. |
| RBAC | `NOT_PRESENT` | No existe modelo de roles/capabilities/permissions productivo. | Implementar namespace, bootstrap, high-risk actions y audit conforme a Constitución. |
| Staff Console | `NOT_PRESENT` | No existe consola staff productiva. | Implementar UI/commands cerrados por RBAC; sin Lua console. |
| UI | `PARTIAL` | Existe una superficie UI amplia: HUD, windows, inventory, social, progression, economy, map y theme system. | No hay adopción del Input Action System contractual ni consumers de `PreferredTextSize`, `PreferredTransparency` o `ReducedMotionEnabled`; faltan requisitos de §161-163 y partes del HUD/map, por lo que la UI global no está integrada completamente. |
| Accessibility | `PARTIAL` | Hay UI scale y `reduceMotion` en theme/settings. | Faltan navegación/focus/gamepad/touch audit, contraste/text scaling y pruebas de accesibilidad. |
| Input | `PARTIAL` | Hay `UserInputService`, intent/interacción y keybind paths. | Falta Input Action System moderno y cobertura real móvil/gamepad/cross-platform. |
| Localization | `NOT_PRESENT` | No hay `LocalizationService`/translator/tablas de localización. | Externalizar todo texto de jugador y añadir pipeline/localization QA. |
| Audio | `PARTIAL` | `SfxListener` existe. | Faltan sistema de audio moderno, buses/wires, contenido, settings y budget/streaming. |
| Animation | `PARTIAL` | `AnimationDirector` existe. | Faltan rigs/avatar setup, animation graph/content y pipeline productivo. |
| VFX | `PARTIAL` | `VfxListener` y `VfxBudgetService` existen. | Faltan assets VFX finales, pooling/LOD/perf validation y art gate. |
| Lighting | `PARTIAL` | `LightingDirector` + `LightingCatalog` y zone/cinematic hooks. | Falta lighting productivo por world, device/perf validation y art pass. |
| Art Pipeline | `PARTIAL` | Existen atlas manifests, mesh presentation/world kit code y asset validation básica. | Falta pipeline DCC→import→review→publish con provenance, budgets y production art gate. |
| Blender | `NOT_PRESENT` | No hay tooling/export pipeline Blender en el repositorio. | Implementar integración DCC principal y validaciones/export contracts cuando se produzca arte. |
| Assets | `PARTIAL` | Atlas manifest, icon/mesh/material catalogs y asset IDs centralizados. | Atlas publicado sigue vacío y faltan ownership/provenance/permissions y assets productivos finales. |
| Persistence | `PARTIAL` | `DataService`/`StoreAdapter` implementan lease, revision CAS, `LastWriteId`, reconciliation fresh-read, quarantine y fail-closed para player profiles; transactions/auction tienen stores propios. | El contrato §22 exige el conjunto fijo de stores y agregados; `ASTRAKYN_Mailboxes` no existe como mailbox separado y Guild/World/Staff/Support persistence contractual sigue incompleta. El core de profile es fuerte, el dominio global no. |
| Transactions | `PARTIAL` | `TransactionCoordinator`/`TransactionRecord` aportan journal durable, state machine, locks locales, receipts participant-safe, applied steps idempotentes, compensation/review y fresh-read reconciliation; trade, mail y auction son consumers productivos. | Extender el mismo contrato a guild/settlement y otros movimientos multi-documento; convertir locks/recovery generales en primitives cross-server cuando el dominio lo requiera y añadir ops + injection tests. |
| Cross-server | `PARTIAL` | `MemoryCoordinationService` usa MemoryStore sorted/hash maps con `UpdateAsync`, TTL, retry/backoff; Auction consume índice global y lease único de expiración cross-server. | Faltan MessagingService, presence, topology/TeleportService, coordinación general de transactions/party/guild/PvP/raids, sharding/quotas observables y failure-injection real. |
| Networking | `PARTIAL` | `RemoteCatalog`, `NetworkRegistry`, handlers y ClientRemotes están cableados. | Schema genérico valida keys pero no tipos/rangos/contexto completos; falta versioning/cross-server protocol. |
| Security | `PARTIAL` | `SecurityService` aplica rate limit, forbidden authority keys y suspicion. | Faltan RBAC, durable audit, Ban API, typed/context schemas y revisión integral de trust boundaries. |
| Anti-exploit | `PARTIAL` | `MovementGuardService`, server-side combat/economy paths y suspicion existen. | Faltan ownership/physics hardening, detection/telemetry y adversarial/runtime testing. |
| Streaming | `PARTIAL` | `default.project.json` fija correctamente streaming nativo (`Improved`, `PauseOutsideLoadedArea`, 64/1024, `Opportunistic`) y existen capas de presence/LOD. | §167 exige código streaming-safe además de properties. `WorldLodController`/`WorldPresenceController` construyen caches de descendants sin subscription al streaming-in/out (LOD ni siquiera expone rebuild por WorldState), y `VoxelStateController` crea localmente `World/Kynfall/zone` cuando la jerarquía no está disponible. Con `World` además `BROKEN`, no hay evidencia de disponibilidad/reconciliación correcta de contenido que aparece después. |
| Performance | `PARTIAL` | `PerformanceBudgets`, LOD/presence y VFX budget existen. | Faltan MicroProfiler baselines, device matrix, memory/network budgets medidos y soak. |
| Analytics | `PARTIAL` | `AnalyticsService` propio genera sessions/funnels pero solo escribe a `Logger`. | Integrar AnalyticsService/plataforma, schemas, privacy y dashboards/alerts productivos. |
| Commerce | `NOT_PRESENT` | No existe MarketplaceService/receipts/PolicyService/Managed Pricing. | Implementar solo con policy vigente, server receipts/idempotency y entitlements seguros. |
| Privacy | `NOT_PRESENT` | No existe RTBF/erasure workflow ni privacy operations. | Implementar borrado/export/retención/PII policy y Open Cloud/ops conforme a Roblox. |
| Testing | `PARTIAL` | 134 specs y 4 módulos de harness/helper cubren una superficie amplia y existen contratos de persistencia/transacciones con fault injection local, pero el propio dominio de testing no satisface todavía toda la pirámide constitucional. | §§170 y 190-193 exigen runtime/multi-client, cross-server, device/network/performance evidence y failure injection transaccional incluyendo ownership en distinto servidor; esos componentes siguen pendientes, por lo que `IMPLEMENTED` era una sobreclasificación. |
| Migration | `PARTIAL` | `MigrationRegistry` ejecuta N→N+1 sobre clone, valida schema y `DataService` quarantina raw inválido/future schema. | §24-25 exige `ENABLE STAFF RECOVERY` con inspect/compare versions/approved repair/restore/retry; RBAC/staff recovery todavía no existe, así que el failure path contractual no está integrado. |
| Release | `PARTIAL` | CI/build/verify/validators están definidos; el último Windows `--verify` confirma validators, StyLua, Selene, tooling y producto, y este snapshot corrige el único TypeError restante del grafo de tests. El build físico/deserialización con Lune 0.10.5 + Rojo 7.7.0 sigue verde. | Falta rerun pinned del `--verify` tras esta corrección, TestService/failure injection, atlas IDs reales y los demás P0 antes de release productivo. |
| Recovery | `PARTIAL` | Perfil dispone de quarantine/raw retention + write reconciliation; trade, mail y auction disponen de journal/receipts/replay, compensation/review y restore/retry. Auction evita compensar cuando un write + fresh-read dejan el resultado incierto. | Falta recovery worker general/cross-server, UI/GM tooling, audit durable, replay/compensation para guild/settlement y runbooks operativos. |

## Reglas de actualización de esta matriz

- Un dominio solo sube de estado cuando existe evidencia nueva para ese nivel; añadir archivos o specs no ejecutadas no
  equivale a `TESTED`.
- Si aparece un defecto que invalida seguridad, datos, policy o el contrato productivo, el dominio puede bajar a
  `BROKEN` aunque tenga mucha implementación.
- Los blockers concretos se mantienen aquí; `CONSTITUTION.md` conserva únicamente el contrato normativo.
- Cualquier cambio que cierre o abra un blocker P0 actualiza esta tabla y la sección **Frontera de trabajo actual** en la
  misma entrega.
