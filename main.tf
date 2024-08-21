#Simple test environemnt

resource "azurerm_resource_group" "rg_norway_east" {
  name     = "rg-dev-env-01"
  location = "Norway East"
}

resource "azurerm_resource_group" "rg_west_europe" {
  name     = "rg-dev-env-02"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet_norway_east" {
  name                = "vnet-dev-env-01"
  location            = azurerm_resource_group.rg_norway_east.location
  resource_group_name = azurerm_resource_group.rg_norway_east.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_virtual_network" "vnet_west_europe" {
  name                = "vnet-dev-env-02"
  location            = azurerm_resource_group.rg_west_europe.location
  resource_group_name = azurerm_resource_group.rg_west_europe.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "subnet_norway_east" {
  name                 = "subnet-dev-env-01"
  resource_group_name  = azurerm_resource_group.rg_norway_east.name
  virtual_network_name = azurerm_virtual_network.vnet_norway_east.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet_west_europe" {
  name                 = "subnet-dev-env-02"
  resource_group_name  = azurerm_resource_group.rg_west_europe.name
  virtual_network_name = azurerm_virtual_network.vnet_west_europe.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_network_interface" "nic_norway_east" {
  name                = "nic-dev-env-01"
  location            = azurerm_resource_group.rg_norway_east.location
  resource_group_name = azurerm_resource_group.rg_norway_east.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_norway_east.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "nic_west_europe" {
  name                = "nic-dev-env-02"
  location            = azurerm_resource_group.rg_west_europe.location
  resource_group_name = azurerm_resource_group.rg_west_europe.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_west_europe.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm_norway_east" {
  name                = "vm-dev-env-01"
  location            = azurerm_resource_group.rg_norway_east.location
  resource_group_name = azurerm_resource_group.rg_norway_east.name
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.nic_norway_east.id,
  ]

  tags = {
    dev_auto_start_shutdow = true
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("id_rsa.pub.pub")
  }
}

resource "azurerm_linux_virtual_machine" "vm_west_europe" {
  name                = "vm-dev-env-02"
  location            = azurerm_resource_group.rg_west_europe.location
  resource_group_name = azurerm_resource_group.rg_west_europe.name
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.nic_west_europe.id,
  ]

  tags = {
    dev_auto_start_shutdow = true
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("./id_rsa.pub.pub")
  }
}

#Test VM that should not be affceted by script (by naming convention)
resource "azurerm_resource_group" "rg_west_europe_test_env" {
  name     = "rg-test-env-02"
  location = "West Europe"
}

resource "azurerm_network_interface" "nic_west_europe_test_env" {
  name                = "nic-test-env-01"
  location            = azurerm_resource_group.rg_west_europe_test_env.location
  resource_group_name = azurerm_resource_group.rg_west_europe_test_env.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_west_europe.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm_norway_east_test_env" {
  name                = "vm-test-env-01"
  location            = azurerm_resource_group.rg_west_europe_test_env.location
  resource_group_name = azurerm_resource_group.rg_west_europe_test_env.name
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.nic_west_europe_test_env.id,
  ]

  tags = {
    dev_auto_start_shutdow = true
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("id_rsa.pub.pub")
  }
}
