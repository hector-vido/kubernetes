# O que é isso?

Este é um repositório que provisiona um cluster [Kubernetes](https://kubernetes.io/) usando o [Vagrant](https://www.vagrantup.com/).

É possível ativar um **desafio** que mexerá em alguns componentes para que você possa testar seu conhecimento sobre infraestrutura, tentar concluir as **tarefas** para testar seu conhecimento sobre operações ou ambos.

Para usá-lo, você precisa [instalar o Vagrant](https://developer.hashicorp.com/vagrant/docs/installation) e também um [hypervisor](https://pt.wikipedia.org/wiki/Hipervisor) como [VirtualBox](https://www.virtualbox.org/) ou [Libvirt](https://libvirt.org/), infelizmente o suporte ao [HyperV](https://pt.wikipedia.org/wiki/Hyper-V) é limitado, pois o Vagrant não pode criar redes dentro dele.

Serão criadas quatro máquinas; certifique-se de que você tenha memória livre suficiente:

| Máquina | IP            | CPU | Memória |
|---------|---------------|-----|---------|
| control | 192.168.56.10 |   2 |    2048 |
| worker1 | 192.168.56.20 |   1 |    1024 |
| worker2 | 192.168.56.30 |   1 |    1024 |
| storage | 192.168.56.40 |   1 |     512 |

Você pode alterar a memória/CPU padrão de cada máquina virtual, alterando o hash denominado `vms` dentro do `Vagrantfile`:

```ruby
vms = {
  'control' => {'memory' => '2048', 'cpus' => 2, 'ip' => '10', 'provision' => 'control.sh'},
  'worker1' => {'memory' => '1024', 'cpus' => 1, 'ip' => '20', 'provision' => 'worker.sh'},
  'worker2' => {'memory' => '1024', 'cpus' => 1, 'ip' => '30', 'provision' => 'worker.sh'},
  'storage' => {'memory' => '512', 'cpus' => 1, 'ip' => '40', 'provision' => 'storage.sh'}
}
```

Se estiver começando no Kubernetes, recomendo dar uma olhada no [minikube](https://minikube.sigs.k8s.io/docs/) porque esse repositório é voltado para pessoas que querem entender sua infraestrutura.

## Provisionamento

Instale o Vagrant - e talvez algum [plugin](https://vagrant-lists.github.io/) - e um hypervisor, clone o repositório e execute `vagrant up`:

```bash
git clone git@github.com:hector-vido/kubernetes.git --config core.autocrlf=false
cd kubernetes
vagrant up
```

> **Importante:** a opção `--config core.autocrlf=true` configura o Windows para não adicionar `\r` aos finais de linha.

Após o provisionamento, todos os comandos devem ser executados a partir do **control** como usuário `root`:

```bash
vagrant ssh control
sudo -i
kubectl get nodes

# Saída:
#
# NAME      STATUS   ROLES           AGE   VERSION
# control   Ready    control-plane   82m   v1.31.0
# worker1   Ready    <none>          82m   v1.31.0
# worker2   Ready    <none>          82m   v1.31.0
```

# Desafio

O **desafio** pode ser ativado com a execução do seguinte comando:

```bash
k8s-challenge
```

Isso desconfigurará alguns componentes e criará uma interrupção no cluster, cabe a você corrigir.

# Tarefas

As **tarefas** são uma lista de coisas que você deve fazer no Kubernetes.

Você pode ver a lista aqui ou pode executar `k8s-tasks`, também pode verificar se concluiu com êxito uma tarefa executando o `k8s-check`.

```
1 - Corrigir o problema de comunicação entre as máquinas:
  1.1 - control....192.168.56.10
  1.2 - worker1....192.168.56.20
  1.3 - worker2....192.168.56.30
  Observação: Não use o kubeadm, não reinicie o cluster.
  O SSH com o usuário "root" é permitido entre as máquinas mencionadas.
  O namespace deve ser sempre "default", a menos que seja especificado.

2 - Provisione um pod chamado "apache" com a imagem "httpd:alpine".

3 - Crie um Deployment chamado "cgi" com a imagem "hectorvido/sh-cgi" e um Service:
  3.1 - O Deployment deve ter 4 réplicas;
  3.2 - Crie um Service chamado "cgi" para a implantação "cgi";
  3.3 - O Service responderá internamente na porta 9090.

4 - Crie um Deployment chamado "nginx" com base em "nginx:alpine":
  4.1 - Atualize o Deployment para a imagem "nginx:perl";
  4.2 - Reverta para a versão anterior.

5 - Crie um pod "memcached:alpine" para cada worker no cluster:
  5.1 - Se um novo nó for adicionado ao cluster, uma réplica
        desse pod precisa ser provisionada automaticamente dentro do novo nó;

6 - Crie um pod com a imagem "hectorvido/apache-auth" chamado "auth":
  6.1 - Crie um Secret chamado "httpd-auth" com base no arquivo "files/auth.ini";
  6.2 - Crie duas variáveis de ambiente no pod:
        HTPASSWD_USER e HTPASSWD_PASS com os respectivos valores de "httpd-auth";
  6.4 - Crie um ConfigMap chamado "httpd-conf" com o conteúdo de "files/httpd.conf";
  6.5 - Monte-o dentro do pod em "/etc/apache2/httpd.conf" usando "subpath";
  6.6 - A página só deve ser exibida com a execução do seguinte comando:
        curl -u developer:secret <pod-ip>
        Caso contrário, uma mensagem sobre autorização deverá ser exibida.
  Observação: não é necessária nenhuma configuração extra, o Secret e o ConfigMap cuidam de
  todo o processo de configuração.

7 - Crie um pod chamado "tools":
  7.1 - O pod deve usar a imagem "busybox";
  7.2 - O pod deve ser estático;
  7.3 - O pod deve estar presente apenas em "worker1".

8 - Crie um StatefulSet chamado "couchdb" com a imagem "couchdb"
    dentro do namespace "database":
  8.1 - Crie o namespace "database";
  8.2 - O "headless service" deve se chamar "couchdb" e escutar na porta 5984;
  8.3 - Crie o diretório "/srv/couchdb" na máquina "worker2";
  8.4 - Crie um volume persistente que use o diretório acima;
  8.5 - O pod só pode ir para a máquina "worker2";
  8.6 - O usuário de conexão deve ser "developer" e a senha "secret";
  8.7 - Persista os dados do couchdb no volume criado acima;
  Observação: o diretório usado pelo couchdb para persistir os dados é "/opt/couchdb/data".
```

## Resolvendo

Se quiser ver tudo funcionando e também testar o ambiente para garantir que nada esteja errado, você pode executar o `k8s-solve`, esse comando criará tudo o que for necessário para resolver as tarefas. Esse comando será executado como se nenhuma tentativa tivesse sido feita, se você já tiver executado algumas das tarefas, provavelmente verá alguns erros.

# Arquivos compartilhados

Esse repositório usa muitos arquivos compartilhados entre o host e as máquinas convidadas. Certifique-se de que uma pasta chamada `/vagrant` com o conteúdo desse repositório esteja presente em todas as máquinas.

O Vagrant faz isso de diferentes maneiras: ele pode simplesmente copiar tudo, montar um NFS ou usar recursos mais avançados de outros hypervisors.

## VirtualBox

Quando o Vagrant provisiona uma máquina com o VirtualBox, o conteúdo do `/vagrant` será populado com um `rsync`.

## Libvirt

Quando o Vagrant provisiona uma máquina com o Libvirt, o conteúdo de `/vagrant` pode ser populado com `nfs` ou `virtiofs`.

Se você usa Linux baseados em RHEL e tem alguns problemas com o SELinux ou não quer digitar sua senha do sudo toda vez que executar o `vagrant up` para montar o NFS, você pode usar o `virtiofs` para compartilhar diretórios:

**~/.vagrant.d/Vagrantfile**

```ruby
Vagrant.configure("2") do |config|
  config.vm.provider :libvirt do |libvirt|
    libvirt.memorybacking :access, :mode => "shared"
    libvirt.qemu_use_session = false
    libvirt.system_uri = 'qemu:///system'
  fim
  config.vm.synced_folder "./", "/vagrant", type: "virtiofs"
end
```

**Importante:** A opção `qemu_use_session` é `false` porque uma sessão de usuário comum não pode criar redes.
