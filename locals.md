# Terraform Locals

## What are Locals?

Terraform **locals** are values defined internally within a Terraform configuration.

They are useful when you want to define a value once and reuse it in multiple places.

### Important Points

* Locals **cannot be overridden** from the command line using `-var`.
* Locals **cannot be changed** using `terraform.tfvars`.
* Locals **cannot be set** using `TF_VAR_*` environment variables.
* If you need a value to be configurable from outside Terraform, use a **variable**.
* Locals can combine or concatenate variables.
* Locals can use Terraform functions.
* Locals are useful for defining **internal rules or reusable values** within your Terraform configuration.

---

## Variable vs Local

### Variable

A variable can receive input from outside the Terraform configuration.

For example:

```bash
terraform plan -var="instance_type=t3.small"
```

Or through:

```text
terraform.tfvars
```

Or:

```bash
export TF_VAR_instance_type="t3.small"
```

### Local

A local is defined inside Terraform and cannot be overridden through those input mechanisms.

```hcl
locals {
  instance_type = "t3.micro"
}
```

---

## Local Syntax

```hcl
locals {
  instance_type = "t3.micro"
}
```

> String values must be enclosed in quotes.

---

## Using Locals

A local value is referenced using:

```hcl
local.instance_type
```

Example:

```hcl
locals {
  instance_type = "t3.micro"
}

resource "aws_instance" "myinstance" {
  ami           = var.ami_id
  instance_type = local.instance_type
}
```

---

## Locals with Variables

Locals can combine variables and create values based on input.

```hcl
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

locals {
  name = "${var.project}-${var.environment}"
}
```

If:

```text
project     = roboshop
environment = dev
```

Then:

```text
local.name = roboshop-dev
```

---

## Locals with Functions

Locals can also use Terraform functions.

```hcl
locals {
  name = lower("${var.project}-${var.environment}")
}
```

This allows you to create reusable internal values using variables, expressions, and Terraform functions.

---

## Simple Rule to Remember

```text
Variable
   ↓
Can be modified from outside Terraform
   ↓
-var / .tfvars / TF_VAR_

Local
   ↓
Internal Terraform value
   ↓
Cannot be overridden from outside
```

**Think of it this way:**

> **Variables = external inputs**
> **Locals = internal Terraform logic**
