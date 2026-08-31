#!/bin/sh
set -e

echo "🔍 Шаг 1: Ждем базу данных..."

# Ждем базу
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DB" > /dev/null 2>&1; do
  echo "⏳ База не готова... ждем 2 сек."
  sleep 2
done

echo "✅ База готова!"

echo "🚀 Шаг 2: Запуск миграций..."
python manage.py migrate --noinput

echo "📦 Шаг 3: Сбор статики (БЕЗ ВОПРОСОВ!)..."
# 👇 ЭТА СТРОКА КРИТИЧНА. Без --noinput будет EOFError 👇
python manage.py collectstatic --noinput

echo "🚀 Шаг 4: Запуск Gunicorn..."
exec gunicorn kittygram_backend.wsgi:application --bind 0.0.0.0:9000