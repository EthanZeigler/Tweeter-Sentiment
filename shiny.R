library(tidyverse)
library(ggplot2)
library(lubridate)

df <- read_csv("sentiment_data/michaelreeves_sentiment.csv")

# Data is already clean from the python scraper and sentiment analysis.
# Display average compound sentiment for each hour of the day
ggplot(df %>%
       mutate(hour_day = hour(with_tz(timestamp, tzone="US/Eastern"))) %>%
       group_by(hour_day) %>%
       mutate(hour_avg = mean(compound)) %>%
       ungroup() %>%
       distinct(hour_day, hour_avg),
    aes(hour_day, hour_avg)) +
  ylim(-1, 1) +
  geom_line()
