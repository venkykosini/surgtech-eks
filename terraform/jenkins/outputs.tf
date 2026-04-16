output "jenkins_public_ip" {
  value = aws_eip.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_eip.jenkins.public_ip}:8080"
}

output "jenkins_webhook_url" {
  value = "http://${aws_eip.jenkins.public_ip}:8080/github-webhook/"
}

output "jenkins_admin_username" {
  value = var.jenkins_admin_username
}

output "jenkins_admin_password" {
  value     = random_password.jenkins_admin.result
  sensitive = true
}

output "jenkins_job_name" {
  value = var.jenkins_job_name
}
