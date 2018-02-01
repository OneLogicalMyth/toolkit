printf "GET / HTTP/1.0\n\n" - | ncat --ssl $1 $2
