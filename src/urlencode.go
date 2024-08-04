package main

import (
	"flag"
	"fmt"
	"net/url"
	"os"
)

func main() {
	flag.Usage = func() {
		flag.PrintDefaults()
	}

	file := flag.String("f", "", "file to convert")
	flag.Parse()

	if len(*file) == 0 {
		panic("file must not be omitted")
	}

	dat, err := os.ReadFile(*file)
	if err != nil {
		panic(err)
	}

	fmt.Println(url.QueryEscape(string(dat)))
}
