--!strict

export type IdentityKind = "Race" | "Origin" | "Archetype"

export type IdentityPresentation = {
	Id: string,
	Kind: IdentityKind,
	DisplayName: string,
	Blurb: string,
	Lore: string,
	Glyph: string,
	ColorKey: string,
	SortOrder: number,
}

export type SpecPresentation = {
	Id: string,
	Blurb: string,
	Lore: string,
}

local GOLD = Color3.fromRGB(212, 175, 55)

-- Client Color3 table keyed by ColorKey. Archetype RGB matches Paint Warden/Weaver/Stalker.
local COLORS: { [string]: Color3 } = {
	Warden = Color3.fromRGB(72, 128, 196),
	Weaver = Color3.fromRGB(188, 132, 255),
	Stalker = Color3.fromRGB(88, 196, 112),
	Luminary = Color3.fromRGB(232, 196, 88),
	Sentinel = Color3.fromRGB(64, 168, 180),
	Hexwright = Color3.fromRGB(168, 64, 120),
	Vanguard = Color3.fromRGB(196, 72, 56),
	Tempest = Color3.fromRGB(72, 168, 220),
	Templar = Color3.fromRGB(212, 168, 64),
	Arbiter = Color3.fromRGB(180, 140, 72),
	Dragoon = Color3.fromRGB(48, 120, 140),
	Channeler = Color3.fromRGB(96, 72, 196),
	Astralborn = Color3.fromRGB(0, 204, 255),
	Emberkin = Color3.fromRGB(255, 128, 48),
	Voidtouched = Color3.fromRGB(148, 88, 220),
	Paleward = Color3.fromRGB(140, 210, 255),
	Threshold = Color3.fromRGB(80, 140, 220),
	Kynfall = Color3.fromRGB(212, 175, 55),
	Emberwatch = Color3.fromRGB(220, 96, 48),
	Palehaven = Color3.fromRGB(176, 216, 232),
	Stonekin = Color3.fromRGB(148, 140, 124),
	Tideborn = Color3.fromRGB(32, 168, 196),
	Thornen = Color3.fromRGB(72, 140, 64),
	Skylorn = Color3.fromRGB(180, 210, 255),
	Voidmarch = Color3.fromRGB(88, 48, 140),
	Tidehaven = Color3.fromRGB(24, 140, 180),
	Thornwood = Color3.fromRGB(56, 120, 48),
	Skyreach = Color3.fromRGB(160, 196, 240),
}

-- Power bar tints (distinct from portrait/theme colors).
local POWER_COLORS: { [string]: Color3 } = {
	Warden = Color3.fromRGB(196, 72, 48),
	Weaver = Color3.fromRGB(220, 120, 255),
	Stalker = Color3.fromRGB(72, 196, 96),
	Luminary = Color3.fromRGB(255, 220, 120),
	Sentinel = Color3.fromRGB(96, 200, 220),
	Hexwright = Color3.fromRGB(200, 96, 160),
	Vanguard = Color3.fromRGB(220, 88, 64),
	Tempest = Color3.fromRGB(88, 180, 255),
	Templar = Color3.fromRGB(255, 200, 96),
	Arbiter = Color3.fromRGB(220, 180, 88),
	Dragoon = Color3.fromRGB(72, 160, 180),
	Channeler = Color3.fromRGB(140, 108, 220),
}

local REQUIRED_SPEC_IDS: { string } = {
	"Aegis",
	"SpecPulse",
	"SpecRift",
	"SpecMend",
	"SpecLash",
	"SpecExecute",
	"LuminaryGrace",
	"LuminaryWard",
	"SentinelMarksman",
	"SentinelSkirmisher",
	"HexwrightPlague",
	"HexwrightPact",
	"VanguardJuggernaut",
	"VanguardRavager",
	"TempestStorm",
	"TempestFrostfire",
	"TemplarCrusader",
	"TemplarProtector",
	"ArbiterHerald",
	"ArbiterOracle",
	"DragoonLancer",
	"DragoonPhantom",
	"ChannelerConduit",
	"ChannelerAnnihilator",
}

local function entry(
	id: string,
	kind: IdentityKind,
	displayName: string,
	blurb: string,
	lore: string,
	glyph: string,
	colorKey: string,
	sortOrder: number
): IdentityPresentation
	if not COLORS[colorKey] then
		error(`IdentityPresentationCatalog unknown ColorKey {colorKey}`)
	end
	if blurb == "" then
		error(`IdentityPresentationCatalog empty Blurb {kind}:{id}`)
	end
	if lore == "" then
		error(`IdentityPresentationCatalog empty Lore {kind}:{id}`)
	end
	return {
		Id = id,
		Kind = kind,
		DisplayName = displayName,
		Blurb = blurb,
		Lore = lore,
		Glyph = glyph,
		ColorKey = colorKey,
		SortOrder = sortOrder,
	}
end

local function specRow(id: string, blurb: string, lore: string): SpecPresentation
	if blurb == "" then
		error(`IdentityPresentationCatalog empty spec Blurb {id}`)
	end
	if lore == "" then
		error(`IdentityPresentationCatalog empty spec Lore {id}`)
	end
	return {
		Id = id,
		Blurb = blurb,
		Lore = lore,
	}
end

local entries: { IdentityPresentation } = {
	entry(
		"Astralborn",
		"Race",
		"Astralborn",
		"Sangre de retícula. Versatilidad en el pulso.",
		"Los Astralborn nacen en el Umbral, donde el Nodo responde por primera vez al cuerpo que se le acerca. Su sangre lleva la retícula del Kyn todavía unida, y por eso cambian de corriente con una versatilidad que otras estirpes pagan con años. Tras la Escisión del Continuo aprendieron a atar el Poder Astral —el remanente inestable— sin elegir una sola escuela. Un Guardián Astralborn no es más puro: es más dúctil. Donde el mundo entra y sale de fidelidad, ellos dan el paso y el Nodo aún los reconoce.",
		"As",
		"Astralborn",
		1
	),
	entry(
		"Stonekin",
		"Race",
		"Stonekin",
		"Forjados en la Puerta. Aguante en la piedra.",
		"Los Stonekin se templaron a la sombra de Kynfall Gate, capital de oficio y tenencia. Su aguante no es metáfora: la piedra de la Puerta les enseña a permanecer cuando las corrientes se agrietan. Mientras las ciudades se aferran a nodos estables, ellos construyen el cerrojo —muralla, yunque, almacén— que permite que el resto del continente respire. La piel se les endurece como sello contra el desgarro. Un Stonekin sostiene el umbral para que otros puedan cruzarlo.",
		"St",
		"Stonekin",
		2
	),
	entry(
		"Emberkin",
		"Race",
		"Emberkin",
		"Nacidos de la brasa. Fuerza de la forja.",
		"Los Emberkin descienden de las plazas de Emberwatch, donde el mineral aún arde con la escuela del calor. La Escisión no apagó sus forjas: las alimentó. La fuerza les llega por la sangre de brasa, un pacto con la corriente térmica que parte vetas y abre escudos. Más allá del nodo, el yermo entra y sale de fidelidad a golpes de calor; ellos caminan como si el suelo aún fuera yunque. Un Emberkin no adora el fuego: lo usa para que el Kyn no se enfríe del todo.",
		"Em",
		"Emberkin",
		3
	),
	entry(
		"Paleward",
		"Race",
		"Paleward",
		"Corte de escarcha. Agilidad en lo pálido.",
		"Los Paleward sirven a la corte pálida de Palehaven, vigilantes del pozo helado. La escuela del frío les afiló el cuerpo: agilidad de hielo fino, evasión antes del golpe. En Palehaven la vigilia no es poesía; es no dejar que el Frostwell se desborde hacia los nodos vecinos. La Escisión les enseñó que el Continuo también se quiebra en silencio. Un Paleward se mueve como la escarcha sobre piedra negra: breve, preciso, imposible de asir.",
		"Pw",
		"Paleward",
		4
	),
	entry(
		"Voidtouched",
		"Race",
		"Voidtouched",
		"Marcados por la grieta. Intelecto en el hueco.",
		"Los Voidtouched llevan la marca de Voidmarch, el campamento de grieta donde el vacío se cazó en vez de sellarse. Su intelecto se abrió al hueco: ven patrones que el Kyn entero ya no sostiene. La escuela del vacío no es ausencia de mundo; es el desgarro que la Escisión dejó cuando las corrientes se separaron. Allí el mundo entra y sale de fidelidad peor que en cualquier plaza, y ellos aprenden a pensar en el fallo. Un Voidtouched ata el hueco a la mente y no finge que el Continuo siga entero.",
		"Vd",
		"Voidtouched",
		5
	),
	entry(
		"Tideborn",
		"Race",
		"Tideborn",
		"Sangre de sal. Espíritu en la marea.",
		"Los Tideborn nacen con la sal de Tidehaven, donde espíritu y marea comparten el mismo pulso. La corriente no les habla en llamas ni en grietas: les habla en ciclo, en subida y bajada del Poder Astral. Su espíritu sostiene a otros Guardianes del Umbral cuando el nodo parpadea. Más allá de la costa, el mundo entra y sale de fidelidad como una resaca; ellos no se ahogan. Un Tideborn no calma el mar: enseña al cuerpo a respirar con él.",
		"Tb",
		"Tideborn",
		6
	),
	entry(
		"Thornen",
		"Race",
		"Thornen",
		"Parientes del zarzal. Pericia en el bosque.",
		"Los Thornen son parientes del zarzal de Thornwood, donde raíz y espina recuerdan cada paso. Su pericia es oficio de bosque: leer el terreno, el veneno, el roce que decide un duelo. La escuela tóxica nació cuando el Kyn se partió; el zarzal la cultivó en vez de temerla. Las ciudades se aferran a nodos; Thornwood enseña a vivir en el margen que pierde fidelidad. Un Thornen lleva la corteza como pacto: quien te atraviesa, sangra.",
		"Tn",
		"Thornen",
		7
	),
	entry(
		"Skylorn",
		"Race",
		"Skylorn",
		"Nacidos del viento. Celeridad en la cumbre.",
		"Los Skylorn bajan de los picos de Skyreach, donde el viento aún guarda la corriente eléctrica. Su celeridad no es prisa vacía: es el arte de estar ya en el siguiente pulso. En las cumbres el mundo entra y sale de fidelidad a tajos de cielo; quien duda, cae. La Escisión les dejó un horizonte roto y ellos lo cruzan en ráfaga. Un Skylorn ata el aire al cuerpo y convierte la altura en filo.",
		"Sk",
		"Skylorn",
		8
	),
	entry(
		"Threshold",
		"Origin",
		"Threshold Reach",
		"Donde el Nodo responde por primera vez.",
		"Threshold Reach es el borde donde el Nodo responde por primera vez. No es capital ni corte: es la prueba de que un cuerpo puede atar corrientes y no deshacerse. Allí empieza todo Guardián del Umbral, entre la retícula que aún canta y el yermo que ya pierde fidelidad. Bajo la tierra espera el Node Undercroft; sobre ella, la Spire mide quién sostiene el pulso. Quien nace o se forma aquí aprende pericia: leer el Nodo antes de que falle.",
		"Th",
		"Threshold",
		1
	),
	entry(
		"Kynfall",
		"Origin",
		"Kynfall Gate",
		"Ciudad-puerta. Oficio y tenencia.",
		"Kynfall Gate es la ciudad-puerta del continente: oficio, tenencia y el único nodo que se atreve a llamarse en paz. Aquí se forja el cerrojo de la civilización —yunque, almacén, correo, veta— mientras el resto de las comarcas se disputan las corrientes. Los Guardianes que salen de la Puerta no olvidan que las ciudades se aferran a nodos estables; sin ese agarre, el mundo se desvanece. El Kyn ya no es un campo único, pero la Puerta insiste en actuar como si aún pudiera guardarse. Quien crece entre sus muros hereda el hábito de construir lo que otros sólo atraviesan.",
		"Ky",
		"Kynfall",
		2
	),
	entry(
		"Emberwatch",
		"Origin",
		"Emberwatch",
		"Plaza de la brasa. Mineral y calor.",
		"Emberwatch es plaza de mineral y calor, la marcha donde la escuela térmica no se apaga. Las forjas marcan el pulso del asentamiento; las vetas, el precio. Más allá del nodo el yermo arde a ráfagas, y el Cinder Vault recuerda que el calor también construye colosos. Un origen aquí enseña a extraer poder del suelo sin fingir que el Continuo siga entero. Quien sale de Emberwatch lleva la brasa como oficio, no como adorno.",
		"Ew",
		"Emberwatch",
		3
	),
	entry(
		"Palehaven",
		"Origin",
		"Palehaven",
		"Corte del pozo helado. Hielo y vigilia.",
		"Palehaven es la corte del pozo helado: hielo, vigilia y la escuela del frío hecha ley. El Frostwell no se contempla; se custodia. La resistencia de sus gentes nace de no ceder cuando el mundo entra y sale de fidelidad en blanco. Cuando el Kyn se partió, el frío dejó de ser clima y se volvió corriente; Palehaven fue de las primeras en ponerle guardia. Quien despierta aquí aprende que la belleza pálida corta igual que ampara.",
		"Ph",
		"Palehaven",
		4
	),
	entry(
		"Voidmarch",
		"Origin",
		"Voidmarch",
		"Campamento de grieta. Hueco y cacería.",
		"Voidmarch es campamento, no corte: grieta, hueco y cacería en el borde donde el vacío no se disculpa. Allí el mundo pierde fidelidad peor, y por eso se piensa con más filo. El Rift Hollow y la sombra de Voidmaw enseñan que algunas corrientes se atan o te desatan. Un origen en la marcha no promete hogar; promete claridad en el desgarro. Quien sobrevive al campamento sale con el intelecto abierto al fallo del Continuo.",
		"Vm",
		"Voidmarch",
		5
	),
	entry(
		"Tidehaven",
		"Origin",
		"Tidehaven",
		"Costa de la marea. Sal y espíritu.",
		"Tidehaven vive de sal y espíritu en la Tidecoast, donde el nodo sube y baja como la mar. El Tidehold ancla lo que la resaca querría llevarse. Aquí el Poder Astral se siente en el pecho antes que en la retícula: un pulso de espíritu que sostiene a la compañía. Más allá de la costa el mundo entra y sale de fidelidad; los de Tidehaven ya ensayaron esa pérdida cada marea. Quien nace o se forma aquí no teme el ciclo: lo convierte en aliento.",
		"Tv",
		"Tidehaven",
		6
	),
	entry(
		"Thornwood",
		"Origin",
		"Thornwood",
		"Extensión de zarzas. Raíz y espina.",
		"Thornwood es la extensión de zarzas: raíz, espina y pericia ganada en el roce. El zarzal no perdona el paso torpe; el Thornroot, menos. Cuando el Kyn se partió, la escuela tóxica encontró en este bosque un lenguaje, no un accidente. Las ciudades se aferran a nodos; Thornwood enseña a caminar el margen que pierde fidelidad. Quien sale del zarzal lee el terreno como otros leen un sello.",
		"Tw",
		"Thornwood",
		7
	),
	entry(
		"Skyreach",
		"Origin",
		"Skyreach",
		"Bastiones de pico. Viento y celeridad.",
		"Skyreach son bastiones de pico, viento y celeridad sobre el abismo. El Windspire corta el cielo donde la corriente eléctrica aún se niega a morir. En las cumbres el mundo entra y sale de fidelidad a tajos; la altura no perdona a quien duda un pulso. Un origen aquí enseña a llegar antes, no a gritar más fuerte. Quien desciende de Skyreach lleva el viento como disciplina, no como paisaje.",
		"Sr",
		"Skyreach",
		8
	),
	entry(
		"Warden",
		"Archetype",
		"Warden",
		"Placa y retícula. Sostén la Puerta.",
		"El Warden sostiene la Puerta con placa y retícula: tanque de la Guardia que convierte el cuerpo en cerrojo. Su recurso es esa Guardia, el privilegio de no ceder cuando las corrientes empujan. Ata calor y vacío al escudo con la misma disciplina con que ata el Kyn al acero. Sin un Warden, el nodo se disputa; con él, el umbral tiene peso. Tú no buscas la gloria del primer golpe: buscas que el último no atraviese a los tuyos.",
		"W",
		"Warden",
		1
	),
	entry(
		"Weaver",
		"Archetype",
		"Weaver",
		"Grieta y resplandor. Doblega el Nodo.",
		"El Weaver doblega el Nodo: taumaturgo de Foco que teje grieta y resplandor hasta que las escuelas vuelven a hablarse. La Escisión partió el Kyn; el Weaver insiste en volver a trenzarlo, aunque sea un instante. Grieta, meteoro, hielo y retícula no son adornos: son el Continuo forzado a recordar que fue uno. El Poder Astral le sirve de hilo, inestable y suficiente. Tú no lanzas signos contra el mundo: le recuerdas al mundo cómo se curvaba.",
		"Λ",
		"Weaver",
		2
	),
	entry(
		"Stalker",
		"Archetype",
		"Stalker",
		"Vacío y filo. Caza entre pulsos.",
		"El Stalker caza entre pulsos, filo de ímpetu que usa el vacío como pasillo. Donde el mundo pierde fidelidad, él ya está al otro lado. Emboscada, látigo y paso hueco convierten la grieta en oficio, no en miedo. Su cuerpo no espera la retícula perfecta: se mueve en el fallo. Tú no persigues a la presa en línea recta; la esperas donde el Continuo parpadea.",
		"S",
		"Stalker",
		3
	),
	entry(
		"Luminary",
		"Archetype",
		"Luminary",
		"Radiancia y retícula. Sana a los heridos.",
		"El Luminary restaña con Poder Astral, sanador que convierte la corriente radiante y el calor residual en aliento ajeno. No predica un culto importado: trabaja el remanente que la Escisión dejó cuando las escuelas se separaron. Sutura, gracia y guarda son formas de atar el pulso al cuerpo herido antes de que el nodo lo suelte. Sin Luminary, la compañía se desangra entre pérdidas de fidelidad. Tú sostienes a los Guardianes para que el umbral no se quede vacío.",
		"L",
		"Luminary",
		4
	),
	entry(
		"Sentinel",
		"Archetype",
		"Sentinel",
		"Alcance y marca. Fija la caza.",
		"El Sentinel fija la caza a distancia, tirador de Foco que marca antes de soltar. Su oficio es el alcance: clavar la retícula en un punto y no permitir que el mundo lo desdibuje. Disparo perforante, remate y fuego concentrado convierten la paciencia en filo. Más allá del nodo el yermo pierde fidelidad; el Sentinel apunta como si el Continuo aún tuviera coordenadas. Tú no llenas el cielo de proyectiles: eliges el pulso en el que la presa deja de existir.",
		"N",
		"Sentinel",
		5
	),
	entry(
		"Hexwright",
		"Archetype",
		"Hexwright",
		"Sello y podredumbre. Ata el hueco.",
		"El Hexwright ata el hueco con sello y podredumbre, taumaturgo de Foco que habla las escuelas tóxica, psíquica y de vacío sin pedir permiso. La Escisión no le asusta: le da vocabulario. Sello, veneno y trampa mental convierten el desgarro en contrato. Donde otros ven ruina, el Hexwright ve una corriente que aún puede ligarse a un cuerpo. Tú no sirves al hueco; le pones condiciones.",
		"H",
		"Hexwright",
		6
	),
	entry(
		"Vanguard",
		"Archetype",
		"Vanguard",
		"Carga y acero. Rompe la línea.",
		"El Vanguard rompe la línea, combate cuerpo a cuerpo de Carga que convierte el avance en recurso. No espera a que el enemigo llegue al nodo: lleva el cerrojo hasta su cara. Tajo amplio, martillo y ajuste de cuentas son la misma tesis: el acero también es una escuela, la que nació del sustrato físico cuando el Kyn se partió. Su ímpetu de vanguardia no es descontrol; es inercia dirigida. Tú no sostienes el muro: eres el muro que camina.",
		"V",
		"Vanguard",
		7
	),
	entry(
		"Tempest",
		"Archetype",
		"Tempest",
		"Tormenta y sobrecarga. Arca el cielo.",
		"El Tempest arca el cielo, taumaturgo de sobrecarga que obliga a las corrientes eléctrica, de calor y de frío a hablarse en el mismo relámpago. La sobrecarga no es lujo: es el privilegio de gastar el pulso más rápido de lo que el Nodo recomienda. Tormenta encadenada, glaciar y brasa convierten el clima roto en arma. Tras la Escisión, el cielo dejó de ser techo y se volvió campo de escuelas. Tú no esperas a que escampe: tú eres el frente.",
		"E",
		"Tempest",
		8
	),
	entry(
		"Templar",
		"Archetype",
		"Templar",
		"Égida y veredicto. Sostén lo radiante.",
		"El Templar es híbrido de Guardia y veredicto: acero que ata la corriente radiante sin soltar el escudo. No es ministro de un altar ajeno; es el oficio de juzgar el campo con lanza solar y placa. La Escisión dejó el resplandor como escuela; el Templar la pone al servicio del umbral, no de un culto. Protege o avanza, pero nunca deja la Guardia atrás. Tú sostienes lo radiante para que otros no tengan que mirar el desgarro desnudos.",
		"P",
		"Templar",
		9
	),
	entry(
		"Arbiter",
		"Archetype",
		"Arbiter",
		"Arenga y retícula. Juzga el campo.",
		"El Arbiter juzga el campo, apoyo de Poder Astral que arenga, marca y disipa. Su visión no es trance de templo: es lectura de la retícula en combate, el arte de decir dónde debe ir el pulso. Arenga, marca y recarga convierten a la compañía en un solo nudo. Las ciudades se aferran a nodos; el Arbiter enseña a una escuadra a ser nodo ambulante. Tú no ganas el duelo solo: decides quién todavía puede ganarlo.",
		"A",
		"Arbiter",
		10
	),
	entry(
		"Dragoon",
		"Archetype",
		"Dragoon",
		"Salto y lanza. Golpea desde el cielo.",
		"El Dragoon golpea desde el cielo, combate de ímpetu que convierte salto y lanza en una sola trayectoria. No cabalga bestias prestadas: usa la altura, la grieta y la interceptación para llegar antes de que la retícula del enemigo se cierre. Lanza, paso de grieta y golpe hueco son el mismo descenso. En Kynfall, el cielo pierde fidelidad a tajos; el Dragoon trata cada tajo como rampa. Tú no esperas en la línea: caes sobre ella.",
		"D",
		"Dragoon",
		11
	),
	entry(
		"Channeler",
		"Archetype",
		"Channeler",
		"Foco e inundación. Desborda el Nodo.",
		"El Channeler desborda el Nodo, taumaturgo de Foco que convierte la inundación en doctrina. Donde otros dosifican el Poder Astral, él abre la compuerta y sostiene el caudal hasta que el enemigo o el canal cede. Fuego concentrado, drenaje y tormenta astral son formas de decirle al remanente que deje de ser resto. Es peligroso: el Nodo no fue hecho para un solo pecho. Tú aceptas ese riesgo para que la Escisión, por un instante, vuelva a ser campo único.",
		"C",
		"Channeler",
		12
	),
}

local specEntries: { SpecPresentation } = {
	specRow(
		"Aegis",
		"Escudo y armadura. El muro que no cede.",
		"Aegis es la especialización del muro: armadura, barrera y el privilegio de no retroceder. El Warden que la elige convierte la Guardia en geometría —escudo, empujón de placa, fortificar— y sella el vacío para que no entre por la rendija. No persigue el pulso ofensivo; lo niega. Tras la Escisión, alguien tenía que ser el cerrojo cuando las corrientes empujan a la vez. Tú eres ese cerrojo: el umbral con nombre y placa."
	),
	specRow(
		"SpecPulse",
		"Radiancia y retícula. El pulso que marca.",
		"Pulse enseña al Warden a pelear con la retícula encendida: radiancia, lanza solar y la marca que delata el siguiente golpe. No abandona la Puerta; la hace brillar hasta que el enemigo no puede mirarla. La sobrecarga aquí no es fuga: es el pulso de Guardia convertido en poder de habilidad. La Escisión dejó la corriente radiante suelta; esta senda la clava al acero. Tú no eres un muro ciego: eres el muro que señala."
	),
	specRow(
		"SpecRift",
		"Grieta y meteoro. El Nodo se abre.",
		"Rift es la senda que abre el Nodo hasta el meteoro. El Weaver que la sigue trenza tiempo, hielo y retícula en una sola herida del Continuo. La forma de tejedor no es disfraz: es el cuerpo aceptando que el Kyn ya no cabe en un solo gesto. Maestría aquí significa precisión en el desgarro, no más ruido. Tú no pides permiso al cielo: lo bajas."
	),
	specRow(
		"SpecMend",
		"Sutura de corrientes. Cura en el fragor.",
		"Mend vuelve al Weaver hacia la sutura: curar en el fragor, limpiar lo que las escuelas infectan, restañar a muchos con el mismo hilo. No es un segundo Luminary; es la prueba de que la retícula también cose carne. El Foco se gasta en sostener cuerpos, no en abrir grietas. Quien sepa unir corrientes después de la Escisión puede unir heridas. Tú tejes para que la compañía no se deshaga entre pulsos."
	),
	specRow(
		"SpecLash",
		"Látigo y paso hueco. Corta entre pulsos.",
		"Lash es el látigo del Stalker: celeridad, paso vacío y el abanico de esquirlas que corta el aire entre pérdidas de fidelidad. La forma de acechador acepta el hueco como piel. Emboscada y golpe hueco convierten el fallo del Continuo en ritmo. No esperas el impacto perfecto; llegas tantas veces que el instante se vuelve irrelevante. Tú cazas en el parpadeo."
	),
	specRow(
		"SpecExecute",
		"Golpe final. Crítico en la herida.",
		"Execute es la tesis del golpe que termina. El Stalker que la elige espera la herida —sangrado, disparo perforante— y cobra cuando el pulso ajeno ya no sostiene el cuerpo. El crítico no es suerte: es lectura del instante en que la retícula del enemigo se abre. El ímpetu aquí se guarda para el final, no para el espectáculo. Tú no alargas la caza: la cierras."
	),
	specRow(
		"LuminaryGrace",
		"Gracia masiva. Calor que restaña.",
		"Grace es la gracia masiva del Luminary: restañar a muchos, calmar el campo y soltar la oleada de calor que cierra carne. El Poder Astral se vuelve aliento compartido, no reliquia de altar. La calma no niega el combate; da el segundo que la compañía no tenía. La corriente de calor, tan temida en Emberwatch, aquí se usa para no dejar morir. Tú eres la marea que empuja la vida de vuelta al nodo."
	),
	specRow(
		"LuminaryWard",
		"Barrera de hielo. Espíritu que cubre.",
		"Ward enseña al Luminary a cubrir antes que a restañar: barrera de hielo, sello y fortificar el espíritu de los suyos. El sanador se vuelve custodio, más cercano a la Guardia que al milagro. Palehaven entendería esta senda: el frío también es amparo. El espíritu aquí no es mística; es la reserva con la que el Poder Astral se niega a romperse. Tú pones el cristal entre el desgarro y la piel."
	),
	specRow(
		"SentinelMarksman",
		"Disparo que remata. Foco en el punto vital.",
		"Marksman es el ojo que remata. El Sentinel concentra Foco en el punto vital —disparo perforante, fuego preciso, el tiro que acaba— y deja que el crítico haga el resto. No corre la línea; la reduce a una coordenada. Más allá del nodo el mundo pierde fidelidad, pero la marca sigue siendo tuya. Tú no llenas el aire: eliges el silencio en el que cae el cuerpo."
	),
	specRow(
		"SentinelSkirmisher",
		"Retirada y carrera. Celeridad en cobertura.",
		"Skirmisher es la celeridad de quien no se deja clavar. Retirada, carrera corta y lance a cobertura convierten el alcance en movilidad, no en trinchera. El Sentinel de esta senda dispara y desaparece antes de que la grieta responda. La prisa aquí es supervivencia táctica: el yermo pierde fidelidad, tú ya no estás. Tú cazas en ráfagas y dejas el suelo vacío."
	),
	specRow(
		"HexwrightPlague",
		"Sangre y veneno. Maestría en la putrefacción.",
		"Plague cultiva la podredumbre como maestría: sangrado, estallido de veneno y el drenaje que paga el Foco con la vida ajena. La escuela tóxica de la Escisión encuentra aquí su gramática más fría. No es caos; es cultivo. El Hexwright de la plaga no grita el sello: deja que el cuerpo enemigo lo recuerde. Tú no buscas el hueco espectacular; buscas el que no se cierra."
	),
	specRow(
		"HexwrightPact",
		"Pacto y trampa. El sello clava la mente.",
		"Pact es el contrato con el hueco: sello, trampa de vacío y la púa psíquica que clava la mente. El poder de habilidad aquí nace de imponer condiciones, no de esperar a que la carne ceda sola. La escuela psíquica y la de vacío se dan la mano en un solo vínculo. El Hexwright de esta senda negocia con lo que la Escisión dejó suelto. Tú no imploras al desgarro: le dictas términos."
	),
	specRow(
		"VanguardJuggernaut",
		"Fortificar y atraer. Armadura que avanza.",
		"Juggernaut es el Vanguard que avanza como fortaleza: armadura, provocación y el quiebre de tierra que niega el suelo al enemigo. La Carga no lo vuelve temerario; lo vuelve inevitable. Fortificar en movimiento es la herejía útil de esta senda. Las ciudades se aferran a nodos; tú llevas el nodo en el pecho. Tú no flanqueas: ocupas."
	),
	specRow(
		"VanguardRavager",
		"Ajuste de cuentas. El tajo parte el suelo.",
		"Ravager es el ajuste de cuentas: tajo amplio, martillo que cae y el golpe que cobra deudas en el mismo pulso. El poder de ataque sustituye al muro; la Carga se gasta en romper, no en permanecer. El Vanguard de esta senda deja la línea hecha astillas. El sustrato físico de las escuelas —el acero que quedó cuando el Kyn se partió— habla aquí sin metáfora. Tú no custodias el umbral: lo empujas encima del enemigo."
	),
	specRow(
		"TempestStorm",
		"Látigo de tormenta. Arco encadenado.",
		"Storm es el látigo eléctrico: arco encadenado, tormenta astral y el chasquido que salta de pecho en pecho. El Tempest de esta senda obliga a la corriente eléctrica a recordar que fue Kyn. La sobrecarga se gasta en no dejar hueco entre relámpagos. El Poder Astral, remanente inestable, aquí se comporta como cielo. Tú no apuntas a uno: enseñas al campo a conducir."
	),
	specRow(
		"TempestFrostfire",
		"Glaciar y brasa. Maestría del contraste.",
		"Frostfire es la maestría del contraste: glaciar contra brasa, estallido de llama contra el hielo que no perdona. El Tempest que la elige no elige escuela; las obliga a pelearse dentro del mismo gesto. Calor y frío se separaron en la Escisión; esta senda los vuelve a estrellar. El dominio no es más fuego: es el instante en que ambas corrientes coinciden. Tú eres el frente donde Emberwatch y Palehaven se tocan sin paz."
	),
	specRow(
		"TemplarCrusader",
		"Lanza solar. Radiancia que juzga.",
		"Crusader es el avance del veredicto: lanza solar, radiancia y el golpe de escudo que convierte la Guardia en ofensiva. El Templar de esta senda no espera a ser asediado. La corriente radiante se ata al acero para juzgar el campo de cerca. No hay culto importado aquí, sólo el oficio de cruzar el umbral con resplandor de escuela y placa. Tú llevas el juicio al enemigo antes de que el nodo pida ayuda."
	),
	specRow(
		"TemplarProtector",
		"Guarda y arenga. Cubre a los tuyos.",
		"Protector es la Guardia compartida: sello, arenga y el lance que cubre al aliado antes que al orgullo. El Templar de esta senda entiende que el híbrido también significa llegar tarde al propio golpe si eso salva el pulso ajeno. La armadura aquí es promesa, no vanidad. Las ciudades se aferran a nodos; tú te aferras a tu escuadra. Tú sostienes lo radiante como techo, no como estandarte."
	),
	specRow(
		"ArbiterHerald",
		"Arenga y marca. Versatilidad en el campo.",
		"Herald es la voz que ordena el campo: arenga, oleada de calor y la marca de retícula que dice dónde duele. La versatilidad del heraldo no es indecisión; es el privilegio de cambiar de corriente según lo que la compañía necesite. El Poder Astral se gasta en hacer de muchos un solo nudo. Tras la Escisión, alguien tenía que hablarle al pulso en voz alta. Tú no susurras al Nodo: lo anuncias."
	),
	specRow(
		"ArbiterOracle",
		"Marca de caza. Espíritu que disipa.",
		"Oracle lee lo que la retícula oculta: marca de caza, recarga y el disipar que arranca sellos ajenos. El espíritu aquí es reserva de claridad, no trance de templo. El Arbiter de esta senda ve el hueco en el enemigo y el nudo en el aliado. El mundo pierde fidelidad; el oráculo insiste en las coordenadas. Tú no predices el destino: lo corriges antes de que cierre."
	),
	specRow(
		"DragoonLancer",
		"Intercepta y clava. La lanza abre grieta.",
		"Lancer es la lanza que llega primero: interceptación, golpe hueco y el paso de grieta que convierte el descenso en herida. El poder de ataque nace de la trayectoria, no del peso parado. El Dragoon de esta senda trata cada tajo del cielo como rampa hacia el pecho enemigo. El ímpetu se gasta en no estar donde te esperaban. Tú no rodeas la línea: la atraviesas de arriba abajo."
	),
	specRow(
		"DragoonPhantom",
		"Emboscada y paso vacío. Fantasma en el filo.",
		"Phantom es el fantasma del filo: emboscada, paso vacío y la puñalada que llega desde un pulso que el enemigo no vio. La celeridad sustituye al impacto espectacular. El Dragoon de esta senda usa el hueco como capucha, no como altar. Donde el mundo pierde fidelidad, el fantasma ya cambió de sitio. Tú no caes como meteoro: desapareces y reapareces en la herida."
	),
	specRow(
		"ChannelerConduit",
		"Foco y drenaje. El Nodo recarga.",
		"Conduit es el canal que no se rompe: fuego concentrado, drenaje y recarga para que el Nodo siga hablando a través de un solo pecho. El espíritu sostiene el caudal. El Channeler de esta senda dosifica la inundación para que dure la batalla, no el segundo. El Poder Astral es remanente inestable; el conducto le da cauce. Tú no eres la tormenta: eres el lecho que la hace útil."
	),
	specRow(
		"ChannelerAnnihilator",
		"Meteoro y tormenta. El Nodo desborda.",
		"Annihilator abre la compuerta del todo: meteoro, púa temporal y tormenta astral, con el faro que marca dónde debe caer el cielo. El poder de habilidad aquí no pide mesura. El Channeler acepta que un pecho no fue hecho para tanto Kyn y lo hace de todos modos. La Escisión partió el campo; esta senda finge, un instante, que volvió a ser uno —y lo estrella. Tú no canalizas para sostener: canalizas para que no quede nodo enemigo al que aferrarse."
	),
}

local byKey: { [string]: IdentityPresentation } = {}
for _, row in entries do
	local key = `{row.Kind}:{row.Id}`
	if byKey[key] ~= nil then
		error(`duplicate identity presentation {key}`)
	end
	if row.Blurb == "" then
		error(`IdentityPresentationCatalog empty Blurb {key}`)
	end
	if row.Lore == "" then
		error(`IdentityPresentationCatalog empty Lore {key}`)
	end
	byKey[key] = row
end

local specById: { [string]: SpecPresentation } = {}
for _, row in specEntries do
	if specById[row.Id] ~= nil then
		error(`duplicate spec presentation {row.Id}`)
	end
	specById[row.Id] = row
end

local requiredCount = 0
for _, specId in REQUIRED_SPEC_IDS do
	requiredCount += 1
	local row = specById[specId]
	if row == nil then
		error(`IdentityPresentationCatalog missing spec presentation {specId}`)
	end
	if row.Blurb == "" then
		error(`IdentityPresentationCatalog empty spec Blurb {specId}`)
	end
	if row.Lore == "" then
		error(`IdentityPresentationCatalog empty spec Lore {specId}`)
	end
end

local presentCount = 0
for _ in specById do
	presentCount += 1
end
if presentCount ~= requiredCount then
	error(`IdentityPresentationCatalog spec presentation count mismatch`)
end

local function collectKind(kind: IdentityKind): { IdentityPresentation }
	local rows: { IdentityPresentation } = {}
	for _, row in entries do
		if row.Kind == kind then
			table.insert(rows, row)
		end
	end
	table.sort(rows, function(a: IdentityPresentation, b: IdentityPresentation)
		if a.SortOrder == b.SortOrder then
			return a.Id < b.Id
		end
		return a.SortOrder < b.SortOrder
	end)
	return rows
end

local races = collectKind("Race")
local origins = collectKind("Origin")
local archetypes = collectKind("Archetype")

local IdentityPresentationCatalog = {}

function IdentityPresentationCatalog.get(id: string, kind: IdentityKind): IdentityPresentation?
	return byKey[`{kind}:{id}`]
end

function IdentityPresentationCatalog.allRaces(): { IdentityPresentation }
	return races
end

function IdentityPresentationCatalog.allOrigins(): { IdentityPresentation }
	return origins
end

function IdentityPresentationCatalog.allArchetypes(): { IdentityPresentation }
	return archetypes
end

function IdentityPresentationCatalog.getSpec(id: string): SpecPresentation?
	return specById[id]
end

function IdentityPresentationCatalog.lore(id: string, kind: IdentityKind): string
	local row = IdentityPresentationCatalog.get(id, kind)
	if row == nil then
		return ""
	end
	return row.Lore
end

function IdentityPresentationCatalog.color(colorKey: string): Color3
	local found = COLORS[colorKey]
	if found then
		return found
	end
	return GOLD
end

function IdentityPresentationCatalog.powerColor(archetypeId: string): Color3
	local found = POWER_COLORS[archetypeId]
	if found then
		return found
	end
	local row = IdentityPresentationCatalog.get(archetypeId, "Archetype")
	if row ~= nil then
		return IdentityPresentationCatalog.color(row.ColorKey)
	end
	return GOLD
end

return IdentityPresentationCatalog
