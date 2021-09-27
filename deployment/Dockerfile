FROM alpine
RUN apk update
RUN apk --update add go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH
RUN apk add bash 
RUN apk add openrc --no-cache 
WORKDIR /var/www/goweb
ADD app/main.go /var/www/goweb/main.go
RUN go build main.go
RUN go mod init main
RUN go install main
EXPOSE 80
CMD ["main", "run"]