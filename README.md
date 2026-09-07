# PM-B Infrastructure

Déploiement et infrastructure du gestionnaire de projet **PM-B** sur **Hetzner Cloud**, avec **Terraform**, **Ansible** et **Docker Compose**.

## 🏗️ Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Frontend   │     │   Backend   │     │  IA Service │
│  (Nginx)    │────▶│ (Spring)    │────▶│  (FastAPI)  │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                    ┌──────▼──────┐
                    │ PostgreSQL  │
                    └─────────────┘
```

Trois serveurs applicatifs + un serveur de base de données, provisionnés sur Hetzner Cloud.

## 🛠️ Outils

- **Terraform** : provisionnement des serveurs Hetzner Cloud (VMs, firewalls, clés SSH)
- **Ansible** : configuration des serveurs (Docker, PostgreSQL, déploiement des conteneurs)
- **Docker Compose** : orchestration des conteneurs (backend, frontend, IA)
- **GitHub Actions** : CI/CD automatisé

## 📁 Structure

```
├── terraform/          # Provisionnement Hetzner Cloud
│   ├── main.tf         # Ressources (VMs, firewalls, SSH keys)
│   ├── variables.tf    # Variables (token, chemins SSH)
│   └── outputs.tf      # Sorties (IPs publiques)
├── ansible/            # Configuration des serveurs
│   ├── site.yml        # Playbook principal
│   └── roles/          # Rôles (common, docker, app, db, ia)
├── compose/            # Fichiers Docker Compose
│   ├── docker-compose.yml      # Backend + frontend
│   └── docker-compose.ia.yml   # Service IA
└── .github/workflows/  # CI/CD
```

## 🚀 Déploiement

### 1. Provisionner les serveurs (Terraform)

```bash
cd terraform
terraform init
terraform apply
```

### 2. Configurer les serveurs (Ansible)

```bash
cd ansible
ansible-playbook -i inventory.ini site.yml
```

### 3. Déployer les conteneurs (Docker Compose)

Les fichiers d'environnement (`backend.env`, `ia.env`) sont copiés depuis les `.example` et renseignés avant déploiement.

## 🔐 Configuration

Copiez les fichiers `.example` et renseignez vos secrets :

| Fichier | Contenu |
|---------|---------|
| `backend.env` | JWT, base de données, SMTP |
| `ia.env` | Clé OpenRouter, clé de chiffrement |
| `terraform/terraform.tfvars` | Token Hetzner, chemins SSH |

> ⚠️ Ces fichiers contiennent des secrets et ne doivent **jamais** être commités.

## 🔗 Projets liés

- [PM-B-backend](https://github.com/jadliaissam-edu/PM-B-backend) — API Spring Boot
- [PM-B-frontend](https://github.com/jadliaissam-edu/PM-B-frontend) — interface React
- [PM-B-ia](https://github.com/jadliaissam-edu/PM-B-ia) — service d'intelligence artificielle
