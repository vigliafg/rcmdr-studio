# Benchmark suite

The Studio benchmark is deliberately small.  It measures the paths that run on
every session and the caps that prevent unbounded memory growth.

```bash
Rscript tests/benchmarks/benchmark.R --quick   # smoke sizes
Rscript tests/benchmarks/benchmark.R           # 10k / 100k rows
Rscript tests/benchmarks/benchmark.R --csv results.csv
```

## Budgets

| Scenario | Budget |
|---|---:|
| Startup shell (`app_ui()` + `menu_tree()`) | 3000 ms |
| Import CSV, 1 000 rows | 1500 ms |
| Import CSV, 5 000 rows | 3000 ms |
| Import CSV, 10 000 rows | 3000 ms |
| Import CSV, 100 000 rows | 15 000 ms |
| Grid page, 1 000 rows | 500 ms |
| Grid page, 10 000 rows | 500 ms |
| Data grid first view, 10 000 rows | 1000 ms |
| Data grid first view, 50 000 rows | 1500 ms |
| Data grid first view, 100 000 rows | 2500 ms |
| 50 history entries | 500 ms |
| 100 history entries | 500 ms |
| 25 plot registrations | 500 ms |
| 50 plot registrations | 500 ms |
| Help index rebuild | 5000 ms |

Results above the budget are reported, not fatal.  A regression should be
investigated against the previous release, not against a single machine.

The unit suite calls `benchmark_suite(quick = TRUE)` in
`tests/testthat/test-performance.R`; browser E2E is separate.

The full suite also runs the data-grid scenarios at 10 000, 50 000 and 100 000
rows.  The per-size table behind the client/server threshold is
`benchmark_data_scale()`, documented in
[`docs/upgrades/QA-DATA.md`](../docs/upgrades/QA-DATA.md).
