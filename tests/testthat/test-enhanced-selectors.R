test_that("variable selectors keep the variable as the option value", {
  html <- as.character(var_input(
    "v", "Variables", c("y", "x"),
    selected = "x", multiple = TRUE,
    descriptions = c(y = "numeric, 0 missing, 5 unique",
                     x = "numeric, 0 missing, 5 unique")
  ))
  expect_match(html, "<option value=\"y\">y \u2014 numeric", fixed = TRUE)
  expect_match(html, "<option value=\"x\" selected>x \u2014 numeric", fixed = TRUE)
  expect_false(grepl("value=\"y \u2014", html, fixed = TRUE))
})

test_that("group selectors keep the level as the option value", {
  html <- as.character(groups_input(
    "g", "Group", c(stats::setNames("", "<none>"),
                    stats::setNames("sex", "sex")),
    descriptions = c(sex = "factor, 2 levels")
  ))
  expect_match(html, "<option value=\"\" selected>&lt;none&gt;</option>", fixed = TRUE)
  expect_match(html, "<option value=\"sex\">sex \u2014 factor, 2 levels</option>",
               fixed = TRUE)
})

test_that("selectors without descriptions still round-trip", {
  html <- as.character(var_input("v", "Variables", c("a", "b")))
  expect_match(html, "<option value=\"a\">a</option>")
  expect_match(html, "<option value=\"b\">b</option>")
})
