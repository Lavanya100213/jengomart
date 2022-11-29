# Create a target group
resource "aws_lb_target_group" "target_group" {
  name     = "Eng84-oleg-terraform-tg-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform_vpc.id
}



# Create an application load balancer
resource "aws_lb" "load_balancer" {
  name                       = "Eng84-oleg-load-balancer"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.pub_sec_group.id]
  subnets                    = [aws_subnet.terraform_public_subnet_1.id, aws_subnet.terraform_public_subnet_2.id]
  enable_deletion_protection = false
}




# Create an AMI template
resource "aws_launch_template" "launch_template" {
  name          = "Eng84_oleg_terraform_template"
  ebs_optimized = false

  image_id      = var.app_ami
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.pub_sec_group.id]
  }

  depends_on = [aws_security_group.pub_sec_group]
}



# Create an auto-scaling group
resource "aws_autoscaling_group" "auto_scale" {
  name             = "Eng84_oleg_auto_scaling_group"
  desired_capacity = 2
  max_size         = 4
  min_size         = 1

  lifecycle {
    ignore_changes = [target_group_arns]
  }

  target_group_arns = [aws_lb_target_group.target_group.arn]

  vpc_zone_identifier = [aws_subnet.terraform_public_subnet_1.id, aws_subnet.terraform_public_subnet_2.id]

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  depends_on = [aws_launch_template.launch_template, aws_lb_listener.listener]
}



# Launching an EC2 using our db ami
# The resource keyword is used to create instances
# Resource type followed by name
resource "aws_instance" "terraform_db" {
  ami                         = var.db_ami
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = var.key
  subnet_id                   = aws_subnet.terraform_private_subnet.id
  private_ip                  = var.db_ip
  vpc_security_group_ids      = [aws_security_group.priv_sec_group.id]

  tags = {
    Name = var.db_name
  }
}