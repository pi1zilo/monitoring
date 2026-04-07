#!/usr/bin/env bash
set -euo pipefail

# === НАСТРОЙКИ ===
NODE_EXPORTER_VERSION="1.8.2" # Обновите при выходе новой версии
INSTALL_DIR="/usr/local/bin"
SERVICE_NAME="node_exporter"
USERNAME="node_exporter"

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   echo "Скрипт требует прав root. Запустите: sudo bash $0"
   exit 1
fi

# Проверка systemd
if ! command -v systemctl &> /dev/null; then
   echo "Скрипт требует systemd. Установите вручную."
   exit 1
fi

# Определение архитектуры
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)  ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "❌ Неподдерживаемая архитектура: $ARCH"; exit 1 ;;
esac

# Очистка временных файлов при выходе
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Установка Prometheus Node Exporter v${NODE_EXPORTER_VERSION}..."

# Скачивание
FILENAME="node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}.tar.gz"
URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${FILENAME}"
echo "⬇️  Загрузка: ${FILENAME}"
curl -fsSL "$URL" -o "${TMP_DIR}/${FILENAME}"

# Распаковка
echo "Распаковка..."
tar xzf "${TMP_DIR}/${FILENAME}" -C "${TMP_DIR}"
BINARY="${TMP_DIR}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}/node_exporter"

# Создание пользователя
if ! id -u "$USERNAME" &>/dev/null; then
   echo "Создание системного пользователя '${USERNAME}'..."
   useradd --no-create-home --shell /bin/false "$USERNAME"
fi

# Установка бинарника
echo "Установка в ${INSTALL_DIR}..."
cp "$BINARY" "${INSTALL_DIR}/node_exporter"
chown "${USERNAME}:${USERNAME}" "${INSTALL_DIR}/node_exporter"
chmod 755 "${INSTALL_DIR}/node_exporter"

# Создание systemd-службы
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
echo "Настройка systemd..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=${USERNAME}
Group=${USERNAME}
Type=simple
ExecStart=${INSTALL_DIR}/node_exporter
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Активация и запуск
echo "Включение и запуск службы..."
systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"

# Проверка
sleep 2
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "Node Exporter успешно установлен и работает!"
    echo "Метрики: http://localhost:9100/metrics"
    echo "Статус: systemctl status ${SERVICE_NAME}"
    echo "Совет: закройте порт 9100 фаерволом для внешних IP."
else
    echo "Ошибка запуска. Логи: journalctl -u ${SERVICE_NAME} -f"
    exit 1
fi