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

test_that("the shortcut modal carries the shared chrome", {
  modal <- as.character(shortcuts_modal())
  expect_match(modal, 'class="modal-header rcmdr-modal-header"', fixed = TRUE)
  expect_match(modal, 'class="modal-footer rcmdr-modal-footer"', fixed = TRUE)
  expect_match(modal, 'id="rcmdr-modal-title">Keyboard shortcuts</h4>',
               fixed = TRUE)
  expect_match(modal, 'class="rcmdr-dialog-category">Help', fixed = TRUE)
  expect_match(modal, 'aria-labelledby="rcmdr-modal-title"', fixed = TRUE)
  expect_match(modal, 'class="btn btn-sm btn-outline-secondary"', fixed = TRUE)
  expect_false(grepl('small text-muted', modal, fixed = TRUE))
  # One header and one footer, both ours.
  expect_length(regmatches(modal, gregexpr('class="modal-header', modal))[[1L]],
                1L)
  expect_length(regmatches(modal, gregexpr('class="modal-footer', modal))[[1L]],
                1L)
})
