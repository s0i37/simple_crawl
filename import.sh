#!/bin/bash

[[ $# -ne 1 ]] && {
	echo $0 words.csv
	exit
}

db="$(basename $1)"
db="${db%.*}".db
[[ -e "$db" ]] || {
	echo "create table words(uri text, ext text, type text, text text);" | sqlite3 $db
}

sqlite3 $db <<E
.separator ","
.import $1 words
E

