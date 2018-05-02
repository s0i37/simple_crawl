#!/bin/bash

LIMIT=10
OFFSET=0
while getopts "c:o:" opt
do
	case $opt in
		c) LIMIT=$OPTARG;;
		o) OFFSET=$OPTARG;;
esac
done

[[ $(($#-$OPTIND)) -lt 1 ]] && {
	echo $0 [opts] words.db SQL_QUERY
	echo "opts:"
	echo "  -c count"
	echo "  -o offset"
	exit
}

DB="${@:$OPTIND:1}"
shift $OPTIND
echo "SELECT text FROM words WHERE text MATCH '$*' limit $LIMIT,$OFFSET;" | sqlite3 "$DB" | grep --color=auto "$*"