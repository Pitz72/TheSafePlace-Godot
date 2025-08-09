# CHANGELOG - The Safe Place

Tutte le modifiche significative di questo progetto saranno documentate in questo file.

Il formato è basato su [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e questo progetto aderisce al [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v0.3.0] - 2025-01-28 "THE CHOSEN ONE"

### ✨ NUOVE FEATURES
- **Sistema Creazione Personaggio Interattivo** - Popup dinamico all'avvio con generazione statistiche 4d6 drop lowest
- **Rivelazione Progressiva Stats** - Animazione sequenziale delle statistiche generate (Forza → Agilità → Intelligenza → Carisma → Fortuna → Vigore → HP)
- **Hotkey System Avanzato** - Controllo completo da tastiera: R per rigenerare, INVIO/SPAZIO per accettare, ESC per annullare
- **Integrazione Seamless PlayerManager** - Applicazione automatica stats generate + oggetti iniziali + aggiornamento UI completo
- **Gestione Stati Input Sofisticata** - Transizione automatica MAP ↔ POPUP con blocco input durante generazione

### 🎨 MIGLIORAMENTI UI/UX
- **Visual Polish Character Creation** - Interfaccia elegante con fade-in progressivo e feedback visivo in tempo reale
- **Responsive Button States** - Pulsanti dinamici con colori contestuali (grigio → verde/giallo) e testi descrittivi
- **Perfect Input Handling** - Gestione mouse + tastiera unificata con protezione anti-double-click
- **Instant UI Refresh** - Aggiornamento immediato tutti i pannelli post-accettazione personaggio

### 🔧 ARCHITETTURA & INTEGRAZIONE
- **Character Creation Popup System** - Nuovo modulo completamente integrato con GameUI esistente
- **Signal-Based Communication** - Comunicazione pulita via `popup_closed`/`character_accepted` signals
- **Clean Instance Management** - Gestione corretta istanze popup con prevenzione memory leaks
- **Backward Compatibility 100%** - Zero breaking changes, sistema esistente preservato integralmente

### 📁 FILES MODIFICATI
- `scripts/ui/GameUI.gd` - Aggiunta orchestrazione popup + signal handlers
- `scripts/ui/popups/CharacterCreationPopup.gd` - Implementazione completa sistema creazione
- `scenes/ui/popups/CharacterCreationPopup.tscn` - Layout e struttura visuale popup

### 🧪 QUALITÀ & TESTING
- **Error Handling Robusto** - Gestione corretta edge cases e stati inconsistenti
- **Performance Optimized** - Animazioni fluide 60fps+ con timer ottimizzati
- **Input State Validation** - Prevenzione conflitti input durante transizioni stato
- **Clean Code Architecture** - Separazione responsabilità e codice maintainable

### 🎯 ACHIEVEMENT UNLOCKED
**"The Chosen One"** - Sistema creazione personaggio che trasforma ogni nuovo gioco in un'esperienza unica e coinvolgente

---

## [v0.2.6] - 2024-12-19 "NO MORE DOUBLE STEPS"

### 🔧 RISOLTI
- **Bug Critico: Doppio Avanzamento Tempo** - Risolto il problema che causava l'avanzamento di 60 minuti invece di 30 per ogni movimento
- **Bug Critico: Messaggi Duplicati** - Eliminati i messaggi duplicati nel diario di gioco
- **Bug Critico: Effetti Duplicati** - Risolte penalità duplicate (HP notturna, attraversamento fiumi)

### 🏗️ MODIFICHE ARCHITETTURALI
- **Istanza World Unica** - Rimossa l'istanza duplicata di World.tscn da MainGame.tscn
- **Connessioni Segnali Ottimizzate** - Refactoring MainGame.gd per connessione dinamica ai segnali World
- **SubViewport Consolidato** - World ora istanziato esclusivamente nel SubViewport di GameUI

### 📁 FILES MODIFICATI
- `scenes/MainGame.tscn` - Rimossa istanza World duplicata
- `scripts/MainGame.gd` - Refactoring connessioni segnali con fallback deferred

### 🔒 ANTI-REGRESSIONE
- Aggiornato ANTI_REGRESSION_TESTS.md con nuovo test "Double World Prevention"
- Implementate verifiche strutturali per prevenire future duplicazioni
- Procedure di validazione consolidate

---

## [v0.2.5] - 2025-01-28 "WHEN THINGS HAPPEN"

### ✨ NUOVE FEATURES
- **Sistema Eventi Dinamico** con cooldown intelligente e probabilità per bioma
- **EventManager Singleton** per gestione centralizzata eventi
- **Database Eventi JSON** strutturato con eventi contestualizzati
- **Integrazione Signal-Based** con PlayerManager per trigger automatici

### 🔧 MIGLIORAMENTI
- Sistema eventi con cooldown per bioma specifico
- Performance ottimizzate per gestione eventi in tempo reale
- 89/89 test anti-regressione superati

---

## [v0.2.1] - 2025-01-28 "THE POLISHED INSPECTOR"

### ✨ NUOVE FEATURES
- **Popup Professionale** per interazione oggetti con griglia 2-colonne
- **Navigazione Keyboard-Only** con evidenziazione negativa
- **Localizzazione Completa** italiana per interfaccia
- **Sistema Porzioni** per consumo intelligente oggetti
- **Azioni Contestuali** basate su tipo oggetto

### 🎨 MIGLIORAMENTI UX
- Bordo verde 2px per popup professionali
- Sfondo opaco ottimizzato per readability
- Log narrativo immersivo invece di testo tecnico

---

## [v0.1.5] - 2025-01-21 "THE MONITOR FRAME"

### 🖥️ NUOVE FEATURES
- **MainGame.tscn** - Scena principale unificata
- **Monitor Frame Concept** - GameUI come cornice monitor anni '80
- **SubViewport Integration** - World renderizzato nel pannello mappa UI
- **Camera Equilibrata** - Zoom 0.8x per visuale ottimale

### 🚧 PROBLEMI RISOLTI
- Path corruption critico (pulizia cache Godot)
- Camera zoom calibrazione
- Input forwarding errors

---

## [v0.1.4] - 2025-01-25 "THE INVENTORY MASTER"

### 🎮 NUOVE FEATURES
- **Navigazione WASD + Frecce** per inventario
- **Evidenziazione Visuale** con sistema `> [1] [2] [3]`
- **Consumo Reale Oggetti** con rimozione inventario
- **Hotkey Diretti** tasti 1-9 per uso immediato
- **Sistema Effetti** heal, nourish, hydrate automatici

---

## [v0.1.3] - 2025-01-24 "THE UI MASTER"

### 🎨 NUOVE FEATURES
- **GameUI Completa** - Layout 3-colonne con 13 pannelli
- **Reactive Architecture** - 16 referenze @onready + segnali PlayerManager
- **ASCII Style** - Conversione da emoji a marcatori ASCII puri
- **World Integration** - SubViewport per World.tscn nel pannello centrale

---

## [v0.1.2] - 2025-01-23 "THE PLAYER MANAGER"

### 🎮 NUOVE FEATURES
- **PlayerManager Singleton** - Sistema completo gestione stato giocatore
- **Risorse Vitali** - HP/Food/Water con segnali reattivi
- **Sistema Inventario** - Add/remove oggetti con stackable support
- **Statistiche** - 5 attributi personaggio
- **Equipaggiamento** - Gestione armi/armature

---

## [v0.1.1] - 2025-01-22 "THE WORLD ECOSYSTEM"

### 🌍 NUOVE FEATURES
- **World System v2.0** - Architettura avanzata con ecosystem completo
- **DataManager Integration** - Unificazione database 52 oggetti
- **Performance Excellence** - 60+ FPS stabili mondo 250x250
- **Camera System** - Zoom e limiti ottimizzati

---

## [v0.1.0] - 2025-01-21 "MY SMALL, WONDERFUL AND DEVASTATED WORLD"

### 🌍 MILESTONE STORICO
- **Primo mondo ASCII completo navigabile**
- **Conversione perfetta mappa 250x250** su TileMap Godot
- **Sistema player** con movimento fluido e camera tracking
- **Performance 60+ FPS** stabili su mondo 62.500 tiles

---

## [v0.0.6] - 2025-01-20 "TILEMAP MIGRATION SUCCESS"

### 🔄 MIGRAZIONE MAGGIORE
- Completata migrazione da RichTextLabel a TileMap
- Risolte performance con 62.500 tag BBCode
- Sistema texture generate per ASCII characters

---

## [v0.0.4] - 2025-01-19 "THE DATABASE MANAGER"

### 📊 SISTEMA DATABASE
- **DataManager Singleton** implementato
- **52 oggetti modulari** categorizzati da 7 file JSON
- **Sistema rarità** e localizzazione completa

---

## [v0.0.3] - 2025-01-19 "FOUND OBJECTS"

### 📦 SISTEMA OGGETTI
- Database oggetti modulare implementato
- Categorizzazione: armi, armature, consumabili, materiali
- Sistema rarità e statistiche complete

---

## [v0.0.2b] - 2025-01-18 "REPAIRING THE OLD MONITOR"

### 🖥️ SISTEMA CRT
- **Shader CRT autentico** con scanline e fosfori verdi
- **Effetti vintage**: rumore animato, curvatura schermo
- **ThemeManager avanzato** per gestione temi dinamici

---

## [v0.0.1] - 2025-01-18 "FOUNDATION"

### 🏗️ FONDAMENTA
- **Setup iniziale** Godot 4.4.1
- **Font Perfect DOS VGA 437** implementato
- **Tema verde terminale** anni '80 autentico
- **ThemeManager Singleton** per gestione temi globali