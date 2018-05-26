package main

import "testing"

func TestMainHandler(t *testing.T) {
	exp := "Hello world"
	resp := Handler()
	if resp != exp {
		t.Fatalf("Expected '%v' got '%v'", exp, resp)
	}
}
