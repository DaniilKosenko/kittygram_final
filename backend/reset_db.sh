#!/bin/sh
set -e

echo "🧹 Запуск очистки базы данных..."

# Ждем, пока база станет готова принимать соединения
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DB"; do
  echo "⏳ Ждем базу данных..."
  sleep 2
done

echo "✅ База готова. Начинаем очистку..."

# Подключаемся к базе и удаляем схему public (или ту, где лежат миграции)
# Мы используем psql для выполнения команды DROP SCHEMA
# Если схема public не существует, флаг IF EXISTS предотвратит ошибку
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DB" -c "DROP SCHEMA IF EXISTS public CASCADE;"

# Теперь создаем схему заново (она нужна для работы)
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DB" -c "CREATE SCHEMA IF NOT EXISTS public;"

echo "🧹 Очистка завершена!"