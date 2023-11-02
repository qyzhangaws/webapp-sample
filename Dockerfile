# golang builder
FROM public.ecr.aws/docker/library/golang:1.21.1-alpine as builder
LABEL stage=gobuilder

WORKDIR /app
COPY . .

RUN go mod tidy \
    && go mod vendor \
    && go build -mod=vendor -o webapp-sample

# golang image
FROM public.ecr.aws/docker/library/golang:1.21.1-alpine

WORKDIR /app
COPY --from=builder /app/webapp-sample ./webapp-sample

EXPOSE 8080
CMD ["./webapp-sample"]
