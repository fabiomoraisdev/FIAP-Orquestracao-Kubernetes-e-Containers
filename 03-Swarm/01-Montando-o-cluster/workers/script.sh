#!/bin/bash
set -euo pipefail

REGION="us-east-1"

if command -v dnf >/dev/null 2>&1; then
  sudo dnf update -y
  sudo dnf install -y docker jq unzip git
else
  sudo yum update -y
  sudo yum install -y docker jq unzip git
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl nao encontrado apos instalacao de pacotes"
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker nao encontrado apos instalacao de pacotes"
  exit 1
fi

sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl is-active --quiet docker

sudo tee /usr/local/bin/ensure-docker-access.sh >/dev/null <<'EOF'
#!/bin/bash
set -euo pipefail

groupadd -f docker

for user in ec2-user ssm-user; do
  if id -u "$user" >/dev/null 2>&1; then
    usermod -aG docker "$user"
  fi
done

if [ -S /var/run/docker.sock ]; then
  chgrp docker /var/run/docker.sock || true
  chmod 660 /var/run/docker.sock || true
fi
EOF
sudo chmod +x /usr/local/bin/ensure-docker-access.sh

sudo tee /etc/systemd/system/ensure-docker-access.service >/dev/null <<'EOF'
[Unit]
Description=Ensure Docker access for ec2-user and ssm-user
After=docker.service amazon-ssm-agent.service
Wants=docker.service amazon-ssm-agent.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ensure-docker-access.sh

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/ensure-docker-access.timer >/dev/null <<'EOF'
[Unit]
Description=Periodically ensure Docker access users

[Timer]
OnBootSec=30s
OnUnitActiveSec=1min
Unit=ensure-docker-access.service

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now ensure-docker-access.service
sudo systemctl enable --now ensure-docker-access.timer

for i in {1..20}; do
  if docker info >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
docker info >/dev/null

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
rm -rf aws
unzip -o awscliv2.zip
sudo ./aws/install --update

aws configure set default.region "$REGION"

WORKER_TOKEN="$(aws ssm get-parameter --name "docker-join-worker-token" | jq -r .Parameter.Value)"
MANAGER_IP="$(aws ssm get-parameter --name "docker-join-manager-ip" | jq -r .Parameter.Value)"

if [ -z "$WORKER_TOKEN" ] || [ -z "$MANAGER_IP" ]; then
  echo "Parametros SSM do cluster nao encontrados"
  exit 1
fi

for i in {1..20}; do
  if docker swarm join --token "$WORKER_TOKEN" "$MANAGER_IP:2377"; then
    break
  fi
  sleep 3
done

if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
  echo "Falha ao entrar no swarm como worker"
  exit 1
fi

TOKEN="$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")"
PUBLIC_IP="$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)"
aws ssm put-parameter --name "docker-worker-ip" --value "$PUBLIC_IP" --type "String" --overwrite

ACCOUNT_ID="$(aws sts get-caller-identity | jq -r .Account)"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
