## 🚀 Nginx Proxy Manager Deployment Guide


## 📁 Folder Structure

```
LAB/
└── nginx-proxy-manager/
    ├── deploy-nginx-quadlet.sh
    ├── install-podman.sh
    └── README.md
```

Deploy **Nginx Proxy Manager** using rootless Podman Quadlets.

## ⭐ Features

* Creates Podman volumes for configuration and SSL certificates
* Quadlet-managed Nginx container
* Opens ports **80**, **443**, and **81** (firewalld-aware)
* Auto-update enabled

## 📦 Components

- jc21/nginx-proxy-manager container
- Podman network (`nginx-nw`)
- Persistent volumes:
  - `nginx-data`
  - `nginx-letsencrypt`


# The script:

## install-podman.sh
   1. Install Podman 
   2. Opens ports (80 / 443 / 81)  

## deploy-nginx-quadlet.sh
   1. Creates Podman volumes  
   2. Creates Quadlet unit 
   3. Starts nginx service  


# 💻 Quick Start

## Run:

```bash
chmod +x install-podman.sh deploy-nginx-quadlet.sh
bash install-podman.sh
bash deploy-nginx-quadlet.sh
podman ps
```
## Access:
```
http://<server-ip>:81
```

## Default login:
```
admin@example.com / changeme
```

## Steps to Create SSL Certificate in Nginx Proxy Manager Web UI

1. Go to **SSL Certificates → Add SSL Certificate**
2. Choose **Request a new SSL Certificate**
3. Fill in:
   - **Domain Names**: `app.example.com`
   - **Email Address**: for Let’s Encrypt notifications
4. Enable:
   - Force SSL
   - HTTP/2 Support
   - HSTS Enabled (optional)
5. Click **Save**
6. Nginx Proxy Manager will automatically request and apply a Let’s Encrypt certificate.

## 💾 Backup & Restore

## 📥 Backup Nginx Proxy Manager Volume Data

```bash
podman volume export nginx-data > nginx-data.tar
podman volume export nginx-letsencrypt > nginx-letsencrypt.tar
```

## ♻️ Restore Nginx Proxy Manager Data

```bash
podman volume import nginx-data nginx-data.tar
podman volume import nginx-letsencrypt nginx-letsencrypt.tar
```

Restart:
```bash
systemctl --user restart nginx
```


## ⬆️ Upgrade Guide

1. Edit `nginx.container`  
   Update to new image tag (optional):
   ```
   Image=docker.io/jc21/nginx-proxy-manager:2.13.5
   ```

2. Reload Quadlet:
   ```bash
   systemctl --user daemon-reload
   ```

3. Restart:
   ```bash
   systemctl --user restart nginx
   ```


## 🧐 Inspect Podman Volumes

```bash
# List All Volumes
podman volume ls

#Inspect a Specific Volume
podman volume inspect <volume_name> | grep Mountpoint

#Example:
podman volume inspect nginx-data | grep Mountpoint
ls -l /var/lib/containers/storage/volumes/nginx-data/_data
```

## 👀 Check Status

```bash
systemctl --user status nginx
podman ps
```


## ❌ Full Uninstall Instructions

```bash
systemctl --user disable --now nginx
systemctl --user stop nginx
rm -rf ~/.config/containers/systemd/nginx/
podman volume rm nginx-data nginx-letsencrypt
podman network rm nginx-nw
```
