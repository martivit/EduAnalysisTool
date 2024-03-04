

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

# Example usage
questions <- c("variable name of the education_access indicator in your kobo? It has to answer to the question: Did (name) attend school or any early childhood education program at any time during the 2023-2024 school year?")
new_variable_names <- c("education_access")

mapping <- create_variable_mapping(questions, new_variable_names)

