-- Palavras chaves de algoritmos
local function keyword(palavra)
    local element
    -- print(palavra.text, "---", string.match(palavra.text, "^%p*-%w+-%p*$"), "*")
    local palavra_chave = string.match(palavra.text, "^%p*-(.*)-%p*$")
    if palavra_chave then
        palavra_chave = string.gsub(palavra_chave, "-", " ")
        local antes = string.match(palavra.text, "^(%p*)-.*-%p*$") or ""
        local depois = string.match(palavra.text, "^%p*-.*-(%p*)$") or ""
        if quarto.doc.is_format("latex") then
            element = pandoc.RawInline("latex",
                antes ..
                "{\\AlgLanguageSet{quarto}{key = {" .. palavra_chave ..
                "}}\\Keyword[quarto]{key}}" ..
                depois
            )
        else
            element = pandoc.Inlines {
                pandoc.Str(antes),
                pandoc.Strong(palavra_chave),
                pandoc.Str(depois)
            }
        end
    else
        element = palavra
    end

    return element
end

-- Nomes de módulos em algoritmos
local function module(palavra)
    local element
    local nome_modulo = string.match(palavra.text, "^%p*+(.*)+%p*$")
    if nome_modulo then
        nome_modulo = string.gsub(nome_modulo, "-", " ")
        local antes = string.match(palavra.text, "^(%p*)+.*+%p*$") or ""
        local depois = string.match(palavra.text, "^%p*+.*+(%p*)$") or ""
        if quarto.doc.is_format("latex") then
            element = pandoc.RawInline("latex",
                antes .. "\\Module{" .. nome_modulo .. "}" .. depois)
        else
            element = pandoc.Inlines {
                pandoc.Str(antes),
                pandoc.SmallCaps(nome_modulo),
                pandoc.Str(depois)
            }
        end
    else
        element = palavra
    end

    return element
end


-- Id em algoritmos
local function id(palavra)
    local id = palavra
    local nome_id = string.match(palavra.text, "%[([^]]*)%]{id}")
    if nome_id then
        if quarto.doc.is_format("latex") then
            id = pandoc.RawInline("latex", "\\Id{" .. nome_id .. "}")
        else
            id = pandoc.Emph(nome_id)
        end
    end

    return id
end


-- Links com abertura em nova aba
local function links_in_new_window(link)
    link.attributes["target"] = "_blank"
    return link
end


local function init(document)
    if not quarto.doc.is_format("pdf") then
        local blocks = { pandoc.Math('InlineMath',
            "\\newcommand\\Id[1]{\\mbox{\\textit{#1}}}") }
        for _, element in pairs(document.blocks) do
            table.insert(blocks, element)
        end
        document.blocks = blocks
    end

    return document
end

return {
    { Pandoc = init },
    { Str = keyword },
    { Str = module },
    { Str = id },
    { Link = links_in_new_window }
}
