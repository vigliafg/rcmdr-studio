# Accessibility checklist — RcmdrShiny Studio

**Riferimento:** Onda 0, S0.8 e Onda 7, P7.21
**Obiettivo:** la Studio UI deve essere utilizzabile da tastiera e leggibile dai
lettori di schermo, senza regressioni rispetto alla modalità Classica.

**Stato:** verificato automaticamente dove possibile da
`tests/testthat/test-accessibility.R`. Le voci marcate **manuale** richiedono
un controllo con browser reale e lettore di schermo prima della release.

---

## 1. Navigazione da tastiera

- [x] Il primo `Tab` raggiunge “Skip to main content”.
- [x] Tutti i controlli interattivi sono raggiungibili con `Tab`.
- [x] L'ordine di focus segue l'ordine visivo.
- [x] `Enter`/`Space` attivano pulsanti e link.
- [x] `Esc` chiude le modali che lo consentono (Bootstrap).
- [x] Il focus è intrappolato nelle modali (Bootstrap).
- [x] Alla chiusura della modale il focus torna all'elemento di origine (Bootstrap).
- [x] La command palette si apre con `Ctrl+K`/`Cmd+K`.
- [x] Frecce su/giù navigano i risultati della palette.
- [x] `Ctrl+Enter` esegue selezione/cella.
- [x] `F6` / `Shift+F6` passano tra vista primaria, secondaria, pannello
      interno (Inspector/Preview), pannello modeless e status bar.
- [x] La griglia dati è un tab stop: le frecce muovono la riga attiva,
      `Invio`/`Spazio` selezionano, `Shift`+frecce estendono la selezione a
      celle, `Esc` pulisce.
- [x] Il grip di larghezza delle colonne è un `separator` focalizzabile:
      frecce sinistra/destra cambiano la larghezza, `Home` torna al default.
- [x] Non ci sono trappole di focus.

## 2. Focus visibile

- [x] Ogni elemento focalizzato ha un outline visibile (`:focus-visible`).
- [x] L'outline non è coperto da overflow o z-index.
- [x] Il focus è visibile anche in tema scuro e alto contrasto.
- [x] Il focus non dipende solo dal colore (outline + offset).

## 3. ARIA e semantica

- [x] La sidebar ha `role="navigation"` e un'etichetta.
- [x] L'area principale ha `role="main"`.
- [x] La status bar ha `aria-live="polite"`, nome e `tabindex="-1"`.
- [x] Le regioni del workspace hanno `role="region"` e un nome
      (“Primary view”, “Secondary view”, pannello, modeless).
- [x] I risultati di ricerca e le notifiche sono annunciati.
- [x] Le tab usano il comportamento Bootstrap (`aria-selected`).
- [x] I dialoghi hanno un titolo associato.
- [x] I campi con errore hanno `aria-invalid` e `aria-describedby`.
- [x] I messaggi di errore sono associati al campo (`dialog_validation_ui`).
- [x] Le icone decorative hanno `aria-hidden="true"`.
- [x] I pulsanti icona hanno `aria-label`.

## 4. Contrasto e colori

- [x] Testo normale: contrasto ≥ 4.5:1 (palette Bootstrap 5 + override scuri).
- [x] Testo grande: contrasto ≥ 3:1.
- [x] Bordi e controlli: contrasto ≥ 3:1.
- [x] Gli stati non sono comunicati solo dal colore (testo `status` accanto al badge).
- [x] Le palette grafiche sono colorblind-safe.
- [x] Il tema scuro mantiene il contrasto.
- [x] Il tema alto contrasto è disponibile.

## 5. Movimento e preferenze

- [x] Le animazioni rispettano `prefers-reduced-motion`.
- [x] Non ci sono lampeggi o transizioni aggressive.
- [x] La dimensione del testo segue lo zoom del browser.
- [x] A 200% di zoom il guscio collassa a una colonna sotto 991.98 px CSS e
      la sidebar impilata resta entro 40vh (verifica CSS automatica).
- [ ] Resa reale a 200% di zoom nel browser. **Manuale**
- [x] Le tabelle hanno scroll orizzontale accessibile.

## 6. Form e dialoghi

- [x] Ogni input ha una label visibile o `aria-label`.
- [x] I campi obbligatori sono indicati.
- [x] La validazione non perde i dati inseriti.
- [x] I select multipli sono utilizzabili da tastiera.
- [x] I messaggi di aiuto sono leggibili.
- [x] Il pulsante primario è chiaro.
- [x] “Reset” non cancella senza conferma se ci sono dati.

## 7. Data Studio

- [x] La griglia è navigabile da tastiera (DT) e ha un cursore di riga.
- [x] Le intestazioni sono annunciate.
- [x] La selezione righe è comprensibile e si avvia senza mouse.
- [x] Le larghezze delle colonne si cambiano anche da tastiera.
- [x] L'inspector è raggiungibile.
- [x] Le azioni di colonna hanno label.
- [x] Il filtro è annunciato.
- [x] Il missingness è comunicato anche testualmente.

## 8. Chart Studio

- [x] Il builder è navigabile.
- [x] L'anteprima ha un testo alternativo.
- [x] I controlli di mapping hanno label.
- [x] La galleria è navigabile.
- [x] I pulsanti di export hanno label.
- [x] Il grafico non è l'unico modo per comunicare un risultato.

## 9. Report Studio

- [x] L'editor è raggiungibile.
- [x] L'outline è navigabile.
- [x] La preview è annunciata.
- [x] I pulsanti Knit/Download hanno label.
- [x] Gli errori di knit sono associati al contesto.
- [x] Le celle hanno un pulsante Esegui accessibile.

## 10. Test

- [x] Audit statico delle nuove superfici desktop (Onda 18, S11):
      regioni, status bar, griglia, grip, zoom, reduced motion.
- [x] Flusso import → summary → plot completabile da tastiera (E2E core).
- [x] Flusso palette → dialogo → OK completabile da tastiera (E2E navigation).
- [x] Flusso Report Studio → knit completabile da tastiera (E2E core).
- [ ] Test con zoom 200% su browser reale. **Manuale** (bloccato: Chrome non
      naviga `http(s)` in questo ambiente, vedi `QA-WIDGETS.md` § 9)
- [x] Test con tema scuro (CSS e E2E).
- [x] Test con tema alto contrasto (CSS).
- [ ] Test con lettore di schermo (NVDA/VoiceOver) sulle schermate principali. **Manuale** (bloccato come sopra)
- [ ] Nessun errore grave con axe-core (opzionale). **Manuale**

---

## Evidenze automatiche

```bash
Rscript -e 'testthat::test_local(filter = "accessibility")'
```

Il test verifica skip link, landmark `main`/`navigation`/`banner`, regione
`aria-live`, semantica del menubar, outline `:focus-visible`,
`prefers-reduced-motion`, validazione `aria-live="assertive"` e campo di ricerca
della palette etichettato.

Le voci di menu non disponibili sono `aria-disabled="true"`, focalizzabili e
accompagnate dal motivo (`visually-hidden` + `title`), così il debito è
annunciato anche senza mouse. Il click su una voce disabilitata non chiude il
menu.
