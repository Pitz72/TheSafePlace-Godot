extends Node

## SkillCheckManager Singleton - The Safe Place v0.4.0
##
## Motore di gioco centralizzato per la gestione di tutti i test di abilità (skill check).
## Creato per disaccoppiare la logica dei "tiri di dado" dal PlayerManager.
## Task ID: M3.T4.2

# ========================================
# INIZIALIZZAZIONE
# ========================================

## Inizializza il generatore di numeri casuali
func _ready() -> void:
	randomize()
	print("🎲 SkillCheckManager pronto.")

# ========================================
# API PUBBLICA
# ========================================

## Esegue un test di abilità (skill check) basato su una statistica del giocatore.
## Restituisce un dizionario dettagliato con il risultato completo del tiro.
##
## @param stat_name: String - Il nome della statistica da usare (es. "forza", "agilita").
## @param difficulty: int - La soglia di difficoltà (DC) che il tiro deve superare.
## @return: Dictionary - Un resoconto completo del test.
func perform_check(stat_name: String, difficulty: int) -> Dictionary:
	# 1. Ottieni il valore della statistica dal PlayerManager
	var stat_value: int = PlayerManager.get_stat(stat_name)

	# 2. Calcola il modificatore (stile D&D)
	var modifier: int = int(floor((stat_value - 10) / 2.0))

	# 3. Lancia il dado (d20)
	var roll: int = randi_range(1, 20)

	# 4. Calcola il totale
	var total: int = roll + modifier

	# 5. Determina il successo
	var success: bool = total >= difficulty

	# 6. Prepara il dizionario di risultato
	var result: Dictionary = {
		"stat_used": stat_name,
		"stat_value": stat_value,
		"modifier": modifier,
		"roll": roll,
		"total": total,
		"difficulty": difficulty,
		"success": success
	}

	return result
