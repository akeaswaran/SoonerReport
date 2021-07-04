# Sooner Report

Automated recruiting predictions scraped from Rivals and 247Sports and posted directly to Slack.

Built using R and Docker.

## Basics

To build, clone the repo and:

```
docker build . -t soonerreport:main
```

and then to run like it would in GitHub Actions (live Slack posting disabled):

```
docker run --env TARGET_SCHOOL='Georgia Tech' --env TARGET_YEAR=2022 --env SLACK_ENABLED=false soonerreport:main
```

Input variables are configurable in `.github/workflows/main.yml`.

## Using this tool

If you're just interested in getting notifications and not building services, then follow these steps:

1. Fork this repo.
2. Follow the steps from the [Service Documentation](#service-documentation) section for each service you want to post updates to.
3. (You should have done this already, but for completion's sake:) Configure any secrets and environment variables you may need for your enabled at `<your fork's root URL>/settings/environments`. **DO NOT CHECK TOKENS/SECRETS INTO SOURCE.**
4. Make sure your service's input variables are properly configured for the `Pull recruit reports and post to Slack` step in `.github/workflows/main.yml`.
    - Make sure that for each service you want to post to that the `SERVICE_ENABLED` variable is set to `true`.
    - Make sure the `image` attribute of the `runs` metadata section of `.github/actions/action.yml` points to your fork of the repo.
5. Commit the changes you've made to `.github/workflows/main.yml` and `.github/actions/action.yml`, then push them.
6. Head to the Actions tab in GitHub, and wait for your new Docker image to build and be pushed to the GitHub Container Registry.
7. Run the `SoonerReport Scheduled Run` workflow from the Actions tab in GitHub, or wait for a scheduled run (default schedule is every six hours).

## Adding a new scraper

Want to add a new data source for notifications? Follow these steps:

1. Duplicate `RF Scraper.R` and save it as `<your data source here>.R`.
2. Replace the code in there with your new scraper code.
3. Head to `services.R` and add your new scraper to the list to `source`. Examples for 247Sports and Rivals are provided.
4. Add any R dependencies you need to for your scraper to the list in the Dockerfile. Make sure to use `\` to put each new dependency on its own line, like the existing ones.

To test your new data source locally, follow the steps in the [Basics](#basics) section above.

To deploy your new data source, follow steps 3-7 in the [Using this tool](#using-this-tool) section above.

## Adding a new posting service

Want to add a new service to output notifications to? Follow these steps:

1. Duplicate `slack.R` and save it as `<your service name here>.R`.
2. Replace the code in there with your service's notification posting code.
3. Add a section to `services.R` for your service with a boolean environment variable to enable it (ex: Slack --> `SLACK_ENABLED`).
    - Follow the given Slack example for this.
    - Make sure to replace the path to `slack.R` with a path to your service's file.
4. Add any dependencies you need to for your service to the list in the Dockerfile. Make sure to use `\` to put each new dependency on its own line, like the existing ones.
5. Update `.github/workflows/main.yml` and `.github/actions/action.yml` with any customizable input variables you must configure for your service, including your `SERVICE_ENABLED` boolean from step 3.
    - Follow the Slack stuff as an example.
    - In `.github/actions/action.yml`, make `SERVICE_ENABLED` the boolean the only required variable of the lot.
6. Update README.md with documentation on how to configure necessary environment variables for your service.
    - Follow the Slack section as an example.
    
To test your new service locally, follow the steps in the [Basics](#basics) section above.

To deploy your new service, follow steps 3-7 in the [Using this tool](#using-this-tool) section above.

## Service Documentation

### Slack 

Note: Posting to Slack will fail until you configure the right environment variables in your GitHub repo's Secrets. To set these up and enable Slack posting:

1. Go to `.github/actions/action.yml` and check what variables require secrets. You can also look at `.github/workflows/main.yml` to view an example on how to configure the variables.
2. Configure relevant values for said identifiers at `<your fork's root URL>/settings/environments`. **DO NOT CHECK TOKENS/SECRETS INTO SOURCE.**
3. Make sure to set `SLACK_ENABLED` to `true` in `.github/workflows/main.yml` or as a local environment variable (if running locally).

---

_Original README from Steven Plaisance as follows_

Automated Oklahoma football reports posted directly to Twitter

Current post schedule:

- Tweets each time OU receives a new 247Sports Crystal Ball
