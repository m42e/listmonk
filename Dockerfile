FROM node:alpine AS nodebuilder
WORKDIR /listmonk
COPY . /listmonk/
RUN ls && cd /listmonk/frontend && yarn install && yarn build

FROM golang:alpine AS gobuilder
WORKDIR /listmonk
COPY . /listmonk/
COPY --from=nodebuilder /listmonk/frontend/dist /listmonk/frontend/
RUN go build -o listmonk -ldflags="-s -w -X 'main.buildString=XXX' -X 'main.versionString=0.7.0'" cmd/*.go
RUN   go get -u github.com/knadh/stuffbin/...
RUN stuffbin -a stuff -in listmonk -out listmonk config.toml.sample \
	schema.sql queries.sql \
	static/public:/public \
	static/email-templates \
	frontend/dist/favicon.png:/frontend/favicon.png \
	frontend/dist/frontend:/frontend

FROM alpine:latest AS deploy
RUN apk --no-cache add ca-certificates
WORKDIR /listmonk
COPY --from=gobuilder /listmonk/listmonk .
COPY config.toml.sample config.toml
COPY config-demo.toml .
CMD ["./listmonk"]
