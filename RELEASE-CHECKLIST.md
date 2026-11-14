# RcmdrShiny Studio release checklist

This checklist covers the Studio platform release (Wave 7). The historical
1.0 checklist is preserved in git; the CRAN upload steps remain at the end.

## Code

- [x] All user-facing Rcmdr dialogs are ported; the remaining legacy entries are
      Tk utilities that stay disabled with an explicit warning.
- [x] Command builders are covered by golden tests.
- [x] Server integration tests cover the main flows.
- [x] Browser end-to-end tests exist for Studio, menu platform and navigation.
- [x] Plugin API v1 and SDK v2 are tested.
- [x] The 15 first-party modules pass the contract test in
      `tests/testthat/test-plugins-compat.R`.
- [x] Large-output, plot-gallery, history, checkpoint, cell-output and knit
      history caps are enforced.
- [x] Project save/load, recent projects, autosave/recovery and bundle export are
      covered by unit and integration tests.
- [x] Session checkpoints (active data set, model, documents) are implemented.
- [x] Health panel and extended diagnostics are available.
- [x] Lazy plugin loading and the menu/help/plugin caches are implemented.
- [x] Accessibility pass: skip link, landmarks, ARIA live regions, focus styles,
      reduced motion, image alt text and the checklist in
      `docs/upgrades/ACCESSIBILITY.md`.

## Checks

- [x] `R CMD check --no-manual` clean on the core package.
- [ ] `R CMD check --as-cran` final run.
- [x] `R CMD check` on the 15 plugin packages: all **Status: OK**.
- [x] Vignettes build (Getting Started, Migrating, Plugins, Menu platform).
- [x] pkgdown configuration.
- [x] CI for Linux/Windows/macOS.
- [x] Coverage and browser E2E workflows.
- [x] Example plugin.
- [x] `CITATION`, desktop entry, `NOTICE`, `UPSTREAM`.
- [x] Help inventory: no missing topics for the core.
- [x] Help link checker: 0 broken links.
- [x] Benchmark suite within the documented budgets on the development machine.
- [x] No regression on golden command tests.

## Project release criteria

- [x] Project schema versioned and validated.
- [x] Save, open, save as, recent projects.
- [x] Autosave and recovery prompt.
- [x] Bundle export (`.tar.gz` by default, `.zip` when the zip executable is
      available).
- [x] Project migration from the pre-schema draft.
- [x] Home card with new/open/save/bundle and recent projects.

## Plugin SDK v2

- [x] `plugin_api_version()` and `plugin_contract()`.
- [x] Stable `module_id`, `menu_id`, `item_id`, `command_id`.
- [x] UI components, presets, workflows, chart types, report templates and help
      examples hooks.
- [x] Additive registries: built-in workflows/charts/templates cannot be replaced
      by id.
- [x] Documentation in `vignettes/plugins.Rmd` and
      `topic:writing-plugins`.
- [x] Contract tests for all 15 first-party modules.

## Release steps

```bash
Rscript -e 'testthat::test_local()'
Rscript tools/check_help_links.R --strict
Rscript tools/inventory_help.R --plugins all
Rscript tests/benchmarks/benchmark.R --quick

R CMD build .
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual RcmdrShiny_*.tar.gz
```

Browser E2E:

```bash
R CMD INSTALL .
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e \
  'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-shinytest2.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e \
  'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-menu-platform-e2e.R")'
NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e \
  'pkgload::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-navigation-e2e.R")'
```

## Sign-off

| Item | Owner | Date |
|---|---|---|
| Core test suite | maintainer | 2026-11-14 |
| R CMD check core | maintainer | 2026-11-14 |
| Plugin contract | maintainer | 2026-11-14 |
| Plugin packages check | maintainer | 2026-11-14 |
| Accessibility manual pass | maintainer | pending |
| CRAN upload | maintainer | pending |
