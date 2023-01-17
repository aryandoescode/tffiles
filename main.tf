terraform {
  required_providers {
    azurerm = {
      version = "3.37.0"
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {

  }
  subscription_id = "cdc3c0fa-a22b-420a-ac28-6c56ec56eb7a"
  tenant_id       = "2848720d-5e3d-440c-8ed8-444178758db2"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg"
  location = "Central India"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/azurekey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "nsgrule" {
  name                        = "nsgrule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "conn" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "ip" {
  name                = "ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "static"
}

resource "azurerm_monitor_action_group" "ag" {
  name                = "myactiongroup"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "ag"

}

resource "azurerm_monitor_metric_alert" "alert" {
  name                 = "alert"
  resource_group_name  = azurerm_resource_group.rg.name
  scopes               = ["/subscriptions/cdc3c0fa-a22b-420a-ac28-6c56ec56eb7a/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/vm"]
  description          = "description"
  target_resource_type = "Microsoft.Compute/virtualMachines"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5

  }
  criteria {

    metric_namespace = "Microsoft.Storage/storageAccounts"

    metric_name = "Transactions"

    aggregation = "Total"

    operator = "GreaterThan"

    threshold = 10
  }
  criteria {
    metric_namesoace = "Microsoft"
  }
  action {
    action_group_id = azurerm_monitor_action_group.ag.id
  }
}