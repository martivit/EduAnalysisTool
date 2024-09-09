

# Define the function
create_variable_mapping <- function(questions, new_variable_names) {
  if (length(questions) != length(new_variable_names)) {
    stop("The number of questions and new variable names must be the same")
  }
  # Create a named vector where names are the new variable names
  # and values are the questions
  variable_mapping <- setNames(questions, new_variable_names)
  
  return(variable_mapping)
}


