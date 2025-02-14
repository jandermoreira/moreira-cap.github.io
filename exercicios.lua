-- exercicios.lua

local function starts_with(text, subtext)
    return string.sub(text, 1, #subtext) == subtext
end


local function insert_in_callout(float)
    local rotulo
    if starts_with(float.identifier, "exr") then
        rotulo = "Problema"
    elseif starts_with(float.identifier, "sol") then
        rotulo = "Resposta para o Problema"
    elseif starts_with(float.identifier, "rem") then
        rotulo = "Comentário sobre o Problema"
    end

    local numero_exercicio = string.sub(float.identifier, 5)

    local callout = quarto.Callout(
        {
            appearance = "simple",
            -- title = rotulo .. " " .. float.order.section[1] .. "."
            --     .. float.order.order .. " [#" .. numero_exercicio .. "]",
            title = "[" .. rotulo .. " #" .. numero_exercicio .. "]",
            content = float.div,
        }
    )

    local div = pandoc.Div({callout}, { id = float.identifier })

    return div
end

if not quarto.doc.is_format("pdf") then
    quarto._quarto.ast.add_renderer(
        "Theorem",
        function(float)
            return starts_with(float.identifier, "exr")
        end,
        insert_in_callout
    )

    quarto._quarto.ast.add_renderer(
        "Proof",
        function(element)
            return starts_with(element.identifier, "sol")
        end,
        insert_in_callout
    )

    quarto._quarto.ast.add_renderer(
        "Proof",
        function(float)
            return starts_with(float.identifier, "rem")
        end,
        insert_in_callout
    )
end

-- local function icone_resposta(str)
--     local element
--     if pandoc.utils.stringify(str) == "&resposta&" then
--         pandoc.Image("", "icones/resposta.png", "",
--             { height = "20px" })
--     elseif pandoc.utils.stringify(str) == "&pergunta&" then
--         element = pandoc.Image("", "icones/pergunta.png", "",
--             { height = "20px" })
--     elseif pandoc.utils.stringify(str) == "&comentário&" or
--         pandoc.utils.stringify(str) == "&comentario&" then
--         element = pandoc.Image("", "icones/comentario.png", "",
--             { height = "20px" })
--     else
--         element = str
--     end
--     return element
-- end

return {}
