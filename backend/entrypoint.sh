#!/bin/sh
set -e

echo "🔍 Начинаем проверку готовности базы данных..."

# Увеличиваем количество попыток и время ожидания.
# pg_isready будет стучаться каждые 2 секунды.
# Мы даем базе до 60 секунд на старт (30 попыток * 2 сек).
for i in $(seq 1 30); do
  if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DB" > /dev/null 2>&1; then
    echo "✅ База данных готова!"
    break
  else
    echo "⏳ База данных ещё не готова (попытка $i/30)... ждём 2 секунды."
    sleep 2
  fi
done

# Если после 60 секунд база всё ещё не готова — выходим с ошибкой
if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_DB" > /dev/null 2>&1; then
  echo "❌ Критическая ошибка: База данных не запустилась за 60 секунд!"
  exit 1
fi

# Теперь, когда база точно готова, запускаем миграции
echo "🚀 Запуск миграций Django..."
python manage.py migrate --noinput

# Сбор статики
echo "📦 Сбор статических файлов..."
# Используем --noinput, чтобы скрипт не спрашивал "Are you sure?" (это вызывало твою ошибку EOFError)
python manage.py collectstatic --noinput

# Запуск сервера
echo "🚀 Запуск Gunicorn..."
exec gunicorn kittygram.wsgi:application --bind 0.0.0.0:8000