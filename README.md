# dio-maquinas-virtuais-com-dimensionamento-automatico
## Configurando Recursos e Dimensionamentos em Máquinas Virtuais na Azure.
### Uma Máquina Virtual no Azure é um serviço de computação sob demanda que oferece uma instância de servidor virtualizada. Ela permite que você execute sistemas operacionais (Windows ou Linux) e aplicativos sem a necessidade de comprar e manter o hardware físico. As VMs no Azure são altamente configuráveis em termos de tamanho (CPU, memória), armazenamento (discos gerenciados), rede (NICs, IPs públicos/privados) e sistemas operacionais. São alguns conceitos básicos que auxiliam nas soluções com VM:
- Imagens: As VMs são provisionadas a partir de imagens de sistema operacional (marketplace ou personalizadas).
- Discos Gerenciados: O Azure oferece discos gerenciados (Standard HDD, Standard SSD, Premium SSD, Ultra Disk) para armazenamento persistente, simplificando o gerenciamento de discos.
- Rede Virtual (VNet) e Sub-redes: As VMs são implantadas dentro de uma rede virtual, permitindo conectividade privada e isolamento.
- Grupos de Segurança de Rede (NSGs): Controlam o tráfego de entrada e saída para as VMs.
- Disponibilidade: Opções como Conjuntos de Disponibilidade e Zonas de Disponibilidade garantem a alta disponibilidade das VMs.
- Extensões: Podem ser usadas para pós-configuração, como instalação de software, monitoramento ou gerenciamento de patches.
### Casos de Uso Comuns:
- Hospedagem de aplicativos legados que não podem ser conteinerizados ou executados em plataformas PaaS.
- Servidores de banco de dados.
- Servidores de desenvolvimento/teste.
- Ambientes de CI/CD.
- Cargas de trabalho que exigem controle granular sobre o sistema operacional
### Um Conjunto de Dimensionamento Automático é um recurso de computação do Azure que permite implantar e gerenciar um grupo de VMs idênticas. Ele é projetado para oferecer alta disponibilidade, resiliência e elasticidade para suas aplicações. A principal característica do VMSS é a capacidade de escalar automaticamente o número de instâncias de VM para cima ou para baixo com base em métricas de desempenho (CPU, memória, etc.) ou em um agendamento. São alguns conceitos básicos que auxiliam nas soluções com dimensionamento automático:
- Escalabilidade Automática: Define regras para adicionar ou remover instâncias de VM automaticamente, otimizando custos e garantindo desempenho.
- Balanceamento de Carga Integrado: Geralmente utilizado em conjunto com um Azure Load Balancer (interno ou externo) para distribuir o tráfego entre as instâncias do VMSS.
- Atualizações Contínuas: Permite a atualização de imagens do sistema operacional e configurações de aplicativos de forma orquestrada, minimizando o tempo de inatividade.
- Orquestração de Instâncias: O Azure gerencia a criação, exclusão e manutenção das instâncias, simplificando a operação.
- Modos de Orquestração:
  - Uniform: Todas as instâncias são idênticas. Mais simples de gerenciar.
  - Flexible: Permite a mistura de VMs com diferentes configurações, além de poder misturar VMs spot e regulares para otimização de custos. Oferece maior granularidade e controle
### Casos de Uso Comuns:
- Hospedagem de aplicações web de alta demanda.
- Serviços de API.
- Processamento de dados em lote.
- Qualquer aplicação que exija escalabilidade horizontal e alta disponibilidade

