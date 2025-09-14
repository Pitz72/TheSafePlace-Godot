# Analisi delle Criticità - The Safe Place v0.4.1

**A cura di:** Jules, Direttore Tecnico
**Data:** 2025-09-13

## Introduzione

Questo documento presenta un'analisi approfondita dello stato attuale del progetto "The Safe Place", con l'obiettivo di identificare le criticità più gravi a livello di documentazione, architettura e codice. L'analisi è stata condotta seguendo il piano approvato in data 2025-09-13.

---

## **Criticità 1: Incoerenza e Obsolescenza della Documentazione (Gravità: BLOCCANTE)**

La criticità più grave e urgente riscontrata è la profonda discrepanza tra le diverse fonti di documentazione del progetto. Questa situazione viola i principi fondamentali stabiliti nel "Patto di Sviluppo" e nelle "Regole di Sviluppo Fondamentali", in particolare il principio della **"Documentazione come Unica Fonte di Verità"**.

### 1.1. Conflitto di Versioning

Esistono almeno tre stati di versione contraddittori documentati nel repository:

*   **Versione `v0.4.1`**: Dichiarata nel titolo del file `README.md`.
*   **Versione `v0.4.0`**: Dichiarata nel contenuto del `README.md` e nell'indice della documentazione `Progetto/00_INDICE_DOCUMENTAZIONE_PROGETTO.md`. Questa sembra essere la versione di riferimento per la documentazione tecnica più recente.
*   **Versione `v0.2.1`**: Dichiarata nel file `docs/01_PRE_PRODUZIONE/00_REGOLE DI SVILUPPO FONDAMENTALI.TXT`. Questa documentazione risulta gravemente obsoleta.

### 1.2. Contraddizioni Strutturali

*   Il `PATTO_LLM_OPERATORE.md` stabilisce che la cartella `Progetto/` (precedentemente `10_DOCUMENTAZIONE`) è la **fonte di verità primaria**.
*   Tuttavia, il `README.md` principale indirizza gli utenti alla cartella `docs/` per la "documentazione completa", che è la fonte di informazione più obsoleta.

### 1.3. Impatto

Questa incoerenza ha un impatto bloccante sullo sviluppo:

*   **Impossibilità di Onboarding:** Un nuovo sviluppatore (umano o IA) non ha un punto di partenza affidabile per comprendere lo stato del progetto.
*   **Rischio di Regressione:** Lavorare basandosi sulla documentazione sbagliata porterebbe inevitabilmente a implementare funzionalità obsolete o a rompere l'architettura corrente.
*   **Sfiducia nel Sistema:** Mina la fiducia in *tutta* la documentazione, richiedendo una verifica incrociata costante tra codice e ogni documento.

### 1.4. Raccomandazione Iniziale

È imperativo unificare la documentazione. Si raccomanda di:
1.  **Deprecare ufficialmente la cartella `docs/`**, spostando il suo contenuto in un archivio (`ARCHIVIO/docs_obsoleti/`) per preservarne lo storico.
2.  **Eleggere la cartella `Progetto/` come unica fonte di verità**, aggiornando il `README.md` per riflettere questo.
3.  **Allineare la versione** in tutti i documenti (`v0.4.1` o la versione effettiva corrente) per garantire coerenza.

---

## **Criticità 2: Architettura Reale vs. Architettura Documentata (Gravità: ALTA)**

L'analisi del codice sorgente ha rivelato una profonda e pericolosa divergenza tra l'architettura implementata e quella descritta nella documentazione "fonte di verità" (v0.4.x). Il codice non è semplicemente una versione leggermente diversa, ma in molti casi segue paradigmi più vecchi e viola direttamente i principi stabiliti.

### 2.1. Duplicazione della Logica di Core Gameplay

La criticità più allarmante è la presenza di implementazioni multiple e conflittuali della stessa logica di gioco.

*   **Implementazione Doppia dello Skill Check:**
    *   **`PlayerManager.gd` (v0.1.2)** contiene una funzione `skill_check` completa.
    *   **`SkillCheckManager.gd` (v0.4.0)** contiene una funzione quasi identica, `perform_check`.
    *   **Impatto:** Questa ridondanza è un incubo per la manutenzione. Un bug risolto in un'implementazione persisterà nell'altra. Qualsiasi modifica al bilanciamento del gioco deve essere applicata in due posti diversi, aumentando il rischio di errori.

### 2.2. Violazione Sistematica del Principio di Disaccoppiamento

L'architettura documentata si basa sulla comunicazione asincrona tramite segnali per minimizzare le dipendenze. Il codice viola sistematicamente questo principio.

*   **Accesso Diretto ai Nodi:** Manager recenti come `EventManager` e `SkillCheckManager` usano `get_node("/root/...")` e chiamate dirette (`PlayerManager.get_stat(...)`) per accedere ad altri manager.
*   **Impatto:** Questo crea dipendenze forti (hard dependencies) che rendono il codice fragile. Se la struttura della scena o il nome di un manager cambia, il codice si rompe. Rende inoltre quasi impossibile il testing unitario dei singoli manager.

### 2.3. Documentazione API Inaffidabile

L'API documentata in `03_SINGLETON_MANAGERS.md` non riflette lo stato reale del codice.

*   **Funzioni Mancanti:** Decine di funzioni pubbliche implementate nei manager (`use_item`, `equip_item`, `get_save_data` in `PlayerManager`) non sono documentate. Interi sistemi (sopravvivenza, progressione) non hanno un'API documentata.
*   **Funzioni Diverse:** Funzioni documentate hanno nomi o parametri diversi nel codice (`spend_stat_point` vs `improve_stat`).
*   **Impatto:** La documentazione è inutile come riferimento per lo sviluppo. Obbliga a leggere l'intero codice sorgente di un manager per capirne l'utilizzo, annullando lo scopo della documentazione stessa.

### 2.4. Debito Tecnico Evidente

Il codice è un mosaico di standard diversi, con componenti legacy che non sono mai stati aggiornati.

*   **Logging Incoerente:** I manager più vecchi (`DataManager`, `PlayerManager`) usano `print()`, ignorando l'utility di logging centralizzata (`TSPLogger`) usata altrove.
*   **Dati Hardcoded:** Dati che dovrebbero essere in file JSON (es. oggetti iniziali) sono hardcodati direttamente nel codice (`PlayerManager.gd`).
*   **Logica di Compatibilità:** `EventManager.gd` contiene complessa logica di "normalizzazione" per supportare formati di dati JSON sia vecchi che nuovi, invece di eseguire una migrazione una tantum dei dati.
*   **Impatto:** Questo debito tecnico rende il codice più difficile da capire, manutenere e debuggare. Aumenta la complessità e il rischio di introdurre nuovi bug.

---

## **Criticità 3: Qualità del Codice e Debito Tecnico Strutturale (Gravità: ALTA)**

Oltre alle discrepanze con la documentazione, il codice stesso presenta gravi problemi strutturali e di qualità che rappresentano un rischio per la stabilità e la manutenibilità futura del progetto.

### 3.1. Manager Monolitici ("God Objects")

Il `PlayerManager.gd` è un chiaro esempio di "God Object". Ha assorbito responsabilità che non gli competono, diventando un monolite che gestisce: stato del giocatore, inventario, equipaggiamento, progressione, applicazione di effetti, applicazione di penalità di sopravvivenza e persino una logica di skill check duplicata.

*   **Impatto:**
    *   **Alta Complessità:** Il file è enorme e difficile da navigare e comprendere.
    *   **Bassa Coesione:** Le sue responsabilità sono troppo vaste e non correlate.
    *   **Alto Accoppiamento:** Moltissimi altri sistemi dipendono da esso, rendendo ogni sua modifica rischiosa.

### 3.2. Logica di Compatibilità Invece di Migrazione Dati

L'`EventManager.gd` contiene una grande quantità di codice di "normalizzazione" il cui unico scopo è supportare formati di dati JSON sia vecchi che nuovi.

*   **Impatto:**
    *   **Fragilità:** Questo strato di compatibilità è complesso e soggetto a errori. Un nuovo formato di dati legacy non previsto potrebbe rompere il sistema.
    *   **Performance:** Eseguire questa logica di conversione a ogni avvio del gioco è inefficiente.
    *   **Manutenibilità:** Rende la comprensione del processo di caricamento degli eventi inutilmente difficile. La soluzione corretta sarebbe stata scrivere uno script di migrazione una tantum per aggiornare tutti i file JSON al nuovo formato.

### 3.3. Dati di Contenuto Hardcodati

Il file `PlayerManager.gd` contiene una lista di oggetti di partenza hardcodata nella funzione `_add_starting_items`.

*   **Impatto:**
    *   **Violazione del Principio Data-Driven:** Contraddice il principio fondamentale del progetto di separare logica e dati.
    *   **Inflessibilità:** Per cambiare gli oggetti di partenza è necessario modificare il codice sorgente, invece di un semplice file di configurazione JSON. Questo impedisce un bilanciamento rapido e iterativo del gioco.

### 3.4. Gestione Errori Incompleta

Nonostante la presenza di alcuni controlli, la gestione degli errori è incompleta. Ad esempio, in `EventManager`, se `PlayerManager` o `DataManager` non vengono trovati, il codice stampa un errore ma non impedisce al gioco di continuare, rischiando crash successivi quando altre funzioni tenteranno di accedere ai manager mancanti.

*   **Impatto:** Il gioco può entrare in uno stato instabile e imprevedibile invece di fallire in modo controllato e prevedibile.

---

## **4. Sintesi e Raccomandazioni Strategiche**

L'analisi ha portato alla luce una serie di criticità interconnesse che, se non affrontate, rischiano di compromettere la stabilità, la manutenibilità e lo sviluppo futuro del progetto "The Safe Place".

### 4.1. Diagnosi Complessiva: "Sviluppo Stratificato"

Il problema fondamentale non è un singolo bug o un errore di progettazione, ma il risultato di uno "sviluppo stratificato". Il progetto è cresciuto per strati successivi, dove nuove idee e standard architetturali sono stati aggiunti senza mai integrare o refattorizzare le fondamenta più vecchie. Questo ha creato un sistema a due velocità:
*   Una **"vecchia guardia"** di codice (`DataManager`, `PlayerManager`) che è funzionale ma monolitica, obsoleta e non conforme agli standard recenti.
*   Una **"nuova guardia"** di codice (`SkillCheckManager`, `TSPLogger`) che è moderna e specializzata, ma che è stata costretta a integrarsi in modo "sporco" con la vecchia guardia, violando i propri principi (es. accesso diretto a `PlayerManager`).

### 4.2. Il Rischio Imminente: Stallo Tecnico

Il progetto si sta avvicinando a uno **stallo tecnico**. L'elevato debito tecnico e la complessità rendono ogni nuova funzionalità difficile e rischiosa da implementare. Il sistema di combattimento, prossimo obiettivo della roadmap, sarebbe quasi impossibile da implementare in modo pulito sull'architettura attuale senza aggravarne ulteriormente i problemi.

### 4.3. Raccomandazioni Strategiche: Il "Grande Refactoring"

Si raccomanda di fermare temporaneamente lo sviluppo di nuove funzionalità e di intraprendere un "Grande Refactoring" mirato a risanare il debito tecnico. Questo non è un "nice to have", ma una necessità strategica per la sopravvivenza del progetto.

**Piano di Refactoring Proposto (ad alto livello):**

1.  **Fase 1: Unificazione della Documentazione (Priorità Massima)**
    *   Deprecare ufficialmente la cartella `docs/`.
    *   Eleggere `Progetto/` come unica fonte di verità e aggiornare il `README.md`.
    *   Verificare e allineare la documentazione v0.4.x con il piano di refactoring.

2.  **Fase 2: Risoluzione della Duplicazione della Logica**
    *   **Rimuovere** l'implementazione di `skill_check` dal `PlayerManager`.
    *   Rendere lo `SkillCheckManager` l'unica fonte di verità per questa logica. Modificarlo affinché non acceda più direttamente al `PlayerManager`, ma riceva i dati necessari come parametri.

3.  **Fase 3: Disaccoppiamento dei Manager**
    *   Rimuovere tutte le chiamate `get_node` e gli accessi diretti tra i manager.
    *   Implementare una comunicazione basata esclusivamente su segnali, come previsto dall'architettura. Un manager che ha bisogno di dati dovrebbe richiederli tramite un segnale, e il provider di dati dovrebbe rispondere con un altro segnale.

4.  **Fase 4: Refactoring dei Manager Monolitici**
    *   Suddividere il `PlayerManager` in manager più piccoli e specializzati (es. `InventoryManager`, `ProgressionManager`, `StatusManager`).
    *   Refattorizzare il `DataManager` e l'`EventManager` per rimuovere la logica di compatibilità, migrando i dati JSON a un formato unico e standardizzato.

5.  **Fase 5: Adozione degli Standard Comuni**
    *   Sostituire tutte le chiamate `print()` con l'utility `TSPLogger` standardizzata.
    *   Esternalizzare tutti i dati hardcodati (come gli oggetti iniziali) in file di configurazione JSON.

### Conclusione Finale
Questo refactoring richiederà un investimento di tempo significativo, ma è l'unico modo per garantire che "The Safe Place" possa avere un futuro sostenibile, scalabile e divertente da sviluppare. Continuare a costruire sull'attuale base instabile porterà solo a maggiori frustrazioni e a un inevitabile fallimento tecnico.
