FROM golang:1.20-alpine AS builder
WORKDIR /src
COPY . .
RUN apk add --no-cache git build-base \
 && cd backend-go \
 && go build -o /bin/aegis-backend main.go

FROM alpine:3.18
COPY --from=builder /bin/aegis-backend /bin/aegis-backend
EXPOSE 8080
ENTRYPOINT ["/bin/aegis-backend"]
