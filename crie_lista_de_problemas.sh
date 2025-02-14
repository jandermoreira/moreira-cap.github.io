#!/bin/bash 
# Cria listagem todos os problemsa com base no seu número de identificação

source=$(sed -E -n '/LISTAGEM: INICIO/,/LISTAGEM: FIM/{
    /^[[:space:]]*[^#][[:space:]]*- pratica/{
        s/.*prat/prat/;
        p
    };
}' _quarto-pratica-algoritmos.yml)

qmd='pratica-algoritmos-listagem-geral.qmd'

cat << EOF > $qmd
# Listagem geral de problemas {#sec-listagem-geral}

Listagem dos problemas por ordem de código:

EOF

echo '`\begin{multicols}{2}`{=latex}'$'\n\n' >> $qmd

echo $'\n\n' >> $qmd
sed -E -n '
    /include problemas.*[0-9].qmd/{
        s/.*problemas\/(....).*/* #\1: @exr-\1/;
        p
    }' $source | sort -n >> $qmd

echo $'\n\n' >> $qmd
echo '`\end{multicols}`{=latex}' >> $qmd

touch -d "-1min" $qmd
