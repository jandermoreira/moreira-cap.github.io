#!/bin/bash
#
# Sync _book to github pages

hoje=$(date +"%m/%d/%Y" | sed 's/\//\\\//g')
sed -i 's/date: .*/date: "'$hoje'"/' _quarto.yml

quarto render github-index.md &> /dev/null && (
    cp github-index.html /home/jander/pessoal/jandermoreira.github.io/;
    cp -r github-index_files /home/jander/pessoal/jandermoreira.github.io/;
)

if [ "$1" = "completo" -o "$1" = "tudo" ]; then
    echo Completo
    quarto render --profile completo &>/dev/null
    # rsync -az4 -e 'ssh -p 2021' \
    #     _cap-completo/* \
    #     jander@ssh.dc.ufscar.br:/home/profs/jander/www/livros/cap/
fi

if [ "$1" = "algoritmos" -o "$1" = "tudo" ]; then
    echo Algoritmos
    quarto render --profile algoritmos #&> /dev/null
    # rsync -az4 -e 'ssh -p 2021' \
    #     _cap-algoritmos/* \
    #     jander@ssh.dc.ufscar.br:/home/profs/jander/www/livros/cap-algoritmos/
fi

if [ "$1" = "programacao" -o "$1" = "tudo" ]; then
    echo Programação
    quarto render --profile programacao &>/dev/null
    # rsync -az4 -e 'ssh -p 2021' \
    #     _cap-linguagem-c/* \
    #     jander@ssh.dc.ufscar.br:/home/profs/jander/www/livros/cap-programacao/
fi

if [ "$1" = "pratica-algoritmos" -o "$1" = "tudo" ]; then
    echo Prática com algoritmos
    ./crie_lista_de_problemas.sh
    quarto render --profile pratica-algoritmos --to pdf &>/dev/null
    quarto render --profile pratica-algoritmos --to html &>/dev/null
    # rsync -az4 -e 'ssh -p 2021' \
    #     _cap-linguagem-c/* \
    #     jander@ssh.dc.ufscar.br:/home/profs/jander/www/livros/cap-programacao/
fi

cd /home/jander/pessoal/jandermoreira.github.io/
git pull
git add *
git commit -a -m "Publicação automática" && git push
