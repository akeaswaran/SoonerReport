FROM rocker/tidyverse:4.0.3

WORKDIR /src

# Install R packages
RUN install2.r --error \
    rvest \
    tidyverse \
    lubridate \
    glue \
    httr \
    jsonlite \
    stringr \
    slackr

COPY . .

CMD ["Rscript", "slack.R"]
