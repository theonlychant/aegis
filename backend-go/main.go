package main

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"encoding/asn1"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io/ioutil"
	"log"
	"math/big"
	"net/http"
	"os"

	vault "github.com/hashicorp/vault/api"
)

type ReputationResponse struct {
	Domain string `json:"domain"`
	Score  int    `json:"score"`
	Reason string `json:"reason,omitempty"`
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("ok"))
}

func reputationHandler(w http.ResponseWriter, r *http.Request) {
	domain := r.URL.Query().Get("domain")
	if domain == "" {
		http.Error(w, "missing domain", http.StatusBadRequest)
		return
	}
	resp := ReputationResponse{Domain: domain, Score: 50, Reason: "placeholder"}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func attestVerifyHandler(w http.ResponseWriter, r *http.Request) {
	type Req struct {
		Token string `json:"token"`
	}
	var req Req
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	// Expect the client to send a JSON object like {"attestation":"<base64>", "bundleId":"com.example.aegis"}
	var payload struct {
		Attestation string `json:"attestation"`
		BundleID    string `json:"bundleId"`
	}
	if err := json.Unmarshal([]byte(req.Token), &payload); err != nil {
		// Try parsing directly from body in case the above format wasn't used
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
			http.Error(w, "invalid attestation payload", http.StatusBadRequest)
			return
		}
	}

	parsed, err := verifyAttestation(payload.Attestation, payload.BundleID)
	if err != nil {
		http.Error(w, fmt.Sprintf("attestation verification failed: %v", err), http.StatusBadRequest)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(parsed)
}

// Serve a signed rule pack. Loads or generates an ECDSA P-256 key and signs the rule pack.
func rulesHandler(w http.ResponseWriter, r *http.Request) {
	// Load rule data from rules/example-rule.json (for demonstration)
	data, err := ioutil.ReadFile("rules/example-rule.json")
	if err != nil {
		http.Error(w, "failed to read rule pack", http.StatusInternalServerError)
		return
	}

	// Obtain signing key: prefer Vault if configured, otherwise file-based key
	priv, err := getSigningKey()
	if err != nil {
		// As a last resort, generate ephemeral key (not suitable for production)
		log.Println("warning: could not load signing key from vault/file, generating ephemeral key:", err)
		k, genErr := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
		if genErr != nil {
			http.Error(w, "failed to generate key", http.StatusInternalServerError)
			return
		}
		priv = k
	}

	// Sign rule pack (sha256 ASN.1 signature)
	sigR, sigS, err := ecdsa.Sign(rand.Reader, priv, sha256Sum(data))
	if err != nil {
		http.Error(w, "sign failed", http.StatusInternalServerError)
		return
	}
	sigBytes, err := asn1Marshal(sigR, sigS)
	if err != nil {
		http.Error(w, "sig marshal failed", http.StatusInternalServerError)
		return
	}

	pubBytes, _ := x509.MarshalPKIXPublicKey(&priv.PublicKey)

	// Versioning and key id (kid)
	version := os.Getenv("RULE_VERSION")
	if version == "" {
		version = "1"
	}
	kid := os.Getenv("RULE_KEY_ID")
	if kid == "" {
		kid = "demo"
	}

	// Sign the payload: concatenate version + \n + rule bytes
	payload := append([]byte(version+"\n"), data...)
	sigR, sigS, err = ecdsa.Sign(rand.Reader, priv, sha256Sum(payload))
	if err != nil {
		http.Error(w, "sign failed", http.StatusInternalServerError)
		return
	}
	sigBytes, err = asn1Marshal(sigR, sigS)
	if err != nil {
		http.Error(w, "sig marshal failed", http.StatusInternalServerError)
		return
	}

	out := map[string]string{
		"version": version,
		"kid": kid,
		"rule": base64.StdEncoding.EncodeToString(data),
		"signature": base64.StdEncoding.EncodeToString(sigBytes),
		"pubkey": base64.StdEncoding.EncodeToString(pubBytes),
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(out)
}

// rulesEncryptedHandler returns an encrypted rulepack using ECDH (P-256) with the client's public key.
// Request JSON: { "pubkey": "<base64 uncompressed EC public key bytes>" }
// Response JSON: { "version","kid","ephemeral_pub","nonce","ciphertext","signature" }
func rulesEncryptedHandler(w http.ResponseWriter, r *http.Request) {
	type Req struct{
		PubKey string `json:"pubkey"`
	}
	var req Req
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}

	clientPubBytes, err := base64.StdEncoding.DecodeString(req.PubKey)
	if err != nil {
		http.Error(w, "invalid pubkey", http.StatusBadRequest)
		return
	}

	// Parse uncompressed EC point
	cx, cy := elliptic.Unmarshal(elliptic.P256(), clientPubBytes)
	if cx == nil {
		http.Error(w, "invalid pubkey format", http.StatusBadRequest)
		return
	}
	clientPub := &ecdsa.PublicKey{Curve: elliptic.P256(), X: cx, Y: cy}

	// Load rule data
	data, err := ioutil.ReadFile("rules/example-rule.json")
	if err != nil {
		http.Error(w, "failed to read rule pack", http.StatusInternalServerError)
		return
	}

	// Ephemeral key and shared secret (ECDH)
	eph, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		http.Error(w, "failed to generate ephemeral key", http.StatusInternalServerError)
		return
	}
	sx, _ := clientPub.Curve.ScalarMult(clientPub.X, clientPub.Y, eph.D.Bytes())
	shared := sx.Bytes()
	k := sha256.Sum256(shared)

	// Encrypt with AES-GCM
	block, err := aes.NewCipher(k[:])
	if err != nil {
		http.Error(w, "cipher error", http.StatusInternalServerError)
		return
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		http.Error(w, "gcm error", http.StatusInternalServerError)
		return
	}
	nonce := make([]byte, gcm.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		http.Error(w, "nonce error", http.StatusInternalServerError)
		return
	}
	ciphertext := gcm.Seal(nil, nonce, data, nil)

	// Signing key and version/kid
	priv, err := getSigningKey()
	if err != nil {
		// fallback generate ephemeral (not for prod)
		priv, err = ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
		if err != nil {
			http.Error(w, "sign key error", http.StatusInternalServerError)
			return
		}
	}
	version := os.Getenv("RULE_VERSION")
	if version == "" { version = "1" }
	kid := os.Getenv("RULE_KEY_ID")
	if kid == "" { kid = "demo" }

	// Sign version + \n + ciphertext
	payload := append([]byte(version+"\n"), ciphertext...)
	rSig, sSig, err := ecdsa.Sign(rand.Reader, priv, sha256Sum(payload))
	if err != nil {
		http.Error(w, "sign failed", http.StatusInternalServerError)
		return
	}
	sigBytes, err := asn1Marshal(rSig, sSig)
	if err != nil {
		http.Error(w, "sig marshal failed", http.StatusInternalServerError)
		return
	}

	ephPub := elliptic.Marshal(elliptic.P256(), eph.PublicKey.X, eph.PublicKey.Y)

	out := map[string]string{
		"version": version,
		"kid": kid,
		"ephemeral_pub": base64.StdEncoding.EncodeToString(ephPub),
		"nonce": base64.StdEncoding.EncodeToString(nonce),
		"ciphertext": base64.StdEncoding.EncodeToString(ciphertext),
		"signature": base64.StdEncoding.EncodeToString(sigBytes),
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(out)
}

// helper functions for ECDSA signing
func sha256Sum(b []byte) []byte {
	h := sha256.New()
	h.Write(b)
	return h.Sum(nil)
}

func asn1Marshal(r, s *big.Int) ([]byte, error) {
	type ecdsaSig struct{ R, S *big.Int }
	return asn1.Marshal(ecdsaSig{r, s})
}

func main() {
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/reputation", reputationHandler)
	http.HandleFunc("/attest/verify", attestVerifyHandler)
	http.HandleFunc("/rules/latest", authMiddleware(rulesHandler))
	http.HandleFunc("/rules/encrypted", authMiddleware(rulesEncryptedHandler))
	http.HandleFunc("/rules/rotate", authMiddleware(rulesRotateHandler))

	addr := ":8080"
	cert := os.Getenv("TLS_CERT_PATH")
	key := os.Getenv("TLS_KEY_PATH")
	if cert != "" && key != "" {
		log.Println("aegis backend listening on https :8443")
		log.Fatal(http.ListenAndServeTLS(":8443", cert, key, nil))
	}

	log.Println("aegis backend listening on :8080 (insecure HTTP)")
	log.Fatal(http.ListenAndServe(addr, nil))
}

// authMiddleware enforces a simple API key header for sensitive endpoints.
func authMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		apiKey := os.Getenv("API_KEY")
		if apiKey == "" {
			http.Error(w, "server misconfigured: no API_KEY", http.StatusInternalServerError)
			return
		}
		got := r.Header.Get("X-API-KEY")
		if got != apiKey {
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}
		next(w, r)
	}
}

// rulesRotateHandler allows rotating the signing key. The new key PEM is expected in the POST body.
func rulesRotateHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}
	// If VAULT_ADDR is configured, write into Vault secret path; otherwise write to RULE_KEY_PATH file if set.
	vaultAddr := os.Getenv("VAULT_ADDR")
	if vaultAddr != "" {
		client, err := vault.NewClient(&vault.Config{Address: vaultAddr})
		if err != nil {
			http.Error(w, "vault client error", http.StatusInternalServerError)
			return
		}
		token := os.Getenv("VAULT_TOKEN")
		if token == "" {
			http.Error(w, "vault token required", http.StatusInternalServerError)
			return
		}
		client.SetToken(token)
		secretPath := os.Getenv("VAULT_SECRET_PATH")
		if secretPath == "" {
			secretPath = "secret/data/aegis/rulekey"
		}
		data := map[string]interface{}{"data": map[string]interface{}{"privkey_pem": string(body)}}
		_, err = client.Logical().Write(secretPath, data)
		if err != nil {
			http.Error(w, "vault write failed", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
		return
	}

	keyPath := os.Getenv("RULE_KEY_PATH")
	if keyPath == "" {
		http.Error(w, "no RULE_KEY_PATH configured", http.StatusInternalServerError)
		return
	}
	if err := ioutil.WriteFile(keyPath, body, 0600); err != nil {
		http.Error(w, "failed to write key", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("ok"))
}

// getSigningKey attempts to fetch an ECDSA P-256 private key from Vault or file
func getSigningKey() (*ecdsa.PrivateKey, error) {
	// Try Vault first
	vaultAddr := os.Getenv("VAULT_ADDR")
	if vaultAddr != "" {
		client, err := vault.NewClient(&vault.Config{Address: vaultAddr})
		if err != nil {
			return nil, fmt.Errorf("vault client: %w", err)
		}
		token := os.Getenv("VAULT_TOKEN")
		if token == "" {
			return nil, fmt.Errorf("vault token missing")
		}
		client.SetToken(token)
		secretPath := os.Getenv("VAULT_SECRET_PATH")
		if secretPath == "" {
			secretPath = "secret/data/aegis/rulekey"
		}
		secret, err := client.Logical().Read(secretPath)
		if err != nil || secret == nil {
			return nil, fmt.Errorf("vault read failed: %w", err)
		}
		// Expect data.privkey_pem
		dataMap, ok := secret.Data["data"].(map[string]interface{})
		if !ok {
			return nil, fmt.Errorf("vault data missing")
		}
		pemStr, ok := dataMap["privkey_pem"].(string)
		if !ok {
			return nil, fmt.Errorf("vault privkey_pem missing")
		}
		block, _ := pem.Decode([]byte(pemStr))
		if block == nil {
			return nil, fmt.Errorf("invalid pem from vault")
		}
		k, err := x509.ParseECPrivateKey(block.Bytes)
		if err != nil {
			return nil, fmt.Errorf("parse ec key: %w", err)
		}
		return k, nil
	}

	// Fallback to file
	keyPath := os.Getenv("RULE_KEY_PATH")
	if keyPath == "" {
		return nil, fmt.Errorf("no key source configured")
	}
	pemBytes, err := ioutil.ReadFile(keyPath)
	if err != nil {
		return nil, fmt.Errorf("read key file: %w", err)
	}
	block, _ := pem.Decode(pemBytes)
	if block == nil {
		return nil, fmt.Errorf("invalid pem in file")
	}
	k, err := x509.ParseECPrivateKey(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("parse ec key: %w", err)
	}
	return k, nil
}
