extends PanelContainer

# Pannello Informazioni (Right Panel)
@onready var posizione_label: Label = $InfoVBox/PosizioneLabel
@onready var luogo_label: Label = $InfoVBox/LuogoLabel
@onready var ora_label: RichTextLabel = $InfoVBox/OraLabel

func _ready():
	if TimeManager:
		TimeManager.time_advanced.connect(update_panel)
	# Non è necessario connettere a un segnale del player per la posizione,
	# perché il World chiama direttamente update_info_panel in GameUI.
	# Manteniamo questo comportamento per ora.
	update_panel()

func update_panel(_new_hour: int = -1, _new_minute: int = -1):
	"""Aggiorna pannello informazioni (posizione, luogo, ora) - M3.T2 Sistema Temporale"""
	# NOTA: Posizione e luogo ora gestiti da _on_player_moved() in real-time
	# Questo aggiorna solo l'ora usando TimeManager
	
	# Aggiorna ora con TimeManager (M3.T2) - Formato con giorni + colore notte
	if ora_label and TimeManager:
		var time_str = TimeManager.get_formatted_time()
		var day_str = TimeManager.get_formatted_day()
		if TimeManager.is_night():
			# Notte: testo blu più chiaro
			ora_label.text = "[color=#6699ff]Ora: %s %s[/color]" % [time_str, day_str]
		else:
			# Giorno: testo normale
			ora_label.text = "Ora: %s %s" % [time_str, day_str]
	elif ora_label:
		ora_label.text = "Ora: 08:00 Giorno 1"  # Fallback se TimeManager non disponibile

func update_position(new_position: Vector2i, terrain_type: String):
	"""Aggiorna solo la posizione e il luogo, chiamato da GameUI"""
	if posizione_label:
		posizione_label.text = "Posizione: [%d, %d]" % [new_position.x, new_position.y]
	if luogo_label:
		luogo_label.text = "Luogo: %s" % terrain_type