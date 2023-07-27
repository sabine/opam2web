FROM ocaml/opam:alpine-3.15-ocaml-4.14 as opam
FROM --platform=linux/amd64 ocaml/opam:archive as opam-archive
FROM ocaml/opam.ocaml.org-legacy as opam-legacy
FROM alpine:3.15 as opam2web

COPY --from=opam /usr/bin/opam /usr/local/bin/opam

RUN apk add --update git curl rsync libstdc++ rdfind
COPY --from=opam-legacy . /www
RUN --mount=type=bind,target=/cache,from=opam-archive rsync -aH /cache/cache/ /www/cache/
COPY ext/key/opam-dev-team.pgp /www/opam-dev-pubkey.pgp

ADD bin/opam-archive.sh /usr/local/bin
ARG DOMAIN=opam.ocaml.org
ARG OPAM_REPO_GIT_SHA=master
RUN echo ${OPAM_REPO_GIT_SHA} >> /www/opam_git_sha
RUN /usr/local/bin/opam-archive.sh ${DOMAIN} ${OPAM_REPO_GIT_SHA}

FROM caddy:2.5.2-alpine
WORKDIR /srv
COPY --from=opam2web /www /usr/share/caddy
COPY bin /usr/share/caddy
COPY ext/Caddyfile .
ENTRYPOINT ["caddy", "run"]