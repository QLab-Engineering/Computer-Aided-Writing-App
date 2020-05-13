library(shiny)
library(shinyBS)
source("functions.R")

predButton <- function(id) {
  actionButton(id, label = "", width = "100%", style ="background-color: #ffffff; border-color: #2e6da4; height:40px")
}

ui = fluidPage(style ="background-color: #e6f7ff",
               tags$script(HTML("$(function(){ 
                $(document).keyup(function(e) {
                if (e.keyCode == 72 && e.ctrlKey && e.altKey) {
                  $('#button1').click()
                }
                });
                })")),
               tags$script(HTML("$(function(){ 
                $(document).keyup(function(e) {
                if (e.keyCode == 74 && e.ctrlKey && e.altKey) {
                  $('#button2').click()
                }
                });
                })")),
               tags$script(HTML("$(function(){ 
                $(document).keyup(function(e) {
                if (e.keyCode == 75 && e.ctrlKey && e.altKey) {
                  $('#button3').click()
                }
                });
                })")),
               tags$script(HTML("$(function(){ 
                $(document).keyup(function(e) {
                if (e.keyCode == 76 && e.ctrlKey && e.altKey) {
                  $('#button4').click()
                }
                });
                })")),
    fluidRow(
      column(12, 
             p(h1(strong("Computer-Aided Writing"), style = "color: #2e6da4"))
             )
    ),
    fluidRow(
      column(3,
             h4(strong("Smart Prediction:")),
             #br(),
             div(tags$i("Hot Key:"), align = "right"),
             predButton("button1"),
             br(),
             div(tags$i("Ctrl + Alt + h"), align = "right"),
             predButton("button2"),
             br(),
             div(tags$i("Ctrl + Alt + j"), align = "right"),
             predButton("button3"),
             br(),
             div(tags$i("Ctrl + Alt + k"), align = "right"),
             predButton("button4"),
             br(),
             div(tags$i("Ctrl + Alt + l"), align = "right"),
             br()
             ),
      column(9,
               br(),
               splitLayout(
                      textInput("tool", label = NULL, value = "", placeholder = "Search", width = "100%"),
                      htmlOutput("dictionary"),
                      bsPopover("dict", "Look it up on dictionary.com"),
                      bsPopover("thes", "Find a synonym on thesaurus.com")
                      ),
             fluidRow(
               column(9,
                      textAreaInput("inText", label = NULL, value = "", width = "100%",
                                    height = NULL, cols = NULL, rows = 10, placeholder = "Enter text here",
                                    resize = NULL)
                      )
             ),
             div("Created by ", tags$a(href="https://github.com/QLab-Engineering/Computer-Aided-Writing-App", "Francis Labrecque"), align = "right")
             )
    )
    )

server <- function(input, output, session) {
  
  pred_word <- reactive(predWordOut(readInput(input$inText)))
  
    observeEvent(input$button1, {
    value <- paste(input$inText, pred_word()[1], " ", sep = "")
    updateTextAreaInput(session, "inText", value = value)
  })
  observeEvent(input$inText,{
    label = pred_word()[1]
    updateActionButton(session, "button1", label = label)
  })
  observeEvent(input$button2, {
    value <- paste(input$inText, pred_word()[2], " ", sep = "")
    updateTextAreaInput(session, "inText", value = value)
  })
  observeEvent(input$inText,{
    label = pred_word()[2]
    updateActionButton(session, "button2", label = label)
  })
  observeEvent(input$button3, {
    value <- paste(input$inText, pred_word()[3], " ", sep = "")
    updateTextAreaInput(session, "inText", value = value)
  })
  observeEvent(input$inText,{
    label = pred_word()[3]
    updateActionButton(session, "button3", label = label)
  })
  observeEvent(input$button4, {
    value <- paste(input$inText, pred_word()[4], " ", sep = "")
    updateTextAreaInput(session, "inText", value = value)
  })
  observeEvent(input$inText,{
    label = pred_word()[4]
    updateActionButton(session, "button4", label = label)
  })
  observeEvent(input$inText,{
    value = word(trimws(input$inText), -1)
    updateTextInput(session, "tool", value = value)
  })
  output$dictionary <- renderUI({
    tagList(
    tags$button(id = "dict",
                class = "btn action-button",
                onclick = paste0("window.open('https://www.dictionary.com/browse/", input$tool, "', '_blank')"),
                style = "width:34px; padding:0px; border-color: #cccccc",
                tags$img(src = "dictionary.jpg",
                         width = "32px",
                         margin = "0px",
                         padding = "0px",
                         height = "32px")
    ),
    tags$button(id = "thes",
                class = "btn action-button",
                onclick = paste0("window.open('https://www.thesaurus.com/browse/", input$tool, "', '_blank')"),
                style = "width:34px; padding:0px; border-color: #cccccc",
                tags$img(src = "thesaurus.png",
                         width = "32px",
                         margin = "0px",
                         padding = "0px",
                         height = "32px")
    )
    )
  })
}

shinyApp(ui = ui, server = server)