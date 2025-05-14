# Hive Take-Home – NGINX on EC2 (+ ALB)

## Deploy
```bash
terraform init
terraform apply -auto-approve
open "$(terraform output -raw alb_dns_name)"
