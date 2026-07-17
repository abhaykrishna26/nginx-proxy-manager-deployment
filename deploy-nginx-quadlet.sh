#!/bin/bash
# ┌──────────────────────────────────────────────┐
# │ Rootless Podman Quadlet: Nginx Proxy Manager │
# └──────────────────────────────────────────────┘

set -euo pipefail
IFS=$'\n\t'

# ────────────────────────────────────────────────
# 1. Configuration
# ────────────────────────────────────────────────
APP_NAME="nginx"
NGINX_PROXY_MANAGER_VERSION="2.13.5"
NETWORK_NAME="nginx-nw"

QUADLET_DIR="$HOME/.config/containers/systemd/nginx"
NGINX_DATA="nginx-data"
LETSENCRYPT_DATA="nginx-letsencrypt"

echo "🚀 Starting deployment for $APP_NAME"

# ────────────────────────────────────────────────
# 2. Directory Setup
# ────────────────────────────────────────────────
mkdir -p "$QUADLET_DIR"

# ────────────────────────────────────────────────
# 3. Create Podman Volumes (Idempotent)
# ────────────────────────────────────────────────
for VOL in "$NGINX_DATA" "$LETSENCRYPT_DATA"; do
    if ! podman volume exists "$VOL"; then
        echo "📦 Creating volume: $VOL"
        podman volume create "$VOL" >/dev/null
    else
        echo "ℹ️ Volume $VOL already exists"
    fi
done

# ────────────────────────────────────────────────
# 4. Quadlet Files Creation (.volume + .container)
# ────────────────────────────────────────────────
echo "📁 Generating Quadlet files in $QUADLET_DIR"

############################
#     Volume Quadlets      #
############################

cat > "$QUADLET_DIR/$NGINX_DATA.volume" <<EOF
[Volume]
VolumeName=$NGINX_DATA

[Install]
WantedBy=default.target
EOF

cat > "$QUADLET_DIR/$LETSENCRYPT_DATA.volume" <<EOF
[Volume]
VolumeName=$LETSENCRYPT_DATA

[Install]
WantedBy=default.target
EOF


############################
#   Container Quadlet      #
############################

cat > "$QUADLET_DIR/$APP_NAME.container" <<EOF
[Unit]
Description=Nginx Proxy Manager Container
Requires=$NGINX_DATA.volume $LETSENCRYPT_DATA.volume
After=$NGINX_DATA.volume $LETSENCRYPT_DATA.volume

[Container]
ContainerName=nginx
Image=docker.io/jc21/nginx-proxy-manager:$NGINX_PROXY_MANAGER_VERSION
Network=$NETWORK_NAME

# Quadlet-managed volumes
Volume=$NGINX_DATA:/data
Volume=$LETSENCRYPT_DATA:/etc/letsencrypt

Environment=DISABLE_IPV6=true

PublishPort=80:80
PublishPort=443:443
PublishPort=81:81

AutoUpdate=registry

[Service]
Restart=unless-stopped

[Install]
WantedBy=default.target
EOF

# ────────────────────────────────────────────────
# 5. Podman Network Creation (idempotent)
# ────────────────────────────────────────────────
if ! podman network exists "$NETWORK_NAME" 2>/dev/null; then
    echo "🌐 Creating Podman network: $NETWORK_NAME"
    podman network create "$NETWORK_NAME" >/dev/null
else
    echo "ℹ️ Podman network '$NETWORK_NAME' already exists"
fi

# ────────────────────────────────────────────────
# 6. Reload Systemd Daemon & Start Services
# ────────────────────────────────────────────────
echo "🔄 Reloading systemd user daemon…"
systemctl --user daemon-reexec >/dev/null
systemctl --user daemon-reload >/dev/null

echo "🚀 Enabling & starting Quadlet volume units…"
systemctl --user enable --now "$NGINX_DATA.volume" "$LETSENCRYPT_DATA.volume" >/dev/null || true

echo "🚀 Starting $APP_NAME container via systemd…"
systemctl --user enable --now "$APP_NAME" 2>/dev/null || echo "ℹ️  enabled $APP_NAME"
systemctl --user start "$APP_NAME" >/dev/null || true
sleep 8
systemctl --user restart "$APP_NAME" >/dev/null || true
sleep 8

if systemctl --user is-active --quiet "$APP_NAME"; then
    echo "✅ $APP_NAME is running successfully!"
else
    echo "❌ Failed to start $APP_NAME."
    echo "   Check logs: podman logs $APP_NAME"
    echo "   Check Status: systemctl --user status $APP_NAME"
    exit 1
fi

# ────────────────────────────────────────────────
# 7. Final Output
# ────────────────────────────────────────────────
echo
echo "🌐 Access Nginx Proxy Manager:"
echo "   → http://<your-host>:81"
echo
echo "🗂 Default credentials:"
echo "   admin@example.com / changeme"
echo
echo "🎉 Deployment complete!"
