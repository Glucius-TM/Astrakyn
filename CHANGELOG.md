# Changelog

## 2026-09-26 — Feature-maturity honesty audit against the live contract and AzerothCore depth

- Audited all 101 maturity rows and inspected the live code/definitions/consumers behind every one of the 37 domains previously marked `INTEGRATED`; corrected 35 inflated rows to `PARTIAL`, leaving only Combat and Threat at `INTEGRATED` on this evidence layer. A second-pass review additionally demoted Trade (no bilateral negotiation/`BOTH LOCK`/reciprocal delivery), Stats (source-less zero-base leaf stats), Macros (unclosed TARGET/FOCUS/SELF/PARTY semantics), Auction (`Quantity` hard-coded to 1 while stack semantics are absent) and Streaming (configuration is correct but client caches/availability paths are not fully streaming-safe).
- Strengthened §§228-229 so maturity is explicitly cumulative: `INTEGRATED` presupposes a complete `IMPLEMENTED` contract and cannot be claimed merely because a service/catalog/UI/remote is wired. Missing runtime evidence alone blocks later evidence levels instead of incorrectly demoting an otherwise complete integration. The same cumulative rule also demoted Testing from `IMPLEMENTED` to `PARTIAL`: repository specs exist, but the testing domain itself still lacks required runtime/multi-client, cross-server, device/network/performance and full transaction failure-injection coverage.
- Recorded concrete blockers rather than generic “needs validation” text: roster tombstones/restore, character customization and identity depth, talent graph enforcement, progression definitions, full ability targeting/trainer authority, encounter state machines, PvP security/cross-server lifecycle, rich faction/item/inventory/equipment semantics, durable loot, vendor context, currency source/sinks, structured separate mailboxes, richer crafting recipes, global world events, accessibility/input, fixed persistence stores and staff-assisted migration recovery.
- Used current AzerothCore 3.3.5a upstream architecture as a structural maturity reference (state/eligibility/ownership/lifecycle/recovery/data-driven extension surfaces) without copying GPL implementation, WoW balance values or treating source LOC as a quality metric.

## 2026-09-25 — v35 optional-array iterator typecheck closure

- Consumed the fourth operator-provided Windows `--verify`. Validators, StyLua, Selene, tooling typecheck and Roblox product typecheck remain green; the same test diagnostic still pointed into `ContentConnectivity.spec`.
- Reproduced the exact Luau-LSP 1.70.0 diagnostic in isolation: generalized iteration over `optionalStringArray or {}` produces `Cannot call a value of type {string} in union: {string} | {| |}`. The actual source was `entry.AbilityIds or {}`, not `ability.Effects`; the earlier effects-loop changes were therefore non-causal.
- Replaced the optional-array fallback iteration with explicit nil narrowing before iterating `AbilityIds`. This preserves the connectivity assertion while eliminating the `{ string } | {}` iterator union without casts, `any`, suppressions or weakened checks.
- A fresh pinned Windows `lune run tools/build/build_place.luau --verify` remains the authority for confirming product+tests fully green.

## 2026-09-25 — v35 ContentConnectivity typed-boundary closure

- Consumed the third operator-provided Windows `--verify` result. Validators, StyLua, Selene, tooling typecheck and Roblox product typecheck remain green; the same single test diagnostic persisted at the numeric `#effects` traversal in `ContentConnectivity.spec`.
- Replaced the traversal with a local helper whose `effectIds` parameter is explicitly `{ string }`. The catalog boundary is now resolved once by the function contract, while the helper body iterates a concrete array type; no cast, `any`, suppression or weakened assertion is introduced.
- Re-ran repository-owned validators/syntax available in the container and rebuilt the product with Rojo 7.7.0. Product output is unchanged at 2,320,769 bytes with SHA-256 `c4dfe6f6ac6e0f0e98493cdbc737ab97e1e56e7b4a5f8c883a35430125b9177a`, as expected because only a test contract and live-state documentation changed.
- A fresh pinned Windows `lune run tools/build/build_place.luau --verify` remains the authority for confirming the final test typecheck.

## 2026-09-25 — v35 final test-typecheck iterator closure

- Consumed the second operator-provided Windows `build_place_verify.log`. It confirms every repository validator, StyLua apply/check, Selene with 0 errors/0 warnings/0 parse errors, tooling typecheck and the Roblox product analysis all pass; only the tests analysis still failed.
- Isolated the remaining diagnostic to `ContentConnectivity.spec`: Luau-LSP 1.70.0 rejected the `ipairs(ability.Effects)` path through an inferred `{ string } | {}` callable-union during generic-for analysis. Replaced that path with an explicit numeric traversal over the typed effects array, preserving the same contract without iterator inference.
- Re-ran the container-available validators/Luau syntax, standalone `tools` typecheck and the physical Lune 0.10.5 + Rojo 7.7.0 build/deserialization. The product place remains 2,320,769 bytes with SHA-256 `c4dfe6f6ac6e0f0e98493cdbc737ab97e1e56e7b4a5f8c883a35430125b9177a`.
- A fresh pinned Windows `--verify` is still required before declaring the v35 product+tests gate fully green; no Selene/StyLua policy or typecheck suppression was weakened.

## 2026-09-25 — v35 Windows verify corrective pass

- Consumed the operator-provided `build_place_verify.log` instead of relying on the container-only partial gate. The Windows run confirmed every repository validator, StyLua apply/check, sourcemap generation and both Roblox Luau-LSP phases were reached before the quality gate failed.
- Fixed the product type error in `StoreAdapter`: Luau-LSP 1.70.0 types the `UpdateAsync` callback `DataStoreKeyInfo` as non-optional, so metadata/UserId preservation now uses the provided key info directly instead of comparing it with `nil`.
- Repaired `TransactionCoordinator.spec` type aliases (`type`, not `local type`), removing the accidental globals/shadowing and the cascade of unknown-type/mismatched-assert diagnostics in the test graph.
- First narrowed `ContentConnectivity.spec` iteration with explicit `ipairs`/`pairs`; the subsequent Windows verify showed Luau-LSP 1.70.0 still inferred the effects path as a callable union, which is closed by the indexed traversal recorded above.
- Removed the accompanying Selene defects without weakening lint policy: reactive combat now consumes its `kind` argument explicitly, persistence-policy asserts have actionable messages, and transaction map clones use `table.clone` where their shallow semantics are intentional.
- Re-ran every container-available validator/source/syntax gate and a physical Lune 0.10.5 + Rojo 7.7.0 build/deserialization. The corrected place is 2,320,769 bytes with SHA-256 `c4dfe6f6ac6e0f0e98493cdbc737ab97e1e56e7b4a5f8c883a35430125b9177a`. A new Windows `--verify` remains required to prove the pinned Roblox product+tests typecheck is fully green after these fixes.

## 2026-09-25 — Durable Auction recovery and first cross-server coordination primitive

- Migrated Auction onto the durable multi-document path already used by trade/mail: listings are authoritative per-key DataStore records, list/buy/cancel/expiry flows use `TransactionCoordinator`, profile receipts and explicit listing state claims, and recovery resumes from journal/listing state instead of trusting process memory.
- Added `AuctionListingRecord` as the durable listing envelope and `AuctionIndexService` as a non-authoritative global browse/expiry index. The index uses `MemoryStoreSortedMap` with TTLs; expiry work is guarded by a `MemoryStoreHashMap` lease through the new `MemoryCoordinationService`. Durable DataStore state remains the source of truth.
- Hardened uncertain-write recovery: a failed listing write followed by an unconfirmed fresh read no longer compensates the source blindly, and purchase compensation now requires a successful fresh durable listing read before releasing/closing the transaction. This prevents an uncertain successful write from turning into item duplication or a permanently stranded purchase claim.
- Expanded `AuctionListingRecord.spec` to cover purchase-claim release plus cancel/expiry claim-to-terminal transitions. The registry now contains 134 specs plus 4 harness/helper modules.
- Re-ran repository validators/Luau syntax, the product require graph and the physical Lune 0.10.5 + Rojo 7.7.0 build/deserialization. `src/` contains 415 Luau files; the product graph has 416 nodes including the mounted atlas manifest and only the two legitimate Rojo entrypoints have no incoming dependency. The final place is 2,320,852 bytes with SHA-256 `5eb0a60c1e0eefd17e88f4d7874519af8ec0e8c985305dc9951c7208c7d3391c`.
- StyLua and Selene remain intentionally outside this pass at operator request. The Roblox definitions-backed full typecheck and runtime/TestService multi-server failure injection remain evidence gaps; Guild/Settlement are now the main unresolved multi-document P0 consumers.

## 2026-09-25 — Durable profile ownership and multi-document transaction consumers

- Replaced blind profile persistence with durable session ownership: profile loads acquire a generation-scoped lease through `UpdateAsync`, autosave/renew/release use revision compare-and-swap, and `LastWriteId` plus uncached reads reconcile uncertain write results without creating replacement profiles.
- Added fail-closed durable envelopes, raw quarantine and ordered N→N+1 migration. Corrupt, future-schema, wrong-identity or incomplete blobs are preserved for recovery instead of being silently converted into `ProfileFactory.empty()`. Production DataStore acquisition can no longer fall back to ephemeral memory storage.
- Added `PersistenceRecord`, `PersistencePolicy` and `MigrationRegistry`, wired profile transaction receipts into validation/defaults, and removed persistence surfaces that became genuinely unconsumed after the new ownership path.
- Added the durable multi-document coordinator with journal state transitions, participant locks/receipts, idempotent applied steps, uncertain-write reconciliation and terminal compensation/review states. `TradeService` and `MailService` are real consumers; auction and guild/settlement remain explicitly open P0 consumers rather than being claimed complete.
- Hardened journal receipts so only declared participants can be recorded and every journal update preserves all participant UserIds. Mail send/return now treats destination identity conflicts as terminal review cases instead of retrying forever, and attachment taking refuses instance collisions rather than silently consuming the mail.
- Added/updated persistence and transaction specs, including profile receipt semantics, coordinator lifecycle/idempotency, foreign-receipt rejection and injected "durable apply but reported failure" reconciliation. The live test registry now contains 133 specs plus 4 harness/helper modules.
- Re-ran the repository-owned validators, Luau syntax gate, productive require graph and physical Lune/Rojo build/deserialization. The current place artifact is 2,264,339 bytes with SHA-256 `c2c9d226f605cb917cd51c104d3fe4d20e54aa9603d1c2439266e2ca3d4708f4`. StyLua and Selene are intentionally left to the operator for this pass; Roblox definitions-backed typecheck and TestService/failure-injection evidence remain pending.

## 2026-09-25 — Repository closure, dead-code audit and current-state normalization

- Reaudited all 575 source-of-truth files before deleting anything: no duplicate file bodies, empty files, temporary/backup artifacts, case-colliding paths, invalid JSON or parallel Rojo projects remain.
- Rebuilt product and product+tests require graphs with Luau-LSP 1.70.0. Every production module has a production consumer except the two legitimate Rojo entrypoints; the test-aware graph adds only `tests/Runner.server.luau` as the expected test entrypoint. No gameplay module was removed without consumer evidence.
- Re-ran every internal schema/source gate, standalone `tools/` typecheck and the physical Lune/Rojo build/deserialization path. Those stages pass; the canonical `--verify` remains intentionally non-green in this container because exact StyLua 2.5.2, Selene 0.31.0 and the pinned Roblox definitions cache are not materialized here.
- Normalized `ESTADO_ACTUAL.md` around v34 evidence and removed the stale v17/v29/v30/v31/v33 gate walkthrough from live-state sections. Historical migration details remain in this changelog instead of competing with current release readiness.

## 2026-09-25 — Catalog depth, acquisition ownership and hostile content consumers

- Audited the complete live catalog surface against the runtime consumers and against mature content dimensions observed in AzerothCore 3.3.5a (creature identity/combat/loot, vendor stock, trainer separation, loot tables, skill ownership and proc metadata) without copying WoW IDs, GPL implementation or balance formulas. The goal of this pass is content connectivity, not raw row inflation.
- Replaced generic hostile spawn behavior with explicit per-entry `CombatProfileId`, `AbilityIds` and resolved loot ownership. The 24 live hostile spawns now use differentiated melee/brute/skirmisher/ranged/caster/controller/channeler profiles and real ability kits; `WorldService` forwards those contracts into `UnitRegistry`, and `EnemyAgent` consumes them with deterministic kit rotation, canonical per-ability cooldowns and basic-attack fallback.
- Extended NPC ability execution so hostile kits consume their secondary effects as well as damage: control, interrupt, resource drain and physical displacement now participate in PvE rather than existing only in player/boss definitions. Encounter reset/clear removes per-NPC kit/cooldown state.
- Expanded acquisition depth rather than adding orphan items. The live surface is now 137 item templates, 22 loot tables, 53 vendor offers and 45 recipes; every shippable item has at least one static source through loot, vendor, crafting or starting loadout. Zone hostile tables now own themed loot instead of routing almost everything through one generic mob table.
- Expanded professions from Mining/Smithing/Cooking to five live professions by adding Alchemy and Latticecraft. Both have real recipes and stat contracts and now persist through profile defaults, roster push/client parsing and lobby presentation.
- Made bags an unavoidable inventory consumer: each starting archetype equips a `SmallBag` into `Bag1` through typed `SlotOverride`, while larger/reagent/profession/bank bags have acquisition/crafting paths.
- Repaired content topology defects discovered by the audit: six service POIs referenced missing NPC definitions and are now backed by real repair/innkeeper NPCs; `NpcDefinition.Role` shares the canonical `PoiKind`; the Hide set's six-piece tier was impossible with five physical pieces and now has `HideMantle` plus icon/acquisition coverage.
- Added `ContentConnectivity.spec` and strengthened `catalogs`/`layout` validators. They now reject item rows without acquisition, invalid crafting professions/materials, impossible set tiers, trinket/gem rows without physical consumers, hostile spawns without valid profile/kit/loot, service POIs without NPCs, professions that do not persist/surface, and Ability/Effect rows without a live consumer. Current content resolves all 109 abilities and 120 effects to live consumers.
- The audit deliberately does **not** claim trainer/skill learning complete. `KnownAbilityService` and persisted abilities exist, but service NPCs with role `Trainer` are still presentation/world content; there is not yet a mature server-authoritative trainer contract for costs, requirements and learning. Quest breadth/composite objectives and richer NPC role AI remain separate follow-up work.

## 2026-09-25 — Periodic offense snapshots and attack-class defense separation

- Added definition-driven periodic snapshot policy and made `BleedAura` the first real `PeriodicSnapshot="Apply"` consumer. Bleed captures the source combat-stat snapshot and numeric stat values at application/refresh time, clones them into the canonical aura record and reuses that source offense/threat context on later ticks instead of retroactively changing with gear/buff swaps.
- Kept periodic target resolution dynamic: target defenses, health/alive state, PvP rules, mitigation/resistance and current geometry/rules are still evaluated when each tick resolves. Reapplying/refreshing the aura replaces the stored source snapshot deterministically with the new application context.
- Split defense eligibility by attack class. `DamageResolver` derives `Melee`, `Ranged` or `Spell` from canonical ability metadata and `DefenseGraph` applies Dodge/Parry/Block only to current Melee-contact attacks; Ranged and Spell no longer inherit melee avoidance/deflection accidentally.
- Preserved ASTRAKYN's existing hit/crit/mitigation model and intentionally did not add AzerothCore/WoW glancing blows, crushing blows, weapon skill or ranged deflect because no current ASTRAKYN stat/consumer owns those mechanics.
- Expanded `Aura.spec` and `CombatDefense.spec` and added static layout guards so Bleed cannot silently return to dynamic caster scaling and Ranged/Spell cannot regress into the melee Dodge/Parry/Block path. The suite remains 127 registered specs plus 4 harness/helper modules.
- Reviewed the boundaries against AzerothCore's separate melee/ranged/magic hit resolution and aura amount calculation concepts without copying GPL implementation or WoW balance formulas.

## 2026-09-25 — Playable channels, physical displacement, reactive defense and social aggro

- Promoted the existing playable `Drain`, `Recharge`, `FocusFire` and `VoidChannel` definitions to real player channel timelines. Channel haste scales duration and tick interval together; cost/cooldown/GCD commit once at start; each tick reuses authoritative target/range/LOS validation and divides the original effect budget through `ChannelTimelineResolver.TickScale`. Movement, hard control, Interrupt, death or an invalid target cancel the pending channel.
- Marked player channel damage as `ChannelTick` and intentionally kept it out of the existing `DirectDamage` proc/on-hit path: no `DamageEcho`, multistrike, combo generation, on-hit resource, victim resource hook or cast pushback is multiplied per tick until a dedicated channel/periodic consumer exists.
- Added physical displacement as definition data plus a shared `DisplacementResolver`. `Void Lash` now owns a live Pull consumer and `Hammerfall` a live Knockback consumer; both use server-side `ApplyImpulse`, horizontal direction/mass/speed resolution, boss Knock immunity and a bounded `MovementGuardService.AcceptExternalMovement` window rather than teleporting the victim.
- Added a server-owned reactive defense window. Dodge/Parry/Block opens a five-second `ReactiveDefense` state; the existing playable Vanguard `Reckoning` ability requires and consumes that window exactly once. The defensive combat event is tagged so clients can observe the opening without trusting client state.
- Added real secondary consumers for aura charges/immunity metadata: `PaleEvadeBuff` owns one Root/Slow immunity charge and `RallyBuff` grants each party recipient one Fear immunity charge, both using the same canonical charge/expiry/UI pipeline as Iron Will.
- Extended encounter aggro with bounded social assistance. Normal Enemy profiles can call same-kind, same-zone allies within `AssistRadius` once per engagement; assisted units are marked immediately to prevent assistance chains, and each assistant still prunes the shared target through its own normal availability/leash rules. Boss/Dummy profiles keep assistance disabled.
- Kept proc taxonomy deliberately unchanged: `DamageEcho` still declares only `AutoAttack` and `DirectDamage`. Player channel ticks do not masquerade as DirectDamage procs and no `ChannelTick` proc trigger was invented without a real proc consumer.
- Added owning coverage for playable channel definitions, displacement direction/impulse and live consumers, reactive state/Reckoning, secondary immunity-charge consumers and encounter assistance profiles. The suite is now 127 registered specs plus 4 harness/helper modules.

## 2026-09-25 — Windows strict-type closure for aura immunity metadata

- Consumed the pinned Windows `--verify` log from v30. Layout/catalog/content/remotes/runtime/Rojo/test/icon/source-policy/syntax validators passed; StyLua apply/check completed; and Selene reported 0 errors, 0 warnings and 0 parse errors before Luau-LSP stopped the gate.
- The log contains one unique product TypeError repeated through product/test analyses: `IronWillBuff.ImmunityTags` was inferred as `{string}` inside the exact `EffectCatalog` table while the canonical effect contract requires `{ControlKind}?`.
- Kept the strong CC union instead of widening the schema: `EffectCatalog` now aliases `ControlKind` from `EffectTypes` and reuses a typed `{ ControlKind }` constant for Iron Will's immunity list. No `any`, suppressions or gameplay/balance changes were introduced.
- Local revalidation on the corrected snapshot passes the repository validators/Luau syntax, `tools` strict typecheck with Luau-LSP 1.70.0 and the physical Rojo 7.7.0 build. A new pinned Windows `--verify` remains the authority for declaring the complete Roblox product/test typecheck green.

## 2026-09-25 — Live CC groups, aura immunity charges, school lockouts and NPC channel ticks

- Promoted previously soft/placeholder controls into real consumers: `ColdBind`/`VoidSnare` apply Root, `ShieldBash` adds a short Stun beside its explicit Interrupt, `Hex` is Disorient, and `VoidTouch` is Fear with damage-break semantics. Boss immunity policy now covers Disorient alongside the existing hard-control set.
- Expanded PvP diminishing returns only for live groups: Stun, Root, Fear, Disorient and Silence use the canonical full → half → quarter → immune sequence; PvE remains outside PvP DR. Disorient now consumes generic `ControlDurationReduction` even without a dedicated per-kind resistance stat.
- Added data-driven aura charges/immunity through the existing `AuraService`. `IronWillBuff` owns two visible charges and CC immunity metadata; compatible CC consumes a charge before DR, the final charge expires through the canonical aura/stat/UI cleanup path, and Fear/Disorient `BreakOnDamage` metadata removes those controls on effective damage.
- Made interrupt lockouts school-specific. Successful Interrupt records `Interrupt:<School>` for the school that was actually interrupted, so different schools do not overwrite/block one another; `InterruptResistance` still reduces lockout duration through the shared control-duration resolver.
- Added real NPC channel ticks via `ChannelTimelineResolver`: channel definitions expose duration/tick interval, total damage budget is divided across ticks, every tick revalidates source/target/range/LOS, and death/evade/hard-CC/Interrupt/school lockout cancels the pending channel. Cast pushback remains Cast-only.
- Made `DamageEcho` trigger data explicit (`AutoAttack` / `DirectDamage`) in `ProcProfiles`; live call sites must supply a permitted trigger before the per-proc ICD can arm. No global proc ICD or consumerless proc taxonomy was added.
- Propagated aura charges through character sheet/UI and expanded owning specs for charges/immunity, damage-break, school lockout, all five live DR groups, channel timeline and event-specific proc triggers. The suite is now 125 registered specs plus 4 harness/helper modules.
- Reviewed these boundaries against AzerothCore 3.3.5a concepts (grouped DR, interrupt/pushback separation, aura immunity/charges and channel timelines) without copying GPL implementation or WoW balance formulas.

## 2026-09-25 — Combat engagement, movement, cast pressure and CC policy

- Reworked combat engagement as a first-class timed relation rather than a presentation/action state. Hostile Damage/Debuff/CC/Interrupt and enemy-target movement engage the caster; support effects only pull the caster into combat when the caster or supported ally/party is already engaged; neutral self/resource/movement effects remain OOC. Rest, Gate Bind, logout and health regen now consult `IsInCombat()` instead of comparing the visible state string.
- Added `CombatEngagementResolver` as the canonical effect-intent classifier and preserved PvE utility aggro by adding bounded threat for hostile non-damage effects on NPCs.
- Replaced the one-size-fits-all movement effect with explicit definition data: Forward, Backward, TowardTarget and Speed. Sprint is now a real +35% MovementSpeed aura with expiry cleanup; Withdraw retreats; Intercept/RiftStep/Voidstep/CoverDash move toward the target; displacement preflights source/destination geometry and LOS before resource/cooldown commit.
- Added capped direct-damage cast pushback through `CastTimelineResolver`: Casts can be delayed twice by 0.5s while Channels/periodic damage are not implicitly delayed. The client cast bar receives the updated remaining time without changing the cast token.
- Added real NPC pending Cast/Channel state instead of resolving every NPC ability instantly. NPC casts can be delayed by direct damage, interrupted by explicit Interrupt, cancelled by hard control or evade/reset, and are removed when the casting NPC dies, including splash kills.
- Added the first explicit PvP diminishing-return group through `CrowdControlResolver`: Silence-family CC progresses full → half → quarter → immune and resets after its post-control window. DR is opt-in definition data (`DiminishingGroup`), not inferred from tags globally. Boss hard-control immunity is centralized and remains distinct from explicit Interrupt, which can still stop an interruptible boss cast.
- Added owning specs for engagement intent, cast pushback and DR/immunity, expanded movement tests for retreat/toward semantics, and updated Sprint sink coverage. The live suite is now 124 registered specs plus 4 harness/helper modules.
- Reviewed these boundaries against AzerothCore 3.3.5a concepts (combat references, cast pushback/interrupt separation, explicit diminishing groups/levels and creature evade) without copying its GPL implementation or WoW balance formulas.

## 2026-09-25 — Windows strict-typecheck closure after v27 combat pass

- Consumed the real Windows `--verify` log from v27. Schema validators, StyLua apply/check and Selene all completed successfully with 0 errors, 0 warnings and 0 parse errors before Luau-LSP stopped the gate.
- Fixed the only product diagnostic: `CombatService` now imports `AbilityTypes` and aliases `AbilityDefinition` from the canonical shared type module for the ranged weapon-channel helper instead of referencing an undeclared type.
- Fixed all five test diagnostics in `CcDispel.spec` without `any` or suppressions: slow magnitudes use an explicit `{ [string]: number }` map and buff expectations use `{ [string]: { StatId: string, Value: number } }`, so Luau-LSP no longer widens iteration values to `unknown`.
- No gameplay or balance contract changed in this closure. The user subsequently confirmed the pinned Windows `lune run tools/build/build_place.luau --verify` succeeds on v28; that remains the last complete pinned-gate baseline before the v29 gameplay changes.

## 2026-09-25 — Autoattack geometry, swing timing and live combat sinks

- Re-audited player/NPC combat against mature AzerothCore 3.3.5a invariants without copying GPL implementation or WoW balance formulas. ASTRAKYN now keeps its own hit/avoidance/stat graph while adopting the useful boundaries: persistent attack state, range/facing retry, independent hand clocks, opposite-hand separation, LOS and speed-change preservation of remaining swing progress.
- Added canonical `CombatGeometry` and made player abilities/autoattack fail closed on missing source/target geometry, range or LOS; autoattack also enforces a 120-degree server-side facing arc. Ground-target LOS stops short of the destination surface so the floor itself is not treated as an obstruction. NPC acquisition/melee uses the same LOS contract.
- Added `SwingTimerResolver`: haste/attack-speed changes rescale the remaining fraction of an in-progress swing, and every successful main/off-hand swing re-applies the minimum hand separation so timers that matured during casts/CC cannot land simultaneously.
- Made weapon damage real instead of a sink without an item producer. `WeaponCombatProfiles` defines ASTRAKYN-owned item-level damage curves, `EquipmentService` applies quality/upgrade/durability once, the active primary weapon owns global `WeaponDamage`, and each hand reads its own instance damage for autoattack.
- Completed the previously unreachable dual-wield path: compatible one-hand main-slot weapons may occupy OffHand, require a distinct valid one-hand MainHand, cannot duplicate one physical instance across slots, and equipment mutations/death normalize invalid pairs. Shields/relics keep their native off-hand semantics.
- Initial autoattack start errors now surface through the existing UI notification path. `DamageEcho` no longer arms its ICD on zero-damage avoidance events.
- Fixed live Slow effects that were cosmetic-only: `VoidSnareCC`, `PinningShotSlow`, `TimeWarpSlow` and `VoidTouchCC` now use canonical MovementSpeed magnitudes through `ModifierResolver`; `CC` is intentionally marked `PARTIAL` until the remaining constitutional control categories and PvP DR are real.
- Fixed four additional zero-Flat live auras that were functionally inert: `IronWillBuff` now grants +15% DamageReduction, `StonehideBuff` +40 Armor, `PaleEvadeBuff` +12% Dodge and `ThornSkinBuff` +10% DamageReduction; owning tests assert each live sink.
- Expanded owning specs/guards for weapon curves, facing/range, swing rescale/separation, dual-wield slot/pair rules, zero-damage proc eligibility and every live slow sink.
- Closed weapon-swap timing: each autoattack hand snapshots the equipped physical instance; replacing that weapon restarts only that hand at the new full period while haste-only changes continue to preserve fractional swing progress.
- Added explicit ability `WeaponChannel` ownership for ranged weapon skills. `PiercingShot`, `FinishShot`, `Volley` and `PinningShot` require a real Ranged weapon and substitute only that instance's `WeaponDamage`, so a sword in MainHand can no longer power bow abilities.
- Consolidated equipment/loadout/persisted-state validation in `EquipmentRules`: slot compatibility, physical-instance uniqueness, durability, RequiredLevel, UniqueEquipped and main/off-hand pair legality now share one rule source; rebuild sanitizes legacy snapshots deterministically.
- Added a first-class interrupt contract. `ShieldBash` now carries `BashInterrupt`; only an actual pending cast/channel consumes the interrupt effect, `InterruptResistance` reduces its lockout through the existing control-duration pipeline, and soft `Slow` effects no longer cancel casts implicitly.
- Closed autoattack restart abuse: repeated `STARTATTACK`, retarget and `STOPATTACK`/`STARTATTACK` preserve the existing hand clocks instead of recreating `MainAt`/`OffAt`; stop now deactivates persistent attack state and only death/session teardown destroys its timers. All death causes publish one `DeathService.Died` transition that centrally clears swing/cast/last-hit/proc transient state, including fall deaths.
- Kept multi-effect presentation deterministic: auxiliary CC/Interrupt/Buff effects still execute and emit server combat events but no longer replace an already-resolved Damage/Heal/Revive payload sent as the ability's primary client result. Removed the unused local gear cache from `ItemResolver` after equipment ownership moved fully to `EquipmentSlotCatalog`/`EquipmentRules`.

## 2026-09-25 — Windows verify diagnostics and resurrection dependency closure

- Consumed the real Windows `build_place_verify.log` from the v25 snapshot instead of relying on container-only evidence. The log confirmed all schema validators and StyLua stages ran, then exposed one Selene unused import plus Roblox Luau-LSP diagnostics in loot UI typing, combat-state narrowing, NPC waypoint indexing, analytics payload typing and a real five-module server dependency cycle.
- Removed the unused `StatCatalog` import from `NpcStats.spec`, made loot-choice dictionary entries optional at their nil-checked boundary, made `CharacterState` writes explicit under strict narrowing, bounds-check dense `PathWaypoint` arrays instead of nil-comparing non-optional elements, and normalized the party analytics flag to the service's string-only context contract.
- Broke `World -> EnemyAgent -> Combat -> Character -> World/WorldEvent` at the correct ownership boundary: `CombatService` no longer statically requires `CharacterService`. Resurrection is injected by `ServiceRegistry` through `CombatService:SetReviveResolver`, preserving `CharacterService` as avatar materialization owner while keeping the domain graph acyclic.
- Made resurrection failure non-consuming: the injected resolver runs after cooldown/resource preflight but before commit; a per-caster resolution lock prevents another ability from racing the same resource pool while `LoadCharacterAsync()` yields. The layout validator now rejects a direct Combat-to-Character require or missing composition-root resurrection wiring.
- Audited the complete uploaded verify log and covered every unique error reported there. A separate static require SCC audit over the current product tree reports zero cycles. Full pinned Windows `--verify` still requires a fresh rerun to turn these fixes into PASS evidence; this environment does not contain the exact Lune/Rojo/Luau-LSP/StyLua/Selene binaries.

## 2026-09-24 — Manual lifecycle, resurrection and server navigation

- Made ASTRAKYN the explicit avatar lifecycle authority: server bootstrap sets `Players.CharacterAutoLoads = false`, `CharacterService` materializes avatars only through `Player:LoadCharacterAsync()`, and the quality gate now rejects deprecated `LoadCharacter()` or deprecated pathfinding APIs.
- Extended `DeathService` into a single death record/corpse authority: pre-terminal corpse zone/CFrame capture, one-time death durability/profile side effects, release delay, mutually exclusive resurrection claim/cancel/complete, encounter aura/threat cleanup and partial-vital restore. Combat and fall deaths enter the same door before the Humanoid terminal state.
- Added real `Revive` and `BattleRevive` ability/effect consumers. Resurrection targets must be dead party players in the same zone; normal revive is blocked in combat, battle revive uses its own long cooldown/resource cost, corpse position drives range and successful materialization returns to the captured location.
- Added server-side NPC chase through `PathfindingService:CreatePath()` + `Path:ComputeAsync()` with async/rate-limited computation, future-waypoint `Path.Blocked` invalidation, aggro/reach/leash separation, physical return-to-home after evade and simulation LOD based on the moving NPC position rather than only its spawn point.
- Expanded the owning death/target/AI specs and added schema guards for the manual lifecycle and non-deprecated navigation API surface; no parallel resurrection or movement authority was introduced.
- Closed the manual-lifecycle/profile-load race exposed by yielding DataStore reads: `DataService.Loaded` is now the session-ready signal, `PlayerLifecycle` no longer boots sessions directly from `PlayerAdded`, loads completing after `PlayerRemoving` are discarded, and manual respawn/revive avatars stay parked until authoritative placement/death-state completion. The layout gate enforces these invariants.
- Hardened evade/return semantics: returning NPCs are explicitly non-attackable, reject new ability/autoattack damage, discard fresh threat during return, and perform a second encounter reset at home before combat is re-enabled.

## 2026-09-24 — Combat lifecycle, evade and group-loot closure

- Added `ProcProfiles` and centralized the live `DamageEcho` internal cooldown in `ProcService`; proc timing is no longer implicit in individual combat callsites and session cleanup clears proc state. No unused generic proc-charge framework was introduced.
- Added `NpcCombatProfiles` and completed a real consumer for leash/evade on the current static-NPC model: invalid/out-of-leash targets are pruned, an encounter without valid threat enters an evade timeout, then health/absorb/threat/auras and swing state return to home. This does not pretend chase/pathfinding exists.
- Added `DeathService` as the single death/release authority used by combat and fall damage. It records death time, enforces the release delay, clears encounter auras/threat, restores vitals/unit state and keeps `UnitRegistry` synchronized after stat rebuild. Corpse/graveyard, resurrection/battle-res and wipe policy remain intentionally open because no live ability/consumer exists yet.
- Tightened Need/Greed: `LootRollRules` delegates gear classification to the existing `ItemResolver`, validates Need against gear+RequiredLevel, preserves Need-over-Greed and deterministic ties, treats timeout as Pass, and returns no winner when everybody passes instead of silently awarding the leader. `canNeed` is propagated through `SheetWireTypes` and the modal hides an ineligible Need action.
- Added owning specs for NPC evade/reset, death/release and loot-roll rules; the live suite is now 121 registered specs plus 4 harness/helper modules.
- Rechecked the constitutional boundary before adding broader Azeroth-inspired systems: resurrection and aura charges were not scaffolded without a real consumer, avoiding dead architecture disguised as completeness.

## 2026-09-24 — Azeroth-informed combat foundations and contract corrections

- Added server-authoritative player autoattack as persistent combat state rather than a synthetic Ability: authoritative target, independent main/off-hand swing clocks, weapon combat profiles, haste-scaled periods, melee/ranged reach, off-hand stagger/damage and reuse of the existing mitigation/proc/resource/event/threat pipeline.
- Wired right-click target+start and stop behavior through the existing combat remotes; added `STARTATTACK`/`STOPATTACK` to the macro DSL without allowing macros or clients to inject damage, swing timing or arbitrary combat authority.
- Split cooldown handling into non-mutating preflight plus execution commit, added resource preflight, and ensure delayed casts that fail at resolution leave `Casting`/`Channeling` instead of sticking state or consuming cooldown/GCD prematurely.
- Decoupled combat engagement from action/control state: a timed engagement window now survives casting/channeling/CC for regen, macro conditions and combat restrictions, while isolated CC no longer invents combat state.
- Hardened PvE threat using concepts reviewed in AzerothCore 3.3.5a: NPC-only threat tables, sticky 110% melee/130% ranged switching, bounded timed taunt/fixate, effective-healing threat, and separate target-clear/source-removal semantics, plus AI-time pruning of dead/disconnected/out-of-zone threat references; centralized repeated damage-threat wiring.
- Added same-zone/reward-range party kill credit and shared XP using ASTRAKYN-owned constants/formulas, informed by mature MMORPG reward eligibility patterns rather than copied WoW formulas.
- Replaced the player-only aura bag with canonical `AuraService`: one registry for Player/NPC/world units, refresh-by-default semantics, explicit `StackPolicy`/`MaxStacks`, data-driven periodic effects, bounded tick scheduling, expiration/strip events, NPC hard-CC consumption and stack counts in player/target HUD. `BleedAura` is the first live stacked periodic consumer. `Auras` remains `PARTIAL` until charges, immunity rules and full snapshot/persistence semantics exist.
- Re-audited maturity labels against constitutional behavior rather than file count: `Death`, `Party` and `Quest` are also `PARTIAL` until resurrection/corpse/wipe, cross-server party continuity/roles/markers, and the required quest-type/sharing/reward-safety contracts actually exist.
- Expanded the live suite to 118 specs and kept the security contract for autoattack remotes, weapon/swing behavior, threat, cooldown/resource transactionality, aura refresh/stack/periodic lifetime and group rewards in owning specs.
- No AzerothCore GPL implementation code was copied; upstream was used only to identify mature functional boundaries and invariants that were then implemented against ASTRAKYN's own architecture and data contracts.

## 2026-09-24 — Canonical ownership migration and final dead-code audit

- Migrated the live tree to the ownership model already required by `CONSTITUTION.md`: server platform capabilities now live under `Server/Platform`, gameplay under `Server/Domains`, client presentation/UI/domain state under their canonical namespaces, shared protocols under `Shared/Protocols`, and tests under evidence-type roots.
- Removed the substituted physical layers `Server/{Infrastructure,Services,Systems,Engines}`, `Client/Hero`, `Definitions/Remotes`, `Shared/{Content,Signals,UI}`, the old domain-first test roots and `tools/types`; all consumers, Rojo mappings, validators and tests were rewired before the legacy paths disappeared.
- Hardened `tools/schema/layout.luau` with explicit ownership allowlists and forbidden substituted layers so the architecture cannot silently regress; updated catalog/remotes validators for `Shared/Protocols/RemoteCatalog.luau` and whole-server producer scanning.
- Removed the unconsumed `Client/UI/HUD/Inspector/Inspector.luau` facade after the Luau-LSP require graph proved it had no product consumer; the final product graph has only the server/client entrypoints without incoming edges, and the test graph adds only `tests/Runner.server.luau`.
- Removed stale global stat-catalog floors/counts and repeated cycle/edge invariants from unrelated specs, leaving each invariant with its owning test; removed duplicated identity/presentation count assertions and corrected stale `v2`, Theme-layer and MachineHeat wording.
- Revalidated the migrated tree with every internal schema gate, standalone `tools/` typecheck, product+test require graphs and a physical Rojo build/deserialization path. Full `--verify` remains explicitly blocked only by unavailable StyLua/Selene binaries and uncached pinned Roblox definitions in this container.

## 2026-09-24 — Test-suite ownership and dead-test cleanup

- Consolidated the historical parallel `RelationResonance.spec.luau` into the canonical `RelationResonanceEdges.spec.luau`, preserving the unique resolver/resonance pipeline cases before deleting the duplicate spec.
- Removed the obsolete umbrella `CatalogFloors.spec.luau`; its catalog, L6, snapshot-budget and voxel-key assertions were weaker duplicates of dedicated live specs.
- Removed dead harness surface (`HARNESS_RUN_MANIFEST`/`runManifest`) and the redundant `assertStreaming` wrapper; streaming is asserted once in its dedicated spec and statically guarded by `rojo-map`.
- Removed unrelated hardcoded `STAT_VERSION == 1` assertions from combat specs and consolidated the generic `STAT_VERSION >= 1` floor in `Properties.spec.luau`; wiring tests still verify the live version is propagated where it matters.
- Reworded historical `v1`/`v2`/`old` test labels that described current behavior, keeping regression intent without presenting obsolete contracts as active terminology.
- Added the `test-suite` schema validator: every `*.spec.luau` must exist, have a unique token/body, be registered exactly once by `tests/Bootstrap.luau`, and every non-entry test helper must have a real require consumer.
- The live suite now contains 115 registered specs plus 4 harness/helper modules, with no orphan specs, missing registrations, duplicate spec bodies or unused test helpers.

## 2026-09-24 — Streaming contract and repository cleanup

- Made `default.project.json` the executable source of truth for native Workspace streaming: `StreamingEnabled = true`, `ModelStreamingBehavior = Improved`, `StreamingIntegrityMode = PauseOutsideLoadedArea`, radii `64/1024` and `StreamOutBehavior = Opportunistic`.
- Aligned `PerformanceBudgets` and streaming specs with the constitutional `64/1024` contract and added a `rojo-map` validator that fails if the Rojo Workspace properties or budget mirrors drift.
- Restored the harness `assert` API to Lua truthiness (`unknown`) instead of the regressed boolean-only contract, matching existing specs and the documented 2026-09-23 contract.
- Removed the unreferenced test-only `DeepFreeze` utility and the redundant test-only `GameConstants.STREAMING_DEFAULT_ON` flag; tests now assert the real Workspace streaming policy instead of a duplicate boolean constant.
- Rebuilt the canonical Rojo project with Rojo 7.7.0 and confirmed the resulting `.rbxlx` serializes the streaming contract exactly; current verification evidence and environment-only blockers are recorded in `ESTADO_ACTUAL.md`.

## 2026-09-23 — Strict typecheck/tooling closure

- Fixed every Luau TypeError reported by the latest Windows `--verify` log in `tools/` and the shared logging contract used by `src/`.
- Tooling typecheck now uses an explicit standard-platform definitions file, so standalone Luau-LSP emits no spurious missing-definitions warning while Lune modules remain version-pinned through `.luaurc`.
- StyLua fixes are always applied before lint/typecheck, followed by `stylua --check` to enforce an idempotent canonical result.

## 2026-09-23 — Windows test-overlay path-base fix

- Confirmed from the third real Windows gate run that schema validation, Selene, StyLua and the product Luau-LSP analysis all pass before the test-overlay phase.
- Diagnosed 6,671 test-phase TypeErrors as a sourcemap path-base failure: the `.build/` project rebased product `$path` entries to `../...`, but Luau-LSP resolved those relative source paths from the root `sourcemap.json`, shifting every module one directory above the actual repository.
- Generate the ephemeral test project as `.astrakyn-test.project.json` beside `default.project.json` and `sourcemap.json`, preserving canonical `$path` values and adding only `TestService.Tests = tests`.
- Keep the overlay ignored and remove it after analysis; `default.project.json` remains the only versioned/canonical Rojo project and `sourcemap.json` remains the only sourcemap.
- Deliberately avoid `rojo sourcemap --absolute` on pinned Rojo 7.7.0 because upstream has post-7.7.0 Windows fixes for absolute/verbatim sourcemap paths consumed by Luau-LSP.

## 2026-09-23 — Test sourcemap and typecheck graph fixes

- Confirmed from the second real Windows Lune run that every schema validator passed and Selene completed with 0 errors, 0 warnings and 0 parse errors before later gates failed.
- Applied the StyLua formatting reported by the real gate instead of weakening or bypassing the formatter check.
- Generate both product and ephemeral-test sourcemaps with `--include-non-scripts`, and require the shared editor setting to keep that behavior explicit.
- Analyze `src` and `tests` together against the ephemeral test overlay so Luau-LSP indexes the production modules required by specs while still restoring the one canonical `sourcemap.json` to the product tree afterwards.
- Aligned the test harness `assert` contract with Lua truthiness, avoiding false type errors for intentional truthy values such as indices, IDs and numeric results.
- Kept `default.project.json` as the only versioned Rojo project; no persistent test project or second sourcemap was reintroduced.

## 2026-09-23 — First real Lune gate fixes

- Fixed catalog parity discovered by the first Windows Lune run: archetype quests intentionally use an empty `ZoneId`, matching the pre-Lune validator behavior that skipped empty references.
- Fixed `tools/schema/rojo_map.luau` so the second return value from `string.gsub` cannot leak into `table.insert`.
- Fixed strict Luau `pcall` type-pack handling for void callbacks in the builder and test-overlay cleanup.
- Added the versioned `.luaurc` alias for Lune 0.10.5 typedefs and documented `lune setup` as the required one-time editor setup after `rokit install` or a Lune pin change.
- Added a layout guard that keeps the `.luaurc` Lune alias synchronized with the exact `rokit.toml` pin.

## 2026-09-22 — Single canonical Rojo project and sourcemap

- Eliminated the versioned `test.project.json`; `default.project.json` is now the only canonical Rojo project.
- Added `tools/test/project.luau` to generate the `TestService.Tests` overlay only as an ignored ephemeral project when tests need DataModel resolution.
- Consolidated editor, quality gate and builder on a single ignored workspace `sourcemap.json`. The gate analyzes `src` against the product map, temporarily reuses the same file for the test overlay, then removes the overlay and restores the product map.
- Removed `.build/sourcemap.json` and `.build/test-sourcemap.json` from the architecture and updated validators/documentation so parallel environment/project configurations cannot return silently.

## 2026-09-22 — Complete current-state inventory and package-manager decision

- Completed the previously empty `ESTADO_ACTUAL.md` work frontier and all 101 mandatory feature-matrix domains from
  `CONSTITUTION.md`, using only observed repository implementation/evidence and conservative maturity levels.
- Recorded P0 blockers for persistence/session ownership, multi-document transactions, RBAC/moderation, cross-server
  topology, runtime world generation, streaming contract drift, platform compliance, analytics/performance and the
  post-Lune execution gap.
- Evaluated Wally against the current Roblox external-tools guidance. ASTRAKYN intentionally keeps no package manager
  manifest while it has no external Luau dependencies; adoption is triggered by the first approved real dependency and
  must include a current ecosystem re-evaluation, lockfile, Rojo realms and locked CI installation.
- Added the durable dependency-management guardrail to `CONSTITUTION.md` and `AGENTS.md`: no dormant package-manager
  scaffolding, generated package trees are not source-of-truth, and Roblox Packages remain a separate asset/Instance
  versioning mechanism.

## 2026-09-22 — Tooling unificado en Lune

- Adoptado Lune 0.10.5 como runtime canónico del tooling propio, fijado en `rokit.toml` junto a Rojo, Selene, StyLua y Luau-LSP.
- Migrados `tools/build` y `tools/schema` de Python a Luau/Lune; eliminados Python, Pyright, `pyrightconfig.json`, `compileall`, `setup-python` y la instalación npm de Pyright.
- Sustituida la extracción regex de catálogos por un parser Luau ligero con delimitadores balanceados para llamadas, argumentos y tablas nombradas.
- El quality gate compila sintácticamente `tools/**/*.luau`, ejecuta validators, Selene/StyLua sobre `src tests tools` y conserva `luau-lsp analyze` estricto para producto y tests con definitions Roblox verificadas por Git blob.
- `build_place.luau` delega build/sourcemap en Rojo y valida el artefacto mediante `@lune/roblox.deserializePlace`; el manifest usa SHA-256 de `@lune/serde`.
- CI queda reducido a `setup-rokit@v3` + las entradas Lune canónicas; sin runtime Python paralelo.
- Actualizados `AGENTS.md`, `CONSTITUTION.md` y `ESTADO_ACTUAL.md` para que documentación, CI y código describan la misma arquitectura.
- La ejecución completa del nuevo gate queda pendiente de un entorno con la toolchain Rokit disponible; no se declara PASS sin esa evidencia.

## 2026-09-21 — Cierre del gate Rojo/Luau-LSP previo a Lune

- Separados los sourcemaps de producción/tests y consolidado `luau-lsp analyze` como typecheck batch.
- Fijadas definitions Roblox para Luau-LSP 1.70.0 mediante Git blob verificado y caché externa al workspace.
- `--verify` y `--release` quedaron separados: quality permite atlas no publicados; release exige IDs reales.
- Añadido workaround de un único `rokit install` para la firma conocida `(os error 3)` de launchers Rokit en Windows.

## 2026-09-20 — Limpieza estructural del repositorio

- Consolidado `tools/` por ownership y eliminados generators/simuladores/placeholders y capas de configuración históricas que ya no eran fuente viva.
- Rojo quedó como única capa de build/sourcemap del place; StyLua como formatter canónico; Selene y Luau-LSP como gates estáticos de Luau.
- Separados proyecto productivo y proyecto de tests; `.build/` quedó reservado a outputs reproducibles efímeros.
- Centralizados runtime config e IDs de atlas en sus manifests canónicos y endurecidos los validators de layout/rojo/config/contenido.

Git conserva el detalle exhaustivo anterior; este archivo mantiene solo hitos que siguen aportando contexto al estado actual.
