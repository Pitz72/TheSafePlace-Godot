extends Node

# Riferimenti ai manager e nodi
@onready var game_ui = $GameUI/GameUI
var world: Node # Riferimento al mondo, verrà impostato in _on_world_ready

# Sistema cooldown eventi
var event_cooldown_time: float = 30.0
var time_since_last_event: float = 0.0
var steps_since_last_event: int = 0
var steps_threshold: int = 10

# Probabilità eventi per bioma
var biome_probabilities = {
	"pianure": 0.35, "foreste": 0.45, "villaggi": 0.55, "città": 0.65,
	"fiumi": 0.40, "montagne": 0.30, "ristoro": 0.25
}

# Narrativa Biomi
var current_biome: String = ""
var biome_entry_messages = {
	"foreste": {"text": "Entri in una fitta foresta. Gli alberi sussurrano segreti antichi.", "color": "#34672a"},
	"pianure": {"text": "Una vasta pianura si apre davanti a te. L'orizzonte sembra infinito.", "color": "#a5c9a5"},
	"città": {"text": "Rovine di una città emergono dalla desolazione.", "color": "#c9c9c9"},
	"villaggio": {"text": "Un piccolo insediamento appare all'orizzonte.", "color": "#c9a57b"},
	"fiumi": {"text": "Raggiungi le sponde di un fiume. L'acqua scorre lenta e scura.", "color": "#1e7ba8"},
	"ristoro": {"text": "Scorgi un rifugio abbandonato. Le sue mura potrebbero offrirti riparo.", "color": "#ffdd00"}
}

# Narrativa Atmosfera
var atmosphere_timer: Timer
var time_since_last_message: float = 0.0
var atmosphere_message_cooldown: float = 45.0
var atmosphere_messages = [
	"Un silenzio innaturale ti circonda.",
	"Il vento ulula tra le rovine in lontananza.",
	"Per un attimo, hai la strana sensazione di essere osservato."
]


# ========================================
# FLUSSO DI INIZIALIZZAZIONE (RICOSTRUITO)
# ========================================

func _ready():
	print("🎮 MainGame: In attesa che il mondo sia pronto...")
	# L'unica responsabilità di MainGame._ready() è attendere che la UI segnali
	# che il mondo di gioco è stato istanziato e aggiunto alla scena.
	# CONNECT_ONE_SHOT assicura che la funzione venga chiamata una sola volta.
	game_ui.world_ready.connect(_on_world_ready, CONNECT_ONE_SHOT)
	
	# Inizializza i manager che non dipendono da scene (come EventManager)
	EventManager.initialize_events()
	if EventManager and not EventManager.event_triggered.is_connected(_on_event_triggered):
		EventManager.event_triggered.connect(_on_event_triggered)

	# Ora che abbiamo connesso il nostro listener, diciamo alla UI di procedere
	# con la creazione del mondo. Questo garantisce che non perderemo il segnale.
	game_ui.initialize_world()


# Callback eseguita SOLO quando GameUI ha finito di creare il mondo.
func _on_world_ready(world_instance: Node):
	print("✅ MainGame: Segnale world_ready ricevuto. Il mondo è pronto.")
	
	# 1. Salva il riferimento al mondo
	self.world = world_instance
	
	# 2. Connetti i segnali di movimento (ORA è sicuro farlo)
	# Connette l'input del giocatore al movimento fisico nel mondo
	InputManager.map_move.connect(world._on_map_move)
	# Connette il movimento fisico del mondo alla logica di gioco (eventi, tempo)
	world.player_moved.connect(self._on_player_moved)
	# Connette i messaggi narrativi del mondo
	if world.has_signal("narrative_message_sent"):
		world.narrative_message_sent.connect(self._on_world_narrative_message)
	
	print("✅ MainGame: Catena di segnali di movimento ripristinata.")

	# 3. Avvia la creazione del personaggio (ORA è il momento giusto)
	# Questo avviene una sola volta e solo dopo che il mondo esiste.
	var char_data = PlayerManager.prepare_new_character_data()
	game_ui.show_character_creation_popup(char_data)
	print("✅ MainGame: Sequenza di creazione personaggio avviata.")

	# 4. Emetti messaggi di benvenuto iniziali
	PlayerManager.narrative_log_generated.emit("[color=yellow]La sopravvivenza dipende dalle tue scelte.[/color]")
	PlayerManager.narrative_log_generated.emit("[color=yellow]Ogni passo è una decisione. Muoviti con [WASD] o le frecce.[/color]")
	PlayerManager.narrative_log_generated.emit("[color=yellow]Ogni passo sarà un'esperienza che ti renderà più forte.[/color]")
	PlayerManager.narrative_log_generated.emit("[color=yellow]Il viaggio inizia ora. Che la fortuna ti accompagni.[/color]")


# ========================================
# LOGICA DI GIOCO (INVARIATA)
# ========================================

func _process(delta):
	time_since_last_event += delta
	time_since_last_message += delta

	if time_since_last_message >= atmosphere_message_cooldown:
		var random_message = atmosphere_messages[randi() % atmosphere_messages.size()]
		PlayerManager.narrative_log_generated.emit(random_message)
		time_since_last_message = 0.0

func _on_player_moved(position: Vector2i, terrain_type: String):
	steps_since_last_event += 1
	
	var exp_gained = randi_range(5, 15) if TimeManager.is_night() else randi_range(5, 10)
	PlayerManager.add_experience(exp_gained, "esplorazione")
	
	var new_biome = _map_terrain_to_biome(terrain_type)

	if new_biome != current_biome:
		if biome_entry_messages.has(new_biome):
			var msg_data = biome_entry_messages[new_biome]
			PlayerManager.narrative_log_generated.emit("[color=%s]%s[/color]" % [msg_data.color, msg_data.text])
			time_since_last_message = 0.0
		current_biome = new_biome
	
	if _can_trigger_event(new_biome):
		_attempt_event_trigger(new_biome)

func _can_trigger_event(_biome: String) -> bool:
	return steps_since_last_event >= steps_threshold

func _attempt_event_trigger(biome: String):
	if biome == "ristoro":
		return
	
	var result = EventManager.trigger_random_event(biome)
	if result.get("triggered", false):
		_reset_cooldowns()

func _reset_cooldowns():
	steps_since_last_event = 0
	time_since_last_event = 0.0

func _on_event_triggered(event_data: Dictionary):
	time_since_last_message = 0.0
	if game_ui and game_ui.has_method("show_event_popup"):
		game_ui.show_event_popup(event_data)
	else:
		print("⚠️ GameUI non disponibile per mostrare evento")

func _map_terrain_to_biome(terrain_type: String) -> String:
	match terrain_type:
		"Foresta": return "foreste"
		"Pianura": return "pianure"
		"Montagna": return "montagne"
		"Città": return "città"
		"Villaggio": return "villaggio"
		"Ristoro": return "ristoro"
		"Fiume": return "fiumi"
		_: return "pianure"

func _on_world_narrative_message():
	time_since_last_message = 0.0
