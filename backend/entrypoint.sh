#!/bin/sh
set -e

echo "🔍 Ждем базу данных..."

# 1. Ждем базу
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DB" > /dev/null 2>&1; do
  echo "⏳ База не готова... ждем 2 сек."
  sleep 2
done

echo "✅ База готова!"

# 2. Миграции (--noinput здесь тоже хорош, но migrate сам не спрашивает)
echo "🚀 Запуск миграций..."
python manage.py migrate --noinput

# 3. СБОР СТАТИКИ (САМОЕ ВАЖНОЕ МЕСТО!)
echo "📦 Сбор статических файлов..."
# 👇 ОБЯЗАТЕЛЬНО добавь --noinput, иначе будет EOFError 👇
python manage.py collectstatic --noinput

# 4. Запуск Gunicorn
echo "🚀 Запуск Gunicorn..."
exec gunicorn kittygram_backend.wsgi:application --bind 0.0.0.0:9000