#!/bin/ash

set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"

        eval indirectVar=\$$var
        eval indirectFileVar=\$$fileVar

	if [ -n "$indirectVar" ] && [ -n "$indirectFileVar" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi

	local val="$def"

	if [ -n "$indirectVar" ]; then
		val="$indirectVar"
	elif [ "$indirectFileVar" ]; then
		val="$(cat "$indirectFileVar")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

file_env 'RESTIC_REPOSITORY'
file_env 'AWS_ACCESS_KEY_ID'
file_env 'AWS_SECRET_ACCESS_KEY'

if [ -z "$RESTIC_REPOSITORY" ]; then
  echo >&2 "error: no repo specified in REPO variable"
  exec "$@"
else

  restic snapshots || restic init

  if [ -z "$RESTIC_FORGET_ARGS" ]; then
    export RESTIC_FORGET_ARGS='--keep-daily 7 --keep-weekly 4 --keep-monthly 6'
  fi

  if [ -z "$CRON_SCHEDULE" ]; then
    CRON_SCHEDULE='0 7 * * *'
  fi

  BACKUP_COMMAND="/bin/backup.sh"

  (crontab -l ; echo "$CRON_SCHEDULE $BACKUP_COMMAND") | crontab -

  eval "$BACKUP_COMMAND"

  exec "$@"

fi

