extends Node

# Riferimenti ai manager
@onready var event_manager: EventManager
@onready var player_manager: PlayerManager
@onready var world: World
@onready var game_ui: Control

# Segnali per sistema rifugi
signal shelter_status_changed(is_in_shelter: bool)

# Sistema cooldown eventi
var event_cooldown_time: float = 30.0  # 30 secondi tra eventi
var time_since_last_event: float = 0.0
var steps_since_last_event: int = 0
var steps_threshold: int = 10  # Minimo 10 passi prima di nuovo evento

# Stato rifugio
var is_in_shelter: bool = false

# Contatore per evitare loop infinito nella connessione segnali
var connection_attempts: int = 0
const MAX_CONNECTION_ATTEMPTS: int = 10

# Probabilità eventi per bioma (allineate con EventManager)
# NOTA: Montagne rimosse - terreno invalicabile, eventi redistribuiti
var biome_probabilities = {
	"pianure": 0.38,
	"foreste": 0.48,
	"villaggi": 0.58,
	"città": 0.68,
	"fiumi": 0.43,
	# montagne: RIMOSSO - invalicabile
	"ristoro": 0.25
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
var atmosphere_message_cooldown: float = 45.0  # Cooldown in secondi
var atmosphere_messages = [
	"Un silenzio innaturale ti circonda.",
	"Il vento ulula tra le rovine in lontananza.",
	"Per un attimo, hai la strana sensazione di essere osservato."
]


func _ready():
	print("🎮 MainGame: Inizio sequenza di avvio UNIFICATA.")
	
	# 1. Inizializza i manager che contengono dati
	EventManager.initialize_events()
	
	# 2. Prepara dati personaggio (senza applicarli)
	var char_data = PlayerManager.prepare_new_character_data()
	
	# 2.5. Ordina alla GameUI di mostrare il popup di creazione personaggio
	game_ui = get_node("/root/MainGame/GameUI/GameUI")
	if game_ui and game_ui.has_method("show_character_creation_popup"):
		game_ui.show_character_creation_popup(char_data)
	else:
		print("⚠️ MainGame: GameUI o show_character_creation_popup() non trovata!")
	
	# 3. Connetti i segnali globali (se necessario)
	_connect_signals() # Assicurati che questa funzione esista e sia corretta
	
	print("✅ MainGame: Flusso di avvio completato.")

func _connect_signals() -> void:
	print("🔌 MainGame: Connessione segnali...")

	# Connetti a EventManager
	if EventManager:
		if not EventManager.event_triggered.is_connected(_on_event_triggered):
			EventManager.event_triggered.connect(_on_event_triggered)
			print("✅ Connesso a EventManager.event_triggered")

	# Connetti a InputManager per azioni rifugio
	if InputManager:
		if not InputManager.shelter_action_requested.is_connected(_on_shelter_action_requested):
			InputManager.shelter_action_requested.connect(_on_shelter_action_requested)
			print("✅ Connesso a InputManager.shelter_action_requested")

	# Connetti a World (tramite GameUI)
	if game_ui and game_ui.has_method("get_world_scene"):
		world = game_ui.get_world_scene()
		if world and world.has_signal("player_moved"):
			# Connetti InputManager.map_move a World._on_map_move (CATENA MOVIMENTO)
			if InputManager and not InputManager.map_move.is_connected(world._on_map_move):
				InputManager.map_move.connect(world._on_map_move)
				print("✅ Connesso InputManager.map_move a World._on_map_move")
			
			# Connetti World.player_moved a MainGame._on_player_moved
			if not world.player_moved.is_connected(_on_player_moved):
				world.player_moved.connect(_on_player_moved)
				print("✅ Connesso a World.player_moved")
				
			if not world.narrative_message_sent.is_connected(_on_world_narrative_message):
				world.narrative_message_sent.connect(_on_world_narrative_message)
				print("✅ Connesso a World.narrative_message_sent")
		else:
			print("⏳ World non ancora disponibile dal GameUI, tento connessione differita...")
			call_deferred("_try_connect_world_signals")
	else:
		print("⚠️ GameUI o metodo get_world_scene non disponibile per la connessione dei segnali.")

	# Emetti messaggi di benvenuto iniziali
	PlayerManager.narrative_log_generated.emit("[color=yellow]La sopravvivenza dipende dalle tue scelte.[/color]")
	PlayerManager.narrative_log_generated.emit("[color=yellow]Ogni passo è una decisione. Muoviti con [WASD] o le frecce.[/color]")
	PlayerManager.narrative_log_generated.emit("[color=yellow]Ogni passo sarà un'esperienza che ti renderà più forte.[/color]")
	PlayerManager.narrative_log_generated.emit("[color=yellow]Il viaggio inizia ora. Che la fortuna ti accompagni.[/color]")

# Tenta di connettere i segnali del World istanziato da GameUI in modo differito
func _try_connect_world_signals():
	# Incrementa contatore per evitare loop infinito
	connection_attempts += 1
	
	# Controlla se abbiamo superato il limite di tentativi
	if connection_attempts > MAX_CONNECTION_ATTEMPTS:
		push_error("MainGame: Impossibile connettere World signals dopo %d tentativi" % MAX_CONNECTION_ATTEMPTS)
		print("❌ MainGame: Timeout connessione World signals")
		return
	
	if not game_ui or not game_ui.has_method("get_world_scene"):
		print("⏳ MainGame: GameUI non ancora pronto, tentativo %d/%d" % [connection_attempts, MAX_CONNECTION_ATTEMPTS])
		call_deferred("_try_connect_world_signals")
		return
		
	var w = game_ui.get_world_scene()
	if w and w.has_signal("player_moved"):
		world = w
		# Connetti InputManager.map_move a World._on_map_move (CATENA MOVIMENTO)
		if InputManager and not InputManager.map_move.is_connected(world._on_map_move):
			InputManager.map_move.connect(world._on_map_move)
			print("✅ Connesso InputManager.map_move a World._on_map_move (deferred)")
		
		if not world.player_moved.is_connected(_on_player_moved):
			world.player_moved.connect(_on_player_moved)
			print("✅ Connesso a World.player_moved (deferred)")
		if not world.narrative_message_sent.is_connected(_on_world_narrative_message):
			world.narrative_message_sent.connect(_on_world_narrative_message)
			print("✅ Connesso a World.narrative_message_sent (deferred)")
			
		# Reset contatore su successo
		connection_attempts = 0
		print("✅ MainGame: Tutti i segnali World connessi con successo")
	else:
		print("⏳ MainGame: World non ancora disponibile, tentativo %d/%d" % [connection_attempts, MAX_CONNECTION_ATTEMPTS])
		call_deferred("_try_connect_world_signals")

# Aggiorna il timer del cooldown eventi
func _process(delta):
	time_since_last_event += delta
	time_since_last_message += delta

	# Controlla se è il momento di un messaggio di atmosfera
	if time_since_last_message >= atmosphere_message_cooldown:
		var random_message = atmosphere_messages[randi() % atmosphere_messages.size()]
		PlayerManager.narrative_log_generated.emit(random_message)
		time_since_last_message = 0.0 # Resetta il timer

# Gestisce il movimento del giocatore e triggera eventi
func _on_player_moved(position: Vector2i, terrain_type: String):
	print("🚶 Giocatore mosso in posizione: %s, terreno: %s" % [str(position), terrain_type])
	
	# Incrementa contatore passi
	steps_since_last_event += 1
	
	# Guadagna esperienza per il movimento (5-10 di giorno, 5-15 di notte)
	var exp_gained: int
	if TimeManager.is_night():
		exp_gained = randi_range(5, 15)  # Più esperienza di notte per la difficoltà
	else:
		exp_gained = randi_range(5, 10)  # Esperienza normale di giorno
	
	# Aggiungi esperienza (i messaggi sono gestiti internamente da PlayerManager)
	PlayerManager.add_experience(exp_gained, "esplorazione")
	
	# Mappa terreno a bioma per EventManager
	var new_biome = _map_terrain_to_biome(terrain_type)

	# GESTIONE STATO RIFUGIO
	var was_in_shelter = is_in_shelter
	is_in_shelter = (new_biome == "ristoro")

	# Se lo stato rifugio è cambiato, emetti segnale e aggiorna crafting
	if was_in_shelter != is_in_shelter:
		shelter_status_changed.emit(is_in_shelter)
		_update_crafting_access(is_in_shelter)
		print("🏠 Stato rifugio cambiato: %s" % ["ENTRATO" if is_in_shelter else "USCITO"])

		# Se entriamo in un rifugio di giorno, mostra popup opzioni
		if is_in_shelter and not TimeManager.is_night():
			_show_day_shelter_popup()
	
	# GESTIONE RIFUGIO NOTTURNO
	if is_in_shelter and TimeManager.is_night():
		print("🌙 Rifugio notturno - unica opzione: riposo completo fino al mattino")
		_shelter_night_rest()
		return  # Non continuare con eventi normali

	# Controlla se il bioma è cambiato per il messaggio narrativo
	if new_biome != current_biome:
		if biome_entry_messages.has(new_biome):
			var msg_data = biome_entry_messages[new_biome]
			PlayerManager.narrative_log_generated.emit("[color=%s]%s[/color]" % [msg_data.color, msg_data.text])
			time_since_last_message = 0.0 # Resetta il timer atmosfera
		current_biome = new_biome
	
	# Verifica se può triggerare un evento
	if _can_trigger_event(new_biome):
		_attempt_event_trigger(new_biome)
	
	print("📊 Passi dall'ultimo evento: %d" % [steps_since_last_event])

# Verifica se può triggerare un evento (cooldown + passi)
func _can_trigger_event(_biome: String) -> bool:
	# Regola attuale: solo numero di passi, niente cooldown temporale
	return steps_since_last_event >= steps_threshold

# Tenta di triggerare un evento basato su probabilità bioma
func _attempt_event_trigger(biome: String):
	# NUOVA LOGICA: I rifugi NON hanno eventi casuali, ma azioni contestuali
	if biome == "ristoro":
		print("🏠 Rifugio rilevato - eventi casuali disattivati, azioni contestuali attive")
		return
	
	print("🎲 Tentativo evento per bioma: %s" % biome)
	var result = EventManager.trigger_random_event(biome)
	if result.get("triggered", false):
		_reset_cooldowns()
		print("✅ Evento triggerato con successo")
	else:
		print("❌ Evento non triggerato: %s" % result.get("reason", "unknown"))

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
	EventManager.trigger_random_event(biome)
	_reset_cooldowns()

# Mappa il tipo di terreno di World ai biomi di EventManager
func _map_terrain_to_biome(terrain_type: String) -> String:
	match terrain_type:
		"Foresta":
			return "foreste"
		"Pianura":
			return "pianure"
		"Montagna":
			return "montagne"
		"Città":
			return "città"
		"Villaggio":
			return "villaggio"
		"Ristoro":
			return "ristoro"  # Ristoro ora ha il suo bioma specifico
		"Fiume":
			return "fiumi"  # Fiume ora ha il suo bioma
		_:
			return "pianure"  # Default

# Funzioni di utilità per debug
func get_steps_until_next_event() -> int:
	return max(0, steps_threshold - steps_since_last_event)

func get_time_until_next_event() -> float:
	return max(0.0, event_cooldown_time - time_since_last_event)

func _on_world_narrative_message():
	time_since_last_message = 0.0 # Resetta il timer atmosfera

# ============================================================================
# SISTEMA RIFUGI CONTESTUALI
# ============================================================================

# Gestisce le azioni richieste dal rifugio (callback da InputManager)
func _on_shelter_action_requested(action_index: int):
	print("🏠 Azione rifugio richiesta: %d" % action_index)
	
	match action_index:
		1:  # Riposa
			_shelter_action_rest()
		2:  # Cerca Risorse
			_shelter_action_search_resources()
		3:  # Banco da Lavoro (Non disponibile)
			_shelter_action_workbench()
		4:  # Lascia il Rifugio
			_shelter_action_leave()
		_:
			print("⚠️ Azione rifugio non valida: %d" % action_index)

# Azione rifugio: Riposa (Recupera 10 HP, +2 ore)
func _shelter_action_rest():
	print("😴 Riposi nel rifugio...")
	
	# Applica benefici
	PlayerManager.modify_hp(10)
	TimeManager.advance_time_by_moves(4)  # 4 mosse = 2 ore
	
	# Messaggio narrativo
	PlayerManager.narrative_log_generated.emit("[color=#ffdd00]Ti concedi un riposo rigenerante nel rifugio. Recuperi 10 HP.[/color]")
	PlayerManager.narrative_log_generated.emit("[color=#888888]Tempo trascorso: 2 ore[/color]")

# Azione rifugio: Cerca Risorse (+30 min, skill check)
func _shelter_action_search_resources():
	print("🔍 Cerchi risorse nel rifugio...")
	
	# Skill check Intelligenza DC 12
	var skill_result = SkillCheckManager.perform_check("intelligenza", 12)
	
	# Fai passare 30 minuti in ogni caso
	TimeManager.advance_time_by_moves(1)  # 1 mossa = 30 minuti
	
	if skill_result.success:
		# Successo: dai 2 oggetti casuali
		var items_found = _get_random_shelter_items(2)
		for item in items_found:
			PlayerManager.add_item(item.id, item.quantity)
		
		PlayerManager.narrative_log_generated.emit("[color=#00ff00]Frugando con attenzione, trovi alcuni oggetti utili nascosti nel rifugio![/color]")
		PlayerManager.narrative_log_generated.emit("[color=#888888]Tempo trascorso: 30 minuti[/color]")
	else:
		# Fallimento: nessun oggetto
		PlayerManager.narrative_log_generated.emit("[color=#ff6666]Cerchi accuratamente ma non trovi nulla di utile. Qualcuno è già passato di qui.[/color]")
		PlayerManager.narrative_log_generated.emit("[color=#888888]Tempo trascorso: 30 minuti[/color]")

# Azione rifugio: Banco da Lavoro
func _shelter_action_workbench():
	if CraftingManager and CraftingManager.has_workbench():
		_show_crafting_interface()
	else:
		PlayerManager.narrative_log_generated.emit("[color=#888888]Il banco da lavoro è troppo danneggiato per essere utilizzato al momento.[/color]")

# Azione rifugio: Lascia il Rifugio
func _shelter_action_leave():
	PlayerManager.narrative_log_generated.emit("[color=#ffdd00]Lasci il rifugio e ti prepari a continuare il viaggio.[/color]")

# Mostra popup per il rifugio diurno con opzioni
func _show_day_shelter_popup():
	print("☀️ Mostrando popup rifugio diurno")

	# Carica e istanzia la scena ShelterPopup
	var popup_scene = load("res://scenes/ui/popups/ShelterPopup.tscn")
	if popup_scene == null:
		push_error("MainGame: Impossibile caricare ShelterPopup.tscn")
		return

	var popup_instance = popup_scene.instantiate()
	print("🏠 Popup istanziato: %s" % popup_instance)

	# Aggiungi popup al GameUI (CanvasLayer) invece che alla scena principale
	var game_ui = get_node("/root/MainGame/GameUI/GameUI")
	if game_ui:
		game_ui.add_child(popup_instance)
		print("🏠 Popup aggiunto al GameUI (CanvasLayer)")
	else:
		push_error("MainGame: GameUI non trovato per aggiungere popup")
		return

	# Connetti segnali
	popup_instance.popup_closed.connect(_on_shelter_popup_closed.bind(popup_instance))
	popup_instance.shelter_action_requested.connect(_on_shelter_action_requested)
	print("🏠 Segnali popup connessi")

	# Mostra il popup con opzioni diurne
	popup_instance.show_day_shelter()
	print("🏠 show_day_shelter() chiamato")

# Riposo notturno completo fino alle 6:00 del mattino
func _shelter_night_rest():
	print("🌙 Iniziando riposo notturno completo nel rifugio")

	# Calcola ore fino alle 6:00 del mattino
	var current_hour = TimeManager.current_hour
	var hours_until_morning = (24 - current_hour) + 6  # Da ora fino a mezzanotte + fino alle 6

	# Converti in mosse (ogni mossa = 30 minuti)
	var moves = hours_until_morning * 2

	# Applica riposo completo
	TimeManager.advance_time_by_moves(moves)
	TimeManager.current_hour = 6  # Forza alle 6:00
	TimeManager.current_minute = 0

	# Recupero completo (più del riposo normale)
	PlayerManager.modify_hp(50)  # Recupero maggiore per riposo notturno
	PlayerManager.modify_food(-20)  # Consumo notturno fame
	PlayerManager.modify_water(-30)  # Consumo notturno sete

	# Messaggio narrativo
	PlayerManager.narrative_log_generated.emit("[color=#4169E1]Passi la notte al sicuro nel rifugio. Ti svegli riposato alle 6:00 del mattino.[/color]")
	PlayerManager.narrative_log_generated.emit("[color=#888888]Notte trascorsa: Recuperi 50 HP ma consumi risorse per il riposo.[/color]")

	print("🌅 Riposo notturno completato - ora: 06:00")

func _on_shelter_popup_closed(popup_instance):
	print("🏠 Popup rifugio chiuso")
	# Rimuovi popup dalla scena
	if popup_instance and is_instance_valid(popup_instance):
		popup_instance.queue_free()

# Aggiorna l'accesso al crafting nei rifugi
func _update_crafting_access(has_access: bool):
	if CraftingManager:
		CraftingManager.set_workbench_access(has_access)
		print("🔨 Accesso crafting aggiornato: %s" % ("ABILITATO" if has_access else "DISABILITATO"))

# Mostra l'interfaccia di crafting
func _show_crafting_interface():
	print("🔨 Apertura interfaccia crafting...")
	# Per ora, mostra semplicemente le ricette disponibili
	var recipes = CraftingManager.get_craftable_recipes()
	var message = "[color=#00ff00]Ricette disponibili al banco da lavoro:[/color]\n"
	for recipe_id in recipes:
		var recipe = CraftingManager.get_recipe_data(recipe_id)
		if recipe:
			message += "• %s\n" % recipe.get("name", recipe_id)
	PlayerManager.narrative_log_generated.emit(message)

# Ottieni oggetti casuali trovabili nel rifugio
func _get_random_shelter_items(count: int) -> Array[Dictionary]:
	var possible_items = [
		{"id": "battery", "quantity": 1},
		{"id": "flashlight", "quantity": 1},
		{"id": "ration_pack", "quantity": 1},
		{"id": "bandage", "quantity": 2},
		{"id": "water_bottle", "quantity": 1}
	]
	
	var items_found: Array[Dictionary] = []
	for i in range(count):
		if possible_items.size() > 0:
			items_found.append(possible_items.pick_random())
	
	return items_found

# ============================================================================
# FUNZIONI DEBUG
# ============================================================================

# DEBUG: Forza l'ora notturna per testare il popup
func _debug_force_night():
	print("🔧 DEBUG: Forzando ora notturna (20:00)")
	TimeManager.current_hour = 20
	TimeManager.current_minute = 0
	PlayerManager.narrative_log_generated.emit("[color=#ffaa00]DEBUG: Ora forzata a 20:00 per test popup notturno[/color]")

func _input(event):
	# DEBUG: Premi F10 per forzare la notte (solo per eventi tastiera)
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_F10:
		_debug_force_night()
