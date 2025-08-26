extends PanelContainer

# Pannello Comandi (Right Panel)
@onready var command1_label: Label = $CommandsVBox/Command1
@onready var command2_label: Label = $CommandsVBox/Command2
@onready var command3_label: Label = $CommandsVBox/Command3

# Riferimento al pannello inventario per sapere se è attivo
var inventory_panel # Assicurati di impostarlo da GameUI

# Stato rifugio
var is_in_shelter: bool = false

func _ready():
	# Connetti al segnale rifugio da MainGame
	var main_game = get_node("/root/MainGame")
	if main_game and main_game.has_signal("shelter_status_changed"):
		main_game.shelter_status_changed.connect(_on_shelter_status_changed)
		print("✅ CommandsPanel connesso a shelter_status_changed")

func _on_shelter_status_changed(in_shelter: bool):
	"""Callback per cambio stato rifugio"""
	is_in_shelter = in_shelter
	print("🏠 CommandsPanel: Stato rifugio cambiato - %s" % ["ENTRATO" if in_shelter else "USCITO"])
	
	# Aggiorna immediatamente i comandi se non siamo in modalità inventario
	if inventory_panel == null or not inventory_panel.is_active:
		update_panel(false)

func update_panel(is_inventory_active: bool):
	"""Aggiorna pannello comandi con istruzioni dinamiche"""
	if not command1_label or not command2_label or not command3_label:
		return
	
	# MODALITÀ INVENTARIO (priorità massima)
	if is_inventory_active:
		command1_label.text = "[WS/↑↓] Naviga\n[ENTER] Ispeziona\n[1-9] Usa oggetto"
		command2_label.text = "[I] Chiudi inventario\n[ESC] Menu"
		command3_label.text = ""
		return
	
	# MODALITÀ RIFUGIO (quando in rifugio di giorno)
	if is_in_shelter and not _is_night():
		command1_label.text = "[1] Riposa\n(Recupera 10 HP, +2 ore)"
		command2_label.text = "[2] Cerca Risorse\n(+30 min, skill check)"
		command3_label.text = "[3] Banco da Lavoro\n(Non disponibile)\n[4] Lascia il Rifugio"
		return
	
	# MODALITÀ MAPPA NORMALE
	command1_label.text = "[WASD] Movimento\n[I]nventario\n[R]iposa"
	command2_label.text = "[L]ivella Personaggio\n[S]alva\n[C]arica"
	command3_label.text = "[ESC] Menu"

# Utility per controllare se è notte
func _is_night() -> bool:
	return TimeManager and TimeManager.is_night()