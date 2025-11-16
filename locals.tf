locals {
    common_name_suffix = "${var.project_name}-${var.environment}" #roboshop-dev
    private_subnet_id = split(",",data.aws_ssm_parameter.private_subnet_id.value)[0]
    private_subnet_ids = split(",",data.aws_ssm_parameter.private_subnet_id.value)
    public_subnet_id = split(",",data.aws_ssm_parameter.public_subnet_id.value)[0]
    public_subnet_ids = split(",",data.aws_ssm_parameter.public_subnet_id.value)
    subnet_ids = "${var.component}" == "frontend" ? public_subnet_ids : private_subnet_ids

    backend_alb_listener_arn = data.aws_ssm_parameter.backend_alb_listener_arn
    frontend_alb_listener_arn = data.aws_ssm_parameter.frontend_alb_listener_arn
    alb_listener_arn = "${var.component}" == "frontend" ? frontend_alb_listener_arn : backend_alb_listener_arn
    
    host_context = "${var.component}" == "frontend" ? "${var.project_name}-${var.environment}.${var.domain_name}" : "${var.component}-backend-alb-${var.environment}.${var.domain_name}"
    tg_port = "${var.component}" == "frontend" ? 80 : 8080
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    sg_id = data.aws_ssm_parameter.sg_id.value
    ami_id = data.aws_ami.ami.id
    health_check_path = "${var.component}" == "frontend" ? "/" : "/health"
    common_tags = {
        Project = var.project_name
        Environment = var.environment
        Terraform = true
    }
}
