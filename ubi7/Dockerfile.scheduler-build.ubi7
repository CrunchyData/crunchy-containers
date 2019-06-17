FROM golang:1.9.1
WORKDIR /go/src/github.com/crunchydata/crunchy-containers
ADD . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -o scheduler ./tools/scheduler
