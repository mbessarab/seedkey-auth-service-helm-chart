# SeedKey Helm Chart

## Содержание
- [Что разворачивает chart](#что-разворачивает-chart)
- [Namespace: важный нюанс](#namespace-важный-нюанс)
- [Установка](#установка)
- [Обновление (upgrade)](#обновление-upgrade)
- [Удаление](#удаление)
- [Настройка](#настройка)
- [Values](#values)
- [FluxCD конфигурация](#fluxcd-конфигурация)
- [🤝 Контрибьютинг](#-контрибьютинг)
- [🔧 Связные проекты](#-связные-проекты)
- [📄 Лицензия](#-лицензия)

Helm chart для деплоя **seedkey-auth-service** и **seedkey-db-migrations**.

## Что разворачивает chart

- `Deployment` для `auth-service` (если `authService.enabled=true`)
- `Service` для `auth-service`
- `Job` для миграций (Liquibase) как Helm hook `pre-install, pre-upgrade` (если `migrations.enabled=true`)
- `ConfigMap` с переменными окружения, если не задан `configMap.existingName`
- `ServiceAccount` (опционально)
- `Namespace` (опционально)

## Namespace: важный нюанс

Chart вычисляет namespace ресурсов так:

- если задан `global.namespace` → ресурсы создаются в нём
- иначе если задан `namespace.name` → ресурсы создаются в нём
- иначе → ресурсы создаются в `.Release.Namespace`

При этом **ресурс Namespace создаётся только по `namespace.*`**, и только если `namespace.name != .Release.Namespace`.

Рекомендация:

- либо используйте `helm ... --namespace <ns> --create-namespace` и не трогайте `global.namespace`
- либо задавайте **оба**: `namespace.name` и `global.namespace` одним и тем же значением (если хотите, чтобы chart сам создавал Namespace)

## Установка

### 1) Подготовьте Secret

Задайте `secrets.existingSecret` и создайте Secret с нужными ключами.

Обязательные ключи для `auth-service`:

- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `JWT_SECRET`

Ключи для миграций (Liquibase):

- `LIQUIBASE_COMMAND_URL`
- `LIQUIBASE_COMMAND_USERNAME`
- `LIQUIBASE_COMMAND_PASSWORD`

### 2) Установите chart

```bash
helm install seedkey ./helm-chart \
  --namespace seedkey --create-namespace \
  --set secrets.existingSecret=seedkey-secrets
```

### Проверка статуса

```bash
kubectl get pods -n seedkey
kubectl get svc -n seedkey
kubectl get jobs -n seedkey -l app.kubernetes.io/component=migrations
kubectl logs -n seedkey -l app.kubernetes.io/component=auth-service
```

## Обновление (upgrade)

```bash
helm upgrade seedkey ./helm-chart \
  --namespace seedkey \
  --set secrets.existingSecret=seedkey-secrets
```

## Удаление

```bash
helm uninstall seedkey --namespace seedkey
```

> Namespace удаляется **только если вы удаляете его отдельно**.

## Настройка

### Подключение к БД

Параметры подключения задаются в `database.connection.*` и попадают в `ConfigMap`:

- `database.connection.host` (по умолчанию: `postgres-db`)
- `database.connection.port` (по умолчанию: `5432`)
- `database.connection.database` (по умолчанию: `seedkey`)
- `database.connection.ssl` (по умолчанию: `"false"`)
- `database.connection.maxConnections` (по умолчанию: `"20"`)

### Использование существующего ConfigMap

Если вы хотите полностью управлять переменными окружения через свой ConfigMap:

```bash
helm upgrade --install seedkey ./helm-chart \
  --namespace seedkey \
  --set configMap.existingName=my-seedkey-config \
  --set secrets.existingSecret=seedkey-secrets
```

В этом режиме chart **не создаёт** свой ConfigMap.

### Миграции Job (Liquibase) 

Параметры:

- `migrations.backoffLimit` — число ретраев
- `migrations.ttlSecondsAfterFinished` — авто-очистка Job после завершения
- `migrations.restartPolicy` — политика рестарта Pod в Job

## Values

### Общие

| Параметр | Описание | Default |
|---|---|---|
| `global.namespace` | Namespace для всех ресурсов chart’а | `"seedkey"` |
| `namespace.create` | Создавать Namespace ресурсом chart’а | `true` |
| `namespace.name` | Имя Namespace для создания (и альтернативно для размещения ресурсов, если `global.namespace` не задан) | `"seedkey"` |
| `configMap.existingName` | Использовать существующий ConfigMap вместо генерации | `""` |
| `secrets.existingSecret` | Secret с кредами БД и `JWT_SECRET`/Liquibase env | `""` |

### auth-service

| Параметр | Описание | Default |
|---|---|---|
| `authService.enabled` | Включить деплой `auth-service` | `true` |
| `authService.replicaCount` | Количество реплик | `1` |
| `authService.service.type` | Тип Service | `ClusterIP` |
| `authService.service.port` | Service port | `80` |
| `authService.service.targetPort` | Container port | `3000` |
### migrations

| Параметр | Описание | Default |
|---|---|---|
| `migrations.enabled` | Включить миграции | `true` |
| `migrations.backoffLimit` | Количество ретраев Job | `4` |
| `migrations.ttlSecondsAfterFinished` | TTL для очистки Job | `3600` |
| `migrations.restartPolicy` | RestartPolicy для Job Pod | `OnFailure` |
| `migrations.resources` | Resources requests/limits | см. `values.yaml` |

### config (ConfigMap данные)

| Параметр | Переменная | Default |
|---|---|---|
| `config.nodeEnv` | `NODE_ENV` | `production` |
| `config.logLevel` | `LOG_LEVEL` | `info` |
| `config.appVersion` | `APP_VERSION` | `"0.0.1"` |
| `config.server.port` | `PORT` | `"3000"` |
| `config.server.host` | `HOST` | `"0.0.0.0"` |
| `config.server.allowedDomains` | `ALLOWED_DOMAINS` | `""` |
| `config.server.connectionTimeout` | `CONNECTION_TIMEOUT` | `"30000"` |
| `config.server.bodyLimit` | `BODY_LIMIT` | `"1048576"` |
| `config.tokens.accessTokenTtl` | `ACCESS_TOKEN_TTL` | `"3600"` |
| `config.tokens.refreshTokenTtl` | `REFRESH_TOKEN_TTL` | `"2592000"` |
| `config.tokens.sessionTtl` | `SESSION_TTL` | `"2592000"` |
| `config.shutdown.timeout` | `SHUTDOWN_TIMEOUT` | `"30000"` |
| `config.shutdown.drainDelay` | `SHUTDOWN_DRAIN_DELAY` | `"5000"` |
| `config.liquibase.logLevel` | `LIQUIBASE_LOG_LEVEL` | `"INFO"` |

### database (ConfigMap данные)

| Параметр | Переменная | Default |
|---|---|---|
| `database.connection.host` | `POSTGRES_HOST` | `"postgres-db"` |
| `database.connection.port` | `POSTGRES_PORT` | `"5432"` |
| `database.connection.database` | `POSTGRES_DB` | `"seedkey"` |
| `database.connection.ssl` | `POSTGRES_SSL` | `"false"` |
| `database.connection.maxConnections` | `POSTGRES_MAX_CONNECTIONS` | `"20"` |


## FluxCD конфигурация.
Если вы используете FluxCD в своем кластере, ваш HelmRelease может выглядеть как-то так:

```
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: seedkey
  namespace: seed-key
spec:
  interval: 10m
  chart:
    spec:
      chart: seedkey
      version: "0.0.3"
      sourceRef:
        kind: HelmRepository
        name: seedkey
        namespace: flux-system
      interval: 10m
  values:
    global:
      namespace: seed-key

    configMap:
      existingName: "app-config"

    # Конфигурация auth-service
    authService:
      enabled: true
      replicaCount: 1
      serviceAccount:
        create: false
        name: "default"
      
      service:
        type: ClusterIP
        port: 80
        targetPort: 3000
      
      resources:
        requests:
          cpu: 200m
          memory: 256Mi
        limits:
          cpu: 500m
          memory: 512Mi
      
      livenessProbe:
        httpGet:
          path: /
          port: http
        initialDelaySeconds: 15
        periodSeconds: 20
      
      readinessProbe:
        httpGet:
          path: /
          port: http
        initialDelaySeconds: 5
        periodSeconds: 10

    # Конфигурация миграций
    migrations:
      enabled: true

      backoffLimit: 4
      ttlSecondsAfterFinished: 3600
      restartPolicy: OnFailure

    secrets:
      existingSecret: "app-secrets"

```


<a name="contributing"></a>
## 🤝 Контрибьютинг

Если у вас есть идеи и желание сделать вклад в развитие проекта, я буду рад вашим issue или pull request!


## 🔧 Связные проекты
Ознакомьтесь также с другими репозиториями экосистемы:
- [seedkey-browser-extension](https://github.com/mbessarab/seedkey-browser-extension) — браузерное расширение.
- [seedkey-db-migrations](https://github.com/mbessarab/seedkey-db-migrations) — миграции для `seedkey-auth-service`.
- [seedkey-auth-service](https://github.com/mbessarab/seedkey-auth-service) — self-hosted решение в виде готового сервиса.
- [seedkey-server-sdk](https://github.com/mbessarab/seedkey-server-sdk) — библиотека для самостоятельной реализации сервиса.
- [seedkey-client-sdk](https://github.com/mbessarab/seedkey-client-sdk) — библиотека для работы с расширением и отправки запросов на бэкенд.


<a name="license"></a>
## 📄 Лицензия

См. `LICENSE`.
