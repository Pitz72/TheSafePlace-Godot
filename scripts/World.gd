extends Node2D
class_name World

# ============================================================================
# WORLD SCRIPT FINALE v2.1 - The Safe Place 
# ============================================================================
# Sistema completo di mondo interattivo con:
# - TileMap ottimizzato per rendering
# - Sprite2D animato per effetti player (lampeggio)
# - Penalità movimento per attraversamento fiumi
# - Camera con limiti calcolati automaticamente e fix saltello
# - Gestione collisioni avanzata
# - Log movimento real-time e pannello informazioni
# ============================================================================

# SEGNALI PER COMUNICAZIONE UI
signal player_moved(new_position: Vector2i, terrain_type: String)
signal narrative_message_sent()

# REFERENZE NODI SCENA
@onready var ascii_tilemap: TileMap = $AsciiTileMap
@onready var special_points: Node2D = $SpecialPoints
@onready var player_character: Sprite2D = $PlayerCharacter
@onready var camera: Camera2D = $Camera2D

# CONFIGURAZIONE MAPPA
const MAP_FILE_PATH = "res://mappa_ascii_gdr.txt"
const TILESET_PATH = "res://tilesets/ascii_tileset.tres"
const TILE_SIZE = 16  # Dimensione tile in pixel

# MAPPING CARATTERI ASCII → TILE ID (AGGIORNATO CON RISTORO)
# Ordine aggiornato nel TileSet (con aggiunta tile Ristoro):
var char_to_tile_id = {
	".": 0,  # Pianura (terrain) - #a5c9a5
	"F": 1,  # Foresta - #34672a  
	"M": 2,  # Montagna - #675945 (CON COLLISION!)
	"~": 3,  # Fiume - #1e7ba8 (PENALITÀ MOVIMENTO!)
	"V": 4,  # Villaggio - #c9a57b
	"C": 5,  # Città - #c9c9c9
	"R": 6,  # Ristoro - #ffdd00 (NUOVO!)
	"S": 8,  # Start Point - end_point.png (CORRETTI!)
	"E": 7   # End Point - start_point.png (CORRETTI!)
}

# MAPPING CARATTERI → NOMI TERRENI (per log movimento)
var char_to_terrain_name = {
	".": "Pianura",
	"F": "Foresta",
	"M": "Montagna",
	"~": "Fiume",
	"V": "Villaggio",
	"C": "Città",
	"R": "Ristoro",
	"S": "Punto di Partenza",
	"E": "Destinazione"
}

# MAPPING DIREZIONI → NOMI (per log movimento)
var direction_to_name = {
	Vector2i(0, -1): "Nord",
	Vector2i(0, 1): "Sud",
	Vector2i(-1, 0): "Ovest",
	Vector2i(1, 0): "Est"
}

# STATO PLAYER E MOVIMENTO
var player_pos: Vector2i = Vector2i(0, 0)
var movement_penalty: int = 0  # Penalità movimento (fiume)
var map_data: Array[String] = []
var map_width: int = 0
var map_height: int = 0

# Narrativa Montagne
var mountain_fail_messages = [
	"[color=orange]Quella montagna non sembra volersi spostare.[/color]",
	"[color=orange]Anche con la rincorsa, non se ne parla.[/color]",
	"[color=orange]La montagna ti guarda con aria di sfida. Tu declini educatamente.[/color]",
	"[color=orange]Fisica: 1, Ottimismo: 0.[/color]"
]

# Narrativa Fiumi
var river_crossing_messages = [
	"[color=#1e7ba8]L'acqua gelida ti toglie il fiato per un istante.[/color]",
	"[color=#1e7ba8]Guadare il fiume richiede uno sforzo notevole.[/color]"
]

# Nuovi messaggi di successo attraversamento fiume
var river_success_messages = [
	"[color=#1e7ba8]Con un balzo agile, superi il fiume senza bagnarti i piedi.[/color]",
	"[color=#1e7ba8]Attraversi il corso d'acqua con sorprendente destrezza.[/color]",
	"[color=#1e7ba8]L'azione è stata completata con successo.[/color]",
	"[color=#1e7ba8]Tutto procede secondo i piani.[/color]"
]

# Messaggi di fallimento skill check fiume
var river_failure_messages = [
	"[color=red]L'azione non è riuscita come previsto.[/color]",
	"[color=red]Qualcosa è andato storto.[/color]"
]

func _handle_river_crossing() -> void:
	"""Gestisce narrativa e skill check per attraversamento fiume secondo nuove regole"""
	if PlayerManager:
		# 1) Messaggio di attraversamento base (blu), sempre
		var base_msg = river_crossing_messages[randi() % river_crossing_messages.size()]
		PlayerManager.narrative_log_generated.emit(base_msg)
		
		# 2) Skill check leggero: di giorno molto facile, di notte leggermente più difficile
		var is_night = TimeManager and TimeManager.is_night()
		var dc = 7 if is_night else 5  # DC estremamente bassa
		# Usa AGILITÀ come stat di default per il guado
		var result = PlayerManager.skill_check("agilita", dc, 0)
		
		if result.get("success", false):
			# Messaggio di successo extra (blu)
			var ok_msg = river_success_messages[randi() % river_success_messages.size()]
			PlayerManager.narrative_log_generated.emit(ok_msg)
		else:
			# Fallimento: piccolissima chance di perdere 1-2 HP (più probabile di notte)
			# Probabilità: giorno 5%, notte 12%
			var chance = 0.12 if is_night else 0.05
			var damage = 0
			if randf() < chance:
				# 70% → 1 HP, 30% → 2 HP
				damage = 1 if randf() < 0.7 else 2
				PlayerManager.modify_hp(-damage)
				PlayerManager.narrative_log_generated.emit("[color=red]Perdi %d HP durante l'attraversamento del fiume.[/color]" % damage)
			# Messaggio rosso di fallimento narrativo (sempre mostrato sul fallimento)
			var fail_msg = river_failure_messages[randi() % river_failure_messages.size()]
			PlayerManager.narrative_log_generated.emit(fail_msg)

# CAMERA SMOOTH TARGET (FIX SALTELLO)
var target_camera_position: Vector2 = Vector2.ZERO

# ============================================================================
# INIZIALIZZAZIONE SISTEMA
# ============================================================================

func _ready():
	# Debug rimosso per ridurre log
	
	# 1. Configura TileMap
	_setup_tilemap()
	
	# 2. Carica e processa mappa
	_load_map()
	
	# 3. Configura camera con zoom e limiti
	_setup_camera()
	
	# 4. Disegna player iniziale
	_update_player_position()
	
	# 5. Avvia animazione di lampeggio
	player_character.get_node("AnimationPlayer").play("pulse")
	
	# La logica di connessione dei segnali è stata spostata in MainGame.gd
	# per centralizzare il flusso di inizializzazione.
	
	# Debug rimosso per ridurre log

func _setup_tilemap():
	"""Configura il TileMap con il TileSet aggiornato"""
	if ascii_tilemap == null:
		# Debug rimosso per ridurre log
		pass
		return
	
	# Carica TileSet con nuova palette
	var tileset = load(TILESET_PATH)
	if tileset == null:
		# Debug rimosso per ridurre log
		pass
		return
	
	ascii_tilemap.tile_set = tileset
	# Debug rimosso per ridurre log

func _setup_camera():
	"""Configura camera con zoom ottimizzato e limiti automatici"""
	if camera == null:
		# Debug rimosso per ridurre log
		pass
		return
	
	# APPROCCIO 1: Zoom ottimizzato per player più visibile
	# Calcolo: 0.925 (vecchio target) + 15% = 1.065x
	camera.zoom = Vector2(1.065, 1.065)
	
	# Calcola limiti mappa in pixel
	var map_width_pixels = map_width * TILE_SIZE
	var map_height_pixels = map_height * TILE_SIZE
	
	# Imposta limiti camera per evitare uscire dalla mappa
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = map_width_pixels
	camera.limit_bottom = map_height_pixels
	
	# Inizializza posizione target camera
	var world_pos = Vector2(player_pos.x * TILE_SIZE, player_pos.y * TILE_SIZE)
	target_camera_position = world_pos
	camera.position = world_pos
	camera.force_update_scroll()
	
	# Debug rimosso per ridurre log

# ============================================================================
# PHYSICS PROCESS - CAMERA SMOOTH UPDATE (FIX SALTELLO)
# ============================================================================

func _physics_process(_delta):
	"""Aggiorna camera smoothly ogni frame per evitare saltelli"""
	if camera != null:
		# Calcola posizione target (sempre a coordinate intere per evitare arrotondamenti)
		var target_world_pos = Vector2(
			round(target_camera_position.x),
			round(target_camera_position.y)
		)
		
		# Aggiorna camera con posizione intera (elimina decimali)
		camera.position = target_world_pos

# ============================================================================
# CARICAMENTO E CONVERSIONE MAPPA
# ============================================================================

func _load_map():
	"""Carica mappa ASCII e converte in TileMap + nodi speciali"""
	# Debug rimosso per ridurre log
	
	# Carica dati raw
	var file = FileAccess.open(MAP_FILE_PATH, FileAccess.READ)
	if file == null:
		# Debug rimosso per ridurre log
		pass
		return
	
	map_data.clear()
	while not file.eof_reached():
		var line = file.get_line().strip_edges(false, true)
		if line.length() > 0:
			map_data.append(line)
	file.close()
	
	if map_data.size() > 0:
		map_height = map_data.size()
		map_width = map_data[0].length()
		# Debug rimosso per ridurre log
		
		# Converti mappa in tiles e nodi speciali
		_convert_map_to_world()
	else:
		# Debug rimosso per ridurre log
		pass
		pass
		pass

func _convert_map_to_world():
	"""Converte mappa ASCII in TileMap con tiles per S/E"""
	# Debug rimosso per ridurre log
	
	var start_found = false
	
	for y in range(map_height):
		var row = map_data[y]
		for x in range(min(row.length(), map_width)):
			var map_char = row[x]
			
			# GESTIONE START/END COME TILES (non più nodi BBCode)
			if map_char == "S":
				if not start_found:
					player_pos = Vector2i(x, y)
					start_found = true
					# Debug rimosso per ridurre log
			
			# TUTTI I CARATTERI (inclusi S/E) DIVENTANO TILES
			var source_id = char_to_tile_id.get(map_char, 0)  # Default: pianura
			ascii_tilemap.set_cell(0, Vector2i(x, y), source_id, Vector2i(0, 0))
	
	# Debug rimosso per ridurre log
	# Debug rimosso per ridurre log
	
	if not start_found:
		# Debug rimosso per ridurre log
		pass
		player_pos = Vector2i(0, 0)

# ============================================================================
# SISTEMA PLAYER E MOVIMENTO
# ============================================================================

func _update_player_position():
	"""Aggiorna posizione player sprite"""
	if player_character == null:
		# Debug rimosso per ridurre log
		pass
		return
	
	# Posiziona player in coordinate mondo (centrato nella tile)
	var world_pos = Vector2(player_pos.x * TILE_SIZE + TILE_SIZE/2.0, player_pos.y * TILE_SIZE + TILE_SIZE/2.0)
	player_character.position = world_pos
	
	# Ridimensiona sprite per adattarsi alle tile (16x16 pixel)
	if player_character.texture != null:
		var texture_size = player_character.texture.get_size()
		var scale_factor = Vector2(float(TILE_SIZE) / texture_size.x, float(TILE_SIZE) / texture_size.y)
		player_character.scale = scale_factor
		# Debug rimosso per ridurre log
	
	# Debug rimosso per ridurre log
	
	# Aggiorna target camera (non più chiamata diretta)
	_update_camera_target()

func _update_camera_target():
	"""Aggiorna target position per camera (processata in _physics_process)"""
	if camera != null:
		# Calcola nuova posizione target per la camera
		target_camera_position = Vector2(player_pos.x * TILE_SIZE, player_pos.y * TILE_SIZE)

# ============================================================================
# LOGICA MOVIMENTO AVANZATA (InputManager Integration)
# ============================================================================

## Connette i segnali InputManager per gestione movimento centralizzata
func _connect_input_manager():
	"""Configura connessioni ai segnali InputManager per movimento player"""
	if not InputManager:
		# Debug rimosso per ridurre log
		pass
		return
	
	# Connetti segnale movimento mappa
	if not InputManager.map_move.is_connected(_on_map_move):
		InputManager.map_move.connect(_on_map_move)
		# Debug rimosso per ridurre log
	
	# Debug rimosso per ridurre log

## Connette il segnale player_moved al GameUI per aggiornamenti info real-time
func _connect_to_gameui():
	"""Connette il segnale al GameUI per aggiornamenti pannello informazioni"""
	# Cerca GameUI nella scena
	var gameui = get_tree().get_first_node_in_group("gameui")
	if gameui == null:
		# Cerca tramite percorso relativo se non trovato nel gruppo
		gameui = get_node("../../../GameUI") if get_node_or_null("../../../GameUI") else null
	
	if gameui and gameui.has_method("_on_player_moved"):
		if not player_moved.is_connected(gameui._on_player_moved):
			player_moved.connect(gameui._on_player_moved)
			# Debug rimosso per ridurre log
	else:
		# Debug rimosso per ridurre log
		pass

## Callback per movimento player tramite InputManager
## @param direction: Vector2i direzione movimento (-1,0,1 per x/y)
func _on_map_move(direction: Vector2i):
	"""Gestisce movimento player con penalità fiume, log movimento e aggiornamenti UI"""
	
	# SISTEMA PENALITÀ MOVIMENTO
	if movement_penalty > 0:
		movement_penalty -= 1
		# Debug rimosso per ridurre log
		if PlayerManager:
			PlayerManager.narrative_log_generated.emit("Penalità movimento: resta %d turni" % movement_penalty)
			narrative_message_sent.emit()
		return  # Salta turno
	
	# Calcola nuova posizione basata su direzione InputManager
	var new_position = player_pos + direction
	
	# Valida movimento
	if _is_valid_move(new_position):
		# CONTROLLO SPECIALE: ATTRAVERSAMENTO FIUME
		var destination_char = _get_char_at_position(new_position)
		if destination_char == "~":
			movement_penalty = 1  # Prossimo turno sarà saltato
			_handle_river_crossing()
			narrative_message_sent.emit()
			# Debug rimosso per ridurre log
		
		# Applica movimento
		player_pos = new_position
		_update_player_position()
		
		# LOG MOVIMENTO CON DIREZIONE E TERRENO (solo per stato UI, NESSUN LOG [MONDO])
		var terrain_name = char_to_terrain_name.get(destination_char, "Terreno Sconosciuto")
		# (disattivato) _add_movement_log("Ti sposti verso %s, raggiungendo: %s" % [direction_name, terrain_name])
		
		# EMETTI SEGNALE PER AGGIORNAMENTO PANNELLO INFO
		player_moved.emit(new_position, terrain_name)
		
		# AVANZAMENTO TEMPO: Ogni movimento = 30 minuti
		if TimeManager:
			TimeManager.advance_time_by_moves(1)
			# (Regola aggiornata) Nessuna penalità HP generica per movimento notturno
			# La difficoltà notturna è gestita nello skill check del fiume

		# Log movimento (solo per posizioni significative)
		if new_position.x % 5 == 0 or new_position.y % 5 == 0:
			# Debug rimosso per ridurre log
			pass
	else:
		# Logica per movimento bloccato
		var destination_char = _get_char_at_position(new_position)
		if destination_char == "M":
			# Messaggio ironico per le montagne
			var random_message = mountain_fail_messages[randi() % mountain_fail_messages.size()]
			if PlayerManager:
				PlayerManager.narrative_log_generated.emit(random_message)
			narrative_message_sent.emit()
		else:
			# Messaggio generico per altri ostacoli
			var direction_name = direction_to_name.get(direction, "Direzione Sconosciuta")
			if PlayerManager:
				PlayerManager.narrative_log_generated.emit("Movimento bloccato verso %s: ostacolo invalicabile" % direction_name)

		# Debug rimosso per ridurre log

## Aggiunge log di movimento al GameUI
func _add_movement_log(message: String):
	"""Invia messaggio di movimento al log del GameUI"""
	# Cerca GameUI nella scena per log movimento
	var gameui = get_tree().get_first_node_in_group("gameui")
	if gameui == null:
		# Cerca tramite percorso relativo se non trovato nel gruppo
		gameui = get_node("../../../GameUI") if get_node_or_null("../../../GameUI") else null
	
	if gameui and gameui.has_method("add_world_log"):
		gameui.add_world_log(message)
	else:
		# Debug rimosso per ridurre log
		pass

func _is_valid_move(pos: Vector2i) -> bool:
	"""Valida movimento con controlli confini e collisioni"""
	
	# Controllo confini mappa
	if pos.x < 0 or pos.x >= map_width or pos.y < 0 or pos.y >= map_height:
		return false
	
	# Ottieni dati tile per collision detection
	var tile_data = ascii_tilemap.get_cell_tile_data(0, pos)
	
	if tile_data == null:
		# Nessun tile = movimento valido (es. punti S/E)
		return true
	
	# Controlla collision shapes (montagne)
	for i in range(tile_data.get_collision_polygons_count(0)):
		var collision_polygon = tile_data.get_collision_polygon_points(0, i)
		if collision_polygon.size() > 0:
			# Tile ha collision = movimento bloccato
			return false
	
	# Nessuna collisione = movimento valido
	return true

# ============================================================================
# UTILITY E API PUBBLICHE
# ============================================================================

func _get_char_at_position(pos: Vector2i) -> String:
	"""Ottieni carattere ASCII alla posizione specificata"""
	if pos.y >= 0 and pos.y < map_data.size():
		var row = map_data[pos.y]
		if pos.x >= 0 and pos.x < row.length():
			return row[pos.x]
	return "?"

func get_player_position() -> Vector2i:
	"""API pubblica: posizione player corrente"""
	return player_pos

func get_movement_penalty() -> int:
	"""API pubblica: turni penalità rimanenti"""
	return movement_penalty

func is_river_crossing() -> bool:
	"""API pubblica: controlla se player è su fiume"""
	return _get_char_at_position(player_pos) == "~"

func get_current_terrain_name() -> String:
	"""API pubblica: nome terreno corrente"""
	var terrain_char = _get_char_at_position(player_pos)
	return char_to_terrain_name.get(terrain_char, "Terreno Sconosciuto")

# ============================================================================
# DEBUG E INFORMAZIONI
# ============================================================================

func debug_world_state():
	"""Debug completo stato World v2.1 - Debug rimosso per ridurre log"""
	# Debug rimosso per ridurre log
	pass
