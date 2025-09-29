# 📚 INDICE GLOBALE DOCUMENTAZIONE - THE SAFE PLACE v0.9.7.3

## 🎯 **NAVIGAZIONE RAPIDA**

Questo è l'indice unificato di tutta la documentazione del progetto "The Safe Place". La documentazione è organizzata in due sezioni principali:

- **📁 `/Progetto`**: Documentazione tecnica sistematica (LLM-friendly)
- **📁 `/development_history`**: Cronologia storica e materiali di sviluppo

---

## 🏗️ **DOCUMENTAZIONE TECNICA PRINCIPALE** (`/Progetto`)

### **📖 ARCHITETTURA E OVERVIEW (01-03)**
| File | Descrizione | Stato |
|------|-------------|-------|
| [00_INDICE_DOCUMENTAZIONE_PROGETTO.md](Progetto/00_INDICE_DOCUMENTAZIONE_PROGETTO.md) | Indice specifico documentazione tecnica | ✅ |
| [01_ARCHITETTURA_GENERALE.md](Progetto/01_ARCHITETTURA_GENERALE.md) | Visione d'insieme sistema e componenti | ✅ |
| [02_GODOT_ENGINE_SPECIFICS.md](Progetto/02_GODOT_ENGINE_SPECIFICS.md) | Specifiche tecniche Godot 4.x | ✅ |
| [03_SINGLETON_MANAGERS.md](Progetto/03_SINGLETON_MANAGERS.md) | **Sistema manager consolidato (v0.9.7.3)** | ✅ |

### **🗄️ DATABASE E DATI (04-07)**
| File | Descrizione | Stato |
|------|-------------|-------|
| [04_DATABASE_OVERVIEW.md](Progetto/04_DATABASE_OVERVIEW.md) | Panoramica database JSON | ✅ |
| [05_ITEMS_DATABASE.md](Progetto/05_ITEMS_DATABASE.md) | Sistema oggetti completo | ✅ |
| [06_EVENTS_DATABASE.md](Progetto/06_EVENTS_DATABASE.md) | Sistema eventi e skill check | ✅ |
| [07_SYSTEM_DATA.md](Progetto/07_SYSTEM_DATA.md) | Configurazioni sistema | ✅ |

### **⚙️ SISTEMI CORE (08-14)**
| File | Descrizione | Stato |
|------|-------------|-------|
| [08_PLAYER_SYSTEM.md](Progetto/08_PLAYER_SYSTEM.md) | Gestione giocatore completa | ✅ |
| [09_WORLD_SYSTEM.md](Progetto/09_WORLD_SYSTEM.md) | Sistema mondo e movimento | ✅ |
| [10_EVENT_SYSTEM.md](Progetto/10_EVENT_SYSTEM.md) | Sistema eventi dinamici | ✅ |
| [11_UI_SYSTEM.md](Progetto/11_UI_SYSTEM.md) | Sistema interfaccia utente | ✅ |
| [12_TIME_SYSTEM.md](Progetto/12_TIME_SYSTEM.md) | Gestione tempo e cicli | ✅ |
| [13_THEME_SYSTEM.md](Progetto/13_THEME_SYSTEM.md) | Temi grafici e CRT | ✅ |
| [14_INPUT_SYSTEM.md](Progetto/14_INPUT_SYSTEM.md) | Gestione input e hotkey | ✅ |

### **🔧 ANALISI TECNICA (15-26)**
| File | Descrizione | Stato |
|------|-------------|-------|
| [15_CODE_PATTERNS.md](Progetto/15_CODE_PATTERNS.md) | Pattern architetturali | ✅ |
| [16_SIGNAL_SYSTEM.md](Progetto/16_SIGNAL_SYSTEM.md) | Sistema segnali Godot | ✅ |
| [17_PERFORMANCE_CONSIDERATIONS.md](Progetto/17_PERFORMANCE_CONSIDERATIONS.md) | Ottimizzazioni performance | ✅ |
| [18_NARRATIVE_CONTENT.md](Progetto/18_NARRATIVE_CONTENT.md) | Contenuti narrativi | ✅ |
| [19_GAME_BALANCE.md](Progetto/19_GAME_BALANCE.md) | Bilanciamento gameplay | ✅ |
| [20_LOCALIZATION.md](Progetto/20_LOCALIZATION.md) | Sistema localizzazione | ✅ |
| [21_DEVELOPMENT_WORKFLOW.md](Progetto/21_DEVELOPMENT_WORKFLOW.md) | Workflow sviluppo | ✅ |
| [22_TESTING_FRAMEWORK.md](Progetto/22_TESTING_FRAMEWORK.md) | Framework testing | ✅ |
| [23_VERSIONING_SYSTEM.md](Progetto/23_VERSIONING_SYSTEM.md) | Sistema versioning | ✅ |
| [24_API_REFERENCE.md](Progetto/24_API_REFERENCE.md) | Riferimenti API | ✅ |
| [25_TROUBLESHOOTING.md](Progetto/25_TROUBLESHOOTING.md) | Risoluzione problemi | ✅ |
| [26_EXTENSION_GUIDELINES.md](Progetto/26_EXTENSION_GUIDELINES.md) | Linee guida estensioni | ✅ |

### **🎮 SISTEMI AVANZATI (27-31)**
| File | Descrizione | Stato |
|------|-------------|-------|
| [27_COMBAT_SYSTEM.md](Progetto/27_COMBAT_SYSTEM.md) | Sistema combattimento | ✅ |
| [28_CRAFTING_SYSTEM.md](Progetto/28_CRAFTING_SYSTEM.md) | Sistema crafting | ✅ |
| [29_NARRATIVE_SYSTEM.md](Progetto/29_NARRATIVE_SYSTEM.md) | Sistema narrativo | ✅ |
| [30_QUEST_SYSTEM.md](Progetto/30_QUEST_SYSTEM.md) | Sistema missioni | ✅ |
| [31_SAVE_LOAD_SYSTEM.md](Progetto/31_SAVE_LOAD_SYSTEM.md) | Sistema salvataggio | ✅ |

### **📋 GESTIONE PROGETTO (32-35)**
| File | Descrizione | Stato |
|------|-------------|-------|
| [32_DEVELOPMENT_HISTORY.md](Progetto/32_DEVELOPMENT_HISTORY.md) | Collegamento cronologia | ✅ |
| [33_DEPLOYMENT_GUIDE.md](Progetto/33_DEPLOYMENT_GUIDE.md) | Guida deployment | ✅ |
| [34_MAINTENANCE_GUIDE.md](Progetto/34_MAINTENANCE_GUIDE.md) | Guida manutenzione | ✅ |
| [35_API_REFERENCE.md](Progetto/35_API_REFERENCE.md) | Documentazione API completa | ✅ |

### **🎨 RISORSE GRAFICHE**
| File | Descrizione | Stato |
|------|-------------|-------|
| [35_CRT_ULTRA_REALISTIC_SHADER.md](Progetto/35_CRT_ULTRA_REALISTIC_SHADER.md) | Shader CRT avanzato | ✅ |

---

## 📊 **DIAGRAMMI ARCHITETTURALI** (`/diagrams`)

### **Visualizzazioni Sistema**
| File | Descrizione | Utilizzo |
|------|-------------|----------|
| [architecture_overview.svg](diagrams/architecture_overview.svg) | Panoramica architetturale completa | Onboarding, revisioni architetturali |
| [manager_dependencies.svg](diagrams/manager_dependencies.svg) | Mappa dipendenze tra Manager | Debug inizializzazione, refactoring |
| [game_flow.svg](diagrams/game_flow.svg) | Diagramma flusso di gioco | Design feature, debug stati |
| [data_flow.svg](diagrams/data_flow.svg) | Flusso dati nel sistema | Ottimizzazione performance, debug sync |
| [README.md](diagrams/README.md) | Guida utilizzo diagrammi | Documentazione diagrammi |

### **Benefici Diagrammi**
- **🎯 Comprensione Rapida**: Visualizzazione immediata delle relazioni
- **🔧 Debug Efficace**: Tracciamento dipendenze e flussi
- **📈 Ottimizzazione**: Identificazione bottleneck e punti critici
- **👥 Onboarding**: Accelerazione comprensione per nuovi sviluppatori

---

## 📚 **CRONOLOGIA SVILUPPO** (`/development_history`)

### **📋 Pre-Produzione**
- **design/**: Documenti game design originali
- **pianificazione/**: Roadmap e pianificazione iniziale
- [PATTO_LLM_OPERATORE.md](development_history/01_PRE_PRODUZIONE/PATTO_LLM_OPERATORE.md): Accordi sviluppo AI
- [00_REGOLE DI SVILUPPO FONDAMENTALI.TXT](development_history/01_PRE_PRODUZIONE/00_REGOLE%20DI%20SVILUPPO%20FONDAMENTALI.TXT): Regole base

### **🔧 Produzione**
- **logs_sviluppo/**: Log dettagliati per versione
  - `DEV_LOG_*.md`: Documentazione milestone
  - `COMMIT_GITHUB_*.txt`: Cronologia commit
- **test_e_verifiche/**: Test regressione e verifiche
  - `ANTI_REGRESSION_TESTS_*.md`: Test per versione
  - `SKILL_CHECK_TEST_RESULTS.md`: Risultati test

### **🔬 Materiale Tecnico**
- **analisi_reverse_engineering/**: Analisi tecniche storiche
- **architettura/**: Documentazione architetturale legacy

### **🎮 Contenuti di Gioco**
- Contenuti narrativi e gameplay storici

---

## 👥 **DOCUMENTAZIONE UTENTE FINALE** (`/user_docs`)

### **Guide per Giocatori**
| File | Descrizione | Stato |
|------|-------------|-------|
| [README.md](user_docs/README.md) | Panoramica documentazione utente | ✅ |
| [USER_MANUAL.md](user_docs/USER_MANUAL.md) | Manuale utente completo | ✅ |
| [INSTALLATION_GUIDE.md](user_docs/INSTALLATION_GUIDE.md) | Guida installazione e configurazione | ✅ |
| [TROUBLESHOOTING.md](user_docs/TROUBLESHOOTING.md) | Risoluzione problemi comuni | ✅ |
| [CHANGELOG_USER.md](user_docs/CHANGELOG_USER.md) | Changelog user-friendly | ✅ |

### **Caratteristiche Documentazione Utente**
- **🎮 Linguaggio Semplice**: Scritto per giocatori, non sviluppatori
- **📖 Guide Pratiche**: Istruzioni passo-passo per ogni aspetto
- **🔧 Risoluzione Problemi**: Soluzioni ai problemi più comuni
- **📋 Aggiornamenti**: Novità spiegate in modo comprensibile
- **🎯 Organizzazione Logica**: Struttura pensata per l'utente finale

---

## 📄 **DOCUMENTAZIONE ROOT**

### **File Principali**
| File | Descrizione | Stato |
|------|-------------|-------|
| [README.md](README.md) | Introduzione progetto | ✅ |
| [CHANGELOG.md](CHANGELOG.md) | Registro modifiche v0.9.0 | ✅ |
| [CHANGELOG_v0.9.5.md](CHANGELOG_v0.9.5.md) | Registro modifiche v0.9.5 | ✅ |
| [CHANGELOG_v0.9.7.3.md](CHANGELOG_v0.9.7.3.md) | **Registro consolidamento manager** | ✅ |
| [ANTI_REGRESSION_v0.9.7.3.md](ANTI_REGRESSION_v0.9.7.3.md) | **Test anti-regressione consolidamento** | ✅ |
| **DOCUMENTATION_INDEX.md** | **Questo indice globale** | ✅ |

### **File di Configurazione**
- [project.godot](project.godot): Configurazione progetto Godot (v0.9.7.3)
- [.gitignore](.gitignore): Configurazione Git
- [.gdignore](.gdignore): Configurazione Godot ignore

---

## 🎯 **GUIDE RAPIDE PER RUOLO**

### **👨‍💻 Per Sviluppatori**
1. **Inizia qui**: [01_ARCHITETTURA_GENERALE.md](Progetto/01_ARCHITETTURA_GENERALE.md)
2. **Singleton Managers**: [03_SINGLETON_MANAGERS.md](Progetto/03_SINGLETON_MANAGERS.md) *(Aggiornato v0.9.7.3)*
3. **Pattern di codice**: [15_CODE_PATTERNS.md](Progetto/15_CODE_PATTERNS.md)
4. **API Reference**: [35_API_REFERENCE.md](Progetto/35_API_REFERENCE.md)
5. **Diagrammi**: [architecture_overview.svg](diagrams/architecture_overview.svg)

### **🤖 Per LLM/AI**
1. **Indice tecnico**: [00_INDICE_DOCUMENTAZIONE_PROGETTO.md](Progetto/00_INDICE_DOCUMENTAZIONE_PROGETTO.md)
2. **Architettura**: [01_ARCHITETTURA_GENERALE.md](Progetto/01_ARCHITETTURA_GENERALE.md)
3. **Database**: [04_DATABASE_OVERVIEW.md](Progetto/04_DATABASE_OVERVIEW.md)
4. **Sistemi core**: Documenti 08-14
5. **API completa**: [35_API_REFERENCE.md](Progetto/35_API_REFERENCE.md)
6. **Dipendenze**: [manager_dependencies.svg](diagrams/manager_dependencies.svg)
7. **Consolidamento**: [CHANGELOG_v0.9.7.3.md](CHANGELOG_v0.9.7.3.md) + [ANTI_REGRESSION_v0.9.7.3.md](ANTI_REGRESSION_v0.9.7.3.md)

### **🎮 Per Game Designer**
1. **Contenuti narrativi**: [18_NARRATIVE_CONTENT.md](Progetto/18_NARRATIVE_CONTENT.md)
2. **Sistema eventi**: [10_EVENT_SYSTEM.md](Progetto/10_EVENT_SYSTEM.md)
3. **Bilanciamento**: [19_GAME_BALANCE.md](Progetto/19_GAME_BALANCE.md)
4. **Database eventi**: [06_EVENTS_DATABASE.md](Progetto/06_EVENTS_DATABASE.md)
5. **Flusso di gioco**: [game_flow.svg](diagrams/game_flow.svg)

### **🔧 Per DevOps**
1. **Deployment**: [33_DEPLOYMENT_GUIDE.md](Progetto/33_DEPLOYMENT_GUIDE.md)
2. **Manutenzione**: [34_MAINTENANCE_GUIDE.md](Progetto/34_MAINTENANCE_GUIDE.md)
3. **Performance**: [17_PERFORMANCE_CONSIDERATIONS.md](Progetto/17_PERFORMANCE_CONSIDERATIONS.md)
4. **Testing**: [22_TESTING_FRAMEWORK.md](Progetto/22_TESTING_FRAMEWORK.md)
5. **Flusso dati**: [data_flow.svg](diagrams/data_flow.svg)

---

## 📊 **STATISTICHE DOCUMENTAZIONE**

### **Copertura Documentale**
- **File totali**: 57 documenti (39 tecnici + 5 diagrammi + 5 utente finale + 8 versioning/protezione)
- **Copertura sistemi**: 100% (7/7 Manager Consolidati v0.9.7.3)
- **Copertura database**: 100% (15/15 database JSON)
- **Documentazione inline**: 95%+ coverage
- **Diagrammi architetturali**: 4 visualizzazioni complete
- **Documentazione utente**: 5 guide complete per giocatori
- **Sistema anti-regressione**: Attivo con checkpoint v0.9.7.3

### **Qualità Documentazione**
- **Standardizzazione**: Formato uniforme con emoji e sezioni
- **Navigabilità**: Cross-reference e indici strutturati
- **Aggiornamento**: Sincronizzato con codice v0.9.7.3
- **Accessibilità LLM**: Ottimizzato per AI comprehension
- **Consolidamento**: Architettura semplificata da 12 a 7 manager

---

## 🔄 **AGGIORNAMENTI E MANUTENZIONE**

### **Processo di Aggiornamento**
1. **Modifica codice**: Implementazione feature/fix
2. **Aggiornamento docs**: Sincronizzazione documentazione
3. **Verifica cross-reference**: Controllo collegamenti
4. **Update indici**: Aggiornamento questo file e indici specifici
5. **Test anti-regressione**: Verifica compatibilità (v0.9.7.3+)

### **Responsabilità**
- **Sviluppatori**: Aggiornamento documentazione tecnica
- **Project Manager**: Manutenzione indici e struttura
- **QA**: Verifica sincronizzazione docs-codice

---

## 📞 **SUPPORTO E CONTRIBUTI**

### **Per Domande**
- Consultare prima [25_TROUBLESHOOTING.md](Progetto/25_TROUBLESHOOTING.md)
- Verificare cronologia in `/development_history`
- Creare issue su GitHub per problemi non risolti

### **Per Contributi**
- Seguire [21_DEVELOPMENT_WORKFLOW.md](Progetto/21_DEVELOPMENT_WORKFLOW.md)
- Rispettare [26_EXTENSION_GUIDELINES.md](Progetto/26_EXTENSION_GUIDELINES.md)
- Aggiornare documentazione per ogni modifica

---

*Indice globale aggiornato per v0.9.7.3 - Manager Consolidation*

**🎯 NAVIGAZIONE RAPIDA:**
- 📁 [Documentazione Tecnica](Progetto/) - Sistema completo LLM-friendly
- 📚 [Cronologia Sviluppo](development_history/) - Storia e materiali legacy
- 📄 [README Progetto](README.md) - Introduzione generale