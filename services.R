library(glue)
library(stringr)
library(lubridate)
library(logging)
library(jsonlite)
basicConfig()

# Configurable environment variables
selected_school <- Sys.getenv("TARGET_SCHOOL")
selected_school <- ifelse(is.na(selected_school) || str_length(selected_school) == 0, "Georgia Tech", selected_school)
target_year <- Sys.getenv("TARGET_YEAR")
target_year <- ifelse(is.na(target_year) || str_length(target_year) == 0, 2022, target_year)

last_updated <- tryCatch(
    {
        tmp <- read_json("./last_updated.json")$date
        tmp <- trim(tmp)
        loginfo("Found last_updated file, using old date for comparison")
        ymd_hms(tmp, tz = "UTC")
    },
    error = function(cond) {
        loginfo("No last_updated file found, using current date")
        logerror(glue::glue("Error shown: {cond}"))
        now()
    }
)
loginfo(glue("Last updated recruits at: {last_updated}"))

## -- ACTUAL DATA SCRAPING --
source("./RF Scraper.R") # Rivals scraper
source("./CB Scraper Run.R")  # 247 scraper

# ADD SERVICES HERE
#
# Slack
slack_enabled <- Sys.getenv("SLACK_ENABLED")
slack_enabled <- !(is.na(slack_enabled) || str_length(slack_enabled) == 0 || tolower(as.character(slack_enabled)) == "false" || slack_enabled == FALSE)
if (slack_enabled) {
    message("Service [Slack] is enabled, messages WILL be sent there")
    source("./slack.R")
} else {
    message("Service [Slack] is not enabled, messages will not be sent there")
}
