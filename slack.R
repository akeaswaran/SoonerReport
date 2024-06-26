library(slackr)
library(glue)
library(stringr)
library(lubridate)
library(logging)
basicConfig()

if (!file.exists("./config.dcf")) {
    loginfo("No config file found, using environment variables to create one")
    create_config_file(
        filename = "./config.dcf",
        token = Sys.getenv("SLACK_BOT_USER_OAUTH_TOKEN"),
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
        hs <- player_hs[2]
        hometown <- futurecasts[row, "hometown"]
        og_school <- futurecasts[row, "original_school"]
        new_school <- futurecasts[row, "forecasted_team"]
        is_update <- futurecasts[row, "update"]
        is_unlikely <- futurecasts[row, "unlikely"]

        colleges_interested = futurecasts[row, "colleges_interested"]
        colleges_interested = format_interest_string(colleges_interested)

        if (is_update == 1 && is_unlikely == 0) {
            text <- glue(
            "🚨 {selected_school} FutureCast

            {predictor} updates forecast for {year} {rank}-Star {pos} {name} from {og_school} to {new_school}

            {ht} / {wt}
            {hometown}

            P5 Programs Interested: {colleges_interested}

            {link}")

        } else if (is_unlikely == 1) {
            text <- glue(
            "🚨 {selected_school} FutureCast Update

            {predictor} updates forecast for {year} {rank}-Star {pos} {name} from {og_school} to be unlikely

            {ht} / {wt}
            {hometown}

            P5 Programs Interested: {colleges_interested}

            {link}")

        } else if (og_school == selected_school) {
            text <- glue(
            "🚨 New FutureCast - {og_school} 🔄 {new_school}

            {year} {rank}-Star {pos} {name}
            {ht} / {wt}
            {hometown}

            By: {predictor}

            P5 Programs Interested: {colleges_interested}

            {link}")
        } else if (grepl(selected_school, colleges_interested)) {
            text <- glue(
            "🚨 New FutureCast - {selected_school} Interest

            {year} {rank}-Star {pos} {name}
            {ht} / {wt}
            {hometown}

            By: {predictor}
            To: {new_school}

            P5 Programs Interested: {colleges_interested}

            {link}")
        } else {
            text <- glue(
            "🚨 New {selected_school} FutureCast

            {year} {rank}-Star {pos} {name}
            {ht} / {wt}
            {hometown}

            By: {predictor}

            P5 Programs Interested: {colleges_interested}

            {link}")
        }
        slack_send(text)
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
    for(i in 1:nrow(new_cbs)) {

        pred <- new_cbs[i, ]

        name <- trim(pred$player_name)
        link <- as.character(pred$player_url)
        pos <- str_trim(pred$player_position)
        if (is.na(pos) || pos == "") {
            pos = "Player"
        }
        ht <- str_trim(pred$player_height)
        wt <- str_trim(pred$player_weight)
        # rank <- trim(pred$star)

        predictor <- trim(pred$predictor_name)
        # acc <- trim(pred$acc)
        # star <- trim(pred$star)
        confidence <- trim(pred$predictor_confidence)
        player_page = read_html(link)

        metrics = player_page %>%
            html_node(".upper-cards") %>%
            html_elements(".metrics-list > li")
        if (length(metrics) > 0) {
            positions = metrics[1] %>% html_elements('span') %>% html_text()
            pos <- str_trim(positions[2])
        }

        if (length(metrics) > 1) {
            heights = metrics[2] %>% html_elements('span') %>% html_text()
            ht <- str_trim(heights[2])
        }

        if (length(metrics) > 2) {
            weights = metrics[3] %>% html_elements('span') %>% html_text()
            wt <- trim(weights[2])
        }

        details <- player_page %>%
            html_nodes(".upper-cards") %>%
            html_nodes(".details") %>%
            html_nodes("li") %>%
            html_nodes("span") %>%
            html_text()
        hs <- str_trim(details[2])
        hometowm <- data.frame(state = details[4])
        sep <- hometowm %>% separate(col = state, into = c("Town", "State"), sep = ", ")
        state <- sep$State

        composite_info = grab_composite_content(link)
        team_interests = grab_team_interests(link)
        offer_string = format_offers_string(team_interests, power_only = TRUE)

        assembled_str = ""
        if (!is.na(composite_info$stars)) {
            assembled_str <- glue("Stars: {composite_info$stars}")
        }

        if (!is.na(composite_info$rating)) {
            assembled_str <- glue("{assembled_str}\nRating: {composite_info$rating}")
        }

        if (!is.null(composite_info$ranks)) {
            writeable = composite_info$ranks %>%
                mutate(
                    pasteable = glue("{title}: #{rank}")
                )
            rank_str = paste0(writeable$pasteable, collapse = " / ")

            assembled_str <- glue("{assembled_str}\n{rank_str}")
        }

        text <-  glue(
            "🔮 New Crystal Ball for {selected_school}

            {target_year} {pos} {name}
            {ht} / {wt}
            {hs} ({state})

            {assembled_str}
            P5 Offers: {offer_string}

            By: {predictor}
            Confidence: {confidence}/10

            {link}")
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
