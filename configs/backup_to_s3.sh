#!/bin/bash
# 2018-06-26
# Updated 2019-09-17
# Lucas

echo "home is $HOME"
source $HOME/.bash_profile
export AWS_SHARED_CREDENTIALS_FILE="/var/lib/nginx/.aws/credentials"
export AWS_CONFIG_FILE="/var/lib/nginx/.aws/config"

# General Vars
HOSTNAME=`hostname`
FROM_NAME="SERVER ${HOSTNAME}"
SUBJECT="[CRITICAL] ${HOSTNAME} backups error"
WEBROOT=/var/www/webroot

ROOTSCRIPTPATH="${WEBROOT}/backup/"
cd $ROOTSCRIPTPATH

DATE=`date +%Y-%m-%d_%Hh%Mm`
DAY=`date +%Y_%m_%d`

/var/lib/nginx/.config/composer/vendor/drush/drush/drush -r /var/www/webroot/ROOT sql:dump --extra-dump=--no-tablespaces --result-file=/var/www/webroot/backup/db_backup.sql --gzip
/usr/local/bin/aws s3 cp ${WEBROOT}/backup/db_backup.sql.gz s3://$AWSBUCKET/${HOSTNAME}/${DAY}/

if [ $? == 0 ]; then
	rm -rf ${WEBROOT}/backup/db_backup.sql.gz
else
	echo -e "Subject:Backups for database on ${HOSTNAME} for failed \n\n Response code was $?" | /usr/sbin/sendmail -f ${BACKUP_FAIL_FROM} ${BACKUP_FAIL_TO}
fi

