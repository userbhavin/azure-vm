provider "azurerm" {
  version = "~>2.0"
  #version        = "= 2.4"
  subscription_id        = "${var.subscription_id}"
  client_id              = "${var.client_id}"
  client_secret          = "${var.client_secret}"
  tenant_id              = "${var.tenant_id}"
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name = "${azurerm_resource_group.main.name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = "10.0.2.0/24"
}


resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-sg"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "main" {
  name                      = "${var.prefix}-nic"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.main.id}"
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
    network_interface_id      = "${azurerm_network_interface.main.id}"
    network_security_group_id = "${azurerm_network_security_group.main.id}"
}

resource "azurerm_public_ip" "main" {
  name                         = "${var.prefix}-ip"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.main.name}"
  allocation_method            = "Dynamic"
  domain_name_label            = "${var.hostname}"
}
resource "tls_private_key" "example_ssh" {
    algorithm = "RSA"
    rsa_bits  = 4096 
} 

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.main.id}"]
  vm_size               = "Standard_B2ms"
  #delete_os_disk_on_termination = true
  #delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  
  os_profile {
    computer_name  = "${var.hostname}"
    admin_username = "${var.ssh_user}"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys  {
      path           = "/home/${var.ssh_user}/.ssh/authorized_keys"
      key_data       = tls_private_key.example_ssh.public_key_openssh
    }
  }
  provisioner "remote-exec" {
    connection {
       type        = "ssh"
       host        = "${azurerm_public_ip.main.fqdn}"
       user        = "${var.ssh_user}"
       private_key = "${tls_private_key.example_ssh.private_key_pem}"
    }
    inline = [
        "sudo apt-get update -y",
        "sudo apt-get install -y docker.io",
        "sudo systemctl start docker",
        "sudo systemctl enable docker",
        "sudo docker version",
        "sudo docker pull mariadb",
        "sudo mkdir ~/wordpress",
        "sudo mkdir -p ~/wordpress/database",
        "sudo mkdir -p ~/wordpress/html",
        "sudo docker run -e MYSQL_ROOT_PASSWORD=aqwe123 -e MYSQL_USER=wpuser -e MYSQL_PASSWORD=wpuser@ -e MYSQL_DATABASE=wordpress_db -v /root/wordpress/database:/var/lib/mysql --name wordpressdb -d mariadb",
        "sudo apt install -y mysql-client-core-5.7",
        "sudo docker pull wordpress:latest",
        "sudo docker run -e WORDPRESS_DB_USER=wpuser -e WORDPRESS_DB_PASSWORD=wpuser@ -e WORDPRESS_DB_NAME=wordpress_db -p 8081:80 -v /root/wordpress/html:/var/www/html --link wordpressdb:mysql --name wpcontainer -d wordpress",
        "sudo apt-get install -y nginx",
        "cd /etc/nginx/sites-available/",
        "sudo touch wordpress",
        "sudo chmod 777 wordpress"
    ]
    
  }
  provisioner "file" {
      source      = "wordpress"
      destination = "/etc/nginx/sites-available/wordpress"

    connection {
       type        = "ssh"
       host        = "${azurerm_public_ip.main.fqdn}"
       user        = "${var.ssh_user}"
       private_key = "${tls_private_key.example_ssh.private_key_pem}"
    }
  }
  provisioner "remote-exec" {
    connection {
       type        = "ssh"
       host        = "${azurerm_public_ip.main.fqdn}"
       user        = "${var.ssh_user}"
       private_key = "${tls_private_key.example_ssh.private_key_pem}"
    }
    inline = [
        "sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/",
        "sudo rm -f /etc/nginx/sites-available/default",
        "sudo rm -f /etc/nginx/sites-enabled/default",
        "sudo systemctl restart nginx",
    ]
    
  }

  tags = {
    environment = "staging"
  }
}
