library(rvest)
library(tidyverse)
library(lubridate)
library(glue)
library(stringr)
library(logging)
library(httr)
basicConfig()

loginfo(glue("Starting 247 Crystal Ball scraping for target year {target_year}..."))

# Configurable environment variables
selected_247_prefix <- Sys.getenv("TARGET_247_PREFIX") # prefix for a team-specific 247Sports blog. Will usually be after the "https://247sports.com/college/" portion of the team site URL.
selected_247_prefix <- ifelse(is.na(selected_247_prefix) || str_length(selected_247_prefix) == 0, "georgia-tech", selected_247_prefix)

national_url <- paste0("https://247sports.com/Season/",target_year,"-Football/CurrentTargetPredictions/")
team_url <- paste0("https://247sports.com/college/",selected_247_prefix,"/Season/",target_year,"-Football/CurrentTargetPredictions/")


find_rankings <- function(rankings_sections, composite_only = TRUE) {
    composite_ranks = data.frame(
        "title" = c(),
        "rank" = c()
    )

    stars = NA
    rating = NA

    for (item in rankings_sections) {
        title = item %>%
            html_element(".title") %>%
            html_text()

        if (!grepl("Composite", title) && composite_only) {
            next
        }

        stars <- item %>%
            html_elements(".ranking > .stars-block > .yellow") %>%
            length()

        rating <- item %>%
            html_elements(".ranking > .rank-block") %>%
            html_text()

        ranks_list <- item %>%
            html_elements("ul.ranks-list > li")

        for (li in ranks_list) {
            # li = ranks_list[[i]]
            r_title = li %>% html_element("b") %>% html_text()
            r_rank = li %>% html_element("a:not(.rank-history-link) > strong") %>% html_text()
            index = nrow(composite_ranks) + 1
            composite_ranks[index, "title"] <- r_title
            composite_ranks[index, "rank"] <- r_rank
        }
    }
    return(
        list(
            "stars" = stars,
            "rating" = as.numeric(str_trim(rating)),
            "ranks" = composite_ranks
        )
    )
}

p5_teams = c(
    "georgia",
    "ohio state",
    "florida",
    "michigan",
    "alabama",
    "penn state",
    "notre dame",
    "florida state",
    "clemson",
    "tennessee",
    "texas a&m",
    "lsu",
    "usc",
    "oklahoma",
    "miami",
    "stanford",
    "arkansas",
    "nebraska",
    "texas",
    "wisconsin",
    "north carolina",
    "georgia tech",
    "purdue",
    "south carolina",
    "ole miss",
    "auburn",
    "iowa",
    "minnesota",
    "mississippi state",
    "texas tech",
    "rutgers",
    "duke",
    "pittsburgh",
    "virginia tech",
    "vanderbilt",
    "arizona",
    "cincinnati",
    "west virginia",
    "illinois",
    "kansas",
    "arizona state",
    "ucf",
    "kentucky",
    "maryland",
    "wake forest",
    "syracuse",
    "louisville",
    "michigan state",
    "washington",
    "iowa state",
    "nc state",
    "oklahoma state",
    "tcu",
    "baylor",
    "indiana",
    "virginia",
    "missouri",
    "ucla",
    "colorado",
    "northwestern",
    "oregon state",
    "utah",
    "boston college",
    "washington state",
    "california",
    "kansas state",
    "brigham young",
    "houston",
    "smu",
    "southern methodist",
    "tulane"
)

format_offers_string <- function(team_interests, power_only = TRUE) {
    if (nrow(team_interests) == 0) {
        return("No offers or visits available.")
    }

    teams_offered = team_interests %>%
        filter(offer)

    if (power_only) {
        teams_offered <- teams_offered %>%
            filter(tolower(team) %in% p5_teams)
    }

    if (nrow(teams_offered) == 0) {
        if (power_only) {
            return("No P5 offers available.")
        } else {
            return("No offers available.")
        }
    }

    return(paste(teams_offered$team, collapse = ", "))
}

grab_team_interests <- function(player_url) {
    player_page = read_html(player_url)
    player_recruitment_url = player_page %>%
        html_element("a.college-comp__view-all") %>%
        html_attr('href')

    # player_recruitment_url = "https://247sports.com/recruitment/jameson-riggs-156395/recruitinterests/"
    #
    if (is.na(player_recruitment_url) || is.null(player_recruitment_url)) {
        return(
            data.frame(
                "team" = NA_character_,
                "visit" = NA_character_,
                "offer" = NA_character_,
                "recruiters" = NA_character_
            ) %>%
                head(0)
        )
    }

    interests = read_html(player_recruitment_url)

    interest_records = interests %>%
        html_elements('ul.recruit-interest-index_lst > li')

    teams = interest_records %>%
        html_element('img') %>%
        html_attr('alt')

    interest_details = interest_records %>%
        html_element('.left > .secondary_blk')

    visit = interest_details %>%
        html_element('.visit') %>%
        html_text() %>%
        str_trim()
    visit = str_trim(gsub("Visit:", "", visit))
    visit = sapply(visit, function (x) {
        if (x == "-") {
            return(NA_character_)
        }
        return(x)
    })

    offer = interest_details %>%
        html_element('.offer') %>%
        html_text()
    offer = str_trim(gsub("Offer:", "", offer))
    offer = grepl("yes", tolower(offer))

    recruiters = list()
    for (item in interest_details) {
        target = item %>%
            html_element('ul.interest-details_lst')
        if (length(target) == 0) {
            recruiters[length(recruiters) + 1] <- NA_character_
        } else {
            recruiters[length(recruiters) + 1] <- paste0(target %>% html_elements('li > a') %>% html_text(), collapse = ", ")
        }
    }

    recruit_interests = data.frame(
        "team" = teams,
        "visit" = visit,
        "offer" = offer,
        "recruiters" = paste0(recruiters)
    ) %>%
        mutate(
            recruiters = case_when(
                recruiters == "NA" ~ NA_character_,
                TRUE ~ recruiters
            )
        )

    return(recruit_interests)
}

grab_composite_content <- function(player_url) {
    # #page-content > div.main-div.clearfix > section > header > div.lower-cards > section.rankings > section:nth-child(3) > div > div.rank-block
    # player_url = "https://247sports.com/Player/jameson-riggs-46133338/"
    player_page = read_html(player_url)
    rankings_sections = player_page %>%
        html_elements("section.rankings-section")

    player_content = find_rankings(rankings_sections)
    if (is.na(player_content[["stars"]])) {
        player_content <- find_rankings(rankings_sections, FALSE)
    }
    return(player_content)
}

grab_composite_content <- function(player_url) {
    # #page-content > div.main-div.clearfix > section > header > div.lower-cards > section.rankings > section:nth-child(3) > div > div.rank-block
    # player_url = "https://247sports.com/Player/jameson-riggs-46133338/"
    player_page = read_html(player_url)
    rankings_sections = player_page %>%
        html_elements("section.rankings-section")

    player_content = find_rankings(rankings_sections)
    if (is.na(player_content[["stars"]])) {
        player_content <- find_rankings(rankings_sections, FALSE)
    }
    return(player_content)
}

query_crystal_balls <- function(url) {
    # # check connection
    # test_result <- GET(url = year_url)
    # loginfo(glue("GET Result test status code: {test_result$status_code}"))
    # loginfo(glue("any http errors? {http_error(test_result)}"))

    loginfo(glue("Scraping 247 URL at {url}"))

    cb_page <- read_html(url)

    cb_list <- cb_page %>%
        html_node('ul.cb-player-list') %>%
        html_nodes('li.target')

    loginfo(glue("Found {length(cb_list)} 247 Crystal Balls, parsing..."))
    cb_results = list()
    for (cb in cb_list) {
        player_name = cb %>%
            html_node(".name > a") %>%
            html_text(trim = T) # will have class year

        player_measures = cb %>%
            html_node(".name > span") %>%
            html_text(trim = T)

        player_rating = cb %>%
            html_node(".name > .ranking > b") %>%
            html_text(trim = T)

        player_stars = cb %>%
            html_nodes(".name > .ranking > span.yellow") %>%
            length(.)

        player_url = cb %>%
            html_node(".name > a") %>%
            html_attr("href")

        predictor_url <- cb %>%
            html_node(".predicted-by > a") %>%
            html_attr("href")

        predictor_info <- cb %>%
            html_nodes(".predicted-by > a > span") %>%
            html_text(trim = T) %>%
            paste(., collapse = ";")

        predictor_accuracy <- cb %>%
            html_nodes(".accuracy > span") %>%
            html_text(trim = T) %>%
            paste(., collapse = ";")

        prediction_date <- cb %>%
            html_node(".prediction > .prediction-date") %>%
            html_text(trim = T)

        prediction_content_classes <- cb %>%
            html_node(".prediction > div") %>%
            html_children() %>%
            html_attr("class")

        prediction_type = "normal"
        if ("flipped-wrap" %in% prediction_content_classes) {
            prediction_team <- cb %>%
                html_node(".prediction > div > .flipped-wrap > img") %>%
                html_attr("alt")
            flipped_from = cb %>%
                html_node(".prediction > div > img") %>%
                html_attr("alt")

            prediction_type = "flip"
        } else {
            prediction_team <- cb %>%
                html_node(".prediction > div > img") %>%
                html_attr("alt")
            flipped_from = NA_character_
            prediction_type = "normal"
        }

        predictor_confidence <- cb %>%
            html_node(".confidence > .confidence-wrap > .confidence-score") %>%
            html_text(trim = T)
        # browser()
        result = data.frame(
            "player_name" = player_name,
            "player_url" = player_url,
            "player_stars" = player_stars,
            "player_rating" = player_rating,
            "player_measures" = player_measures,
            "predictor_url" = predictor_url,
            "predictor_info" = predictor_info,
            "predictor_accuracy" = predictor_accuracy,
            "prediction_date" = prediction_date,
            "prediction_team" = prediction_team,
            "prediction_flipped_from" = flipped_from,
            "prediction_type" = prediction_type,
            "predictor_confidence" = predictor_confidence
        )
        # browser()
        cb_results = append(cb_results, list(result))
    }

    current_year = year(now())
    current_month = month(now())

    cb_df_raw = bind_rows(cb_results)
    cb_df = cb_df_raw %>%
        mutate(
            player_class_year = str_extract(player_name, "\\(\\d+\\)"),
            player_class_year = str_replace_all(player_class_year, "[\\(\\)]", ""),
            player_class_year = str_trim(player_class_year),
            player_class_year = as.numeric(player_class_year),
            player_type = case_when(
                 player_class_year > current_year ~ "high_school",
                 (current_month >= 7) & (player_class_year == (current_year + 1)) ~ "high_school",
                TRUE ~ "transfer"
            ),
            player_rating = case_when(
                player_rating == "NA" ~ NA_character_,
                TRUE ~ player_rating
            ),
            player_stars = case_when(
                player_stars == 0 ~ NA_integer_,
                TRUE ~ player_stars
            ),
            player_stars = as.numeric(player_stars),

            player_name = str_replace(player_name, "\\(\\d+\\)", ""),
            player_name = str_trim(player_name),

            prediction_date = as_datetime(prediction_date, format = "%m/%d/%y %R%p"),

            player_position = str_extract(player_measures, "^\\w+ /"),
            player_position = str_replace(player_position, "/", ""),
            player_position = str_trim(player_position),
            player_height = str_extract(player_measures, " / .* / "),
            player_height = str_replace_all(player_height, "/", ""),
            player_height = str_trim(player_height),
            player_weight = str_extract(player_measures, "/ \\w+$"),
            player_weight = str_replace_all(player_weight, "/", ""),
            player_weight = str_trim(player_weight),

            predictor_name = str_extract(predictor_info, "^.*;"),
            predictor_name = str_replace(predictor_name, ";", ""),
            predictor_position = str_extract(predictor_info, ";.*$"),
            predictor_position = str_replace(predictor_position, ";", ""),

            predictor_accuracy = str_replace(predictor_accuracy, "Accuracy:;", ""),
            predictor_accuracy_pct = str_extract(predictor_accuracy, "^.*;"),
            predictor_accuracy_pct = str_replace_all(predictor_accuracy_pct, "[\\(\\);]", ""),
            predictor_accuracy_raw = str_extract(predictor_accuracy, ";.*$"),
            predictor_accuracy_raw = str_replace(predictor_accuracy_raw, ";", "")
        ) %>%
        select(
            -predictor_accuracy,
            -player_measures,
            -predictor_info
        )
    return(cb_df)
}

final_cbs <<- data.frame()
links <- c(national_url, team_url)
for (item in links) {
    tmp = query_crystal_balls(item)
    final_cbs <- rbind(final_cbs, tmp)
}
loginfo(glue("Found {nrow(final_cbs)} total Crystal Balls, deduping and filtering based on criteria: school ({selected_school}), year ({target_year}), and time since last updated ({last_updated})..."))

new_cbs <- final_cbs %>%
    group_by(predictor_name, player_name, prediction_team) %>%
    slice_min(order_by = row_number(), n = 1) %>%
    ungroup() %>%
    mutate(
        elapsed = as.double(difftime(prediction_date, last_updated, units = "secs"))
    ) %>%
    filter(elapsed >= 0 & (grepl(selected_school, prediction_team) == TRUE))

loginfo(glue("Found {nrow(new_cbs)} Crystal Balls that match given criteria."))
