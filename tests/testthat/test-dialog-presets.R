test_that("presets can be saved, read and deleted", {
  state <- AppState(env = new.env())
  saved <- dialog_preset_save(
    state, "numericalSummaries", "Default",
    list(mean = TRUE, sd = TRUE)
  )
  expect_true(saved$ok)
  expect_equal(names(dialog_presets_for(state, "numericalSummaries")), "Default")
  expect_equal(
    dialog_preset_get(state, "numericalSummaries", "Default")$mean,
    TRUE
  )

  expect_false(dialog_preset_save(state, "numericalSummaries", " ", list())$ok)
  deleted <- dialog_preset_delete(state, "numericalSummaries", "Default")
  expect_true(deleted$ok)
  expect_length(dialog_presets_for(state, "numericalSummaries"), 0L)
  expect_false(dialog_preset_delete(state, "numericalSummaries", "Missing")$ok)
})

test_that("presets export and import with a version check", {
  state <- AppState(env = new.env())
  dialog_preset_save(state, "numericalSummaries", "Default", list(mean = TRUE))
  exported <- dialog_presets_export(state)

  expect_equal(exported$application, "RcmdrShiny")
  expect_equal(exported$version, dialog_presets_version())
  expect_equal(names(exported$presets), "numericalSummaries")

  target <- AppState(env = new.env())
  imported <- dialog_presets_import(target, exported)
  expect_true(imported$ok)
  expect_equal(imported$imported, 1L)
  expect_equal(
    dialog_preset_get(target, "numericalSummaries", "Default")$mean,
    TRUE
  )

  twice <- dialog_presets_import(target, exported, overwrite = FALSE)
  expect_true(twice$ok)
  expect_equal(twice$imported, 0L)

  broken <- exported
  broken$version <- 99L
  expect_false(dialog_presets_import(target, broken)$ok)
  expect_false(dialog_presets_import(target, list())$ok)
})

test_that("presets round-trip through an RDS file", {
  state <- AppState(env = new.env())
  dialog_preset_save(state, "numericalSummaries", "Default", list(mean = TRUE))
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)

  written <- dialog_presets_save_file(state, path)
  expect_true(written$ok)
  expect_true(file.exists(path))

  target <- AppState(env = new.env())
  loaded <- dialog_presets_load_file(target, path)
  expect_true(loaded$ok)
  expect_equal(loaded$imported, 1L)

  expect_false(dialog_presets_save_file(state, "")$ok)
  expect_false(dialog_presets_load_file(target, tempfile())$ok)
})

test_that("preferences persist favourites, recents and presets", {
  state <- AppState(env = new.env())
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  state$options$preferences_file <- path
  state$options$persist_preferences <- TRUE

  menu_favorite_toggle(state, "numericalSummaries")
  menu_recent_add(state, "readDataSet")
  dialog_preset_save(state, "numericalSummaries", "Default", list(mean = TRUE))

  expect_true(preferences_save(state))

  target <- AppState(env = new.env())
  target$options$preferences_file <- path
  target$options$persist_preferences <- TRUE
  expect_true(preferences_load(target))
  expect_equal(menu_favorite_ids(target), "numericalSummaries")
  expect_equal(menu_recent_ids(target), "readDataSet")
  expect_equal(names(dialog_presets_for(target, "numericalSummaries")), "Default")

  preferences_clear(target, remove = TRUE)
  expect_length(menu_favorite_ids(target), 0L)
  expect_false(file.exists(path))
})

test_that("preferences can be disabled", {
  state <- AppState(env = new.env())
  state$options$preferences_file <- tempfile(fileext = ".rds")
  state$options$persist_preferences <- FALSE
  expect_false(preferences_save(state))
  expect_false(preferences_load(state))
})
