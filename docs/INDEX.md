# 📚 Indice della Documentazione - The Safe Place

Questa cartella contiene tutta la documentazione del progetto "The Safe Place", organizzata in modo logico e strutturato per facilitare la navigazione e la consultazione.

## 🗂️ Struttura della Documentazione

### 📋 01_PRE_PRODUZIONE
Contiene tutti i documenti creati prima e durante la fase di progettazione iniziale:

- **📁 design/**
  - `GAME_DESIGN.md` - Documento di game design principale
- **📁 pianificazione/**
  - `ROADMAP.md` - Roadmap di sviluppo aggiornata
  - `01 ROADMAP.txt` - Roadmap originale storica
- `PATTO_LLM_OPERATORE.md` - Accordi e regole per lo sviluppo con AI
- `00_REGOLE DI SVILUPPO FONDAMENTALI.TXT` - Regole base del progetto

### 🔧 02_PRODUZIONE
Documenti generati durante lo sviluppo attivo del progetto:

- **📁 logs_sviluppo/**
  - File `DEV_LOG_*.md` - Log dettagliati di ogni versione
  - File `COMMIT_GITHUB_*.txt` - Cronologia dei commit
  - `CHANGELOG.md` - Registro delle modifiche
  - `CORREZIONI_SISTEMA_EVENTI.md` - Correzioni specifiche
  - `NOTE_SESSIONE_PROSSIMA.md` - Note per sessioni future
  - Altri file di log e documentazione di sviluppo

- **📁 test_e_verifiche/**
  - `ANTI_REGRESSION_TESTS_*.md` - Test di regressione
  - `SKILL_CHECK_TEST_RESULTS.md` - Risultati test skill check
  - `TESTS.md` - Documentazione test generali
  - `VERIFICA_*.md` - Verifiche di milestone e sistemi

### 🔬 03_MATERIALE_TECNICO
Documentazione tecnica e analisi approfondite:

- **📁 analisi_reverse_engineering/**
  - `ANALISI_*.md` - Analisi dettagliate di sistemi specifici
  - `ARCHITETTURA_GENERALE.md` - Architettura generale del sistema
  - `CONTENUTI_DI_GIOCO.md` - Analisi contenuti
  - `ROADMAP_PORTING.md` - Piano di porting
  - **📁 02_CONTENUTI_DI_GIOCO/** - Sottocartelle con analisi specifiche

- **📁 architettura/**
  - (Riservata per futura documentazione architetturale)

### 🎮 04_CONTENUTI_DI_GIOCO
Tutti i contenuti narrativi e di gameplay:

- **📁 eventi/**
  - `01 pianure.md` - Eventi delle pianure
  - `02 foreste.md` - Eventi delle foreste
  - `03 villaggi.md` - Eventi dei villaggi
  - `04 città.md` - Eventi delle città
  - `05 fiumi.md` - Eventi dei fiumi
  - `06 generic.md` - Eventi generici
  - `roadmap-eventi-temp.md` - Roadmap temporanea eventi

- **📁 mappe/**
  - *Cartella riservata per future mappe di gioco*
  - *Nota: I file mappa principali sono nella root del progetto per compatibilità con Godot*

## 🧭 Come Navigare la Documentazione

### Per Sviluppatori Nuovi al Progetto:
1. Inizia con `01_PRE_PRODUZIONE/design/GAME_DESIGN.md`
2. Leggi `01_PRE_PRODUZIONE/PATTO_LLM_OPERATORE.md`
3. Consulta `01_PRE_PRODUZIONE/pianificazione/ROADMAP.md`

### Per Sviluppo e Debug:
1. Controlla `02_PRODUZIONE/logs_sviluppo/` per l'ultima versione
2. Usa `02_PRODUZIONE/test_e_verifiche/` per test e verifiche
3. Consulta `03_MATERIALE_TECNICO/analisi_reverse_engineering/` per dettagli tecnici

### Per Content Design:
1. Esplora `04_CONTENUTI_DI_GIOCO/eventi/` per eventi esistenti
2. Usa `04_CONTENUTI_DI_GIOCO/mappe/` per riferimenti geografici

## 📝 Note di Manutenzione

- Tutti i nuovi documenti devono essere inseriti nella cartella appropriata
- I log di sviluppo vanno sempre in `02_PRODUZIONE/logs_sviluppo/`
- Le analisi tecniche vanno in `03_MATERIALE_TECNICO/analisi_reverse_engineering/`
- I contenuti di gioco vanno in `04_CONTENUTI_DI_GIOCO/`

---
*Ultimo aggiornamento: Dicembre 2024*
*Versione progetto: v0.3.2 "The Importance of Choices"*