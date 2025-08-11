extends PanelContainer

# Pannello Comandi (Right Panel)
@onready var command1_label: Label = $CommandsVBox/Command1
@onready var command2_label: Label = $CommandsVBox/Command2
@onready var command3_label: Label = $CommandsVBox/Command3

# Riferimento al pannello inventario per sapere se è attivo
var inventory_panel # Assicurati di impostarlo da GameUI

func _ready():
	# L'aggiornamento dei comandi dipende dallo stato dell'inventario,
	# quindi viene chiamato da GameUI quando necessario.
	pass

func update_panel(is_inventory_active: bool):
	"""Aggiorna pannello comandi con istruzioni dinamiche"""
	if not command1_label or not command2_label or not command3_label:
		return
	
	# Comandi dinamici basati su modalità inventario
	if is_inventory_active:
		# Modalità inventario: comandi specifici navigazione (in colonna)
		command1_label.text = "[WS/↑↓] Naviga\n[ENTER] Ispeziona\n[1-9] Usa oggetto"
		command2_label.text = "[I] Chiudi inventario\n[ESC] Menu"
		command3_label.text = ""
	else:
		# Modalità mappa: comandi completi sistema GDR (in colonna)
		command1_label.text = "[WASD] Movimento\n[I]nventario\n[R]iposa"
		command2_label.text = "[L]ivella Personaggio\n[S]alva\n[C]arica"
		command3_label.text = "[ESC] Menu"