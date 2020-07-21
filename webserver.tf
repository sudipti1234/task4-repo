
resource "aws_security_group" "public-sg" {
    name = "public-sg"
    description = "Allow connection to public instances connections."

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

      egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }  

    vpc_id = "${aws_vpc.task3-vpc.id}"

    tags = {
        Name = "public-sg"
    }
}

resource "aws_instance" "webserver" {

           depends_on = [
    aws_security_group.public-sg,
  ]
 
    ami = "ami-0a54aef4ef3b5f881"
    instance_type = "t2.micro"
    key_name	= "${var.key_name}"
      vpc_security_group_ids = ["${aws_security_group.public-sg.id}"]
    subnet_id = "${aws_subnet.public-subnet.id}"
    associate_public_ip_address = true


    tags = {
        Name = "Web Server"
    }
}




//  LAUNCHING BASTION INTANCE IN PUBLIC ZONE TO ACCESS THE DATABASE SERVER.....................

// bastion security group 

resource "aws_security_group" "bastion-sg" {
    name = "bastion-sg"
    description = "Allow incoming traffic from bastion ."

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["192.168.0.0/16"]
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
        Name = "bastion-sg"
    }
}



resource "aws_instance" "bastion" {
        depends_on = [
    aws_security_group.bastion-sg,
  ]
    ami = "ami-0a54aef4ef3b5f881"
    instance_type = "t2.micro"
    key_name	= "${var.key_name}"
   vpc_security_group_ids = ["${aws_security_group.bastion-sg.id}"]
    subnet_id = "${aws_subnet.public-subnet.id}"
    tags = {
        Name = "Bastion"
    }
}

resource "null_resource" "copying_key" {

  provisioner "local-exec"   {
    command = "echo scp -i ${var.key_name}.pem   ${var.key_name}.pem   ec2-user@${aws_instance.webserver.public_ip}:~/"
  } 
}