package main

import (
	"io/ioutil"
	"net/http/httptest"
	"testing"
	"fmt"
)

func TestDebugRules(t *testing.T) {
	req := httptest.NewRequest("GET", "/rules/latest", nil)
	w := httptest.NewRecorder()
	rulesHandler(w, req)
	res := w.Result()
	b, _ := ioutil.ReadAll(res.Body)
	fmt.Printf("status=%d\nbody=%s\n", res.StatusCode, string(b))
}
