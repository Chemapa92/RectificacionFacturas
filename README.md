# RectificaciónFacturas (Salesforce DX)

Proyecto SFDX para trabajar en sandbox y versionar cambios con GitHub.

## Requisitos
- Node 18+
- Salesforce CLI (sf) o SFDX CLI
- Git

## Setup rápido
```bash
# Autenticar sandbox
sf org login sandbox --alias devSandbox --set-default

# Recuperar fuentes (source tracking)
sf project retrieve start --source-dir force-app --wait 10

# Validar en sandbox
sf project deploy validate --target-org devSandbox --test-level RunLocalTests
```

## Flujo recomendado
- Trabajar en ramas feature/* y abrir PR a main.
- Usar `sf project deploy start` para subir cambios a sandbox.
- Usar GitHub Actions para validaciones automáticas.
