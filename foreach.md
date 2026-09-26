# Terraform `for_each`

## 1. What is `for_each`?

`for_each` is a Terraform meta-argument used to create **multiple instances of a resource**.

It is commonly used with:

* **Maps**
* **Sets**

Basic syntax:

```hcl
for_each = var.instances
```

---

# 2. `for_each` with a Map

Example variable:

```hcl
variable "instances" {
  type = map(string)

  default = {
    mongo = "t3.micro"
    redis = "t3.small"
    mysql = "t3.medium"
  }
}
```

Use it in a resource:

```hcl
resource "aws_instance" "myinstance" {
  for_each = var.instances

  ami           = var.ami_id
  instance_type = each.value

  tags = {
    Name = each.key
  }
}
```

### `each.key` and `each.value`

For the map:

```text
mongo = t3.micro
redis = t3.small
mysql = t3.medium
```

Terraform provides:

```text
each.key       each.value
   ↓               ↓
 mongo          t3.micro
 redis          t3.small
 mysql          t3.medium
```

So:

```hcl
instance_type = each.value
```

gets the instance type.

And:

```hcl
Name = each.key
```

gets the instance name.

---

# 3. `for_each` with a Set

`for_each` can also work with a set of strings.

Example:

```hcl
variable "instances" {
  type = set(string)

  default = [
    "mongo",
    "redis",
    "mysql"
  ]
}
```

Then:

```hcl
resource "aws_instance" "myinstance" {
  for_each = var.instances

  ami           = var.ami_id
  instance_type = "t3.micro"

  tags = {
    Name = each.value
  }
}
```

With a set:

```text
mongo
redis
mysql
```

each item becomes the **value**:

```text
each.value = mongo
each.value = redis
each.value = mysql
```

There is no meaningful separate key like a map has.

You can use:

```hcl
Name = each.value
```

---

# 4. `toset()`

If you already have a list and want to use it with `for_each`, convert the list to a set:

```hcl
for_each = toset(var.instances)
```

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

Then:

```hcl
resource "aws_instance" "myinstance" {
  for_each = toset(var.instances)

  ami           = var.ami_id
  instance_type = "t3.micro"

  tags = {
    Name = each.value
  }
}
```

`toset()` converts:

```text
["mongo", "redis", "mysql"]
```

into a set:

```text
{"mongo", "redis", "mysql"}
```

Each item becomes the value.

---

# 5. `each.key` vs `each.value`

### With a Map

```hcl
for_each = var.instances
```

You get:

```text
each.key
each.value
```

Example:

```text
mongo → t3.micro
  ↑        ↑
 key     value
```

### With a Set

```hcl
for_each = toset(var.instances)
```

Each item becomes the value:

```text
mongo → each.value
redis → each.value
mysql → each.value
```

For a set of strings, `each.key` and `each.value` represent the same string value, but `each.value` is the clearer choice.

---

# 6. Important Difference: `count` vs `for_each`

| `count`                         | `for_each`                        |
| ------------------------------- | --------------------------------- |
| Commonly used with lists/counts | Commonly used with maps/sets      |
| Uses `count.index`              | Uses `each.key` / `each.value`    |
| Index-based                     | Key/value-based                   |
| `resource[0]`                   | `resource["mongo"]`               |
| Good for identical resources    | Good for uniquely named resources |

### `count`

```hcl
count = length(var.instances)

Name = var.instances[count.index]
```

### `for_each`

```hcl
for_each = toset(var.instances)

Name = each.value
```

**Easy way to remember:**

```text
count
  ↓
index
  ↓
count.index


for_each
  ↓
key / value
  ↓
each.key / each.value
```
