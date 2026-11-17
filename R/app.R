# Shiny application ---------------------------------------------------------

app_css <- function() {
  htmltools::HTML(
    "
    body { background: var(--rcmdr-bg); }
    .rcmdr-topbar { background: var(--rcmdr-primary); color: var(--rcmdr-on-primary); }
    .rcmdr-topbar .badge-box { color: var(--rcmdr-on-primary-muted); font-size: .9rem; }
    .rcmdr-topbar .form-select { max-width: 8rem; }
    /* Selectize renders its own dropdown at z-index 1000; the menubar and the
       toolbar sit at 1040, so the language and theme lists were painted under
       them.  Keep every select list above those bars. */
    .selectize-control .selectize-dropdown { z-index: 1050; }
    .rcmdr-sidebar {
      background: var(--rcmdr-surface); border-right: 1px solid var(--rcmdr-border);
      min-height: calc(100vh - 90px); padding: .75rem .65rem;
      max-height: calc(100vh - 90px); overflow-y: auto;
    }
    .rcmdr-menu-group > summary {
      cursor: pointer; font-weight: 600; padding: .25rem 0;
      list-style: none; color: var(--rcmdr-heading);
    }
    .rcmdr-menu-group > summary::-webkit-details-marker { display: none; }
    .rcmdr-menubar { display: flex; align-items: stretch; gap: .1rem;
      flex-wrap: wrap; overflow: visible;
      background: var(--rcmdr-surface); border-bottom: 1px solid var(--rcmdr-border);
      padding: .2rem .5rem; position: relative; z-index: 1040; }
    .rcmdr-menubar-group { position: relative; }
    .rcmdr-menubar-group > summary { list-style: none; cursor: pointer;
      padding: .45rem .7rem; border-radius: .3rem; color: var(--rcmdr-heading);
      font-weight: 500; white-space: nowrap; }
    .rcmdr-menubar-group > summary::-webkit-details-marker { display: none; }
    .rcmdr-menubar-group > summary:hover,
    .rcmdr-menubar-group[open] > summary { background: var(--rcmdr-hover); }
    .rcmdr-menubar-dropdown { position: absolute; top: calc(100% + .15rem);
      left: 0; min-width: 270px; max-width: 420px; max-height: 75vh;
      overflow-y: auto; background: var(--rcmdr-surface); border: 1px solid var(--rcmdr-border);
      border-radius: .4rem; box-shadow: 0 .6rem 1.4rem rgba(31, 58, 95, .18);
      padding: .35rem; }
    .rcmdr-menubar-dropdown .rcmdr-menu-group { margin: .1rem 0; }
    .rcmdr-menubar-dropdown .rcmdr-menu-group > summary {
      padding: .32rem .45rem; border-radius: .25rem; }
    .rcmdr-menubar-dropdown .rcmdr-menu-group > summary:hover {
      background: var(--rcmdr-hover); }
    .rcmdr-menubar-dropdown .rcmdr-menu-children { padding-left: .55rem; }
    .rcmdr-menubar-dropdown .rcmdr-menu-row { padding-left: .15rem; }
    .rcmdr-menubar-dropdown .rcmdr-menu-item { white-space: normal; }
    .rcmdr-menubar-toggle { display: none; }
    @media (max-width: 991px) {
      .rcmdr-menubar-group > summary { padding: .4rem .5rem; font-size: .92rem; }
      .rcmdr-menubar-dropdown { width: calc(100vw - 1rem);
        min-width: 0; max-width: calc(100vw - 1rem); }
    }
    .rcmdr-menu-group > summary:before { content: '\\25B8'; display: inline-block;
      width: 1em; transition: transform .1s; }
    .rcmdr-menu-group[open] > summary:before { transform: rotate(90deg); }
    .rcmdr-menu-children { padding-left: .9rem; }
    .rcmdr-menu-item { display: block; padding: .12rem 0; text-decoration: none;
      color: var(--rcmdr-link); }
    .rcmdr-menu-item:hover { color: var(--rcmdr-accent); text-decoration: underline; }
    .rcmdr-menu-item.disabled { color: var(--rcmdr-disabled); cursor: not-allowed; }
    .rcmdr-statusbar { background: var(--rcmdr-surface-muted); border-top: 1px solid var(--rcmdr-border);
      padding: .25rem .75rem; font-size: .85rem; color: var(--rcmdr-muted); }
    pre.shiny-text-output { white-space: pre-wrap; background: var(--rcmdr-surface);
      border: 1px solid var(--rcmdr-border); border-radius: .35rem; padding: .75rem;
      min-height: 120px; max-height: 60vh; overflow-y: auto; }
    .rcmdr-plot img.rcmdr-main-plot { max-width: 100%; border: 1px solid var(--rcmdr-border); }
    .rcmdr-gallery { display: flex; flex-wrap: wrap; gap: .5rem; margin-bottom: .75rem; }
    .rcmdr-gallery img.rcmdr-thumb { width: 110px; height: 82px; object-fit: cover;
      border: 2px solid var(--rcmdr-border); border-radius: .3rem; cursor: pointer;
      background: var(--rcmdr-surface); }
    .rcmdr-gallery img.rcmdr-thumb.active { border-color: var(--rcmdr-accent); }
    .rcmdr-chart-grid { display: grid; gap: .75rem;
      grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); }
    .rcmdr-chart-card { background: var(--rcmdr-surface); border: 1px solid var(--rcmdr-border);
      border-radius: .45rem; overflow: hidden; display: flex;
      flex-direction: column; }
    .rcmdr-chart-card.pinned { border-color: var(--rcmdr-accent); }
    .rcmdr-chart-thumb { background: var(--rcmdr-surface-sunken); cursor: pointer;
      min-height: 130px; display: flex; align-items: center;
      justify-content: center; }
    .rcmdr-chart-thumb img { width: 100%; height: 130px; object-fit: cover; }
    .rcmdr-chart-thumb-empty { color: var(--rcmdr-muted); font-size: .85rem; }
    .rcmdr-chart-card-body { padding: .6rem .7rem; }
    .rcmdr-chart-card-body h6 { margin-bottom: .25rem; }
    .rcmdr-chart-preview-image { background: var(--rcmdr-surface); border: 1px solid var(--rcmdr-border);
      border-radius: .35rem; padding: .35rem; text-align: center; }
    .rcmdr-chart-detail { margin-top: 1rem; background: var(--rcmdr-surface);
      border: 1px solid var(--rcmdr-border); border-radius: .45rem; padding: .9rem; }
    .rcmdr-chart-detail-image { max-width: 100%; border: 1px solid var(--rcmdr-border);
      border-radius: .35rem; margin: .5rem 0; }
    .rcmdr-report-toolbar { background: var(--rcmdr-surface); border: 1px solid var(--rcmdr-border);
      border-radius: .45rem; padding: .6rem .75rem; margin-bottom: .75rem; }
    .rcmdr-report-workspace .rcmdr-section-card { margin-bottom: .75rem; }
    .rcmdr-report-outline { display: flex; flex-direction: column; gap: .15rem;
      max-height: 32vh; overflow-y: auto; }
    .rcmdr-report-outline a { color: var(--rcmdr-heading); text-decoration: none;
      padding: .1rem .25rem; border-radius: .2rem; }
    .rcmdr-report-outline a:hover { background: var(--rcmdr-hover); }
    .rcmdr-report-outline .rcmdr-outline-level-1 { font-weight: 600; }
    .rcmdr-report-outline .rcmdr-outline-level-2 { padding-left: .9rem; }
    .rcmdr-report-outline .rcmdr-outline-level-3 { padding-left: 1.8rem;
      font-size: .92rem; }
    .rcmdr-report-outline .rcmdr-outline-level-4,
    .rcmdr-report-outline .rcmdr-outline-level-5,
    .rcmdr-report-outline .rcmdr-outline-level-6 { padding-left: 2.6rem;
      font-size: .88rem; }
    .rcmdr-cell-list { display: flex; flex-direction: column; gap: .4rem;
      max-height: 34vh; overflow-y: auto; }
    .rcmdr-cell-card { border: 1px solid var(--rcmdr-border); border-radius: .35rem;
      padding: .35rem .5rem; background: var(--rcmdr-surface-muted); }
    .rcmdr-cell-output { margin-top: .25rem; }
    .rcmdr-cell-output pre { font-size: .78rem; max-height: 200px;
      overflow-y: auto; background: var(--rcmdr-surface); border: 1px solid var(--rcmdr-border);
      padding: .35rem; border-radius: .25rem; }
    .rcmdr-cell-plot { max-width: 100%; border: 1px solid var(--rcmdr-border);
      border-radius: .25rem; margin-top: .35rem; }
    .rcmdr-report-preview { max-height: 62vh; overflow-y: auto;
      background: var(--rcmdr-surface); border: 1px solid var(--rcmdr-border); border-radius: .35rem;
      padding: .75rem; }
    .rcmdr-report-chunk { border: 1px dashed var(--rcmdr-border); border-radius: .35rem;
      margin: .5rem 0; background: var(--rcmdr-surface-muted); }
    .rcmdr-report-chunk-label { font-size: .78rem; text-transform: uppercase;
      letter-spacing: .04em; color: var(--rcmdr-muted); padding: .25rem .5rem;
      border-bottom: 1px dashed var(--rcmdr-border); }
    .rcmdr-report-chunk pre { margin: 0; padding: .5rem; font-size: .8rem; }
    .rcmdr-report-source { white-space: pre-wrap; font-size: .82rem;
      background: var(--rcmdr-surface-muted); border: 1px solid var(--rcmdr-border); padding: .5rem;
      border-radius: .3rem; }
    .rcmdr-template-grid { display: grid; gap: .5rem;
      grid-template-columns: repeat(auto-fill, minmax(190px, 1fr)); }
    .rcmdr-template-list { display: flex; flex-direction: column; gap: .35rem; }
    .rcmdr-template-card { display: block; border: 1px solid var(--rcmdr-border);
      border-radius: .35rem; padding: .5rem .6rem; background: var(--rcmdr-surface);
      color: inherit; text-decoration: none; }
    .rcmdr-template-card:hover { border-color: var(--rcmdr-accent); background: var(--rcmdr-hover); }
    .rcmdr-report-status { border-top: 1px solid var(--rcmdr-border); padding-top: .35rem; }
    .rcmdr-knit-history { display: flex; flex-direction: column; gap: .25rem; }
    .rcmdr-knit-entry { border-bottom: 1px solid var(--rcmdr-border); padding: .2rem 0; }
    .rcmdr-doc-tabs { display: flex; align-items: center; gap: .25rem;
      flex-wrap: wrap; margin-bottom: .5rem; border-bottom: 1px solid var(--rcmdr-border);
      padding-bottom: .25rem; }
    .rcmdr-doc-tab { display: inline-flex; align-items: center; gap: .35rem;
      border: 1px solid var(--rcmdr-border); border-bottom: none; border-radius: .35rem .35rem 0 0;
      padding: .2rem .45rem; background: var(--rcmdr-surface-muted); }
    .rcmdr-doc-tab.active { background: var(--rcmdr-surface); border-color: var(--rcmdr-accent);
      box-shadow: inset 0 -2px 0 var(--rcmdr-accent); }
    .rcmdr-doc-tab a { color: var(--rcmdr-heading); text-decoration: none;
      display: inline-flex; gap: .35rem; align-items: center; }
    .rcmdr-doc-mode { font-size: .68rem; text-transform: uppercase;
      letter-spacing: .04em; color: var(--rcmdr-muted); }
    .rcmdr-doc-close, .rcmdr-doc-new { border: none; background: transparent;
      color: var(--rcmdr-muted); line-height: 1; padding: 0 .2rem; }
    .rcmdr-doc-close:hover, .rcmdr-doc-new:hover { color: var(--rcmdr-danger); }
    .rcmdr-doc-new { font-size: 1.1rem; font-weight: 600; }
    .rcmdr-script-findbar { display: flex; gap: .4rem; align-items: center;
      flex-wrap: wrap; margin-bottom: .4rem; }
    .rcmdr-script-outputs { display: flex; flex-direction: column; gap: .4rem;
      margin-top: .5rem; }
    .rcmdr-script-output { font-size: .78rem; max-height: 220px;
      overflow-y: auto; background: var(--rcmdr-surface-muted); border: 1px solid var(--rcmdr-border);
      padding: .4rem; border-radius: .3rem; }
    .rcmdr-script-diagnostics { display: flex; flex-direction: column; gap: .2rem; }
    .rcmdr-object-table td, .rcmdr-object-table th,
    .rcmdr-models-table td, .rcmdr-models-table th { vertical-align: middle;
      font-size: .86rem; }
    .rcmdr-object-preview { max-height: 40vh; overflow-y: auto;
      background: var(--rcmdr-surface-muted); border: 1px solid var(--rcmdr-border); padding: .6rem;
      border-radius: .35rem; font-size: .8rem; }
    .rcmdr-console-log { max-height: 48vh; overflow-y: auto;
      display: flex; flex-direction: column; gap: .4rem; margin-bottom: .5rem; }
    .rcmdr-message-text { margin: .25rem 0 0; font-size: .82rem;
      white-space: pre-wrap; }
    .rcmdr-history-card.pinned { border-left: 3px solid var(--rcmdr-accent); }
    .rcmdr-output-raw { margin-top: .75rem; }
    .rcmdr-help-text { white-space: pre-wrap; max-height: 60vh; overflow-y: auto;
      background: var(--rcmdr-surface-muted); border: 1px solid var(--rcmdr-border); padding: .75rem; }
    .rcmdr-help-search { margin-bottom: .75rem; }
    .rcmdr-help-sidebar { background: var(--rcmdr-surface); border: 1px solid var(--rcmdr-border);
      border-radius: .4rem; padding: .75rem; }
    .rcmdr-help-sidebar h6 { text-transform: uppercase; letter-spacing: .04em;
      font-size: .75rem; color: var(--rcmdr-muted); }
    .rcmdr-help-category { display: flex; justify-content: space-between;
      align-items: center; gap: .5rem; padding: .3rem .4rem;
      border-radius: .3rem; color: var(--rcmdr-link); text-decoration: none; }
    .rcmdr-help-category:hover, .rcmdr-help-category.active {
      background: var(--rcmdr-hover); color: var(--rcmdr-accent); }
    .rcmdr-help-result { display: block; padding: .55rem .6rem; margin-bottom: .35rem;
      border: 1px solid var(--rcmdr-border); border-radius: .4rem; background: var(--rcmdr-surface);
      color: inherit; text-decoration: none; }
    .rcmdr-help-result:hover { border-color: var(--rcmdr-accent); }
    .rcmdr-help-result-title { font-weight: 600; color: var(--rcmdr-heading); }
    .rcmdr-help-result-category { float: right; font-size: .75rem;
      text-transform: uppercase; color: var(--rcmdr-muted); }
    .rcmdr-help-result-snippet { margin: .25rem 0 0; font-size: .88rem;
      color: var(--rcmdr-muted); }
    .rcmdr-help-topic { margin-top: 1rem; background: var(--rcmdr-surface);
      border: 1px solid var(--rcmdr-border); border-radius: .4rem; padding: 1rem 1.25rem; }
    .rcmdr-help-topic:focus-visible { outline: 3px solid var(--rcmdr-accent); }
    .rcmdr-help-body { max-width: 70ch; }
    .rcmdr-help-body pre { background: var(--rcmdr-surface-sunken); border: 1px solid var(--rcmdr-border);
      border-radius: .35rem; padding: .6rem .75rem; overflow-x: auto; }
    .rcmdr-help-body table { border-collapse: collapse; margin: .75rem 0; }
    .rcmdr-help-body th, .rcmdr-help-body td {
      border: 1px solid var(--rcmdr-border); padding: .3rem .5rem; }
    .rcmdr-help-footer { display: flex; gap: .5rem; flex-wrap: wrap;
      margin-top: 1rem; padding-top: .75rem; border-top: 1px solid var(--rcmdr-border); }
    .rcmdr-help-related ul { padding-left: 1.1rem; }
    .rcmdr-help-inline { margin-top: 1rem; padding-top: .75rem;
      border-top: 2px solid var(--rcmdr-border); max-height: 45vh; overflow-y: auto; }
    .rcmdr-help-language { text-transform: uppercase; font-size: .75rem;
      color: var(--rcmdr-muted); }
    .rcmdr-help-filters { display: flex; gap: .5rem; align-items: end;
      flex-wrap: wrap; margin-top: .5rem; }
    .rcmdr-help-filters .form-group { margin-bottom: 0; }
    .rcmdr-help-result-meta { display: flex; gap: .35rem; align-items: center;
      float: right; }
    .rcmdr-help-result-meta .badge { font-weight: 500; }
    .rcmdr-help-result-snippet mark { background: var(--rcmdr-mark-bg); padding: 0 .1rem; }
    .rcmdr-help-toc { border: 1px solid var(--rcmdr-border);
      border-radius: var(--rcmdr-radius); background: var(--rcmdr-surface-muted);
      padding: .6rem .8rem; margin-bottom: 1rem; }
    .rcmdr-help-toc h5 { font-size: .85rem; text-transform: uppercase;
      letter-spacing: .04em; color: var(--rcmdr-muted); }
    .rcmdr-help-toc ul { list-style: none; padding-left: 0; margin: 0; }
    .rcmdr-help-toc-level-3 { padding-left: 1rem; }
    .rcmdr-help-toc-level-4 { padding-left: 2rem; }
    .rcmdr-help-examples, .rcmdr-help-dialogs, .rcmdr-help-commands {
      margin-top: 1.25rem; }
    .rcmdr-help-example { border: 1px solid var(--rcmdr-border);
      border-radius: var(--rcmdr-radius); padding: .75rem; margin-bottom: .75rem; }
    .rcmdr-help-example-code { background: var(--rcmdr-surface-sunken); border-radius: .35rem;
      padding: .6rem .75rem; }
    .rcmdr-help-example-actions { display: flex; gap: .4rem; flex-wrap: wrap;
      margin-top: .4rem; }
    .rcmdr-error-help { display: inline-block; margin-left: .5rem; }
    .rcmdr-checklist-list { list-style: none; padding-left: 0; margin: 0; }
    .rcmdr-checklist-item { display: flex; gap: .55rem; align-items: center;
      padding: .4rem 0; border-bottom: 1px solid var(--rcmdr-border); }
    .rcmdr-checklist-item:last-child { border-bottom: 0; }
    .rcmdr-checklist-mark { color: var(--rcmdr-muted); font-weight: 700; }
    .rcmdr-checklist-item.done .rcmdr-checklist-mark { color: var(--rcmdr-success); }
    .rcmdr-checklist-item.done .rcmdr-checklist-label strong {
      text-decoration: line-through; color: var(--rcmdr-muted); }
    .rcmdr-checklist-item.unavailable { opacity: .65; }
    .rcmdr-checklist-progress { height: .45rem; }
    .rcmdr-tour-highlight { outline: 3px solid #f59e0b !important;
      outline-offset: 3px; box-shadow: 0 0 0 6px rgba(245, 158, 11, .25);
      border-radius: .35rem; }
    .rcmdr-busy { color: var(--rcmdr-warning); font-weight: 600; }
    .rcmdr-skip-link { position: absolute; left: .5rem; top: .5rem;
      background: var(--rcmdr-surface); color: var(--rcmdr-heading); padding: .4rem .7rem;
      border-radius: .3rem; z-index: 2000; }
    :focus-visible { outline: 3px solid var(--rcmdr-accent); outline-offset: 2px; }

    /* Density -------------------------------------------------------------
       The interface is dense by default: a statistical workbench is a tool,
       not a brochure. Every value is a token, so a component can stay compact
       without repeating numbers, and the comfortable variant restores the
       Bootstrap spacing in one place. */
    body {
      --rcmdr-field-gap: .4rem;
      --rcmdr-label-size: .8125rem;
      --rcmdr-label-gap: .1rem;
      --rcmdr-control-size: .875rem;
      --rcmdr-control-pad: .22rem .45rem;
      --rcmdr-control-min: 1.9rem;
      --rcmdr-section-gap: .4rem;
      --rcmdr-help-size: .78rem;
    }
    body.rcmdr-density-compact { --rcmdr-space: .55rem; }
    body.rcmdr-density-comfortable {
      --rcmdr-field-gap: 1rem;
      --rcmdr-label-size: .9375rem;
      --rcmdr-label-gap: .5rem;
      --rcmdr-control-size: .9375rem;
      --rcmdr-control-pad: .375rem .75rem;
      --rcmdr-control-min: 2.4rem;
      --rcmdr-section-gap: 1rem;
      --rcmdr-help-size: .875rem;
      --rcmdr-space: .75rem;
    }
    body .form-group,
    body .shiny-input-container { margin-bottom: var(--rcmdr-field-gap); }
    body .form-group > label,
    body label.control-label { margin-bottom: var(--rcmdr-label-gap); }
    body .form-group > label,
    body label.control-label,
    body .form-check-label { font-size: var(--rcmdr-label-size); }
    body .form-check { margin-bottom: 0; }
    body .form-control,
    body .form-select {
      min-height: var(--rcmdr-control-min);
      padding: var(--rcmdr-control-pad);
      font-size: var(--rcmdr-control-size);
    }
    body .selectize-control .selectize-input {
      min-height: var(--rcmdr-control-min);
      padding: var(--rcmdr-control-pad);
      font-size: var(--rcmdr-control-size);
    }
    body hr { margin: var(--rcmdr-section-gap) 0; }
    body .form-text, body .help-block {
      font-size: var(--rcmdr-help-size);
      margin: .15rem 0 0;
    }

    .rcmdr-topbar { background: var(--rcmdr-primary); }
    .rcmdr-topbar .rcmdr-brand-sub { color: var(--rcmdr-on-primary-muted); }
    .rcmdr-topbar .form-select { max-width: 9rem; }
    .rcmdr-sidebar {
      background: var(--rcmdr-surface);
      border-right: 1px solid var(--rcmdr-border);
      min-height: calc(100vh - 90px); padding: var(--rcmdr-space);
      max-height: calc(100vh - 90px); overflow-y: auto;
    }
    .rcmdr-statusbar {
      background: var(--rcmdr-surface-muted);
      border-top: 1px solid var(--rcmdr-border);
    }
    .rcmdr-toolbar {
      background: var(--rcmdr-surface);
      border: 1px solid var(--rcmdr-border);
      border-radius: var(--rcmdr-radius);
      padding: .5rem .65rem; margin-bottom: var(--rcmdr-space);
    }
    .rcmdr-toolbar-field .form-group,
    .rcmdr-toolbar-field .shiny-input-container { margin-bottom: 0; }
    .rcmdr-dialog-category {
      font-size: .78rem; font-weight: 400; text-transform: uppercase;
      letter-spacing: .04em; color: var(--rcmdr-muted);
    }
    .rcmdr-dialog-preview {
      margin-top: .75rem; border-top: 1px solid var(--rcmdr-border);
      padding-top: .5rem;
    }
    .rcmdr-dialog-preview > summary { cursor: pointer; color: var(--rcmdr-muted); }
    .rcmdr-dialog-presets {
      border-bottom: 1px solid var(--rcmdr-border);
      padding-bottom: .5rem; margin-bottom: .75rem;
    }
    .rcmdr-code-preview {
      position: relative; background: var(--rcmdr-surface-sunken);
      border: 1px solid var(--rcmdr-border); border-radius: var(--rcmdr-radius);
      padding: .5rem .65rem;
    }
    .rcmdr-code-preview pre { margin: 0; white-space: pre-wrap; }
    .rcmdr-code-preview .rcmdr-copy { position: absolute; top: .35rem; right: .35rem; }
    .rcmdr-status-pill {
      display: inline-block; padding: .08rem .45rem; border-radius: 999px;
      font-size: .75rem; font-weight: 600; line-height: 1.4;
    }
    .rcmdr-status-ok { background: var(--rcmdr-ok-bg); color: var(--rcmdr-success); }
    .rcmdr-status-warning { background: var(--rcmdr-warn-bg); color: var(--rcmdr-warning); }
    .rcmdr-status-error { background: var(--rcmdr-err-bg); color: var(--rcmdr-danger); }
    .rcmdr-status-muted { background: var(--rcmdr-surface-muted); color: var(--rcmdr-muted); }
    .rcmdr-empty {
      border: 1px dashed var(--rcmdr-border); border-radius: var(--rcmdr-radius);
      padding: 1.25rem; text-align: center; color: var(--rcmdr-muted);
      background: var(--rcmdr-surface);
    }
    .rcmdr-empty-title { font-weight: 600; color: var(--rcmdr-text); }
    .rcmdr-empty-text { margin: .35rem 0 0; }
    .rcmdr-metric {
      background: var(--rcmdr-surface); border: 1px solid var(--rcmdr-border);
      border-radius: var(--rcmdr-radius); padding: .85rem 1rem;
    }
    .rcmdr-metric-label { font-size: .78rem; text-transform: uppercase;
      letter-spacing: .04em; color: var(--rcmdr-muted); }
    .rcmdr-metric-value { font-size: 1.35rem; font-weight: 600; }
    .rcmdr-metric-help { font-size: .82rem; color: var(--rcmdr-muted); }
    .rcmdr-section-card {
      background: var(--rcmdr-surface); border: 1px solid var(--rcmdr-border);
      border-radius: var(--rcmdr-radius); padding: .65rem .85rem;
      margin-bottom: var(--rcmdr-space);
    }
    .rcmdr-section-card > summary { cursor: pointer; font-weight: 600; }
    .rcmdr-section-body { padding-top: .5rem; }
    .rcmdr-field-grid {
      display: grid; gap: .55rem .9rem; align-items: start;
      grid-template-columns: repeat(auto-fill, minmax(11rem, 1fr));
    }
    .rcmdr-field-grid > .form-group,
    .rcmdr-field-grid > .shiny-input-container,
    .rcmdr-field-grid > .shiny-bound-input,
    .rcmdr-field-grid > .form-check { margin-bottom: 0; min-width: 0; }
    .rcmdr-field-grid > .shiny-html-output { display: contents; }
    .rcmdr-field-grid .shiny-input-container,
    .rcmdr-field-grid .form-control,
    .rcmdr-field-grid .form-select { width: 100%; }
    .rcmdr-field-grid > .form-text { grid-column: 1 / -1; }
    .rcmdr-field-grid .rcmdr-field-wide { grid-column: 1 / -1; }
    .rcmdr-field-grid .rcmdr-field-half { grid-column: span 2; }
    .rcmdr-field-grid .form-check { min-height: 0; }
    /* A dialog body is a flat list of fields: lay it out in columns. Only real
       inputs take a cell; headings, help text, previews and any other block
       keep the full width, so unusual dialogs cannot be squeezed. */
    .rcmdr-dialog-grid > * { grid-column: 1 / -1; }
    .rcmdr-dialog-grid > .form-group,
    .rcmdr-dialog-grid > .shiny-input-container { grid-column: auto; }
    .rcmdr-dialog-grid > .shiny-input-radiogroup,
    .rcmdr-dialog-grid > .shiny-input-checkboxgroup { grid-column: span 2; }
    .rcmdr-dialog-grid > .rcmdr-field-wide { grid-column: 1 / -1; }
    .rcmdr-breadcrumb { margin-bottom: .5rem; }
    .rcmdr-home-hero {
      background: linear-gradient(135deg, var(--rcmdr-primary) 0%, var(--rcmdr-accent) 100%);
      color: var(--rcmdr-on-primary); border-radius: var(--rcmdr-radius);
      padding: 1.4rem 1.6rem; margin-bottom: var(--rcmdr-space);
    }
    .rcmdr-home-hero h2 { font-size: 1.65rem; margin-bottom: .25rem; }
    .rcmdr-home-hero p { color: var(--rcmdr-on-primary-muted); margin-bottom: 1rem; }
    .rcmdr-home-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: var(--rcmdr-space); }
    .rcmdr-home-card {
      background: var(--rcmdr-surface); border: 1px solid var(--rcmdr-border);
      border-radius: var(--rcmdr-radius); padding: .85rem 1rem;
    }
    .rcmdr-home-card h5 { font-size: 1rem; margin-bottom: .5rem; }
    .rcmdr-history-card {
      background: var(--rcmdr-surface); border: 1px solid var(--rcmdr-border);
      border-radius: var(--rcmdr-radius); padding: .6rem .75rem;
      margin-bottom: .6rem;
    }
    .rcmdr-history-head { display: flex; gap: .5rem; align-items: center; flex-wrap: wrap; }
    .rcmdr-history-source, .rcmdr-history-time {
      font-size: .78rem; color: var(--rcmdr-muted);
    }
    .rcmdr-history-command {
      margin: .5rem 0 .25rem; padding: .45rem .55rem;
      background: var(--rcmdr-surface-muted); border-radius: .35rem;
      white-space: pre-wrap; font-size: .86rem;
    }
    .rcmdr-history-output pre, .rcmdr-history-messages pre {
      max-height: 18rem; overflow: auto; font-size: .84rem;
    }
    .rcmdr-palette .form-group { margin-bottom: .35rem; }
    .rcmdr-palette-hint { color: var(--rcmdr-muted); font-size: .78rem; margin-bottom: .5rem; }
    .rcmdr-palette-results { max-height: 55vh; overflow-y: auto; }
    .rcmdr-palette-result {
      display: grid; grid-template-columns: minmax(0, 1fr) auto;
      gap: .1rem .6rem; width: 100%; text-align: left;
      background: transparent; border: 1px solid transparent;
      border-radius: var(--rcmdr-radius); padding: .45rem .6rem;
      color: var(--rcmdr-text);
    }
    .rcmdr-palette-result:hover, .rcmdr-palette-result.active {
      background: var(--rcmdr-surface-muted); border-color: var(--rcmdr-border);
    }
    .rcmdr-palette-result.disabled { opacity: .55; cursor: not-allowed; }
    .rcmdr-palette-label { font-weight: 600; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .rcmdr-palette-type {
      font-size: .7rem; text-transform: uppercase; letter-spacing: .04em;
      color: var(--rcmdr-muted);
    }
    .rcmdr-palette-path { grid-column: 1 / -1; font-size: .78rem; color: var(--rcmdr-muted); }
    .rcmdr-palette-reason { grid-column: 1 / -1; font-size: .78rem; color: var(--rcmdr-warning); }
    .rcmdr-palette-result { cursor: pointer; }
    .rcmdr-palette-result:focus-visible {
      outline: 2px solid var(--rcmdr-focus, var(--rcmdr-accent)); outline-offset: 2px;
    }
    .rcmdr-palette-main {
      display: grid; grid-template-columns: auto minmax(0, 1fr);
      gap: .1rem .55rem; align-items: baseline; min-width: 0;
    }
    .rcmdr-palette-main .rcmdr-palette-label { grid-column: 2; }
    .rcmdr-palette-main .rcmdr-palette-path,
    .rcmdr-palette-main .rcmdr-palette-reason { grid-column: 1 / -1; }
    .rcmdr-palette-actions {
      display: flex; gap: .25rem; flex-wrap: wrap; justify-content: flex-end;
      align-items: center;
    }
    .rcmdr-palette-filters { margin-bottom: .35rem; }
    .rcmdr-menu-row { display: flex; align-items: center; gap: .2rem; }
    .rcmdr-menu-row .rcmdr-menu-item { flex: 1 1 auto; min-width: 0; }
    .rcmdr-menu-star {
      border: 0; background: transparent; padding: 0 .15rem;
      color: var(--rcmdr-muted); line-height: 1;
    }
    .rcmdr-menu-star.active { color: var(--rcmdr-warning); }
    .rcmdr-menu-shortcuts { margin-bottom: .5rem; }
    .rcmdr-menu-shortcut-group > summary { font-weight: 600; }
    .rcmdr-menu-mark { padding: 0 .05rem; background: var(--rcmdr-mark-bg); color: inherit; }
    .rcmdr-menu-actions { margin: .25rem 0 .5rem; }
    .rcmdr-dialog-errors { margin-bottom: .75rem; }
    .rcmdr-dialog-errors ul { padding-left: 1.1rem; }
    .rcmdr-dialog-errors a { color: inherit; text-decoration: underline; }
    .rcmdr-workflow-panel { margin-bottom: var(--rcmdr-space); }
    .rcmdr-workflow-grid {
      display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: var(--rcmdr-space);
    }
    .rcmdr-workflow-card {
      background: var(--rcmdr-surface); border: 1px solid var(--rcmdr-border);
      border-radius: var(--rcmdr-radius); padding: .85rem 1rem;
    }
    .rcmdr-workflow-card h6 { margin-bottom: .35rem; }
    .rcmdr-workflow-steps { display: flex; flex-direction: column; gap: .5rem; }
    .rcmdr-workflow-step {
      background: var(--rcmdr-surface); border: 1px solid var(--rcmdr-border);
      border-radius: var(--rcmdr-radius); padding: .55rem .7rem;
    }
    .rcmdr-workflow-step.current {
      border-color: var(--rcmdr-accent); box-shadow: 0 0 0 2px rgba(47, 93, 138, .18);
    }
    .rcmdr-workflow-draft pre {
      max-height: 16rem; overflow: auto; font-size: .82rem;
      background: var(--rcmdr-surface-muted); padding: .6rem;
      border-radius: var(--rcmdr-radius);
    }
    .rcmdr-variable-suggestions {
      border-top: 1px dashed var(--rcmdr-border); margin-top: .65rem;
      padding-top: .65rem;
    }
    .rcmdr-variable-suggestions h6 { font-size: .85rem; }
    .modal-dialog { max-height: 94vh; }
    .modal-body { overflow-y: auto; max-height: 72vh; }
    .modal-footer { flex-wrap: wrap; gap: .35rem; }
    /* Dialogs are draggable by their header (see app_js()). */
    .modal-header { cursor: grab; touch-action: none; }
    body.rcmdr-dragging { user-select: none; }
    body.rcmdr-dragging .modal-header { cursor: grabbing; }
    .rcmdr-shortcuts-table td, .rcmdr-shortcuts-table th { vertical-align: middle; }
    @media (max-width: 991.98px) {
      .rcmdr-sidebar { max-height: 46vh; overflow-y: auto; }
      .modal-dialog { margin: .4rem; }
      .modal-body { max-height: 66vh; }
    }
    .rcmdr-console-input { display: flex; gap: .5rem; align-items: flex-start; }
    .rcmdr-console-input .form-group { flex: 1; margin-bottom: 0; }
    .rcmdr-console-note { color: var(--rcmdr-muted); font-size: .8rem; margin: .5rem 0; }
    .dataTable tbody tr.rcmdr-row-selected td { background-color: var(--rcmdr-selection) !important; }
    .dataTable tbody tr { cursor: pointer; }
    .rcmdr-selection-bar {
      display: flex; align-items: center; gap: .5rem;
      margin-top: .75rem; padding: .45rem .6rem;
      background: var(--rcmdr-surface-muted);
      border: 1px solid var(--rcmdr-border);
      border-radius: var(--rcmdr-radius);
    }
    .rcmdr-selection-bar .btn-link { padding: 0; }
    .rcmdr-menu-search { margin-bottom: .6rem; }
    .rcmdr-menu-search .form-group { margin-bottom: 0; }
    .rcmdr-menu-flat-path { font-size: .72rem; color: var(--rcmdr-muted); display: block; }
    /* Design tokens -------------------------------------------------------
       Every surface, border and text colour in the Studio resolves to these
       variables.  Each palette below keeps body text at >= 4.5:1 against its
       surface and muted text at >= 4.5:1 as well, so no variant is ever
       dark-on-dark or light-on-light. */
    :root,
    body.rcmdr-light {
      color-scheme: light;
      --rcmdr-bg: #f4f6fa;
      --rcmdr-surface: #ffffff;
      --rcmdr-surface-muted: #eef1f6;
      --rcmdr-surface-sunken: #f7f9fc;
      --rcmdr-text: #16202b;
      --rcmdr-heading: #0f2b45;
      --rcmdr-link: #17486f;
      --rcmdr-muted: #47566a;
      --rcmdr-disabled: #7b8794;
      --rcmdr-border: #bcc8d6;
      --rcmdr-primary: #1f3a5f;
      --rcmdr-on-primary: #ffffff;
      --rcmdr-on-primary-muted: #d9e5f2;
      --rcmdr-accent: #0b5ed7;
      --rcmdr-hover: #e4edf8;
      --rcmdr-selection: #d6e6fa;
      --rcmdr-mark-bg: #ffe9a8;
      --rcmdr-mark-text: #3a2a00;
      --rcmdr-hero-from: #1f3a5f;
      --rcmdr-hero-to: #2f5d8a;
      --rcmdr-ok-bg: #dcfae6;
      --rcmdr-ok-fg: #05603a;
      --rcmdr-warn-bg: #fef0c7;
      --rcmdr-warn-fg: #8a4b00;
      --rcmdr-err-bg: #fee4e2;
      --rcmdr-err-fg: #a1120b;
      --rcmdr-danger: #b02a37;
      --rcmdr-warning: #b54708;
      --rcmdr-success: #067647;
      --rcmdr-shadow: 0 .6rem 1.4rem rgba(16, 32, 51, .18);
      --rcmdr-focus-ring: 0 0 0 2px rgba(11, 94, 215, .28);
    }
    :root {
      --rcmdr-radius: .5rem;
      --rcmdr-space: .75rem;
      --rcmdr-font-size: 1rem;
    }
    body.rcmdr-light-warm {
      color-scheme: light;
      --rcmdr-bg: #f7f2e9;
      --rcmdr-surface: #fffdf7;
      --rcmdr-surface-muted: #f0e7d7;
      --rcmdr-surface-sunken: #f9f4ea;
      --rcmdr-text: #26211a;
      --rcmdr-heading: #3d2f18;
      --rcmdr-link: #6a4a12;
      --rcmdr-muted: #5a4e3c;
      --rcmdr-disabled: #857a66;
      --rcmdr-border: #cdb999;
      --rcmdr-primary: #47391f;
      --rcmdr-on-primary: #ffffff;
      --rcmdr-on-primary-muted: #eedfca;
      --rcmdr-accent: #8a5a00;
      --rcmdr-hover: #ece0cb;
      --rcmdr-selection: #f2e0ba;
      --rcmdr-mark-bg: #ffe08a;
      --rcmdr-mark-text: #3a2a00;
      --rcmdr-hero-from: #4a3a1f;
      --rcmdr-hero-to: #7a5a28;
      --rcmdr-ok-bg: #e3f3d9;
      --rcmdr-ok-fg: #2c5a10;
      --rcmdr-warn-bg: #fbeac2;
      --rcmdr-warn-fg: #7a4400;
      --rcmdr-err-bg: #fbe0d8;
      --rcmdr-err-fg: #8d1f10;
      --rcmdr-danger: #a01f14;
      --rcmdr-warning: #8a4b00;
      --rcmdr-success: #2c5a10;
      --rcmdr-shadow: 0 .6rem 1.4rem rgba(61, 47, 24, .2);
      --rcmdr-focus-ring: 0 0 0 2px rgba(138, 90, 0, .3);
    }
    body.rcmdr-light-cool {
      color-scheme: light;
      --rcmdr-bg: #e9f0f8;
      --rcmdr-surface: #fbfdff;
      --rcmdr-surface-muted: #dfe9f4;
      --rcmdr-surface-sunken: #f1f6fc;
      --rcmdr-text: #131e2b;
      --rcmdr-heading: #0d2c48;
      --rcmdr-link: #10527f;
      --rcmdr-muted: #3f5468;
      --rcmdr-disabled: #77889a;
      --rcmdr-border: #b0c3d8;
      --rcmdr-primary: #123a5e;
      --rcmdr-on-primary: #ffffff;
      --rcmdr-on-primary-muted: #d2e3f3;
      --rcmdr-accent: #0a58ca;
      --rcmdr-hover: #d8e7f7;
      --rcmdr-selection: #c9ddf6;
      --rcmdr-mark-bg: #ffe9a8;
      --rcmdr-mark-text: #3a2a00;
      --rcmdr-hero-from: #123a5e;
      --rcmdr-hero-to: #276c9f;
      --rcmdr-ok-bg: #d8f2e6;
      --rcmdr-ok-fg: #05563a;
      --rcmdr-warn-bg: #fdeec6;
      --rcmdr-warn-fg: #834700;
      --rcmdr-err-bg: #fde2e2;
      --rcmdr-err-fg: #9c1414;
      --rcmdr-danger: #a01f2b;
      --rcmdr-warning: #834700;
      --rcmdr-success: #05563a;
      --rcmdr-shadow: 0 .6rem 1.4rem rgba(13, 44, 72, .18);
      --rcmdr-focus-ring: 0 0 0 2px rgba(10, 88, 202, .28);
    }
    body.rcmdr-dark {
      color-scheme: dark;
      --rcmdr-bg: #0e1621;
      --rcmdr-surface: #19222f;
      --rcmdr-surface-muted: #222d3c;
      --rcmdr-surface-sunken: #121a25;
      --rcmdr-text: #e9eff7;
      --rcmdr-heading: #ffffff;
      --rcmdr-link: #a9cff7;
      --rcmdr-muted: #b4c2d3;
      --rcmdr-disabled: #8b99ab;
      --rcmdr-border: #3a4757;
      --rcmdr-primary: #234870;
      --rcmdr-on-primary: #ffffff;
      --rcmdr-on-primary-muted: #d9e7f6;
      --rcmdr-accent: #78b9ff;
      --rcmdr-hover: #29394a;
      --rcmdr-selection: #2f4a68;
      --rcmdr-mark-bg: #f7d774;
      --rcmdr-mark-text: #241b00;
      --rcmdr-hero-from: #17293f;
      --rcmdr-hero-to: #23486f;
      --rcmdr-ok-bg: #0b3d2c;
      --rcmdr-ok-fg: #a7f3d0;
      --rcmdr-warn-bg: #40290a;
      --rcmdr-warn-fg: #fde68a;
      --rcmdr-err-bg: #45100d;
      --rcmdr-err-fg: #fecaca;
      --rcmdr-danger: #ff9b93;
      --rcmdr-warning: #f7c76b;
      --rcmdr-success: #86e6b6;
      --rcmdr-shadow: 0 .6rem 1.6rem rgba(0, 0, 0, .55);
      --rcmdr-focus-ring: 0 0 0 2px rgba(120, 185, 255, .45);
    }
    body.rcmdr-dark-dim {
      color-scheme: dark;
      --rcmdr-bg: #191c20;
      --rcmdr-surface: #23272c;
      --rcmdr-surface-muted: #2c3137;
      --rcmdr-surface-sunken: #1e2126;
      --rcmdr-text: #eef1f5;
      --rcmdr-heading: #ffffff;
      --rcmdr-link: #b9d5f2;
      --rcmdr-muted: #c2c9d2;
      --rcmdr-disabled: #949ca6;
      --rcmdr-border: #454b52;
      --rcmdr-primary: #33475e;
      --rcmdr-on-primary: #ffffff;
      --rcmdr-on-primary-muted: #dbe4ef;
      --rcmdr-accent: #93c1f5;
      --rcmdr-hover: #333941;
      --rcmdr-selection: #3b4a5c;
      --rcmdr-mark-bg: #f2d17a;
      --rcmdr-mark-text: #241b00;
      --rcmdr-hero-from: #262c33;
      --rcmdr-hero-to: #38424d;
      --rcmdr-ok-bg: #1d3b2c;
      --rcmdr-ok-fg: #b3f0d2;
      --rcmdr-warn-bg: #3d2e12;
      --rcmdr-warn-fg: #f8dd9a;
      --rcmdr-err-bg: #401c1c;
      --rcmdr-err-fg: #f8c9c9;
      --rcmdr-danger: #ffa8a0;
      --rcmdr-warning: #f5c881;
      --rcmdr-success: #9ae9c1;
      --rcmdr-shadow: 0 .6rem 1.6rem rgba(0, 0, 0, .5);
      --rcmdr-focus-ring: 0 0 0 2px rgba(147, 193, 245, .45);
    }
    body.rcmdr-dark-graphite {
      color-scheme: dark;
      --rcmdr-bg: #141618;
      --rcmdr-surface: #1e2124;
      --rcmdr-surface-muted: #272b2f;
      --rcmdr-surface-sunken: #191c1e;
      --rcmdr-text: #eceff2;
      --rcmdr-heading: #ffffff;
      --rcmdr-link: #a8deda;
      --rcmdr-muted: #c1c7cd;
      --rcmdr-disabled: #8f979e;
      --rcmdr-border: #3e4348;
      --rcmdr-primary: #2f3a3d;
      --rcmdr-on-primary: #ffffff;
      --rcmdr-on-primary-muted: #d8e2e3;
      --rcmdr-accent: #7fd8c9;
      --rcmdr-hover: #30363a;
      --rcmdr-selection: #35474a;
      --rcmdr-mark-bg: #f0d47a;
      --rcmdr-mark-text: #241b00;
      --rcmdr-hero-from: #222a2c;
      --rcmdr-hero-to: #33474a;
      --rcmdr-ok-bg: #1b3a32;
      --rcmdr-ok-fg: #b0efdd;
      --rcmdr-warn-bg: #3a2d12;
      --rcmdr-warn-fg: #f6dda0;
      --rcmdr-err-bg: #3d1c1b;
      --rcmdr-err-fg: #f8c9c4;
      --rcmdr-danger: #ffaaa2;
      --rcmdr-warning: #f3ca85;
      --rcmdr-success: #98e8c8;
      --rcmdr-shadow: 0 .6rem 1.6rem rgba(0, 0, 0, .5);
      --rcmdr-focus-ring: 0 0 0 2px rgba(127, 216, 201, .45);
    }
    body.rcmdr-contrast {
      color-scheme: light;
      --rcmdr-bg: #ffffff;
      --rcmdr-surface: #ffffff;
      --rcmdr-surface-muted: #f2f2f2;
      --rcmdr-surface-sunken: #f5f5f5;
      --rcmdr-text: #000000;
      --rcmdr-heading: #000000;
      --rcmdr-link: #0033cc;
      --rcmdr-muted: #1f1f1f;
      --rcmdr-disabled: #4a4a4a;
      --rcmdr-border: #000000;
      --rcmdr-primary: #000000;
      --rcmdr-on-primary: #ffffff;
      --rcmdr-on-primary-muted: #ffffff;
      --rcmdr-accent: #0047ff;
      --rcmdr-hover: #e6e6e6;
      --rcmdr-selection: #cfe0ff;
      --rcmdr-mark-bg: #ffe066;
      --rcmdr-mark-text: #000000;
      --rcmdr-hero-from: #000000;
      --rcmdr-hero-to: #000000;
      --rcmdr-ok-bg: #d6f5e3;
      --rcmdr-ok-fg: #003d23;
      --rcmdr-warn-bg: #ffeec2;
      --rcmdr-warn-fg: #5c3100;
      --rcmdr-err-bg: #ffd9d5;
      --rcmdr-err-fg: #7a0000;
      --rcmdr-danger: #b00020;
      --rcmdr-warning: #6b3b00;
      --rcmdr-success: #005c33;
      --rcmdr-shadow: 0 .5rem 1.2rem rgba(0, 0, 0, .35);
      --rcmdr-focus-ring: 0 0 0 3px rgba(0, 71, 255, .45);
    }
    body {
      background: var(--rcmdr-bg);
      color: var(--rcmdr-text);
    }
    body.rcmdr-dark .rcmdr-topbar,
    body.rcmdr-dark .rcmdr-home-hero { border-bottom: 1px solid var(--rcmdr-border); }

    /* Bootstrap widgets follow the palette ------------------------------- */
    body .form-control,
    body .form-select,
    body .form-check-input,
    body .input-group-text {
      background-color: var(--rcmdr-surface);
      color: var(--rcmdr-text);
      border-color: var(--rcmdr-border);
    }
    .form-text, .help-block { color: var(--rcmdr-muted); }
    .text-success { color: var(--rcmdr-success); }
    .text-danger { color: var(--rcmdr-danger); }
    .rcmdr-topbar .text-success { color: #7ee2a8; }
    .rcmdr-topbar .text-danger { color: #ffb3ad; }
    .form-control::placeholder { color: var(--rcmdr-muted); opacity: 1; }
    body.rcmdr-dark .form-control::placeholder { color: var(--rcmdr-disabled); }
    /* selectize ships its own white stylesheet, so these need to outrank it. */
    body .selectize-control .selectize-input,
    body .selectize-control .selectize-input.focus,
    body .selectize-control .selectize-input.full,
    body .selectize-control .selectize-input.input-active,
    body .selectize-control .selectize-input.active,
    body .selectize-control .selectize-input.dropdown-active,
    body .selectize-control .selectize-dropdown {
      background-color: var(--rcmdr-surface);
      color: var(--rcmdr-text);
      border-color: var(--rcmdr-border);
    }
    body .selectize-control .selectize-input.focus { box-shadow: var(--rcmdr-focus-ring); }
    body .selectize-control .selectize-input input,
    body .selectize-control.single .selectize-input .item,
    body .selectize-control .selectize-dropdown .option,
    body .selectize-control .selectize-dropdown .optgroup-header { color: var(--rcmdr-text); }
    body .selectize-control .selectize-dropdown .optgroup-header {
      background: var(--rcmdr-surface-muted);
      color: var(--rcmdr-muted);
      font-size: .78rem;
      text-transform: uppercase;
      letter-spacing: .04em;
    }
    body .selectize-control .selectize-dropdown .option.active,
    body .selectize-control .selectize-dropdown .option:hover {
      background: var(--rcmdr-hover); color: var(--rcmdr-heading);
    }
    body .selectize-control.single .selectize-input:after {
      border-color: var(--rcmdr-text) transparent transparent transparent;
    }
    body .selectize-control.multi .selectize-input > div {
      background: var(--rcmdr-surface-muted); color: var(--rcmdr-text);
      border-color: var(--rcmdr-border);
    }
    .card,
    .card-header,
    .card-footer,
    .list-group-item,
    .accordion-item,
    .modal-content,
    .modal-header,
    .modal-footer,
    .dropdown-menu {
      background-color: var(--rcmdr-surface);
      color: var(--rcmdr-text);
      border-color: var(--rcmdr-border);
    }
    .card-header, .card-footer, .modal-header, .modal-footer {
      background-color: var(--rcmdr-surface-muted);
    }
    .dropdown-item { color: var(--rcmdr-text); }
    .dropdown-item:hover,
    .dropdown-item:focus { background: var(--rcmdr-hover); color: var(--rcmdr-heading); }
    .nav-tabs { border-color: var(--rcmdr-border); }
    .nav-tabs .nav-link { color: var(--rcmdr-link); }
    .nav-tabs .nav-link:hover { border-color: var(--rcmdr-border); background: var(--rcmdr-hover); }
    .nav-tabs .nav-link.active {
      background: var(--rcmdr-surface); color: var(--rcmdr-text);
      border-color: var(--rcmdr-border) var(--rcmdr-border) var(--rcmdr-surface);
    }
    /* The main views are windows on the workspace, not a second menu: a
       segmented control keeps them visually distinct from the menubar. */
    #main_tabs.nav-tabs {
      display: inline-flex; flex-wrap: wrap; gap: .1rem;
      padding: .15rem; margin-bottom: var(--rcmdr-space);
      border: 1px solid var(--rcmdr-border); border-radius: var(--rcmdr-radius);
      background: var(--rcmdr-surface-muted);
    }
    #main_tabs .nav-link {
      border: 0; border-radius: .3rem; padding: .22rem .55rem;
      font-size: .86rem; color: var(--rcmdr-muted);
    }
    #main_tabs .nav-link:hover {
      background: var(--rcmdr-hover); color: var(--rcmdr-heading);
    }
    #main_tabs .nav-link.active {
      background: var(--rcmdr-surface); color: var(--rcmdr-heading);
      font-weight: 600; box-shadow: 0 1px 2px rgba(0, 0, 0, .12);
    }
    .rcmdr-result-hint {
      display: flex; align-items: center; justify-content: space-between;
      gap: .75rem; flex-wrap: wrap;
      padding: .4rem .75rem; margin-bottom: var(--rcmdr-space);
      background: var(--rcmdr-surface); color: var(--rcmdr-text);
      border: 1px solid var(--rcmdr-border);
      border-left: .3rem solid var(--rcmdr-accent);
      border-radius: var(--rcmdr-radius);
    }
    .rcmdr-result-hint-text { font-size: .9rem; min-width: 0; }
    .rcmdr-result-hint .form-group,
    .rcmdr-result-hint .form-check { margin-bottom: 0; }
    .rcmdr-result-hint .form-check-label {
      font-size: .85rem; color: var(--rcmdr-muted);
    }
    .breadcrumb { --bs-breadcrumb-divider-color: var(--rcmdr-muted); }
    .breadcrumb-item { color: var(--rcmdr-muted); }
    .breadcrumb-item.active { color: var(--rcmdr-text); }
    .breadcrumb-item a { color: var(--rcmdr-link); }
    .breadcrumb-item + .breadcrumb-item::before { color: var(--rcmdr-muted); }
    .table { color: var(--rcmdr-text); }
    .table > :not(caption) > * > * {
      color: var(--rcmdr-text);
      border-color: var(--rcmdr-border);
      /* Bootstrap paints cells with --bs-table-bg, which stays white in a
         dark palette and hid the cell text. */
      background-color: transparent;
    }
    .table-striped > tbody > tr:nth-of-type(odd) > * {
      color: var(--rcmdr-text);
      background-color: var(--rcmdr-surface-muted);
    }
    .table-hover > tbody > tr:hover > * {
      color: var(--rcmdr-heading);
      background-color: var(--rcmdr-hover);
    }
    body.rcmdr-dark .dataTable tbody tr.rcmdr-row-selected td,
    body.rcmdr-dark .dataTable tbody tr.selected td {
      background-color: var(--rcmdr-selection) !important;
      color: var(--rcmdr-text) !important;
    }
    body.rcmdr-dark .dataTables_wrapper,
    body.rcmdr-dark .dataTables_info,
    body.rcmdr-dark .dataTables_filter label,
    body.rcmdr-dark .dataTables_length label { color: var(--rcmdr-text); }
    body.rcmdr-dark .dataTables_paginate .paginate_button { color: var(--rcmdr-text) !important; }
    body.rcmdr-dark .dataTables_paginate .paginate_button.current {
      background: var(--rcmdr-selection) !important;
      border-color: var(--rcmdr-border) !important;
      color: var(--rcmdr-heading) !important;
    }
    body.rcmdr-dark .modal-header .btn-close { filter: invert(1) grayscale(1) brightness(1.7); }
    body.rcmdr-dark .btn-close { filter: invert(1) grayscale(1) brightness(1.7); }
    body.rcmdr-dark .btn-light,
    body.rcmdr-dark .btn-default,
    body.rcmdr-dark .btn-outline-secondary,
    body.rcmdr-dark .btn-outline-dark {
      background: var(--rcmdr-surface-muted); color: var(--rcmdr-text);
      border-color: var(--rcmdr-border);
    }
    body.rcmdr-dark .btn-light:hover,
    body.rcmdr-dark .btn-default:hover,
    body.rcmdr-dark .btn-outline-secondary:hover,
    body.rcmdr-dark .btn-outline-dark:hover {
      background: var(--rcmdr-hover); color: var(--rcmdr-heading);
    }
    body.rcmdr-dark .btn-link { color: var(--rcmdr-link); }
    body.rcmdr-dark a { color: var(--rcmdr-link); }
    body.rcmdr-dark .dropdown-item.active,
    body.rcmdr-dark .dropdown-item:active { background: var(--rcmdr-selection); color: var(--rcmdr-heading); }
    body.rcmdr-dark .text-muted { color: var(--rcmdr-muted) !important; }
    body.rcmdr-dark .text-dark,
    body.rcmdr-dark .text-body { color: var(--rcmdr-text) !important; }
    body.rcmdr-dark .text-success { color: var(--rcmdr-success) !important; }
    body.rcmdr-dark .text-warning { color: var(--rcmdr-warning) !important; }
    body.rcmdr-dark .text-danger,
    body.rcmdr-dark .text-error { color: var(--rcmdr-danger) !important; }
    body.rcmdr-dark .shiny-output-error,
    body.rcmdr-dark .shiny-output-error-validation,
    body.rcmdr-dark .shiny-output-error-error { color: var(--rcmdr-danger) !important; }
    body.rcmdr-dark .btn-danger {
      background-color: #b42318; border-color: #d92d20; color: #ffffff;
    }
    body.rcmdr-dark .btn-danger:hover { background-color: #d92d20; color: #ffffff; }
    body.rcmdr-dark .btn-outline-danger { color: var(--rcmdr-danger); border-color: var(--rcmdr-danger); }
    body.rcmdr-dark .text-secondary { color: var(--rcmdr-muted) !important; }
    body.rcmdr-dark .bg-white,
    body.rcmdr-dark .bg-light { background-color: var(--rcmdr-surface) !important; }
    body.rcmdr-dark .border,
    body.rcmdr-dark .border-top,
    body.rcmdr-dark .border-bottom,
    body.rcmdr-dark .border-start,
    body.rcmdr-dark .border-end { border-color: var(--rcmdr-border) !important; }
    body.rcmdr-dark .badge.bg-light,
    body.rcmdr-dark .badge.bg-white {
      background: var(--rcmdr-surface-muted) !important;
      color: var(--rcmdr-text) !important;
    }
    body.rcmdr-dark .badge.bg-secondary { background: var(--rcmdr-surface-muted) !important; color: var(--rcmdr-text) !important; }
    body.rcmdr-dark hr { border-color: var(--rcmdr-border); opacity: .7; }
    body.rcmdr-dark pre,
    body.rcmdr-dark code {
      background-color: var(--rcmdr-surface-sunken);
      color: var(--rcmdr-text);
      border-color: var(--rcmdr-border);
    }
    body.rcmdr-dark .shiny-input-container > label,
    body.rcmdr-dark .control-label,
    body.rcmdr-dark legend { color: var(--rcmdr-text); }
    body.rcmdr-dark .rcmdr-topbar .selectize-input,
    body.rcmdr-dark .rcmdr-topbar .form-select {
      background: var(--rcmdr-surface);
      color: var(--rcmdr-text);
      border-color: var(--rcmdr-border);
    }

    /* Search highlights stay readable on every palette ------------------- */
    .rcmdr-menu-mark,
    .rcmdr-help-result-snippet mark {
      background: var(--rcmdr-mark-bg);
      color: var(--rcmdr-mark-text);
      padding: 0 .12rem;
      border-radius: .15rem;
    }
    .rcmdr-menu-item.disabled,
    .rcmdr-palette-result.disabled { color: var(--rcmdr-disabled); }
    .rcmdr-status-ok { background: var(--rcmdr-ok-bg); color: var(--rcmdr-ok-fg); }
    .rcmdr-status-warning { background: var(--rcmdr-warn-bg); color: var(--rcmdr-warn-fg); }
    .rcmdr-status-error { background: var(--rcmdr-err-bg); color: var(--rcmdr-err-fg); }
    .rcmdr-status-muted { background: var(--rcmdr-surface-muted); color: var(--rcmdr-muted); }
    body.rcmdr-dark .rcmdr-status-ok { background: var(--rcmdr-ok-bg); color: var(--rcmdr-ok-fg); }
    body.rcmdr-dark .rcmdr-status-warning { background: var(--rcmdr-warn-bg); color: var(--rcmdr-warn-fg); }
    body.rcmdr-dark .rcmdr-status-error { background: var(--rcmdr-err-bg); color: var(--rcmdr-err-fg); }
    body.rcmdr-dark .rcmdr-status-muted { background: var(--rcmdr-surface-muted); color: var(--rcmdr-muted); }
    .rcmdr-home-hero {
      background: linear-gradient(135deg, var(--rcmdr-hero-from) 0%, var(--rcmdr-hero-to) 100%);
      color: var(--rcmdr-on-primary);
    }
    .rcmdr-home-hero p { color: var(--rcmdr-on-primary-muted); }
    .rcmdr-code-preview,
    .rcmdr-report-source { background: var(--rcmdr-surface-sunken); }
    .rcmdr-cell-output pre,
    .rcmdr-help-body pre,
    .rcmdr-help-example-code,
    .rcmdr-workflow-draft pre { background: var(--rcmdr-surface-sunken); color: var(--rcmdr-text); }
    .rcmdr-doc-tab { color: var(--rcmdr-text); }
    .rcmdr-doc-tab a,
    .rcmdr-help-category,
    .rcmdr-report-outline a { color: var(--rcmdr-link); }
    .rcmdr-doc-tab .rcmdr-doc-mode,
    .rcmdr-doc-tab .rcmdr-doc-close,
    .rcmdr-doc-tab .rcmdr-doc-new { color: var(--rcmdr-muted); }
    :focus-visible { outline-color: var(--rcmdr-accent); }

    @media (prefers-reduced-motion: reduce) {
      *, *::before, *::after {
        animation-duration: .01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: .01ms !important;
        scroll-behavior: auto !important;
      }
    }
    "
  )
}

app_js <- function(lang = current_language()) {
  htmltools::HTML(
    paste0(
    "document.documentElement.lang = '", lang, "';\n",
    "Shiny.addCustomMessageHandler('rcmdr-click', function(id) {
      var el = document.getElementById(id);
      if (el) el.click();
    });
    Shiny.addCustomMessageHandler('rcmdr-tab', function(message) {
      // The server sends {tab, sub} with stable view ids; a plain string is
      // still accepted for older callers.
      var target = (typeof message === 'string') ? { tab: message } : (message || {});
      var bar = document.getElementById('main_tabs');
      if (!bar) return;
      var link = target.tab
        ? bar.querySelector('.nav-link[data-value=\"' + target.tab + '\"]')
        : null;
      if (!link) {
        link = Array.from(bar.querySelectorAll('.nav-link')).find(function(a) {
          return a.textContent.trim() === target.tab;
        });
      }
      if (!link) return;
      link.click();
      if (!target.sub) return;
      var href = link.getAttribute('href');
      var pane = href ? document.querySelector(href) : null;
      var sub = pane
        ? pane.querySelector('.nav-link[data-value=\"' + target.sub + '\"]')
        : null;
      if (sub) sub.click();
    });
    Shiny.addCustomMessageHandler('rcmdr-focus', function(id) {
      var el = document.getElementById(id);
      if (el) el.focus();
    });
    // Modal dialogs can be moved by dragging their header. Bootstrap 5 does not
    // ship a draggable modal any more, and the statistical dialogs are wide
    // enough that the data underneath is worth looking at while the dialog is
    // open. The offset is a transform, so Bootstrap keeps its own centring and
    // the dialog never leaves the window completely.
    (function () {
      var drag = null;

      function offsets(dialog) {
        var x = parseFloat(dialog.getAttribute('data-rcmdr-x'));
        var y = parseFloat(dialog.getAttribute('data-rcmdr-y'));
        return {
          x: isNaN(x) ? 0 : x,
          y: isNaN(y) ? 0 : y
        };
      }

      function place(dialog, x, y) {
        dialog.setAttribute('data-rcmdr-x', x);
        dialog.setAttribute('data-rcmdr-y', y);
        dialog.style.transform = 'translate(' + x + 'px,' + y + 'px)';
      }

      function reset(dialog) {
        dialog.style.transform = '';
        dialog.removeAttribute('data-rcmdr-x');
        dialog.removeAttribute('data-rcmdr-y');
      }

      function bounds(dialog, base) {
        var width = dialog.offsetWidth;
        return {
          minX: 40 - base.left - width,
          maxX: window.innerWidth - base.left - 40,
          minY: -base.top,
          maxY: window.innerHeight - base.top - 56
        };
      }

      function nearest(value, low, high) {
        if (low > high) {
          var swap = low;
          low = high;
          high = swap;
        }
        return Math.min(Math.max(value, low), high);
      }

      function baseOf(dialog, current) {
        var rect = dialog.getBoundingClientRect();
        return {
          left: rect.left - current.x,
          top: rect.top - current.y
        };
      }

      function interactive(target) {
        if (!target || !target.closest) return false;
        return !!target.closest(
          'button, a, input, select, textarea, label, [role=button], ' +
          '[data-bs-dismiss]'
        );
      }

      document.addEventListener('pointerdown', function (event) {
        if (event.button !== 0 || drag) return;
        var header = event.target.closest && event.target.closest('.modal-header');
        if (!header || interactive(event.target)) return;
        var dialog = header.closest('.modal-dialog');
        if (!dialog) return;
        var current = offsets(dialog);
        drag = {
          dialog: dialog,
          id: event.pointerId,
          startX: event.clientX,
          startY: event.clientY,
          from: current,
          base: baseOf(dialog, current)
        };
        if (header.setPointerCapture) {
          try { header.setPointerCapture(event.pointerId); } catch (e) {}
        }
        document.body.classList.add('rcmdr-dragging');
        event.preventDefault();
      });

      document.addEventListener('pointermove', function (event) {
        if (!drag || event.pointerId !== drag.id) return;
        var limit = bounds(drag.dialog, drag.base);
        var x = nearest(
          drag.from.x + (event.clientX - drag.startX), limit.minX, limit.maxX
        );
        var y = nearest(
          drag.from.y + (event.clientY - drag.startY), limit.minY, limit.maxY
        );
        place(drag.dialog, Math.round(x), Math.round(y));
        event.preventDefault();
      });

      function stop(event) {
        if (!drag) return;
        if (event && event.pointerId !== undefined && event.pointerId !== drag.id) {
          return;
        }
        drag = null;
        document.body.classList.remove('rcmdr-dragging');
      }

      document.addEventListener('pointerup', stop);
      document.addEventListener('pointercancel', stop);

      // Double click on the header puts the dialog back where it opened.
      document.addEventListener('dblclick', function (event) {
        var header = event.target.closest && event.target.closest('.modal-header');
        if (!header || interactive(event.target)) return;
        var dialog = header.closest('.modal-dialog');
        if (dialog) reset(dialog);
      });

      // Keep the header reachable when the window is resized.
      window.addEventListener('resize', function () {
        Array.prototype.forEach.call(
          document.querySelectorAll('.modal-dialog[data-rcmdr-x]'),
          function (dialog) {
            var current = offsets(dialog);
            var limit = bounds(dialog, baseOf(dialog, current));
            place(
              dialog,
              Math.round(nearest(current.x, limit.minX, limit.maxX)),
              Math.round(nearest(current.y, limit.minY, limit.maxY))
            );
          }
        );
      });
    })();
    function rcmdrThemeClasses(theme) {
      if (theme === 'system') {
        var prefersDark = window.matchMedia &&
          window.matchMedia('(prefers-color-scheme: dark)').matches;
        theme = prefersDark ? 'dark' : 'light';
      }
      if (theme === 'dark-dim') return ['rcmdr-dark', 'rcmdr-dark-dim'];
      if (theme === 'dark-graphite') return ['rcmdr-dark', 'rcmdr-dark-graphite'];
      if (theme === 'dark') return ['rcmdr-dark'];
      if (theme === 'contrast') return ['rcmdr-contrast'];
      if (theme === 'light-warm') return ['rcmdr-light-warm'];
      if (theme === 'light-cool') return ['rcmdr-light-cool'];
      return ['rcmdr-light'];
    }
    var rcmdrThemeChoice = 'system';
    function rcmdrApplyTheme(theme) {
      var body = document.body;
      if (!body) return;
      if (typeof theme !== 'string' || !theme) theme = 'system';
      rcmdrThemeChoice = theme;
      body.classList.remove('rcmdr-dark', 'rcmdr-dark-dim',
        'rcmdr-dark-graphite', 'rcmdr-light', 'rcmdr-light-warm',
        'rcmdr-light-cool', 'rcmdr-contrast');
      rcmdrThemeClasses(theme).forEach(function(name) {
        body.classList.add(name);
      });
      body.setAttribute('data-rcmdr-theme', theme);
      try { window.localStorage.setItem('rcmdr-theme', theme); } catch (e) {}
    }
    function rcmdrApplyDensity(density) {
      var body = document.body;
      if (!body) return;
      var comfortable = density === 'comfortable';
      body.classList.toggle('rcmdr-density-comfortable', comfortable);
      body.classList.toggle('rcmdr-density-compact', !comfortable);
      body.setAttribute('data-rcmdr-density',
                        comfortable ? 'comfortable' : 'compact');
      try {
        window.localStorage.setItem('rcmdr-density',
                                    comfortable ? 'comfortable' : 'compact');
      } catch (e) {}
    }
    Shiny.addCustomMessageHandler('rcmdr-theme', function(payload) {
      // A plain string is the old theme-only message; objects carry both.
      var theme = payload;
      var density = null;
      if (payload && typeof payload === 'object') {
        theme = payload.theme;
        density = payload.density;
      }
      rcmdrApplyTheme(theme);
      if (density) rcmdrApplyDensity(density);
    });
    (function() {
      function applyStoredTheme() {
        var stored = 'system';
        try { stored = window.localStorage.getItem('rcmdr-theme') || 'system'; }
        catch (e) { stored = 'system'; }
        rcmdrApplyTheme(stored);
        var density = 'compact';
        try {
          density = window.localStorage.getItem('rcmdr-density') || 'compact';
        } catch (e) { density = 'compact'; }
        rcmdrApplyDensity(density);
      }
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', applyStoredTheme);
      } else {
        applyStoredTheme();
      }
      if (window.matchMedia) {
        var media = window.matchMedia('(prefers-color-scheme: dark)');
        var onSystemTheme = function() {
          if (rcmdrThemeChoice === 'system') rcmdrApplyTheme('system');
        };
        if (media.addEventListener) media.addEventListener('change', onSystemTheme);
        else if (media.addListener) media.addListener(onSystemTheme);
      }
    })();
    function rcmdrRunChunk() {
      var element = document.querySelector('#script_editor_ui .ace_editor');
      if (!element) return;
      var editor = ace.edit(element);
      var position = editor.getCursorPosition();
      Shiny.setInputValue('run_chunk_at',
        {row: position.row, column: position.column}, {priority: 'event'});
    }
    window.rcmdrReportGoto = function(line) {
      var element = document.querySelector('#report_editor_ui .ace_editor');
      if (!element) return false;
      var editor = ace.edit(element);
      editor.gotoLine(line + 1, 0);
      editor.focus();
      return false;
    };
    window.rcmdrScriptGoto = function(line) {
      var element = document.querySelector('#script_editor_ui .ace_editor');
      if (!element) return false;
      var editor = ace.edit(element);
      editor.gotoLine(line + 1, 0);
      editor.focus();
      return false;
    };
    window.rcmdrScriptRunAt = function(inputId) {
      var element = document.querySelector('#script_editor_ui .ace_editor');
      if (!element) return false;
      var editor = ace.edit(element);
      var position = editor.getCursorPosition();
      Shiny.setInputValue(inputId,
        {row: position.row, column: position.column, nonce: Math.random()},
        {priority: 'event'});
      return false;
    };
    function rcmdrScriptEditor() {
      var element = document.querySelector('#script_editor_ui .ace_editor');
      if (!element) return null;
      var editor = ace.edit(element);
      rcmdrApplyCompletions(editor);
      return editor;
    }
    function rcmdrApplyCompletions(editor) {
      if (!editor || !window.rcmdrCompletionWords) return;
      try { ace.require('ace/ext/language_tools'); } catch (e) { return; }
      editor.setOptions({enableBasicAutocompletion: true, enableLiveAutocompletion: true});
      if (editor.__rcmdrCompleter === window.rcmdrCompletionWords) return;
      editor.__rcmdrCompleter = window.rcmdrCompletionWords;
      editor.completers = [{
        getCompletions: function(editor, session, pos, prefix, callback) {
          callback(null, window.rcmdrCompletionWords.map(function(word) {
            return {name: word, value: word, score: 1000, meta: 'R'};
          }));
        }
      }].concat(editor.completers || []);
    }
    window.rcmdrScriptFind = function() {
      var editor = rcmdrScriptEditor();
      if (!editor) return false;
      var input = document.getElementById('script_find');
      var query = input ? input.value : '';
      if (!query) return false;
      editor.find(query, {
        backwards: false, wrap: true, caseSensitive: false,
        wholeWord: false, regExp: false
      });
      editor.focus();
      return false;
    };
    window.rcmdrScriptReplace = function(all) {
      var editor = rcmdrScriptEditor();
      if (!editor) return false;
      var findInput = document.getElementById('script_find');
      var replaceInput = document.getElementById('script_replace');
      var query = findInput ? findInput.value : '';
      var replacement = replaceInput ? replaceInput.value : '';
      if (!query) return false;
      if (all) {
        editor.replaceAll(replacement, {regExp: false});
      } else {
        editor.find(query, {
          backwards: false, wrap: true, caseSensitive: false,
          wholeWord: false, regExp: false
        });
        editor.replace(replacement);
      }
      editor.focus();
      return false;
    };
    window.rcmdrScriptEditor = rcmdrScriptEditor;
    Shiny.addCustomMessageHandler('rcmdr-completions', function(words) {
      window.rcmdrCompletionWords = words || [];
      rcmdrApplyCompletions(rcmdrScriptEditor());
    });
    Shiny.addCustomMessageHandler('rcmdr-bind-script', function(message) {
      rcmdrScriptEditor();
    });
    function rcmdrCopy(text) {
      if (!text) return;
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text);
      }
    }
    window.rcmdrCopy = rcmdrCopy;
    window.rcmdrPaletteClick = function(el) {
      if (!el) return false;
      if (el.getAttribute('data-palette-enabled') === 'false') return false;
      Shiny.setInputValue('palette_action', {
        type: el.getAttribute('data-palette-type'),
        id: el.getAttribute('data-palette-id'),
        action: el.getAttribute('data-palette-action')
      }, {priority: 'event'});
      return false;
    };
    window.rcmdrPaletteAction = function(button, action) {
      if (!button || !button.closest) return false;
      var row = button.closest('.rcmdr-palette-result');
      if (!row) return false;
      if (row.getAttribute('data-palette-enabled') === 'false') return false;
      Shiny.setInputValue('palette_action', {
        type: row.getAttribute('data-palette-type'),
        id: row.getAttribute('data-palette-id'),
        command: row.getAttribute('data-palette-command') || '',
        action: action
      }, {priority: 'event'});
      return false;
    };
    window.rcmdrFocusField = function(id) {
      var el = document.getElementById(id);
      if (!el) el = document.querySelector('[id$=\"_' + id + '\"]');
      if (!el) return false;
      el.classList.add('is-invalid');
      el.setAttribute('aria-invalid', 'true');
      if (el.focus) el.focus();
      if (el.scrollIntoView) el.scrollIntoView({block: 'center'});
      return false;
    };
    Shiny.addCustomMessageHandler('rcmdr-field-errors', function(message) {
      document.querySelectorAll('.is-invalid').forEach(function(el) {
        el.classList.remove('is-invalid');
        el.removeAttribute('aria-invalid');
      });
      var errors = (message && message.errors) || {};
      var first = null;
      Object.keys(errors).forEach(function(id) {
        var el = document.getElementById(id) ||
          document.querySelector('[id$=\"_' + id + '\"]');
        if (!el) return;
        el.classList.add('is-invalid');
        el.setAttribute('aria-invalid', 'true');
        if (!first) first = el;
      });
      if (first && first.focus) first.focus();
    });
    var rcmdrTourStarted = false;
    function rcmdrTourCheck() {
      if (rcmdrTourStarted) return;
      try {
        if (window.localStorage &&
            window.localStorage.getItem('rcmdr-tour-dismissed') === '1') return;
        if (!window.Shiny || !window.Shiny.setInputValue) return;
        rcmdrTourStarted = true;
        Shiny.setInputValue('tour_start', Date.now(), {priority: 'event'});
      } catch (e) {}
    }
    document.addEventListener('shiny:connected', rcmdrTourCheck);
    if (document.readyState === 'complete') {
      setTimeout(rcmdrTourCheck, 400);
    } else {
      window.addEventListener('load', function() {
        setTimeout(rcmdrTourCheck, 400);
      });
    }
    Shiny.addCustomMessageHandler('rcmdr-tour-highlight', function(message) {
      document.querySelectorAll('.rcmdr-tour-highlight').forEach(function(el) {
        el.classList.remove('rcmdr-tour-highlight');
      });
      var selector = message && message.selector;
      if (!selector) return;
      var target = document.querySelector(selector);
      if (!target) return;
      target.classList.add('rcmdr-tour-highlight');
      if (target.scrollIntoView) target.scrollIntoView({block: 'center'});
    });
    Shiny.addCustomMessageHandler('rcmdr-tour-clear', function(message) {
      document.querySelectorAll('.rcmdr-tour-highlight').forEach(function(el) {
        el.classList.remove('rcmdr-tour-highlight');
      });
    });
    Shiny.addCustomMessageHandler('rcmdr-tour-dismissed', function(message) {
      try {
        if (window.localStorage) {
          window.localStorage.setItem('rcmdr-tour-dismissed', '1');
        }
      } catch (e) {}
    });
    window.rcmdrAlignDropdown = function(group) {
      var panel = group && group.querySelector('.rcmdr-menubar-dropdown');
      var bar = group && group.closest ? group.closest('.rcmdr-menubar') : null;
      if (!panel || !bar) return;
      panel.style.left = '';
      panel.style.right = '';
      panel.style.top = '';
      var margin = 8;
      var groupRect = group.getBoundingClientRect();
      var barRect = bar.getBoundingClientRect();
      var panelRect = panel.getBoundingClientRect();
      var maxLeft = Math.max(margin, window.innerWidth - margin - panelRect.width);
      var targetLeft = Math.min(Math.max(groupRect.left, margin), maxLeft);
      panel.style.left = Math.round(targetLeft - groupRect.left) + 'px';
      if (groupRect.bottom < barRect.bottom) {
        panel.style.top = Math.round(barRect.bottom - groupRect.top + 2) + 'px';
      }
    };
    // The menu tree is re-rendered by the server (tick()), which replaces the
    // open <details> elements.  Remember the open top-level group so it can be
    // reopened after a re-render instead of closing under the pointer.
    var rcmdrOpenMenubarGroup = null;
    window.rcmdrRestoreMenubar = function() {
      if (!rcmdrOpenMenubarGroup) return;
      var groups = document.querySelectorAll('.rcmdr-menubar-group');
      var group = null;
      for (var i = 0; i < groups.length; i++) {
        if (groups[i].getAttribute('data-menu-group') === rcmdrOpenMenubarGroup) {
          group = groups[i];
          break;
        }
      }
      if (!group) return;
      if (!group.open) group.open = true;
      window.rcmdrAlignDropdown(group);
    };
    if (window.MutationObserver) {
      var rcmdrMenubarObserver = new MutationObserver(function(records) {
        if (!rcmdrOpenMenubarGroup) return;
        for (var i = 0; i < records.length; i++) {
          var target = records[i].target;
          if (!target || target.nodeType !== 1) continue;
          if (target.id === 'menubar' ||
              (target.closest && target.closest('#menubar'))) {
            window.rcmdrRestoreMenubar();
            return;
          }
        }
      });
      rcmdrMenubarObserver.observe(document.documentElement,
                                   { childList: true, subtree: true });
    }
    var closeMenubarGroups = function() {
      rcmdrOpenMenubarGroup = null;
      document.querySelectorAll('.rcmdr-menubar-group[open]').forEach(function(el) {
        el.open = false;
      });
    };
    document.addEventListener('click', function(event) {
      var target = event.target;
      if (target && target.closest) {
        // A disabled item only carries its reason; keep the menu open.
        if (target.closest('.rcmdr-menubar .rcmdr-menu-item.disabled')) return;
        // Choosing an item closes the menu, as a menubar is expected to do.
        if (target.closest('.rcmdr-menubar .rcmdr-menu-item')) {
          closeMenubarGroups();
          return;
        }
        if (target.closest('.rcmdr-menubar')) return;
      }
      closeMenubarGroups();
    }, true);
    document.addEventListener('toggle', function(event) {
      var target = event.target;
      if (!target || !target.matches) return;
      if (target.matches('.rcmdr-menubar-group')) {
        var groupId = target.getAttribute('data-menu-group');
        if (target.open) {
          rcmdrOpenMenubarGroup = groupId;
          document.querySelectorAll('.rcmdr-menubar-group[open]').forEach(function(el) {
            if (el !== target) el.open = false;
          });
          window.rcmdrAlignDropdown(target);
        } else if (groupId && groupId === rcmdrOpenMenubarGroup && target.isConnected) {
          // A re-render removes the old group, which also reports a close; only
          // a close from a group still in the page is a real user action.
          rcmdrOpenMenubarGroup = null;
        }
      }
      if (!target.matches('details[data-menu-id]')) return;
      Shiny.setInputValue('menu_group_toggle', {
        id: target.getAttribute('data-menu-id'),
        open: target.open
      }, {priority: 'event'});
    }, true);
    window.rcmdrHistoryClick = function(el, action) {
      if (!el) return false;
      if (action === 'copy') {
        rcmdrCopy(el.getAttribute('data-history-command'));
        return false;
      }
      Shiny.setInputValue('history_action', {
        id: el.getAttribute('data-history-id'),
        action: action
      }, {priority: 'event'});
      return false;
    };
    document.addEventListener('click', function(event) {
      var target = event.target;
      if (!target || !target.closest) return;
      var example = target.closest('[data-help-example]');
      if (example) {
        event.preventDefault();
        Shiny.setInputValue('help_example_run', {
          topic: example.getAttribute('data-help-example'),
          index: parseInt(example.getAttribute('data-help-example-index') || '1', 10)
        }, {priority: 'event'});
        return;
      }
      var exampleInsert = target.closest('[data-help-example-insert]');
      if (exampleInsert) {
        event.preventDefault();
        Shiny.setInputValue('help_example_insert',
          exampleInsert.getAttribute('data-help-example-insert'),
          {priority: 'event'});
        return;
      }
      var dialogLink = target.closest('[data-help-dialog]');
      if (dialogLink) {
        event.preventDefault();
        Shiny.setInputValue('help_open_dialog',
          dialogLink.getAttribute('data-help-dialog'), {priority: 'event'});
        return;
      }
      var help = target.closest('[data-help-topic]');
      if (help) {
        event.preventDefault();
        Shiny.setInputValue('help_open',
          help.getAttribute('data-help-topic'), {priority: 'event'});
        var pane = document.getElementById('help_topic_pane');
        if (pane) pane.focus();
        return;
      }
      var copy = target.closest('[data-rcmdr-copy]');
      if (copy) {
        event.preventDefault();
        rcmdrCopy(copy.getAttribute('data-rcmdr-copy'));
        return;
      }
    }, true);
    document.addEventListener('keydown', function(event) {
      var mod = event.ctrlKey || event.metaKey;
      var key = (event.key || '').toLowerCase();
      if (mod && !event.shiftKey && !event.altKey && key === 'k') {
        var paletteButton = document.getElementById('palette_open');
        if (paletteButton) {
          event.preventDefault();
          paletteButton.click();
        }
      }
      if (mod && event.shiftKey && !event.altKey && key === 'p') {
        var paletteShift = document.getElementById('palette_open');
        if (paletteShift) {
          event.preventDefault();
          paletteShift.click();
        }
      }
      if (mod && !event.shiftKey && !event.altKey && key === '/') {
        var shortcuts = document.getElementById('shortcuts_open');
        if (shortcuts) {
          event.preventDefault();
          shortcuts.click();
        }
      }
      if (event.key === 'F1' && !mod && !event.altKey) {
        var helpShortcut = document.getElementById('help_shortcut');
        if (helpShortcut) {
          event.preventDefault();
          helpShortcut.click();
        }
      }
      if (event.altKey && !mod && !event.shiftKey && /^[1-9]$/.test(event.key)) {
        var tabs = document.querySelectorAll('#main_tabs .nav-link');
        var index = parseInt(event.key, 10) - 1;
        if (tabs[index]) {
          event.preventDefault();
          tabs[index].click();
        }
      }
      if (mod && event.shiftKey && event.key === 'Enter') {
        var runAll = document.getElementById('run_all');
        if (runAll) {
          event.preventDefault();
          runAll.click();
        }
      }
      if (mod && !event.shiftKey && !event.altKey && key === 's') {
        var save = document.getElementById('document_save');
        if (save) {
          event.preventDefault();
          save.click();
        }
      }
      if (mod && event.shiftKey && key === 's') {
        var saveAs = document.getElementById('document_save_as');
        if (saveAs) {
          event.preventDefault();
          saveAs.click();
        }
      }
      if (event.key === 'Enter' && mod && !event.shiftKey && !event.target.matches('#console_input, #palette_query')) {
        var run = document.getElementById('run_selection');
        if (run) {
          event.preventDefault();
          run.click();
        }
      }
      if (event.target.id === 'console_input' && event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        var consoleRun = document.getElementById('console_run');
        if (consoleRun) consoleRun.click();
      }
      if (event.target.id === 'console_input' &&
          (event.key === 'ArrowUp' || event.key === 'ArrowDown')) {
        var historyButton = document.getElementById(
          event.key === 'ArrowUp' ? 'console_prev' : 'console_next'
        );
        if (historyButton) {
          event.preventDefault();
          historyButton.click();
        }
      }
    });
    document.addEventListener('keydown', function(event) {
      if (event.target.id !== 'palette_query') return;
      var results = Array.from(document.querySelectorAll('#palette_results .rcmdr-palette-result:not(.disabled)'));
      if (results.length === 0) return;
      var current = results.findIndex(function(el) { return el.classList.contains('active'); });
      if (event.key === 'ArrowDown') {
        event.preventDefault();
        current = Math.min(results.length - 1, current + 1);
        results.forEach(function(el) { el.classList.remove('active'); });
        results[current].classList.add('active');
        results[current].scrollIntoView({block: 'nearest'});
      } else if (event.key === 'ArrowUp') {
        event.preventDefault();
        current = Math.max(0, current <= 0 ? 0 : current - 1);
        results.forEach(function(el) { el.classList.remove('active'); });
        results[current].classList.add('active');
        results[current].scrollIntoView({block: 'nearest'});
      } else if (event.key === 'Enter') {
        event.preventDefault();
        if (current < 0) current = 0;
        results[current].click();
      }
    });
    "
  ))
}

script_pane_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "d-flex gap-2 align-items-center mb-2 flex-wrap",
      selectInput(
        "document_mode", NULL,
        choices = stats::setNames(
          c("r", "rmd", "rnw"),
          c(tr("R script"), tr("R Markdown"), tr("knitr"))
        ),
        selected = "r", width = "140px"
      ),
      actionButton("document_new", tr("New"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_open", tr("Open"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_save", tr("Save"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_save_as", tr("Save as"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_section", tr("Section"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_chunk", tr("Chunk"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_remove_block", tr("Remove block"),
                   class = "btn-sm btn-outline-secondary"),
      actionButton("document_remove_section", tr("Remove section"),
                   class = "btn-sm btn-outline-secondary"),
      actionButton("document_knit", tr("Knit"), class = "btn-sm btn-primary")
    ),
    htmltools::div(
      class = "d-flex gap-2 align-items-center mb-2 flex-wrap",
      actionButton("run_selection", tr("Run selection"), class = "btn-sm btn-primary"),
      actionButton("run_all", tr("Run all"), class = "btn-sm btn-outline-primary"),
      actionButton("run_chunk", tr("Run chunk"), class = "btn-sm btn-outline-primary",
                   onclick = "rcmdrRunChunk();"),
      actionButton("clear_script", tr("Clear"), class = "btn-sm btn-outline-secondary"),
      downloadButton("download_script", tr("Download"),
                     class = "btn-sm btn-outline-secondary"),
      checkboxInput("auto_append", tr("Append generated commands"), value = TRUE)
    ),
    uiOutput("script_editor_ui")
  )
}

classic_report_pane_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "d-flex gap-2 mb-2 flex-wrap",
      downloadButton("download_knit", tr("Download report"),
                     class = "btn-sm btn-outline-secondary"),
      actionButton("knit_refresh", tr("Refresh"), class = "btn-sm btn-outline-secondary")
    ),
    uiOutput("report_pane")
  )
}

report_pane_ui <- function(mode = "studio") {
  if (identical(mode, "classic")) {
    classic_report_pane_ui()
  } else {
    report_studio_ui()
  }
}

output_pane_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "d-flex gap-2 mb-2",
      downloadButton("download_output", tr("Download output"),
                     class = "btn-sm btn-outline-secondary"),
      actionButton("clear_output", tr("Clear"), class = "btn-sm btn-outline-secondary")
    ),
    verbatimTextOutput("output_text")
  )
}

messages_pane_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "d-flex gap-2 mb-2",
      actionButton("clear_messages", tr("Clear"), class = "btn-sm btn-outline-secondary")
    ),
    verbatimTextOutput("messages_text")
  )
}

classic_data_pane_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "d-flex gap-2 align-items-center mb-2 flex-wrap",
      radioButtons(
        "data_mode", NULL,
        choices = stats::setNames(c("view", "edit"), c(tr("View"), tr("Edit"))),
        inline = TRUE
      ),
      actionButton("data_refresh", tr("Refresh"), class = "btn-sm btn-outline-secondary"),
      actionButton("data_apply", tr("Apply changes"), class = "btn-sm btn-primary"),
      downloadButton("download_dataset", tr("Download CSV"),
                     class = "btn-sm btn-outline-secondary"),
      downloadButton("download_dataset_rdata", tr("Save .RData"),
                     class = "btn-sm btn-outline-secondary"),
      uiOutput("data_info", inline = TRUE)
    ),
    uiOutput("data_pane")
  )
}

data_pane_ui <- function(mode = "studio") {
  if (identical(mode, "classic")) {
    classic_data_pane_ui()
  } else {
    data_studio_ui()
  }
}

classic_plots_pane_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "d-flex gap-2 mb-2 flex-wrap",
      downloadButton("download_plot_png", tr("Save PNG"),
                     class = "btn-sm btn-outline-secondary"),
      downloadButton("download_plot_pdf", tr("Save PDF"),
                     class = "btn-sm btn-outline-secondary"),
      if (requireNamespace("rgl", quietly = TRUE)) {
        downloadButton("download_rgl", tr("Save 3D PNG"),
                       class = "btn-sm btn-outline-secondary")
      }
    ),
    uiOutput("plotly_pane"),
    uiOutput("plot_gallery"),
    uiOutput("plot_header"),
    htmltools::div(
      class = "rcmdr-plot",
      imageOutput("plot_image", height = "auto")
    ),
    uiOutput("rgl_pane")
  )
}

plots_pane_ui <- function(mode = "studio") {
  if (identical(mode, "classic")) {
    classic_plots_pane_ui()
  } else {
    chart_studio_ui()
  }
}

home_pane_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "rcmdr-home-hero",
      htmltools::tags$h2(tr("RcmdrShiny Studio")),
      htmltools::tags$p(tr(
        "A browser-native statistical workbench inspired by the R Commander. Every action still produces reproducible R code."
      )),
      htmltools::div(
        class = "d-flex gap-2 flex-wrap",
        actionButton("home_import", tr("Import data"), class = "btn-light btn-sm"),
        actionButton("home_report", tr("New report"), class = "btn-light btn-sm"),
        actionButton("home_workflows", tr("Guided workflows"),
                     class = "btn-light btn-sm"),
        actionButton("home_palette", tr("Command palette"), class = "btn-light btn-sm"),
        actionButton("home_help", tr("Getting started"), class = "btn-light btn-sm")
      )
    ),
    htmltools::div(
      class = "rcmdr-home-grid",
      uiOutput("home_continue"),
      uiOutput("home_projects"),
      uiOutput("home_checklist"),
      uiOutput("home_recent"),
      uiOutput("home_health"),
      htmltools::div(
        class = "rcmdr-home-card",
        htmltools::tags$h5(tr("Keyboard")),
        htmltools::tags$p(class = "small text-muted mb-1",
                          tr("Ctrl+K opens the command palette.")),
        htmltools::tags$p(class = "small text-muted mb-1",
                          tr("Ctrl+Enter runs the selection or the current chunk.")),
        htmltools::tags$p(class = "small text-muted mb-2",
                          tr("Ctrl+S saves the current document.")),
        actionButton("home_shortcuts", tr("All keyboard shortcuts"),
                     class = "btn-sm btn-outline-secondary")
      )
    )
  )
}

console_workspace_ui <- function() {
  tabsetPanel(
    id = "console_tabs",
    tabPanel(tr("Console"), console_studio_ui(), value = "console"),
    tabPanel(tr("Output"), output_studio_ui(), value = "output"),
    tabPanel(tr("Messages"), messages_studio_ui(), value = "messages"),
    tabPanel(tr("History"), history_pane_ui(), value = "history")
  )
}

main_tabs_ui <- function(mode = "studio") {
  if (identical(mode, "classic")) {
    return(tabsetPanel(
      id = "main_tabs",
      tabPanel(tr("Script"), script_pane_ui(), value = "script"),
      tabPanel(tr("Output"), output_pane_ui(), value = "console"),
      tabPanel(tr("Messages"), messages_pane_ui(), value = "messages"),
      tabPanel(tr("Plots"), plots_pane_ui("classic"), value = "charts"),
      tabPanel(tr("Report"), report_pane_ui("classic"), value = "report"),
      tabPanel(tr("Data"), data_pane_ui("classic"), value = "data"),
      tabPanel(tr("Environment"), uiOutput("environment_pane"),
               value = "environment"),
      tabPanel(tr("Help"), help_center_ui(), value = "help")
    ))
  }
  tabsetPanel(
    id = "main_tabs",
    tabPanel(tr("Home"), home_pane_ui(), value = "home"),
    tabPanel(tr("Workflows"), uiOutput("workflow_panel"),
             value = "workflows"),
    tabPanel(tr("Data Studio"), data_pane_ui("studio"), value = "data"),
    tabPanel(tr("Chart Studio"), plots_pane_ui("studio"), value = "charts"),
    tabPanel(tr("Report Studio"), report_pane_ui("studio"), value = "report"),
    tabPanel(tr("Script"), script_studio_ui(), value = "script"),
    tabPanel(tr("Output (Console)"), console_workspace_ui(),
             value = "console"),
    tabPanel(tr("Environment"), environment_workspace_ui(),
             value = "environment"),
    tabPanel(tr("Help centre"), help_center_ui(), value = "help")
  )
}

#' Stable identifiers for the main views
#'
#' The tabs are windows onto the same state, their labels are translated and
#' the Studio and Classic modes show different windows. Navigation therefore
#' uses a stable view id: renaming a tab or switching language can never break
#' `state$show_tab()` silently.
#'
#' @return A named character vector mapping labels to view ids.
#' @keywords internal
main_view_aliases <- function() {
  c(
    "Home" = "home",
    "Workflows" = "workflows",
    "Data" = "data",
    "Data Studio" = "data",
    "Charts" = "charts",
    "Chart Studio" = "charts",
    "Plots" = "charts",
    "Report" = "report",
    "Report Studio" = "report",
    "Script" = "script",
    "Console" = "console",
    "Output (Console)" = "console",
    "Output" = "output",
    "Messages" = "messages",
    "History" = "history",
    "Environment" = "environment",
    "Help" = "help",
    "Help centre" = "help",
    "Help center" = "help"
  )
}

#' @keywords internal
main_view_ids <- function() unique(unname(main_view_aliases()))

#' Resolve a view label or id to a view id
#'
#' @param x A view id ("data"), an English label ("Data Studio") or a
#'   translated label ("Studio dati").
#' @return A single view id, or `NULL` when `x` is not a known view.
#' @keywords internal
main_view_id <- function(x) {
  if (is.null(x) || length(x) == 0L) return(NULL)
  value <- trimws(as.character(x[[1L]]))
  if (!nzchar(value)) return(NULL)
  if (value %in% main_view_ids()) return(value)
  aliases <- main_view_aliases()
  if (value %in% names(aliases)) return(unname(aliases[[value]]))
  for (msgid in names(aliases)) {
    if (identical(value, tr(msgid))) return(unname(aliases[[msgid]]))
  }
  NULL
}

#' Where a view id lives in the current tab layout
#'
#' Output, messages and history are panes of the Console workspace in Studio
#' mode but real tabs in Classic mode.
#'
#' @param x View id or label.
#' @param mode UI mode, "studio" or "classic".
#' @return `list(tab = <tab value>, sub = <sub-tab value or NULL>)`, or `NULL`.
#' @keywords internal
main_tab_target <- function(x, mode = "studio") {
  view <- main_view_id(x)
  if (is.null(view)) return(NULL)
  if (!identical(mode, "classic")) {
    if (identical(view, "output")) return(list(tab = "console", sub = "output"))
    if (identical(view, "messages")) {
      return(list(tab = "console", sub = "messages"))
    }
    if (identical(view, "history")) {
      return(list(tab = "console", sub = "history"))
    }
    return(list(tab = view))
  }
  if (view %in% c("output", "history")) return(list(tab = "console"))
  list(tab = view)
}

#' Labels of the main views in the current mode and language
#'
#' @param mode UI mode, "studio" or "classic".
#' @return A named character vector of labels, keyed by view id.
#' @keywords internal
main_tab_labels <- function(mode = "studio") {
  if (identical(mode, "classic")) {
    return(c(
      home = tr("Home"),
      workflows = tr("Workflows"),
      data = tr("Data"),
      charts = tr("Plots"),
      report = tr("Report"),
      script = tr("Script"),
      console = tr("Output"),
      messages = tr("Messages"),
      environment = tr("Environment"),
      help = tr("Help")
    ))
  }
  c(
    home = tr("Home"),
    workflows = tr("Workflows"),
    data = tr("Data Studio"),
    charts = tr("Chart Studio"),
    report = tr("Report Studio"),
    script = tr("Script"),
    console = tr("Output (Console)"),
    messages = tr("Messages"),
    environment = tr("Environment"),
    help = tr("Help centre")
  )
}

#' @keywords internal
main_tab_label <- function(view, mode = "studio") {
  labels <- main_tab_labels(mode)
  value <- labels[[as.character(view)[[1L]]]]
  if (is.null(value)) as.character(view)[[1L]] else unname(value)
}

#' @keywords internal
main_subtab_labels <- function() {
  c(console = tr("Console"), output = tr("Output"),
    messages = tr("Messages"), history = tr("History"))
}

#' The "where did my result go" bar
#'
#' A classic interface opened the result window after a command; this one keeps
#' the user where they are, so it says where the result landed and offers to
#' open it.
#'
#' @param info A `list(tab = , sub = , command = )` recorded by
#'   `apply_dialog_result()`, or `NULL`.
#' @param mode UI mode, "studio" or "classic".
#' @param auto Whether the auto-switch preference is on.
#' @return UI, or `NULL` when there is no result to show.
#' @keywords internal
result_hint_ui <- function(info, mode = "studio", auto = FALSE) {
  if (is.null(info)) return(NULL)
  target_label <- main_tab_label(info$tab, mode)
  sub_labels <- main_subtab_labels()
  sub_label <- if (!is.null(info$sub)) {
    unname(sub_labels[[info$sub]] %||% info$sub)
  } else {
    NULL
  }
  path <- info$command %||% character()
  command_label <- if (length(path) > 0L) {
    paste(vapply(path, menu_label, character(1)), collapse = " \u203a ")
  } else {
    NULL
  }
  htmltools::div(
    class = "rcmdr-result-hint",
    role = "status",
    `aria-live` = "polite",
    htmltools::div(
      class = "rcmdr-result-hint-text",
      if (!is.null(command_label)) htmltools::tags$strong(command_label),
      " \u2192 ",
      tr("Result in:"),
      " ",
      htmltools::tags$strong(
        paste(c(target_label, sub_label), collapse = " \u25b8 ")
      )
    ),
    htmltools::div(
      class = "d-flex align-items-center gap-2 flex-wrap",
      actionButton("result_hint_open", tr("Show result"),
                   class = "btn-sm btn-primary"),
      checkboxInput("result_hint_auto", tr("Open automatically"),
                    value = isTRUE(auto)),
      actionButton("result_hint_close", tr("Dismiss"),
                   class = "btn-sm btn-outline-secondary")
    )
  )
}

app_topbar_ui <- function(theme = "system") {
  languages <- available_languages()
  current <- current_language()
  if (!current %in% languages) languages <- c(current, languages)
  htmltools::div(
    class = "rcmdr-topbar d-flex justify-content-between align-items-center px-3 py-2",
    role = "banner",
    htmltools::div(
      class = "d-flex align-items-center gap-2",
      htmltools::tags$strong(tr("RcmdrShiny Studio"), class = "fs-5"),
      htmltools::tags$small(tr("Inspired by R Commander"),
                            class = "rcmdr-brand-sub")
    ),
    htmltools::div(
      class = "d-flex gap-2 badge-box align-items-center flex-wrap",
      actionButton(
        "palette_open", tr("Search"),
        class = "btn-sm btn-outline-light",
        title = tr("Command palette (Ctrl+K)")
      ),
      uiOutput("dataset_badge", inline = TRUE),
      uiOutput("model_badge", inline = TRUE),
      selectInput(
        "language", NULL,
        choices = stats::setNames(languages, toupper(languages)),
        selected = current, width = "90px"
      ),
      selectInput(
        "theme", NULL,
        choices = theme_choices(),
        selected = theme,
        width = "160px"
      ),
      uiOutput("ui_mode_toggle_ui", inline = TRUE),
      actionLink("about_open", tr("About"), class = "text-white small")
    )
  )
}

app_ui <- function() {
  bslib::page_fluid(
    theme = bslib::bs_theme(version = 5, primary = "#1f3a5f"),
    htmltools::tags$head(
      htmltools::tags$style(app_css()),
      htmltools::tags$script(app_js())
    ),
    htmltools::tags$a(
      class = "visually-hidden-focusable rcmdr-skip-link",
      href = "#main-content", tr("Skip to main content")
    ),
    uiOutput("app_topbar"),
    uiOutput("menubar"),
    htmltools::div(
      class = "container-fluid",
      htmltools::div(
        class = "row",
        htmltools::div(
          class = "col-lg-3 col-xl-2 rcmdr-sidebar",
          role = "navigation", `aria-label` = tr("Application menus"),
          htmltools::div(
            class = "rcmdr-menu-search",
            textInput("menu_search", NULL,
                      placeholder = tr("Search menus..."), width = "100%"),
            htmltools::div(
              class = "d-flex gap-2 align-items-center rcmdr-menu-actions",
              actionLink("menu_expand_all", tr("Expand all")),
              actionLink("menu_collapse_all", tr("Collapse all"))
            )
          ),
          uiOutput("menus")
        ),
        htmltools::div(
          class = "col-lg-9 col-xl-10 py-3",
          id = "main-content", role = "main", tabindex = "-1",
          uiOutput("result_hint"),
          uiOutput("main_tabs_ui")
        )
      )
    ),
    htmltools::div(
      class = "rcmdr-statusbar", role = "status", `aria-live` = "polite",
      uiOutput("statusbar", inline = TRUE)
    ),
    # Report downloads are triggered from the Export report dialog; the
    # buttons are invisible but must exist for Shiny to bind the outputs.
    htmltools::div(
      class = "visually-hidden",
      actionButton("shortcuts_open", tr("Keyboard shortcuts")),
      actionButton("help_shortcut", tr("Help")),
      downloadButton("download_report_rmd", tr("Download report (.Rmd)")),
      downloadButton("download_report_html", tr("Download report (.html)"))
    )
  )
}

#' Application server
#'
#' @param env Evaluation environment for commands.
#' @return A Shiny server function.
#' @keywords internal
app_server <- function(env = globalenv()) {
  force(env)

  function(input, output, session) {
    state <- AppState(env)
    state$session <- session
    try(preferences_load(state), silent = TRUE)
    if (!is.null(state$options$language) && nzchar(state$options$language)) {
      i18n_set_language(state$options$language)
    }
    persist_preferences <- function() {
      try(preferences_save(state), silent = TRUE)
      invisible(NULL)
    }
    document_registry_ensure(state)
    tick <- reactiveVal(0L)
    menu_revision <- reactiveVal(0L)
    language_revision <- reactiveVal(0L)
    state$language_revision <- language_revision
    dialog_revision <- reactiveVal(0L)
    script_value <- reactiveVal("")
    editor_mode <- reactiveVal(state$document$mode %||% "r")
    plot_selected <- reactiveVal(NULL)
    last_plot_count <- reactiveVal(0L)
    main_tabs_mode <- reactiveVal(ui_mode(state))
    history_revision <- reactiveVal(0L)
    data_grid_revision <- reactiveVal(0L)
    data_selection_revision <- reactiveVal(0L)
    chart_revision <- reactiveVal(0L)
    state$notify <- function() tick(tick() + 1L)
    state$script_consumed <- 0L
    state$set_script <- function(value) {
      script_value(value)
      shinyAce::updateAceEditor(session, "script", value = value)
    }

    sync_editor <- function() {
      value <- document_text(state)
      script_value(value)
      shinyAce::updateAceEditor(session, "script", value = value)
      invisible(value)
    }
    state$sync_document <- sync_editor

    # Project autosave.  The timer is cheap: it writes only when a project is
    # open or has unsaved metadata, and project_autosave() is atomic.
    project_autosave_timer <- shiny::reactiveTimer(
      as.integer(state$options$autosave_interval %||% 30000L)
    )
    shiny::observeEvent(project_autosave_timer(), {
      if (!is.null(state$project_path) || isTRUE(state$project_dirty)) {
        project_autosave(state)
      }
    }, ignoreInit = TRUE)

    # Offer recovery once, when the most recent project has a newer autosave.
    if (isTRUE(getOption("RcmdrShiny.recovery_prompt", TRUE))) {
      session$onFlushed(function() {
        recent <- tryCatch(project_recent(limit = 1L), error = function(e) NULL)
        if (is.null(recent) || nrow(recent) == 0L) return(invisible(NULL))
        info <- tryCatch(
          project_recovery_info(recent$path[[1L]]),
          error = function(e) NULL
        )
        if (is.null(info) || !isTRUE(info$available) ||
            !isTRUE(info$newer)) {
          return(invisible(NULL))
        }
        state$project_recovery_path <- info$path
        shiny::showModal(project_recovery_modal(info))
        invisible(NULL)
      }, once = TRUE)
    }

    # Read the editor content even when a tick-driven observer runs before the
    # input binding has propagated the latest keystrokes.
    current_document_text <- function() {
      value <- isolate(input$script)
      if (!is.null(value) && nzchar(value)) document_set_text(state, value)
      document_text(state)
    }
    state$current_document_text <- current_document_text
    state$persist_preferences <- function() persist_preferences()
    state$show_tab <- function(view) {
      target <- main_tab_target(view, main_tabs_mode())
      if (is.null(target)) return(invisible(FALSE))
      session$sendCustomMessage("rcmdr-tab", target)
      invisible(TRUE)
    }

    output$app_topbar <- renderUI({
      language_revision()
      app_topbar_ui(ui_theme(state))
    })

    tour_index <- reactiveVal(1L)
    show_tour_step <- function(index = 1L) {
      steps <- tour_steps()
      index <- max(1L, min(length(steps), as.integer(index)))
      tour_index(index)
      step <- steps[[index]]
      if (nzchar(step$tab %||% "")) state$show_tab(tr(step$tab))
      session$sendCustomMessage(
        "rcmdr-tour-highlight", list(selector = step$target)
      )
      showModal(tour_modal(step, index, length(steps)))
    }
    state$start_tour <- function() show_tour_step(1L)

    session$onFlushed(function() {
      session$sendCustomMessage("rcmdr-theme", list(
        theme = ui_theme(state),
        density = ui_density(state)
      ))
    }, once = TRUE)

    open_palette <- function() {
      showModal(palette_modal())
      session$sendCustomMessage("rcmdr-focus", "palette_query")
    }

    output$ui_mode_toggle_ui <- renderUI({
      language_revision()
      actionLink(
        "ui_mode_toggle",
        if (identical(main_tabs_mode(), "studio")) tr("Classic") else tr("Studio"),
        class = "text-white small"
      )
    })

    # Result hint ------------------------------------------------------------
    # A command runs where it always ran, but the user coming from a classic
    # interface expects the result window to open.  The hint says where the
    # result landed and offers to open it, like the classic window did.
    output$result_hint <- renderUI({
      tick()
      language_revision()
      result_hint_ui(
        state$last_result,
        mode = main_tabs_mode(),
        auto = isTRUE(state$options$auto_switch_result)
      )
    })

    observeEvent(input$result_hint_open, {
      info <- isolate(state$last_result)
      if (is.null(info)) return()
      state$show_tab(info$sub %||% info$tab)
    }, ignoreInit = TRUE)

    observeEvent(input$result_hint_close, {
      state$last_result <- NULL
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$result_hint_auto, {
      state$options$auto_switch_result <- isTRUE(input$result_hint_auto)
      persist_preferences()
      if (isTRUE(state$options$auto_switch_result)) {
        info <- isolate(state$last_result)
        if (!is.null(info)) state$show_tab(info$sub %||% info$tab)
      }
    }, ignoreInit = TRUE)

    help_server(input, output, session, state)

    # Per-session directory for plot thumbnails and downloads.
    plot_dir <- file.path(tempdir(), paste0("rcmdrshiny-", session$token))
    dir.create(plot_dir, showWarnings = FALSE, recursive = TRUE)
    state$plot_dir <- plot_dir
    state$plot_prefix <- paste0("rcmdr-plots-", session$token)
    try(addResourcePath(state$plot_prefix, plot_dir), silent = TRUE)

    knit_dir <- file.path(tempdir(), paste0("rcmdrshiny-knit-", session$token))
    dir.create(knit_dir, showWarnings = FALSE, recursive = TRUE)
    state$knit_dir <- knit_dir
    state$knit_prefix <- paste0("rcmdr-knit-", session$token)
    try(addResourcePath(state$knit_prefix, knit_dir), silent = TRUE)

    report_dir <- file.path(tempdir(), paste0("rcmdrshiny-report-", session$token))
    dir.create(report_dir, showWarnings = FALSE, recursive = TRUE)
    state$report_dir <- report_dir
    state$autosave_dir <- file.path(tempdir(), "rcmdrshiny-autosave")

    tree <- menu_tree()
    leaves <- menu_leaves(tree)

    failures <- plugin_failures()
    if (nrow(failures) > 0L) {
      showNotification(
        sprintf(tr("%d plugin(s) could not be loaded. See Home > Health."),
                nrow(failures)),
        type = "warning", duration = 10
      )
    }
    conflicts <- plugin_conflicts()
    if (nrow(conflicts) > 0L) {
      showNotification(
        sprintf(tr("%d plugin conflict(s) recorded. See Home > Health."),
                nrow(conflicts)),
        type = "warning", duration = 10
      )
    }

    # -- menus --------------------------------------------------------------

    output$menubar <- renderUI({
      menu_revision()
      language_revision()
      tick()
      menubar_ui(
        tree,
        function(node) {
          command_status(state, node$command, node$activation, node$install)
        },
        favorites = menu_favorite_ids(state),
        expanded = state$menu_expanded %||% character()
      )
    })

    output$menus <- renderUI({
      menu_revision()
      language_revision()
      tick()
      query <- trimws(input$menu_search %||% "")
      favorites <- menu_favorite_ids(state)
      if (!nzchar(query)) {
        return(menu_sections_ui(state, leaves))
      }
      translated <- vapply(leaves$label, menu_label, character(1))
      matches <- leaves[
        grepl(query, paste(leaves$label, translated, leaves$path,
                           leaves$command),
              ignore.case = TRUE, fixed = TRUE),
        , drop = FALSE
      ]
      if (nrow(matches) == 0L) {
        return(empty_state(
          tr("No menu entries"),
          tr("Try a different search term.")
        ))
      }
      htmltools::tagList(lapply(seq_len(nrow(matches)), function(i) {
        row <- matches[i, , drop = FALSE]
        status <- command_status(state, row$command, row$activation, row$install)
        if (identical(status, "hidden")) return(NULL)
        menu_flat_item_ui(row, status, query,
                          row$command[[1L]] %in% favorites)
      }))
    })

    observeEvent(input$menu_favorite, {
      action <- input$menu_favorite
      if (is.null(action) || is.null(action$command)) return()
      menu_favorite_toggle(state, action$command)
      persist_preferences()
      menu_revision(menu_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$menu_group_toggle, {
      action <- input$menu_group_toggle
      if (is.null(action) || is.null(action$id)) return()
      # Re-rendering the menu tree recreates the open <details> elements, which
      # makes the browser report a toggle for a state the session already has.
      # Touching the state for those echoes re-renders the tree again (tick())
      # and the UI loops forever, so only real changes are applied.
      if (menu_toggle_is_echo(isolate(state$menu_expanded), action$id,
                              action$open)) {
        return()
      }
      menu_toggle_expanded(state, action$id, isTRUE(action$open))
      persist_preferences()
    }, ignoreInit = TRUE)

    observeEvent(input$menu_expand_all, {
      menu_set_expanded(state, menu_group_ids(tree), expand = TRUE)
      persist_preferences()
      menu_revision(menu_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$menu_collapse_all, {
      menu_set_expanded(state, menu_group_ids(tree), expand = FALSE)
      persist_preferences()
      menu_revision(menu_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$shortcuts_open, {
      showModal(shortcuts_modal())
    }, ignoreInit = TRUE)

    observeEvent(input$home_shortcuts, {
      showModal(shortcuts_modal())
    }, ignoreInit = TRUE)

    finish_tour <- function(dismiss = FALSE) {
      removeModal()
      session$sendCustomMessage("rcmdr-tour-clear", list())
      if (isTRUE(dismiss)) {
        session$sendCustomMessage("rcmdr-tour-dismissed", list())
      }
      invisible(NULL)
    }

    observeEvent(input$tour_start, {
      show_tour_step(1L)
    })

    observeEvent(input$tour_next, {
      index <- tour_index()
      steps <- tour_steps()
      if (index >= length(steps)) {
        finish_tour(dismiss = TRUE)
        showNotification(tr("Tour completed. You can restart it from Help > Tour."),
                         type = "message", duration = 4)
      } else {
        show_tour_step(index + 1L)
      }
    })

    observeEvent(input$tour_back, {
      show_tour_step(tour_index() - 1L)
    })

    observeEvent(input$tour_skip, {
      finish_tour(dismiss = FALSE)
    })

    observeEvent(input$tour_dismiss, {
      finish_tour(dismiss = TRUE)
    })

    observeEvent(input$help_shortcut, {
      if (is.function(state$help_show)) state$help_show("getting-started")
      state$show_tab(tr("Help"))
    }, ignoreInit = TRUE)

    observeEvent(input$home_workflows, {
      state$show_tab(tr("Workflows"))
    }, ignoreInit = TRUE)

    observeEvent(tick(), {
      mode <- ui_mode(state)
      if (!identical(mode, isolate(main_tabs_mode()))) {
        main_tabs_mode(mode)
      }
    }, ignoreInit = TRUE)

    output$main_tabs_ui <- renderUI({
      language_revision()
      main_tabs_ui(main_tabs_mode())
    })

    open_dialog <- function(spec) {
      if (!is.null(spec$on_open)) spec$on_open(state)
      state$dialog_errors <- list()
      state$current_dialog <- spec$id
      if (!is.null(state$help_reset_dialog)) state$help_reset_dialog()
      dialog_revision(dialog_revision() + 1L)
      showModal(dialog_modal(spec))
    }

    state$open_dialog <- function(id) {
      spec <- get_dialog_spec(id)
      if (!is.null(spec)) open_dialog(spec)
      invisible(NULL)
    }

    output$script_editor_ui <- renderUI({
      mode <- editor_mode()
      shinyAce::aceEditor(
        "script", value = isolate(script_value()),
        mode = document_ace_mode(mode), theme = "textmate",
        height = "460px", fontSize = 13, selectionId = "script_selection",
        autoComplete = "enabled"
      )
    })

    launch <- function(command) {
      availability <- command_availability(state, command)
      if (!identical(availability$status, "enabled")) {
        showNotification(
          command_status_message(availability$status),
          type = "warning", duration = 5
        )
        return(invisible(NULL))
      }

      menu_recent_add(state, command)
      persist_preferences()

      spec <- get_dialog_spec(command)
      if (!is.null(spec)) {
        open_dialog(spec)
        return(invisible(TRUE))
      }

      action <- direct_commands()[[command]]
      if (!is.null(action)) {
        old_source <- state$execution_source
        state$execution_source <- "menu"
        on.exit(state$execution_source <- old_source, add = TRUE)
        action(state)
        tick(tick() + 1L)
        menu_revision(menu_revision() + 1L)
        history_revision(history_revision() + 1L)
        return(invisible(TRUE))
      }

      showNotification(tr("This command has not been ported yet."),
                       type = "message", duration = 5)
      invisible(NULL)
    }

    for (i in seq_len(nrow(leaves))) {
      local({
        key <- leaves$key[[i]]
        command <- leaves$command[[i]]
        observeEvent(input[[key]], launch(command), ignoreInit = TRUE)
      })
    }

    observeEvent(input$menu_command, {
      command <- input$menu_command
      if (is.null(command) || !nzchar(command)) return()
      launch(command)
    }, ignoreInit = TRUE)

    # -- dialogs ------------------------------------------------------------

    output$dialog_body <- renderUI({
      dialog_revision()
      spec <- get_dialog_spec(state$current_dialog %||% "")
      req(spec)
      htmltools::div(
        class = "rcmdr-field-grid rcmdr-dialog-grid",
        spec$ui(state, get_dialog_memory(state, spec$id))
      )
    })

    strip_dialog_prefix <- function(values, id) {
      prefix <- paste0(id, "_")
      names(values) <- sub(paste0("^", prefix), "", names(values))
      values
    }

    capture_dialog_inputs <- function(id) {
      values <- shiny::reactiveValuesToList(input)
      prefix <- paste0(id, "_")
      keep <- startsWith(names(values), prefix)
      strip_dialog_prefix(values[keep], id)
    }

    dialog_preview_result <- shiny::reactive({
      dialog_revision()
      spec <- get_dialog_spec(state$current_dialog %||% "")
      if (is.null(spec) || !isTRUE(feature_enabled(state, "dialog_preview")) ||
          !isTRUE(spec$preview)) {
        return(NULL)
      }
      tryCatch(
        spec$on_ok(input, preview_state_clone(state)),
        error = function(e) list(error = conditionMessage(e))
      )
    })
    dialog_preview_result_d <- shiny::debounce(dialog_preview_result, 300)

    output$dialog_preview_panel <- renderUI({
      result <- dialog_preview_result_d()
      if (is.null(result)) return(NULL)
      if (!is.null(result$error)) {
        return(htmltools::tags$p(
          class = "text-muted small mb-0",
          result$error
        ))
      }
      commands <- result$commands %||% character()
      if (length(commands) > 0L) {
        return(code_preview(paste(commands, collapse = "\n")))
      }
      if (!is.null(result$script) && nzchar(result$script)) {
        return(code_preview(result$script))
      }
      if (!is.null(result$interactive)) {
        return(htmltools::tags$p(
          class = "text-muted small mb-0",
          tr("This dialog produces an interactive plot.")
        ))
      }
      if (!is.null(result$report)) {
        return(htmltools::tags$p(
          class = "text-muted small mb-0",
          tr("This dialog prepares a report; no R command is generated.")
        ))
      }
      if (!is.null(result$tab)) {
        return(htmltools::tags$p(
          class = "text-muted small mb-0",
          sprintf(tr("This dialog opens the %s tab."), result$tab)
        ))
      }
      htmltools::tags$p(
        class = "text-muted small mb-0",
        tr("No R command is generated by this dialog.")
      )
    })

    output$dialog_validation_ui <- renderUI({
      dialog_revision()
      dialog_validation_ui(state$dialog_errors %||% list())
    })

    output$dialog_presets_ui <- renderUI({
      dialog_revision()
      spec <- get_dialog_spec(state$current_dialog %||% "")
      if (is.null(spec) || !isTRUE(feature_enabled(state, "dialog_presets")) ||
          !isTRUE(spec$presets)) {
        return(NULL)
      }
      presets <- names(dialog_presets_for(state, spec$id))
      choices <- c(stats::setNames("", tr("(no preset)")),
                   stats::setNames(presets, presets))
      htmltools::tags$div(
        class = "rcmdr-dialog-presets d-flex gap-2 align-items-end flex-wrap",
        htmltools::tags$div(
          style = "min-width: 170px;",
          selectInput("dialog_preset_select", NULL, choices = choices,
                      width = "170px", selectize = FALSE)
        ),
        actionButton("dialog_preset_apply", tr("Apply"),
                     class = "btn-sm btn-outline-secondary"),
        actionButton("dialog_preset_delete", tr("Delete"),
                     class = "btn-sm btn-outline-secondary"),
        htmltools::tags$div(
          style = "width: 150px;",
          textInput("dialog_preset_name", NULL,
                    placeholder = tr("Preset name"))
        ),
        actionButton("dialog_preset_save", tr("Save preset"),
                     class = "btn-sm btn-outline-primary"),
        downloadButton("dialog_preset_export", tr("Export"),
                       class = "btn-sm btn-outline-secondary"),
        shiny::fileInput(
          "dialog_preset_import", NULL, accept = ".rds", width = "150px",
          buttonLabel = tr("Import"), placeholder = tr("Preset file")
        )
      )
    })

    observeEvent(input$dialog_preset_apply, {
      id <- state$current_dialog
      req(id)
      name <- input$dialog_preset_select %||% ""
      if (!nzchar(name)) return()
      preset <- dialog_preset_get(state, id, name)
      if (is.null(preset)) return()
      set_dialog_memory(state, id, preset)
      state$dialog_errors <- list()
      dialog_revision(dialog_revision() + 1L)
      showNotification(tr("Preset applied."), type = "message", duration = 2)
    }, ignoreInit = TRUE)

    observeEvent(input$dialog_preset_save, {
      id <- state$current_dialog
      req(id)
      result <- dialog_preset_save(
        state, id, input$dialog_preset_name %||% "",
        capture_dialog_inputs(id)
      )
      if (!isTRUE(result$ok)) {
        showNotification(result$error %||% tr("The preset could not be saved."),
                         type = "error", duration = 4)
        return()
      }
      persist_preferences()
      updateTextInput(session, "dialog_preset_name", value = "")
      dialog_revision(dialog_revision() + 1L)
      showNotification(tr("Preset saved."), type = "message", duration = 2)
    }, ignoreInit = TRUE)

    observeEvent(input$dialog_preset_delete, {
      id <- state$current_dialog
      req(id)
      name <- input$dialog_preset_select %||% ""
      if (!nzchar(name)) return()
      dialog_preset_delete(state, id, name)
      persist_preferences()
      dialog_revision(dialog_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$dialog_preset_import, {
      upload <- input$dialog_preset_import
      if (is.null(upload) || is.null(upload$datapath)) return()
      result <- dialog_presets_load_file(state, upload$datapath,
                                         overwrite = TRUE)
      if (!isTRUE(result$ok)) {
        showNotification(result$error %||% tr("The preset file could not be read."),
                         type = "error", duration = 5)
        return()
      }
      persist_preferences()
      dialog_revision(dialog_revision() + 1L)
      showNotification(
        sprintf(tr("%d presets imported."), result$imported %||% 0L),
        type = "message", duration = 3
      )
    }, ignoreInit = TRUE)

    output$dialog_preset_export <- downloadHandler(
      filename = function() "rcmdrshiny-presets.rds",
      content = function(file) {
        saveRDS(dialog_presets_export(state), file)
      }
    )

    observeEvent(input$dialog_insert_script, {
      result <- isolate(dialog_preview_result())
      commands <- result$commands %||% character()
      if (length(commands) == 0L && !is.null(result$script) &&
          nzchar(result$script)) {
        commands <- result$script
      }
      if (length(commands) == 0L) {
        showNotification(tr("This dialog has no command to insert."),
                         type = "message", duration = 3)
        return()
      }
      insert_commands_into_script(state, commands)
      removeModal()
      state$current_dialog <- NULL
      state$dialog_errors <- list()
      dialog_revision(dialog_revision() + 1L)
      tick(tick() + 1L)
      state$show_tab(tr("Script"))
    }, ignoreInit = TRUE)

    submit_dialog <- function(close = TRUE) {
      id <- state$current_dialog
      req(id)
      spec <- get_dialog_spec(id)
      req(spec)

      result <- tryCatch(
        spec$on_ok(input, state),
        error = function(e) list(error = conditionMessage(e))
      )

      field_errors <- dialog_field_errors(result)
      if (length(field_errors) > 0L) {
        prefixed <- stats::setNames(
          unlist(field_errors, use.names = FALSE),
          ifelse(startsWith(names(field_errors), paste0(id, "_")),
                 names(field_errors),
                 paste0(id, "_", names(field_errors)))
        )
        state$dialog_errors <- as.list(prefixed)
        dialog_revision(dialog_revision() + 1L)
        session$sendCustomMessage("rcmdr-field-errors",
                                  dialog_validation_payload(state$dialog_errors))
        return(invisible(FALSE))
      }

      if (!is.null(result$error)) {
        showNotification(result$error, type = "error", duration = 10)
        return(invisible(FALSE))
      }

      state$dialog_errors <- list()
      if (!is.null(result$memory)) set_dialog_memory(state, id, result$memory)

      before_history <- vapply(state$history %||% list(),
                               function(entry) entry$id %||% "", character(1))
      state$busy <- TRUE
      ok <- tryCatch(
        apply_dialog_result(state, result),
        error = function(e) {
          state$last_error <- conditionMessage(e)
          state$messages <- c(state$messages, paste0("Error: ", state$last_error))
          FALSE
        }
      )
      state$busy <- FALSE

      if (isTRUE(ok) && !is.null(state$workflow)) {
        after_history <- vapply(state$history %||% list(),
                                function(entry) entry$id %||% "", character(1))
        workflow_mark_step(
          state, id, result,
          history_ids = setdiff(after_history, before_history)
        )
      }

      if (close) {
        removeModal()
        state$current_dialog <- NULL
        dialog_revision(dialog_revision() + 1L)
      }
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)

      if (!ok) {
        state$last_failed_dialog <- list(
          id = id,
          memory = get_dialog_memory(state, id)
        )
        showModal(modalDialog(
          title = tr("Command error"),
          htmltools::tagList(
            htmltools::tags$pre(state$last_error %||% tr("The command produced an error.")),
            tryCatch(error_help_link_ui(state$last_error),
                     error = function(e) NULL)
          ),
          easyClose = TRUE,
          footer = htmltools::tagList(
            modalButton(tr("Close")),
            actionButton("dialog_retry", tr("Retry"), class = "btn-primary")
          )
        ))
      } else if (!close) {
        showNotification(tr("Applied."), type = "message", duration = 2)
      }
      invisible(ok)
    }

    observeEvent(input$dialog_ok, submit_dialog(close = TRUE))
    observeEvent(input$dialog_apply, submit_dialog(close = FALSE))

    observeEvent(input$dialog_cancel, {
      removeModal()
      state$current_dialog <- NULL
      state$dialog_errors <- list()
      if (!is.null(state$help_reset_dialog)) state$help_reset_dialog()
      dialog_revision(dialog_revision() + 1L)
    })

    observeEvent(input$dialog_reset, {
      id <- state$current_dialog
      req(id)
      spec <- get_dialog_spec(id)
      req(spec)
      state$dialog_errors <- list()
      clear_dialog_memory(state, id)
      if (!is.null(state$help_reset_dialog)) state$help_reset_dialog()
      if (!is.null(spec$on_open)) spec$on_open(state)
      dialog_revision(dialog_revision() + 1L)
      showModal(dialog_modal(spec))
    })

    observeEvent(input$dialog_retry, {
      failed <- state$last_failed_dialog
      req(failed)
      removeModal()
      spec <- get_dialog_spec(failed$id)
      req(spec)
      state$current_dialog <- failed$id
      if (!is.null(state$help_reset_dialog)) state$help_reset_dialog()
      if (!is.null(failed$memory)) {
        set_dialog_memory(state, failed$id, failed$memory)
      }
      if (!is.null(spec$on_open)) spec$on_open(state)
      dialog_revision(dialog_revision() + 1L)
      showModal(dialog_modal(spec))
    })

    for (spec in dialog_catalog()) {
      if (!is.null(spec$observers)) {
        spec$observers(input, output, session, state, tick)
      }
    }

    # -- output panes -------------------------------------------------------

    output$output_text <- renderText({
      tick()
      paste(state$output, collapse = "\n")
    })

    output$messages_text <- renderText({
      tick()
      paste(state$messages, collapse = "\n")
    })

    outputOptions(output, "output_text", suspendWhenHidden = FALSE)
    outputOptions(output, "messages_text", suspendWhenHidden = FALSE)

    output$output_cards <- renderUI({
      tick()
      menu_revision()
      history_revision()
      entries <- history_filter_entries(
        history_recent(state, 100L),
        input$output_filter %||% "",
        input$output_source %||% "all",
        input$output_status %||% "all"
      )
      if (isTRUE(input$output_pinned)) {
        pinned <- history_pinned_ids(state)
        entries <- Filter(function(entry) entry$id %in% pinned, entries)
      }
      history_cards_ui(entries, pinned = history_pinned_ids(state))
    })
    outputOptions(output, "output_cards", suspendWhenHidden = FALSE)

    output$messages_cards <- renderUI({
      tick()
      entries <- messages_filter(
        state$message_entries %||% list(),
        input$messages_filter %||% "",
        input$messages_severity %||% "all"
      )
      if (length(entries) == 0L) {
        return(empty_state(tr("No messages"),
                           tr("Warnings, errors and notes appear here.")))
      }
      htmltools::tagList(lapply(entries, function(entry) {
        severity <- entry$severity %||% "message"
        pill <- switch(
          severity,
          error = status_pill(tr("Error"), "error"),
          warning = status_pill(tr("Warning"), "warning"),
          status_pill(tr("Note"), "muted")
        )
        htmltools::tags$div(
          class = "rcmdr-history-card",
          htmltools::tags$div(
            class = "rcmdr-history-head",
            pill,
            htmltools::tags$span(class = "rcmdr-history-time",
                                 format(entry$time %||% Sys.time(), "%H:%M:%S")),
            if (nzchar(entry$history_id %||% "")) {
              htmltools::tags$div(
                class = "ms-auto",
                htmltools::tags$button(
                  type = "button", class = "btn btn-sm btn-outline-secondary",
                  onclick = sprintf(
                    "rcmdrHistoryClick(this, 'rerun'); return false;"
                  ),
                  `data-history-action` = "rerun",
                  `data-history-id` = entry$history_id,
                  tr("Rerun")
                )
              )
            }
          ),
          if (nzchar(entry$command %||% "")) {
            htmltools::tags$pre(class = "rcmdr-history-command", entry$command)
          },
          htmltools::tags$pre(class = "rcmdr-message-text", entry$text),
          if (identical(severity, "error")) {
            tryCatch(error_help_link_ui(entry$text), error = function(e) NULL)
          }
        )
      }))
    })
    outputOptions(output, "messages_cards", suspendWhenHidden = FALSE)

    observeEvent(input$clear_output, {
      state$output <- character()
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$output_clear, {
      state$output <- character()
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$clear_messages, {
      state$messages <- character()
      state$warnings <- character()
      state$last_error <- NULL
      messages_clear(state)
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$messages_clear, {
      state$messages <- character()
      state$warnings <- character()
      state$last_error <- NULL
      messages_clear(state)
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    # -- history, console and palette --------------------------------------

    output$history_cards <- renderUI({
      tick()
      menu_revision()
      history_revision()
      entries <- history_filter_entries(
        history_recent(state, 100L),
        input$history_filter %||% "",
        input$history_source %||% "all"
      )
      history_cards_ui(entries)
    })

    observeEvent(input$history_action, {
      action <- input$history_action
      if (is.null(action) || is.null(action$id)) return()
      switch(
        action$action %||% "rerun",
        rerun = history_rerun(state, action$id),
        dialog = history_open_dialog(state, action$id),
        script = history_insert_script(state, action$id),
        report = history_insert_report(state, action$id),
        pin = history_toggle_pin(state, action$id),
        unpin = history_toggle_pin(state, action$id)
      )
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$history_clear, {
      history_clear(state)
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    # Nested console tabs are suspended while hidden; force the history output
    # to refresh when the History tab becomes visible.
    observeEvent(input$console_tabs, {
      if (identical(input$console_tabs, "history")) {
        history_revision(history_revision() + 1L)
      }
    }, ignoreInit = TRUE)

    output$console_log <- renderUI({
      tick()
      menu_revision()
      history_revision()
      entries <- console_entries(
        state,
        input$console_filter %||% "",
        input$console_status %||% "all",
        20L
      )
      if (length(entries) == 0L) {
        return(empty_state(
          tr("Console ready"),
          tr("Type an R command above. Commands are logged and added to the history.")
        ))
      }
      history_cards_ui(entries, pinned = history_pinned_ids(state))
    })

    output$console_status_ui <- renderUI({
      tick()
      last <- state$console_last
      if (is.null(last)) {
        return(htmltools::tags$p(
          class = "small text-muted mb-1",
          tr("Ready.")
        ))
      }
      htmltools::tags$p(
        class = if (identical(last$status, "ok")) "small text-success mb-1" else
          "small text-danger mb-1",
        sprintf(
          "%s - %s - %.0f ms",
          if (identical(last$status, "ok")) tr("OK") else tr("Error"),
          format(last$time %||% Sys.time(), "%H:%M:%S"),
          last$duration_ms %||% 0
        )
      )
    })
    outputOptions(output, "console_status_ui", suspendWhenHidden = FALSE)

    observeEvent(input$console_run, {
      code <- trimws(input$console_input %||% "")
      if (!nzchar(code)) return()
      if (console_is_interactive(code)) {
        showNotification(
          tr("Interactive commands such as readline() or menu() cannot run in the browser console."),
          type = "error", duration = 8
        )
        return()
      }
      state$busy <- TRUE
      console_execute(state, code)
      state$busy <- FALSE
      updateTextInput(session, "console_input", value = "")
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$console_prev, {
      updateTextInput(session, "console_input",
                      value = console_history_recall(state, -1L))
    }, ignoreInit = TRUE)

    observeEvent(input$console_next, {
      updateTextInput(session, "console_input",
                      value = console_history_recall(state, 1L))
    }, ignoreInit = TRUE)

    observeEvent(input$console_clear, {
      history <- Filter(function(entry) !identical(entry$source, "console"),
                        state$history %||% list())
      state$history <- history
      state$console_history <- character()
      state$console_index <- 0L
      state$console_last <- NULL
      tick(tick() + 1L)
      history_revision(history_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$palette_open, open_palette(), ignoreInit = TRUE)
    observeEvent(input$home_palette, open_palette(), ignoreInit = TRUE)

    output$palette_results <- renderUI({
      tick()
      menu_revision()
      index <- palette_index_cached(state)
      results <- palette_search(
        input$palette_query %||% "", index, 25L,
        type = input$palette_type %||% "all",
        favorites_only = isTRUE(input$palette_favorites)
      )
      palette_results_ui(results)
    })

    observeEvent(input$palette_action, {
      action <- input$palette_action
      if (is.null(action) || is.null(action$id)) return()
      type <- action$type %||% ""
      verb <- action$action %||% "run"
      if (identical(type, "menu") || identical(type, "dialog")) {
        if (identical(verb, "favorite")) {
          menu_favorite_toggle(state, action$id)
          persist_preferences()
          menu_revision(menu_revision() + 1L)
          return()
        }
        if (identical(verb, "copy")) {
          tryCatch(
            utils::writeClipboard(action$command %||% action$id),
            error = function(e) NULL
          )
          showNotification(tr("Command copied."), type = "message",
                           duration = 2)
          return()
        }
        removeModal()
        launch(action$id)
        return()
      }
      if (identical(type, "workflow")) {
        removeModal()
        result <- workflow_start(state, action$id)
        if (!isTRUE(result$ok)) {
          showNotification(result$error %||% tr("Unknown workflow."),
                           type = "error", duration = 5)
        } else {
          menu_recent_add(state, paste0("workflow:", action$id))
          persist_preferences()
          state$show_tab(tr("Workflows"))
          tick(tick() + 1L)
        }
        return()
      }
      removeModal()
      switch(
        type,
        help = {
          if (is.function(state$help_show)) state$help_show(action$id)
          state$show_tab(tr("Help"))
        },
        dataset = {
          tryCatch(active_dataset(state, action$id), error = function(e) NULL)
          tick(tick() + 1L)
          menu_revision(menu_revision() + 1L)
        },
        variable = {
          updateSelectInput(session, "data_inspector_column",
                            selected = action$id)
          state$show_tab(tr("Data"))
          showNotification(
            sprintf(tr("Variable: %s"), action$id),
            type = "message", duration = 2
          )
        },
        history = {
          if (identical(verb, "insert")) {
            history_insert_script(state, action$id)
          } else if (identical(verb, "copy")) {
            entry <- Filter(function(item) identical(item$id, action$id),
                            state$history %||% list())
            if (length(entry) > 0L) {
              tryCatch(utils::writeClipboard(entry[[1L]]$command %||% ""),
                       error = function(e) NULL)
              showNotification(tr("Command copied."), type = "message",
                               duration = 2)
            }
          } else {
            history_rerun(state, action$id)
          }
          tick(tick() + 1L)
          menu_revision(menu_revision() + 1L)
        }
      )
    }, ignoreInit = TRUE)

    output$workflow_panel <- renderUI({
      tick()
      workflow_panel_ui(state)
    })

    observeEvent(input$workflow_action, {
      action <- input$workflow_action
      if (is.null(action) || is.null(action$action)) return()
      switch(
        action$action,
        start = {
          result <- workflow_start(state, action$step)
          if (!isTRUE(result$ok)) {
            showNotification(result$error %||% tr("Unknown workflow."),
                             type = "error", duration = 5)
          }
        },
        open = {
          result <- workflow_step_open(state, action$step %||% NULL)
          if (!isTRUE(result$ok)) {
            showNotification(result$error %||% tr("The step is not available."),
                             type = "error", duration = 5)
          } else if (!is.null(result$dialog)) {
            open_dialog_memory(state, result$dialog, result$memory %||% list())
          } else if (!is.null(result$message)) {
            showNotification(result$message, type = "message", duration = 3)
          }
        },
        skip = {
          result <- workflow_skip_step(state, action$step %||% NULL)
          if (!isTRUE(result$ok)) {
            showNotification(result$error %||% tr("The step cannot be skipped."),
                             type = "warning", duration = 4)
          }
        },
        back = workflow_back(state),
        cancel = {
          workflow_cancel(state)
          showNotification(tr("Workflow cancelled."), type = "message",
                           duration = 2)
        },
        report_section = {
          section <- workflow_report_section(state)
          showModal(modalDialog(
            title = tr("Draft report section"),
            code_preview(section),
            easyClose = TRUE,
            footer = modalButton(tr("Close")),
            size = "l"
          ))
        },
        report_insert = {
          result <- workflow_insert_report(state)
          if (!isTRUE(result$ok)) {
            showNotification(result$error %||% tr("No report section yet."),
                             type = "warning", duration = 4)
          } else {
            state$show_tab(tr("Report"))
            showNotification(tr("Workflow section inserted into the report."),
                             type = "message", duration = 3)
          }
        }
      )
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$ui_mode_toggle, {
      next_mode <- if (identical(ui_mode(state), "studio")) "classic" else "studio"
      set_ui_mode(state, next_mode)
      tick(tick() + 1L)
      showNotification(
        if (identical(next_mode, "studio")) {
          tr("Studio interface enabled.")
        } else {
          tr("Classic interface enabled.")
        },
        type = "message", duration = 2
      )
    }, ignoreInit = TRUE)

    observeEvent(input$theme, {
      set_ui_theme(state, input$theme %||% "system")
      persist_preferences()
      session$sendCustomMessage("rcmdr-theme", list(
        theme = input$theme %||% "system",
        density = ui_density(state)
      ))
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$about_open, {
      action <- direct_commands()[["helpAboutCommander"]]
      if (!is.null(action)) action(state)
    }, ignoreInit = TRUE)

    observeEvent(input$home_import, {
      state$open_dialog("readDataSet")
    }, ignoreInit = TRUE)

    observeEvent(input$home_report, {
      state$open_dialog("newRmd")
    }, ignoreInit = TRUE)

    observeEvent(input$home_help, {
      if (is.function(state$help_show)) state$help_show("getting-started")
      state$show_tab(tr("Help"))
    }, ignoreInit = TRUE)

    output$home_checklist <- renderUI({
      tick()
      language_revision()
      onboarding_checklist_ui(state)
    })

    observeEvent(input$home_check_import, {
      state$open_dialog("readDataSet")
    }, ignoreInit = TRUE)

    observeEvent(input$home_check_summary, {
      state$open_dialog("numericalSummaries")
    }, ignoreInit = TRUE)

    observeEvent(input$home_check_chart, {
      state$show_tab(tr("Charts"))
    }, ignoreInit = TRUE)

    observeEvent(input$home_check_report, {
      state$open_dialog("newRmd")
    }, ignoreInit = TRUE)

    observeEvent(input$home_check_project, {
      state$open_dialog("projectNew")
    }, ignoreInit = TRUE)

    output$home_projects <- renderUI({
      tick()
      language_revision()
      project_home_ui(state)
    })

    observeEvent(input$home_project_new, {
      state$open_dialog("projectNew")
    }, ignoreInit = TRUE)

    observeEvent(input$home_project_open, {
      state$open_dialog("projectOpen")
    }, ignoreInit = TRUE)

    observeEvent(input$home_project_save, {
      action <- direct_commands()[["projectSave"]]
      if (!is.null(action)) action(state)
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$home_project_bundle, {
      state$open_dialog("projectBundle")
    }, ignoreInit = TRUE)

    observeEvent(input$home_project_recent_open, {
      path <- input$home_project_recent %||% ""
      if (!nzchar(path)) return()
      result <- tryCatch(project_load(state, path), error = function(e) e)
      if (inherits(result, "error")) {
        showNotification(conditionMessage(result), type = "error")
        return()
      }
      if (is.function(state$sync_document)) state$sync_document()
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$project_recovery_recover, {
      path <- state$project_recovery_path
      removeModal()
      if (is.null(path)) return()
      result <- tryCatch(project_recover(state, path), error = function(e) e)
      if (inherits(result, "error")) {
        showNotification(conditionMessage(result), type = "error")
        return()
      }
      if (is.function(state$sync_document)) state$sync_document()
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$project_recovery_ignore, {
      state$project_recovery_ignored <- TRUE
      removeModal()
    }, ignoreInit = TRUE)

    observeEvent(input$project_recovery_delete, {
      path <- state$project_recovery_path
      removeModal()
      if (!is.null(path)) unlink(paste0(path, ".autosave"))
      state$project_recovery_ignored <- TRUE
    }, ignoreInit = TRUE)

    output$home_continue <- renderUI({
      tick()
      dataset_name <- active_dataset(state)
      model_name <- active_model(state)
      htmltools::tags$div(
        class = "rcmdr-home-card",
        htmltools::tags$h5(tr("Continue")),
        htmltools::tags$p(
          class = "small text-muted mb-1",
          sprintf(tr("Active data: %s"),
                  dataset_name %||% tr("none"))
        ),
        htmltools::tags$p(
          class = "small text-muted mb-1",
          sprintf(tr("Active model: %s"),
                  model_name %||% tr("none"))
        ),
        htmltools::tags$p(
          class = "small text-muted mb-2",
          sprintf(tr("Document: %s"), document_mode(state))
        ),
        htmltools::tags$div(
          class = "d-flex gap-2 flex-wrap",
          actionButton("home_view_data", tr("View data"),
                       class = "btn-sm btn-outline-secondary"),
          actionButton("home_script", tr("Open script"),
                       class = "btn-sm btn-outline-secondary")
        )
      )
    })

    observeEvent(input$home_view_data, {
      state$show_tab(tr("Data"))
    }, ignoreInit = TRUE)

    observeEvent(input$home_script, {
      state$show_tab(tr("Script"))
    }, ignoreInit = TRUE)

    output$home_recent <- renderUI({
      tick()
      history_revision()
      entries <- history_recent(state, 5L)
      htmltools::tags$div(
        class = "rcmdr-home-card",
        htmltools::tags$h5(tr("Recent commands")),
        if (length(entries) == 0L) {
          htmltools::tags$p(class = "small text-muted mb-0",
                            tr("No commands yet."))
        } else {
          htmltools::tags$ul(
            class = "small mb-0",
            lapply(entries, function(entry) {
              htmltools::tags$li(
                paste0(history_command_label(entry, 70L), " \u00b7 ",
                       format(entry$time %||% Sys.time(), "%H:%M"))
              )
            })
          )
        }
      )
    })

    output$home_health <- renderUI({
      tick()
      language_revision()
      health_panel_ui(state)
    })

    observeEvent(input$health_refresh, {
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$health_diagnostics, {
      action <- direct_commands()[["helpDiagnostics"]]
      if (!is.null(action)) action(state)
    }, ignoreInit = TRUE)

    outputOptions(output, "history_cards", suspendWhenHidden = FALSE)
    outputOptions(output, "console_log", suspendWhenHidden = FALSE)
    outputOptions(output, "home_recent", suspendWhenHidden = FALSE)

    # -- data pane ----------------------------------------------------------

    output$data_info <- renderUI({
      tick()
      df <- dataset(state)
      if (is.null(df)) return(NULL)
      htmltools::tags$span(
        class = "text-muted",
        sprintf(tr("%d rows x %d columns, %d cells"),
                nrow(df), ncol(df), nrow(df) * ncol(df)),
        if (!editable_dataset(state)) {
          htmltools::tags$span(
            class = "text-warning",
            tr(" (editing disabled: threshold exceeded)")
          )
        }
      )
    })

    output$data_pane <- renderUI({
      tick()
      df <- dataset(state)
      if (is.null(df)) {
        return(htmltools::tags$p(class = "text-muted",
                                 tr("No active data set.")))
      }
      if (identical(input$data_mode %||% "view", "edit")) {
        if (!editable_dataset(state)) {
          return(htmltools::tags$div(
            class = "alert alert-warning",
            tr("This data set exceeds the interactive editing threshold.")
          ))
        }
        return(rhandsontable::rHandsontableOutput("data_editor"))
      }
      DT::dataTableOutput("data_table")
    })

    output$data_table <- DT::renderDataTable({
      tick()
      df <- dataset(state)
      req(df)
      DT::datatable(
        df,
        options = list(pageLength = 10, scrollX = TRUE, dom = "ftip"),
        rownames = FALSE
      )
    }, server = FALSE)

    output$data_editor <- rhandsontable::renderRHandsontable({
      tick()
      df <- dataset(state)
      req(df, editable_dataset(state))
      rhandsontable::rhandsontable(
        df, height = 480, stretchH = "all", useTypes = TRUE
      )
    })

    action_clicked <- function(value) {
      if (is.null(value) || length(value) == 0L) return(FALSE)
      if (is.character(value)) return(any(value == "click"))
      value <- suppressWarnings(as.numeric(value))
      length(value) == 1L && !is.na(value) && value > 0
    }

    data_selected_column <- reactive({
      tick()
      data_grid_revision()
      df <- dataset(state)
      if (is.null(df) || ncol(df) == 0L) return(NULL)
      column <- input$data_inspector_column %||% ""
      if (!nzchar(column) || !column %in% names(df)) column <- names(df)[[1L]]
      column
    })

    observeEvent(input$data_dictionary, {
      if (!action_clicked(input$data_dictionary)) return()
      open_dialog_memory(state, "dataDictionary",
                         list(variable = data_selected_column()))
    }, ignoreInit = TRUE)

    observeEvent(input$data_checkpoints, {
      if (!action_clicked(input$data_checkpoints)) return()
      open_dialog_memory(state, "dataCheckpoints", list())
    }, ignoreInit = TRUE)

    observeEvent(input$data_create_subset, {
      if (!action_clicked(input$data_create_subset)) return()
      open_dialog_memory(state, "dataCreateSubset", list())
    }, ignoreInit = TRUE)

    observeEvent(input$data_delete_rows, {
      if (!action_clicked(input$data_delete_rows)) return()
      rows <- data_selection(state)$rows
      if (length(rows) == 0L) {
        showNotification(tr("Select one or more rows first."),
                         type = "message", duration = 4)
        return()
      }
      open_dialog_memory(state, "dataDeleteRows", list(rows = rows))
    }, ignoreInit = TRUE)

    observeEvent(input$data_duplicate_column, {
      if (!action_clicked(input$data_duplicate_column)) return()
      column <- data_selected_column()
      req(column)
      open_dialog_memory(state, "dataDuplicateColumn", list(variable = column))
    }, ignoreInit = TRUE)

    observeEvent(input$data_add_column, {
      if (!action_clicked(input$data_add_column)) return()
      open_dialog_memory(state, "dataAddColumn", list())
    }, ignoreInit = TRUE)

    observeEvent(input$data_col_type, {
      if (!action_clicked(input$data_col_type)) return()
      column <- data_selected_column()
      req(column)
      open_dialog_memory(state, "dataColumnType", list(variable = column))
    }, ignoreInit = TRUE)

    observeEvent(input$data_col_label, {
      if (!action_clicked(input$data_col_label)) return()
      column <- data_selected_column()
      req(column)
      open_dialog_memory(state, "dataDictionary", list(variable = column))
    }, ignoreInit = TRUE)

    refresh_data_ui <- function(touch_dataset = TRUE) {
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)
      if (isTRUE(touch_dataset)) {
        data_grid_revision(data_grid_revision() + 1L)
      }
      invisible(NULL)
    }

    run_data_commands <- function(commands, checkpoint_label = NULL,
                                  destructive = FALSE) {
      commands <- commands %||% character()
      commands <- commands[nzchar(commands)]
      if (length(commands) == 0L) return(invisible(FALSE))
      if (isTRUE(destructive)) {
        checkpoint_create(state, checkpoint_label %||% tr("Before Data Studio change"))
      }
      ok <- TRUE
      for (command in commands) {
        outcome <- run_command(state, command, source = "data")
        if (!identical(outcome$status, "ok")) ok <- FALSE
      }
      refresh_data_ui()
      invisible(ok)
    }

    observeEvent(input$data_apply, {
      if (!action_clicked(input$data_apply)) return()
      editor <- input$data_studio_editor %||% input$data_editor
      req(editor)
      df <- tryCatch(
        rhandsontable::hot_to_r(editor),
        error = function(e) NULL
      )
      if (is.null(df) || !is.data.frame(df)) {
        showNotification(tr("The edited data are not valid."),
                         type = "error", duration = 6)
        return()
      }
      old <- dataset(state)
      commands <- cmd_edit_cells(active_dataset(state), old, df)
      if (length(commands) == 0L) {
        showNotification(tr("No changes to apply."), type = "message",
                         duration = 3)
        return()
      }
      run_data_commands(
        commands,
        checkpoint_label = tr("Before cell editing"),
        destructive = TRUE
      )
      showNotification(tr("Data set updated."), type = "message", duration = 3)
    }, ignoreInit = TRUE)

    observeEvent(input$data_refresh, {
      if (!action_clicked(input$data_refresh)) return()
      dataset_register(state, active_dataset(state), refresh = TRUE)
      refresh_data_ui()
    }, ignoreInit = TRUE)

    # -- Data Studio --------------------------------------------------------

    output$data_dataset_selector <- renderUI({
      tick()
      data_grid_revision()
      registry <- dataset_registry(state)
      if (nrow(registry) == 0L) {
        return(htmltools::tags$span(class = "text-muted small",
                                    tr("No data sets registered")))
      }
      labels <- sprintf("%s (%d x %d)", registry$name, registry$rows,
                        registry$cols)
      selectInput(
        "data_dataset_choice", tr("Active data set"),
        choices = stats::setNames(registry$name, labels),
        selected = active_dataset(state),
        width = "100%"
      )
    })

    observeEvent(input$data_dataset_choice, {
      choice <- input$data_dataset_choice %||% ""
      if (!nzchar(choice) || identical(choice, active_dataset(state))) return()
      dataset_activate(state, choice)
      clear_data_selection(state)
      data_selection_revision(data_selection_revision() + 1L)
      refresh_data_ui()
    }, ignoreInit = TRUE)

    data_filter_value_d <- shiny::debounce(
      reactive(input$data_filter_value %||% ""), 300
    )

    output$data_filter_ui <- renderUI({
      tick()
      data_grid_revision()
      df <- dataset(state)
      if (is.null(df)) return(NULL)
      choices <- stats::setNames(
        c("", names(df)),
        c(tr("(no column filter)"), names(df))
      )
      selected <- isolate(input$data_filter_column %||% "")
      if (!selected %in% names(df)) selected <- ""
      value <- isolate(input$data_filter_value %||% "")
      htmltools::div(
        class = "d-flex gap-2 align-items-end",
        selectInput("data_filter_column", NULL, choices = choices,
                    selected = selected, width = "190px"),
        textInput("data_filter_value", NULL, value = value,
                  placeholder = tr("Filter value"), width = "150px"),
        actionButton("data_filter_clear", tr("Clear filter"),
                     class = "btn-sm btn-outline-secondary")
      )
    })

    data_view_frame <- reactive({
      tick()
      data_grid_revision()
      df <- dataset(state)
      if (is.null(df)) return(NULL)
      grid <- data_grid_frame(df)
      column <- input$data_filter_column %||% ""
      value <- trim_blanks(data_filter_value_d() %||% "")
      if (!nzchar(column) || !column %in% names(grid) || !nzchar(value)) {
        return(grid)
      }
      x <- grid[[column]]
      keep <- tryCatch({
        if (is.numeric(x)) {
          number <- suppressWarnings(as.numeric(value))
          if (!is.na(number)) {
            !is.na(x) & x == number
          } else {
            grepl(value, as.character(x), ignore.case = TRUE, fixed = TRUE)
          }
        } else {
          grepl(value, as.character(x), ignore.case = TRUE, fixed = TRUE)
        }
      }, error = function(e) rep(TRUE, nrow(grid)))
      grid[keep %in% TRUE, , drop = FALSE]
    })

    observeEvent(input$data_filter_clear, {
      if (!action_clicked(input$data_filter_clear)) return()
      updateSelectInput(session, "data_filter_column", selected = "")
      updateTextInput(session, "data_filter_value", value = "")
      data_grid_revision(data_grid_revision() + 1L)
    }, ignoreInit = TRUE)

    output$data_grid <- renderUI({
      tick()
      data_grid_revision()
      df <- dataset(state)
      if (is.null(df)) {
        return(empty_state(
          tr("No active data set"),
          tr("Import a file or load a data set from a package to start.")
        ))
      }
      mode <- input$data_mode %||% "view"
      if (identical(mode, "edit") && editable_dataset(state)) {
        return(rhandsontable::rHandsontableOutput("data_studio_editor"))
      }
      targeted <- identical(mode, "edit") && !editable_dataset(state)
      server_mode <- nrow(df) > (state$options$dt_server_threshold %||% 5000L)
      htmltools::tagList(
        if (targeted) {
          htmltools::tags$div(
            class = "alert alert-warning py-2",
            tr("This data set is above the interactive editing threshold. Targeted column and row actions remain available.")
          )
        },
        if (server_mode) {
          DT::dataTableOutput("data_studio_table_server")
        } else {
          DT::dataTableOutput("data_studio_table")
        }
      )
    })

    output$data_studio_table <- DT::renderDataTable({
      tick()
      data_grid_revision()
      grid <- data_view_frame()
      req(grid)
      DT::datatable(
        grid,
        selection = "none",
        callback = grid_selection_callback(),
        options = list(
          pageLength = 25L, scrollX = TRUE, searchHighlight = TRUE,
          autoWidth = TRUE,
          columnDefs = list(
            list(visible = FALSE, targets = ncol(grid) - 1L)
          )
        ),
        rownames = FALSE
      )
    }, server = FALSE)

    output$data_studio_table_server <- DT::renderDataTable({
      tick()
      data_grid_revision()
      grid <- data_view_frame()
      req(grid)
      DT::datatable(
        grid,
        selection = "none",
        callback = grid_selection_callback(),
        options = list(
          pageLength = 25L, scrollX = TRUE, autoWidth = TRUE,
          dom = "ftip",
          columnDefs = list(
            list(visible = FALSE, targets = ncol(grid) - 1L)
          )
        ),
        rownames = FALSE
      )
    }, server = TRUE)

    output$data_studio_editor <- rhandsontable::renderRHandsontable({
      tick()
      data_grid_revision()
      df <- dataset(state)
      req(df, editable_dataset(state))
      rhandsontable::rhandsontable(
        df, height = 520, stretchH = "all", useTypes = TRUE
      ) |>
        rhandsontable::hot_context_menu(allowRowEdit = TRUE,
                                        allowColEdit = FALSE) |>
        rhandsontable::hot_cols(manualColumnResize = TRUE, columnSorting = TRUE) |>
        rhandsontable::hot_rows(rowHeights = 28)
    })

    output$data_inspector <- renderUI({
      tick()
      data_grid_revision()
      data_selection_revision()
      df <- dataset(state)
      if (is.null(df)) return(NULL)
      column <- data_selected_column()
      profile <- column_profile(state, active_dataset(state), column)
      htmltools::tags$div(
        class = "rcmdr-section-card",
        selectInput(
          "data_inspector_column", tr("Column"),
          choices = stats::setNames(names(df), names(df)),
          selected = column, width = "100%"
        ),
        data_inspector_ui(profile),
        if (!is.null(column)) variable_suggestions_ui(state, column)
      )
    })

    observeEvent(input$variable_suggestion, {
      action <- input$variable_suggestion
      if (is.null(action) || is.null(action$variable) ||
          is.null(action$dialog)) {
        return()
      }
      if (!action$dialog %in% dialog_ids()) return()
      open_dialog_memory(
        state, action$dialog,
        suggestion_memory(state, action$variable, action$dialog)
      )
    }, ignoreInit = TRUE)

    output$data_selection_columns_ui <- renderUI({
      tick()
      data_grid_revision()
      data_selection_revision()
      df <- dataset(state)
      if (is.null(df)) return(NULL)
      selectizeInput(
        "data_selection_columns", tr("Columns for subset"),
        choices = stats::setNames(names(df), names(df)),
        selected = data_selection(state)$columns,
        multiple = TRUE, width = "100%"
      )
    })

    output$data_profile_plot <- renderPlot({
      tick()
      data_grid_revision()
      column <- data_selected_column()
      req(column)
      profile <- column_profile(state, active_dataset(state), column)
      req(profile)
      graphics::par(mar = c(3, 3, 1, 1))
      if (!is.null(profile$histogram)) {
        graphics::barplot(
          profile$histogram$counts,
          names.arg = format(profile$histogram$mids, digits = 3),
          col = "#4c78a8", border = NA, las = 2, cex.names = 0.7,
          main = "", ylab = "", xlab = ""
        )
      } else if (!is.null(profile$levels)) {
        top <- utils::head(profile$levels, 10L)
        graphics::barplot(
          top$count, names.arg = top$value, col = "#4c78a8", border = NA,
          las = 2, cex.names = 0.7, ylab = "", xlab = ""
        )
      } else {
        graphics::plot.new()
      }
    })

    output$data_missingness <- renderUI({
      tick()
      data_grid_revision()
      data_missingness_ui(data_missingness(state))
    })

    output$data_selection_bar <- renderUI({
      tick()
      data_selection_revision()
      selection <- data_selection(state)
      htmltools::tags$div(
        class = "rcmdr-selection-bar",
        htmltools::tags$span(selection_summary(state)),
        if (length(selection$rows) > 0L || length(selection$columns) > 0L ||
            nzchar(selection$expression %||% "")) {
          actionButton("data_selection_clear", tr("Clear selection"),
                       class = "btn-sm btn-link")
        }
      )
    })

    observeEvent(input$data_grid_selection, {
      rows <- input$data_grid_selection %||% integer()
      rows <- as.integer(rows)
      rows <- rows[!is.na(rows)]
      columns <- data_selection(state)$columns
      set_data_selection(state, rows = rows, columns = columns)
      data_selection_revision(data_selection_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$data_selection_columns, {
      rows <- data_selection(state)$rows
      set_data_selection(
        state, rows = rows,
        columns = input$data_selection_columns %||% character()
      )
      data_selection_revision(data_selection_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$data_selection_clear, {
      if (!action_clicked(input$data_selection_clear)) return()
      clear_data_selection(state)
      data_selection_revision(data_selection_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$data_search, {
      df <- dataset(state)
      if (is.null(df)) return()
      id <- if (nrow(df) > (state$options$dt_server_threshold %||% 5000L)) {
        "data_studio_table_server"
      } else {
        "data_studio_table"
      }
      tryCatch({
        proxy <- DT::dataTableProxy(id, session = session)
        DT::updateSearch(
          proxy,
          keywords = list(global = input$data_search %||% "")
        )
      }, error = function(e) NULL)
    }, ignoreInit = TRUE)

    observeEvent(input$data_import_wizard, {
      if (!action_clicked(input$data_import_wizard)) return()
      state$open_dialog("dataImportWizard")
    }, ignoreInit = TRUE)

    observeEvent(input$data_col_summary, {
      if (!action_clicked(input$data_col_summary)) return()
      column <- data_selected_column()
      req(column)
      if (!column %in% numeric_variables(state)) {
        showNotification(tr("Numerical summaries need a numeric variable."),
                         type = "message", duration = 5)
        return()
      }
      open_dialog_memory(state, "numericalSummaries", list(x = column))
    }, ignoreInit = TRUE)

    observeEvent(input$data_col_plot, {
      if (!action_clicked(input$data_col_plot)) return()
      column <- data_selected_column()
      req(column)
      df <- dataset(state)
      if (is.numeric(df[[column]])) {
        open_dialog_memory(state, "Histogram", list(variable = column))
      } else {
        open_dialog_memory(state, "barGraph", list(variable = column))
      }
    }, ignoreInit = TRUE)



    observeEvent(input$data_col_rename, {
      if (!action_clicked(input$data_col_rename)) return()
      column <- data_selected_column()
      req(column)
      open_dialog_memory(state, "renameVariables",
                         list(variables = column, names = column))
    }, ignoreInit = TRUE)



    observeEvent(input$data_col_recode, {
      if (!action_clicked(input$data_col_recode)) return()
      column <- data_selected_column()
      req(column)
      open_dialog_memory(state, "RecodeDialog", list(variables = column))
    }, ignoreInit = TRUE)

    observeEvent(input$data_col_delete, {
      if (!action_clicked(input$data_col_delete)) return()
      column <- data_selected_column()
      req(column)
      open_dialog_memory(state, "deleteVariable", list(variables = column))
    }, ignoreInit = TRUE)



    observeEvent(input$data_add_row, {
      if (!action_clicked(input$data_add_row)) return()
      run_data_commands(
        cmd_add_row(active_dataset(state)),
        checkpoint_label = tr("Before adding a row"),
        destructive = TRUE
      )
    }, ignoreInit = TRUE)

    observeEvent(input$data_duplicate_rows, {
      if (!action_clicked(input$data_duplicate_rows)) return()
      rows <- data_selection(state)$rows
      if (length(rows) == 0L) {
        showNotification(tr("Select one or more rows first."),
                         type = "message", duration = 4)
        return()
      }
      run_data_commands(
        cmd_duplicate_rows(active_dataset(state), rows),
        checkpoint_label = tr("Before duplicating rows"),
        destructive = TRUE
      )
    }, ignoreInit = TRUE)






    output$download_dictionary_csv <- downloadHandler(
      filename = function() {
        paste0(active_dataset(state) %||% "dictionary", "-dictionary.csv")
      },
      content = function(file) {
        utils::write.csv(dictionary_export(state), file, row.names = FALSE)
      }
    )

    output$download_dictionary_yaml <- downloadHandler(
      filename = function() {
        paste0(active_dataset(state) %||% "dictionary", "-dictionary.yml")
      },
      content = function(file) {
        table <- dictionary_export(state)
        entries <- lapply(seq_len(nrow(table)), function(i) {
          list(
            variable = table$variable[[i]],
            label = table$label[[i]],
            units = table$units[[i]],
            description = table$description[[i]]
          )
        })
        names(entries) <- table$variable
        yaml::write_yaml(entries, file)
      }
    )

    output$environment_pane <- renderUI({
      tick()
      objects <- ls(envir = state$env)
      if (length(objects) == 0L) {
        return(htmltools::tags$p(class = "text-muted",
                                 tr("The environment is empty.")))
      }
      info <- data.frame(
        name = objects,
        class = vapply(objects, function(x) {
          paste(class(get(x, envir = state$env)), collapse = ", ")
        }, character(1)),
        size = vapply(objects, function(x) {
          object <- get(x, envir = state$env)
          if (is.data.frame(object)) {
            sprintf("%d x %d", nrow(object), ncol(object))
          } else {
            as.character(utils::object.size(object))
          }
        }, character(1)),
        stringsAsFactors = FALSE
      )
      DT::datatable(info, rownames = FALSE, options = list(dom = "t"))
    })

    # -- environment and models ---------------------------------------------

    output$environment_objects <- renderUI({
      tick()
      environment_objects_ui(state, input$environment_filter %||% "")
    })

    output$environment_preview <- renderUI({
      tick()
      preview <- state$environment_preview
      if (is.null(preview) || !nzchar(preview)) {
        return(help_text(tr("Select Preview on an object to inspect it here.")))
      }
      htmltools::tags$pre(class = "rcmdr-object-preview", preview)
    })

    output$environment_datasets <- renderUI({
      tick()
      environment_datasets_ui(state)
    })

    output$models_dashboard <- renderUI({
      tick()
      menu_revision()
      models_dashboard_ui(state)
    })

    outputOptions(output, "environment_objects", suspendWhenHidden = FALSE)
    outputOptions(output, "environment_preview", suspendWhenHidden = FALSE)
    outputOptions(output, "environment_datasets", suspendWhenHidden = FALSE)
    outputOptions(output, "models_dashboard", suspendWhenHidden = FALSE)

    observeEvent(input$environment_action, {
      action <- input$environment_action
      if (is.null(action) || !nzchar(action$name %||% "")) return()
      result <- object_action(state, action$name, action$action %||% "preview")
      if (!isTRUE(result$ok) && nzchar(result$message %||% "")) {
        showNotification(result$message, type = "message", duration = 5)
      }
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$environment_refresh, {
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$environment_refresh_datasets, {
      dataset_registry(state)
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    observeEvent(input$model_action, {
      action <- input$model_action
      if (is.null(action) || !nzchar(action$name %||% "")) return()
      result <- model_action(state, action$name, action$action %||% "select")
      if (!isTRUE(result$ok) && nzchar(result$message %||% "")) {
        showNotification(result$message, type = "message", duration = 5)
      }
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)
    }, ignoreInit = TRUE)

    # -- plots --------------------------------------------------------------

    current_plot <- reactive({
      tick()
      n <- length(state$plots)
      if (n == 0L) return(NULL)
      index <- plot_selected()
      if (is.null(index) || index < 1L || index > n) index <- n
      state$plots[[index]]
    })

    observeEvent(input$plot_selected, {
      plot_selected(input$plot_selected)
    }, ignoreInit = TRUE)

    observeEvent(tick(), {
      n <- length(state$plots)
      if (n > last_plot_count()) {
        plot_selected(NULL)
        last_plot_count(n)
      }
    }, ignoreInit = TRUE)

    output$plot_gallery <- renderUI({
      tick()
      n <- length(state$plots)
      if (n == 0L) return(NULL)
      active <- plot_selected()
      if (is.null(active) || active < 1L || active > n) active <- n
      htmltools::div(
        class = "rcmdr-gallery",
        lapply(seq_len(n), function(index) {
          plot <- state$plots[[index]]
          htmltools::tags$img(
            src = plot$url %||% "",
            class = paste("rcmdr-thumb", if (index == active) "active"),
            title = plot$code, alt = plot$code,
            onclick = sprintf(
              "Shiny.setInputValue('plot_selected', %d, {priority: 'event'})",
              index
            )
          )
        })
      )
    })

    output$plotly_pane <- renderUI({
      tick()
      if (!plotly_available() || is.null(state$plotly_widget)) return(NULL)
      htmltools::tagList(
        htmltools::tags$h6(state$plotly_title %||% tr("Interactive plot")),
        plotly::plotlyOutput("plotly_plot", height = "480px")
      )
    })

    if (plotly_available()) {
      output$plotly_plot <- plotly::renderPlotly({
        tick()
        req(state$plotly_widget)
        state$plotly_widget
      })
    }

    output$plot_image <- renderImage({
      plot <- current_plot()
      req(plot)
      list(src = plot$file, contentType = "image/png", alt = plot$code)
    }, deleteFile = FALSE)

    output$plot_header <- renderUI({
      tick()
      if (length(state$plots) == 0L) {
        return(htmltools::tags$p(class = "text-muted", tr("No plot yet.")))
      }
      plot <- current_plot()
      req(plot)
      htmltools::tags$div(
        class = "mb-2",
        htmltools::tags$strong(sprintf(
          tr("Plot %d of %d"),
          plot_selected() %||% length(state$plots), length(state$plots)
        )),
        htmltools::tags$pre(class = "small text-muted mb-1", plot$code)
      )
    })

    output$rgl_pane <- renderUI({
      tick()
      if (is.null(state$rgl_widget)) return(NULL)
      htmltools::tagList(
        htmltools::tags$h6(tr("3D plot")),
        if (requireNamespace("rgl", quietly = TRUE)) {
          rgl::rglwidgetOutput("rgl_plot", height = "420px")
        }
      )
    })

    if (requireNamespace("rgl", quietly = TRUE)) {
      output$rgl_plot <- rgl::renderRglwidget({
        tick()
        req(state$rgl_widget)
        state$rgl_widget
      })
    }

    # -- Chart Studio -------------------------------------------------------

    chart_studio_server(
      input, output, session, state, chart_revision,
      tick = tick,
      refresh = function(...) {
        tick(tick() + 1L)
        menu_revision(menu_revision() + 1L)
        history_revision(history_revision() + 1L)
        chart_revision(chart_revision() + 1L)
        invisible(NULL)
      }
    )

    # -- Report Studio ------------------------------------------------------

    report_studio_server(
      input, output, session, state,
      tick = tick,
      refresh = function(...) {
        tick(tick() + 1L)
        menu_revision(menu_revision() + 1L)
        history_revision(history_revision() + 1L)
        invisible(NULL)
      }
    )

    # -- downloads ----------------------------------------------------------

    output$download_report_rmd <- downloadHandler(
      filename = function() {
        paste0("rcmdrshiny-report-", Sys.Date(), ".Rmd")
      },
      content = function(file) {
        write_report_rmd(state, file,
                         title = state$report_title %||% "RcmdrShiny report")
      }
    )

    output$download_report_html <- downloadHandler(
      filename = function() {
        paste0("rcmdrshiny-report-", Sys.Date(), ".html")
      },
      content = function(file) {
        write_report_html(state, file,
                          title = state$report_title %||% "RcmdrShiny report")
      }
    )

    output$report_pane <- renderUI({
      tick()
      result <- state$knit_result
      if (is.null(result)) {
        return(htmltools::tags$p(
          class = "text-muted",
          tr("No report yet. Use Knit to build one.")
        ))
      }
      if (identical(result$format, "word")) {
        return(htmltools::tagList(
          htmltools::tags$p(tr("The Word document is ready for download.")),
          htmltools::tags$p(basename(result$file))
        ))
      }
      htmltools::tags$iframe(
        src = result$url %||% "",
        style = "width:100%;height:70vh;border:1px solid #dde2e8;"
      )
    })

    output$download_knit <- downloadHandler(
      filename = function() {
        if (is.null(state$knit_result)) {
          "report.html"
        } else {
          basename(state$knit_result$file)
        }
      },
      content = function(file) {
        req(state$knit_result)
        file.copy(state$knit_result$file, file, overwrite = TRUE)
      }
    )

    observeEvent(input$knit_refresh, {
      tick(tick() + 1L)
    }, ignoreInit = TRUE)

    output$download_script <- downloadHandler(
      filename = function() {
        mode <- document_mode(state)
        paste0("RcmdrShiny-script-", Sys.Date(),
               ".", document_extension(mode))
      },
      content = function(file) {
        writeLines(isolate(script_value()), file)
      }
    )

    output$download_output <- downloadHandler(
      filename = function() "RcmdrShiny-output.txt",
      content = function(file) {
        writeLines(isolate(paste(state$output, collapse = "\n")), file)
      }
    )

    output$download_dataset <- downloadHandler(
      filename = function() {
        name <- active_dataset(state) %||% "dataset"
        paste0(name, ".csv")
      },
      content = function(file) {
        df <- isolate(dataset(state))
        req(df)
        utils::write.csv(df, file, row.names = FALSE)
      }
    )

    output$download_dataset_rdata <- downloadHandler(
      filename = function() {
        name <- active_dataset(state) %||% "dataset"
        paste0(name, ".RData")
      },
      content = function(file) {
        name <- isolate(active_dataset(state))
        req(name)
        save(list = name, file = file, envir = state$env)
      }
    )

    output$download_workspace <- downloadHandler(
      filename = function() "RcmdrShiny-workspace.RData",
      content = function(file) {
        objects <- isolate(ls(envir = state$env))
        req(length(objects) > 0L)
        save(list = objects, file = file, envir = state$env)
      }
    )

    output$download_plot_png <- downloadHandler(
      filename = function() "RcmdrShiny-plot.png",
      content = function(file) {
        plot <- isolate(current_plot())
        req(plot)
        file.copy(plot$file, file, overwrite = TRUE)
      }
    )

    output$download_rgl <- downloadHandler(
      filename = function() "RcmdrShiny-3D.png",
      content = function(file) {
        req(state$rgl_widget)
        rgl::rgl.snapshot(file)
      }
    )

    output$download_plot_pdf <- downloadHandler(
      filename = function() "RcmdrShiny-plot.pdf",
      content = function(file) {
        plot <- isolate(current_plot())
        req(plot, plot$recorded)
        grDevices::pdf(file)
        on.exit(grDevices::dev.off(), add = TRUE)
        grDevices::replayPlot(plot$recorded)
      }
    )

    # -- language -----------------------------------------------------------

    observeEvent(input$language, {
      language <- i18n_normalize(input$language %||% "en")
      state$options$language <- language
      i18n_set_language(language)
      state$palette_cache <- NULL
      persist_preferences()
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      language_revision(language_revision() + 1L)
      showNotification(
        tr("Language changed. Menus, help and new output use the new language."),
        type = "message", duration = 5
      )
    }, ignoreInit = TRUE)

    # -- status bar and badges ---------------------------------------------

    output$dataset_badge <- renderUI({
      tick()
      name <- active_dataset(state)
      htmltools::tags$span(
        if (is.null(name)) tr("No active data set") else name,
        class = if (is.null(name)) "text-warning" else "text-white"
      )
    })

    output$model_badge <- renderUI({
      tick()
      name <- active_model(state)
      htmltools::tags$span(
        if (is.null(name)) tr("No active model") else name,
        class = if (is.null(name)) "text-white-50" else "text-white"
      )
    })

    output$statusbar <- renderUI({
      tick()
      version <- tryCatch(
        as.character(utils::packageVersion("RcmdrShiny")),
        error = function(e) "0.1.0"
      )
      df <- dataset(state)
      dimensions <- if (is.null(df)) {
        tr("no data")
      } else {
        sprintf("%d x %d", nrow(df), ncol(df))
      }
      htmltools::tagList(
        htmltools::tags$span(sprintf(tr("RcmdrShiny Studio %s"), version)),
        htmltools::tags$span(" | "),
        htmltools::tags$span(toupper(ui_mode(state))),
        htmltools::tags$span(" | "),
        htmltools::tags$span(dimensions),
        htmltools::tags$span(" | "),
        htmltools::tags$span(sprintf(tr("%d command(s)"), length(state$log))),
        htmltools::tags$span(" | "),
        htmltools::tags$span(sprintf(tr("%d history step(s)"),
                                      length(state$history %||% list()))),
        htmltools::tags$span(" | "),
        htmltools::tags$span(sprintf(tr("%d plot(s)"), length(state$plots))),
        if (isTRUE(state$busy)) {
          htmltools::tags$span(class = "rcmdr-busy", tr(" | busy"))
        },
        if (!is.null(state$last_error)) {
          htmltools::tags$span(
            class = "text-danger",
            sprintf(tr(" | last error: %s"), state$last_error)
          )
        }
      )
    })

    # -- script pane --------------------------------------------------------

    observeEvent(input$script, {
      value <- input$script %||% ""
      if (!identical(isolate(script_value()), value)) {
        script_value(value)
        document_set_text(state, value)
      }
    }, ignoreInit = TRUE)

    observeEvent(tick(), {
      mode <- document_mode(state)
      if (!identical(mode, isolate(editor_mode()))) {
        editor_mode(mode)
        script_value(document_text(state))
      }
    }, ignoreInit = FALSE)

    append_log_to_script <- function() {
      if (!isTRUE(input$auto_append)) return(invisible(NULL))
      if (length(state$log) <= state$script_consumed) return(invisible(NULL))
      new_commands <- state$log[seq.int(state$script_consumed + 1L, length(state$log))]
      state$script_consumed <- length(state$log)
      if (!identical(document_mode(state), "r")) {
        current_document_text()
        for (command in new_commands) document_append_chunk(state, command)
        sync_editor()
        return(invisible(NULL))
      }
      value <- paste(c(isolate(script_value()), new_commands), collapse = "\n")
      script_value(value)
      shinyAce::updateAceEditor(session, "script", value = value)
      invisible(NULL)
    }

    observeEvent(tick(), append_log_to_script(), ignoreInit = TRUE)

    run_script <- function(code) {
      if (is.null(code) || !nzchar(trimws(code))) return(invisible(NULL))
      state$busy <- TRUE
      result <- script_execute(state, code, source = "script")
      state$busy <- FALSE
      tick(tick() + 1L)
      menu_revision(menu_revision() + 1L)
      history_revision(history_revision() + 1L)
      if (identical(result$status, "error")) {
        showNotification(
          result$error %||% tr("The script produced an error."),
          type = "error", duration = 8
        )
      }
      invisible(result)
    }

    observeEvent(input$run_all, {
      code <- isolate(script_value())
      mode <- document_mode(state)
      if (!identical(mode, "r")) {
        code <- document_script_from_chunks(code, mode)
      }
      run_script(code)
    }, ignoreInit = TRUE)

    observeEvent(input$run_selection, {
      selection <- input$script_selection %||% ""
      run_script(if (nzchar(trimws(selection))) selection else script_value())
    }, ignoreInit = TRUE)

    observeEvent(input$run_chunk_at, {
      position <- input$run_chunk_at
      row <- position$row %||% 0
      code <- document_chunk_at(current_document_text(), row,
                                document_mode(state))
      if (nzchar(trimws(code))) run_script(code)
    }, ignoreInit = TRUE)

    observeEvent(input$clear_script, {
      if (!identical(document_mode(state), "r")) {
        document_set_text(state, "")
      }
      script_value("")
      shinyAce::updateAceEditor(session, "script", value = "")
    }, ignoreInit = TRUE)

    observeEvent(input$document_mode, {
      mode <- input$document_mode %||% "r"
      if (!identical(mode, document_mode(state))) {
        document_switch_mode(state, mode)
        editor_mode(mode)
        sync_editor()
        menu_revision(menu_revision() + 1L)
      }
    }, ignoreInit = TRUE)

    observeEvent(input$document_new, {
      if (identical(document_mode(state), "r")) {
        current_document_text()
        script_create(state)
        sync_editor()
        tick(tick() + 1L)
        menu_revision(menu_revision() + 1L)
        return()
      }
      state$open_dialog(
        if (identical(document_mode(state), "rnw")) "newRnw" else "newRmd"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$document_open, {
      document_open_current(state, document_mode(state))
    }, ignoreInit = TRUE)

    observeEvent(input$document_save, {
      current_document_text()
      document_save_current(state)
    }, ignoreInit = TRUE)

    observeEvent(input$document_save_as, {
      current_document_text()
      state$open_dialog(
        if (identical(document_mode(state), "rnw")) "saveRnwAs" else "saveRmdAs"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$document_knit, {
      current_document_text()
      document_knit_current(state)
    }, ignoreInit = TRUE)

    observeEvent(input$document_section, {
      state$open_dialog("insertSection")
    }, ignoreInit = TRUE)

    observeEvent(input$document_chunk, {
      state$open_dialog("insertChunk")
    }, ignoreInit = TRUE)

    observeEvent(input$document_remove_block, {
      current_document_text()
      removed <- document_remove_current_chunk(state)
      if (isTRUE(removed)) sync_editor()
    }, ignoreInit = TRUE)

    observeEvent(input$document_remove_section, {
      current_document_text()
      removed <- document_remove_current_section(state)
      if (isTRUE(removed)) sync_editor()
    }, ignoreInit = TRUE)

    # -- Script Studio ------------------------------------------------------

    script_studio_server(
      input, output, session, state,
      tick = tick,
      run_code = run_script,
      refresh = function(...) {
        tick(tick() + 1L)
        menu_revision(menu_revision() + 1L)
        history_revision(history_revision() + 1L)
        invisible(NULL)
      }
    )
  }
}

#' Create the RcmdrShiny application
#'
#' @param env Evaluation environment for user commands.  Defaults to the
#'   global environment.
#' @return A `shiny.appobj`.
#' @export
app <- function(env = globalenv(), plugins = NULL) {
  saved <- tryCatch(saved_plugin_selection(), error = function(e) character())
  load_plugins(resolve_startup_plugins(plugins, saved))
  persisted <- tryCatch(preferences_peek(), error = function(e) list())
  if (is.character(persisted$language) && length(persisted$language) == 1L &&
      nzchar(persisted$language)) {
    i18n_set_language(persisted$language)
  }
  shinyApp(ui = app_ui(), server = app_server(env))
}

#' Run RcmdrShiny
#'
#' Starts the local Shiny application in the browser.
#'
#' @param env Evaluation environment for user commands.
#' @param language Language code for the session (for example `"en"` or
#'   `"it"`).  Defaults to the current language.
#' @param ... Further arguments passed to [shiny::runApp()].
#' @return The value returned by [shiny::runApp()], invisibly.
#' @examples
#' \dontrun{
#' RcmdrShiny::run()
#' }
#' @export
run_app <- function(env = globalenv(), language = NULL, plugins = NULL, ...) {
  if (!is.null(language)) Sys.setenv(LANGUAGE = language)
  shiny::runApp(app(env = env, plugins = plugins), ...)
}

#' @rdname run_app
#' @export
run <- run_app
