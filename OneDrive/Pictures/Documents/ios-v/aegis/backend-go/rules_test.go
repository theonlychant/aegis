package main

import (
    "encoding/json"
    "encoding/base64"
    "net/http/httptest"
    "testing"
)

func TestRulesHandler(t *testing.T) {
    req := httptest.NewRequest("GET", "/rules/latest", nil)
    w := httptest.NewRecorder()
    rulesHandler(w, req)
    res := w.Result()
    if res.StatusCode != 200 {
        t.Fatalf("expected 200 got %d", res.StatusCode)
    }
    var out map[string]string
    if err := json.NewDecoder(res.Body).Decode(&out); err != nil {
        t.Fatalf("decode failed: %v", err)
    }
    if _, ok := out["rule"]; !ok {
        t.Fatalf("missing rule field")
    }
    if _, ok := out["signature"]; !ok {
        t.Fatalf("missing signature field")
    }
    if _, ok := out["pubkey"]; !ok {
        t.Fatalf("missing pubkey field")
    }
    // validate base64 decodes
    if _, err := base64.StdEncoding.DecodeString(out["rule"]); err != nil {
        t.Fatalf("rule base64 invalid: %v", err)
    }
    if _, err := base64.StdEncoding.DecodeString(out["signature"]); err != nil {
        t.Fatalf("signature base64 invalid: %v", err)
    }
    if _, err := base64.StdEncoding.DecodeString(out["pubkey"]); err != nil {
        t.Fatalf("pubkey base64 invalid: %v", err)
    }
}
