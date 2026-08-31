#!/bin/sh
set -e

echo "🔍 Начинаем проверку готовности базы данных..."

# Бесконечный цикл ожидания. База должна ответить на pg_isready.
# Мы не ограничиваем количество попыток, чтобы точно дождаться старта.
while ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DB" > /dev/null 2>&1; do
  echo "⏳ База данных еще не готова... ждем 1 секунду."
  sleep 1
done

echo "✅ База данных готова! Продолжаем..."

# Запуск миграций
echo "🚀 Запуск миграций Django..."
python manage.py migrate --noinput

# Сбор статики (--noinput критически важен, чтобы не было EOFError)
echo "📦 Сбор статических файлов..."
python manage.py collectstatic --noinput

# Запуск Gunicorn
echo "🚀 Запуск Gunicorn..."
exec gunicorn kittygram.wsgi:application --bind 0.0.0.0:8000