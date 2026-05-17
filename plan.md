Plan de deploiement (simple et propre)

Objectif
Deployer une application Fullstack (Spring Boot + React) sur Hetzner Cloud avec IaC (Terraform) et configuration automatisee (Ansible).

Architecture cible
- 1 Load Balancer
- 2 serveurs App (haute disponibilite)
- 1 serveur DB (dedie)

Phase 0 - Preparation locale
- Installer Terraform, Ansible, OpenSSH
- Creer une cle SSH dediee au projet
- Definir un fichier .env local pour les secrets
- Verifier l acces a Hetzner (token API)

Phase 1 - Terraform (Infrastructure Hetzner)
- Creer les ressources:
	- 1 Load Balancer
	- 2 VPS App (Ubuntu)
	- 1 VPS DB (Ubuntu)
- Ajouter les SSH keys
- Configurer les Firewalls (ports stricts)
- Exporter les outputs: IP publiques/privées + IP LB

Phase 2 - Ansible (Configuration serveur)
- Roles simples:
	- common: users, SSH hardening, UFW
	- docker: Docker + Docker Compose
	- app: deployment compose, env, services
	- db: installation et securite DB
- Inventaire base sur les outputs Terraform

Phase 3 - Docker/Compose (Application)
- Backend Spring Boot: Dockerfile simple
- Frontend React: build statique servi par Nginx
- docker-compose.yml reutilisable pour les 2 serveurs App
- Variables d environnement via .env

Phase 4 - Deploiement
- Terraform: init, plan, apply
- Ansible: site.yml
- App: docker compose up -d

Phase 5 - Verification minimale
- Health checks via Load Balancer
- Logs Docker

Decoupage recommande (simple)
- infra/terraform/
- infra/ansible/
- deploy/compose/

Note
- HTTPS et domaine plus tard (apres validation HTTP)
