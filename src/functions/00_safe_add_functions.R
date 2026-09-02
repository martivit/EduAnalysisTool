# --- Workaround for a humind naming/overwrite issue (see GitHub issue: <link once opened>) ---
# humind's add_loop_edu_ind_age_corrected()/add_loop_edu_access_d()/etc. (and a
# couple of this project's own local functions with the same pattern) silently
# overwrite pre-existing columns that share a name with one of their outputs
# (e.g. a raw survey column called "edu_ind_age_schooling" colliding with
# humind::add_loop_edu_ind_age_corrected()'s output column of the same name).
#
# TO REMOVE once humind ships a fix for the underlying issue: delete this
# file, then find-and-replace "safe_add_" -> "add_" in
# src/01-add_education_indicators.R. Nothing else needs to change -
# MAIN.R already skips sourcing this file silently if it's absent (see the
# file.exists() check around its source() call), and 00_edu_helper.R was
# never touched by this workaround.

## ----------------------------------------------------------------------------------------------------------
# Compares `before_df` and `after_df` (the same object, captured immediately
# before and after a single add_* call). Any column present in both whose
# values differ is split in two: the pre-call value stays in that column's
# original position under a "<col>_orig" name, and the newly computed value
# moves to a fresh column under the original name, appended at the end (i.e.
# where a genuinely new output column would land), with a warning naming
# what was preserved. Newly created columns (not present in `before_df`) are
# left untouched. Returns `after_df`; the old -> new rename map is attached
# as its "renamed_cols" attribute for propagate_col_renames() to use.
#
# This compares before/after (rather than requiring a hardcoded list of each
# step's output columns) because some steps, like add_edu_level_grade_indicators(),
# generate a variable, country-dependent set of column names.
preserve_overwritten_columns <- function(before_df, after_df, step_label) {
  common_cols <- intersect(colnames(before_df), colnames(after_df))
  changed <- Filter(function(col) !identical(before_df[[col]], after_df[[col]]), common_cols)

  if (length(changed) == 0) {
    attr(after_df, "renamed_cols") <- character(0)
    return(after_df)
  }

  renamed_names <- paste0(changed, "_orig")
  dup <- renamed_names[renamed_names %in% colnames(after_df)]
  if (length(dup) > 0) {
    stop(sprintf(
      "Cannot preserve original data after '%s': target name(s) %s already exist. Resolve manually.",
      step_label, paste(dup, collapse = ", ")
    ))
  }

  for (i in seq_along(changed)) {
    col <- changed[i]
    orig_name <- renamed_names[i]
    new_values <- after_df[[col]]          # newly computed values, sitting in the original column's position
    after_df[[col]] <- before_df[[col]]    # restore old values in place, still under the old name
    names(after_df)[names(after_df) == col] <- orig_name  # rename in place -> "_orig", position preserved
    after_df[[col]] <- new_values          # append the new column under its real name, at the end
  }
  warning(sprintf(
    "'%s' overwrote existing column(s) %s. Original value(s) preserved as %s.",
    step_label, paste(changed, collapse = ", "), paste(renamed_names, collapse = ", ")
  ))

  attr(after_df, "renamed_cols") <- setNames(renamed_names, changed)
  after_df
}

# Given the old -> new rename map from preserve_overwritten_columns(), updates
# any pipeline variable in `varnames` (looked up in `envir`) that currently
# holds one of the renamed (old) column names, so it keeps pointing at the
# original data under its new "_orig" name instead of silently going stale.
propagate_col_renames <- function(renames, varnames, envir = parent.frame()) {
  if (length(renames) == 0) return(invisible(NULL))
  for (vn in varnames) {
    if (!exists(vn, envir = envir, inherits = FALSE)) next
    val <- get(vn, envir = envir)
    if (is.character(val) && length(val) == 1 && val %in% names(renames)) {
      assign(vn, unname(renames[[val]]), envir = envir)
      warning(sprintf("Variable '%s' pointed to renamed column '%s' -> now points to '%s'.", vn, val, renames[[val]]))
    }
  }
  invisible(NULL)
}

## ----------------------------------------------------------------------------------------------------------
# Each safe_* wrapper below has the exact same call signature as the function
# it wraps; it just adds preserve_overwritten_columns()/propagate_col_renames()
# protection around the call, using the `pipeline_col_vars` list defined in
# src/01-add_education_indicators.R.
#
# propagate_col_renames() is called with envir = .GlobalEnv explicitly here
# (rather than relying on its parent.frame() default) because this wrapper
# adds a stack frame between the pipeline script and propagate_col_renames();
# the pipeline variables it needs to update (ind_age, id_col_loop, etc.) live
# in .GlobalEnv, since MAIN.R/01-add_education_indicators.R are sourced there
# (source()'s default local = FALSE), not in safe_step()'s own call frame.
safe_step <- function(df, step_fn, step_label, ...) {
  before <- df
  after <- step_fn(df, ...)
  after <- preserve_overwritten_columns(before, after, step_label)
  propagate_col_renames(attr(after, "renamed_cols"), pipeline_col_vars, envir = .GlobalEnv)
  after
}

safe_add_loop_edu_ind_age_corrected     <- function(df, ...) safe_step(df, add_loop_edu_ind_age_corrected, "add_loop_edu_ind_age_corrected", ...)
safe_add_loop_edu_access_d              <- function(df, ...) safe_step(df, add_loop_edu_access_d, "add_loop_edu_access_d", ...)
safe_add_loop_edu_disrupted_d           <- function(df, ...) safe_step(df, add_loop_edu_disrupted_d, "add_loop_edu_disrupted_d", ...)
safe_add_edu_school_cycle               <- function(df, ...) safe_step(df, add_edu_school_cycle, "add_edu_school_cycle", ...)
safe_add_edu_level_grade_indicators     <- function(df, ...) safe_step(df, add_edu_level_grade_indicators, "add_edu_level_grade_indicators", ...)
safe_add_loop_edu_barrier_d             <- function(df, ...) safe_step(df, add_loop_edu_barrier_d, "add_loop_edu_barrier_d", ...)
safe_add_loop_child_gender_d            <- function(df, ...) safe_step(df, add_loop_child_gender_d, "add_loop_child_gender_d", ...)
safe_add_loop_edu_optional_nonformal_d  <- function(df, ...) safe_step(df, add_loop_edu_optional_nonformal_d, "add_loop_edu_optional_nonformal_d", ...)
safe_add_loop_wgq_ss                    <- function(df, ...) safe_step(df, add_loop_wgq_ss, "add_loop_wgq_ss", ...)
