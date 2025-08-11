extends PanelContainer

# Pannello Statistiche (Right Panel)
@onready var strength_label: Label = $StatsVBox/StrengthLabel
@onready var agility_label: Label = $StatsVBox/AgilityLabel
@onready var intelligence_label: Label = $StatsVBox/IntelligenceLabel
@onready var charisma_label: Label = $StatsVBox/CharismaLabel
@onready var luck_label: Label = $StatsVBox/LuckLabel
@onready var vigore_label: Label = $StatsVBox/VigoreLabel

func _ready():
	if PlayerManager:
		PlayerManager.stats_changed.connect(update_panel)
	update_panel()

func update_panel():
	"""Aggiorna pannello statistiche RPG - M3.T1 con sistema progressione"""
	if not PlayerManager:
		return
	
	# Aggiorna tutte le 6 statistiche RPG con protezione null
	if strength_label:
		strength_label.text = "Forza: %d" % PlayerManager.get_stat("forza")
	if agility_label:
		agility_label.text = "Agilità: %d" % PlayerManager.get_stat("agilita")
	if intelligence_label:
		intelligence_label.text = "Intelligenza: %d" % PlayerManager.get_stat("intelligenza")
	if charisma_label:
		charisma_label.text = "Carisma: %d" % PlayerManager.get_stat("carisma")
	if luck_label:
		luck_label.text = "Fortuna: %d" % PlayerManager.get_stat("fortuna")
	if vigore_label:
		vigore_label.text = "Vigore: %d" % PlayerManager.get_stat("vigore")