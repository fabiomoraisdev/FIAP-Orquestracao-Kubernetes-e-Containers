## Swarm 2.1 - Montando seu cluster

**Antes de começar, execute os passos abaixo para configurar o ambiente caso não tenha feito isso ainda na aula de HOJE: [Preparando Credenciais](../../01-create-codespaces/Inicio-de-aula.md)**

1. Entre na pasta das demos da disciplina e atualize o repositório com o comandos abaixo para garantir que tem a ultima versão do código utilizado nessa aula. Se tiver feito isso hoje no inicio da aula, pode pular esse passo.
```  shell
cd /workspaces/FIAP-Orquestracao-Kubernetes-e-Containers/
git reset --hard && git pull origin master
```
2. Primeiramente você irá precisar entrar na pasta onde está o código responsável por criar o nó master do cluster. Para isso execute o comando abaixo

``` shell
cd /workspaces/FIAP-Orquestracao-Kubernetes-e-Containers/03-Swarm/01-Montando-o-cluster/manager/
```

3. Antes de iniciar , você precisa adicionar ao codespaces a chave SSH a ser utilizada para criar as maquinas na AWS. Para isso volte na aba do seu navegador `Worksbench - Vocareum`, a mesma que utiliza para abrir a conta da AWS quando fica verde, e clique em `AWS Details` no canto superior direito.
   
   ![](img/5.png)
   
4. Em <b>SSH Key</b> clique em `Show` para visualizar a chave SSH que você irá utilizar para criar as maquinas na AWS.

   ![](img/7.png)

5. Copie todo o conteúdo da chave SSH e volte para a aba do codespaces.
6. De volta ao codespaces, execute o comando abaixo. Esse comando vai abrir uma nova aba no seu IDE.

``` shell
code /home/vscode/.ssh/vockey.pem
```

7. Cole o conteudo da chave SSH que você copiou anteriormente e salve o arquivo utilizando ctrl + S.

   ![](img/8.png)

8. No terminal execute o comando `chmod 400 ~/.ssh/vockey.pem` para dar as permissões corretas para a chave SSH.
9.  O primeiro passo do cluster é criar o nó master, para isso entre na pasta onde esta o código responsável por criar o nó master do cluster com os comandos abaixo:
``` shell
cd /workspaces/FIAP-Orquestracao-Kubernetes-e-Containers/03-Swarm/01-Montando-o-cluster/manager/
terraform init
```

   ![](img/2.png)

10. Para provisionar o nó master do cluster swarm utilize o comando abaixo. Esse comando pode demorar por volta de 5 minutos para terminar.

``` shell
terraform apply --auto-approve
```

![](img/9.png)

11. Com o nó master de pé agora é hora de provisionar o worker para isso entre na pasta com o comando:

``` shell
cd /workspaces/FIAP-Orquestracao-Kubernetes-e-Containers/03-Swarm/01-Montando-o-cluster/workers/
```

12.  Execute o comando `terraform init` para inicializar o terraform dos workers.
   
   ![](img/3.png)

13.  Para provisionar o nó worker do cluster swarm utilize o comando de apply abaixo. Esse comando pode demorar por volta de 5 minutos para terminar.
``` shell
terraform apply --auto-approve
```

![](img/4.png)

14.  Vamos fazer a configuração do AWS System Manger para que seja possível acessar o worker via terminal. Para isso execute o comando abaixo para criar um novo documento de permissão do SSM.
``` shell
bash /workspaces/FIAP-Orquestracao-Kubernetes-e-Containers/03-Swarm/01-Montando-o-cluster/configura-system-manager.sh
```

15. O que faremos agora é acessar o nó master para validar se esta tudo certo com o cluster. Para isso execute o comando abaixo para acessar o nó master via ssm.
``` shell
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb" && \
sudo dpkg -i session-manager-plugin.deb

INSTANCE_ID=$(aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=docker-swarm-manager" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)
aws ssm start-session \
  --region us-east-1 \
  --target "$INSTANCE_ID"
```

   ![](img/11.png)

1.  Ao final se executar o comando `docker node ls` verá os 2 nós no cluster.
   
   ![](img/10.png)
