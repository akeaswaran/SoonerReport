library(rvest)
library(tidyverse)
library(rtweet)
library(lubridate)
library(glue)

rf_html <- read_html("https://n.rivals.com/futurecast")

rf_nodes <- rf_html %>%
    html_nodes("[class^=\"ForecastActivity_forecastActivity__\"] > [class^=\"ForecastActivity_activityText__\"]")

column <- function(x) rf_nodes %>% html_node(css = x) %>% html_text()

rf <- data.frame(
    author = column("[class^=\"ForecastActivity_forecastText__\"] > b"),
    text = column("[class^=\"ForecastActivity_forecastText__\"]"),
    time_since = column("[class^=\"ForecastActivity_forecastTime__\"]"),
    stringsAsFactors = FALSE
)

now <- now()
rf <- rf %>%
    mutate(
        time_since = gsub(" ago", "", time_since),
        unit_elapsed = case_when(
            grepl("s", time_since) == TRUE ~ "second",
            grepl("m", time_since) == TRUE ~ "minute",
            grepl("h", time_since) == TRUE ~ "hour",
            grepl("d", time_since) == TRUE ~ "day",
            TRUE ~ "unknown"
        ),
        value_elapsed = as.numeric(gsub("d", "", gsub("h", "", gsub("m", "", gsub("s", "", time_since))))),
        date = case_when(
            unit_elapsed == "second" ~ (now %m-% seconds(value_elapsed)),
            unit_elapsed == "minute" ~ (now %m-% minutes(value_elapsed)),
            unit_elapsed == "hour" ~ (now%m-% hours(value_elapsed)),
            unit_elapsed == "day" ~ (now %m-% days(value_elapsed))
        )
    ) %>%
    select(-time_since, -unit_elapsed, -value_elapsed)


