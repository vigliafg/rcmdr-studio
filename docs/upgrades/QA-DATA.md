# Dati grandi — misure e soglie

Onda 18, S10. Le soglie della griglia non sono state scelte a occhio: questo
documento registra cosa è stato misurato, su quale forma di dati e con quale
decisione.

## Metodo

- Frame sintetico a 5 colonne (`numeric`, `numeric`, `integer`, `factor`,
  `character`), lo stesso di `benchmark_data_frame()`.
- `benchmark_data_scale()` misura, per ogni dimensione:
  - `grid_mb`: memoria del frame di vista (data set + `.row_id`);
  - `build_ms`: costruzione del widget DT;
  - `client_kb`: payload JSON che il client DT dovrebbe scaricare;
  - `server_kb`: payload della sola pagina da 25 righe;
  - `filter_ms`: filtro numerico sull'intera colonna;
  - `copy_ms`: copia TSV di 1000 righe selezionate;
  - `first_view_ms`: frame + widget + serializzazione client.
- Macchina di sviluppo, un solo run: i numeri servono a scegliere la soglia e
  a notare le regressioni, non come benchmark assoluto.

Riproduzione:

```bash
Rscript --vanilla -e 'pkgload::load_all("."); print(benchmark_data_scale(), digits = 4)'
```

## Misure

| Righe | Celle | Data set | Frame vista | Widget | Payload client | Payload server | Filtro | Copia 1k | Prima vista |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 10 000 | 50 000 | 0.96 MB | 0.99 MB | 90 ms | 474 KB | 1.3 KB | 0 ms | 5 ms | 198 ms |
| 50 000 | 250 000 | 4.8 MB | 5.0 MB | 85 ms | 2.4 MB | 1.3 KB | 6 ms | 30 ms | 207 ms |
| 100 000 | 500 000 | 9.5 MB | 9.9 MB | 80 ms | 4.9 MB | 1.3 KB | 9 ms | 5 ms | 552 ms |

La costruzione del widget è piatta: DT avvolge il frame, non lo elabora. Il
costo che cresce è il payload: da 474 KB a 4.9 MB, con la serializzazione che
passa da ~110 a ~470 ms. Il lato server resta a 1.3 KB per pagina, indipendente
dal numero di righe.

## Decisione

- **Soglia server-side: 5000 righe** (`dt_server_threshold`). Sopra questa
  soglia il payload client raddoppia circa ogni 5000 righe senza alcun
  beneficio di interfaccia; sotto, la griglia client resta più reattiva per
  ordinamento e ricerca locale.
- **Soglia editor: 10 000 celle** (`edit_threshold`, invariata). È un budget
  diverso: riguarda rhandsontable, non DT.
- Le due soglie sono indipendenti e `data_grid_plan()` è l'unico punto che le
  applica: render della griglia, proxy di ricerca e avviso leggono lo stesso
  piano.
- **Nessun motore nuovo.** Se in futuro 100 000 righe non bastassero, il gate
  `rtabulator`/`toastui` del piano resta il passo successivo, non una modifica
  a questa onda.

## Limiti noti

- Il frame di vista aggiunge `.row_id`, quindi la memoria è circa il doppio del
  data set. A 100 000 righe sono ~20 MB: accettabile, documentato qui.
- La modalità Classica mantiene la sua griglia client-side: per i dati grandi
  va usata la modalità Studio.
- La copia a intervallo resta limitata alla pagina DT visibile; non esiste
  ancora un range tra pagine.
- In modalità server ordinamento e ricerca passano da DT verso R: sono
  corretti, non istantanei come nel client.
