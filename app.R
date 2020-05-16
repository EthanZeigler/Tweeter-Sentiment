library(shiny)
library(tidyverse)
library(ggplot2)
library(lubridate)

# current loaded file
previous_account <- ""
data <- NULL

# is production? (no debug)
prod <- TRUE

# get the dataframe for the given user
user_file <- function(name) {
  # new account?
  if (name != previous_account) {
    previous_account <<- name
    data <<- read_csv(gsub("ACCOUNT", name, "sentiment_data/ACCOUNT_sentiment.csv"))
    return(data)
  } else {
    # return cached
    return(data)
  }
}

# SHINY UI
ui <- fluidPage(
  titlePanel("Tweeter Sentiment"),
  # input sidebar
  sidebarLayout(
    sidebarPanel(
      # Account selection
      selectInput(
        inputId = "accountInput",
        label = "Account",
        selected = "BarackObama",
        choices = c("BarackObama",
                    "BrunoMars",
                    "DisguisedToast",
                    "elonmusk",
                    "EmmaWatson",
                    "Fedmyster",
                    "iamdevloper",
                    "katyperry",
                    "LilyPichu",
                    "michaelreeves",
                    "realdonaldtrump",
                    "Scarra",
                    "taylorswift13")),
      # tweet date range slider
      sliderInput(
        inputId = "dateRangeInput",
        label = "Date Range",
        min = as_date("2006-01-01"),
        max = today(),
        value = c(as_date("2006-01-01"), today()),
        step = 30, # days
        timeFormat = "%b '%y"),
      # interval
      radioButtons(
        inputId = "typeInput",
        label = "Plot Type",
        choices = c("Hour of Day", "Day of Week", "Year"),
        selected = "Hour of Day")),
    # Graph section
    mainPanel(
      plotOutput("plot"),
      br(), br(),
      tableOutput("results"))))

# SHINY Server
server <- function(input, output) {
  # manipulate and get average measures per interval
  output$plot <- renderPlot({
    print(input$dateRangeInput)
    to_display <- user_file(input$accountInput) %>%
      # filter to selected range
      mutate(start = as_date(timestamp) >= as_date(input$dateRangeInput[1])) %>%
      mutate(end = as_date(timestamp) <= as_date(input$dateRangeInput[2])) %>%
      filter(start, end) %>%
      # calculate normalized values for graphs
      mutate(hour_day = hour(with_tz(timestamp, tzone="US/Eastern"))) %>%
      mutate(norm_to_year = `year<-`(timestamp, 2018)) %>%
      mutate(norm_to_week = `week<-`(norm_to_year, 2)) %>%
      mutate(hour_week = hour_day + (wday(norm_to_week) * 24)) %>%
      mutate(hour_year = hour_day + (yday(norm_to_year) * 24)) %>%
      # get values for the year interval
      group_by(hour_year) %>%
        mutate(hour_year_avg = mean(compound)) %>%
        mutate(hour_year_total = n()) %>%
      ungroup() %>%
      # values for the week interval
      group_by(hour_week) %>%
        mutate(hour_week_avg = mean(compound)) %>%
        mutate(hour_week_total = n()) %>%
      ungroup() %>%
      # values for the day interval
      group_by(hour_day) %>%
        mutate(hour_day_avg = mean(compound)) %>%
        mutate(hour_day_total = n()) %>%
      ungroup()

    # dont call rstudio command in shiny prod
    if (!prod) {
      View(to_display)
    }

    if (input$typeInput == "Hour of Day") {
      # Show the sentiment over an average 24 hour period
      ggplot(to_display, aes(hour_day, hour_day_avg)) +
        ylim(-1, 1) +
        geom_line(aes(color=hour_day_total), size=2) +
        labs(
          y = "Positivity Rating",
          x = "Hour of Day",
          title = paste("@", input$accountInput, "'s Average Tweet Sentiment", sep=""))
    } else if (input$typeInput == "Day of Week") {
      # Show the sentiment over an average week period
      ggplot(to_display, aes(norm_to_week, hour_week_avg, color=hour_week_total)) +
        ylim(-1, 1) +
        #geom_point(shape=23, alpha=0.1) +
        geom_line() +
        labs(
          y = "Positivity Rating",
          x = "Day of Week",
          color = "Number of Tweets",
          title = paste("@", input$accountInput, "'s Average Tweet Sentiment", sep="")) +
        scale_x_datetime(date_labels = "%A", date_breaks = "1 day")
    } else {
      # Show the sentiment over an average week period
      ggplot(to_display, aes(norm_to_year, hour_year_avg, color=hour_year_total)) +
        ylim(-1, 1) +
        geom_line() +
        labs(
          y = "Positivity Rating",
          x = "Date (year normalized)",
          color = "Number of Tweets",
          title = paste("@", input$accountInput, "'s Average Tweet Sentiment", sep="")) +
        scale_x_datetime(
          date_labels = "%m",
          date_breaks = "1 month",
          date_minor_breaks = "1 week")
    }
  })
}

# Start shiny server
shinyApp(ui = ui, server = server)
