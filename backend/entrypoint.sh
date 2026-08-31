#!/bin/sh
set -e

echo "🔍 Шаг 1: Ожидание готовности базы данных..."

# Ждем, пока pg_isready скажет, что база готова принимать соединения
# Это может занять от 10 до 60 секунд при первом старте
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DB" > /dev/null 2>&1; do
  echo "⏳ База еще не готова... ждем 2 секунды."
  sleep 2
done

echo "✅ База готова! Начинаем подготовку."

# ---------------------------------------------------------
# ВАЖНО: ОЧИСТКА СХЕМЫ ДЛЯ ИСПРАВЛЕНИЯ ОШИБКИ DUPLICATE KEY
# ---------------------------------------------------------
echo "🧹 Шаг 2: Очистка схемы базы данных (удаление старых объектов)..."

# Используем psql для удаления схемы public со всеми объектами (CASCADE)
# Это решает проблему с "duplicate key value violates unique constraint"
# PGPASSWORD нужен, так как psql не принимает пароль через переменную окружения иначе в одной строке
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DB" -c "DROP SCHEMA IF EXISTS public CASCADE;"

# Создаем схему заново (она обязательна для работы)
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DB" -c "CREATE SCHEMA IF NOT EXISTS public;"

echo "🧹 Очистка завершена. Схема создана заново."

# ---------------------------------------------------------
# ДАЛЕЕ СТАНДАРТНЫЕ ДЕЙСТВИЯ
# ---------------------------------------------------------

echo "🚀 Шаг 3: Запуск миграций Django..."
python manage.py migrate --noinput

echo "📦 Шаг 4: Сбор статических файлов..."
# --noinput критически важен, чтобы избежать ошибки EOFError
python manage.py collectstatic --noinput

echo "🚀 Шаг 5: Запуск Gunicorn..."
exec gunicorn kittygram.wsgi:application --bind 0.0.0.0:9000