# Test matrix — RcmdrShiny Studio

**Riferimento:** Onda 7, P7.19
**Obiettivo:** ogni modifica passa dal livello più economico che può rilevarla.

| Livello | Cosa copre | Comando | Evidenza corrente |
|---|---|---|---|
| Unit | Funzioni pure, parser, builder, schema progetto, cache | `Rscript -e 'testthat::test_local()'` | 3 333 test |
| Integration | Server Shiny, dialoghi, stato, progetto, checkpoint | `testthat::test_local()` | `test-app-integration.R`, `test-project.R`, `test-session-checkpoints.R` |
| Golden | Comandi esistenti invariati | `test-command-builders-*.R` | tutti i builder |
| Menu contract | ID stabili, copertura comandi, moduli first-party | `test-menu-registry.R`, `test-plugins-compat.R` | 782/782 comandi |
| E2E | Flussi Studio e Classica | `RCMDRSHINY_E2E=1` + `test-shinytest2.R` | 15 test |
| E2E menu | Menubar gerarchico e ID DOM | `test-menu-platform-e2e.R` | 16 test |
| E2E navigation | Palette, preferiti, ricerca | `test-navigation-e2e.R` | 4 test |
| Visual | Grafici deterministici | `vdiffr` (opzionale) | `test-visual.R` |
| Accessibility | Landmark, ARIA, focus, skip link | `test-accessibility.R` + `docs/upgrades/ACCESSIBILITY.md` | checklist |
| Performance | Avvio, import, griglia, cache, cap | `tests/benchmarks/benchmark.R` | `test-performance.R` |
| Package | Core e 15 plugin | `R CMD check` | core OK |

## Comandi rapidi

```bash
# unit + integration + golden
Rscript -e 'testthat::test_local()'

# E2E browser (richiede chromote)
R CMD INSTALL .
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e \
  'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-shinytest2.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e \
  'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-menu-platform-e2e.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e \
  'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-navigation-e2e.R")'

# visual (opzionale)
Rscript -e 'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-visual.R")'

# benchmark
Rscript tests/benchmarks/benchmark.R --quick
Rscript tests/benchmarks/benchmark.R

# package
R CMD build .
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual RcmdrShiny_*.tar.gz
```

## Regole

- Un test unitario nuovo accompagna ogni funzione nuova.
- Un comando nuovo o modificato richiede un golden test.
- Una modifica al menu richiede il test di copertura comandi.
- Una modifica al progetto richiede save/load, migrazione e path helper.
- I test E2E sono gated da `RCMDRSHINY_E2E=1`: la suite normale resta veloce.
- I benchmark non sono fatali; un superamento del budget va confrontato con la
  release precedente.
