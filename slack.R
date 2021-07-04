library(slackr)
library(glue)
library(stringr)
library(lubridate)
library(logging)
basicConfig()

send_empty_updates <- Sys.getenv("SLACK_SEND_EMPTY_UPDATES")
send_empty_updates <- !(is.na(send_empty_updates) || str_length(send_empty_updates) == 0 || tolower(as.character(send_empty_updates)) == "false" || send_empty_updates == FALSE)

if (!file.exists("./config.dcf")) {
    loginfo("No config file found, using environment variables to create one")
    create_config_file(
        filename = "./config.dcf",
        bot_user_oauth_token = Sys.getenv("SLACK_BOT_USER_OAUTH_TOKEN"),
        incoming_webhook_url = Sys.getenv("SLACK_INCOMING_URL_PREFIX"),
        username = Sys.getenv("SLACK_USERNAME"),
        channel = Sys.getenv("SLACK_CHANNEL")
    )
}
slackr_setup(
    config_file = "./config.dcf"
)

slack_send <- function(msg) {
    loginfo(glue("Sending message: {msg}"))
    slackr_msg(msg)
}

# ----- Data from Rivals -----
if (exists("futurecasts") && nrow(futurecasts) > 0) {
    loginfo("Iterating through futurecasts and sending messages...")
    for (row in 1:nrow(futurecasts)) {
        player_id <- futurecasts[row, "player_id"]
        name  <- trim(futurecasts[row, "recruit"])
        year  <- futurecasts[row, "year"]
        slack_send(glue("Found recent Rivals FutureCast for {selected_school}: {name} (ID: {player_id}, Year: {year})"))
    }
} else {
    loginfo("No futurecasts to send messages for")
    if (send_empty_updates) {
        slack_send(glue("No recent Rivals FutureCasts found for {selected_school} class of {target_year} since {last_updated}"))
    }
}

# ----- Data from 247 -----
if (exists("new_cbs") && nrow(new_cbs) > 0) {
    loginfo("Iterating through Crystal Balls and sending messages...")
    for(i in 1:nrow(new_cbs)){

        pred <- new_cbs %>% slice(i)

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
        slack_send(text)
    }
} else {
    loginfo("No Crystal Balls to send messages for")
    if (send_empty_updates) {
        slack_send(glue("No recent 247 Crystal Balls found for {selected_school} class of {target_year} since {last_updated}"))
    }
}

loginfo("Tearing down Slack integration after use")
slackr_teardown()
