package main

import (
    "fmt"
    "net/http"
    "bytes"
    "log"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello World!!!")
    })

    http.HandleFunc("/greet/", func(w http.ResponseWriter, r *http.Request) {
        name := r.URL.Path[len("/greet/"):]
        fmt.Fprintf(w, "Your name is %s\n", name)
    })

    http.ListenAndServe(":9990", nil)
}