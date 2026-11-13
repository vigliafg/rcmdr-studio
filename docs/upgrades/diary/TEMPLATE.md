# Diario di handoff — Onda XX — <nome ondata>

**Data:** YYYY-MM-DD  
**Stato:** completata | parziale | bloccata  
**Ondata precedente:** `wave-XX-...`  
**Ondata successiva:** Onda XX — <nome>  
**Documento di settore:** `0X-...md`  
**Checklist:** [`CHECKLIST.md`](../CHECKLIST.md)

---

## 1. Obiettivo e risultato

**Obiettivo dell'ondata:** ...

**Risultato effettivo:** ...

**Cosa è pronto:** ...

**Cosa non è pronto:** ...

---

## 2. Commit

| Hash | Messaggio | Note |
|---|---|---|
| `...` | ... | ... |

---

## 3. File creati e modificati

### Creati

- `R/...`
- `tests/testthat/...`
- `inst/help-topics/topics/...`

### Modificati

- `R/...`
- `DESCRIPTION`
- `NAMESPACE`

### Documentazione

- `docs/upgrades/...`

---

## 4. Test ed evidenze

| Verifica | Comando | Esito |
|---|---|---|
| Unit test | `testthat::test_local()` | ... |
| E2E | `RCMDRSHINY_E2E=1 ...` | ... |
| `R CMD check` | `R CMD check ...` | ... |
| Help inventory | `Rscript tools/inventory_help.R` | ... |
| Link checker | `Rscript tools/check_help_links.R --strict` | ... |
| Benchmark | ... | ... |

**Log o artefatti rilevanti:** ...

---

## 5. Decisioni e ADR

- ADR nuovi: ...
- ADR aggiornati: ...
- Decisioni minori prese durante l'implementazione: ...

---

## 6. Deviazioni dal piano

| Task | Piano originale | Cosa è stato fatto | Motivo |
|---|---|---|---|
| ... | ... | ... | ... |

---

## 7. Problemi noti e blocchi

| Problema | Impatto | Workaround | Task collegata |
|---|---|---|---|
| ... | ... | ... | ... |

---

## 8. Domande aperte

- [ ] ...
- [ ] ...

---

## 9. Prossimi passi esatti

### Prima cosa da fare nella prossima sessione

1. ...
2. ...
3. ...

### Task dell'ondata successiva

| ID | Task | Priorità | Note |
|---|---|---|---|
| ... | ... | ... | ... |

---

## 10. Comandi per riprendere

```bash
# dalla root di rcmdr-studio
git status
git log --oneline -5
Rscript -e 'testthat::test_local()'
```

**Baseline attesa:** ...

---

## 11. Note di contesto

Informazioni che non si deducono facilmente dal codice:

- ...
- ...

---

## 12. Aggiornamenti alla checklist

- [ ] `CHECKLIST.md` aggiornata.
- [ ] Documento di settore aggiornato.
- [ ] Diario committato e pushato.
- [ ] Utente informato: “diario pronto, puoi compattare il contesto”.
