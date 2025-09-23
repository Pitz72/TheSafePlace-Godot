extends Node

## TimeManager Singleton - The Safe Place v0.2.2+
## 
## Gestisce il passaggio del tempo nel gioco, il ciclo giorno/notte e le conseguenze sulla sopravvivenza.
## Ogni movimento sulla mappa fa avanzare il tempo di 30 minuti.
##
## MILESTONE 3 TASK 2: Il Passaggio del Tempo (The Ticking Clock)
## Architettura: Signal-based per integrazione con PlayerManager e GameUI

# ========================================
# SEGNALI PUBBLICI
# ========================================

## Emesso quando il tempo avanza
## @param new_hour: int ora corrente (0-23)
## @param new_minute: int minuto corrente (0 o 30)
signal time_advanced(new_hour: int, new_minute: int)

## Emesso quando cambia il giorno
## @param new_day: int numero del giorno
signal day_changed(new_day: int)

## Emesso all'inizio della notte (19:00)
signal night_started()

## Emesso all'inizio del giorno (06:00)
signal day_started()

## Emesso per penalità sopravvivenza (ogni sera alle 19:00)
signal survival_penalty_tick()

# ========================================
# VARIABILI DI STATO
# ========================================

## Numero totale di movimenti effettuati dal giocatore
var total_moves: int = 0

## Ora corrente del gioco (0-23)
var current_hour: int = 8  # Inizio alle 08:00

## Minuto corrente del gioco (0 o 30)
var current_minute: int = 0

## Giorno corrente del gioco (inizia da 1)
var current_day: int = 1

## Flag per tracciare se è notte (19:00-05:59)
var is_night_time: bool = false

# ========================================
# INIZIALIZZAZIONE
# ========================================

func _ready() -> void:
	# Debug rimosso per ridurre log
	# Debug rimosso per ridurre log
	# Debug rimosso per ridurre log
	# Debug rimosso per ridurre log
	# Debug rimosso per ridurre log
	
	# Controlla se il tempo iniziale è notte
	_check_day_night_cycle(current_hour, current_hour)
	
	# Debug rimosso per ridurre log

# ========================================
# API PUBBLICA - AVANZAMENTO TEMPO
# ========================================

## Avanza il tempo di gioco di un numero specificato di movimenti
## Ogni movimento = 30 minuti di tempo di gioco
## @param moves: int numero di movimenti (default: 1)
func advance_time_by_moves(moves: int = 1) -> void:
	if moves <= 0:
		# Debug rimosso per ridurre log
		pass
		return
	
	var previous_hour = current_hour
	
	# Aggiorna contatore movimenti totali
	total_moves += moves
	
	# Calcola avanzamento tempo (30 minuti per movimento)
	var minutes_to_add = moves * 30
	var total_minutes = (current_hour * 60) + current_minute + minutes_to_add
	
	# Calcola nuova ora e minuto
	var new_hour = int(total_minutes / 60.0) % 24
	var new_minute = total_minutes % 60
	
	# Gestisci cambio giorno se necessario
	var days_passed = int(total_minutes / (24.0 * 60))
	if days_passed > 0:
		current_day += days_passed
		# Debug rimosso per ridurre log
		day_changed.emit(current_day)
	
	# Aggiorna tempo corrente
	current_hour = new_hour
	current_minute = new_minute
	
	# Debug rimosso per ridurre log
	
	# Emetti segnale avanzamento tempo
	time_advanced.emit(current_hour, current_minute)
	
	# Controlla transizioni giorno/notte
	_check_day_night_cycle(previous_hour, current_hour)
	
	# Controlla penalità sopravvivenza (alle 19:00)
	_check_survival_penalty(previous_hour, current_hour)

## Avanza il tempo fino a una specifica ora del giorno
## Usato per la funzionalità notturna del rifugio (avanza fino alle 6:00)
## @param target_hour: int ora target (0-23)
func advance_time_until_hour(target_hour: int) -> void:
	if target_hour < 0 or target_hour > 23:
		print("⚠️ TimeManager: Ora target non valida: ", target_hour)
		return
	
	var moves_needed = 0
	var temp_hour = current_hour
	var temp_minute = current_minute
	
	# Calcola quanti movimenti servono per raggiungere l'ora target
	while temp_hour != target_hour:
		# Ogni movimento avanza di 30 minuti
		var total_minutes = (temp_hour * 60) + temp_minute + 30
		temp_hour = int(total_minutes / 60.0) % 24
		temp_minute = total_minutes % 60
		moves_needed += 1
		
		# Sicurezza: evita loop infiniti
		if moves_needed > 48:  # Massimo 24 ore = 48 movimenti
			print("⚠️ TimeManager: Troppi movimenti per raggiungere l'ora ", target_hour)
			break
	
	print("🕐 TimeManager: Avanzando di ", moves_needed, " movimenti fino alle ", target_hour, ":00")
	advance_time_by_moves(moves_needed)

# ========================================
# API PUBBLICA - QUERY STATO
# ========================================

## Restituisce se è attualmente notte
## @return: bool true se è notte (19:00-05:59)
func is_night() -> bool:
	return current_hour >= 19 or current_hour <= 5

## Restituisce il tempo formattato come stringa
## @return: String tempo nel formato "HH:MM"
func get_formatted_time() -> String:
	return "%02d:%02d" % [current_hour, current_minute]

## Restituisce il giorno formattato
## @return: String giorno nel formato "Giorno X"
func get_formatted_day() -> String:
	return "Giorno %d" % current_day

## Restituisce i dati completi del tempo per salvataggio
## @return: Dictionary dati tempo per persistenza
func get_time_data() -> Dictionary:
	return {
		"total_moves": total_moves,
		"current_hour": current_hour,
		"current_minute": current_minute,
		"current_day": current_day,
		"is_night_time": is_night()
	}

## Carica i dati del tempo da salvataggio
## @param data: Dictionary dati tempo da ripristinare
func load_time_data(data: Dictionary) -> void:
	if data.has("total_moves"):
		total_moves = data.get("total_moves", 0)
	if data.has("current_hour"):
		current_hour = data.get("current_hour", 8)
	if data.has("current_minute"):
		current_minute = data.get("current_minute", 0)
	if data.has("current_day"):
		current_day = data.get("current_day", 1)
	
	# Aggiorna stato notte
	is_night_time = is_night()
	
	# Debug rimosso per ridurre log

# ========================================
# FUNZIONI HELPER PRIVATE
# ========================================

## Controlla le transizioni del ciclo giorno/notte
## @param prev_hour: int ora precedente
## @param new_hour: int nuova ora
func _check_day_night_cycle(prev_hour: int, new_hour: int) -> void:
	var was_night = (prev_hour >= 19 or prev_hour <= 5)
	var is_now_night = (new_hour >= 19 or new_hour <= 5)
	
	# Transizione da giorno a notte (18:xx → 19:xx)
	if not was_night and is_now_night and new_hour == 19:
		is_night_time = true
		# Debug rimosso per ridurre log
		night_started.emit()
	
	# Transizione da notte a giorno (05:xx → 06:xx)
	elif was_night and not is_now_night and new_hour == 6:
		is_night_time = false
		# Debug rimosso per ridurre log
		day_started.emit()
	
	# Aggiorna stato attuale
	is_night_time = is_now_night

## Controlla se applicare penalità sopravvivenza
## @param prev_hour: int ora precedente
## @param new_hour: int nuova ora
func _check_survival_penalty(prev_hour: int, new_hour: int) -> void:
	# Penalità sopravvivenza alle 19:00 (inizio notte)
	if prev_hour != 19 and new_hour == 19:
		# Debug rimosso per ridurre log
		pass
		survival_penalty_tick.emit()

# ========================================
# DEBUG E UTILITY
# ========================================

## Stampa lo stato attuale del tempo (per debug)
func debug_print_time_status() -> void:
	# Debug rimosso per ridurre log
	# Debug rimosso per ridurre log
	pass
	# Debug rimosso per ridurre log
	# Debug rimosso per ridurre log
	# Debug rimosso per ridurre log
