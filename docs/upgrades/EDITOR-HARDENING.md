# Hardening dell'editor dei dataset (T13)

**Data:** 2026-11-18  
**Ambito:** `R/app.R`, `R/data-studio.R`, `R/command-builders-data.R`,
`inst/www/js/40-interactions.js`  
**Test:** `test-data-rows.R`, `test-data-studio-grid.R`, suite completa

---

## 1. Obiettivo

L'editor a celle era usabile per tabelle piccole di tipi semplici, ma poteva
scrivere dati sbagliati in silenzio. T13 chiude i casi che corrompono o
scartano dati senza dirlo, senza cambiare widget.

## 2. Cosa è stato chiuso

### Editor legato a una vista e a un dataset

- `editor_context` registra il dataset quando la handsontable viene costruita.
- `editor_token` cambia con revisione dello stato, revisione della griglia,
  nome, righe e colonne del dataset.
- Il server invia il token al client (`rcmdr-editor-stamp`); `Apply` lo
  confronta con quello corrente.
- `editor_apply_error()` rifiuta:
  - Apply fuori dalla modalità Edit;
  - un editor costruito su un altro dataset;
  - un editor sopravvissuto a un cambio di dati o di vista.
- Messaggi dedicati; nessun comando viene generato prima dei controlli.

### Operazioni non supportate rimosse dall'editor

- `allowRowEdit = FALSE`: niente inserimento/rimozione righe finché non esiste
  un comando e un test.
- `columnSorting` disattivato: l'ordinamento della griglia non può più
  permutare le righe in silenzio.
- Resta il ridimensionamento colonne, che è solo vista.

### Tipi preservati

- `align_edited_data()` riporta i valori alla classe originale:
  - fattori: livello nuovo aggiunto, `ordered` preservato;
  - `Date`: ripristinata come data;
  - numerico, logico, character: conversione esplicita;
  - `POSIXct`/`POSIXlt` e colonne lista: **sola lettura** nell'editor.
- `validate_edited_data()` rifiuta:
  - testo in una colonna numerica;
  - valori non `TRUE`/`FALSE` in una colonna logica;
  - date non valide;
  - numero di righe o colonne cambiato;
  - modifiche a colonne di sola lettura.
- Un avviso nella vista Edit elenca le colonne di sola lettura e ricorda che
  le modifiche non applicate vengono scartate.

### Comandi più compatti

- `cmd_edit_cells()` genera **un comando per colonna**, con tutti gli indici
  cambiati: `D[c(2, 4), "a"] <- c(20, 40)`.
- Un fattore con un livello nuovo riceve prima
  `levels(D[["f"]]) <- c(levels(D[["f"]]), "nuovo")`, poi l'assegnazione.
- `Date` e `NA` mantengono la loro forma (`as.Date("...")`, `NA`).
- Il checkpoint “Before cell editing” resta invariato.

### Errori di applicazione

- Se `run_data_commands()` fallisce, l'interfaccia dice “Some changes could
  not be applied” invece di mostrare “Data set updated”.

## 3. Test aggiunti

- celle multiple nella stessa colonna → un solo comando;
- fattore con livello nuovo, anche ordinato;
- `Date` e `NA`;
- rifiuto di numerico, logico, data, righe e colonne non validi;
- `editor_readonly_columns()` per `POSIXct` e colonne lista;
- `editor_apply_error()` per View, dataset sbagliato e token vecchio;
- avviso nell'editor con l'elenco delle colonne di sola lettura.

## 4. Cosa resta aperto

| Limite | Motivo | Prossimo passo |
|---|---|---|
| Inserimento/rimozione righe | richiede comandi dedicati e checkpoint | T14 o azioni riga esistenti |
| `POSIXct`/`POSIXlt` in cella | il fuso orario non è round-trip affidabile | sola lettura, per ora |
| Colonne lista | struttura non rappresentabile nella griglia | sola lettura, per ora |
| Dirty guard modale | oggi c'è l'avviso, non una conferma che blocca il cambio vista | valutare con il nuovo editor |
| Verifica browser | Chrome non naviga `http(s)` in questo ambiente | T11 desktop/CI |
| `rhandsontable` fermo a Handsontable 6 | licenza v7+ non-commercial/commercial | eventuale gate T14 |

## 5. Decisione

L'editor resta `rhandsontable` nella versione hardening. I difetti certi sono
stati chiusi o resi espliciti; il cambio di motore resta un gate separato
(`rtabulator` vs `toastui` vs `editbl`), non un prerequisito per usare il Data
Studio.
