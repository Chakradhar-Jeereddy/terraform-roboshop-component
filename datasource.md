# Understanding Terraform Data Sources

**What is a Data Source?**

A data source is a read-only block that **queries and retrieves existing infrastructure information** from your cloud provider (AWS, Azure, GCP, etc.). It doesn't create anything—it just fetches data.

Think of it like a **search query** instead of a **create command**.

---

## When to Use Data Sources

Use data sources when you need to:

1. **Reference existing resources** you didn't create with Terraform
2. **Dynamically fetch values** that change over time (like AMI IDs)
3. **Query provider information** without hardcoding values
4. **Filter and find resources** based on specific criteria

---

## Your Example Explained

```terraform
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]  # Matches "al2023-ami-2024.1.2", etc.
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
```

**What it does:**
- Searches AWS for all Amazon Linux 2023 AMIs
- Filters to official Amazon images only
- Selects the **most recent** one
- Returns the AMI ID

**Then you use it:**
```terraform
resource "aws_instance" "web" {
  ami = data.aws_ami.amazon_linux_2.id  # Reference the fetched AMI
  # ...
}
```

---

## Data Source vs Resource

| Aspect | Resource | Data Source |
|--------|----------|-------------|
| **Creates** | ✅ Yes (new infrastructure) | ❌ No (read-only) |
| **Modifies** | ✅ Yes | ❌ No |
| **Deletes** | ✅ Yes | ❌ No |
| **Queries** | ❌ No | ✅ Yes |
| **Example** | `resource "aws_instance"` | `data "aws_ami"` |

---

## Common Use Cases

**1. Get latest AMI (your case)**
```terraform
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter { name = "name"; values = ["al2023-ami-*"] }
}
```

**2. Reference existing VPC**
```terraform
data "aws_vpc" "default" {
  default = true  # Use the default VPC without creating one
}
```

**3. Get availability zones**
```terraform
data "aws_availability_zones" "available" {
  state = "available"
}
```

**4. Lookup security group**
```terraform
data "aws_security_group" "existing" {
  name = "my-existing-sg"  # Reference existing security group
}
```

---

## Why This is Better Than Hardcoding

**❌ Bad (hardcoded):**
```terraform
ami = "ami-0c55b159cbfafe1f0"  # If AWS updates, this breaks!
```

**✅ Good (using data source):**
```terraform
ami = data.aws_ami.amazon_linux_2.id  # Always gets latest
```

Your Terraform code stays current automatically! 🎯
