# Sooner Report

Automated recruiting predictions scraped from Rivals and 247Sports and posted directly to Slack.

Built using R and Docker.

## Basics

To build, clone the repo and:

```
docker build . -t soonerreport:main
```

and then to run like it would in GitHub Actions (Slack posting disabled):

```
docker run --env TARGET_SCHOOL='Georgia Tech' --env TARGET_YEAR=2022 --env SLACK_ENABLED=false soonerreport:main
```

Bot variables are configurable in `.github/workflows/main.yml`.

## Adding a new service

Want to add a new service to output notifications to? Follow these steps:

1. Duplicate `slack.R` and save it as `<your service name here>.R`.
2. Replace code in there with your service's notification posting code.
3. Add a section to `services.R` for your service with a boolean environment variable to enable it (ex: Slack --> `SLACK_ENABLED`).
    - Follow the given Slack example for this.
    - Make sure to replace the path to `slack.R` with a path to your service's file.
4. Add any dependencies you need to for your service to the list in the Dockerfile. Make sure to use `\` to put each new dependency on its own line, like the existing ones.
5. Update `main.yml` with any customizable input variables you must configure for your service, including your `SERVICE_ENABLED` boolean from step 3.
    - Follow the Slack stuff as an example and make the boolean the only required variable of the lot.

To use your new service:

1. Configure any secret environment variable you may need for your service at `<your fork's root URL>/settings/environments`. **DO NOT CHECK TOKENS/SECRETS INTO SOURCE.**
2. Make sure your service's input variables are properly configured for the SoonerReport step in `.github/workflows/main.yml`.
    - Make sure your `SERVICE_ENABLED` variable is set to `true`.
3. Commit and push your changes.
3. Run your workflow from the Actions tab in GitHub, or wait for a scheduled run (default schedule is every six hours).

## Service Documentation

### Slack 

Note: Posting to Slack will fail until you configure the right environment variables in your GitHub repo.

- Configure said variables at `<your fork's root URL>/settings/environments`. **DO NOT CHECK TOKENS/SECRETS INTO SOURCE.**
- Note: `slackr` also supports `.dcf` files for configuration instead of environment variables. These are automatically ignored in commits to _this_ repo, but if you use one locally, take care to make sure you don't commit one to source accidentally.
    - See `slackr`'s documentation for more details on how to configure a `config.dcf` file: https://mrkaye97.github.io/slackr/reference/slackr_setup.html
- Also, make sure to set `SLACK_ENABLED` to `true` in `.github/workflows/main.yml` or as a local environment variable (if running locally).

---

_Original README from Steven Plaisance as follows_

Automated Oklahoma football reports posted directly to Twitter

Current post schedule:

- Tweets each time OU receives a new 247Sports Crystal Ball
