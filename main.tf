variable "instance_count" {
  default = 1
  }

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "us-east-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-*"]
    }
    
  filter {
    name = "virtualization-type"
    values = ["hvm"]
    }
    
  owners = ["099720109477"]
  }
  
resource "aws_instance" "amy-ptfe-demo" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "m5a.large"
  key_name = "amy-ohio"
  vpc_security_group_ids = ["sg-0753511d92cf43cc5"]
  subnet_id = "subnet-0df3e7ca2603dc1ac"
  associate_public_ip_address = true
  volume_tags {
    volume_size = "50"
    }
  count = "${var.instance_count}"
  tags {
    "Owner" = "Amy Brown"
    "Name" = "amy-ptfe-demo"
  }
}

resource "aws_route53_record" "amy-ptfe-demo" {
  count = "${var.instance_count}"
  zone_id = "Z30WCTDR9QHV42"
  name = "amy-ptfe${count.index}"
  type = "A"
  ttl = "300"
  records = ["${element(aws_instance.amy-ptfe-demo.*.public_ip, count.index)}"]
  }

output "ip" {
  value = ["${aws_instance.amy-ptfe-demo.*.public_ip}"]
}
