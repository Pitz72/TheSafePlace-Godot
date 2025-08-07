# CombatUI.gd
#
# Gestisce l'interfaccia utente per la schermata di combattimento.
# Ascolta i segnali dal CombatManager per aggiornare lo stato visivo.
# Emette segnali al CombatManager quando il giocatore compie un'azione.

extends ColorRect

# Riferimenti ai nodi della scena (verranno collegati nella scena .tscn)
@onready var player_hp_label = $VBoxContainer/StatsHBox/PlayerStats/PlayerHPLabel
@onready var enemy_name_label = $VBoxContainer/StatsHBox/EnemyStats/EnemyNameLabel
@onready var enemy_hp_label = $VBoxContainer/StatsHBox/EnemyStats/EnemyHPLabel
@onready var combat_log = $VBoxContainer/CombatLog
@onready var attack_button = $VBoxContainer/ActionsHBox/AttackButton

# Dati locali per l'aggiornamento dell'UI
var _player_max_hp: int = 100
var _enemy_max_hp: int = 10

func _ready():
    # L'UI di combattimento è nascosta di default
    hide()

    # Connessione ai segnali del CombatManager
    if CombatManager:
        CombatManager.combat_started.connect(_on_combat_started)
        CombatManager.combat_ended.connect(_on_combat_ended)
        CombatManager.combat_log_updated.connect(_on_combat_log_updated)
        CombatManager.player_health_changed.connect(_on_player_health_changed)
        CombatManager.enemy_health_changed.connect(_on_enemy_health_changed)
        CombatManager.turn_changed.connect(_on_turn_changed)
        print("[CombatUI] Connesso ai segnali di CombatManager.")
    else:
        print("❌ [CombatUI] Errore: CombatManager non trovato.")

# ========================================
# GESTIONE VISIBILITÀ
# ========================================

func show_ui():
    self.visible = true
    print("[CombatUI] UI di combattimento mostrata.")

func hide_ui():
    self.visible = false
    print("[CombatUI] UI di combattimento nascosta.")

# ========================================
# GESTORI SEGNALI DA COMBATMANAGER
# ========================================

func _on_combat_started(player_data: Dictionary, enemy_data: Dictionary):
    print("[CombatUI] Ricevuto segnale 'combat_started'.")

    # Salva i dati per aggiornamenti futuri
    _player_max_hp = player_data.get("max_hp", 100)
    _enemy_max_hp = enemy_data.get("stats", {}).get("max_hp", 10)

    # Popola l'UI con i dati iniziali
    _on_player_health_changed(player_data.get("hp", 100))

    enemy_name_label.text = enemy_data.get("name", "Nemico Sconosciuto")
    _on_enemy_health_changed(enemy_data.get("stats", {}).get("max_hp", 10))

    # Pulisci il log e mostra il messaggio iniziale
    combat_log.clear()
    combat_log.add_text("Inizia il combattimento contro %s!" % enemy_name_label.text)

    attack_button.disabled = false
    show_ui()

func _on_combat_ended(result: String):
    print("[CombatUI] Ricevuto segnale 'combat_ended'.")
    combat_log.add_text("\n\nCombattimento terminato. Risultato: [b]%s[/b]" % result.to_upper())
    attack_button.disabled = true

    # Nascondi l'UI dopo un breve ritardo per permettere al giocatore di leggere il risultato
    get_tree().create_timer(3.0).timeout.connect(hide_ui)

func _on_combat_log_updated(message: String):
    combat_log.add_text("\n" + message)
    combat_log.scroll_to_line(combat_log.get_line_count()) # Auto-scroll

func _on_player_health_changed(new_health: int):
    player_hp_label.text = "HP: %d / %d" % [new_health, _player_max_hp]

func _on_enemy_health_changed(new_health: int):
    enemy_hp_label.text = "HP: %d / %d" % [new_health, _enemy_max_hp]

func _on_turn_changed(current_turn: String):
    # Abilita/disabilita il pulsante di attacco in base al turno
    if current_turn == "player":
        attack_button.disabled = false
    else:
        attack_button.disabled = true

# ========================================
# GESTORI SEGNALI DAI NODI UI
# ========================================

func _on_attack_button_pressed():
    print("[CombatUI] Pulsante 'Attacca' premuto.")

    # Disabilita il pulsante per prevenire input multipli
    attack_button.disabled = true

    # Notifica il CombatManager che il giocatore vuole attaccare
    if CombatManager:
        CombatManager.player_perform_attack()
    else:
        _on_combat_log_updated("Errore: Impossibile comunicare con CombatManager.")
        attack_button.disabled = false # Riabilita se c'è un errore
