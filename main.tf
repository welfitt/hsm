provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "hsm_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "hsm_subnet" {
  vpc_id                  = aws_vpc.hsm_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "hsm_sg" {
  name        = "hsm_sg"
  vpc_id      = aws_vpc.hsm_vpc.id
  description = "Allow SSH and CloudHSM traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_IP/32"] # <-- replace this
  }

  ingress {
    from_port   = 2225
    to_port     = 2226
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudhsm_v2_cluster" "hsm_cluster" {
  hsm_type   = "hsm1.medium"
  subnet_ids = [aws_subnet.hsm_subnet.id]
}

resource "aws_instance" "hsm_initializer" {
  ami                         = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.hsm_subnet.id
  security_groups             = [aws_security_group.hsm_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.cloudhsm_instance_profile.name
  key_name                    = "your-key-name" # <-- replace this

  user_data = templatefile("${path.module}/init-hsm.sh.tpl", {
    cluster_id = aws_cloudhsm_v2_cluster.hsm_cluster.cluster_id
    region     = "us-west-2"
  })

  tags = {
    Name = "hsm-initializer"
  }
}

output "cluster_id" {
  value = aws_cloudhsm_v2_cluster.hsm_cluster.cluster_id
}

