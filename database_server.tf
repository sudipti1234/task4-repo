//  LAUNCHING DATABASE SERVER IN PRIVATE SUBNET 

resource "aws_security_group" "private-sg" {
    name = "private-sg"
    description = "Allow incoming database connections."

    ingress { # SQL Server
        from_port = 1433
        to_port = 1433
        protocol = "tcp"
        security_groups = ["${aws_security_group.public-sg.id}"]
    }
    ingress { # MySQL
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = ["${aws_security_group.public-sg.id}"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = ["${aws_security_group.bastion-sg.id}"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["192.168.0.0/16"]
    }

     egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.0.0/16"]
  }  

  vpc_id = "${aws_vpc.task3-vpc.id}"

    tags = {
        Name = "private-sg"
    }
}




resource "aws_instance" "db-server" {
        depends_on = [
    aws_security_group.bastion-sg,
    aws_security_group.private-sg,
  ]
    ami = "ami-0a54aef4ef3b5f881"
    instance_type = "t2.micro"
    key_name	= "${var.key_name}"
      vpc_security_group_ids = ["${aws_security_group.private-sg.id}"]
    subnet_id = "${aws_subnet.private-subnet.id}"


    tags = {
        Name = "DB Server "
    }
}

