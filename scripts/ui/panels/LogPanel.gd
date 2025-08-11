extends PanelContainer

# Pannello Diario (Center Panel)
@onready var log_display: RichTextLabel = $LogVBox/LogDisplay

func _ready():
	if PlayerManager:
		PlayerManager.narrative_log_generated.connect(add_log_message)

func add_log_message(message: String):
	"""Aggiunge un messaggio timestampato al diario - STILE ASCII"""
	if not log_display:
		print("LogPanel: [ERROR] log_display è null - messaggio perso: " + message)
		return
	
	var timestamp = get_current_timestamp()
	var formatted_message = "[color=yellow]%s[/color] %s\n" % [timestamp, message]
	
	log_display.append_text(formatted_message)
	
	# Scroll automatico all'ultimo messaggio
	log_display.scroll_to_line(log_display.get_line_count() - 1)

func get_current_timestamp() -> String:
	"""Genera timestamp per messaggi diario - M3.T2 Sistema Temporale"""
	if TimeManager:
		return "[%s]" % TimeManager.get_formatted_time()
	else:
		return "[08:00]"  # Fallback se TimeManager non disponibile

func clear_log():
	"""Pulisce completamente il diario"""
	log_display.clear()
	print("LogPanel: 🔄 Diario pulito")

func add_world_log(message: String):
	"""Aggiunge un messaggio di movimento dal World al diario"""
	if not log_display:
		print("LogPanel: [ERROR] log_display è null - messaggio World perso: " + message)
		return
	
	var timestamp = get_current_timestamp()
	var formatted_message = "[color=cyan]%s[/color] [color=lightgreen][MONDO][/color] %s\n" % [timestamp, message]
	
	log_display.append_text(formatted_message)
	
	# Scroll automatico all'ultimo messaggio
	log_display.scroll_to_line(log_display.get_line_count() - 1)