create_xlsx_education_table <- function(gt_table, wb, sheet_name) {
  # ordering data
  ordered_gt_data <- gt_table$`_data`[, gt_table$`_boxhead`$var]

  # if spanner
  get_spanner_info <- function(gt_table, level, ordered_data) {
    list(
      label_spanner = gt_table$`_spanners`$spanner_label[[level]],
      columns_spanner = which(names(ordered_data) %in% gt_table$`_spanners`$vars[[level]])
    )
  }

  if (nrow(gt_table$`_spanners`) > 0) {
    spanner_helper <- list()
    for (i in max(gt_table$`_spanners`$spanner_level):1) {
      spanner_helper[[paste0("level", i)]] <- which(gt_table$`_spanners`$spanner_level == i) %>%
        map(~ get_spanner_info(gt_table, .x, ordered_gt_data))
    }
  }

  has_title <- function(gt_table) {
    list(
      has_title = !is.null(gt_table[["_heading"]][["title"]]),
      has_subtitle = !is.null(gt_table[["_heading"]][["subtitle"]])
    )
  }
  spanner_in_excel <- function(wb, sheet, spanner, row, style) {
    openxlsx::writeData(
      wb = wb,
      sheet = sheet,
      x = spanner$label_spanner,
      startCol = min(spanner$columns_spanner),
      startRow = row
    )
    openxlsx::mergeCells(wb = wb, sheet = sheet, cols = spanner$columns_spanner, rows = row)
    openxlsx::addStyle(
      wb = wb, sheet = sheet, rows = row,
      cols = spanner$columns_spanner, style = style
    )
  }

  mygtinfo <- has_title(gt_table)

  title_style <- createStyle(halign = "center", border = "TopLeftRight", borderColour = "#D3D3D3")
  column_labels_border <- openxlsx::createStyle(border = "TopLeftRight", borderColour = "#D3D3D3")
  total_cols <- ncol(ordered_gt_data)

  openxlsx::addWorksheet(wb, sheet_name, gridLines = F)


  # header
  ## write title
  current_row <- 1
  if (mygtinfo$has_title) {
    writeData(wb, sheet_name, gt_table$`_heading`$title, startCol = 1, startRow = current_row)
    openxlsx::mergeCells(wb, sheet_name, cols = 1:total_cols, rows = current_row)

    addStyle(wb, sheet_name, rows = current_row, cols = 1:total_cols, style = title_style)
    current_row <- current_row + 1
  }

  ## write subtitle
  if (mygtinfo$has_subtitle) {
    writeData(wb, sheet_name, gt_table$`_heading`$subtitle, startCol = 1, startRow = current_row)
    openxlsx::mergeCells(wb, sheet_name, cols = 1:total_cols, rows = current_row)

    addStyle(wb, sheet_name, rows = current_row, cols = 1:total_cols, style = title_style)

    current_row <- current_row + 1
  }

  # stubhead

  # columns labels
  ## spanner label
  if (length(spanner_helper) > 0) {
    for (i in 1:length(spanner_helper)) {
      row_start <- i + mygtinfo$has_title + mygtinfo$has_subtitle

      spanner_helper[[i]] %>%
        map(~ spanner_in_excel(wb,
          sheet = sheet_name,
          spanner = .x,
          row = row_start,
          style = column_labels_border
        ))
    }
  }


  ## write columns names
  row_start_col_names <- length(spanner_helper) + mygtinfo$has_title + mygtinfo$has_subtitle + 1
  writeData(wb, sheet_name,
    x = gt_table$`_boxhead`$column_label, colNames = F,
    startRow = row_start_col_names
  )
  openxlsx::addStyle(wb, sheet_name,
    rows = row_start_col_names, cols = 1:ncol(ordered_gt_data),
    style = column_labels_border
  )

  # stub
  ## row group label
  row_start_stub_initial <- row_start_col_names + 1 # keeping in memory for later
  row_start_stub <- row_start_stub_initial

  label_groups_row <- list()
  cell_data_row <- list()

  for (i in unique(gt_table$`_row_groups`)) {
    writeData(wb, sheet_name, i, startRow = row_start_stub)
    mergeCells(wb, sheet_name, rows = row_start_stub, cols = 1:ncol(ordered_gt_data))
    openxlsx::addStyle(
      wb = wb, sheet = sheet_name, rows = row_start_stub,
      cols = 1:ncol(ordered_gt_data), style = column_labels_border
    )

    label_groups_row[[i]] <- row_start_stub

    row_start_stub <- row_start_stub + 1

    data_to_write <- ordered_gt_data[ordered_gt_data[[1]] == i, ]
    data_to_write[, 1] <- ""

    writeData(wb, sheet_name, data_to_write,
      startRow = row_start_stub, colNames = F,
      borders = "surrounding",
      borderColour = "#D3D3D3"
    )

    cell_data_row[[i]][["start"]] <- row_start_stub
    cell_data_row[[i]][["end"]] <- row_start_stub + nrow(data_to_write) - 1

    row_start_stub <- row_start_stub + nrow(data_to_write) + 1

    groupRows(wb, sheet_name, rows = c(cell_data_row[[i]][["start"]]:cell_data_row[[i]][["end"]]))
  }
  percent_style <- createStyle(numFmt = "0%")
  ## format cell manually, cannot find info in gt_table
  which(names(ordered_gt_data) %in% gt_table$`_formats`[[1]]$cols) %>%
    map(~ addStyle(wb, sheet_name, percent_style, rows = row_start_stub_initial:row_start_stub, cols = .x, stack = T))
}
