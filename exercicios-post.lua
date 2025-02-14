local function starts_with(text, subtext)
    return string.sub(text, 1, #subtext) == subtext
end


local function ajusta_prefixo(cite, imagem, texto)
    local altura
    if quarto.doc.is_format("pdf") then
        altura = "1em"
    else
        altura = "18px"
        texto = ""
    end
    return pandoc.Inlines(
        {
            -- pandoc.Image("", "icones/" .. imagem, "", { height = altura }),
            pandoc.Str(" " .. texto)
        }
    )
end

local function citacoes(cite)
    if starts_with(cite.citations[1].id, "rem") then
        cite.citations[1].prefix =
            ajusta_prefixo(cite, "comentario.png", "Comentário")
    elseif starts_with(cite.citations[1].id, "sol") then
        cite.citations[1].prefix =
            ajusta_prefixo(cite, "resposta.png", "Resposta")
    elseif starts_with(cite.citations[1].id, "exr") then
        cite.citations[1].prefix =
            ajusta_prefixo(cite, "pergunta.png", "Problema")
    end

    return cite
end

local in_header = [[
\let\remark\undefined
\let\endremark\undefined
\newtheorem*{remark}{Comentário}
\let\solution\undefined
\let\endsolution\undefined
\newtheorem*{solution}{Resposta}
]]

function latex(doc)
    if quarto.doc.is_format("pdf") then
        quarto.doc.include_text('in-header', in_header)
    end

    return doc
end

return {
    Cite = citacoes,
    Pandoc = latex
}
