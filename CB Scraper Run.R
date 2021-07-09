library(rvest)
library(tidyverse)
library(lubridate)
library(glue)
library(logging)
library(httr)
basicConfig()

loginfo(glue("Starting 247 Crystal Ball scraping for target year {target_year}..."))

year_url <- paste0("https://247sports.com/Season/",target_year,"-Football/TargetPredictions/")

# # check connection
# test_result <- GET(url = year_url)
# loginfo(glue("GET Result test status code: {test_result$status_code}"))
# loginfo(glue("any http errors? {http_error(test_result)}"))

loginfo(glue("Scraping 247 URL at {year_url}"))

cb <- read_html(year_url)

span <- cb %>%
  html_elements("span") %>%
  html_attr("class")

loginfo(glue("Found {length(span)} 247 Crystal Balls, parsing..."))

image_names<-cb %>% html_nodes("img") %>% html_attr("alt")
image_height<-cb %>% html_nodes("img") %>% html_attr("height")
links<-cb %>% html_nodes("a") %>% html_attr("href")
pred_date<-cb %>% html_elements(".prediction-date") %>% html_text()
player_names<-cb %>% html_nodes(".name")
names <- html_children(player_names)
predictor_names<-cb %>% html_nodes(".predicted-by") %>% html_nodes("a") %>%
  html_nodes(".jsonly") %>% html_attr("alt")
predictor_stats <- cb %>% html_nodes(".accuracy") %>% html_nodes("span") %>% html_text()
p_stats <- data.frame(acc = predictor_stats)
seq <- seq(to = 150, from = 3, by = 3)
p_stats <- p_stats[seq, ]
p_stats <- gsub(" ","",p_stats)
confidence<-cb %>% html_nodes(".confidence") %>% html_nodes(".confidence-wrap") %>%
  html_text()
confidence <- data.frame(confidence <- confidence)
sep <- confidence %>% separate(col = confidence....confidence, into = c("A", "B", "C"), sep = "                ")
confidence <- sep$B
confidence <- gsub("\n","",confidence)

player_info <- data.frame(name = NA,
                          pos = NA,
                          rank = NA)

for(i in 0:49){
  info <- data.frame(name = html_text(names[[i*3+1]]),
                     pos = html_text(names[[((i*3)+2)]]),
                     rank = html_text(names[[((i*3)+3)]]))

  player_info <- bind_rows(player_info, info)
}
loginfo(glue("Converted CBs into {nrow(player_info)} player info records..."))

player_info <- player_info %>% slice(2:51)
player_info$number <- 1:nrow(player_info)
loginfo(glue("Assigned ids to {nrow(player_info)} records..."))

images <- data.frame(names = image_names, height = image_height)
teams <- images %>% dplyr::filter(height == 24)

zero <- data.frame(name = span)
zero <- zero %>% dplyr::slice(31:731)

zeroes <- which(zero == "icon-zero")
emptys <- floor(zeroes/14)

if(length(emptys!=0)) {
  teams$number <- 1:nrow(teams)
  cut <- teams %>% dplyr::filter(number>(emptys-1))
  teams <- teams %>% dplyr::filter(number<(emptys))
  cut <- cut %>% mutate(new = number+1) %>% select(-number, number = new)
  teams <- bind_rows(teams, cut)
  new_row <- data.frame(names = "icon-zero", height = as.factor(24), number = emptys)
  teams <- bind_rows(teams, new_row)
} else{
  teams$number <- 1:nrow(teams)
}
pred_date <- as.data.frame(pred_date)
pred_date$number = 1:nrow(pred_date)
teams <- left_join(teams, pred_date, by="number")

loginfo(glue("Found {nrow(teams)} teams in dataset"))

targets <- data.frame(link = links)
sep <- targets %>% separate(col = link, into = c("prefix", "body"), sep = 8)
sep <- sep %>% separate(col = "body", into = c("site", "body"), sep = 9)
sep <- sep %>% separate(col = "body", into = c("suffix", "body"), sep = 5)
sep <- sep %>% separate(col = "body", into = c("type", "body"), sep = 6)
targets <- targets %>% mutate(site = sep$site, type = sep$type) %>% filter(type == "Player") %>% mutate(number = 1:nrow(.))

new_names <- data.frame(name = player_info$name)
sep <- new_names %>% separate(col = name, into = c("A", "B", "C", "D", "E"), sep = "                ")
player_info$name <- sep$B
player_info$name <- gsub("\n","",player_info$name)

new_pos <- data.frame(pos = player_info$pos)
sep <- new_pos %>% separate(col = pos, into = c("A", "B", "C"), sep = "/")
new_pos$pos <- sep$A
new_pos$ht <- sep$B
new_pos$wt <- sep$C
new_pos$pos <- gsub("\n                ","",new_pos$pos)
sep3 <- new_pos %>% separate(col = wt, into = c("A", "B"), sep = "            ")
player_info$ht <- sep3$ht
player_info$ht <- gsub(" ","",player_info$ht)
player_info$wt <- sep3$A
player_info$wt <- gsub(" |\n","",player_info$wt)
player_info$pos <- new_pos$pos

new_rank <- data.frame(rank = player_info$rank)
sep <- new_rank %>% separate(col = rank, into = c("A", "B"), sep = "                \n                ")
new_rank$rank <- sep$B
sep <- new_rank %>% separate(col = rank, into = c("A", "B"), sep = "            ")
player_info$rank <- sep$A
player_info <- player_info %>% mutate(star = if_else(rank>0.9830, "5-Star",
                                                     if_else(rank>0.8900, "4-Star",
                                                             "3-Star")))

cb_list <- left_join(teams, targets, by="number")

loginfo(glue("Parsed/Cleaned {nrow(cb_list)} records from 247Sports. Filtering based on criteria: school ({selected_school}), year ({target_year}), and time since last updated ({last_updated})..."))

cb_list$pred_date=mdy_hm(cb_list$pred_date, tz = "UTC")
cb_list <- cb_list %>% mutate(elapsed = as.double(difftime(pred_date,
                                                           last_updated,
                                                           units = "secs")))
cb_list <- left_join(cb_list, player_info, by="number")
predictor_info <- data.frame(predictor = predictor_names, acc = p_stats)
predictor_info$number <- 1:nrow(predictor_info)
predictor_info$confidence <- confidence
cb_list <- left_join(cb_list, predictor_info, by="number")

new_cbs <- cb_list %>% filter(elapsed >= 0 & (names == selected_school))

loginfo(glue("Found {nrow(new_cbs)} Crystal Balls that match given criteria."))
