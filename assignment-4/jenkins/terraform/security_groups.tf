# Jenkins Controller SG
resource "aws_security_group" "jenkins_controller" {
  name        = "jenkins-controller-sg"
  description = "Allow SSH and 8080 from my IP"
  vpc_id      = data.terraform_remote_state.a3.outputs.vpc_id

  ingress {
    description = "Jenkins UI from My IP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "SSH from My IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-controller-sg"
  }
}

# Jenkins Agent SG
resource "aws_security_group" "jenkins_agent" {
  name        = "jenkins-agent-sg"
  description = "Allow SSH from Jenkins Controller only"
  vpc_id      = data.terraform_remote_state.a3.outputs.vpc_id

  ingress {
    description     = "SSH from Controller"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_controller.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-agent-sg"
  }
}
