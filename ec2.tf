resource "aws_iam_role" "ecsInstanceRole" {
  name               = "ecsInstanceRole"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_ecs.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"]
   tags = {
   "environment" = "${var.env}" 
   "application" = "${local.app_name}"
 }
}

resource "aws_iam_instance_profile" "ec2_ecs_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ecsInstanceRole.name
  tags = {
   "environment" = "${var.env}" 
   "application" = "${local.app_name}"
 }
}

resource "aws_launch_template" "ecs_lt" {
 name_prefix   = "ecs-${local.app_name}-template"
 image_id      = data.aws_ami.isolutions_ec2_ami.id
 instance_type = "t3.micro"

 key_name               = "ecs_isolutions"
 vpc_security_group_ids = [aws_security_group.ecs_instance_security_group.id]
 iam_instance_profile {
   arn = aws_iam_instance_profile.ec2_ecs_instance_profile.arn
 }

 block_device_mappings {
   device_name = "/dev/xvda"
   ebs {
     volume_size = 30
     volume_type = "gp2"
   }
 }

 tag_specifications {
   resource_type = "instance"
   tags = {
     environment = "${var.env}"
     application="${local.app_name}"
   }
 }

 user_data = filebase64("${path.module}/ecs.sh")
}



resource "aws_autoscaling_group" "ecs_asg" {
 vpc_zone_identifier = [aws_subnet.zonea.id, aws_subnet.zoneb.id]
 desired_capacity    = 1
 max_size            = 2
 min_size            = 1

 launch_template {
   id      = aws_launch_template.ecs_lt.id
   version = "$Latest"
 }

 tag {
   key                 = "AmazonECSManaged"
   value               = true
   propagate_at_launch = true
 }
}


resource "aws_lb" "isolutionz_ecs_alb" {
 name               = "ecs-alb"
 internal           = false
 load_balancer_type = "application"
 security_groups    = [aws_security_group.load_balancer_security_group.id]
 subnets            = [aws_subnet.zonea.id, aws_subnet.zoneb.id]

 tags = {
   name = "ecs-alb"
   environment = "${var.env}" 
   application = "${local.app_name}"
   
 }
}

resource "aws_lb_listener" "ecs_alb_listener" {
 load_balancer_arn = aws_lb.isolutionz_ecs_alb.arn
 port              = 80
 protocol          = "HTTP"

 default_action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.ecs_tg.arn
 }
}

resource "aws_lb_target_group" "ecs_tg" {
 name        = "ecs-target-group"
 port        = 80
 protocol    = "HTTP"
 target_type = "ip"
 vpc_id      = aws_vpc.isolutionz_vpc.id

 health_check {
   path = "/docs/auth/isolutionz"
 }
  tags = {
   environment = "${var.env}" 
   application = "${local.app_name}"
 }
}


