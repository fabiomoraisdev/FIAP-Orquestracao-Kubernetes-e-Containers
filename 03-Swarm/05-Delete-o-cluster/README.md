## Conteiners 3.5 - Delete o cluster

**Antes de começar, execute os passos abaixo para configurar o ambiente caso não tenha feito isso ainda na aula de HOJE: [Preparando Credenciais](../../01-create-codespaces/Inicio-de-aula.md)**

1. No Codespaces entre na pasta das demos da disciplina e atualize o repositório com os comandos abaixo para garantir que tem a ultima versão do código utilizado nessa aula.
``` shell
cd /workspaces/FIAP-Orquestracao-Kubernetes-e-Containers/
git reset --hard && git pull origin master
```

2. O processo de deleção deve ser feito primeiro nos workers e depois no manager. Comece entrando na pasta dos workers com o comando abaixo.
``` shell
cd /workspaces/FIAP-Orquestracao-Kubernetes-e-Containers/03-Swarm/01-Montando-o-cluster/workers/
```

3. Execute o destroy dos workers.
``` shell
terraform destroy --auto-approve
```

4. Com os workers removidos, entre na pasta do manager.
``` shell
cd /workspaces/FIAP-Orquestracao-Kubernetes-e-Containers/03-Swarm/01-Montando-o-cluster/manager/
```

5. Execute o destroy do manager.
``` shell
terraform destroy --auto-approve
```

6. Para confirmar que não restaram instancias do laboratório em execução, execute o comando abaixo no codespaces.
``` shell
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=docker-swarm-manager,docker-swarm-worker-*" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query "Reservations[].Instances[].{Id:InstanceId,Name:Tags[?Key=='Name']|[0].Value,State:State.Name}" \
  --output table
```

7. (Opcional) Se quiser limpar os parâmetros do SSM criados durante os módulos, execute os comandos abaixo.
``` shell
aws ssm delete-parameter --name docker-join-worker-token --region us-east-1 || true
aws ssm delete-parameter --name docker-join-manager-token --region us-east-1 || true
aws ssm delete-parameter --name docker-join-manager-ip --region us-east-1 || true
aws ssm delete-parameter --name docker-worker-ip --region us-east-1 || true
```

