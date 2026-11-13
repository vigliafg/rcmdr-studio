# Accessibility checklist — RcmdrShiny Studio

**Riferimento:** Onda 0, S0.8 e Onda 7, P7.21  
**Obiettivo:** la Studio UI deve essere utilizzabile da tastiera e leggibile dai
lettori di schermo, senza regressioni rispetto alla modalità Classica.

---

## 1. Navigazione da tastiera

- [ ] Il primo `Tab` raggiunge “Skip to main content”.
- [ ] Tutti i controlli interattivi sono raggiungibili con `Tab`.
- [ ] L'ordine di focus segue l'ordine visivo.
- [ ] `Enter`/`Space` attivano pulsanti e link.
- [ ] `Esc` chiude le modali che lo consentono.
- [ ] Il focus è intrappolato nelle modali.
- [ ] Alla chiusura della modale il focus torna all'elemento di origine.
- [ ] La command palette si apre con `Ctrl+K`/`Cmd+K`.
- [ ] Frecce su/giù navigano i risultati della palette.
- [ ] `Ctrl+Enter` esegue selezione/cella.
- [ ] Non ci sono trappole di focus.

## 2. Focus visibile

- [ ] Ogni elemento focalizzato ha un outline visibile.
- [ ] L'outline non è coperto da overflow o z-index.
- [ ] Il focus è visibile anche in tema scuro e alto contrasto.
- [ ] Il focus non dipende solo dal colore.

## 3. ARIA e semantica

- [ ] La sidebar ha `role="navigation"` e un'etichetta.
- [ ] L'area principale ha `role="main"`.
- [ ] La status bar ha `aria-live="polite"`.
- [ ] I risultati di ricerca e le notifiche sono annunciati.
- [ ] Le tab usano `aria-current` o `aria-selected`.
- [ ] I dialoghi hanno un titolo associato.
- [ ] I campi con errore hanno `aria-invalid` e `aria-describedby`.
- [ ] I messaggi di errore sono associati al campo.
- [ ] Le icone decorative hanno `aria-hidden="true"`.
- [ ] I pulsanti icona hanno `aria-label`.

## 4. Contrasto e colori

- [ ] Testo normale: contrasto ≥ 4.5:1.
- [ ] Testo grande: contrasto ≥ 3:1.
- [ ] Bordi e controlli: contrasto ≥ 3:1.
- [ ] Gli stati non sono comunicati solo dal colore.
- [ ] Le palette grafiche sono colorblind-safe.
- [ ] Il tema scuro mantiene il contrasto.
- [ ] Il tema alto contrasto è disponibile.

## 5. Movimento e preferenze

- [ ] Le animazioni rispettano `prefers-reduced-motion`.
- [ ] Non ci sono lampeggi o transizioni aggressive.
- [ ] La dimensione del testo segue lo zoom del browser.
- [ ] Il layout non si rompe a 200% di zoom.
- [ ] Le tabelle hanno scroll orizzontale accessibile.

## 6. Form e dialoghi

- [ ] Ogni input ha una label visibile o `aria-label`.
- [ ] I campi obbligatori sono indicati.
- [ ] La validazione non perde i dati inseriti.
- [ ] I select multipli sono utilizzabili da tastiera.
- [ ] I messaggi di aiuto sono leggibili.
- [ ] Il pulsante primario è chiaro.
- [ ] “Reset” non cancella senza conferma se ci sono dati.

## 7. Data Studio

- [ ] La griglia è navigabile da tastiera.
- [ ] Le intestazioni sono annunciate.
- [ ] La selezione righe è comprensibile.
- [ ] L'inspector è raggiungibile.
- [ ] Le azioni di colonna hanno label.
- [ ] Il filtro è annunciato.
- [ ] Il missingness è comunicato anche testualmente.

## 8. Chart Studio

- [ ] Il builder è navigabile.
- [ ] L'anteprima ha un testo alternativo.
- [ ] I controlli di mapping hanno label.
- [ ] La galleria è navigabile.
- [ ] I pulsanti di export hanno label.
- [ ] Il grafico non è l'unico modo per comunicare un risultato.

## 9. Report Studio

- [ ] L'editor è raggiungibile.
- [ ] L'outline è navigabile.
- [ ] La preview è annunciata.
- [ ] I pulsanti Knit/Download hanno label.
- [ ] Gli errori di knit sono associati al contesto.
- [ ] Le celle hanno un pulsante Esegui accessibile.

## 10. Test

- [ ] Flusso import → summary → plot completabile da tastiera.
- [ ] Flusso palette → dialogo → OK completabile da tastiera.
- [ ] Flusso Report Studio → knit completabile da tastiera.
- [ ] Test con zoom 200%.
- [ ] Test con tema scuro.
- [ ] Test con tema alto contrasto.
- [ ] Test con lettore di schermo (NVDA/VoiceOver) sulle schermate principali.
- [ ] Nessun errore grave con axe-core (opzionale).
