# 🖥️ Monitoring Stack

> Готовый стек мониторинга на базе **Prometheus + Grafana + Node Exporter** для быстрого развёртывания и анализа метрик

[![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker)](https://docs.docker.com/compose/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Metrics-e6522c?logo=prometheus)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-Dashboards-f46800?logo=grafana)](https://grafana.com/)

---

## 📋 О проекте

Этот репозиторий содержит минимальную, но полностью готовую к работе конфигурацию системы мониторинга. Она позволяет:

* 📊 собирать метрики с серверов
* 📈 визуализировать данные через удобные дашборды
* 🚨 закладывать основу для алертинга

Подходит для:

* 🏠 HomeLab-инфраструктуры
* 🧪 тестовых и учебных окружений
* 🚀 быстрого старта небольших проектов

---

## 🧩 Состав стека

| Сервис            | Порт   | Описание                                        |
| ----------------- | ------ | ----------------------------------------------- |
| **Prometheus**    | `9090` | Сбор, хранение и обработка метрик (TSDB)        |
| **Grafana**       | `3000` | Визуализация, дашборды и алерты                 |
| **Node Exporter** | `9100` | Сбор системных метрик (CPU, RAM, Disk, Network) |

---

## 🚀 Быстрый старт

### Требования

* Установленные Docker и Docker Compose
* ≥ 2 ГБ оперативной памяти
* ОС: Linux / macOS / Windows (WSL2)

### Установка

```bash
# Клонирование репозитория
git clone https://github.com/pi1zilo/monitoring.git
cd monitoring

# Настройка (см. раздел ниже)

# Запуск
docker-compose up -d

# Проверка
docker-compose ps
```

---

## 🔑 Доступ к сервисам

| Сервис            | Адрес                                                          | Данные для входа   |
| ----------------- | -------------------------------------------------------------- | ------------------ |
| **Grafana**       | [http://localhost:3000](http://localhost:3000)                 | `admin / admin` ⚠️ |
| **Prometheus**    | [http://localhost:9090](http://localhost:9090)                 | без авторизации    |
| **Node Exporter** | [http://localhost:9100/metrics](http://localhost:9100/metrics) | только метрики     |

> ⚠️ После первого входа в Grafana обязательно смените пароль.

---

## ⚙️ Конфигурация

### Добавление целей (targets) в Prometheus

Отредактируйте файл:

```
prometheus/prometheus.yml
```

Пример:

```yaml
- job_name: 'node'
  static_configs:
    - targets: ['x.x.x.x:9100']
```

Чтобы добавить новый хост — просто продублируйте блок с другим IP и именем.

> 📌 На каждом целевом сервере должен быть установлен и запущен Node Exporter.

---

## 📥 Установка Node Exporter (на целевые хосты)

> ⚠️ **Node Exporter должен быть установлен на каждом сервере, метрики которого вы хотите собирать.**

### 🔹 Способ 1: Автоматически (скрипт) — Рекомендуется

```bash
# Скачиваем скрипт установки
curl -fsSL https://raw.githubusercontent.com/pi1zilo/monitoring/main//install-node-exporter.sh

# Делаем исполняемым и запускаем
chmod +x install-node-exporter.sh
sudo bash install-node-exporter.sh
```

✅ Скрипт автоматически:
* Определит архитектуру системы
* Скачает актуальный бинарник с GitHub
* Создаст systemd-службу и включит автозапуск
* Запустит Node Exporter на порту `9100`

> 📄 Исходный код скрипта: [`install-node-exporter.sh`](install-node-exporter.sh)

---

### 🔹 Способ 2: Вручную (бинарный файл)

```bash
# 1. Создаём пользователя
sudo useradd --no-create-home --shell /bin/false node_exporter

# 2. Скачиваем и распаковываем (замените версию при необходимости)
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xzf node_exporter-*.tar.gz
sudo cp node_exporter-*/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# 3. Создаём systemd-юнит
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 4. Запускаем
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
```

---

### ✅ Проверка установки

```bash
# Статус службы
systemctl status node_exporter

# Проверка метрик (должны увидеть вывод)
curl -s http://localhost:9100/metrics | head -n 10
```

---


### Безопасность Grafana

В `docker-compose.yml` задайте свои учётные данные:

```yaml
environment:
  - GF_SECURITY_ADMIN_USER=your_user
  - GF_SECURITY_ADMIN_PASSWORD=your_password
```

---

### Работа с данными (Volumes)

```bash
# Список томов
docker volume ls | grep monitoring

# Бэкап Prometheus
docker run --rm \
  -v monitoring_prometheus_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/prometheus_backup.tar.gz -C /data .
```

---

## 📊 Дашборд

В проект уже включён готовый дашборд:

📁 `grafana/dashboards/Node Exporter Full.json`

### Возможности:

* CPU, RAM, SWAP, Disk, Uptime
* Детальные графики загрузки системы
* Метрики дисков (IOPS, latency, usage)
* Сетевой трафик и ошибки
* TCP/UDP состояния
* PSI (при поддержке ядра)

### Импорт:

1. Grafana → Dashboards → Import
2. Upload JSON
3. Выбрать `Node Exporter Full.json`
4. Указать источник данных Prometheus

> 💡 Дашборд автоматически импортируется через provisioning при первом запуске.

---

## 🛠️ Полезные команды

```bash
# Логи
docker-compose logs -f prometheus
docker-compose logs -f grafana

# Перезапуск
docker-compose restart grafana

# Остановка
docker-compose down

# Полное удаление (с данными)
docker-compose down -v
```

---

## 🔍 Примеры PromQL

```promql
# CPU (среднее за 5 минут)
100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Использование памяти (%)
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Свободное место (GB)
node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} / 1024^3

# Входящий трафик
irate(node_network_receive_bytes_total[5m])
```

---

## ⚠️ Рекомендации по безопасности

* Не используйте дефолтные пароли
* Ограничьте доступ к портам (9090, 3000, 9100)
* Настройте HTTPS (Nginx / Traefik)
* Добавьте аутентификацию для Prometheus
* Регулярно обновляйте образы:

```bash
docker-compose pull && docker-compose up -d
```

---

## 🐛 Troubleshooting

| Проблема                    | Решение                                             |
| --------------------------- | --------------------------------------------------- |
| Grafana не открывается      | Проверить `docker-compose logs grafana` и порт 3000 |
| Нет метрик                  | Проверить `/api/v1/targets` в Prometheus            |
| Высокое потребление памяти  | Настроить `retention_time`                          |
| Нет доступа к Node Exporter | Проверить firewall (`9100`)                         |

---

## 📁 Структура проекта

```
monitoring/
├── docker-compose.yml
├── prometheus/
│   ├── prometheus.yml
│   └── rules/
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   └── dashboards/
│   └── dashboards/
│       └── Node Exporter Full.json
└── .gitignore
```


