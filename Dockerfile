# build
FROM golang:1.14.7-alpine3.12 AS build
WORKDIR /go/src/${owner:-github.com/emanzx}/reporter
RUN apk update && apk add make git
ADD . .
RUN make build

# create image
FROM alpine:3.12
COPY util/texlive.profile /
ENV TZ=Asia/Kuala_Lumpur
RUN PACKAGES="wget perl-switch fontconfig fontconfig-dev" \
        && apk update \
        && apk add $PACKAGES \
        && apk add ca-certificates \
        && update-ca-certificates \
        && apk add --update tzdata \
        && wget -qO- \
          "https://raw.githubusercontent.com/yihui/tinytex/main/tools/install-unx.sh" | \
          sh -s - --admin --no-path \
        && mv ~/.TinyTeX /opt/TinyTeX \
        && /opt/TinyTeX/bin/*/tlmgr path add \
        && tlmgr path add \
        && chown -R root:adm /opt/TinyTeX \
        && chmod -R g+w /opt/TinyTeX \
        && chmod -R g+wx /opt/TinyTeX/bin \
        && tlmgr install epstopdf-pkg \
        # Cleanup
        && apk del --purge -qq $PACKAGES \
        && apk del --purge -qq \
        && rm -rf /var/lib/apt/lists/* \
        && rm -rf /var/cache/apk/*


COPY --from=build /go/bin/grafana-reporter /usr/local/bin
ENTRYPOINT [ "/usr/local/bin/grafana-reporter" ]
