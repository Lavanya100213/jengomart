data "aws_availability_zones" "all" {}
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}
data "aws_region" "current" {}

locals {
  name               = "demo"
  is_non_prod        = var.env == "prod" ? false : true
  availability_zones = slice(sort(data.aws_availability_zones.all.zone_ids), 0, var.number_of_azs)
  account            = data.aws_caller_identity.current.account_id
  region             = data.aws_region.current.name
  tags = {
    Environment                                   = var.env
    Name                                          = local.name
  }
}

module "vpc" {
  source = "./vpc"

  vpc_name                 = local.name
  vpc_azs                  = local.availability_zones
  vpc_single_nat_gateway   = local.is_non_prod
  vpc_enable_nat_gateway   = true
  vpc_enable_dns_hostnames = true
  vpc_tags                 = local.tags
}

// external facing load balancer
resource "aws_lb" "ext_lb" {
  name_prefix        = local.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.external_facing_web_sg.id]
  subnets            = module.vpc.vpc_public_subnet_ids
  drop_invalid_header_fields = true
  enable_deletion_protection = false

  tags = {
    Environment = var.env
  }
}

data "aws_iam_role" "myrole" {
  name = "0b1-wan-ken0be"
}

resource "aws_lb_listener" "ext_lb" {
  load_balancer_arn = aws_lb.ext_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = format("\"These aren't the Dr01ds you're looking for.\", said %s in %s", data.aws_iam_role.myrole.id, local.region )
      status_code  = "404"
    }
  }
}
# Create the Subnet
resource "aws_subnet" "terraform_public_subnet" {
  vpc_id     = aws_vpc.terraform_vpc.id
  cidr_block = "10.0.1.0/24"
  #availability_zone = "eu-west-1c"

  tags = {
    Name = var.aws_subnet_pub
  }
}

resource "aws_subnet" "terraform_private_subnet" {
  vpc_id     = aws_vpc.terraform_vpc.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = var.aws_subnet_priv
  }
}
# Create an internet gateway that attaches to our vpc
resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = var.igw_name
  }
}



# Edit the main route table
resource "aws_default_route_table" "terraform_rt_pub" {
  default_route_table_id = aws_vpc.terraform_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  tags = {
    Name = var.pub_rt_name
  }
}
# Create Private route table
resource "aws_route_table" "terraform_rt_priv" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = var.priv_rt_name
  }
}


# Associate route tables with subnets
resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.terraform_public_subnet.id
  route_table_id = aws_vpc.terraform_vpc.default_route_table_id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.terraform_private_subnet.id
  route_table_id = aws_route_table.terraform_rt_priv.id
}

// external facing load balancer security group allowing inbound http
resource "aws_security_group" "external_facing_web_sg" {
  name        = "external-facing-web-sg"
  description = "Allow inbound HTTP"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow ingress access to port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow egress access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "external-facing-web-sg"
  }
}

#Create db instance first
resource "aws_instance" "terraform_db" {
  ami                         = var.db_ami_id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = var.aws_key_name
  subnet_id                   = aws_subnet.terraform_private_subnet.id
  private_ip                  = var.db_ip
  vpc_security_group_ids      = [aws_security_group.priv_sec_group.id]

  tags = {
    Name = "${var.db_name}"
  }
}


# Create and assign an instance to the subnet
resource "aws_instance" "app_instance" {
  # add the AMI id between "" as below
  ami = var.webapp_ami_id

  # Let's add the type of instance we would like launch
  instance_type = "t2.micro"
  #The key_name to ssh into instance
  key_name = var.aws_key_name
  #aws_key_path = var.aws_key_path

  # Subnet
  subnet_id = aws_subnet.terraform_public_subnet.id

  # Security group
  vpc_security_group_ids = [aws_security_group.pub_sec_group.id]

  # Do we need to enable public IP for our app
  associate_public_ip_address = true

  # Tags is to give name to our instance
  tags = {
    Name = "${var.webapp_name}"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${var.aws_key_path}") #var.aws_key_path "${file("${var.PRIVATE_KEY_PATH}")}"
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "./scripts/app/init.sh"
    destination = "/tmp/init.sh"
  }

  # Change permissions on bash script and execute.
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init.sh",
      "bash /tmp/init.sh",
    ]
  }


}
