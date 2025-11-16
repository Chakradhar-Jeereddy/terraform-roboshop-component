resource "aws_instance" "main" {
    ami = local.ami_id
    subnet_id = local.private_subnet_id
    instance_type = "t3.micro"
    vpc_security_group_ids = [local.sg_id]
    tags = merge(
       local.common_tags,
       {
         Name = "${local.common_name_suffix}-${var.component}" #roboshop-dev-%%
       }
    )
}

resource "terraform_data" "main" {
  triggers_replace = [
    aws_instance.main.id  #trigger when ID is changed.
  ]

connection {
    type = "ssh"
    user = "ec2-user"
    password = "DevOps321"
    host = aws_instance.main.private_ip
}
provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
}

  provisioner "remote-exec" {
    inline = [
        "chmod +x /tmp/bootstrap.sh",
        "sudo sh /tmp/bootstrap.sh ${var.component} ${var.environment}"
    ]
  }
}
resource "aws_ec2_instance_state" "main" {
  instance_id = aws_instance.main.id
  state       = "stopped"
  force       = false # Set to true for a forced stop (use with caution)
  depends_on = [ terraform_data.main ]
}

resource "aws_ami_from_instance" "main" {
  name               = "${local.common_name_suffix}-${var.component}-ami"
  source_instance_id = aws_instance.main.id
  depends_on = [ aws_ec2_instance_state.main ]
  tags = merge(
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-{var.component}-ami" #roboshop-dev-catalogue-ami
    }
  )

}

resource "aws_lb_target_group" "main" {
  name     = "${local.common_name_suffix}-${var.component}"
  port     = local.tg_port# if frontend port is 80, otherwise port is 8080
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  deregistration_delay = 60 # Waiting period before deleting the instance
  health_check {
    interval = 10
    matcher = "200-299"
    path = locals.health_check_path
    port = local.tg_port
    protocol = "HTTP"
    timeout = 2
    unhealthy_threshold = 2
  }
}

resource "aws_launch_template" "main" {
  name_prefix = "${local.common_name_suffix}-${var.component}"
  image_id      = aws_ami_from_instance.main.id # Replace with your desired AMI ID
  instance_type = "t3.micro"
  instance_initiated_shutdown_behavior = "terminate"
  vpc_security_group_ids = [local.sg_id]
  # when we run terraform apply again a new version will be created with new AMI ID
  update_default_version = true
  # tags attached to the instance
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-${var.component}" #roboshop-dev-catalogue
      }
    ) 
  }
  # tags attached to the volumes created
  tag_specifications {
    resource_type = "volume"
    tags = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-${var.component}" #roboshop-dev-catalogue
      }
    )
  }

  # tags attached to the launch template
  tags = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-${var.component}" #roboshop-dev-catalogue
      }
  )
}

resource "aws_autoscaling_group" "main" {
  name                      = "${local.common_name_suffix}-${var.component}"
  max_size                  = 10
  min_size                  = 1
  health_check_grace_period = 100
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = false
  vpc_zone_identifier       = local.subnet_ids
  target_group_arns = [ aws_lb_target_group.main.arn ]
  #First it will create one new instance with new launch template vesion
  #Once the new one is up, it will delete the old one. No downtime, but
  #But at some point two applications of same versions are running.
  #It is better to announce downtime and run terraform apply.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50 #atleast 50% instances should be up and running
      instance_warmup = 300
    }
    triggers = ["launch_template"] # Trigger refresh when launch template changes
  }
  launch_template {
    id = aws_launch_template.main.id
    version = aws_launch_template.main.latest_version
  }

  dynamic "tag" {
    for_each = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-${var.component}"
      }
    )
    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
      
    }
  }
  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_policy" "main" {
  name                   = "${local.common_name_suffix}-${var.component}"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 75.0 # Target 60% CPU utilization
    }
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = local.alb_listener_arn
  priority     = var.rule_priority

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    host_header {
      values = [local.host_context]
    }
  }
}

resource "terraform_data" "main_local" {
  triggers_replace = [
    aws_instance.main.id
  ]
depends_on = [ aws_autoscaling_group.main ]
provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${aws_instance.main.id}"
  }
}