# Public IPs for Web Tier VMs
resource "azurerm_public_ip" "web" {
  count = var.web_vm_count

  name                = "${var.project_name}-web-${count.index + 1}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-web-${count.index + 1}-pip"
    Tier = "Web"
  })
}

# Network Interfaces for Web Tier
resource "azurerm_network_interface" "web" {
  count = var.web_vm_count

  name                = "${var.project_name}-web-${count.index + 1}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.public_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web[count.index].id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-web-${count.index + 1}-nic"
    Tier = "Web"
  })
}

# Network Interfaces for App Tier
resource "azurerm_network_interface" "app" {
  count = var.app_vm_count

  name                = "${var.project_name}-app-${count.index + 1}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.private_subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-${count.index + 1}-nic"
    Tier = "App"
  })
}

# Web Tier Virtual Machines
resource "azurerm_linux_virtual_machine" "web" {
  count = var.web_vm_count

  name                = "${var.project_name}-web-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.web_vm_size
  admin_username      = var.admin_username

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.web[count.index].id,
  ]

  admin_password = var.admin_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/user_data/web_user_data.sh", {
    instance_id = count.index + 1
  }))

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-web-${count.index + 1}"
    Tier = "Web"
    Type = "WebServer"
  })
}

# App Tier Virtual Machines
resource "azurerm_linux_virtual_machine" "app" {
  count = var.app_vm_count

  name                = "${var.project_name}-app-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.app_vm_size
  admin_username      = var.admin_username

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.app[count.index].id,
  ]

  admin_password = var.admin_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/user_data/app_user_data.sh", {
    instance_id = count.index + 1
    db_endpoint = var.database_fqdn
  }))

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-${count.index + 1}"
    Tier = "App"
    Type = "AppServer"
  })
}
