# Sooner Report

Automated recruiting predictions scraped from Rivals and 247Sports and posted directly to Slack.

Built using R and Docker.

To build, clone the repo and:

```
docker build . -t soonerreport:main
```

and then to run like it would in GitHub Actions (Slack posting disabled):

```
docker run --env TARGET_SCHOOL='Georgia Tech' --env TARGET_YEAR=2022 --env SLACK_ENABLED=false soonerreport:main
```

Bot variables are configurable in `.github/workflows/main.yml`.

Note: Posting to Slack will fail until you configure the right environment variables in GitHub Actions/local Docker runs.

- Configure these for GitHub at `<your fork's root URL>/settings/environments`. **DO NOT CHECK TOKENS/SECRETS INTO SOURCE.**
- Note: `slackr` also supports `.dcf` files for configuration instead of environment variables. These are automatically ignored in commits to _this_ repo, but if you use one locally, take care to make sure you don't commit one to source accidentally.
- See `slackr`'s documentation for more details on how to configure a `config.dcf` file: https://mrkaye97.github.io/slackr/reference/slackr_setup.html
- Also, make sure to set `SLACK_ENABLED` to `true` in `.github/workflows/main.yml` or as a local environment variable.

---

_Original README from Steven Plaisance as follows_

Automated Oklahoma football reports posted directly to Twitter

Current post schedule:

- Tweets each time OU receives a new 247Sports Crystal Ball
