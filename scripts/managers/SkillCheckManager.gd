extends Node

## SkillCheckManager Singleton - The Safe Place v0.4.0
##
## Motore di gioco centralizzato per la gestione di tutti i test di abilità (skill check).
## Creato per disaccoppiare la logica dei "tiri di dado" dal PlayerManager.
## Task ID: M3.T4.2
## v0.4.0: Added modifier caching for performance optimization

# ========================================
# PERFORMANCE OPTIMIZATION
# ========================================

## Cache for stat modifiers to avoid recalculation
var _modifier_cache: Dictionary = {}
var _cache_dirty: bool = true

# ========================================
# INIZIALIZZAZIONE
# ========================================

## Inizializza il generatore di numeri casuali
func _ready() -> void:
	randomize()
	# Connect to PlayerManager to clear cache when stats change
	if PlayerManager:
		PlayerManager.stats_changed.connect(_on_stats_changed)
	print("🎲 SkillCheckManager pronto.")

## Clears modifier cache when player stats change
func _on_stats_changed() -> void:
	_modifier_cache.clear()
	_cache_dirty = true

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

	# 2. Calcola il modificatore (con cache per performance)
	var modifier: int = _get_cached_modifier(stat_name, stat_value)

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

## Gets cached modifier or calculates and caches if not present
## @param stat_name: String - Name of the stat
## @param stat_value: int - Current stat value
## @return: int - The calculated modifier
func _get_cached_modifier(stat_name: String, stat_value: int) -> int:
	var cache_key = "%s_%d" % [stat_name, stat_value]
	
	if _modifier_cache.has(cache_key):
		return _modifier_cache[cache_key]
	
	# Calculate modifier (D&D style)
	var modifier: int = int(floor((stat_value - 10) / 2.0))
	_modifier_cache[cache_key] = modifier
	
	return modifier
