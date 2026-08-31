#!/bin/sh
set -e

echo "🔍 Проверка подключения к базе данных..."

# Цикл ожидания: pg_isready вернёт 0, если база готова
# Флаг -h: хост, -p: порт, -U: пользователь, -d: имя базы
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DB"; do
  echo "⏳ База данных ещё не готова... ждём 2 секунды."
  sleep 2
done

echo "✅ База данных готова!"

# Запуск миграций
echo "🚀 Запуск миграций Django..."
python manage.py migrate --noinput

# Сбор статических файлов
echo "📦 Сбор статических файлов..."
python manage.py collectstatic --noinput

# Запуск сервера (Gunicorn)
echo "🚀 Запуск Gunicorn..."
exec gunicorn kittygram.wsgi:application --bind 0.0.0.0:9000