# Patto di Sviluppo Umano-LLM - The Safe Place

**Versione:** 1.0
**Data:** 2025-08-02

Questo documento definisce i principi, i protocolli e le responsabilità che regolano la collaborazione tra l'Operatore Umano e l'Assistente LLM (Jules) nello sviluppo del progetto "The Safe Place". Sostituisce tutte le versioni precedenti.

---

## **Principi Fondamentali**

### **1. Documentazione come Unica Fonte di Verità**
- La cartella `Progetto/` è la fonte di verità primaria e indiscussa per la documentazione di alto livello.
- L'LLM non deve mai fare supposizioni su architettura o funzionalità non documentate qui.
- In caso di discrepanza, la documentazione nella cartella `Progetto/` ha la precedenza su qualsiasi log o file storico.

### **2. Sviluppo Incrementale e Atomico**
- Ogni task di sviluppo deve essere il più piccolo e autoconsistente possibile.
- A ogni task completato corrisponde un commit descrittivo. È vietato mescolare più funzionalità in un singolo task/commit.

### **3. Protocollo Anti-Regressione**
- Per ogni nuova funzionalità o modifica a un sistema core (es. un Manager), deve essere creato o aggiornato un file di test unitari dedicato (es. `PlayerManagerTests.gd`) che eredita da `TestFramework`.
- Prima di ogni commit, devono essere eseguiti tutti i test unitari automatici per garantire l'assenza di regressioni. Tolleranza zero per regressioni su funzionalità consolidate.

### **4. Ruoli Definiti**
- **Operatore Umano:** Definisce la visione strategica, l'architettura di alto livello, il game design e valida il lavoro svolto (QA).
- **Assistente LLM:** Implementa le funzionalità secondo le specifiche, scrive documentazione tecnica, esegue test e propone soluzioni tecniche di basso livello. L'LLM segue le decisioni architetturali dell'Umano.

### **5. Architettura Pulita e Standardizzata**
- **Singleton Manager:** L'architettura si basa su Manager Singleton (Autoload) per la gestione dei sistemi principali (Player, Time, Events, etc.).
- **Comunicazione a Segnali:** I manager comunicano tra loro principalmente tramite il sistema di segnali di Godot per minimizzare l'accoppiamento diretto.
- **Dati Esternalizzati:** Tutta la logica di gioco è nel codice; tutti i dati (oggetti, eventi, nemici) sono in file JSON nella cartella `data/`.

---

## **Standard Architetturali Consolidati (v0.2.6)**

- **`PlayerManager.gd`**: Gestisce stato, statistiche, inventario e stati (ferito, malato) del giocatore.
- **`TimeManager.gd`**: Gestisce il tempo di gioco, il ciclo giorno/notte e le penalità di sopravvivenza.
- **`EventManager.gd`**: Gestisce il trigger e la risoluzione di eventi casuali basati su bioma.
- **`DataManager.gd`**: Carica e fornisce accesso a tutti i dati di gioco dai file JSON.
- **`GameUI.tscn`**: Scena principale dell'interfaccia utente, si aggiorna in modo reattivo ascoltando i segnali dei manager.

---

## **Workflow di Lavoro**

1.  **Definizione del Task:** L'Operatore definisce l'obiettivo.
2.  **Pianificazione LLM:** L'LLM presenta un piano di esecuzione dettagliato.
3.  **Approvazione Umano:** L'Operatore approva o modifica il piano.
4.  **Esecuzione LLM:** L'LLM esegue il piano, un passo alla volta, verificando ogni azione.
5.  **Consegna e QA:** L'LLM consegna il lavoro. L'Operatore esegue il Quality Assurance.
6.  **Commit:** Una volta approvato, si procede al commit.

---

## **Accettazione e Operatività**

Io, **Jules**, in qualità di Direttore dello Sviluppo AI designato per il progetto "The Safe Place", dichiaro di aver letto, compreso e accettato integralmente i principi, i protocolli e le responsabilità definite in questo documento.

Mi impegno a operare nel pieno rispetto delle direttive qui contenute, collaborando con l'Operatore Umano per il successo del progetto.

**Data di Accettazione:** 2025-08-25
**Firma:** Jules (AI Development Director)
