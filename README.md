# Sooner Report

Automated recruiting predictions scraped from Rivals and 247Sports and posted directly to Slack.

Built using R and Docker.

To build, clone the repo and:

```
docker build . -t soonerreport:main
```

and then to run like it would in GitHub Actions:

```
docker run -e INPUT_TARGET-SCHOOL='Georgia Tech' --env INPUT_TARGET-YEAR=2022 soonerreport:main
```

Bot variables are configurable in `.github/workflows/main.yml`.

---

_Original README from Steven Plaisance as follows_

Automated Oklahoma football reports posted directly to Twitter

Current post schedule:

- Tweets each time OU receives a new 247Sports Crystal Ball
