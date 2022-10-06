package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"fmt"
	vault "github.com/hashicorp/vault/api"
	auth "github.com/hashicorp/vault/api/auth/kubernetes"
	"io/ioutil"
	"net/http"
	"os"
)

var (
	VaultAddr   = "https://127.0.0.1:8200"
	VaultCAPath = "/run/secrets/kubernetes.io/serviceaccount/ca.crt"
	SATokenPath = "/run/secrets/kubernetes.io/serviceaccount/token"
	RoleName    = ""
)

func envConfig() {
	if v := os.Getenv("VAULT_ADDR"); v != "" {
		VaultAddr = v
	}
	if v := os.Getenv("VAULT_CA_PATH"); v != "" {
		VaultCAPath = v
	}
	if v := os.Getenv("SA_TOKEN_PATH"); v != "" {
		SATokenPath = v
	}
	if v := os.Getenv("ROLE_NAME"); v != "" {
		RoleName = v
	}
}

func main() {
	envConfig()

	vaultClient, err := getVaultClient()
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println(vaultClient.Token())
}

func getVaultClient() (*vault.Client, error) {
	var httpTransport = HTTPTransport()
	// If set, the VAULT_ADDR environment variable will be the address that
	// your pod uses to communicate with Vault.
	var config = vault.DefaultConfig() // modify for more granular configuration

	// set Vault address
	config.Address = VaultAddr

	// if CA Cert path exists, then...
	if FileExists(VaultCAPath) {
		caCert, err := ioutil.ReadFile(VaultCAPath)
		if err != nil {
			return nil, fmt.Errorf("%v", err)
		}
		caCertPool := x509.NewCertPool()
		caCertPool.AppendCertsFromPEM(caCert)
		httpTransport.TLSClientConfig = &tls.Config{RootCAs: caCertPool}
		config.HttpClient = &http.Client{Transport: httpTransport}
	}

	vaultClient, err := vault.NewClient(config)
	if err != nil {
		return nil, fmt.Errorf("%v", err)
	}

	// The service-account token will be read from the path where the token's
	// Kubernetes Secret is mounted. By default, Kubernetes will mount it to
	// /var/run/secrets/kubernetes.io/serviceaccount/token, but an administrator
	// may have configured it to be mounted elsewhere.
	// In that case, we'll use the option WithServiceAccountTokenPath to look
	// for the token there.
	k8sAuth, err := auth.NewKubernetesAuth(RoleName, auth.WithServiceAccountTokenPath(SATokenPath))
	if err != nil {
		return nil, fmt.Errorf("unable to initialize Kubernetes auth method: %w", err)
	}

	authInfo, err := vaultClient.Auth().Login(context.TODO(), k8sAuth)
	if err != nil {
		return nil, fmt.Errorf("unable to log in with Kubernetes auth: %w", err)
	}
	if authInfo == nil {
		return nil, fmt.Errorf("no auth info was returned after login")
	}

	return vaultClient, nil
}
