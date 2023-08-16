provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["/home/hp/.aws/credentials"]
}

# vpc 

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "test"
    project = "sprints"
  }
}
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.myvpc.id
  
}

#public subnet

resource "aws_subnet" "public" {
    cidr_block = "10.0.0.0/24"
    vpc_id = aws_vpc.myvpc.id
    
}
#route table

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "PublicRtassociation" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.rt.id
}

#security group

resource "aws_security_group" "websg" {
    name = "sprints security group using terraform"
    description = "sprints security group using terraform"
    vpc_id = aws_vpc.myvpc.id

    ingress {
        description = "HTTPS"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    ingress  {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
       ingress  {
        description = "SSH"
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
       ingress  {
        description = "SSH"
        from_port = 9000
        to_port = 9000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    ingress  {
        description = "SSH"
        from_port = 0
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    egress  {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "web_sg"
    }
  
}


data "aws_ami" "ubuntu" {

    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"]
}

resource "aws_instance" "ec2" {
  ami = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  tags = {
    Name = "sprints-ansible"
  }
  #vpc_id = aws_vpc.myvpc.id
  subnet_id = aws_subnet.public.id
  key_name = "sprints-key"
  vpc_security_group_ids = [aws_security_group.websg.id]
  associate_public_ip_address = true
  
}

resource "null_resource" "write_ip_to_file" {
  provisioner "local-exec" {
    command = "echo '\nec2 ansible_host=${aws_instance.ec2.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=./sprints-key.pem' >> inventory.txt"
  }
  depends_on = [aws_instance.ec2]
}