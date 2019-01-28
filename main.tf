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
    "Name" = "amy-ptfe${count.index}"
  }
}

resource "aws_route53_record" "amy-ptfe-demo" {
  count = "${var.instance_count}"
  zone_id = "Z30WCTDR9QHV42"
  name = "amy-ptfe${count.index}"
  type = "A"
  ttl = "300"
  records = ["${element(aws_instance.amy-ptfe-demo.*.public_ip, count.index)}"]
  
  connection {
    type = "ssh"
    host = "${element(aws_instance.amy-ptfe-demo.*.public_ip, count.index)}"
    user = "ubuntu"
    private_key = "${var.aws_pem}"
    agent = false
    }
  
  provisioner "remote-exec" {
    inline = [
      "mkdir /tmp/ptfe-install",
      "sudo apt-get install -y software-properties-common",
      "sudo add-apt-repository -y universe",
      "sudo add-apt-repository -y ppa:certbot/certbot",
      "sudo apt-get install -y certbot",
      "sudo certbot certonly --standalone --non-interactive --agree-tos --email ${var.email_address} -d ${element(aws_route53_record.amy-ptfe-demo.*.fqdn, count.index)}",
      ]
    }
  
  provisioner "file" {
    source = "${var.json_location}"
    destination = "/tmp/ptfe-install/settings.json"
    }
  
  provisioner "file" {
    source = "${var.replicated_conf}"
    destination = "/etc/replicated.conf"
    }
  
  provisioner "file" {
    source = "${var.license}"
    destination = "/tmp/ptfe-install/license.rli"
    }
  
  provisioner "remote-exec" {
    inline = [
      "cd /tmp/ptfe-install; curl -o install.sh https://install.terraform.io/ptfe/stable",
      "bash /tmp/ptfe-install/install.sh no-proxy private-address=${element(aws_instance.amy-ptfe-demo.*.public_ip, count.index)} public-address=${element(aws_instance.amy-ptfe-demo.*.public_ip, count.index)}"
      ]
    }
}

#resource "null_resource" "provision_ptfe" {  
#  triggers {
#    route53_resource = "$(element{aws_route53_record.amy-ptfe-demo.id, count.index)}"
#    }
#}

output "ip" {
  value = ["${aws_instance.amy-ptfe-demo.*.public_ip}"]
}

output "fqdn" {
  value = "${aws_route53_record.amy-ptfe-demo.*.fqdn}"
  }


