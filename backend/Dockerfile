FROM python:3.12-slim

# Устанавливаем рабочую директорию внутри контейнера
WORKDIR /app

# --- СИСТЕМНЫЕ ЗАВИСИМОСТИ ---
# Это критически важно! 
# 1. libpq-dev и postgresql-client нужны, чтобы внутри контейнера работал pg_isready (для entrypoint.sh)
#    и чтобы корректно собрался драйвер psycopg2 для Django.
# 2. gcc нужен для компиляции некоторых Python-библиотек (например, psycopg2 или cryptography).
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# --- УСТАНОВКА PYTHON-ЗАВИСИМОСТЕЙ ---
# Сначала копируем requirements.txt, чтобы использовать кэш Docker.
# Если ты меняешь код, но не меняешь зависимости, Docker не будет заново качать пакеты.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- КОПИРОВАНИЕ КОДА И СКРИПТА ---
# Копируем весь исходный код проекта в контейнер
COPY . .

# Копируем наш скрипт-обертку и делаем его исполняемым
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]