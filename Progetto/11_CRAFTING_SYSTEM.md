# 🛠️ Progetto/11_CRAFTING_SYSTEM.md - Documento di Design

**Versione:** 0.1 (Bozza Iniziale)
**Data:** 2025-08-25
**Autore:** Jules (AI Development Director)
**Stato:** 🟡 In Progettazione

## 1. Panoramica e Obiettivi

Questo documento descrive l'architettura e il funzionamento del sistema di crafting per "The Safe Place". L'obiettivo è creare un sistema intuitivo, espandibile e profondamente integrato con le meccaniche di gioco esistenti (inventario, abilità, mondo di gioco).

## 2. Architettura dei Dati

Il cuore del sistema di crafting sarà un nuovo file JSON di ricette.

### 2.1. Struttura Ricette (`data/crafting/recipes.json`)

Ogni ricetta sarà un oggetto JSON con la seguente struttura:

```json
{
  "recipe_id": "craft_medkit_basic",
  "recipe_name": "Crea Kit Medico di Base",
  "description": "Assembla bende e disinfettante per creare un kit medico.",
  "category": "medico",
  "required_materials": [
    { "item_id": "bandage", "quantity": 2 },
    { "item_id": "disinfectant", "quantity": 1 }
  ],
  "output_item_id": "medkit_basic",
  "output_quantity": 1,
  "requirements": {
    "skill": "medicina",
    "level": 10,
    "workstation": "workbench"
  },
  "experience_gained": 15
}
```
*   **`category`**: Categorie possibili: "armi", "armature", "consumabili", "strumenti", "modifiche".
*   **`requirements`**: Oggetto opzionale. Può contenere `skill`, `level` e `workstation` (es. "fuoco_da_campo", "banco_da_lavoro").
*   **`experience_gained`**: Punti esperienza guadagnati al successo (opzionale).

## 3. Logica del Manager (`CraftingManager.gd`)

Verrà creato un nuovo Singleton `CraftingManager.gd` per gestire tutta la logica di crafting.

### 3.1. Responsabilità Principali
- **Caricamento Ricette:** Caricare e validare `recipes.json` all'avvio tramite `DataManager`.
- **Verifica Disponibilità:** Fornire funzioni per verificare quali ricette il giocatore può creare. `can_craft(recipe_id)` controllerà materiali, abilità e vicinanza a una workstation.
- **Esecuzione Crafting:** Gestire il processo di crafting, che sarà un'operazione atomica:
  - Consumare materiali dall'inventario (tramite `PlayerManager.apply_item_transaction`).
  - Aggiungere l'oggetto creato all'inventario (tramite `PlayerManager.apply_item_transaction`).
  - Assegnare punti esperienza.
- **Comunicazione:** Emettere segnali per notificare l'UI e altri sistemi.

### 3.2. Segnali Emessi
- `crafting_success(item_id, quantity)`
- `crafting_failed(reason_string)`

## 4. Interazione con i Sistemi Esistenti

- **PlayerManager:** `CraftingManager` interrogherà `PlayerManager` per l'inventario e le abilità. Userà la sua funzione `apply_item_transaction` per garantire la gestione atomica degli oggetti.
- **DataManager:** `CraftingManager` non caricherà file direttamente, ma richiederà le ricette a `DataManager`, che gestirà il caricamento e il caching.
- **GameUI:** L'interfaccia di crafting ascolterà i segnali di `CraftingManager` e interagirà con esso per mostrare le ricette e avviare il processo.
- **TimeManager:** Azioni di crafting complesse potrebbero richiedere tempo, consumando ore di gioco tramite `TimeManager`.

## 5. Interfaccia Utente (UI)

Verrà creata una nuova scena `CraftingPanel.tscn` che sarà un pannello all'interno della `GameUI`.

### 5.1. Flusso Utente
1. Il giocatore apre il pannello di crafting da un menu principale.
2. L'UI richiede a `CraftingManager` la lista di tutte le ricette e le mostra, divise per categoria.
3. Le ricette che il giocatore può creare sono evidenziate (`can_craft` viene chiamato per ogni ricetta).
4. Selezionando una ricetta, l'UI mostra i materiali richiesti (evidenziando quelli mancanti), l'oggetto in uscita e i requisiti.
5. Un pulsante "Crea" avvia il processo, chiamando la funzione `craft(recipe_id)` su `CraftingManager`.
6. L'UI mostra un feedback visivo (es. un messaggio nel log) basato sul segnale (`crafting_success` o `crafting_failed`) ricevuto da `CraftingManager`.
