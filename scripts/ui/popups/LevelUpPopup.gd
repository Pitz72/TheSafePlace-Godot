extends CanvasLayer

## LevelUpPopup Script - The Safe Place v0.3.0
## 
## Gestisce la logica del popup per il miglioramento delle statistiche del personaggio.
## Mostra le statistiche correnti e permette di spendere punti disponibili.
##
## PRINCIPIO 8: Design keyboard-only con navigazione frecce tra i bottoni [+].
## Versione: M3.T1 - Sistema Progressione AD&D

# ========================================
# SEGNALI PUBBLICI
# ========================================

## Emesso quando il popup si chiude (per ripristino stato input)
signal popup_closed

# ========================================
# REFERENZE AI NODI (@onready)
# ========================================

@onready var title_label: Label = $Panel/MarginContainer/Layout/TitleLabel
@onready var available_points_label: Label = $Panel/MarginContainer/Layout/AvailablePointsLabel

# Referenze alle statistiche (label + bottoni)
@onready var forza_label: Label = $Panel/MarginContainer/Layout/StatsContainer/StatForza/ForzaLabel
@onready var forza_button: RichTextLabel = $Panel/MarginContainer/Layout/StatsContainer/StatForza/ForzaButton

@onready var agilita_label: Label = $Panel/MarginContainer/Layout/StatsContainer/StatAgilita/AgilitaLabel
@onready var agilita_button: RichTextLabel = $Panel/MarginContainer/Layout/StatsContainer/StatAgilita/AgilitaButton

@onready var intelligenza_label: Label = $Panel/MarginContainer/Layout/StatsContainer/StatIntelligenza/IntelligenzaLabel
@onready var intelligenza_button: RichTextLabel = $Panel/MarginContainer/Layout/StatsContainer/StatIntelligenza/IntelligenzaButton

@onready var carisma_label: Label = $Panel/MarginContainer/Layout/StatsContainer/StatCarisma/CarismaLabel
@onready var carisma_button: RichTextLabel = $Panel/MarginContainer/Layout/StatsContainer/StatCarisma/CarismaButton

@onready var fortuna_label: Label = $Panel/MarginContainer/Layout/StatsContainer/StatFortuna/FortunaLabel
@onready var fortuna_button: RichTextLabel = $Panel/MarginContainer/Layout/StatsContainer/StatFortuna/FortunaButton

@onready var close_button: RichTextLabel = $Panel/MarginContainer/Layout/CloseContainer/CloseButton

# Referenze alle informazioni di progressione (M3.T1 Enhancement)
@onready var level_info_label: Label = $Panel/MarginContainer/Layout/ProgressionInfo/LevelInfo
@onready var exp_info_label: Label = $Panel/MarginContainer/Layout/ProgressionInfo/ExpInfo
@onready var exp_remaining_label: Label = $Panel/MarginContainer/Layout/ProgressionInfo/ExpRemainingInfo
@onready var total_exp_label: Label = $Panel/MarginContainer/Layout/ProgressionInfo/TotalExpInfo

# ========================================
# VARIABILI PRIVATE
# ========================================

## Indice azione attualmente selezionata (per navigazione keyboard-only)
var selected_stat_index: int = 0

## Array delle azioni disponibili per navigazione (ordine: forza, agilita, intelligenza, carisma, fortuna, chiudi)
var _stat_buttons: Array[RichTextLabel] = []
var _stat_names: Array[String] = ["forza", "agilita", "intelligenza", "carisma", "fortuna"]

## Flag per impedire input mentre popup non è attivo
var _is_active: bool = false

# ========================================
# INIZIALIZZAZIONE
# ========================================

func _ready() -> void:
	print("🏆 LevelUpPopup: Inizializzazione popup livellamento")
	
	# Nascondi popup all'inizio
	self.hide()
	
	# Configura array bottoni per navigazione
	_stat_buttons = [forza_button, agilita_button, intelligenza_button, carisma_button, fortuna_button, close_button]
	
	print("✅ LevelUpPopup: Pronto (%d bottoni configurati)" % _stat_buttons.size())

# ========================================
# FUNZIONE PUBBLICA PRINCIPALE
# ========================================

## Mostra il popup di livellamento (sempre, anche senza punti disponibili)
func show_level_up_popup() -> void:
	if not PlayerManager:
		print("❌ LevelUpPopup: PlayerManager non disponibile")
		return
	
	print("🏆 LevelUpPopup: Apertura popup livellamento")
	
	# Aggiorna dati popup
	_update_popup_data()
	
	# Reset selezione e attiva navigazione
	selected_stat_index = 0
	_update_visual_selection()
	
	# Cambia stato input e mostra popup
	InputManager.set_state(InputManager.InputState.POPUP)
	_is_active = true
	self.show()
	
	print("✅ LevelUpPopup: Popup attivo - Punti disponibili: %d" % PlayerManager.available_stat_points)

## Chiude il popup e ripristina stato input
func close_popup() -> void:
	print("🏆 LevelUpPopup: Chiusura popup")
	
	_is_active = false
	self.hide()
	
	# Ripristina stato input precedente (MAP o INVENTORY)
	InputManager.set_state(InputManager.InputState.MAP)
	
	# Emetti segnale di chiusura
	popup_closed.emit()
	
	print("✅ LevelUpPopup: Popup chiuso, input ripristinato")

# ========================================
# GESTIONE INPUT KEYBOARD-ONLY
# ========================================

func _input(event: InputEvent) -> void:
	# Processa input solo se popup è attivo
	if not _is_active or not event.is_pressed():
		return
	
	# ESC: Chiudi popup
	if event.is_action_pressed("ui_cancel") or Input.is_key_pressed(KEY_ESCAPE):
		close_popup()
		return
	
	# Navigazione frecce SU/GIÙ
	if event.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		_navigate_selection(-1)
		return
	elif event.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		_navigate_selection(1)
		return
	
	# ENTER/SPACE: Attiva azione selezionata
	if event.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER):
		_activate_selected_action()
		return

## Naviga tra le opzioni disponibili
func _navigate_selection(direction: int) -> void:
	selected_stat_index += direction
	
	# Wrap around
	if selected_stat_index < 0:
		selected_stat_index = _stat_buttons.size() - 1
	elif selected_stat_index >= _stat_buttons.size():
		selected_stat_index = 0
	
	print("🎯 LevelUpPopup: Navigazione → index %d" % selected_stat_index)
	_update_visual_selection()

## Attiva l'azione attualmente selezionata
func _activate_selected_action() -> void:
	if not PlayerManager:
		return
	
	print("🎯 LevelUpPopup: Attivazione azione index %d" % selected_stat_index)
	
	# Se è selezionato "Chiudi" (ultimo bottone)
	if selected_stat_index >= _stat_names.size():
		close_popup()
		return
	
	# Altrimenti, migliora la statistica selezionata
	var stat_name = _stat_names[selected_stat_index]
	
	# Verifica se ci sono ancora punti disponibili
	if not PlayerManager.has_available_stat_points():
		print("⚠️ LevelUpPopup: Nessun punto disponibile per migliorare %s" % stat_name)
		return
	
	# Migliora statistica tramite PlayerManager
	if PlayerManager.improve_stat(stat_name):
		print("✅ LevelUpPopup: %s migliorata con successo" % stat_name.capitalize())
		
		# Aggiorna visualizzazione
		_update_popup_data()
		_update_visual_selection()
		
		# Se non ci sono più punti, chiudi automaticamente
		if not PlayerManager.has_available_stat_points():
			print("🏆 LevelUpPopup: Tutti i punti spesi - Chiusura automatica")
			call_deferred("close_popup")  # Chiusura differita per evitare problemi input
	else:
		print("❌ LevelUpPopup: Errore nel miglioramento di %s" % stat_name)

# ========================================
# FUNZIONI HELPER PRIVATE
# ========================================

## Aggiorna tutti i dati mostrati nel popup
func _update_popup_data() -> void:
	if not PlayerManager:
		return
	
	# Aggiorna punti disponibili
	var available_points = PlayerManager.available_stat_points
	available_points_label.text = "Punti Disponibili: %d" % available_points
	
	# Aggiorna valori statistiche
	forza_label.text = "Forza: %d" % PlayerManager.get_stat("forza")
	agilita_label.text = "Agilità: %d" % PlayerManager.get_stat("agilita")
	intelligenza_label.text = "Intelligenza: %d" % PlayerManager.get_stat("intelligenza")
	carisma_label.text = "Carisma: %d" % PlayerManager.get_stat("carisma")
	fortuna_label.text = "Fortuna: %d" % PlayerManager.get_stat("fortuna")
	# Vigore non è modificabile nel level up (solo HP base influisce)
	
	# Aggiorna informazioni progressione (M3.T1 Enhancement)
	_update_progression_info()
	
	print("📊 LevelUpPopup: Dati aggiornati - Punti: %d" % available_points)

## Aggiorna le informazioni di progressione (livello, EXP, ecc.)
func _update_progression_info() -> void:
	if not PlayerManager:
		return
	
	# Calcola livello attuale basato sull'esperienza
	var current_level = _calculate_current_level(PlayerManager.experience)
	var current_exp = PlayerManager.experience
	var exp_for_next = PlayerManager.experience_for_next_point
	var exp_remaining = max(0, exp_for_next - current_exp)
	
	# Aggiorna label informazioni progressione
	level_info_label.text = "Livello Attuale: %d" % current_level
	exp_info_label.text = "Esperienza: %d / %d" % [current_exp, exp_for_next]
	exp_remaining_label.text = "EXP Mancante: %d" % exp_remaining
	total_exp_label.text = "EXP Totale: %d" % current_exp
	
	print("📈 LevelUpPopup: Progressione - Livello: %d | EXP: %d/%d" % [current_level, current_exp, exp_for_next])

## Calcola il livello attuale basato sull'esperienza totale
func _calculate_current_level(total_experience: int) -> int:
	# Sistema AD&D: inizia da livello 1, ogni 100/150/225... EXP sale di livello
	# Per semplicità, calcoliamo livello approssimativo
	if total_experience < 100:
		return 1
	elif total_experience < 250:  # 100 + 150
		return 2
	elif total_experience < 475:  # 100 + 150 + 225
		return 3
	elif total_experience < 812:  # ... + 337
		return 4
	elif total_experience < 1318:  # ... + 506
		return 5
	else:
		# Per livelli alti, approssimazione
		return 5 + int((total_experience - 1318) / 600)  # Incremento di ~600 EXP per livello

## Aggiorna l'evidenziazione visuale della selezione corrente
func _update_visual_selection() -> void:
	# Reset tutti i bottoni a stato normale
	for i in range(_stat_buttons.size()):
		var button = _stat_buttons[i]
		if button:
			if i < _stat_names.size():
				# Bottone statistica: mostra [+] normale o disabilitato
				if PlayerManager and PlayerManager.has_available_stat_points():
					button.text = "[color=#00FF40][+][/color]"
				else:
					button.text = "[color=#666666][+][/color]"  # Disabilitato
			else:
				# Bottone chiudi
				button.text = "[color=#00FF40]Chiudi[/color]"
	
	# Evidenzia il bottone selezionato
	var selected_button = _stat_buttons[selected_stat_index]
	if selected_button:
		if selected_stat_index < _stat_names.size():
			# Bottone statistica selezionato: sfondo verde + testo nero
			if PlayerManager and PlayerManager.has_available_stat_points():
				selected_button.text = "[bgcolor=#00FF40][color=#000000][+][/color][/bgcolor]"
			else:
				selected_button.text = "[bgcolor=#666666][color=#000000][+][/color][/bgcolor]"  # Disabilitato
		else:
			# Bottone chiudi selezionato
			selected_button.text = "[bgcolor=#00FF40][color=#000000]Chiudi[/color][/bgcolor]"
	
	print("🎨 LevelUpPopup: Selezione aggiornata - Index: %d" % selected_stat_index)