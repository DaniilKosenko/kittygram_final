#!/bin/sh
set -e

echo "🔍 Шаг 1: Ждем, пока база данных станет доступна..."

# Ждем до 120 секунд (2 минуты), пока pg_isready не скажет ОК
for i in $(seq 1 120); do
  if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DB" > /dev/null 2>&1; then
    echo "✅ База готова!"
    break
  else
    echo "⏳ База не готова (попытка $i/120)... ждем 2 сек."
    sleep 2
  fi
done

# Финальная проверка
if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DB" > /dev/null 2>&1; then
  echo "❌ Критическая ошибка: База не запустилась за 2 минуты."
  exit 1
fi

echo "🚀 Шаг 2: Запуск миграций Django..."
# Миграции сами создадут таблицу django_migrations, если её нет.
# Если есть конфликт - мы его решим вручную.
python manage.py migrate --noinput

echo "📦 Шаг 3: Сбор статики..."
python manage.py collectstatic --noinput

echo "🚀 Шаг 4: Запуск Gunicorn..."
exec gunicorn kittygram_backend.wsgi:application --bind 0.0.0.0:9000