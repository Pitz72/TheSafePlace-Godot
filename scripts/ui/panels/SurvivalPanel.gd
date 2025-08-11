extends PanelContainer

# Pannello Sopravvivenza (Left Panel)
@onready var hp_label: Label = $SurvivalVBox/HPLabel
@onready var food_label: Label = $SurvivalVBox/FoodLabel
@onready var water_label: Label = $SurvivalVBox/WaterLabel
@onready var status_label: RichTextLabel = $SurvivalVBox/StatusLabel

func _ready():
	if PlayerManager:
		PlayerManager.resources_changed.connect(update_panel)
		PlayerManager.stats_changed.connect(update_panel)
	# Chiama un primo aggiornamento per assicurarsi che i dati siano visibili all'avvio
	update_panel()

func update_panel():
	"""Aggiorna pannello sopravvivenza (HP, Food, Water, Status)"""
	if not PlayerManager:
		print("SurvivalPanel: ❌ PlayerManager non disponibile")
		return
	
	# Verifica che le label esistano prima di aggiornare
	if hp_label:
		hp_label.text = "HP: %d/%d" % [PlayerManager.hp, PlayerManager.max_hp]
		if PlayerManager.hp <= 20:
			hp_label.text += " [CRITICO!]"
	
	if food_label:
		food_label.text = "Sazietà: %d/%d" % [PlayerManager.food, PlayerManager.max_food]
		if PlayerManager.food <= 10:
			food_label.text += " [FAME!]"
	
	if water_label:
		water_label.text = "Idratazione: %d/%d" % [PlayerManager.water, PlayerManager.max_water]
		if PlayerManager.water <= 10:
			water_label.text += " [SETE!]"
	
	# Aggiorna status del personaggio (M3.T3)
	if status_label:
		var status_text = "Status: "
		if PlayerManager.active_statuses.is_empty():
			status_text += "Normale"
		else:
			var status_parts = []
			for status in PlayerManager.active_statuses:
				match status:
					PlayerManager.Status.WOUNDED:
						status_parts.append("[color=red]Ferito[/color]")
					PlayerManager.Status.SICK:
						status_parts.append("[color=orange]Malato[/color]")
					PlayerManager.Status.POISONED:
						status_parts.append("[color=purple]Avvelenato[/color]")
					PlayerManager.Status.NORMAL:
						status_parts.append("Normale")
			status_text += ", ".join(status_parts)
		status_label.text = status_text