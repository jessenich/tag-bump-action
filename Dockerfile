FROM alpine:latest
LABEL "com.github.actions.name"="Tag Bump"
LABEL "com.github.actions.description"="Bump and push git tag on merge"
LABEL "com.github.actions.icon"="git-merge"
LABEL "com.github.actions.color"="purple"

LABEL "repository"="https://github.com/jessenich/tag-bump-action"
LABEL "homepage"="https://github.com/jessenich/tag-bump-action" 
LABEL "maintainer"="Jesse N. <jesse@keplerdev.com>"

RUN apk install --update -no-cache git curl
COPY ./semver.sh ./semver
RUN install ./semver /usr/local/bin
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
