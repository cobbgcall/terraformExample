package main

import (
    "fmt"
    "net/http"
//    "bytes"
//    "log"
)

func main() {
//    var(
//        buf     bytes.Buffer
//        logger = log.new(&buf, "logger: ", log.Lshortfile)
//    )

    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
//        logger.Print(r)
        fmt.Fprintf(w, "Hello World!!!")
//        logger.Print(w)
    })

    http.HandleFunc("/greet/", func(w http.ResponseWriter, r *http.Request) {
        name := r.URL.Path[len("/greet/"):]
        fmt.Fprintf(w, "Your name is %s\n", name)
    })

    http.ListenAndServe(":9990", nil)
}