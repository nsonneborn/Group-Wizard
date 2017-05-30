# Group Wizard: Make groups from ranked preferences.
# App by Nina Sonneborn (Twitter: @nina_sonneborn, GitHub @nsonneborn)


library(shiny)
library(tidyverse)
library(lpSolve)
if (interactive()) {
  # Define UI for application that draws a histogram
  ui <- fluidPage(
    
    # Application title
    titlePanel("Group Wizard: Make groups from ranked preferences"),
    p("Instructions, examples and source code can be found on"),
    a(href= "https://github.com/nsonneborn/Group-Wizard", "GitHub"),
    hr(),
    # Sidebar to choose 2 input files 
    fluidRow(
      column(5, fileInput(inputId="choices", label="Choose CSV File of individuals' preferences",
                          accept = c(
                            "text/csv",
                            "text/comma-separated-values,text/plain",
                            ".csv")
      )
      ),
      column(5, fileInput(inputId="capacities", label="Choose CSV File of group capacities",
                          accept = c(
                            "text/csv",
                            "text/comma-separated-values,text/plain",
                            ".csv")
      )
      ),
      hr(),
      tableOutput("contents")
    )
  )
  server <- function(input, output) {
    output$contents <- renderTable({
      if (is.null(input$choices) | is.null(input$capacities))
        return(NULL)
      choices <- input$choices$datapath
      capacities <- input$capacities$datapath
      # input files will be NULL initially. After the user selects
      # and uploads a file, it will be a data frame with 'name',
      # 'size', 'type', and 'datapath' columns. The 'datapath'
      # column will contain the local filenames where the data can
      # be found.
      # Load data from csv ------------------
      choices <- 
        read_csv(choices) %>%
        rename("1" = `Choice 1`, "2" = `Choice 2`, "3" = `Choice 3`, "4" = `Choice 4`)
      print("data loaded")
      capacities <- read_csv(capacities)
      
      # Bug fix: if any chores aren't entered at all
      requested <- unique(union_all(choices$`1`, choices$`2`, choices$`3`, choices$`4`))
      unrequested <- setdiff(capacities$chore, requested)
      if(length(unrequested) > 0){
        for(i in 1:length(unrequested)){
          dummy <- c(paste("Dummy", i, sep=""), unrequested[i], sample(requested, 3))
          choices <- rbind(choices, dummy)
        }
      }
      
      # Tidy data format
      camper_prefs <- gather(choices, "rank", "chore", 2:5) %>%
        mutate(rank = as.integer(rank)) %>%
        spread( Camper, rank, drop = FALSE)
      
      # Prep inputs for lp.transport() -------------------------
      camper_prefs_matrix <- as.matrix(select(camper_prefs, 2:ncol(camper_prefs)))
      row.names(camper_prefs_matrix) <- camper_prefs$chore
      # camper_prefs_matrix
      
      # Solve cost optimization problem using lp.transport()-----
      lp_costs <- camper_prefs_matrix
      
      # Costs: 0 = 1st choice, 1 = 2nd choice, 2 = 3rd choice. 3 = 4th choice.
      # All others = # of chores - 1
      lp_costs[is.na(lp_costs)] <- ncol(lp_costs)
      lp_costs <- lp_costs - 1
      
      col.rhs <- rep(1, ncol(lp_costs))
      col.signs <- rep ("==", ncol(lp_costs))
      row.signs <- rep ("<=", length(capacities$capacity))
      row.rhs <- sort(capacities$capacity)
      
      # Run lpSolve
      lp_output <- lp.transport(lp_costs, "min", row.signs, row.rhs, col.signs, col.rhs)
      
      print("lp solved")
      # Make solution readable for human -----------------
      solution <- lp_output$solution 
      colnames(solution) <- sort(choices$Camper)
      
      solution <- bind_cols(tbl_df(sort(capacities$chore)), as.data.frame(solution)) %>%
        rename(chore = value)
      
      final_assignments <- solution %>% 
        gather("Camper", "included", -chore) %>%
        filter(included == 1) %>% 
        select(chore, Camper)
      final_assignments <- final_assignments[,c(2,1)]
      
      # lp_output
      # final_assignments
      
      final_assignments <- final_assignments %>% 
        rename(assignment = chore) %>%
        left_join(choices, by="Camper") %>%
        mutate(choice_num = ifelse(assignment == `1`, "1", 
                                   ifelse(assignment == `2`, "2",
                                          ifelse(assignment == `3`, "3",
                                                 ifelse(assignment == `4`, "4",
                                                        "Not requested"))))) %>%
        mutate(is_dummy = grepl("Dummy",Camper)) %>%
        filter(is_dummy == FALSE) %>%
        select(Camper, assignment, choice_num)
      
      print(head(final_assignments))
      final_assignments %>% as.data.frame()
      
    })
  }
  shinyApp(ui, server)
}
