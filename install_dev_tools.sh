#!/bin/bash

# Скрипт сумісний з Ubuntu/Debian

# Перевірка ОС
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        echo "Цей скрипт призначений тільки для Ubuntu/Debian. Поточна ОС: $ID"
        exit 1
    fi
else
    echo "Не вдалося визначити ОС. Скрипт призначений для Ubuntu/Debian."
    exit 1
fi

set -e  # Зупинити скрипт при помилці

echo "Перевірка та встановлення інструментів розробки..."

# Оновлення списку пакетів
sudo apt update

# Перевірка та встановлення Docker
if ! command -v docker &> /dev/null; then
    echo "Docker не встановлений. Встановлюємо..."
    sudo apt install -y docker.io
    echo "Docker встановлений."
else
    echo "Docker вже встановлений."
fi

# Перевірка та встановлення Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose не встановлений. Встановлюємо..."
    sudo apt install -y docker-compose
else
    echo "Docker Compose вже встановлений."
fi

# Перевірка та встановлення Python 3.9+
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    if [[ "$(printf '%s\n' "$PYTHON_VERSION" "3.9" | sort -V | head -n1)" != "3.9" ]]; then
        echo "Python версії $PYTHON_VERSION встановлений, але потрібна 3.9 або новіша. Оновлюємо..."
        sudo apt install -y python3 python3-pip
    else
        echo "Python $PYTHON_VERSION вже встановлений."
    fi
else
    echo "Python не встановлений. Встановлюємо..."
    sudo apt install -y python3 python3-pip
fi

# Перевірка та встановлення pip (якщо не встановлений з python3-pip)
if ! command -v pip3 &> /dev/null; then
    echo "pip не встановлений. Встановлюємо..."
    sudo apt install -y python3-pip
else
    echo "pip вже встановлений."
fi

# Встановлення Django через pip
if python3 -c "import django" &> /dev/null; then
    echo "Django вже встановлений."
else
    echo "Django не встановлений. Встановлюємо..."
    pip3 install django
fi

echo "Всі інструменти перевірено та встановлено!"
