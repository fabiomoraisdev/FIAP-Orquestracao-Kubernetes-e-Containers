#!/bin/bash
set -euo pipefail

REGION="us-east-1"

if command -v dnf >/dev/null 2>&1; then
  sudo dnf update -y
  sudo dnf install -y docker jq unzip
else
  sudo yum update -y
  sudo yum install -y docker jq unzip
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

if id -u ec2-user >/dev/null 2>&1; then
  sudo usermod -aG docker ec2-user
fi

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

TOKEN="$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")"
PUBLIC_IP="$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)"

docker swarm init --advertise-addr "$PUBLIC_IP" || true

WORKER_TOKEN="$(docker swarm join-token worker -q)"
MANAGER_TOKEN="$(docker swarm join-token manager -q)"

aws configure set default.region "$REGION"
aws ssm put-parameter --name "docker-join-worker-token" --value "$WORKER_TOKEN" --type "String" --overwrite
aws ssm put-parameter --name "docker-join-manager-token" --value "$MANAGER_TOKEN" --type "String" --overwrite
aws ssm put-parameter --name "docker-join-manager-ip" --value "$PUBLIC_IP" --type "String" --overwrite

ACCOUNT_ID="$(aws sts get-caller-identity | jq -r .Account)"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
