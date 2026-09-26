# Terraform Conditions and Count

## 1. Conditions in Terraform

Terraform supports **conditional expressions** using the following syntax:

```hcl
condition ? true_value : false_value
```

### Example

```hcl
instance_type = var.env == "dev" ? "t2.micro" : "t3.micro"
```

Meaning:

```text
If env = dev
    ↓
t2.micro

Otherwise
    ↓
t3.micro
```

### Complete Example

```hcl
variable "env" {
  type    = string
  default = "dev"
}

resource "aws_instance" "myinstance" {
  ami           = var.ami_id
  instance_type = var.env == "dev" ? "t2.micro" : "t3.micro"
}
```

> **Note:** String values such as `t2.micro` and `t3.micro` must be enclosed in quotes.

---

# 2. `count` in Terraform

The `count` meta-argument is used to **create multiple instances of a resource**.

Example:

```hcl
resource "aws_instance" "myinstance" {
  count = 3

  ami           = var.ami_id
  instance_type = "t3.micro"
}
```

Terraform creates:

```text
aws_instance.myinstance[0]
aws_instance.myinstance[1]
aws_instance.myinstance[2]
```

The `count.index` value starts from **0**.

```text
count.index = 0
count.index = 1
count.index = 2
```

---

# 3. Using `count` with a List

A common use of `count` is to create resources based on the number of items in a list.

### Variable

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

### Resource

```hcl
resource "aws_instance" "myinstance" {
  count = length(var.instances)

  ami           = var.ami_id
  instance_type = "t3.micro"

  tags = {
    Name = var.instances[count.index]
  }
}
```

### How it works

Terraform calculates:

```hcl
length(var.instances)
```

The list contains 3 items:

```text
mongo
redis
mysql
```

Therefore:

```text
count = 3
```

Terraform creates:

```text
Instance 0 → mongo
Instance 1 → redis
Instance 2 → mysql
```

The `count.index` connects each resource to the corresponding list item:

```text
var.instances[0] → mongo
var.instances[1] → redis
var.instances[2] → mysql
```

So:

```hcl
Name = var.instances[count.index]
```

produces:

```text
Instance 0 → Name = mongo
Instance 1 → Name = redis
Instance 2 → Name = mysql
```

---

## Quick Reference

```text
Condition:

condition ? true_value : false_value


Count:

count = 3


Count index:

count.index


List:

var.instances


Number of list items:

length(var.instances)


List item using count:

var.instances[count.index]
```

### Easy way to remember

```text
List
 ↓
length()
 ↓
count
 ↓
count.index
 ↓
list[index]
```

Example:

```hcl
count = length(var.instances)

Name = var.instances[count.index]
```

This lets Terraform automatically create **one resource for each item in the list**.
