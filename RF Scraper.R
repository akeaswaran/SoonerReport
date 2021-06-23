library(rvest)
library(tidyverse)
library(rtweet)
library(lubridate)
library(glue)

trim <- function (x) gsub("^\\s+|\\s+$", "", x)
column <- function(x, css) x %>% html_node(css = css) %>% html_text()

rf_html <- read_html("https://n.rivals.com/futurecast")

# ----- FutureCast Forecasters -----
forecast_nodes <- rf_html %>%
    html_nodes("[class^=\"ForecasterThumbnail_forecasterInformation__\"]")

forecasters <- data.frame(
    title = column(forecast_nodes, "[class^=\"ForecasterThumbnail_forecasterTitle__\"]"),
    first_name = column(forecast_nodes, "[class^=\"Link_link__1xDdm ForecasterThumbnail_forecasterName__\"] > div:nth_child(1)"),
    last_name = column(forecast_nodes, "[class^=\"Link_link__1xDdm ForecasterThumbnail_forecasterName__\"] > div:nth_child(2)"),
    accuracy = column(forecast_nodes, "[class^=\"ForecasterThumbnail_forecasterAccuracy__\"]"),
    stringsAsFactors = FALSE
)

forecasters <- forecasters %>%
    mutate(
        title = trim(title),
        first_name = trim(first_name),
        last_name = trim(last_name),
        full_name = glue("{first_name} {last_name}"),
        accuracy = as.numeric(gsub("% accuracy", "", accuracy))
    ) %>%
    select(full_name, title, accuracy)


# ----- FutureCasts -----

fc_nodes <- rf_html %>%
    html_nodes("[class^=\"ForecastActivity_forecastActivity__\"] > [class^=\"ForecastActivity_activityText__\"]")




futurecasts <- data.frame(
    forecaster = column(fc_nodes, "[class^=\"ForecastActivity_forecastText__\"] > b:nth-child(1)"),
    recruit = column(fc_nodes, "[class^=\"ForecastActivity_forecastText__\"] > b:nth_child(2)"),
    profile_url = fc_nodes %>% html_node("[class^=\"ForecastActivity_forecastText__\"] > b:nth_child(2) > a") %>% html_attr('href'),
    full_text = column(fc_nodes, "[class^=\"ForecastActivity_forecastText__\"]"),
    time_since = column(fc_nodes, "[class^=\"ForecastActivity_forecastTime__\"]"),
    stringsAsFactors = FALSE
)

now <- now()
futurecasts <- futurecasts %>%
    mutate(
        forecaster = trim(forecaster),
        recruit = trim(recruit),
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


