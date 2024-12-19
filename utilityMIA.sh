#!/bin/bash

#функция для вывода списка пользователей и их директорий
list_users() {
  awk -F: '$3 >= 1000 {print $1 "\t" $6}' /etc/passwd | sort
}

#функция для вывода списка процессов в скрипте и время
list_processes() {
  ps -eo pid,cmd,start --sort=pid
}

#вывода мануала
show_help() {
  cat <<EOF
 $0 

Опции:
  -u, --users            Вывод списка пользователей и их домашних директорий
  -p, --processes        Вывод списка процессов, отсортированных по ID
  -h, --help             Вывод справки
  -l PATH, --log PATH    Запись вывода в файл по указанному пути
  -e PATH, --errors PATH Запись ошибок в файл по указанному пути

Примеры:
  $0 --users
  $0 --processes --log output.txt
  $0 --users --errors error.log
EOF
    exit 0
}

#чекалка пути для вывода
validate_path() {
  local path="$1"
  if [[ ! -d "$(dirname "$path")" ]]; then
    echo "Ошибка: директория для файла '$path' не существует или недоступна для записи." >&2
    return 1
  fi
  return 0
}

#основная функция
main() {
  local log_path=""
  local error_path=""
  local action=""

  #парсинг аргументов с помощью getopt
  TEMP=$(getopt -o upl:e:h --long users,processes,log:,errors:,help -n "$0" -- "$@")
  if [[ $? -ne 0 ]]; then
    echo "Ошибка: неверные параметры." >&2
    exit 1
  fi
  eval set -- "$TEMP"

  #обработка аргументов
  while true; do
    case "$1" in
      -u|--users)
        action="users"
        shift
        ;;
      -p|--processes)
        action="processes"
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      -l|--log)
        log_path="$2"
        shift 2
        ;;
      -e|--errors)
        error_path="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      *)
        echo "Ошибка: неизвестный параметр $1." >&2
        exit 1
        ;;
    esac
  done

  #проверка и установление log path
  if [[ -n "$log_path" ]]; then
    validate_path "$log_path" || exit 1
    exec >"$log_path"
  fi

  #проверка и установка вывода ошибок
  if [[ -n "$error_path" ]]; then
    validate_path "$error_path" || exit 1
    exec 2>"$error_path"
  fi

  #выполнение действий
  case "$action" in
    users)
      list_users
      ;;
    processes)
      list_processes
      ;;
    *)
      echo "Ошибка: действие не задано." >&2
      show_help
      exit 1
      ;;
  esac
}

main "$@"
