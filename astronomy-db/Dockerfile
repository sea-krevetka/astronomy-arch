# Используем официальный образ PostgreSQL
FROM postgres:15-alpine

# Устанавливаем необходимые пакеты (опционально)
RUN apk add --no-cache \
    postgresql-contrib \
    bash \
    && rm -rf /var/cache/apk/*

# Создаем директорию для скриптов инициализации
WORKDIR /docker-entrypoint-initdb.d

# Копируем SQL-скрипт инициализации
COPY init.sql /docker-entrypoint-initdb.d/01-init.sql

# Создаем директорию для бэкапов
RUN mkdir -p /var/backups/postgresql && chown postgres:postgres /var/backups/postgresql

# Добавляем скрипт для автоматического бэкапа (опционально)
COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

# Устанавливаем пользователя postgres
USER postgres

# Метка для версионирования
LABEL version="1.0"
LABEL description="PostgreSQL with Astronomy Database"