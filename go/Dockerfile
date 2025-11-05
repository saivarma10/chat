FROM golang:1.23-alpine AS build

RUN apk add --no-cache protobuf-dev protobuf

WORKDIR /app

COPY go/go.mod go/go.sum* ./

# Copy proto file from proto directory
COPY proto/chatapp.proto ./proto/

RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

RUN protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    proto/chatapp.proto

COPY go/main.go ./

RUN go mod tidy
RUN go build -o main .

FROM alpine:latest

WORKDIR /app

COPY --from=build /app/main .

EXPOSE 8080

CMD ["./main"]
