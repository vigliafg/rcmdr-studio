test_that("shortcut definitions cover palette, run, save, tabs and help", {
  definitions <- shortcut_definitions()
  expect_true(all(c("Ctrl+K", "Ctrl+Shift+P", "Ctrl+S", "Ctrl+Shift+S",
                    "Ctrl+Enter", "Ctrl+Shift+Enter", "Alt+1 ... Alt+9",
                    "F1", "Ctrl+/", "Esc") %in% definitions$keys))
  expect_equal(definitions$action[definitions$keys == "Ctrl+K"], "palette")
  expect_equal(definitions$action[definitions$keys == "Ctrl+Shift+P"],
               "palette")
})

test_that("the shortcut table and modal render", {
  html <- as.character(shortcuts_table_ui())
  expect_match(html, "rcmdr-shortcuts-table")
  expect_match(html, "Ctrl\\+K")

  modal <- as.character(shortcuts_modal())
  expect_match(modal, "Keyboard shortcuts")
  expect_match(modal, "modal-dialog")
})
