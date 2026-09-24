# Terraform Syntax & Basics

## 1. Basic Terraform Syntax

Terraform configuration files use **HCL (HashiCorp Configuration Language)**.

Basic key-value syntax:

```hcl
key = "value"
```

Example resource:

```hcl
resource "aws_instance" "myinstance" {
  ami           = "ami-xxxxxxxx"
  instance_type = "t3.micro"
}
```

### Resource Syntax

```hcl
resource "resource_type" "local_name" {
  argument = value
}
```

For example:

```hcl
resource "aws_instance" "myinstance" {
  ami           = var.ami_id
  instance_type = var.instance_type
}
```

Here:

* `aws_instance` → resource type
* `myinstance` → local resource name
* `ami` → argument
* `var.ami_id` → value coming from a variable

---

## 2. Terraform Map

A map is a collection of key-value pairs.

```hcl
tags = {
  Name = "terraform"
}
```

Example with multiple values:

```hcl
tags = {
  Name        = "terraform"
  Environment = "dev"
  Project     = "roboshop"
}
```

---

## 3. Basic Terraform Workflow

The common Terraform workflow is:

```text
terraform init
        ↓
terraform validate
        ↓
terraform plan
        ↓
terraform apply
```

### Step 1: Initialize

```bash
terraform init
```

Initializes the Terraform working directory and downloads required providers and modules.

### Step 2: Validate

```bash
terraform validate
```

Checks whether the Terraform configuration is syntactically valid and internally consistent.

It **does not** verify whether AWS APIs will successfully create the resources.

### Step 3: Plan

```bash
terraform plan
```

Shows what Terraform intends to create, modify, or destroy.

### Step 4: Apply

```bash
terraform apply
```

Actually creates or modifies the infrastructure.

---

# 4. Terraform Resources

Terraform resources represent infrastructure objects.

Example:

```hcl
resource "aws_instance" "myinstance" {
  ami           = var.ami_id
  instance_type = var.instance_type
}
```

Terraform can create resources such as:

* EC2 instances
* Security Groups
* Route53 records
* S3 buckets
* VPCs
* Load Balancers
* RDS databases

---

# 5. Resource Attributes

Resources expose attributes that can be referenced by other resources.

General syntax:

```text
resource_type.local_name.attribute
```

Example:

```hcl
aws_instance.myinstance.private_ip
```

Another resource can use this attribute:

```hcl
resource "aws_route53_record" "record" {
  records = [aws_instance.myinstance.private_ip]
}
```

This creates a dependency between the Route53 record and the EC2 instance.

---

# 6. Variables

Variables allow us to make Terraform configurations reusable.

Common variable types:

```text
string
number
boolean
list
set
map
```

Example:

```hcl
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
```

Use the variable:

```hcl
resource "aws_instance" "myinstance" {
  instance_type = var.instance_type
}
```

---

# 7. Ways to Provide Variable Values

Terraform variables can be supplied in several ways.

## Command Line

```bash
terraform plan -var="instance_type=t3.small"
```

---

## Environment Variable

Terraform environment variables use the `TF_VAR_` prefix:

```bash
export TF_VAR_instance_type="t3.small"
```

Then:

```bash
terraform plan
```

---

## terraform.tfvars

Create:

```text
terraform.tfvars
```

Example:

```hcl
instance_type = "t3.small"
```

Terraform automatically loads values from `terraform.tfvars`.

---

## variables.tf

Variables are commonly defined in:

```text
variables.tf
```

Example:

```hcl
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
```

A common Terraform directory structure:

```text
.
├── main.tf
├── variables.tf
├── terraform.tfvars
├── outputs.tf
└── providers.tf
```

---

# 8. Conditional Expressions

Terraform supports the following conditional syntax:

```text
condition ? true_value : false_value
```

Example:

```hcl
instance_type = var.env == "dev" ? "t3.small" : "t3.medium"
```

Meaning:

```text
If environment = dev
        ↓
    t3.small

Otherwise
        ↓
    t3.medium
```

The values should be strings when specifying instance types:

```hcl
"t3.small"
"t3.medium"
```

---

# 9. Loops with count

Terraform supports creating multiple instances using `count`.

Example:

```hcl
resource "aws_instance" "myinstance" {
  count = 3

  ami           = var.ami_id
  instance_type = var.instance_type
}
```

Terraform creates:

```text
aws_instance.myinstance[0]
aws_instance.myinstance[1]
aws_instance.myinstance[2]
```

## count.index

When `count` is used, Terraform exposes:

```hcl
count.index
```

The index starts from **0**.

For:

```hcl
count = 3
```

the indexes are:

```text
0
1
2
```

Example:

```hcl
resource "aws_instance" "myinstance" {
  count = 3

  ami = var.ami_id

  tags = {
    Name = var.instances[count.index]
  }
}
```

---

# 10. List Variables with count

Example:

```hcl
variable "instances" {
  type = list(string)

  default = [
    "mongo",
    "redis",
    "mysql"
  ]
}
```

Use it with `count`:

```hcl
resource "aws_instance" "myinstance" {
  count = length(var.instances)

  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = var.instances[count.index]
  }
}
```

Terraform creates:

```text
Instance 0 → mongo
Instance 1 → redis
Instance 2 → mysql
```

Using:

```hcl
count = length(var.instances)
```

is better than hardcoding:

```hcl
count = 3
```

because the number of resources automatically follows the number of items in the list.

---

# 11. Outputs

Outputs allow you to display or expose information after Terraform creates resources.

Example:

```hcl
output "instance_id" {
  value = aws_instance.myinstance.id
}
```

For a resource using `count`, you can output all instance IDs:

```hcl
output "instance_ids" {
  value = aws_instance.myinstance[*].id
}
```

You can also output a specific instance:

```hcl
output "first_instance_id" {
  value = aws_instance.myinstance[0].id
}
```

After `terraform apply`, Terraform displays the output.

You can also retrieve it with:

```bash
terraform output
```

Or:

```bash
terraform output instance_ids
```

---

# 12. Important Terraform Concepts

```text
HCL
 │
 ├── Resources
 │     └── Create infrastructure
 │
 ├── Variables
 │     └── Make configuration reusable
 │
 ├── Attributes
 │     └── Information exposed by resources
 │
 ├── Conditions
 │     └── Choose values dynamically
 │
 ├── count
 │     └── Create multiple resources
 │
 └── Outputs
       └── Display/expose resource information
```

## Quick Reference

| Concept     | Example                                       |
| ----------- | --------------------------------------------- |
| Resource    | `resource "aws_instance" "web" {}`            |
| Variable    | `var.instance_type`                           |
| Attribute   | `aws_instance.web.private_ip`                 |
| Map         | `{ Name = "terraform" }`                      |
| List        | `["mongo", "redis", "mysql"]`                 |
| Condition   | `var.env == "dev" ? "t3.small" : "t3.medium"` |
| Count       | `count = 3`                                   |
| Count index | `count.index`                                 |
| Output      | `output "ip" { value = ... }`                 |
| Initialize  | `terraform init`                              |
| Validate    | `terraform validate`                          |
| Plan        | `terraform plan`                              |
| Apply       | `terraform apply`                             |
