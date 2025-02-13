# Create an ec2 instance  

# where to create it - provide cloud name
provider "aws" {

  # which region to use
  region = var.region
}

# which services/resources
resource "aws_instance" "app_instance" {

    # what AMI ID
  ami = var.ami_id

  # which type of instance
  instance_type = var.instance_type

  # public Ip
  associate_public_ip_address = true

  # security group
  vpc_security_group_ids = [aws_security_group.tech501-zainab-tf-allow-port-22-3000-80.id]
  
  # key pair
  key_name = aws_key_pair.zainab-key-tf.id

  # name the isntance
  tags = {
    Name = var.instance_name
  }

}

# Creating the security group

resource "aws_security_group" "tech501-zainab-tf-allow-port-22-3000-80" {
    name        = var.security_group_name
    description = "security group"

    tags = {
        Name = var.security_group_name
    }
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh" {
  security_group_id = aws_security_group.tech501-zainab-tf-allow-port-22-3000-80.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  cidr_ipv4  = var.my-ip
}

resource "aws_vpc_security_group_ingress_rule" "allow-http" {
  security_group_id = aws_security_group.tech501-zainab-tf-allow-port-22-3000-80.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  cidr_ipv4 =  var.open-access-ip


}

resource "aws_vpc_security_group_ingress_rule" "allow-3000" {
  security_group_id = aws_security_group.tech501-zainab-tf-allow-port-22-3000-80.id
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
  cidr_ipv4 =   var.open-access-ip

}

# Creating a key pair for ec2
resource "aws_key_pair" "zainab-key-tf" {
  key_name   = var.key_name
  public_key = file(var.key_file)  # Replace with your actual public key path
}