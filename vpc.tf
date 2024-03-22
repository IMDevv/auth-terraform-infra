resource "aws_vpc" "isolutionz_vpc" {
 cidr_block           = var.vpc_cidr
 enable_dns_hostnames = true
 tags = {
   name = "${local.app_name}-vpc-main"
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

resource "aws_subnet" "zonea" {
 vpc_id                  = aws_vpc.isolutionz_vpc.id
 cidr_block              = cidrsubnet(aws_vpc.isolutionz_vpc.cidr_block, 8, 1)
 map_public_ip_on_launch = true
 availability_zone       = "eu-west-1a"
 tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

resource "aws_subnet" "zoneb" {
 vpc_id                  = aws_vpc.isolutionz_vpc.id
 cidr_block              = cidrsubnet(aws_vpc.isolutionz_vpc.cidr_block, 8, 2)
 map_public_ip_on_launch = true
 availability_zone       = "eu-west-1b"
 tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

resource "aws_internet_gateway" "isolutionz_internet_gateway" {
 vpc_id = aws_vpc.isolutionz_vpc.id
 tags = {
   name = "internet_gateway"
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

resource "aws_route_table" "isolutionz_route_table" {
 vpc_id = aws_vpc.isolutionz_vpc.id
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.isolutionz_internet_gateway.id
 }
 tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

resource "aws_route_table_association" "subneta_route" {
 subnet_id      = aws_subnet.zonea.id
 route_table_id = aws_route_table.isolutionz_route_table.id
}


resource "aws_route_table_association" "subnetb_route" {
 subnet_id      = aws_subnet.zoneb.id
 route_table_id = aws_route_table.isolutionz_route_table.id
}

resource "aws_security_group" "ecs_instance_security_group" {
  name        = "ecs-instance-security-group"
  description = "Security group for ECS instances"
  vpc_id      = aws_vpc.isolutionz_vpc.id

  // Allow incoming SSH (port 22) from your IP address or a specific range
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["41.90.186.42/32"]  
    description = "Allow SSH access"
  }

  // Allow incoming traffic on port 4000 for your ECS service
  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming traffic on port 4000"
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #allowing the traffic from load balancer security group
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  // Allow outgoing traffic to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

# Create a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
  name        = "lb_sg"
  description = "security group for the load_balancer"
  vpc_id      = aws_vpc.isolutionz_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "Permit incoming HTTP requests from the internet"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Permit all outgoing requests to the internet"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}

# To ensure access for ecs service with more secure vpc create a aws sercurity group service.
resource "aws_security_group" "service_security_group" {
  name        = "service_sg"
  description = "security group for the ecs service"
  vpc_id      = aws_vpc.isolutionz_vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #allowing the traffic from ec2 instance security group
    security_groups = ["${aws_security_group.ecs_instance_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}
