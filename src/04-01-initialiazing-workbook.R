library(openxlsx)
#write ToC
wb <- openxlsx::createWorkbook("education_results")

addWorksheet(wb, "Table_of_content")
writeData(wb, sheet = "Table_of_content", x = "Table of Content", startCol = 1, startRow = 1)
