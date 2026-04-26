output "jenkins_controller_ip" {
  description = "Public IP of the Jenkins Controller"
  value       = aws_instance.jenkins_controller.public_ip
}

output "jenkins_agent_private_ip" {
  description = "Private IP of the Jenkins Agent"
  value       = aws_instance.jenkins_agent.private_ip
}

output "jenkins_url" {
  description = "URL to access Jenkins UI"
  value       = "http://${aws_instance.jenkins_controller.public_ip}:8080"
}
