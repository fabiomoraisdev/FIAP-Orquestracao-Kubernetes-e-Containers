# Specify the provider and access details
provider "aws" {
  region = var.aws_region
}

data "aws_ssm_parameter" "al2023_ami" {
  name = var.ami_ssm_parameter
}

resource "aws_instance" "web" {
  instance_type        = "t2.medium"
  ami                  = data.aws_ssm_parameter.al2023_ami.value
  iam_instance_profile = "LabInstanceProfile"

  vpc_security_group_ids = ["${aws_security_group.allow-ssh.id}"]
  key_name               = var.KEY_NAME

  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }
  provisioner "file" {
    source      = "docker_ecr_login.service"
    destination = "/tmp/docker_ecr_login.service"
  }
  provisioner "file" {
    source      = "ecr-login.sh"
    destination = "/tmp/ecr-login.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sudo /tmp/script.sh",
      "for i in $(seq 1 20); do sudo systemctl is-active --quiet docker && break; sleep 2; done",
      "sudo systemctl is-active --quiet docker",
      "sudo cp /tmp/ecr-login.sh /etc/systemd/system/ecr-login.sh",
      "sudo chmod +x /etc/systemd/system/ecr-login.sh",
      "sudo cp /tmp/docker_ecr_login.service /etc/systemd/system/docker_ecr_login.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable docker_ecr_login",
      "sudo systemctl restart docker_ecr_login",
      "sudo systemctl --no-pager --full status docker_ecr_login || true",
      "if sudo systemctl is-failed --quiet docker_ecr_login; then sudo journalctl -u docker_ecr_login --no-pager -n 100; exit 1; fi"
    ]
  }
  user_data = <<-EOF
              #!/bin/bash -xe
              echo 'swarm_manager' | sudo tee -a /proc/sys/kernel/hostname
              sudo hostname swarm_manager
              EOF

  connection {
    user        = var.INSTANCE_USERNAME
    private_key = file("${var.PATH_TO_KEY}")
    host        = self.public_dns
  }

  tags = {
    Name = "docker-swarm-manager"
  }
}
