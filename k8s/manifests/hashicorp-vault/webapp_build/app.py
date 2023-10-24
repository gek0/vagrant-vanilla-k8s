import logging
import re
import os
import requests
from http.server import BaseHTTPRequestHandler, HTTPServer

# Configure logging
logging.basicConfig(level=logging.INFO)

VAULT_ADDR = os.environ.get("VAULT_ADDR")
SECRET_PATH = os.environ.get("SECRET_PATH")
APP_NAME = os.environ.get("APP_NAME")
JWT_PATH = os.environ.get("JWT_PATH")
CURL_TIMEOUT = 1


def authenticate_with_vault():
    if not VAULT_ADDR:
        print("Vault server not defined!")
        return None

    # Authenticate with Vault using Kubernetes service account token
    print("Authenticating with Kubernetes service account...")
    with open(JWT_PATH, "r") as jwt_file:
        k8s_sa_token = jwt_file.read()

    auth_url = f"{VAULT_ADDR}/v1/auth/kubernetes/login"
    auth_data = {"role": APP_NAME, "jwt": k8s_sa_token}
    headers = {"Content-Type": "application/json"}

    try:
        response = requests.post(auth_url, json=auth_data, headers=headers, verify=False, timeout=CURL_TIMEOUT)
        response.raise_for_status()
        auth_response = response.json()
    except requests.exceptions.RequestException as e:
        print(f"Failed to authenticate with Vault: {e}")
        return None

    token = auth_response.get("auth", {}).get("client_token")

    if not token:
        print("Failed to obtain a Vault token.")
        return None

    return token


def fetch_secrets(token):
    if not VAULT_ADDR:
        print("Vault server not defined!")
        return None

    # Specify the Vault secrets endpoint and your Vault token
    secrets_url = f"{VAULT_ADDR}/v1/{SECRET_PATH}"
    headers = {"X-Vault-Token": token}

    # Fetch secrets using the Vault token
    print("Fetching secrets...")
    try:
        response = requests.get(secrets_url, headers=headers, verify=False, timeout=1)
        response.raise_for_status()
        secrets_data = response.json().get("data", {}).get("data", {})
    except requests.exceptions.RequestException as e:
        print(f"Failed to fetch secrets: {e}")
        return None

    return secrets_data


class HTTPRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if re.search('/get/*', self.path):
            uri = self.path.split('/')[-1]

            if uri == "env":
                # Set response headers
                self.send_response(200)
                self.send_header('Content-type', 'text/html')
                self.end_headers()

                # Get environment variables and convert to JSON
                env_variables = dict(os.environ)

                # Format environment variables as a Bootstrap-styled table
                env_table = '<table class="table table-bordered table-striped">'
                env_table += '<thead><tr><th>Variable</th><th>Value</th></tr></thead>'
                env_table += '<tbody>'
                for key, value in env_variables.items():
                    env_table += f'<tr><td>{key}</td><td>{value}</td></tr>'
                env_table += '</tbody></table>'

                # Create HTML response
                response_html = f"""
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Environment Variables</title>
                    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
                </head>
                <body>
                    <div class="container">
                        <h2>Environment Variables</h2>
                        {env_table}
                    </div>
                    <!-- Include Bootstrap JS and jQuery for table styling -->
                    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
                    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.5.0/dist/js/bootstrap.min.js"></script>
                </body>
                </html>
                """

                self.wfile.write(response_html.encode())
            else:
                self.send_response(404)
                self.end_headers()
        else:
            self.send_response(403)
            self.end_headers()


if __name__ == '__main__':
    token = authenticate_with_vault()
    if token:
        secrets_data = fetch_secrets(token)
        if secrets_data:
            for key, value in secrets_data.items():
                os.environ[key] = str(value)
            print("Vault secrets have been loaded as environment variables.")
        else:
            print("Failed to fetch secrets.")
            exit(1)

    server = HTTPServer(('0.0.0.0', 8000), HTTPRequestHandler)
    logging.info('Starting webapp...\n')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    server.server_close()
    logging.info('Stopping webapp...\n')
