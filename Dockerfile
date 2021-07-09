FROM alpine:latest
LABEL "com.github.actions.name"="Tag Bump"
LABEL "com.github.actions.description"="Bump and push git tag on merge"
LABEL "com.github.actions.icon"="git-merge"
LABEL "com.github.actions.color"="purple"

LABEL "repository"="https://github.com/jessenich/tag-bump-action"
LABEL "homepage"="https://github.com/jessenich/tag-bump-action" 
LABEL "maintainer"="Nick Sjostrom"

COPY ./contrib/semver ./contrib/semver
RUN install ./contrib/semver /usr/local/bin
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
