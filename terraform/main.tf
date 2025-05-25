# 1. Configuracao do Provedor Azure
# Este bloco informa ao Terraform para usar o provedor Azure
# A versao eh importante para garantir compatibilidade com os recursos
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# 2. Configuracao do Provedor Azure (Autenticacao)
# Aqui, voce pode configurar as credenciais para autenticacao no Azure
# Recomenda--e usar autenticacao baseada em Service Principal ou Azure CLI
# Se estiver usando Azure CLI (az login), este bloco pode ser omitido
provider "azurerm" {
  features {} # Este bloco eh necessario para habilitar os recursos do provedor
  # client_id       = "PLACEHOLDER_AZURE_CLIENT_ID"
  # client_secret   = "PLACEHOLDER_AZURE_CLIENT_SECRET"
  # tenant_id       = "PLACEHOLDER_AZURE_TENANT_ID"
  # subscription_id = "PLACEHOLDER_AZURE_SUBSCRIPTION_ID"
}

# 3. Definicao de Variaveis
# Eh uma boa pratica usar variaveis para valores que podem mudar ou que precisam ser configurados
variable "resource_group_name" {
  description = "Nome do grupo de recursos."
  type        = string
  default     = "rg-terraform-demo"
}

variable "location" {
  description = "Localização dos recursos do Azure."
  type        = string
  default     = "East US"
}

variable "vm_admin_username" {
  description = "Nome de usuário administrador para as VMs."
  type        = string
  default     = "azureuser"
}

variable "vm_admin_password" {
  description = "Senha do administrador para as VMs. Use um método seguro para gerenciar senhas em produção (ex: Azure Key Vault)."
  type        = string
  sensitive   = true
  default     = "StrongPassword!123"
}

# 4. Grupo de Recursos
# Todos os recursos serao provisionados dentro deste grupo de recursos
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# 5. Rede Virtual (VNet)
# Uma rede virtual eh essencial para isolar e conectar seus recursos no Azure
resource "azurerm_virtual_network" "main" {
  name                = "vnet-terraform-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# 6. Sub-rede para Maquina Virtual (VM)
# Uma sub-rede dedicada para a VM.
resource "azurerm_subnet" "vm_subnet" {
  name                 = "subnet-vm"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 7. Sub-rede para Conjunto de Dimensionamento Automatico (VMSS)
# Uma sub-rede dedicada para o VMSS.
resource "azurerm_subnet" "vmss_subnet" {
  name                 = "subnet-vmss"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 8. Endereco IP Publico para a Maquina Virtual (Opcional, para acesso direto)
# Um IP publico eh necessario se voce precisa acessar a VM diretamente da internet
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "publicip-vm-demo"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
}

# 9. Interface de Rede (NIC) para a Maquina Virtual
# A NIC conecta a VM a sub-rede e, opcionalmente, ao IP publico
resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-vm-demo"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

# 10. Maquina Virtual (VM)
# Definicao de uma unica Maquina Virtual
resource "azurerm_linux_virtual_machine" "vm_demo" {
  name                            = "vm-terraform-demo"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_B1s"
  admin_username                  = var.vm_admin_username
  admin_password                  = var.vm_admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.vm_nic.id]

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

  tags = {
    environment = "development"
    project     = "terraform-demo"
  }
}

# 11. Load Balancer para o Conjunto de Dimensionamento Automatico (VMSS)
# Um Load Balancer é crucial para distribuir o trafego entre as instancias do VMSS.
resource "azurerm_public_ip" "lb_public_ip" {
  name                = "publicip-lb-vmss-demo"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "vmss_lb" {
  name                = "lb-vmss-demo"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontend"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

# 12. Backend Pool para o Load Balancer
# O backend pool define quais VMs receberao trafego do Load Balancer
resource "azurerm_lb_backend_address_pool" "vmss_lb_backend_pool" {
  loadbalancer_id = azurerm_lb.vmss_lb.id
  name            = "BackendPool"
}

# 13. Health Probe para o Load Balancer
# O health probe verifica a saude das instancias do VMSS
resource "azurerm_lb_probe" "vmss_lb_probe" {
  loadbalancer_id = azurerm_lb.vmss_lb.id
  name            = "HttpProbe"
  port            = 80
  protocol        = "Tcp" # Ou "Http" se voce tiver um endpoint HTTP
  interval_in_seconds = 5
  number_of_probes = 2
}

# 14. Regra de Balanceamento de Carga
# Define como o trafego de entrada eh distribuido para o backend pool
resource "azurerm_lb_rule" "vmss_lb_rule" {
  loadbalancer_id                = azurerm_lb.vmss_lb.id
  name                           = "HttpRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontend"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.vmss_lb_backend_pool.id
  probe_id                       = azurerm_lb_probe.vmss_lb_probe.id
  enable_floating_ip             = false
}

# 15. Conjunto de Dimensionamento Automatico (VMSS)
# Definicao do Conjunto de Dimensionamento Automatico
resource "azurerm_linux_virtual_machine_scale_set" "vmss_demo" {
  name                = "vmss-terraform-demo"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard_B1s" 
  instances           = 2
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  
  # Modo de Orquestracao - Uniform eh o mais comum para cenarios simples
  orchestration_mode = "Uniform" 

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true
    ip_configuration {
      name                          = "internal"
      primary                       = true
      subnet_id                     = azurerm_subnet.vmss_subnet.id
      private_ip_address_allocation = "Dynamic"
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.vmss_lb_backend_pool.id]
    }
  }

  # Configuracao de Auto-dimensionamento (Autoscaling)
  # Este bloco define como o VMSS ira escalar automaticamente
  # Exemplo: escalar com base na utilização da CPU.
  # Pode ser configurado para escalar para cima (scale out) e para baixo (scale in)
  automatic_instance_repair {
    enabled = true
  }
  # Exemplo de configuracao de auto-dimensionamento (nao descomentar em producao sem entender os custos)
  # Este bloco adicionaria uma regra de autoscaling para escalar baseado em CPU
  # Os perfis de autoscaling e regras podem ser bem complexos dependendo da necessidade
  # Voce precisaria de um `azurerm_monitor_autoscale_setting` para isso

  tags = {
    environment = "development"
    project     = "terraform-demo-vmss"
  }
}

# 16. Saidas (Outputs)
# As saídas mostram informacoes importantes sobre os recursos provisionados apos a execucao do Terraform
output "vm_public_ip_address" {
  description = "Endereço IP público da Máquina Virtual de demonstração."
  value       = azurerm_public_ip.vm_public_ip.ip_address
}

output "lb_public_ip_address" {
  description = "Endereço IP público do Load Balancer para o VMSS."
  value       = azurerm_public_ip.lb_public_ip.ip_address
}

output "resource_group_name" {
  description = "Nome do Grupo de Recursos."
  value       = azurerm_resource_group.main.name
}
