# SeedKey Helm Chart

## Table of Contents
- [What the Chart Deploys](#what-the-chart-deploys)
- [Namespace: Important Nuance](#namespace-important-nuance)
- [Installation](#installation)
- [Upgrade](#upgrade)
- [Uninstallation](#uninstallation)
- [Configuration](#configuration)
- [Values](#values)
- [FluxCD Configuration](#fluxcd-configuration)
- [🤝 Contributing](#-contributing)
- [🔧 Related Projects](#-related-projects)
- [📄 License](#-license)

Helm chart for deploying **seedkey-auth-service** and **seedkey-db-migrations**.

## What the Chart Deploys

- `Deployment` for `auth-service` (if `authService.enabled=true`)
- `Service` for `auth-service`
- `Job` for migrations (Liquibase) as a Helm hook `pre-install, pre-upgrade` (if `migrations.enabled=true`)
- `ConfigMap` with environment variables, if `configMap.existingName` is not set
- `ServiceAccount` (optional)
- `Namespace` (optional)

## Namespace: Important Nuance

The chart calculates the resource namespace as follows:

- if `global.namespace` is set → resources are created in it
- otherwise if `namespace.name` is set → resources are created in it
- otherwise → resources are created in `.Release.Namespace`

Note that the **Namespace resource is only created based on `namespace.*`**, and only if `namespace.name != .Release.Namespace`.

Recommendation:

- either use `helm ... --namespace <ns> --create-namespace` and don't touch `global.namespace`
- or set **both**: `namespace.name` and `global.namespace` to the same value (if you want the chart to create the Namespace itself)

## Installation

### 1) Prepare Secret

Set `secrets.existingSecret` and create a Secret with the required keys.

Required keys for `auth-service`:

- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `JWT_SECRET`

Keys for migrations (Liquibase):

- `LIQUIBASE_COMMAND_URL`
- `LIQUIBASE_COMMAND_USERNAME`
- `LIQUIBASE_COMMAND_PASSWORD`

### 2) Install the Chart

```bash
helm install seedkey ./helm-chart \
  --namespace seedkey --create-namespace \
  --set secrets.existingSecret=seedkey-secrets
```

### Check Status

```bash
kubectl get pods -n seedkey
kubectl get svc -n seedkey
kubectl get jobs -n seedkey -l app.kubernetes.io/component=migrations
kubectl logs -n seedkey -l app.kubernetes.io/component=auth-service
```

## Upgrade

```bash
helm upgrade seedkey ./helm-chart \
  --namespace seedkey \
  --set secrets.existingSecret=seedkey-secrets
```

## Uninstallation

```bash
helm uninstall seedkey --namespace seedkey
```

> The Namespace is deleted **only if you delete it separately**.

## Configuration

### Database Connection

Connection parameters are set in `database.connection.*` and end up in the `ConfigMap`:

- `database.connection.host` (default: `postgres-db`)
- `database.connection.port` (default: `5432`)
- `database.connection.database` (default: `seedkey`)
- `database.connection.ssl` (default: `"false"`)
- `database.connection.maxConnections` (default: `"20"`)

### Using an Existing ConfigMap

If you want to fully manage environment variables via your own ConfigMap:

```bash
helm upgrade --install seedkey ./helm-chart \
  --namespace seedkey \
  --set configMap.existingName=my-seedkey-config \
  --set secrets.existingSecret=seedkey-secrets
```

In this mode, the chart **does not create** its own ConfigMap.

### Migrations Job (Liquibase)

Parameters:

- `migrations.backoffLimit` — number of retries
- `migrations.ttlSecondsAfterFinished` — auto-cleanup of the Job after completion
- `migrations.restartPolicy` — restart policy for the Pod in the Job

## Values

### General

| Parameter | Description | Default |
|---|---|---|
| `global.namespace` | Namespace for all chart resources | `"seedkey"` |
| `namespace.create` | Create Namespace resource by the chart | `true` |
| `namespace.name` | Namespace name for creation (and alternative for resource placement if `global.namespace` is not set) | `"seedkey"` |
| `configMap.existingName` | Use existing ConfigMap instead of generating one | `""` |
| `secrets.existingSecret` | Secret with DB credentials and `JWT_SECRET`/Liquibase env | `""` |

### auth-service

| Parameter | Description | Default |
|---|---|---|
| `authService.enabled` | Enable `auth-service` deployment | `true` |
| `authService.replicaCount` | Number of replicas | `1` |
| `authService.service.type` | Service type | `ClusterIP` |
| `authService.service.port` | Service port | `80` |
| `authService.service.targetPort` | Container port | `3000` |

### migrations

| Parameter | Description | Default |
|---|---|---|
| `migrations.enabled` | Enable migrations | `true` |
| `migrations.backoffLimit` | Job backoff limit | `4` |
| `migrations.ttlSecondsAfterFinished` | TTL for Job cleanup | `3600` |
| `migrations.restartPolicy` | RestartPolicy for Job Pod | `OnFailure` |
| `migrations.resources` | Resources requests/limits | see `values.yaml` |

### config (ConfigMap data)

| Parameter | Variable | Default |
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

### database (ConfigMap data)

| Parameter | Variable | Default |
|---|---|---|
| `database.connection.host` | `POSTGRES_HOST` | `"postgres-db"` |
| `database.connection.port` | `POSTGRES_PORT` | `"5432"` |
| `database.connection.database` | `POSTGRES_DB` | `"seedkey"` |
| `database.connection.ssl` | `POSTGRES_SSL` | `"false"` |
| `database.connection.maxConnections` | `POSTGRES_MAX_CONNECTIONS` | `"20"` |

## FluxCD Configuration

If you use FluxCD in your cluster, your HelmRelease might look something like this:

```yaml
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

    # auth-service configuration
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

    # migrations configuration
    migrations:
      enabled: true

      backoffLimit: 4
      ttlSecondsAfterFinished: 3600
      restartPolicy: OnFailure

    secrets:
      existingSecret: "app-secrets"
```

<a name="contributing"></a>
## 🤝 Contributing

If you have ideas and a desire to contribute to the project's development, I would be happy to see your issues or pull requests!

## 🔧 Related Projects

Check out other repositories in the ecosystem:
- [seedkey-browser-extension](https://github.com/mbessarab/seedkey-browser-extension) — browser extension.
- [seedkey-db-migrations](https://github.com/mbessarab/seedkey-db-migrations) — migrations for `seedkey-auth-service`.
- [seedkey-auth-service](https://github.com/mbessarab/seedkey-auth-service) — self-hosted solution as a ready-made service.
- [seedkey-server-sdk](https://github.com/mbessarab/seedkey-server-sdk) — library for self-implementation of the service.
- [seedkey-client-sdk](https://github.com/mbessarab/seedkey-client-sdk) — library for working with the extension and sending requests to the backend.

<a name="license"></a>
## 📄 License

See `LICENSE`.
