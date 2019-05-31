#!/bin/bash
#
# script to check the validity of domain media-cloud.nl certificate
# it will import new certificate if it expired
#
# Owner: Ruk
# Version: 1.1
# Date: 31 May 2019
#

rename_public_cert () {
        cdate=`date +%d-%B-%Y`
        if [ -f "/root/keytool/public.crt" ]
        then
                `mv /root/keytool/public.crt /root/keytool/public.crt_${cdate}`
        fi

}

remove_old_cert () {
        rename_public_cert
        alias_name=`echo 'changeit'|/usr/lib/jvm/java-8-oracle/bin/keytool -keystore /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts -list -v 2>/dev/null | grep -B 5 'media-cloud.nl' | grep 'Alias name' | awk '{print $3}'`
        if [ ! -z $alias_name ]
        then
                echo "`date` :: delete the expired certificate"
                echo "`date` :: cmd-> /usr/lib/jvm/java-8-oracle/bin/keytool -alias $alias_name -keystore /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts -delete"
                `echo 'changeit'|/usr/lib/jvm/java-8-oracle/bin/keytool -alias $alias_name -keystore /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts -delete`
        fi
}

import_cert () {
        remove_old_cert
        cdated=`date +%d%m%Y`
        aname="mediaclountnl${cdated}"
        echo "`date` :: generate new public.crt"
        echo "`date` :: cmd-> openssl s_client -connect media-cloud.nl:443 < /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > public.crt"
        `openssl s_client -connect media-cloud.nl:443 < /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > public.crt`
        echo "`date` :: import the new certificate"
        echo "`date` :: cmd-> /usr/lib/jvm/java-8-oracle/bin/keytool -import -alias $aname -keystore /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts -file public.crt >/dev/null"
        echo "`date` :: keystore password-> changeit, Trust this certificate-> yes"
        `/usr/lib/jvm/java-8-oracle/bin/keytool -import -alias $aname -keystore /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts -file public.crt >/dev/null`
        healthcheck
}

healthcheck () {
        `/usr/lib/jvm/java-8-oracle/bin/java SSLPoke media-cloud.nl 443 2>/dev/null > /dev/null`
        if [ "$?" -eq "0" ]
        then
                echo "`date` :: healthcheck-> Success"
        else
                echo "`date` :: healthcheck-> Failure"
        fi
}

validate_certificate () {
        validity=`echo 'changeit'|/usr/lib/jvm/java-8-oracle/bin/keytool -keystore /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts -list -v 2>/dev/null | grep -A 3 'media-cloud.nl' | grep 'Valid from' | awk -F 'until:' '{print $2}'`
        echo "`date` :: checking for media-cloud.nl domain"
        echo "`date` :: cmd-> /usr/lib/jvm/java-8-oracle/bin/keytool -keystore /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts -list -v"
#validity="Mon Jun 10 08:04:55 UTC 2019"
#validity=""

        if [ -z "$validity" ]
        then
                echo "`date` :: No certificate found for domain media-cloud.nl"
                echo "`date` :: Importing certificate"
                import_cert
                exit
        fi

        validity_seconds=`date --date="$validity" +%s`
        #echo "$validity_seconds"
        today_date_in_seconds=`date +%s`
        #echo "$today_date_in_seconds"

        if [ $today_date_in_seconds -gt $validity_seconds ]
        then
                echo "`date` :: certificate is expired on $validity"
                #echo -n "Do you want to re-import the certificate (y/n): "; read op

                #if [[ $op == "y" || $op == "Y" ]]
                #then
                echo "`date` :: Importing certificate"
                import_cert
                #else
                #        echo "abort"
                #       exit 1
                #fi
        else
                echo "`date` :: certificate will expire on $validity"
                healthcheck
        fi
}

#----------------------------- -------------------------------------------------------------------#

validate_certificate