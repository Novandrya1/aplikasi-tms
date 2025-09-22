# builder
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o /app/server ./cmd/server

# runtime
FROM alpine:3.18
RUN apk --no-cache add wget && \
    addgroup -S app && adduser -S app -G app && \
    mkdir -p /app/uploads && \
    chown -R app:app /app
COPY --from=builder /app/server /usr/local/bin/server
USER app
WORKDIR /app
EXPOSE 8080
CMD ["/usr/local/bin/server"]