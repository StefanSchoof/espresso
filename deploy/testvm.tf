resource "azurerm_virtual_network" "network" {
  count               = var.with_testvm ? 1 : 0
  name                = "dockerhost-vnet"
  address_space       = ["10.1.0.0/24"]
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
}

resource "azurerm_subnet" "default" {
  count                = var.with_testvm ? 1 : 0
  name                 = "default"
  resource_group_name  = azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.network[0].name
  address_prefix       = "10.1.0.0/24"
}

resource "azurerm_public_ip" "ip" {
  count                   = var.with_testvm ? 1 : 0
  name                    = "dockerhost-ip"
  location                = azurerm_resource_group.group.location
  resource_group_name     = azurerm_resource_group.group.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
  domain_name_label       = "espresso"
}

resource "azurerm_network_interface" "nic" {
  count               = var.with_testvm ? 1 : 0
  name                = "dockerhost-nic"
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.default[0].id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.ip[0].id
  }
}

data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-config.txt")
}

data "template_cloudinit_config" "config" {
  part {
    content_type = "text/x-include-url"
    content      = "https://get.docker.com"
  }

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.cloud_init.rendered
  }
}

resource "azurerm_linux_virtual_machine" "dockerhost" {
  count                 = var.with_testvm ? 1 : 0
  name                  = "dockerhost-vm"
  location              = azurerm_resource_group.group.location
  resource_group_name   = azurerm_resource_group.group.name
  network_interface_ids = [azurerm_network_interface.nic[0].id]
  size                  = "Standard_DS1_v2"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  admin_username = "dockeradmin"
  custom_data    = data.template_cloudinit_config.config.rendered
  admin_ssh_key {
    username   = "dockeradmin"
    public_key = var.public_key
  }
}

resource "azurerm_virtual_machine_extension" "cloudinitwait" {
  count                = var.with_testvm ? 1 : 0
  name                 = "cloudinitwait"
  virtual_machine_id   = azurerm_linux_virtual_machine.dockerhost[0].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "cloud-init status --wait"
    }
SETTINGS

}

output "public_fqdn_address" {
  value = azurerm_public_ip.ip.*.fqdn
}

