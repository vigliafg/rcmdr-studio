# RcmdrShiny Studio — upgrade plan

This repository (`rcmdr-studio`) is the development line for **RcmdrShiny
Studio**, a browser-native statistical workbench inspired by the R Commander.

It starts as an exact copy of the tracked source of the frozen functional
clone in `rstats-commander` (RcmdrShiny 1.13.0). The clone remains untouched as
the stable baseline; all upgrades happen here.

- **Product name:** RcmdrShiny Studio
- **Package name:** `RcmdrShiny` (unchanged)
- **Positioning:** inspired by R Commander, not a functional clone
- **Order:** foundations → Data → Charts → Report → workbench → navigation →
  help/i18n → platform
- **Constraint:** no new statistical procedures

The detailed, sector-by-sector upgrade plan lives in
[`docs/upgrades/`](docs/upgrades/README.md):

| Document | Scope |
|---|---|
| [`README.md`](docs/upgrades/README.md) | Decisions, roadmap, dependencies, DoD, risks |
| [`DECISIONS.md`](docs/upgrades/DECISIONS.md) | Architecture Decision Records |
| [`00-foundations.md`](docs/upgrades/00-foundations.md) | Identity, design system, shell, palette, history, preview, a11y |
| [`01-data-studio.md`](docs/upgrades/01-data-studio.md) | Data Studio |
| [`02-chart-studio.md`](docs/upgrades/02-chart-studio.md) | Chart Studio |
| [`03-report-studio.md`](docs/upgrades/03-report-studio.md) | Report Studio |
| [`04-workbench.md`](docs/upgrades/04-workbench.md) | Script, Console, Output, Environment, Models |
| [`05-navigation-dialogs-workflows.md`](docs/upgrades/05-navigation-dialogs-workflows.md) | Navigation, dialogs, guided workflows |
| [`06-help-i18n-onboarding.md`](docs/upgrades/06-help-i18n-onboarding.md) | Help, i18n, onboarding |
| [`07-platform-plugins-quality.md`](docs/upgrades/07-platform-plugins-quality.md) | Project, performance, plugin SDK, QA |
| [`CHECKLIST.md`](docs/upgrades/CHECKLIST.md) | Task tracking |
| [`ACCESSIBILITY.md`](docs/upgrades/ACCESSIBILITY.md) | Accessibility checklist |
| [`diary/TEMPLATE.md`](docs/upgrades/diary/TEMPLATE.md) | Handoff diary template between waves |

The code in this initial commit is still RcmdrShiny 1.13.0. The rebranding and
the upgrades begin with Onda 0.
