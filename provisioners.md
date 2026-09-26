# Terraform Provisioners

## What are Provisioners?

Terraform **provisioners** are used to execute scripts or commands during resource creation or destruction.

The two commonly used provisioners are:

* `local-exec`
* `remote-exec`

---

# 1. `local-exec`

`local-exec` is used to execute a command **on the machine where Terraform is running**.

Example:

```hcl
provisioner "local-exec" {
  command = "echo '${self.private_ip}' > inv"
}
```

If Terraform is running on your laptop, the command runs on your **laptop**.

If Terraform is running on an EC2 instance, the command runs on that **EC2 instance**.

### Common use cases

* Create an inventory file
* Run a local script
* Call a local command
* Perform a local configuration task

---

# 2. `remote-exec`

`remote-exec` is used to execute commands or scripts **inside the target server**.

Example:

```hcl
provisioner "remote-exec" {
  inline = [
    "sudo yum update -y",
    "sudo yum install -y nginx"
  ]
}
```

Unlike `local-exec`, Terraform needs to know **how to connect to the target server**.

Therefore, a `connection` block is normally required.

---

# 3. Connection Block

Example:

```hcl
resource "aws_instance" "myinstance" {
  ami           = var.ami_id
  instance_type = "t3.micro"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("my-key.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y nginx"
    ]
  }
}
```

The flow is:

```text
Terraform
    |
    | SSH
    ↓
Target EC2
    |
    └── Execute commands
```

---

# 4. `on_failure`

`on_failure` controls what Terraform should do if the provisioner fails.

Example:

```hcl
provisioner "local-exec" {
  command    = "some-command"
  on_failure = continue
}
```

### Default behavior

```hcl
on_failure = fail
```

If the provisioner fails, Terraform considers the provisioning operation failed.

### Continue on failure

```hcl
on_failure = continue
```

Terraform continues even if the provisioner command fails.

---

# 5. Run Provisioner During Destroy

By default, a provisioner runs during **resource creation**.

To run a provisioner when the resource is being destroyed, use:

```hcl
when = destroy
```

Example:

```hcl
provisioner "local-exec" {
  when    = destroy
  command = "echo 'Instance is being destroyed'"
}
```

The flow becomes:

```text
terraform apply
       ↓
Resource created
       ↓
Provisioner runs


terraform destroy
       ↓
Resource being destroyed
       ↓
Destroy provisioner runs
```

---

# 6. Complete Example

```hcl
resource "aws_instance" "myinstance" {
  ami           = var.ami_id
  instance_type = "t3.micro"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("my-key.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y nginx"
    ]
  }

  provisioner "local-exec" {
    command = "echo '${self.private_ip}' > inventory"
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "echo 'Instance destroyed'"
    on_failure = continue
  }
}
```

---

# Quick Reference

| Provisioner   | Runs where?               | Connection required? |
| ------------- | ------------------------- | -------------------- |
| `local-exec`  | Machine running Terraform | No                   |
| `remote-exec` | Target server             | Yes                  |

### Important arguments

```hcl
provisioner "local-exec" {
  command = "..."
}
```

```hcl
provisioner "remote-exec" {
  inline = [
    "command1",
    "command2"
  ]
}
```

```hcl
on_failure = continue
```

```hcl
when = destroy
```

### Easy way to remember

```text
local-exec
    ↓
Run locally


remote-exec
    ↓
Connect to server
    ↓
Run inside server


when = destroy
    ↓
Run provisioner during destroy
```

> **Note:** Provisioners are generally considered a last resort in Terraform. Prefer using native Terraform resources, cloud-init/user-data, or configuration-management tools when they can accomplish the same task.
