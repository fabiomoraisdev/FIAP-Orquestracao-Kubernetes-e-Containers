## Conteiners 2.2 - Compose & Swarm Intro

**Antes de começar, execute os passos abaixo para configurar o ambiente caso não tenha feito isso ainda na aula de HOJE: [Preparando Credenciais](../../01-create-codespaces/Inicio-de-aula.md)**

1. Vamos acessar o terminal do nó master do cluster pelo console para fazer a demonstração. Para isso acesse o [link](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:instanceState=running) e selecione o nó master criado no módulo anterior.
    
    ![img/1.png](img/1.png)
2. Com o nó selecionado, clique em `Conectar`
    
    ![img/2.png](img/2.png)

3. Selecione a aba `Session Manager` e clique em `Conectar`
    
    ![img/3.png](img/3.png) 

4. Se tudo deu certo, você deve estar conectado no terminal do nó master do cluster. Agora vamos para a parte prática da aula.

    ![](img/4.png)

5.  Dentro do nó master execute os comandos abaixo para se mover para a pasta correta e baixar do git o repositório dessa demo
``` shell
cd /home/ssm-user/
git clone https://github.com/vamperst/python-redis-docker-compose-intro.git
```

![img/gitclone.png](img/gitclone.png)


6. Entre na pasta 'python-redis-docker-compose-intro' com o comando 
``` shell
cd /home/ssm-user/python-redis-docker-compose-intro
```

7. Entre na pasta 'python-redis-docker-compose-intro' com o comando 
``` shell
cd /home/ssm-user/python-redis-docker-compose-intro
```

8. Execute o comando `cat Dockerfile` para ver o conteudo do Dockerfile
   
   ![img/catdockerfile.png](img/catdockerfile.png)

9. Execute o comando `cat docker-compose.yml` para ver o conteudo do docker-compose.yml
   
   ![img/catdockercompose.png](img/catdockercompose.png)

10. Esta aplicação consiste em um app que conta quantos acessos uma pagina já teve e exibe a cada acesso. Para tal utiliza um código python que esta na pasta lib, e um container de redis como banco de dados.
11. Você irá precisar do numero da sua conta em uma variável do console. Para isso execute o comando 
    ``` shell
    accountID=`aws sts get-caller-identity | jq .Account -r`  
    ```
12. Execute o comando `sed -i -e "s/ACCOUNTID/$accountID/g" docker-compose.yml` para atualizar o arquivo para utilizar seu account id no nome da imagem. Você pode verificar a diferença pelo comando `cat docker-compose.yml`
13.  Será necessário criar um novo repositório do ECR para fazer o push da imagem dessa demo. Para isso acesse o [link](https://us-east-1.console.aws.amazon.com/ecr/private-registry/repositories/create?region=us-east-1)
14.  O repositório deve se chamar `app-counter`
    
    ![](img/ecr-create.png)

15.  Clique em `Criar`
16.  Devolta ao terminal do nó manager execute a sequência abaixo de comandos <b>UM POR UM</b> para que você monte a imagem docker e faça o push para o repositório récem criado.
    ``` shel
    accountID=`aws sts get-caller-identity | jq .Account -r`
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $accountID.dkr.ecr.us-east-1.amazonaws.com
    docker build -t app-counter .
    docker tag app-counter:latest $accountID.dkr.ecr.us-east-1.amazonaws.com/app-counter:1.0
    docker push $accountID.dkr.ecr.us-east-1.amazonaws.com/app-counter:1.0
    ```
    
    ![img/push.png](img/push.png)

17.  Execute o comando `docker stack deploy --with-registry-auth --compose-file docker-compose.yml app-counter` para subir todos os serviços
   
   ![img/stackcreate.png](img/stackcreate.png)

18.  Execute o comando `docker stack ls` para ver o status da stack completa
    
    ![img/stackls1.png](img/stackls1.png)

19.  Você também pode verificar a saude dos serviços através do comando `docker service ls`
    
    ![img/servicels1.png](img/servicels1.png)

20.  Caso todos os serviços estejam rodando conforme a imagem acima é hora de acessar o serviço criado. Para isso você vai precisar acessar via o IP público do nó manager, utilize o comando abaixo para gerar o link.
    ```
    workerIp=`aws ssm get-parameter --name "docker-worker-ip" | jq .Parameter.Value -r` && echo "http://$workerIp:5000"
    ```
    ![](img/getip1.png)

21.  Ao acessar via navegador você pode recarregar a página e ver o contador aumentar por que a cada vez que acessa um registro no redis é atualizado.
    
    ![](img/gethits.png)

22. De volta ao nó manager, para visualizar todos os containers em execução e onde estão vamos utilizar o Visualizer. Para tal execute o comando:
``` shell
docker service create --name=viz --publish=8080:8080/tcp  --constraint=node.role==manager --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock dockersamples/visualizer
```

![](img/viz1.png)

![](img/6.png)

23.  Utilize o comando abaixo para visualizar onde estão rodando cada container de serviço no cluster.
    ```
    TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    publicC9Ip=`curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4` && echo "http://$publicC9Ip:8080"
    ```
    
![img/visualizer.png](img/visualizer.png)

24. Acesse pelo navegador o link gerado no passo anterior para visualizar o cluster e onde estão rodando os containers. Você pode clicar em cada container para ver mais detalhes como o nome do serviço, a imagem utilizada, etc.

![](img/visualizer3.png)


25.  Voltando ao nó manager, agora vamos remover tudo do cluster. Primeiro a stack, execute o comando `docker stack rm app-counter`. Vai conseguir notar no visualizer que logo após o comando, os containers sumiram rapidamente.
    
    ![](img/viz3.png)
    ![img/visualizer2.png](img/visualizer2.png)

26.  Por fim remova o serviço criado para o visualizer com o comando `docker service rm viz`

![](img/vizremove.png)