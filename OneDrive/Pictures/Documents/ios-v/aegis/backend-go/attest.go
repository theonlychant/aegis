package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "io"
    "io/ioutil"
    "net/http"
    "os"
    "time"
    "crypto/ecdsa"
    "crypto/x509"
    "encoding/pem"

    "github.com/golang-jwt/jwt/v5"
)

// verifyAttestation sends an attestation to Apple's App Attest verification endpoint.
// It requires the following environment variables to be set:
// - APPLE_ATTEST_URL: base URL for the Apple attestation service (e.g. https://api.appattest.apple.com)
// - APPLE_KEY_ID: the Key ID (kid) for the private key used to sign the JWT
// - APPLE_TEAM_ID: your Apple Team ID (iss)
// - APPLE_PRIVATE_KEY_PATH: path to the PEM-encoded private key (ES256)
//
// This function builds a short-lived JWT for authenticating to Apple, posts the attestation,
// and returns Apple's parsed JSON response.
func verifyAttestation(attestationB64 string, bundleID string) (map[string]interface{}, error) {
    appleURL := os.Getenv("APPLE_ATTEST_URL")
    if appleURL == "" {
        appleURL = "https://api.appattest.apple.com" // placeholder; replace if docs differ
    }
    keyID := os.Getenv("APPLE_KEY_ID")
    teamID := os.Getenv("APPLE_TEAM_ID")
    privPath := os.Getenv("APPLE_PRIVATE_KEY_PATH")
    if keyID == "" || teamID == "" || privPath == "" {
        return nil, fmt.Errorf("missing APPLE_KEY_ID, APPLE_TEAM_ID or APPLE_PRIVATE_KEY_PATH env vars")
    }

    privPem, err := ioutil.ReadFile(privPath)
    if err != nil {
        return nil, fmt.Errorf("read priv key: %w", err)
    }
    block, _ := pem.Decode(privPem)
    if block == nil {
        return nil, fmt.Errorf("failed to parse PEM")
    }
    key, err := x509.ParseECPrivateKey(block.Bytes)
    if err != nil {
        return nil, fmt.Errorf("parse EC priv key: %w", err)
    }

    // Create JWT (ES256) to authenticate to Apple's service. Header contains kid.
    now := time.Now()
    token := jwt.NewWithClaims(jwt.SigningMethodES256, jwt.MapClaims{
        "iss": teamID,
        "iat": now.Unix(),
        "exp": now.Add(5 * time.Minute).Unix(),
    })
    token.Header["kid"] = keyID

    signed, err := token.SignedString(key)
    if err != nil {
        return nil, fmt.Errorf("sign jwt: %w", err)
    }

    // Build request body to Apple's attestation endpoint. The exact endpoint and body
    // shape may change based on Apple's API; consult Apple's docs and adjust.
    body := map[string]string{
        "attestation": attestationB64,
        "bundleId":    bundleID,
    }
    b, _ := json.Marshal(body)

    req, err := http.NewRequest("POST", fmt.Sprintf("%s/attestations", appleURL), bytes.NewReader(b))
    if err != nil {
        return nil, err
    }
    req.Header.Set("Authorization", "Bearer "+signed)
    req.Header.Set("Content-Type", "application/json")

    client := &http.Client{Timeout: 20 * time.Second}
    resp, err := client.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    out, _ := io.ReadAll(resp.Body)
    if resp.StatusCode != 200 {
        return nil, fmt.Errorf("apple attestation failed: %d %s", resp.StatusCode, string(out))
    }
    var parsed map[string]interface{}
    if err := json.Unmarshal(out, &parsed); err != nil {
        return nil, fmt.Errorf("parse apple response: %w", err)
    }
    return parsed, nil
}

// helper to parse PEM from string for tests or inline keys
func parseECPrivateKeyFromPEM(pemData []byte) (*ecdsa.PrivateKey, error) {
    block, _ := pem.Decode(pemData)
    if block == nil {
        return nil, fmt.Errorf("invalid PEM data")
    }
    return x509.ParseECPrivateKey(block.Bytes)
}
