library(rtweet)
library(glue)
library(stringr)
library(lubridate)
library(logging)
basicConfig()

twitter_token <- Sys.getenv("TWITTER_TOKEN")

tweet_msg <- function(msg) {
    if (!is.na(twitter_token)) {
        loginfo(glue("Sending message: {msg}"))
        post_tweet(
            status = msg,
            media = NULL,
            token = twitter_token
        )
    } else {
        loginfo(glue("Logging message, twitter token is not configured: {msg}"))
    }
}

# ----- Data from Rivals -----
if (exists("futurecasts") && nrow(futurecasts) > 0) {
    loginfo("Iterating through futurecasts and sending messages...")
    for (row in 1:nrow(futurecasts)) {
        link <- futurecasts[row, "profile_url"]

        player_profile <- read_html(link)

        player_hs <- player_profile %>% html_nodes("div.new-prospect-profile >
                                               div.prospect-personal-information >
                                               div.location-block >
                                               div.right-personal-information >
                                               a > .prospect-small-information >
                                               .vital-line-location") %>% html_text()

        name  <- trim(futurecasts[row, "recruit"])
        year  <- futurecasts[row, "year"]
        pos <- futurecasts[row, "position_abbreviation"]
        rank <- futurecasts[row, "stars"]
        ht <- fixHeight(futurecasts[row, "height"])
        wt <- futurecasts[row, "weight"]
        predictor <- futurecasts[row, "forecaster"]
        acc <- futurecasts[row, "accuracy"]
        hs <- player_hs[2]
        hometown <- futurecasts[row, "hometown"]
        og_school <- futurecasts[row, "original_school"]
        new_school <- futurecasts[row, "forecasted_team"]
        is_update <- futurecasts[row, "update"]

        if (is_update == 1) {
            tweet_msg(glue("
            \U000F16A8 {selected_school} FutureCast

            {predictor} ({acc}%) updates forecast for {year} {rank}-Star {pos} {name} from {og_school} to {new_school}

            {ht} / {wt}
            {hs} ({hometown})
            {link}
            "))
        } else {
            tweet_msg(glue("
            \U0001F52E New {selected_school} FutureCast

            {year} {rank}-Star {pos} {name}
            {ht} / {wt}
            {hs} ({hometown})

            By: {predictor} ({acc}%)

            {link}
            "))
        }
    }
} else {
    loginfo("No futurecasts to send messages for")
    if (send_empty_updates) {
        tweet_msg(glue("No recent Rivals FutureCasts found for {selected_school} class of {target_year} since {last_updated}"))
    }
}

# ----- Data from 247 -----
if (exists("new_cbs") && nrow(new_cbs) > 0) {
    loginfo("Iterating through Crystal Balls and sending messages...")
    for(i in 1:nrow(new_cbs)){

        pred <- new_cbs %>% slice(i)

        name <- trim(pred$name)
        link <- as.character(pred$link)
        pos <- trim(pred$pos)
        rank <- trim(pred$star)
        ht <- trim(pred$ht)
        wt <- trim(pred$wt)
        predictor <- trim(pred$predictor)
        acc <- trim(pred$acc)
        star <- trim(pred$star)
        confidence <- trim(pred$confidence)

        player_page <- read_html(link) %>% html_nodes(".upper-cards") %>% html_nodes(".details") %>%
            html_nodes("li") %>% html_nodes("span") %>% html_text()
        hs <- player_page[2]
        hs <- gsub("\n                            ","",hs)
        hs <- gsub("\n                        ","",hs)
        hs <- trim(hs)
        hometowm <- data.frame(state = player_page[4])
        sep <- hometowm %>% separate(col = state, into = c("Town", "State"), sep = ", ")
        state <- sep$State
        if(is.na(rank)) {
            text <-  glue(
                "
            \U0001f6A8 New Crystal Ball for {selected_school}

            {target_year} {pos} {name}
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

                {target_year} {star} {pos} {name}
                {ht} / {wt}
                {hs} ({state})

                By: {predictor} ({acc} in {target_year})
                Confidence: {confidence}/10

                {link}
            ")
        }
        tweet_msg(text)
    }
} else {
    loginfo("No Crystal Balls to send messages for")
    if (send_empty_updates) {
        tweet_msg(glue("No recent 247 Crystal Balls found for {selected_school} class of {target_year} since {last_updated}"))
    }
}
