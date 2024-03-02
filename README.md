# Repositório

A intenção deste repositório é fornecer um **Vagrantfile** capaz de criar um cluster kubernetes, fazendo com que a interação com o cluster esteja mais próxima dos ambientes de produção.

Se está começando com o Kubernetes, recomendo utilizar o **minikube**, pois este provisionamento é mais interessante para quem pretende conhecer a infraestrutura.

## KVM

Para quem utiliza Linux baseados em RHEL e tem problemas com SELinux ou mesmo não queria digitar usuário e senha a todo `vagrant up` para montar os NFS, podemos utilizar `virtiofs` para compartilhar diretórios:

**~/.vagrant.d/Vagrantfile**

```ruby
Vagrant.configure("2") do |config|
  config.vm.provider :libvirt do |libvirt|
    libvirt.cpus = 2
    libvirt.numa_nodes = [{ :cpus => "0-1", :memory => 8192, :memAccess => "shared" }]
    libvirt.memorybacking :access, :mode => "shared"
  end
  config.vm.synced_folder "./", "/vagrant", type: "virtiofs"
end
```

# Kubernetes

Abaixo há uma pequena introdução a respeito do universo dos contâineres e o papel do Kubernetes, logo após, alguns objetos do Kubernetes são apresentados com breves descrições.

## Container

É uma espécie de virtualização, o encapsulamento e isolamento de recursos controlados a nível de processo. Uma imagem contendo todas as dependências da aplicação, podendo rodar independete de qualquer sistema. Uma aplicação auto-contida.

- **cgroups** - Permite ao host compartilhar e limitar recursos que cada processo utilizará. Limita o quanto pode usar.
- **Namespaces** - Cria a área chamada de contêiner, limitando a visualização que o processo possuí dos demais processos, filesystems, redes e componentes de usuário. Limita o quanto pode ver.
- **Union filesystems** - Conceito de copy-on-write, utiliza-se de camadas já existentes - snapshots - e cria uma camada superficial de escrita, lendo o que for necessário nas camadas inferiores e ao alterá-las, copia a modificação para a camada superior.

## Pod

É a únidade mínima do Kubernetes, pode conter um ou mais contêineres. Os pods agrupam lógicamente os contêineres em termos de rede e hardware. O processo entre estes contêineres pode acontecer sem a alta latência de ter que atravessar uma rede. Assim como dados comuns podem ser guardados em volumes que são compartilhados entre esses contêineres.

## Orquestrador

Serviços baseados em contêineres são construídos em cima de uma rígida organização. Com o tempo, alocação de recursos, self-healing, táticas de deploy, proximidade de serviços, movimentação de containers e rollbacks começam a aumentar a complexibilidade de uma infraestrutura. É neste momento que um orquestrador é necessário, ou seja, o Kubernetes.

# Objetos do Kubernetes

## Pod

**cgi-pod.yml**:

```yml
apiVersion: v1
kind: Pod
metadata:
  name: cgi-pod
  labels:
    app: cgi
spec:
  containers:
  - name: cgi-pod
    image: hectorvido/sh-cgi
    ports:
    - containerPort: 8080
```

Adicione o pod ao Kubernetes executando o seguinte comando:

```bash
kubectl create -f cgi-pod.yml
kubectl get pods
kubectl describe pods/cgi-pod
kubectl get pod cgi-pod --template='{{.status.podIP}}'
```

Isto criará um pod com um contêiner chamado **cgi-pod**.
Veja que o pod possuí um IP privado. A partir deste momento, podemos acessar este endereço em qualquer um dos nodes de nosso cluster.

## Labels

Labels são conjuntos de chave/valor que servem para agrupar determinados objetos dentro do Kubernetes. Podemos adicioná-los no momento da criação ou a qualquer momento depois. São utilizados para a organização e seleção de um conjunto de objetos.

## Services

Um objeto service utiliza labels para selecionar e fornecer um ponto de acesso em comum para um conjunto de pods, criando automaticamente um balanceamento de carga entre os pods disponíveis:

**cgi-service.yml**

```yml
apiVersion: v1
kind: Service
metadata:
  name: cgi-service
  labels:
    app: cgi
spec:
  selector:
    app: cgi
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

# Deployments

Deployment é um objeto de alto nível responsável por controlar a forma como os pods são recriados através da modificação do número desejado de réplicas em relação ao número atual.
Ao criar um deployment, três objetos aparecem:

 - Pod
 - ReplicaSet
 - Deployment

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cgi-deploy
  labels:
    app: cgi
spec:
  replicas: 8
  selector:
    matchLabels:
      app: cgi-deploy
  minReadySeconds: 5
  strategy:
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    metadata:
      labels:
        app: cgi-deploy
    spec:
      containers:
      - name: cgi-deploy
        image: hectorvido/sh-cgi
        ports:
        - containerPort: 8080
```

# Secrets e ConfigMaps

Os secrets e os configmaps são capazes de gerar valores que podem ficar disponíveis por todo o cluster, removendo a necessidade de atualizar variáveis de ambiente especificadas a um **Deployment**.
Ao contrário do que pareça ser, os Secrets não são nada mais do que ConfigMaps - com a excessão de que seus valores são codificados em base64. A única diferença real entre ambos é o fato de poder bloquear através de RBAC o acesso a qualquer um dos dois, geralmente o **Secret**. Dessa forma, usa-se a convenção de que o **ConfigMap** carrega informações não sigilosas.

> Caso se utilize **Secrets** ou **ConfigMaps** para preencher valores de variáveis de ambiente e haja necessidade de atualização destes valores, os pods precisarão ser recriados. O mesmo não é verdadeiro para o caso de utilizar qualquer um dos dois como volume.

## ConfigMap

Podemos criar o configMap através do cli:

```bash
kubectl create cm --from-file lighttpd.conf lighttpd-config
```

### Manualmente

**configmap.yml**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: lighttpd-config
  labels:
    name: test
data:
  lighttpd.conf: |
    server.modules = (
        "mod_access",
        "mod_accesslog"
    )
    include "mime-types.conf"
    server.username      = "lighttpd"
    server.groupname     = "lighttpd"
    server.document-root = "/var/www/localhost/htdocs"
    server.pid-file      = "/run/lighttpd.pid"
    server.errorlog      = "/var/log/lighttpd/error.log"
    accesslog.filename   = "/var/log/lighttpd/access.log"
    server.indexfiles    = ("index.html", "index.sh")
    static-file.exclude-extensions = (".cgi", ".sh")
    server.modules += ("mod_cgi")
    cgi.assign = (
        ".sh" => "/bin/sh",
    )
```

## Secret

Podemos criar o secret através do cli:

```bash
kubectl create secret generic --from-env-file .env db-secret
```

### Manualmente

Para colocar os valores no secret, devemos codificá-los para base64:

```bash
echo -n 'mysql.k8s.com' | base64 #bXlzcWwuazhzLmNvbQ==
echo -n '3306' | base64 #MzMwNg==
echo -n 'k8s' | base64 #azhz
echo -n 'kub3rn3ts' | base64 #a3ViM3JuM3Rz
```

**secret.yml**

```yml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
  labels:
    name: test
type: Opaque
data:
  db_host: bXlzcWwuazhzLmNvbQ==
  db_port: MzMwNg==
  db_user: azhz
  db_pass: a3ViM3JuM3Rz
```

Existem várias formas de tornar o secret disponível dentro do pod, um dos exemplos é como variáveis de ambiente e o outro como um arquivo em um volume:

```yml
apiVersion: v1
kind: Pod
metadata:
  name: pod
  labels:
    name: test
spec:
  containers:
  - name: container
    image: alpine
    stdin: true
    tty: true
    env:
      - name: HOST
        valueFrom:
          secretKeyRef:
            name: db-secret
            key: db_host
      - name: PORT
        valueFrom:
          secretKeyRef:
            name: db-secret
            key: db_port
      - name: USERNAME
        valueFrom:
          secretKeyRef:
            name: db-secret
            key: db_user
      - name: PASSWORD
        valueFrom:
          secretKeyRef:
            name: db-secret
            key: db_pass
    volumeMounts:
    - name: config-volume
      mountPath: /etc/lighttpd/
  volumes:
  - name: config-volume
    configMap:
      name: lighttpd-config
```

## Ingress

Apesar de ser possível expor serviços distribuídos no cluster diretamente com LoadBalancer ou NodePort, existem cenários de roteamento mais avançados. O **ingress** é utilizado para isso, pense nele como uma camada extra de roteamento antes que a requisição chegue ao serviço. Assim como uma aplicação possuí um serviço e seus pods, os recursos do ingress precisam de uma entrada no ingress e um controlador que executa uma lógica customizada. A entrada define a rota e o controlador faz o roteamento.
Pode ser configurado para fornecer URLs externas para os serviços, terminar o SSL, load balacing, e fornecer nomes para hosts virtuais como vemos em web servers.

Em serviços de cloud como DigitalOcean ou GCP, já existe um controlador de ingress pronto para ser utilizado, mas quando provisionamos o cluster por conta própria, precisamos instalar esse controlador. Um dos mais conveninentes e conhecidos parece ser o **nginx**, mas neste caso utilizaremos um baseado em **HAProxy**:

[https://haproxy-ingress.github.io/docs/getting-started/](https://haproxy-ingress.github.io/docs/getting-started/)

### Instalação

Aplique o manifesto que adicionará todos os objetos necessários:

```bash
kubectl create -f https://haproxy-ingress.github.io/resources/haproxy-ingress.yaml
```

O controle do ingress vai apenas para as máquinas especificadas com o label `role=ingress-controller`, vamos adicioná-lo:

```bash
for X in master node1 node2; do
	kubectl label node $X role=ingress-controller
done
```

Para acelerar as coisas, crie o o deployment (altere para 4 réplicas) e o serviço através da linha de comando:

```bash
kubectl create deployment cgi --image=hectorvido/sh-cgi
kubectl patch deployment cgi -p '{"spec" : {"replicas" : 4}}' # ou scale deploy
kubectl expose deployment cgi --port 80 --target-port 8080
kubectl get all
```

Vamos criar um ingress e utilizá-lo para fazer roteamento através de hostname e terminação TLS, isso significa que nosso cluster passará a responder por um host e fará a comunicação segura entre o cliente e o cluster, mas do cluster para o pod a comunicação será comum.
Antes disso, vamos criar nosso certificado x509 auto-assinado, se você usa *Let's s Encrypt* o processo é o mesmo, você só não precisará gerar o certificado:

```
# Crie um novo certificado x509 sem criptografia na chave privada.
# Colocando a chave no arqivo key.pem e o certificado em cert.pem
openssl req -x509 -nodes -keyout key.pem -out cert.pem
```

Os certificados utilizados pelo ingress são salvos em um **secret**, portanto obrigatoriamente no formato **base64**. Felizmente existe um comando que facilita esta conversão e criação:

```
kubectl create secret tls cgi --key key.pem --cert cert.pem
# Para visualizar o arquivo puro, como deveria ser feito:
kubectl edit secret cgi
```

Com tudo pronto, definiremos o ingress que irá responder pelo **hostname** e apontar para um determinado serviço:

```yml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: cgi
spec:
  tls:
  - hosts:
    - cgi.172-27-11-10.nip.io
    secretName: cgi
  rules:
  - host: cgi.172-27-11-10.nip.io
    http:
      paths:
      - path: /
        backend:
          serviceName: cgi
          servicePort: 80
```

Provisione o serviço no cluster e teste o endereço adicionando o ip de qualquer um dos **minions** no */etc/hosts* ou utilizando o parâmetro --resolv do curl:

```bash
kubectl apply -f sh-cgi-ingress.yml
curl -kL https://cgi.172-27-11-10.nip.io
```

Pelo fato de utilizarmos um certificado auto-assinado, o parâmetro -k é obrigatório para o funcionamento.

# Volumes

O Kubernetes suporta diversos tipos de volume, por exemplo:

- NFS
- iSCSI
- GlusterFS
- CephFS
- Cinder

Cada volume é definido através de um **PersistentVolume**, que disponibiliza o volume para o cluster, e os usuário requisitam estes volumes através de um **PersistentVolumeClaim**.

## Mode

É possível através da diretiva **volumeMode** especificar o uso de dispositivos inteiros com **block** ou pontos de montagem com **filesystem**, que é o padrão.

## Access Modes

Cada volume possuí três tipos de acesso:

- **ReadWriteOnce** – o volume pode ser montado para leitura e escrita por apenas um node - RWO
- **ReadOnlyMany** – o volume pode ser montado somente para leitura em vários nodes - ROX
- **ReadWriteMany** – o volume pode ser montado para leitura e escrita em vários nodes - RWX

## NFS

Por questões de facilidade, exemplificarei o uso de NFS. Os passos de instalação e criação dos pontos de montagem são executados durante o provisionamento das máquinas pelo Vagrant.
Instalar o pacote **nfs-kernel-server** na máquina que será o nosso storage e criar os diretórios que serão utilizados:

```bash
apt-get install -y nfs-kernel-server
mkdir -p /srv/nfs/v{0..9}
```

Feito isso, edite o arquivo **/etc/exports** para adicionar os pontos de montagem que serão disponibilizados no cluster:

**/etc/exports**

```
/srv/nfs/v1 172.27.11.0/255.255.255.0(rw,no_root_squash,no_subtree_check)
/srv/nfs/v2 172.27.11.0/255.255.255.0(rw,no_root_squash,no_subtree_check)
/srv/nfs/v3 172.27.11.0/255.255.255.0(rw,no_root_squash,no_subtree_check)
/srv/nfs/v4 172.27.11.0/255.255.255.0(rw,no_root_squash,no_subtree_check)
/srv/nfs/v5 172.27.11.0/255.255.255.0(rw,no_root_squash,no_subtree_check)
```

Execute o comando **exportfs** para habilitar os pontos de montagem:

```bash
exportfs -a
exportfs
```

Nas máquinas que rodam os pods instalar o **nfs-common** e verificar se é possível montar os diretórios remotamente:

```bash
apt-get install -y nfs-common
mount -t nfs 172.27.11.40:/srv/nfs/v1 /mnt
echo kubernetes > /mnt/k8s
umount /mnt
```

Verificar na máquina **storage** se o arquivo passou a existir:

```bash
cat /srv/nfs/v1/k8s
```

Para disponibilizar os volumes para o cluster, precisamos criar um tipo de objeto chamado **PersistentVolume** ou pv:

**nfs-pv.yml**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-v1
spec:
  capacity:
    storage: 256Mi
  accessModes:
  - ReadWriteMany
  nfs:
    server: 172.27.11.40
    path: "/srv/nfs/v1"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-v2
spec:
  capacity:
    storage: 512Mi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 172.27.11.40
    path: "/srv/nfs/v2"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-v3
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  nfs:
    server: 172.27.11.40
    path: "/srv/nfs/v3"
```

Para que um usuário possa utilizar um destes volumes, é preciso que um **PersistentVolumeClain** seja criado. Desta forma, um volume persistente que atenda as exigências do pedido passará a estar disponível para ser atachado a algum pod:

**nfs-pvc1.yml**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc1
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 256Mi
```

```bash
kubectl get pv
kubectl get pvc
```

Para atachar o volume para os pods de um deployment que agora poderão compartilhar arquivos em qualquer lugar do cluster. Veja que o volume faz referência ao **PersistentVolumeClaim** não ao **PersistentVolume**:

**volume-deploy.yml**

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lighttpd
  labels:
    app: lighttpd
spec:
  selector:
    matchLabels:
      app: lighttpd
  replicas: 3
  template:
    metadata:
      labels:
        app: lighttpd
    spec:
      containers:
      - image: hectorvido/sh-cgi
        name: lighttpd
        ports:
        - containerPort: 80
        volumeMounts:
        - name: shared-data
          mountPath: /var/shared-data
      volumes:
      - name: shared-data
        persistentVolumeClaim:
          claimName: nfs-pvc1
```

Além disso, outros pods podem utilizar o volume, sem nenhum problema:

**alpine-pod.yml**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: alpine
spec:
  containers:
  - image: alpine
    name: alpine
    tty: true
    stdin: true
    volumeMounts:
    - name: shared-data
      mountPath: /var/shared-data
  volumes:
  - name: shared-data
    persistentVolumeClaim:
      claimName: nfs-pvc1
```
