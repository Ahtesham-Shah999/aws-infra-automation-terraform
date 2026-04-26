locals {
  controller_user_data = <<-EOF
#!/bin/bash
exec > /var/log/user-data.log 2>&1
apt-get update -y

# 1. Install Java 17
apt-get install -y openjdk-17-jdk git curl unzip jq software-properties-common

# 2. Install Jenkins LTS
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update -y
apt-get install -y jenkins

# 3. Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker ubuntu
usermod -aG docker jenkins
systemctl restart jenkins

# 4. Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# 5. Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update -y
apt-get install -y terraform
EOF

  agent_user_data = <<-EOF
#!/bin/bash
exec > /var/log/user-data.log 2>&1
apt-get update -y

# Install Java 17 (Required for Jenkins agent) and Git
apt-get install -y openjdk-17-jdk git curl unzip jq software-properties-common

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker ubuntu

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update -y
apt-get install -y terraform
EOF
}

resource "aws_instance" "jenkins_controller" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  subnet_id                   = data.terraform_remote_state.a3.outputs.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.jenkins_controller.id]
  key_name                    = var.key_name
  user_data                   = local.controller_user_data
  associate_public_ip_address = true

  tags = {
    Name = "jenkins-controller"
  }
}

resource "aws_instance" "jenkins_agent" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  subnet_id                   = data.terraform_remote_state.a3.outputs.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.jenkins_agent.id]
  key_name                    = var.key_name
  user_data                   = local.agent_user_data

  tags = {
    Name = "jenkins-agent"
  }
}
