# 🎛️ SINGLETON MANAGERS SYSTEM - THE SAFE PLACE v0.9.7.4

## 🎯 **OVERVIEW SISTEMA MANAGERS**

Il progetto utilizza un sistema di **7 Singleton Managers consolidati** implementati tramite il sistema Autoload di Godot. Questa architettura consolidata riduce la complessità mantenendo tutte le funzionalità attraverso manager specializzati che comunicano via sistema di segnali per il disaccoppiamento architetturale.

### **🔄 Consolidamento v0.9.7.4**
- **Prima:** 12 manager separati con sovrapposizioni funzionali
- **Dopo:** 7 manager consolidati con responsabilità chiare
- **Benefici:** Riduzione complessità, migliori performance, manutenibilità migliorata
- **Compatibilità:** Mantenuti tutti gli alias legacy per retrocompatibilità

---

## 🗄️ **1. COREDATAMANAGER** *(Consolidato)*

### **Responsabilità Principali**
- Caricamento e caching di tutti i database JSON (items, enemies, quests)
- Validazione integrità dati oggetti
- Unificazione database categorizzati
- Sistema colori oggetti basato su categoria/rarità
- API per accesso dati validati
- **NUOVO:** Gestione dati nemici e quest (consolidato da EventManager)

### **File:** `scripts/managers/CoreDataManager.gd`
### **Alias Legacy:** `DataManager` → `CoreDataManager`

### **Struttura Dati Gestite**
```gdscript
# Database separati per categoria
var weapons: Dictionary = {}
var armor: Dictionary = {}
var consumables: Dictionary = {}
var crafting_materials: Dictionary = {}
var ammo: Dictionary = {}
var quest_items: Dictionary = {}
var unique_items: Dictionary = {}

# Database unificato per accesso rapido
var items: Dictionary = {}  # {"item_id": item_data}

# Sistema rarità condiviso
var rarity_system: Dictionary = {}
```

### **API Pubbliche Principali**
```gdscript
# Accesso dati oggetti
func get_item_data(item_id: String) -> Dictionary
func has_item(item_id: String) -> bool
func validate_item_data(item_data: Dictionary) -> bool

# Sistema colori dinamico (v0.4.0)
func get_item_color(item_id: String) -> Color
func get_category_color(category: String) -> Color
func get_rarity_multiplier(rarity: String) -> float

# Statistiche database
func get_total_items_count() -> int
func get_items_by_category(category: String) -> Array
```

### **Costanti Sistema Colori**
```gdscript
const CATEGORY_COLORS: Dictionary = {
    "WEAPON": Color(0.8, 0.2, 0.2),         # Rosso
    "ARMOR": Color(0.2, 0.6, 0.8),          # Blu
    "CONSUMABLE": Color(0.2, 0.8, 0.2),     # Verde
    "TOOL": Color(0.8, 0.6, 0.2),           # Arancione
    "AMMO": Color(0.6, 0.4, 0.2),           # Marrone
    "CRAFTING_MATERIAL": Color(0.6, 0.2, 0.8), # Viola
    "QUEST": Color(0.8, 0.8, 0.2),          # Giallo
    "UNIQUE": Color(0.8, 0.4, 0.6),         # Rosa
    "ACCESSORY": Color(0.4, 0.8, 0.8)       # Ciano
}

const RARITY_MULTIPLIERS: Dictionary = {
    "COMMON": 0.6,
    "UNCOMMON": 0.8, 
    "RARE": 1.0,
    "EPIC": 1.3,
    "LEGENDARY": 1.6
}
```

### **Segnali Emessi**
```gdscript
# Nessun segnale emesso - è un provider di dati
# Altri manager dipendono da DataManager ma non viceversa
```

---

## 👤 **2. PLAYERSYSTEMMANAGER** *(Consolidato)*

### **Responsabilità Principali**
- Gestione stato completo del giocatore
- Sistema inventario con limite slot
- Progressione personaggio (EXP, statistiche)
- Stati fisici (normale, ferito, malato, avvelenato)
- Applicazione conseguenze eventi
- Calcolo HP dinamico basato su Vigore
- **NUOVO:** Consolidato da PlayerManager + TimeManager per gestione sopravvivenza

### **File:** `scripts/managers/PlayerSystemManager.gd`
### **Alias Legacy:** `PlayerManager` → `PlayerSystemManager`

### **Struttura Stato Player**
```gdscript
# Risorse vitali
var hp: int = 100
var max_hp: int = 100
var food: int = 100
var max_food: int = 100
var water: int = 100
var max_water: int = 100

# Statistiche personaggio (4d6 drop lowest)
var stats: Dictionary = {
    "forza": 12,      # STR - combattimento melee
    "agilita": 14,    # DEX - combattimento ranged, schivare
    "intelligenza": 13, # INT - skill check tecnici
    "carisma": 11,    # CHA - interazioni sociali
    "fortuna": 16,    # LUC - eventi casuali
    "vigore": 15      # CON - calcolo HP
}

# Sistema progressione
var experience: int = 0
var experience_for_next_point: int = 100
var available_stat_points: int = 0

# Stati fisici
enum Status { NORMAL, WOUNDED, SICK, POISONED }
var active_statuses: Array[Status] = []

# Inventario (limite 10 slot)
const MAX_INVENTORY_SLOTS: int = 10
var inventory: Array[Dictionary] = []
# Struttura: [{"id": "item_id", "quantity": 1, "instance_data": {}}]

# Equipaggiamento
var equipped_weapon: Dictionary = {}
var equipped_armor: Dictionary = {}
```

### **API Pubbliche Principali**
```gdscript
# Creazione personaggio
func prepare_new_character_data() -> Dictionary
func finalize_character_creation() -> void

# Gestione risorse
func modify_hp(amount: int) -> void
func modify_food(amount: int) -> void  
func modify_water(amount: int) -> void

# Gestione inventario
func add_item(item_id: String, quantity: int = 1) -> bool
func remove_item(item_id: String, quantity: int = 1) -> bool
func get_item_count(item_id: String) -> int

# Sistema progressione
func add_experience(amount: int, source: String = "") -> void
func spend_stat_point(stat_name: String) -> bool
func get_stat_modifier(stat_name: String) -> int

# Skill check system
func skill_check(stat: String, difficulty: int, modifier: int = 0) -> Dictionary

# Stati e equipaggiamento
func add_status(status: Status) -> void
func remove_status(status: Status) -> void
func equip_weapon(item_id: String) -> bool
func equip_armor(item_id: String) -> bool

# Sistema transazioni oggetti (v0.4.0)
func apply_item_transaction(transaction: Dictionary) -> void
func _add_starting_items() -> void

# Metodi interni gestione inventario
func _generate_initial_stats() -> Dictionary
func _calculate_max_hp(vigor_stat: int) -> int
func _connect_time_manager_signals() -> void
```

### **Segnali Emessi**
```gdscript
signal inventory_changed           # Inventario modificato
signal stats_changed              # Statistiche cambiate
signal resources_changed          # HP/Food/Water modificati
signal narrative_log_generated(message: String)  # Log eventi
signal level_up_available         # Punti stat disponibili
signal status_effect_applied(status: String)     # Nuovo stato applicato
```

---

## ⏰ **3. TIMEMANAGER**

### **Responsabilità Principali**
- Gestione ciclo giorno/notte
- Calcolo tempo di gioco trascorso
- Applicazione penalità sopravvivenza automatiche
- Calcolo penalità movimento notturne
- Sistema di giorni sopravvissuti

### **File:** `scripts/managers/TimeManager.gd`

### **Struttura Temporale**
```gdscript
# Tempo di gioco
var game_minutes: int = 0       # Minuti totali in gioco
var days_survived: int = 1      # Giorni sopravvissuti
var current_hour: int = 8       # Ora corrente (8 AM start)

# Configurazione giorno/notte
var minutes_per_hour: int = 60  # 1 ora reale = 1 ora gioco
var hours_per_day: int = 24     # Ciclo completo 24 ore
var night_start_hour: int = 20  # 8 PM inizia notte
var day_start_hour: int = 6     # 6 AM inizia giorno

# Penalità sopravvivenza
var food_penalty_per_hour: int = 2   # Fame diminuisce
var water_penalty_per_hour: int = 3  # Sete diminuisce più veloce
var night_penalty_multiplier: float = 1.5  # Penalità notturne
```

### **API Pubbliche Principali**
```gdscript
# Avanzamento tempo
func advance_time(minutes: int) -> void
func skip_to_next_day() -> void

# Query stato temporale
func is_night() -> bool
func is_day() -> bool
func get_current_time_string() -> String
func get_formatted_day() -> String

# Penalità automatiche
func apply_survival_penalties() -> void
func get_movement_penalty_multiplier() -> float

# Calcoli temporali
func minutes_to_time_string(minutes: int) -> String
func get_day_progress_percentage() -> float
```

### **Segnali Emessi**
```gdscript
signal time_advanced(minutes: int)    # Tempo avanzato
signal day_changed(new_day: int)      # Nuovo giorno
signal night_started                  # Inizia notte
signal day_started                    # Inizia giorno
signal hour_changed(new_hour: int)    # Nuova ora
```

---

## 🎭 **4. EVENTMANAGER**

### **Responsabilità Principali**
- Caricamento eventi per bioma dai file JSON
- Trigger eventi casuali durante esplorazione
- Gestione skill check eventi
- Applicazione conseguenze eventi
- Cache eventi per performance

### **File:** `scripts/managers/EventManager.gd`

### **Struttura Eventi**
```gdscript
# Cache eventi per performance
var cached_events: Dictionary = {}
var biome_event_pools: Dictionary = {
    "foreste": [],
    "pianure": [],
    "citta": [],
    "villaggi": [],
    "fiumi": [],
    "ristoro": [],
    "unique": []
}

# Gestione evento corrente
var current_event: Dictionary = {}
var current_event_id: String = ""

# Configurazione probabilità per bioma
var biome_event_chances: Dictionary = {
    "pianure": 0.35,
    "foreste": 0.45,
    "villaggi": 0.55,
    "citta": 0.65,
    "fiumi": 0.40,
    "montagne": 0.30
}
```

### **API Pubbliche Principali**
```gdscript
# Inizializzazione
func initialize_events() -> void

# Gestione eventi
func trigger_random_event(biome: String) -> Dictionary
func get_random_event(biome: String) -> Dictionary
func process_event_choice(event_id: String, choice_index: int) -> Dictionary

# Utility
func get_events_count_for_biome(biome: String) -> int
func has_events_for_biome(biome: String) -> bool
```

### **Struttura Evento JSON**
```json
{
  "id": "event_unique_id",
  "title": "Titolo Evento",
  "description": "Descrizione situazione",
  "biome": "foreste",
  "choices": [
    {
      "text": "Scelta 1",
      "skill_check": {"stat": "agilita", "difficulty": 12},
      "consequences_success": {
        "narrative_text": "Messaggio successo",
        "items_gained": [{"id": "item_id", "quantity": 1}],
        "hp_change": 5
      },
      "consequences_failure": {
        "narrative_text": "Messaggio fallimento", 
        "hp_change": -10
      }
    }
  ]
}
```

### **Segnali Emessi**
```gdscript
signal event_triggered(event_data: Dictionary)
signal event_choice_resolved(result_text: String, narrative_log: String, skill_check_details: Dictionary)
```

---

## 🎲 **5. SKILLCHECKMANAGER**

### **Responsabilità Principali**
- Calcolo skill check basati su statistiche
- Sistema dadi D20 + modificatori
- Gestione difficoltà dinamiche
- Calcolo modificatori situazionali
- Log dettagliati risultati

### **File:** `scripts/managers/SkillCheckManager.gd`

### **Sistema Skill Check**
```gdscript
# Formula base: d20 + stat_modifier + situational_modifier vs DC
func perform_skill_check(stat_value: int, difficulty: int, modifier: int = 0) -> Dictionary:
    var d20_roll = randi_range(1, 20)
    var stat_modifier = get_stat_modifier(stat_value)
    var total = d20_roll + stat_modifier + modifier
    var success = total >= difficulty
    
    return {
        "success": success,
        "roll": d20_roll,
        "stat_modifier": stat_modifier,
        "situational_modifier": modifier,
        "total": total,
        "difficulty": difficulty,
        "margin": total - difficulty
    }
```

### **Modificatori Statistiche (D&D-style)**
```gdscript
func get_stat_modifier(stat_value: int) -> int:
    # Formula D&D: (stat - 10) / 2
    return (stat_value - 10) / 2

# Esempi:
# Stat 8  → Modifier -1
# Stat 10 → Modifier +0  
# Stat 12 → Modifier +1
# Stat 14 → Modifier +2
# Stat 16 → Modifier +3
# Stat 18 → Modifier +4
```

### **API Pubbliche**
```gdscript
func perform_skill_check(stat_value: int, difficulty: int, modifier: int = 0) -> Dictionary
func get_stat_modifier(stat_value: int) -> int
func get_difficulty_description(dc: int) -> String
func calculate_success_chance(stat_value: int, difficulty: int, modifier: int = 0) -> float
```

### **Difficoltà Standard**
```
DC 5:  Molto Facile (95% successo con stat 10)
DC 10: Facile (60% successo con stat 10)
DC 15: Medio (30% successo con stat 10)
DC 20: Difficile (10% successo con stat 10)
DC 25: Molto Difficile (1% successo con stat 10)
```

---

## ⌨️ **6. INPUTMANAGER**

### **Responsabilità Principali**
- Processamento input da tastiera
- Gestione stati input (inventario attivo, popup aperti)
- Mapping hotkey (1-9 per inventario)
- Prevenzione input conflittuali
- Debug input (F9)

### **File:** `scripts/managers/InputManager.gd`

### **Input States**
```gdscript
# Stati input per prevenire conflitti
var is_inventory_active: bool = false
var is_popup_active: bool = false
var is_character_creation_active: bool = false

# Mapping hotkey inventario
var hotkey_map: Dictionary = {
    KEY_1: 1, KEY_2: 2, KEY_3: 3, KEY_4: 4, KEY_5: 5,
    KEY_6: 6, KEY_7: 7, KEY_8: 8, KEY_9: 9
}
```

### **API Pubbliche**
```gdscript
# Gestione stati
func set_inventory_active(active: bool) -> void
func set_popup_active(active: bool) -> void
func can_process_movement() -> bool
func can_process_inventory() -> bool

# Debug
func show_debug_info() -> void
```

### **Segnali Emessi**
```gdscript
signal map_move(direction: Vector2i)              # Movimento mappa
signal inventory_toggle                           # Toggle inventario
signal inventory_use_item(slot_number: int)      # Usa oggetto slot
signal action_confirm                             # Azione conferma
signal action_cancel                              # Azione annulla
signal level_up_request                           # Richiesta level up
signal debug_info_requested                       # Info debug F9
```

---

## 🎨 **7. THEMEMANAGER**

### **Responsabilità Principali**
- Gestione tema CRT retro
- Caricamento font Perfect DOS VGA
- Applicazione shader CRT
- Configurazione colori terminale
- Gestione palette colori UI

### **File:** `scripts/ThemeManager.gd`

### **Risorse Tema**
```gdscript
# Tema principale
var main_theme: Theme = preload("res://themes/main_theme.tres")

# Font CRT
var main_font: Font = preload("res://themes/Perfect DOS VGA 437 Win.ttf")

# Shader materials
var crt_material: ShaderMaterial = preload("res://themes/crt_material.tres")
var crt_simple_material: ShaderMaterial = preload("res://themes/crt_simple_material.tres")
```

### **API Pubbliche**
```gdscript
func get_main_theme() -> Theme
func get_main_font() -> Font
func get_crt_material() -> ShaderMaterial
func apply_crt_effect_to_node(node: Control) -> void
func get_terminal_color(color_name: String) -> Color
```

### **Palette Colori CRT**
```gdscript
var terminal_colors: Dictionary = {
    "green": Color(0.0, 1.0, 0.0),      # Verde fosforescente
    "amber": Color(1.0, 0.75, 0.0),     # Ambra
    "white": Color(0.9, 0.9, 0.9),      # Bianco CRT
    "red": Color(1.0, 0.2, 0.2),        # Rosso errore
    "blue": Color(0.2, 0.6, 1.0),       # Blu info
    "yellow": Color(1.0, 1.0, 0.2)      # Giallo warning
}
```

---

## ⚔️ **8. COMBATMANAGER**

### **Responsabilità Principali**
- Gestione sistema combattimento turn-based
- Calcolo danni e risoluzione combattimenti
- Gestione stati combattimento (idle, player_turn, enemy_turn)
- Integrazione con PlayerManager per statistiche
- Sistema di escalation difficoltà nemici

### **File:** `scripts/managers/CombatManager.gd`

### **Struttura Stato Combattimento**
```gdscript
enum CombatState {
    IDLE,           # Nessun combattimento attivo
    PLAYER_TURN,    # Turno del giocatore
    ENEMY_TURN,     # Turno del nemico
    RESOLVING,      # Risoluzione turno
    ENDED           # Combattimento terminato
}

# Stato corrente combattimento
var current_combat_state: CombatState = CombatState.IDLE
var current_enemy: Dictionary = {}
var combat_log: Array = []
```

### **API Pubbliche Principali**
```gdscript
# Inizio combattimento
func start_combat(enemy_id: String) -> bool

# Azioni giocatore
func process_player_action(action: String, target: String = "") -> Dictionary

# Risoluzione turno nemico
func process_enemy_turn() -> Dictionary

# Fine combattimento
func end_combat(result: String) -> void

# Utility combattimento
func calculate_damage(attacker_stats: Dictionary, weapon_data: Dictionary) -> int
func get_available_actions() -> Array
func get_combat_state() -> Dictionary
```

### **Segnali Emessi**
```gdscript
signal combat_started(enemy_data: Dictionary)          # Combattimento iniziato
signal combat_ended(result: String, rewards: Dictionary) # Combattimento finito
signal turn_changed(new_state: CombatState)            # Cambio turno
signal damage_dealt(amount: int, is_player_damage: bool) # Danno inflitto
signal combat_action_performed(action: String, success: bool) # Azione eseguita
```

---

## 🔨 **9. CRAFTINGMANAGER**

### **Responsabilità Principali**
- Gestione sistema crafting e produzione
- Validazione ricette e materiali richiesti
- Calcolo qualità prodotti basata su materiali
- Sistema workbench per rifugi
- Progressione abilità crafting

### **File:** `scripts/managers/CraftingManager.gd`

### **Struttura Sistema Crafting**
```gdscript
# Database ricette
var crafting_recipes: Dictionary = {}

# Stato workbench
var workbench_active: bool = false
var current_workbench_level: int = 1

# Statistiche crafting
var crafting_skill: int = 1
var crafted_items_count: int = 0
```

### **API Pubbliche Principali**
```gdscript
# Sistema workbench
func set_workbench_access(has_access: bool) -> void
func get_available_recipes() -> Array

# Crafting operations
func can_craft_recipe(recipe_id: String) -> bool
func craft_item(recipe_id: String) -> Dictionary

# Sistema qualità
func calculate_craft_quality(materials_used: Array) -> float
func get_quality_multiplier(quality: float) -> float

# Progressione
func improve_crafting_skill(experience: int) -> void
func get_crafting_skill_level() -> int
```

### **Segnali Emessi**
```gdscript
signal workbench_access_changed(has_access: bool)      # Accesso workbench cambiato
signal item_crafted(item_data: Dictionary, quality: float) # Oggetto crafted
signal crafting_skill_improved(new_level: int)        # Abilità crafting migliorata
signal recipe_unlocked(recipe_id: String)              # Ricetta sbloccata
```

---

## 📖 **10. NARRATIVEMANAGER**

### **Responsabilità Principali**
- Gestione stato emotivo del giocatore
- Sistema ricordi familiari e lore
- Calcolo empatia con personaggi
- Influenza narrativa basata su scelte passate
- Sistema di immersione narrativa

### **File:** `scripts/managers/NarrativeManager.gd`

### **Struttura Stato Narrativo**
```gdscript
# Stato emotivo
var emotional_state: Dictionary = {
    "current_state": "cold_pragmatic",  # Stato corrente
    "connection_level": 1,              # Livello connessione (1-5)
    "morality_alignment": 0,            # Allineamento morale (-10 a +10)
    "trust_level": 0                    # Livello fiducia (-5 a +5)
}

# Sistema ricordi
var memories_unlocked: Array = []
var character_empathy: Dictionary = {}  # Empatia per personaggio
var lore_progression: Dictionary = {}   # Progressione storia
```

### **API Pubbliche Principali**
```gdscript
# Stato emotivo
func get_emotional_state() -> Dictionary
func update_emotional_state(trigger: String, intensity: int) -> void

# Sistema ricordi
func unlock_memory(memory_id: String) -> bool
func get_memory_count() -> int
func has_memory(memory_id: String) -> bool

# Empatia personaggi
func update_character_empathy(character: String, change: int) -> void
func get_character_relationship(character: String) -> String

# Progressione narrativa
func advance_lore_progression(lore_id: String) -> void
func get_lore_completion_percentage() -> float
```

### **Segnali Emessi**
```gdscript
signal emotional_state_changed(new_state: Dictionary)  # Stato emotivo cambiato
signal memory_unlocked(memory_id: String)              # Ricordo sbloccato
signal empathy_changed(character: String, new_level: int) # Empatia cambiata
signal lore_progressed(lore_id: String, progress: float) # Progressione lore
```

---

## 🎯 **11. QUESTMANAGER**

### **Responsabilità Principali**
- Gestione sistema missioni strutturato
- Progressione quest principale e secondarie
- Tracking obiettivi e condizioni completamento
- Sistema ricompense quest
- Integrazione narrativa con eventi

### **File:** `scripts/managers/QuestManager.gd`

### **Struttura Sistema Quest**
```gdscript
# Database quest
var main_quest: Dictionary = {}
var side_quests: Dictionary = {}
var completed_quests: Array = []

# Stato attivo
var active_quests: Dictionary = {}
var quest_progress: Dictionary = {}  # Progress per quest

# Sistema obiettivi
var quest_objectives: Dictionary = {}
var objective_tracking: Dictionary = {}
```

### **API Pubbliche Principali**
```gdscript
# Inizializzazione
func initialize_quests() -> void

# Gestione quest
func start_quest(quest_id: String) -> bool
func complete_quest(quest_id: String) -> bool
func abandon_quest(quest_id: String) -> bool

# Tracking obiettivi
func update_quest_progress(quest_id: String, objective_id: String, progress: int) -> void
func check_quest_completion(quest_id: String) -> bool

# Query
func get_active_quests() -> Array
func get_quest_details(quest_id: String) -> Dictionary
func get_quest_progress(quest_id: String) -> Dictionary
```

### **Segnali Emessi**
```gdscript
signal quest_started(quest_id: String)                 # Quest avviata
signal quest_completed(quest_id: String, rewards: Dictionary) # Quest completata
signal quest_progress_updated(quest_id: String, objective: String) # Progress aggiornato
signal quest_failed(quest_id: String)                  # Quest fallita
signal objective_completed(quest_id: String, objective_id: String) # Obiettivo completato
```

---

## 💾 **12. SAVELOADMANAGER**

### **Responsabilità Principali**
- Sistema completo salvataggio/caricamento
- Serializzazione stato di gioco completo
- Gestione slot salvataggio multipli
- Backup automatico e recovery
- Integrazione con tutti i manager

### **File:** `scripts/managers/SaveLoadManager.gd`

### **Struttura Sistema Salvataggio**
```gdscript
# Slot salvataggio
var available_saves: Array = []
var current_save_slot: int = -1
var auto_save_enabled: bool = true

# Dati salvataggio
var save_data_structure: Dictionary = {
    "metadata": {},
    "player": {},
    "world": {},
    "quests": {},
    "narrative": {},
    "combat": {},
    "inventory": {},
    "timestamp": 0
}
```

### **API Pubbliche Principali**
```gdscript
# Operazioni salvataggio
func save_game(slot: int = -1) -> bool
func quick_save() -> bool
func auto_save() -> void

# Operazioni caricamento
func load_game(slot: int) -> bool
func quick_load() -> bool

# Gestione slot
func get_available_save_slots() -> Array
func delete_save_slot(slot: int) -> bool
func get_save_metadata(slot: int) -> Dictionary

# Utility
func validate_save_data(save_data: Dictionary) -> bool
func create_backup(slot: int) -> bool
```

### **Segnali Emessi**
```gdscript
signal game_saved(slot: int, success: bool)            # Gioco salvato
signal game_loaded(slot: int, success: bool)           # Gioco caricato
signal save_slot_created(slot: int)                     # Slot creato
signal save_slot_deleted(slot: int)                     # Slot eliminato
signal auto_save_completed(success: bool)               # Auto-save completato
```

---

## 🔄 **INTER-MANAGER COMMUNICATION**

### **Dependency Graph**
```
ThemeManager ← (utilizzato da) GameUI
    ↑
DataManager ← PlayerManager ← EventManager ← CombatManager
    ↑             ↑              ↑              ↑
    └─── InputManager ←──── TimeManager ←──── CraftingManager
                ↑                    ↑              ↑
           SkillCheckManager ←──── NarrativeManager
                                      ↑
                                 QuestManager ← SaveLoadManager
```

### **Signal Chain Examples**

#### **Movement Chain**
```
1. User Input (WASD)
   ↓
2. InputManager._input()
   ↓ 
3. InputManager.map_move signal
   ↓
4. World._on_map_move()
   ↓
5. World.player_moved signal
   ↓
6. MainGame._on_player_moved()
   ↓
7. TimeManager.advance_time()
   ↓
8. TimeManager.time_advanced signal
   ↓
9. PlayerManager._on_time_advanced()
   ↓
10. PlayerManager.resources_changed signal
    ↓
11. UI Panels update
```

#### **Event Chain**
```
1. MainGame determines event trigger
   ↓
2. EventManager.trigger_random_event()
   ↓
3. EventManager.event_triggered signal
   ↓
4. GameUI shows EventPopup
   ↓
5. User selects choice
   ↓
6. EventManager.process_event_choice()
   ↓
7. SkillCheckManager.perform_skill_check()
   ↓
8. EventManager.event_choice_resolved signal
   ↓
9. PlayerManager applies consequences
   ↓
10. PlayerManager state change signals
    ↓
11. UI updates reflect changes
```

---

## 🛡️ **ERROR HANDLING E VALIDATION**

### **DataManager Validation**
```gdscript
func validate_item_data(item_data: Dictionary) -> bool:
    var required_fields = ["id", "name", "category", "rarity"]
    for field in required_fields:
        if not item_data.has(field):
            return false
    return true
```

### **PlayerManager Safety Checks**
```gdscript
func add_item(item_id: String, quantity: int = 1) -> bool:
    # Validazione con DataManager
    if not DataManager.has_item(item_id):
        print("❌ Oggetto non trovato: ", item_id)
        return false
    
    # Controllo limite inventario
    if inventory.size() >= MAX_INVENTORY_SLOTS:
        print("⚠️ Inventario pieno")
        return false
        
    # Operazione sicura
    return true
```

### **EventManager Error Recovery**
```gdscript
func get_random_event(biome: String) -> Dictionary:
    if not biome_event_pools.has(biome):
        print("❌ Bioma non trovato: ", biome)
        return {}
        
    var events = biome_event_pools[biome]
    if events.is_empty():
        print("⚠️ Nessun evento per bioma: ", biome)
        return {}
        
    return events[randi() % events.size()]
```

---

## 📊 **PERFORMANCE PATTERNS**

### **Caching Strategies**
```gdscript
# DataManager - Cache JSON in memoria
var items: Dictionary = {}  # No ricaricamento

# EventManager - Cache eventi per bioma  
var biome_event_pools: Dictionary = {}  # Accesso O(1)

# PlayerManager - No caching (stato live)
# ThemeManager - Preload resources
# InputManager - No caching necessario
```

### **Signal Optimization**
```gdscript
# Controllo connessioni duplicate
if not signal_name.is_connected(callback):
    signal_name.connect(callback)

# Batch updates per UI
signal resources_changed  # Singolo segnale per HP/Food/Water
```

### **Memory Management**
```gdscript
# No memory leak - solo singleton persistenti
# Popup cleanup gestito da GameUI
# JSON data persiste per tutta la sessione
```

---

## 🔧 **INITIALIZATION SEQUENCE**

### **Critical Initialization Order**
```
1. ThemeManager._ready()     # Carica tema e font
2. DataManager._ready()      # Carica tutti i JSON database
3. PlayerManager._ready()    # Prepara stato player (vuoto)
4. InputManager._ready()     # Setup input handlers
5. TimeManager._ready()      # Inizializza tempo gioco
6. EventManager._ready()     # Prepara sistema eventi
7. SkillCheckManager._ready() # Setup formule skill check
8. QuestManager._ready()     # Sistema missioni
9. NarrativeManager._ready() # Sistema narrativo
10. CraftingManager._ready() # Sistema crafting
11. CombatManager._ready()   # Sistema combattimento
12. SaveLoadManager._ready() # Sistema salvataggio

13. MainGame._ready()        # Coordinamento generale
    ├── EventManager.initialize_events()  # Post-init eventi
    ├── QuestManager.initialize_quests()  # Post-init quest
    ├── PlayerManager.prepare_new_character_data()
    └── Signal connections

14. GameUI._ready()          # Setup UI e world scene
```

### **Dependencies Check**
```gdscript
# Pattern standard per verifica dipendenze
func _ready():
    if not DataManager:
        push_error("DataManager non disponibile")
        return
        
    if not PlayerManager:
        push_error("PlayerManager non disponibile") 
        return
        
    # Proceed with initialization
```

---

## 📋 **TESTING E DEBUGGING**

### **Manager-Specific Debug**
```gdscript
# DataManager debug
func _debug_print_loaded_items():
    print("=== DataManager Debug ===")
    print("Total items: ", items.size())
    for category in ["WEAPON", "ARMOR", "CONSUMABLE"]:
        print(category, ": ", get_items_by_category(category).size())

# PlayerManager debug  
func _debug_print_player_state():
    print("=== PlayerManager Debug ===")
    print("HP: ", hp, "/", max_hp)
    print("Food: ", food, "/", max_food)
    print("Water: ", water, "/", max_water)
    print("Inventory: ", inventory.size(), "/", MAX_INVENTORY_SLOTS)

# EventManager debug
func _debug_print_event_pools():
    print("=== EventManager Debug ===")
    for biome in biome_event_pools.keys():
        print(biome, ": ", biome_event_pools[biome].size(), " eventi")
```

## 📝 **STANDARDIZED LOGGING PATTERN**

### **Logger Utility (v0.4.0)**
The project now includes a standardized logging utility (`scripts/tools/Logger.gd`) for consistent log formatting:

```gdscript
# Standard logging format: [LEVEL] Icon ManagerName: Message
Logger.info("PlayerManager", "Dati personaggio preparati")
Logger.error("DataManager", "File non trovato: items.json")
Logger.success("EventManager", "Evento triggerato con successo")
Logger.warn("InputManager", "Input state conflict detected")
Logger.debug("ThemeManager", "Shader compilation details")
```

### **Manager Log Prefixes**
```
🗄️ DataManager       - Database operations and validation
👤 PlayerManager      - Player state and progression
🎭 EventManager       - Event triggering and processing
⏰ TimeManager        - Time system and penalties
⌨️ InputManager       - Input processing and states
🎨 ThemeManager       - UI theming and resources
🎲 SkillCheckManager  - Skill test calculations
⚔️ CombatManager      - Combat system and resolution
🔨 CraftingManager    - Crafting and production
📖 NarrativeManager   - Emotional state and memories
🎯 QuestManager       - Quest tracking and progression
💾 SaveLoadManager    - Save/load operations
 MainGame           - Game flow coordination
🗺️ World             - Map and movement systems
🖥️ GameUI            - UI updates and interactions
```

### **Usage Examples**
```gdscript
# In DataManager.gd
Logger.info("DataManager", "Caricamento database iniziato")
Logger.operation_result("DataManager", "JSON Parse", success, error_details)

# In PlayerManager.gd  
Logger.success("PlayerManager", "Personaggio creato con successo")
Logger.warn("PlayerManager", "Inventario pieno - item non aggiunto")

# In EventManager.gd
Logger.debug("EventManager", "Pool eventi caricato per bioma: %s" % biome)
Logger.error("EventManager", "Evento malformato: %s" % event_id)
```

---

**Versione:** v0.9.7.1 "Is it a Game or a Library?"
**Data:** 24 Settembre 2025
**Target:** LLM Technical Analysis - Singleton Architecture
