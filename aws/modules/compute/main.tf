# Web Tier Instances
resource "aws_instance" "web" {
  count = var.web_instance_count

  ami                    = var.ami_id
  instance_type          = var.web_instance_type
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null
  vpc_security_group_ids = [var.web_security_group_id]
  subnet_id              = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]

  # Plain text: the provider base64-encodes user_data itself
  user_data = templatefile("${path.module}/user_data/web_user_data.sh", {
    instance_id = count.index + 1
  })

  # user_data only runs on first boot, so replace the instance when the script changes
  user_data_replace_on_change = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-web-${count.index + 1}"
    Tier = "Web"
    Type = "WebServer"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# App Tier Instances
resource "aws_instance" "app" {
  count = var.app_instance_count

  ami                    = var.ami_id
  instance_type          = var.app_instance_type
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null
  vpc_security_group_ids = [var.app_security_group_id]
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]

  # Plain text: the provider base64-encodes user_data itself
  user_data = templatefile("${path.module}/user_data/app_user_data.sh", {
    instance_id = count.index + 1
    db_endpoint = var.database_endpoint
  })

  # user_data only runs on first boot, so replace the instance when the script changes
  user_data_replace_on_change = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-${count.index + 1}"
    Tier = "App"
    Type = "AppServer"
  })

  lifecycle {
    create_before_destroy = true
  }
}
