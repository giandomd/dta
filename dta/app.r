# Install required packages if not installed
if (!require("shiny")) install.packages("shiny")
if (!require("bslib")) install.packages("bslib")
if (!require("riskyr")) install.packages("riskyr")

# Load required packages
library(ggplot2)
library(tidyverse)
library(readxl)
library(scales)
library(DT)
library(gt)
library(dplyr)
library(riskyr)
library(shiny)
library(bslib)
library(bsicons)

# Set the theme
theme_set(theme_light(base_size = 30, base_family = "Atkinson Hyperlegible"))
pal <- init_pal(riskyr::pal_rgb)

# Define UI
ui <- fluidPage(
  titlePanel("Diagnostic Test Accuracy Dashboard"),
  
  sidebarLayout(
    sidebarPanel(
      textInput('cond', 'Condition', value = 'CAD'),
      textInput('pop', 'Population', value = 'Stable angina'),
      textInput('test', 'Test name', value = 'ETT'),
      numericInput('sample', 'Sample size', min = 1, value = 100, step = 1),
      br(),
      numericInput('sens', 'Sensitivity (%)', min = 1, max = 100, value = 80, step = 0.1),
      numericInput('spec', 'Specificity (%)', min = 1, max = 100, value = 80, step = 0.1),
      numericInput('prev', 'Disease prevalence (%)', min = 1, max = 99.9, value = 40, step = 0.1)
    ),
    
    mainPanel(
      plotOutput('p4'),
      
      fluidRow(
        column(6, 
               valueBoxOutput("ACC", width = 6),
               plotOutput('pfagan', height = 300)
        ),
        column(6,
               valueBoxOutput("ptpos", width = 6),
               valueBoxOutput("ptneg", width = 6)
        )
      ),
      
      fluidRow(
        column(6,
               plotOutput('p0', height = 300),
               plotOutput('p1', height = 300)
        ),
        column(6,
               plotOutput('p3', height = 300)
        )
      ),
      
      plotOutput('p2', height = 300),
      
      fluidRow(
        column(4,
               valueBoxOutput("PPV", width = 6)
        ),
        column(4,
               valueBoxOutput("NPV", width = 6)
        ),
        column(4)
      )
    )
  )
)

# Define server
server <- function(input, output) {
  
  output$PLR <- reactive({
    round(ifelse(input$spec == 100, no = input$sens / (100 - input$spec), yes = 100), digits = 2)
  })
  
  output$NLR <- reactive({
    round(ifelse(input$spec == 0, no = (100 - input$sens) / input$spec, yes = 100), digits = 2)
  })
  
  output$PPV <- reactive({
    paste(round((input$sens * input$prev / (input$sens * input$prev + (100 - input$spec) * (100 - input$prev))) * 100, digits = 1), "%", sep = "")
  })
  
  output$NPV <- reactive({
    paste(round((input$spec * (100 - input$prev) / ((100 - input$sens) * input$prev + (input$spec) * (100 - input$prev))) * 100, digits = 1), "%", sep = "")
  })
  
  output$ACC <- reactive({
    paste(round((input$sens * input$prev + input$spec * (100 - input$prev)) / 100, digits = 1), "%", sep = "")
  })
  
  output$ptneg <- reactive({
    paste(round(
      (input$prev / (100 - input$prev)) *
        ifelse(input$spec == 0, no = (100 - input$sens) / (input$spec), yes = 100) /
        (1 + (input$prev / (100 - input$prev)) *
           ifelse(input$spec == 0, no = (100 - input$sens) / (input$spec), yes = 100)) * 100, digits = 1),
      "%"
    )
  })
  
  output$ptpos <- reactive({
    paste(round(
      (input$prev / (100 - input$prev)) *
        ifelse(input$spec == 100, no = input$sens / (100 - input$spec), yes = 100) /
        (1 + (input$prev / (100 - input$prev)) *
           ifelse(input$spec == 100, no = input$sens / (100 - input$spec), yes = 100)) * 100, digits = 1),
      "%"
    )
  })
  
  output$TP <- reactive({
    round((input$sens / 100) * (input$prev / 100) * input$sample, digits = 0)
  })
  
  output$FN <- reactive({
    round((input$prev / 100) * (input$sample) * (1 - input$sens / 100), digits = 0)
  })
  
  output$TN <- reactive({
    round((input$spec / 100) * input$sample * (1 - input$prev / 100), digits = 0)
  })
  
  output$FP <- reactive({
    round(input$sample * (1 - input$prev / 100) * (1 - input$spec / 100), digits = 0)
  })
  
  output$p0 <- renderPlot({
    riskyr::riskyr(
      scen_lbl = paste(input$cond, "reclassification by", input$test),
      popu_lbl = input$pop,
      cond_true_lbl = paste(input$cond, "present"),
      cond_false_lbl = paste(input$cond, "absent"),
      dec_lbl = paste(input$test, "result"),
      dec_pos_lbl = "predicts presence",
      dec_neg_lbl = "predicts absence",
      hi_lbl = paste(input$cond, "properly diagnosed"),
      mi_lbl = paste(input$cond, "missed"),
      fa_lbl = paste(input$cond, "falsely diagnosed"),
      cr_lbl = paste(input$cond, "properly excluded"),
      prev = input$prev / 100,
      sens = input$sens / 100,
      spec = input$spec / 100,
      N = input$sample
    ) %>% plot(type = 'prism', col_pal = riskyr::pal_rgb)
  })
  
  output$p1 <- renderPlot({
    riskyr::riskyr(
      scen_lbl = paste(input$cond, "reclassification by", input$test),
      popu_lbl = input$pop,
      cond_true_lbl = paste(input$cond, "present"),
      cond_false_lbl = paste(input$cond, "absent"),
      dec_lbl = paste(input$test, "result"),
      dec_pos_lbl = "predicts presence",
      dec_neg_lbl = "predicts absence",
      hi_lbl = paste(input$cond, "properly diagnosed"),
      mi_lbl = paste(input$cond, "missed"),
      fa_lbl = paste(input$cond, "falsely diagnosed"),
      cr_lbl = paste(input$cond, "properly excluded"),
      prev = input$prev / 100,
      sens = input$sens / 100,
      spec = input$spec / 100,
      N = input$sample
    ) %>% plot(type = 'curve', col_pal = riskyr::pal_rgb)
  })
  
  output$p2 <- renderPlot({
    riskyr::riskyr(
      scen_lbl = paste(input$cond, "reclassification by", input$test),
      popu_lbl = input$pop,
      cond_true_lbl = paste(input$cond, "present"),
      cond_false_lbl = paste(input$cond, "absent"),
      dec_lbl = paste(input$test, "result"),
      dec_pos_lbl = "predicts presence",
      dec_neg_lbl = "predicts absence",
      hi_lbl = paste(input$cond, "properly diagnosed"),
      mi_lbl = paste(input$cond, "missed"),
      fa_lbl = paste(input$cond, "falsely diagnosed"),
      cr_lbl = paste(input$cond, "properly excluded"),
      prev = input$prev / 100,
      sens = input$sens / 100,
      spec = input$spec / 100,
      N = input$sample
    ) %>% plot(type = 'tab', col_pal = riskyr::pal_rgb)
  })
  
  output$p3 <- renderPlot({
    riskyr::riskyr(
      scen_lbl = paste(input$cond, "reclassification by", input$test),
      popu_lbl = input$pop,
      cond_true_lbl = paste(input$cond, "present"),
      cond_false_lbl = paste(input$cond, "absent"),
      dec_lbl = paste(input$test, "result"),
      dec_pos_lbl = "predicts presence",
      dec_neg_lbl = "predicts absence",
      hi_lbl = paste(input$cond, "properly diagnosed"),
      mi_lbl = paste(input$cond, "missed"),
      fa_lbl = paste(input$cond, "falsely diagnosed"),
      cr_lbl = paste(input$cond, "properly excluded"),
      prev = input$prev / 100,
      sens = input$sens / 100,
      spec = input$spec / 100,
      N = input$sample
    ) %>% plot(type = 'bar', col_pal = riskyr::pal_rgb)
  })
  
  output$p4 <- renderPlot({
    riskyr::riskyr(
      scen_lbl = paste(input$cond, "reclassification by", input$test),
      popu_lbl = input$pop,
      cond_true_lbl = paste(input$cond, "present"),
      cond_false_lbl = paste(input$cond, "absent"),
      dec_lbl = paste(input$test, "result"),
      dec_pos_lbl = "predicts presence",
      dec_neg_lbl = "predicts absence",
      hi_lbl = paste(input$cond, "properly diagnosed"),
      mi_lbl = paste(input$cond, "missed"),
      fa_lbl = paste(input$cond, "falsely diagnosed"),
      cr_lbl = paste(input$cond, "properly excluded"),
      prev = input$prev / 100,
      sens = input$sens / 100,
      spec = input$spec / 100,
      N = input$sample
    ) %>% plot(type = 'icon', col_pal = riskyr::pal_rgb)
  })
  
  output$pfagan <- renderPlot({
    data.frame(
      ecg_pos = c(input$prev,
                  (input$prev / (100 - input$prev)) *
                    ifelse(input$spec == 100, no = input$sens / (100 - input$spec), yes = 100) /
                    (1 + (input$prev / (100 - input$prev)) *
                       ifelse(input$spec == 100, no = input$sens / (100 - input$spec), yes = 100)) * 100),
      ecg_neg = c(input$prev,
                  (input$prev / (100 - input$prev)) *
                    ifelse(input$spec == 0, no = (100 - input$sens) / input$spec, yes = 100) /
                    (1 + (input$prev / (100 - input$prev)) *
                       ifelse(input$spec == 0, no = (100 - input$sens) / input$spec, yes = 100)) * 100),
      thres_angio = 65,
      thres_notest = 15,
      time = c(0, 1)
    ) %>% ggplot() +
      geom_rect(aes(xmin = time[1], xmax = time[2], ymin = thres_angio, ymax = 100), alpha = 0.05, fill = "darkred") +
      geom_rect(aes(xmin = time[1], xmax = time[2], ymin = 0, ymax = thres_notest), alpha = 0.05) +
      geom_line(aes(x = time, y = ecg_pos), color = "darkred", cex = 1.1) +
      geom_line(aes(x = time, y = ecg_neg), color = "darkred", linetype = "dashed", cex = 1.1) +
      geom_rect(aes(xmin = time[1], xmax = time[2], ymin = thres_angio, ymax = 100), alpha = 0.15, fill = "darkred") +
      geom_rect(aes(xmin = time[1], xmax = time[2], ymin = 0, ymax = thres_notest), alpha = 0.15) +
      geom_line(aes(x = time, y = thres_angio), linetype = "dashed", color = "black") +
      geom_line(aes(x = time, y = thres_notest), linetype = "dashed", color = "black") +
      ylim(0, 100) +
      ylab("") +
      xlim(0, 1) +
      xlab("") +
      theme(legend.position = "bottom") +
      scale_x_continuous(breaks = NULL) +
      theme(panel.grid.major = element_line(color = 'grey', linetype = 'dotted')) +
      ggtitle(label = "Fagan nomogram",
              subtitle = paste(input$test, "Detection of", input$cond, "in patients with", input$pop))
  })
}

# Run the application
shinyApp(ui, server)
