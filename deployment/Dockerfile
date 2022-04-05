FROM alpine
RUN apk update
RUN apk --update add go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV GOCACHE /tmp/
ENV PATH /go/bin:$PATH
RUN apk add bash openrc --no-cache
WORKDIR /var/www/goweb
RUN adduser usergo -D --home /var/www/goweb -H
ADD app/main.go /var/www/goweb/main.go
RUN go build main.go
RUN go mod init main
RUN go install main
EXPOSE 9990
USER usergo:usergo
CMD ["main", "run"]