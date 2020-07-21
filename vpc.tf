provider "aws" {
  region     = "us-east-2"
  profile    = "vpc-task"
}

// Step 1- Generating keys 

variable "key_name" {}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


// Step 2- creating a key pair in aws

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.key_name}"
  public_key = "${tls_private_key.example.public_key_openssh}"
}




variable "public_key"{
	default = "aws_key_pair.generated_key.key_name"
}

resource "local_file"  "private_key"{
 content = tls_private_key.example.private_key_pem
 filename = "${var.key_name}.pem"

depends_on = [
    tls_private_key.example,
    aws_key_pair.generated_key	
]
}


// creating vpc
resource "aws_vpc" "task3-vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames  = true

  tags = {
    Name = "task2-vpc"
  }
}

//creating subnet under vpc


// Creating public subnet in vpc 

resource "aws_subnet" "public-subnet" {
  vpc_id     = "${aws_vpc.task3-vpc.id}"
  cidr_block = "192.168.10.0/24"

  tags = {
    Name = "public-subnet"
  }
}


// Creating private subnet in vpc


resource "aws_subnet" "private-subnet" {
  vpc_id     = "${aws_vpc.task3-vpc.id}"
  cidr_block = "192.168.20.0/24"

  tags = {
    Name = "private-subnet"
  }
}


// Internet gateway 

resource "aws_internet_gateway" "public-subnet-igw" {
    vpc_id = "${aws_vpc.task3-vpc.id}"
    tags = {
        Name = "public-subnet-igw"
    }
}



//  ............................PUBLIC SUBNET SETTINGS .............................

resource "aws_route_table" "public-route" {
  vpc_id = "${aws_vpc.task3-vpc.id}"

  route {
     cidr_block = "0.0.0.0/0" 
    gateway_id = "${aws_internet_gateway.public-subnet-igw.id}"
  }

 
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public-subnet-association" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-route.id
}


// ............................





// ........................ PRIVATE  SUBNET   SETTINGS .............................



resource "aws_instance" "nat-instance" {

        depends_on = [
    aws_security_group.public-sg,
  ]
 
    ami = "ami-00d1f8201864cc10c"
    instance_type = "t2.micro"
    key_name	= "${var.key_name}"
     vpc_security_group_ids = ["${aws_security_group.public-sg.id}"]
      subnet_id = "${aws_subnet.public-subnet.id}"
    associate_public_ip_address = true
    source_dest_check = false

    tags = {
        Name = "VPC NAT INSTANCE"
    }
}


resource "aws_route_table" "private-route" {
     depends_on = [
    aws_instance.nat-instance,
  ]
  vpc_id = "${aws_vpc.task3-vpc.id}"

  route {
     cidr_block = "0.0.0.0/0" 
    instance_id = "${aws_instance.nat-instance.id}"
  }

 
  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private-subnet-association" {
       depends_on = [
    aws_route_table.private-route,
  ]
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-route.id
}










