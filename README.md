# simple_crawl
pure-bash http/ftp/smb/imap crawling

## requirements
apt-get install uchardet #(charset detect)

apt-get install catdoc #(.doc and .xls files)

apt-get install python-pdfminer #(.pdf files)

apt-get install radare2 #(get strings from executable)

apt-get install 7z #(archive files)

apt-get install lynx #(.html files)

apt-get install maildir-utils mpack #(emails files)

apt-get install tesseract-ocr #(image text recognize)


## crawling
Now only support common formats: zip,rar,7z,html,txt,doc,docx,xls,xlsx,pdf,exe,images


### HTTP
./spider.sh http://www.site.com/ [/usr/bin/wget options]

./crawl.sh www.site.com [/usr/bin/find options]

./import.sh www.site.com.csv


### FTP
./spider.sh ftp://ftp.site.com/pub [/usr/bin/wget options]

./crawl.sh ftp.site.com [/usr/bin/find options]

./import.sh ftp.site.com.csv


### SMB
mount -t cifs -o dom=domain,user=username //ip/share /mnt/

./crawl.sh /mnt/ [/usr/bin/find options]

./import.sh mnt.csv


### IMAP
mkdir emails && cd emails

./imap.sh imaps://imap.site.com user:pass

cd ..

./crawl.sh emails [/usr/bin/find options]

./import.sh emails.csv


## searching (cli)
./search.sh database.db words words words

## searching (gui)
cd search

### prepare
service elasticsearch start

./search_tool.py 127.0.0.1:9200 -i newindex -init

./search_tool.py 127.0.0.1:9200 -i newindex -import path/to/import.csv

### searching

./index.js

surf http://127.0.0.1:8080/newindex/
