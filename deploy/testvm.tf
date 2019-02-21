resource "azurerm_virtual_network" "network" {
  count               = "${terraform.workspace == "prod" ? 0 : 1}"
  name                = "dockerhost-vnet"
  address_space       = ["10.1.0.0/24"]
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
}

resource "azurerm_subnet" "default" {
  count                = "${terraform.workspace == "prod" ? 0 : 1}"
  name                 = "default"
  resource_group_name  = "${azurerm_resource_group.group.name}"
  virtual_network_name = "${azurerm_virtual_network.network.name}"
  address_prefix       = "10.1.0.0/24"
}

resource "azurerm_public_ip" "ip" {
  count                        = "${terraform.workspace == "prod" ? 0 : 1}"
  name                         = "dockerhost-ip"
  location                     = "${azurerm_resource_group.group.location}"
  resource_group_name          = "${azurerm_resource_group.group.name}"
  allocation_method            = "Dynamic"
  idle_timeout_in_minutes      = 30
  domain_name_label            = "espresso"
}

resource "azurerm_network_interface" "nic" {
  count               = "${terraform.workspace == "prod" ? 0 : 1}"
  name                = "dockerhost-nic"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.default.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.ip.id}"
  }
}

data "template_file" "cloud_init" {
  template = "${file("${path.module}/cloud-config.txt")}"
}

data "template_cloudinit_config" "config" {
  part {
    content_type = "text/x-include-url"
    content      = "https://get.docker.com"
  }

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud_init.rendered}"
  }
}

resource "azurerm_virtual_machine" "dockerhost" {
  count                 = "${terraform.workspace == "prod" ? 0 : 1}"
  name                  = "dockerhost-vm"
  location              = "${azurerm_resource_group.group.location}"
  resource_group_name   = "${azurerm_resource_group.group.name}"
  network_interface_ids = ["${azurerm_network_interface.nic.id}"]
  vm_size               = "Standard_DS1_v2"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "dockerhostosdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "dockerhost"
    admin_username = "dockeradmin"
    custom_data = "${data.template_cloudinit_config.config.rendered}"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/dockeradmin/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9QKIJL4OygWMvTzvsi9zC03R/t5riw4SfLg3+EqfM79Bex0ChBdqx6i2ddhkmkfGwFXm/Si2cEM2WVcjNWCgbTgKaJDGVANnCz4zlxqsUAEE2izzMLD+vLqSz7OAn/xAiMv0w0mNevmleFLPwgRyXCq7TRzl+b83/DJD6R4YIHeqsnCRkqCmh+FGJL9SF0u+gIdl8/a4L0XLTz2nvWVrFWPfP4bn5f6GCKpKuaHwa9dxyGlQRo1xYviE5nRZjxVfY4cBvahkBJFxc26iRVDgdyqk/iTPVosN2qNDQ3/Yt2106UqRmLi9ssW6hiFr2Ejoq3JJd6Tq8V2QRVU45OQEV sschoof@sdhamw057"
    }
  }
}

resource "azurerm_virtual_machine_extension" "cloudinitwait" {
  count = "${terraform.workspace == "prod" ? 0 : 1}"
  name = "cloudinitwait"
  location = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  virtual_machine_name = "${azurerm_virtual_machine.dockerhost.name}"
  publisher = "Microsoft.Azure.Extensions"
  type = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "cloud-init status --wait"
    }
SETTINGS
}

output "public_fqdn_address" {
  value = "${azurerm_public_ip.ip.*.fqdn}"
}
