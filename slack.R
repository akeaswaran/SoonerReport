library(slackr)
library(glue)
library(stringr)
library(lubridate)

# Configurable environment variables
selected_school <- Sys.getenv("TARGET_SCHOOL")
selected_school <- ifelse(is.na(selected_school) || str_length(selected_school) == 0, "Georgia Tech", selected_school)
target_year <- Sys.getenv("TARGET_YEAR")
target_year <- ifelse(is.na(target_year) || str_length(target_year) == 0, 2022, target_year)

last_updated <- tryCatch(
    {
        tmp <- read_json("last_updated.json")$date
        tmp <- trim(tmp)
        ymd_hms(tmp, tz = "UTC")
    },
    error = function(cond) {
        message("No last_updated file found, using current date")
        now()
    }
)

source("./RF Scraper.R") # Rivals scraper
source("./CB Scraper Run.R")  # 247 scraper

# ----- Data from Rivals -----
if (exists("futurecasts") && nrow(futurecasts) > 0) {
    for (row in 1:nrow(futurecasts)) {
        player_id <- futurecasts[row, "player_id"]
        name  <- trim(futurecasts[row, "recruit"])
        year  <- futurecasts[row, "year"]

        message(glue("Found Recent Rivals FutureCast for {selected_school}: {name} (ID: {player_id}, Year: {year})"))
    }
} else {
    message(glue("No recent Rivals FutureCasts found for {target_year} & {selected_school} since {last_updated}"))
}

# ----- Data from 247 -----
if (exists("new_cbs") && nrow(new_cbs) > 0) {
    for(i in 1:nrow(new_pred)){

        pred <- new_pred %>% slice(i)

        name <- pred$name
        link <- as.character(pred$link)
        pos <- pred$pos
        rank <- pred$star
        ht <- pred$ht
        wt <- pred$wt
        predictor <- pred$predictor
        acc <- pred$acc
        star <- pred$star
        confidence <- pred$confidence

        player_page <- read_html(link) %>% html_nodes(".upper-cards") %>% html_nodes(".details") %>%
            html_nodes("li") %>% html_nodes("span") %>% html_text()
        hs <- player_page[2]
        hs <- gsub("\n                            ","",hs)
        hs <- gsub("\n                        ","",hs)
        hometowm <- data.frame(state = player_page[4])
        sep <- hometowm %>% separate(col = state, into = c("Town", "State"), sep = ", ")
        state <- sep$State
        if(is.na(rank)) {
            text <-  glue(
                "
            \U0001f6A8 New Crystal Ball for {selected_school}

            {target_year} {pos}{name}
            {ht} / {wt}
            {{hs} ({state})

            By: {predictor} ({acc} in {target_year})
            Confidence: {confidence}/10

            {link}
            ")
        } else {
            text <-  glue(
                "
                \U0001f6A8 New Crystal Ball for {selected_school}

                {target_year} {star} {pos}{name}
                {ht} / {wt}
                {hs} ({state})

                By: {predictor} ({acc} in {target_year})
                Confidence: {confidence}/10

                {link}
            ")
        }
        message(text)
    }
} else {
    message(glue("No recent 247 Crystal Balls found for class of {target_year} & {selected_school} since {last_updated}"))
}

# slackr_setup(
#     config_file = "./config.dcf"
# )
# slackr(glue(""),
#            channel="#gtrecruiting",
#            icon_emoji="")

write(paste(
    "{  \"date\": \"",now,"\" }"
), "./last_updated.json")

