 #!/bin/bash

opts='-type f -size -10M ! -iname "*.wav" ! -iname "*.mp3"'

[[ $# -lt 1 ]] && {
	echo "$0 index_local_path [/usr/bin/find options]"
	echo "example: $0 /mnt/share/ -type f -size -10M ! -iname '*.wav' ! -iname '*.mp3'"
	exit
}

function session_file_done(){
	path="$1"
	echo "$path" >> "$session_file"
}

function session_is_file_done(){
	path="$1"
	grep "$path" "$session_file" 1> /dev/null 2> /dev/null && echo 1 || echo 0
}

function session_create(){
	session_file="$1"
	stat "$session_file" 1> /dev/null 2> /dev/null && echo 1 || {
		touch "/dev/shm/$session_file"
		ln -s "/dev/shm/$session_file" "$session_file"
		echo 0
	}
}

function session_close(){
	rm "$session_file"
	rm "/dev/shm/$session_file"
}

function escape(){
	echo -n '"'
	while read line
	do
		echo -n "$line"|sed -r 's/"/""/g'
	done
	echo -n "$line"|sed -r 's/"/""/g'
	echo -n '"'
}

index="$(basename $1).csv"
session_file=".$(basename $1).sess"
is_resume=$(session_create $session_file)

find $1 $opts -print | 
while read path
do
	[[ $is_resume = 1 && $(session_is_file_done $path) = 1 ]] && {
		echo "(skip $path)"
		continue
	}
	echo "$path"
	echo -n "$path" | escape >> "$index"
	echo -n "," >> "$index"
	ext=${path##*.}
	echo -n "$ext" | escape >> "$index"
	echo -n "," >> "$index"
	mime=$(xdg-mime query filetype "$path")
	case $mime in
		*/xml)
			echo -n "xml," >> "$index"
			cat "$path" | escape >> "$index"
			;;
		*/*html*)
			echo -n "html," >> "$index"
			cat "$path" | lynx -nolist -dump -stdin | escape >> "$index"
			;;
		text/*|*/*script)
			echo -n "text," >> "$index"
			cat "$path" | escape >> "$index"
			;;
		application/msword)
			echo -n "doc," >> "$index"
			catdoc "$path" | escape >> "$index"
			;;
		application/vnd.openxmlformats-officedocument.wordprocessingml.document)
			echo -n "doc," >> "$index"
			unzip -p "$path" | grep '<w:r' | sed 's/<w:p[^<\/]*>/ /g' | sed 's/<[^<]*>//g' | grep -v '^[[:space:]]*$' | sed G | escape >> "$index"
			;;
		application/vnd.ms-excel|application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)
			echo -n "xls," >> "$index"
			xls2csv -x "$path" | escape >> "$index"
			;;
		application/pdf)
			echo -n "pdf," >> "$index"
			pdf2txt -t text "$path" | escape >> "$index"
			;;
		application/x-executable|application/x-ms-dos-executable)
			echo -n "exe," >> "$index"
			/opt/radare2/bin/rabin2 -z "$path" | sed -rn "s/vaddr=[^\s]+.*string=(.*)/\1/p" | escape >> "$index"
			;;
		application/*compressed*|application/*zip*|application/*rar*|application/*tar*|application/*gzip*)
			echo -n "zip," >> "$index"
			7z l "$path" | tail -n +13 | escape >> "$index"
			printf "\n" >> "$index" 
			temp=$(tempfile)
			rm $temp && mkdir -p "$temp/$path"
			7z x "$path" -o"$temp/$path" 1> /dev/null 2> /dev/null
			ln -s "$(realpath $0)" "$temp/$(basename $0)"
			ln -s "$(realpath $index)" "$temp/$index"
			( cd "$temp"; "./$(basename $0)" "$(dirname $1|cut -c 2-)/${index%.*}"; )
			rm -r $temp
			;;
		image/*)
			echo -n "image," >> "$index"
			identify -verbose "$path" | escape >> "$index"
			#tesseract "$path" stdout -l eng >> "$index"
			#tesseract "$path" stdout -l rus >> "$index"
			;;
		message/*)
			echo -n "message," >> "$index"
			mu view "$path" | escape >> "$index"
			printf "\n" >> "$index"
			temp=$(tempfile)
			rm $temp && mkdir -p "$temp/$path"
			cp "$path" "$temp/$path/"
			munpack -t -f -C "$(realpath $temp/$path)" "$(basename $path)"
			rm "$temp/$path/$(basename $path)"
			ln -s "$(realpath $0)" "$temp/$(basename $0)"
			ln -s "$(realpath $index)" "$temp/$index"
			( cd "$temp"; "./$(basename $0)" "${index%.*}"; )
			rm -r $temp
			;;
		application/octet-stream)
			echo -n "raw," >> "$index"
			strings "$path" | escape >> "$index"
			;;
		application/x-raw-disk-image)
			echo -n "disk," >> "$index"
			binwalk "$path" | escape >> "$index"
			;;
		*)
			echo -n "unknown," >> "$index"
			file "$path" | grep text > /dev/null &&
			cat "$path" | escape >> "$index" ||
			{
				#strings "$path" >> "$index"
				echo "$path $mime" >> unknown_mime.log
			}
			;;
	esac
	printf "\n" >> "$index"
	session_file_done $path
done

session_close