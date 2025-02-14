#!/bin/bash
# Filtro de capítulos

# for file in $(cat estrutura.qmd | tr -d '`' | tr -d , |
#     sed -n '/^# C/{s/.*C: /c-/; s/ /-/g; p}' | iconv -f utf8 -t ascii//TRANSLIT |
#     tr 'A-Z' 'a-z' | tr -d '(' | tr -d ')' | awk '{ print $0".qmd" }'); do

#     echo $file
# done

# for file in $(cat estrutura.qmd | tr -d '`' | tr -d , |
#     sed -n '/^# Algoritmos/{s/.*Algoritmos: /algoritmos-/; s/ /-/g; p}' | iconv -f utf8 -t ascii//TRANSLIT |
#     tr 'A-Z' 'a-z' | tr -d '(' | tr -d ')' | awk '{ print $0".qmd" }'); do

#     echo $file
# done

for file in $(cat estrutura.qmd | tr -d '`' | tr -d , |
    sed -n '/^# /{s/.*Algoritmos: /algoritmos-/; s/^.*C: /c-/; s/ /-/g; p}' | iconv -f utf8 -t ascii//TRANSLIT |
    tr 'A-Z' 'a-z' | tr -d '(' | tr -d ')' | awk '{ print $0".qmd" }'); do

    echo $file
done
