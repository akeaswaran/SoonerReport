FROM rocker/tidyverse:4.1.0

WORKDIR /src

# Install R packages
RUN install2.r --error \
    tidyverse \
    httr \
    jsonlite \
    stringr \
    slackr

COPY . .

CMD ["Rscript", "slack.R"]
