extends Node

# Riferimenti ai manager
@onready var event_manager: EventManager
@onready var player_manager: PlayerManager
@onready var world: World
@onready var game_ui: Control

# Sistema cooldown eventi
var event_cooldown_time: float = 30.0  # 30 secondi tra eventi
var time_since_last_event: float = 0.0
var steps_since_last_event: int = 0
var steps_threshold: int = 5  # Minimo 5 passi prima di nuovo evento

# Probabilità eventi per bioma
var biome_probabilities = {
	"pianure": 0.15,
	"foreste": 0.25,
	"villaggi": 0.20,
	"città": 0.30,
	"fiumi": 0.18,
	"montagne": 0.12
}

# Narrativa Biomi
var current_biome: String = ""
var biome_entry_messages = {
	"foreste": {"text": "Entri in una fitta foresta. Gli alberi sussurrano segreti antichi.", "color": "green"},
	"pianure": {"text": "Una vasta pianura si apre davanti a te. L'orizzonte sembra infinito.", "color": "goldenrod"},
	"città": {"text": "Rovine di una città emergono dalla desolazione.", "color": "gray"},
	"villaggio": {"text": "Un piccolo insediamento appare all'orizzonte.", "color": "sandybrown"}
}

# Narrativa Atmosfera
var atmosphere_timer: Timer
var time_since_last_message: float = 0.0
var atmosphere_message_cooldown: float = 45.0  # Cooldown in secondi
var atmosphere_messages = [
	"Un silenzio innaturale ti circonda.",
	"Il vento ulula tra le rovine in lontananza.",
	"Per un attimo, hai la strana sensazione di essere osservato."
]


func _ready():
	print("🎮 MainGame inizializzato")
	
	# Ottieni riferimenti ai manager
	event_manager = EventManager
	player_manager = PlayerManager
	world = get_node("World") if has_node("World") else null
	game_ui = get_node("GameUI/GameUI") if has_node("GameUI/GameUI") else null
	
	# Connetti segnali se disponibili
	if world and world.has_signal("player_moved"):
		world.player_moved.connect(_on_player_moved)
		world.narrative_message_sent.connect(_on_world_narrative_message)
		print("✅ Connesso a World.player_moved e World.narrative_message_sent")
	else:
		print("⚠️ World o i suoi segnali non disponibili")
	
	if event_manager:
		event_manager.event_triggered.connect(_on_event_triggered)
		print("✅ Connesso a EventManager.event_triggered")
	
	# Emetti messaggi di benvenuto iniziali
	player_manager.narrative_log_generated.emit("[color=yellow]La sopravvivenza dipende dalle tue scelte.[/color]")
	player_manager.narrative_log_generated.emit("[color=yellow]Ogni passo è una decisione. Muoviti con [WASD] o le frecce.[/color]")
	player_manager.narrative_log_generated.emit("[color=yellow]Il viaggio inizia ora. Che la fortuna ti accompagni.[/color]")

	print("🎯 MainGame pronto per gestire eventi durante il gameplay")

# Aggiorna il timer del cooldown eventi
func _process(delta):
	time_since_last_event += delta
	time_since_last_message += delta

	# Controlla se è il momento di un messaggio di atmosfera
	if time_since_last_message >= atmosphere_message_cooldown:
		var random_message = atmosphere_messages[randi() % atmosphere_messages.size()]
		player_manager.narrative_log_generated.emit(random_message)
		time_since_last_message = 0.0 # Resetta il timer

# Gestisce il movimento del giocatore e triggera eventi
func _on_player_moved(position: Vector2i, terrain_type: String):
	print("🚶 Giocatore mosso in posizione: %s, terreno: %s" % [str(position), terrain_type])
	
	# Incrementa contatore passi
	steps_since_last_event += 1
	
	# Mappa terreno a bioma per EventManager
	var new_biome = _map_terrain_to_biome(terrain_type)

	# Controlla se il bioma è cambiato per il messaggio narrativo
	if new_biome != current_biome:
		if biome_entry_messages.has(new_biome):
			var msg_data = biome_entry_messages[new_biome]
			player_manager.narrative_log_generated.emit("[color=%s]%s[/color]" % [msg_data.color, msg_data.text])
			time_since_last_message = 0.0 # Resetta il timer atmosfera
		current_biome = new_biome
	
	# Verifica se può triggerare un evento
	if _can_trigger_event(new_biome):
		_attempt_event_trigger(new_biome)
	
	print("📊 Passi dall'ultimo evento: %d, Cooldown: %.1fs" % [steps_since_last_event, time_since_last_event])

# Verifica se può triggerare un evento (cooldown + passi)
func _can_trigger_event(biome: String) -> bool:
	var time_ok = time_since_last_event >= event_cooldown_time
	var steps_ok = steps_since_last_event >= steps_threshold
	return time_ok and steps_ok

# Tenta di triggerare un evento basato su probabilità bioma
func _attempt_event_trigger(biome: String):
	var trigger_chance = biome_probabilities.get(biome, 0.1)
	
	if randf() <= trigger_chance:
		print("🎲 Evento triggerato per bioma: %s (probabilità: %.1f%%)" % [biome, trigger_chance * 100])
		event_manager.trigger_random_event(biome)
		_reset_cooldowns()
	else:
		print("🎲 Evento non triggerato per %s (probabilità: %.1f%%)" % [biome, trigger_chance * 100])

# Reset dei cooldown dopo un evento
func _reset_cooldowns():
	steps_since_last_event = 0
	time_since_last_event = 0.0
	print("⏰ Cooldown eventi resettato")

# Gestisce l'evento triggerato dall'EventManager
func _on_event_triggered(event_data: Dictionary):
	print("🎯 Evento ricevuto: %s" % event_data.get("title", "Sconosciuto"))
	time_since_last_message = 0.0 # Resetta il timer atmosfera
	
	# Passa l'evento al GameUI per la visualizzazione
	if game_ui and game_ui.has_method("show_event_popup"):
		game_ui.show_event_popup(event_data)
	else:
		print("⚠️ GameUI non disponibile per mostrare evento")

# Funzione debug per forzare eventi
func force_trigger_event(target_biome: String = ""):
	var biome = target_biome
	if biome == "":
		biome = ["forest", "plains", "mountains", "urban"][randi() % 4]
	
	print("🔧 DEBUG: Forzando evento per bioma: %s" % biome)
	event_manager.trigger_random_event(biome)
	_reset_cooldowns()

# Mappa il tipo di terreno di World ai biomi di EventManager
func _map_terrain_to_biome(terrain_type: String) -> String:
	match terrain_type:
		"Foresta":
			return "forest"
		"Pianura":
			return "plains"
		"Montagna":
			return "mountains"
		"Città", "Villaggio", "Ristoro":
			return "urban"
		"Fiume":
			return "plains"  # Fiume considerato come pianura
		_:
			return "plains"  # Default

# Funzioni di utilità per debug
func get_steps_until_next_event() -> int:
	return max(0, steps_threshold - steps_since_last_event)

func get_time_until_next_event() -> float:
	return max(0.0, event_cooldown_time - time_since_last_event)

func _on_world_narrative_message():
	time_since_last_message = 0.0 # Resetta il timer atmosfera
