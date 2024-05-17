#!/bin/bash


USERNAME=$MYSQL_ROOT
PASSWORD=$MYSQL_ROOT_PASSWORD


manage_upgrade_version() {
 
    # Boucle de START_VERSION jusqu'à MYSQL_MIGRATION_VERSION
    CURRENT_VERSION=$START_VERSION
    while [ $CURRENT_VERSION -le $MYSQL_MIGRATION_VERSION ]; do
    echo "Traitement de la version: $CURRENT_VERSION"


    input="/usr/local/bin/migrations/$CURRENT_VERSION.txt"
 
    # Vérifiez si le fichier existe et est lisible
    if [ ! -f "$input" ] || [ ! -r "$input" ]; then
        echo "Le fichier $input n'existe pas ou n'est pas lisible"
        pwd
        exit 1
    fi

    # Lire le fichier ligne par ligne
    while IFS= read -r ligne
    do
        # La chaîne ne commence pas par # et n'est pas vide.
        if [ ! -z "$1" ] && [[ ! $1 == \#* ]]; then
            # executer les commandes inscrite dans les fichiers
            mysql -u$USERNAME -p$PASSWORD -e "$ligne"
        fi
    done < "$input"

    # Incrémenter la version courante
    CURRENT_VERSION=$((CURRENT_VERSION + 1))
    echo $CURRENT_VERSION > $FILE
    done
}

wait_serveur_mysql_is_running() {
    sleep 2

    # wait for the serveur running
    mysql -u$USERNAME -p$PASSWORD -e "EXIT;"
    while [ $? -ne 0 ]
    do
        sleep 2
        mysql -u$USERNAME -p$PASSWORD -e "EXIT;"        
    done
}

check_migration_version_env() {
    # Assurez-vous que MYSQL_MIGRATION_VERSION est défini
    if [ -z "$MYSQL_MIGRATION_VERSION" ]; then
        echo "La variable MYSQL_MIGRATION_VERSION n'est pas définie."
        exit 1
    fi
}

get_current_db_version() {
   # Nom du fichier contenant l'entier
    FILE="./dbversion.txt"

    # Vérification de l'existence du fichier
    if [ ! -f "$FILE" ]; then
        echo "0" > $FILE
    fi

    # Lecture du contenu du fichier
    START_VERSION=$(cat "$FILE")

    # Vérification que le contenu est bien un entier
    if ! [[ "$START_VERSION" =~ ^-?[0-9]+$ ]]; then
    echo "Le contenu du fichier $FILE n'est pas un entier valide."
    exit 1
    fi

}

script_fork() {

    get_current_db_version

    check_migration_version_env

    if [ $START_VERSION -gt $MYSQL_MIGRATION_VERSION ]; then
        exit 1
    fi

    wait_serveur_mysql_is_running

    manage_upgrade_version
}


_main() {
    #fork the script
    script_fork &
}


_main
