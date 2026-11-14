# Diario di avanzamento — Onda 7 — Piattaforma, plugin, qualità

**Data:** 2026-11-14
**Stato:** in corso (P7.1 completato)
**Ondata precedente:** `wave-06.5-menu-platform.md`
**Documento di settore:** [`../07-platform-plugins-quality.md`](../07-platform-plugins-quality.md)
**Checklist:** [`../CHECKLIST.md`](../CHECKLIST.md)

---

## 0. Punto di ripresa

**Stato:** branch `main`, working tree pulito dopo il commit di P7.1, tutto
pushato su `origin/main`.

**Baseline aggiornata:** `testthat::test_local()` → **3020 pass, 0 fail,
16 skip** (+88 test rispetto a 2932).

**Prossimo task:** **P7.2 — Save/load progetto** in `R/project.R`.

**Da leggere, in quest'ordine:**

1. questo diario (sezioni 1–5);
2. [`../07-platform-plugins-quality.md`](../07-platform-plugins-quality.md),
   sezioni 2.2–2.4;
3. [`../CHECKLIST.md`](../CHECKLIST.md), Onda 7.

---

## 1. P7.1 — Schema progetto

### Obiettivo

Definire il formato `.rcmdrproj` e il validatore, senza ancora leggere o
scrivere file. Il formato è YAML versionato; la versione dello schema è
obbligatoria.

### Implementazione

`R/project.R` contiene:

- **Costanti**: `project_schema_version()` = 1, `project_extension()` =
  `"rcmdrproj"`, `project_timestamp()`, `project_package_version()`.
- **Costruttori di voce**: `project_dataset()`, `project_model_entry()`,
  `project_document_entry()`, `project_plot_entry()`, `project_options()`.
- **Progetto vuoto**: `project_new(path = NULL, title = NULL)`.
- **Validazione pura**: `project_validate(project, strict = TRUE)` restituisce
  `ok`, `problems`, `warnings`. Non ripara mai il progetto.
- **Stop helper**: `project_validate_or_stop()`.
- **Normalizzazione**: `project_normalize()` riempie le collezioni opzionali,
  recupera i nomi dalle liste nominate e applica i default delle opzioni.
- **Migrazione**: `project_migrate()` con passi in `project_migrations()`;
  oggi il passo `0 → 1` copre le bozze pre-schema (`data`/`data_sets` →
  `datasets`, `active_dataset` → flag `active`, `docs` → `documents`,
  `figures` → `plots`, `favourites` → `favorites`). Una versione futura viene
  rifiutata, mai riscritta.
- **Path**: `project_path_absolute()`, `project_path_escapes()`,
  `project_normalize_path()`, `project_relative_path()`,
  `project_resolve_path()`, `project_path_inside()`,
  `project_assets_dir()`.
- **Payload**: `project_payload()` esclude `path`, che è metadato di runtime e
  non va serializzato.

### Struttura dello schema

Campi top-level: `version`, `created`, `modified`, `package_version`, `title`,
`datasets`, `models`, `active_model`, `documents`, `active_document`, `plots`,
`presets`, `favorites`, `options`, `history`. In memoria è ammesso anche
`path`.

Regole validate:

- versione intera positiva, non futura;
- timestamp ISO-8601 UTC;
- nomi di dataset e modelli unici;
- ogni dataset ha un `source`; al massimo un dataset attivo;
- `active_model` e `active_document` devono esistere;
- mode documento in `r`, `rmd`, `rnw`; id senza separatori di path;
- al massimo un documento attivo;
- id plot unici; `file` relativo, senza `..`, idealmente sotto `assets/`;
- preset come albero dialogo → nome → lista;
- preferiti come vettore di command id non vuoti;
- `ui_mode` in `studio`/`classic`, tema tra `system`, `light`, `dark`,
  `contrast`, lingua in `available_languages()`;
- `history$include` logico.

Campi sconosciuti: warning, non errore, per non rompere file scritti da una
versione più recente dello stesso schema.

### Test

`tests/testthat/test-project.R`: 88 asserzioni su schema, costruttori,
duplicati, riferimenti attivi, documenti, plot, preferiti, opzioni, preset,
migrazione, normalizzazione e path helper.

---

## 2. Decisioni

- **Il progetto è un elenco puro**: nessun oggetto Shiny, nessuna dipendenza da
  una sessione viva. Save/load potranno testarlo senza browser.
- **`path` non è schema**: è metadato di runtime; `project_payload()` lo
  toglie prima della serializzazione.
- **La validazione non ripara**: `project_normalize()` e `project_migrate()`
  trasformano, `project_validate()` solo giudica. È il modo più semplice per
  testare i file corrotti.
- **Migrazione esplicita per versione**: `project_migrations()` è una mappa
  versione → funzione; aggiungere lo schema 2 significherà aggiungere una voce,
  non modificare `project_migrate()`.
- **Path relativi, mai `..`**: `project_path_escapes()` e
  `project_path_inside()` impediscono a un progetto di uscire dalla propria
  cartella. `project_relative_path()` restituisce il path assoluto se il file
  è fuori, invece di inventare una catena di `..`.
- **Nessun path assoluto nei plot**: i plot vivono in `assets/`; un file fuori
  da `assets/` è un warning, un path assoluto o con `..` è un errore.

---

## 3. File

### Creati

- `R/project.R`
- `tests/testthat/test-project.R`
- `docs/upgrades/diary/wave-07-platform.md` (questo diario)

### Modificati

- `docs/upgrades/CHECKLIST.md` — P7.1 chiuso, changelog Onda 7.

---

## 4. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Test P7.1 | `testthat::test_local(filter = "project")` | **88 pass** |
| Suite completa | `testthat::test_local()` | **3020 pass, 0 fail, 16 skip** |

---

## 5. Prossimi passi

1. **P7.2 — Save/load**: `project_save(state, path)`, `project_open(path)`,
   scrittura atomica, YAML con `yaml`, `project_payload()`, validazione e
   migrazione in apertura.
2. **P7.3 — Recent projects**: elenco persistito e integrazione nella Home.
3. **P7.4 — Autosave/recovery**: `.rcmdrproj.autosave`, scrittura atomica,
   prompt di recupero.
4. **P7.5 — Export bundle**: cartella `assets/`, dati inclusi, manifest.
5. Attivare il feature flag `project` solo quando P7.2 è utilizzabile dalla
   UI.

**Nota:** il flag `project` in `R/features.R` resta `FALSE`; la Home continua a
mostrare il messaggio “non disponibile” finché save/load non è pronto.

---

## 6. Comandi per riprendere

```bash
cd /home/vigliafg/Documenti/GitHub/rcmdr-studio
git status
Rscript -e 'testthat::test_local()'
Rscript -e 'testthat::test_local(filter = "project")'
```
