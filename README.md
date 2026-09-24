# Disk Alert - Discord Webhook Monitor

Script em Bash para monitoramento de uso de disco com envio de alertas
via Webhook do Discord.

Projeto desenvolvido para fornecer um monitoramento leve, direto e
eficiente, sem necessidade de ferramentas complexas como Zabbix ou
Nagios para esse caso específico.

------------------------------------------------------------------------

# Objetivo

Monitorar partições do servidor e:

-   Enviar alertas programados quando o uso estiver acima do limite
    crítico.
-   Detectar aumento percentual enquanto o disco já estiver em estado
    crítico.
-   Enviar notificações automáticas para um canal do Discord.
-   Operar com baixo consumo de recursos.

------------------------------------------------------------------------

# Funcionamento Geral

O script trabalha com dois modos de operação:

-   `report`
-   `watch`

Ambos utilizam a mesma base de verificação de disco, mas possuem
comportamentos diferentes.

------------------------------------------------------------------------

# Modo 1 - REPORT (Relatório Programado)

Executado em horários fixos (ex: 08h e 20h).

## O que ele faz:

-   Verifica as partições configuradas.
-   Se o uso estiver acima do limite crítico, envia alerta.
-   Envia alerta mesmo que não tenha havido alteração desde a última
    checagem.
-   Funciona como lembrete operacional.

------------------------------------------------------------------------

# Modo 2 - WATCH (Monitoramento Contínuo)

Executado em intervalos curtos (ex: a cada 5 minutos).

## O que ele faz:

-   Só envia alerta se:
    -   O uso estiver acima do limite crítico **E**
    -   Houve aumento percentual desde a última execução.

## Benefícios:

Detecta crescimento contínuo de consumo como:

-   Logs descontrolados
-   Backups acumulando
-   Erros de aplicação
-   Ataques
-   Geração excessiva de arquivos temporários

------------------------------------------------------------------------

# Lógica de Estado

O script mantém um pequeno arquivo local para armazenar o último
percentual visto.

Exemplo de caminho:

    /var/lib/disk-alert/state.db

Formato do arquivo:

    particao|ultimo_percentual|timestamp_ultimo_alerta

Exemplo:

    /home|96|1708702103

Esse arquivo:

-   Não é um banco de dados real
-   É apenas um arquivo texto simples
-   Não depende de MySQL, PostgreSQL ou SQLite
-   Serve apenas para comparação de estado anterior

------------------------------------------------------------------------

# O que é o timestamp?

O número como:

    1708702103

É um **Unix Timestamp**, ou seja:

Quantidade de segundos desde 01/01/1970 (Epoch Unix).

Pode ser convertido com:

``` bash
date -d @1708702103
```

------------------------------------------------------------------------

# Configuração no Script

## Variáveis principais:

``` bash
THRESHOLD=95
DELTA_WHILE_CRIT=1
DISCORD_URL="WEBHOOK_URL_AQUI"
```

## Explicação:

-   `THRESHOLD` → Percentual considerado crítico.
-   `DELTA_WHILE_CRIT` → Variação mínima para gerar novo alerta no modo
    watch.
-   `DISCORD_URL` → Webhook do Discord.

------------------------------------------------------------------------

# Partições Monitoradas

Exemplo:

``` bash
PARTITIONS=(
    "/"
    "/home"
    "/backup"
)
```

------------------------------------------------------------------------

# Configuração Recomendada do CRON

## Relatórios fixos (modo report):

``` bash
0 8 * * *  /usr/local/bin/disk_alert.sh report
0 20 * * * /usr/local/bin/disk_alert.sh report
```

## Monitoramento contínuo (modo watch):

``` bash
*/5 * * * * /usr/local/bin/disk_alert.sh watch
```

------------------------------------------------------------------------

# Segurança

-   Comunicação apenas via HTTPS com o Discord
-   Não depende de SMTP
-   Não abre portas no servidor
-   Pode utilizar `flock` para evitar execução simultânea
-   Sem dependência de banco de dados

------------------------------------------------------------------------

# Dependências

Normalmente já presentes no Linux:

-   bash
-   curl
-   df
-   flock

------------------------------------------------------------------------

# Deploy

Pode ser distribuído via:

-   Ansible
-   SCP
-   Git pull
-   Template base de VM

O script é praticamente stateless, exceto pelo arquivo local de estado.

------------------------------------------------------------------------

# Benefícios

-   Leve
-   Fácil manutenção
-   Baixo consumo
-   Fácil expansão
-   Alternativa simples para monitoramento específico de disco
-   Independente de infraestrutura de e-mail

------------------------------------------------------------------------

# Possíveis Melhorias Futuras

-   Descoberta automática de partições
-   Ignorar automaticamente tmpfs, overlay, docker
-   Identificação de diretórios que mais cresceram
-   Embed estruturado no Discord
-   Integração com Prometheus
-   Envio para múltiplos webhooks
-   Modo debug

------------------------------------------------------------------------

# Autor

Projeto desenvolvido para uso interno de monitoramento de
infraestrutura.

------------------------------------------------------------------------

# Resumo Arquitetural

O monitoramento funciona de forma híbrida:

-   Alertas programados (`report`)
-   Detecção de crescimento em tempo real acima do limite crítico
    (`watch`)

Garantindo:

-   Controle operacional
-   Visibilidade contínua
-   Detecção rápida de crescimento anormal
