# monitoring doker
grafana + prometheus


# 📊 Мониторинг: Prometheus + Grafana + Node Exporter

> [!INFO] Описание проекта
> Готовый стек мониторинга для сбора метрик серверов и их визуализации. Разворачивается за 5 минут через Docker Compose.

---

## 🚀 Быстрый старт

### 1. Проверка требований

```bash
# Проверить Docker
docker --version

# Проверить Docker Compose
docker-compose --version

# Проверить свободное место
df -h
```

### 2. Клонирование/Копирование файлов

```bash
# Создать структуру папок
mkdir -p monitoring/prometheus
cd monitoring

# Создать docker-compose.yml
nano docker-compose.yml

# Создать prometheus.yml
nano prometheus/prometheus.yml
```

### 3. Запуск

```bash
# Запустить все сервисы
docker-compose up -d

# Проверить статус
docker-compose ps

# Посмотреть логи
docker-compose logs -f
```

### 4. Доступ к сервисам

| Сервис | URL | Логин/Пароль |
|--------|-----|--------------|
| **Grafana** | `http://localhost:3000` | `admin` / `admin` |
| **Prometheus** | `http://localhost:9090` | — |
| **Node Exporter** | `http://localhost:9100/metrics` | — |

---

## 📁 Структура проекта

```
monitoring/
├── docker-compose.yml          # Конфигурация контейнеров
├── prometheus/
│   └── prometheus.yml          # Настройки сбора метрик
├── README.md                   # Эта инструкция
└── .env                        # Переменные среды (опционально)
```

---

## ⚙️ Файл: docker-compose.yml

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    restart: unless-stopped
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    restart: unless-stopped
    networks:
      - monitoring
    depends_on:
      - prometheus

  node_exporter:
    image: prom/node-exporter:latest
    container_name: node_exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:

networks:
  monitoring:
```

---

## ⚙️ Файл: prometheus/prometheus.yml

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  # Мониторинг самого Prometheus
  - job_name: 'prometheus'
    static_configs:
      targets: ['prometheus:9090']

  # Мониторинг хоста (Windows/Mac)
  - job_name: 'windows'
    static_configs:
      targets: ['host.docker.internal:9100']

  # Мониторинг удалённой машины (Kali/Linux)
  - job_name: 'kali'
    static_configs:
      targets: ['192.168.31.200:9100']
```

> [!WARNING] Важно
> Перед запуском в новой сети **обновите IP-адреса** в разделе `targets`!

---

## 🔧 Настройка Grafana (первый вход)

### Шаг 1: Вход в систему

```
URL: http://localhost:3000
Логин: admin
Пароль: admin
```

### Шаг 2: Добавление DataSource

```
1. ⚙️ Settings (шестерёнка слева)
2. Data Sources → Add data source
3. Выбрать "Prometheus"
4. URL: http://prometheus:9090
5. Save & Test → "Data source is working" ✅
```

### Шаг 3: Импорт дашборда

```
1. 📊 Dashboards → New → Import
2. Ввести ID: 1860 (Node Exporter Full)
3. Выбрать DataSource: Prometheus
4. Import ✅
```

---

## 🌐 Адаптация для новой сети (Колледж/Лаборатория)

### 1. Узнать новую подсеть

```bash
# Linux/Mac
ip addr show

# Windows
ipconfig
```

### 2. Обновить prometheus.yml

```yaml
scrape_configs:
  # ❌ Удалить старые IP
  # - job_name: 'kali'
  #   static_configs:
  #     targets: ['192.168.31.200:9100']
  
  # ✅ Добавить новые IP лаборатории
  - job_name: 'lab_clients'
    static_configs:
      targets:
        - '192.168.50.101:9100'
        - '192.168.50.102:9100'
        - '192.168.50.103:9100'
```

### 3. Перезапустить Prometheus

```bash
docker-compose restart prometheus
```

### 4. Проверить цели

```bash
curl http://localhost:9090/api/v1/targets
# Или в браузере: http://localhost:9090/targets
```

---

## 🖥️ Установка Node Exporter на клиенты

### Linux

```bash
# Скачать
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz

# Распаковать
tar xvfz node_exporter-*.tar.gz
sudo mv node_exporter-*/node_exporter /usr/local/bin/

# Запустить
nohup node_exporter &

# Открыть порт
sudo ufw allow 9100/tcp
```

### Windows

```powershell
# Скачать windows_exporter
# https://github.com/prometheus-community/windows_exporter/releases

# Установить
msiexec /i windows_exporter.msi

# Открыть порт
New-NetFirewallRule -DisplayName "Node Exporter" -Direction Inbound -Protocol TCP -LocalPort 9100 -Action Allow
```

### Проверка клиента

```bash
curl http://<IP_КЛИЕНТА>:9100/metrics
# Должен вернуться текст с метриками
```

---

## ✅ Проверка работоспособности

### 1. Статус контейнеров

```bash
docker-compose ps
```

**Ожидаемый результат:**
```
NAME          STATUS
prometheus    Up
grafana       Up
node_exporter Up
```

### 2. Проверка портов

```bash
netstat -tulpn | grep -E '3000|9090|9100'
```

### 3. Проверка метрик

```bash
# Prometheus
curl http://localhost:9090/api/v1/status

# Node Exporter
curl http://localhost:9100/metrics | head -20

# Grafana
curl http://localhost:3000/api/health
```

### 4. Проверка целей в Prometheus

```bash
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
# Все должны быть "up"
```

---

## 🛠️ Полезные команды

| Команда | Описание |
|---------|----------|
| `docker-compose up -d` | Запуск в фоновом режиме |
| `docker-compose down` | Остановка контейнеров |
| `docker-compose restart` | Перезапуск всех сервисов |
| `docker-compose logs -f` | Просмотр логов в реальном времени |
| `docker-compose ps` | Статус контейнеров |
| `docker-compose exec prometheus sh` | Вход в контейнер Prometheus |

### Очистка данных

```bash
# Остановить и удалить тома (данные будут потеряны!)
docker-compose down -v

# Только контейнеры (данные сохранятся)
docker-compose down
```

---

## ⚠️ Troubleshooting

| Проблема | Решение |
|----------|---------|
| **Контейнеры не стартуют** | `docker-compose logs` — посмотреть ошибку |
| **Цели DOWN в Prometheus** | Проверить фаервол: `sudo ufw status` |
| **Grafana не видит Prometheus** | Проверить URL: `http://prometheus:9090` |
| **Порт занят** | `sudo lsof -i :3000` — найти процесс |
| **Нет данных в Grafana** | Проверить DataSource в настройках |
| **host.docker.internal не работает** | На Linux добавить в docker-compose: `extra_hosts: - "host.docker.internal:host-gateway"` |

### Быстрая диагностика

```bash
# Проверить сеть Docker
docker network inspect monitoring

# Проверить связь между контейнерами
docker exec grafana ping prometheus

# Перезагрузить конфигурацию Prometheus
curl -X POST http://localhost:9090/-/reload
```

---

## 🔐 Безопасность

### Сменить пароль Grafana

```yaml
environment:
  - GF_SECURITY_ADMIN_PASSWORD=<новый_пароль>
```

### Ограничить доступ к портам

```yaml
# Только локальный доступ
ports:
  - "127.0.0.1:3000:3000"
```

### Открыть для локальной сети

```yaml
# Доступ из локальной сети
ports:
  - "0.0.0.0:3000:3000"
```

---

## 📊 Рекомендуемые дашборды

| Название | ID | Описание |
|----------|-----|----------|
| Node Exporter Full | `1860` | Полная статистика сервера |
| Prometheus Stats | `2` | Мониторинг Prometheus |
| Docker Monitoring | `179` | Статистика контейнеров |
| Host Metrics | `13659` | Альтернатива Node Exporter |

---

## 📝 Чек-лист для развёртывания

```
⬜ 1. Проверить Docker и Docker Compose
⬜ 2. Создать структуру папок
⬜ 3. Скопировать docker-compose.yml
⬜ 4. Скопировать prometheus.yml
⬜ 5. Обновить IP-адреса в prometheus.yml
⬜ 6. Запустить: docker-compose up -d
⬜ 7. Проверить: docker-compose ps
⬜ 8. Войти в Grafana: http://localhost:3000
⬜ 9. Добавить DataSource (Prometheus)
⬜ 10. Импортировать дашборд (ID: 1860)
⬜ 11. Проверить targets: http://localhost:9090/targets
⬜ 12. Сменить пароль администратора
```

---

## 📞 Контакты и поддержка

| Ресурс | Ссылка |
|--------|--------|
| Prometheus Docs | https://prometheus.io/docs/ |
| Grafana Docs | https://grafana.com/docs/ |
| Node Exporter | https://github.com/prometheus/node_exporter |
| Docker Compose | https://docs.docker.com/compose/ |

---

> [!TAGS]
> #docker #prometheus #grafana #monitoring #devops #readme #infrastructure

---

**Версия:** 1.0  
**Последнее обновление:** `{{date}}`  
**Статус:** ✅ Готово к использованию  
**Время развёртывания:** 🕐 ~5-10 минут
