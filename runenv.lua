-- rundev.lua
-- Jander Moreira (moreira.jander@gmail.com)
-- 2024


-- ---------------------------------------------
-- Utilities


-- string_count: returns the number of times pattern
--  occours in text
function string_count(text, pattern)
    return select(2, string.gsub(text, pattern, ""))
end

-- copy_table: clones a table with embeded tables
local function copy_table(a_table)
    local new_table = {}
    for key, value in pairs(a_table) do
        if type(value) ~= "table" then
            new_table[key] = value
        else
            new_table[key] = copy_table(value)
        end
    end

    return new_table
end


local function insert_to_table(a_table, new_value)
    local new_table = copy_table(a_table)
    table.insert(new_table, new_value)
    return new_table
end


-- file_exists: checks if path is a readable file
local function file_exists(path)
    local file = io.open(path, "r")
    local exists
    if file == nil then
        exists = false
    else
        exists = true
        file:close()
    end

    return exists
end


-- read_from_file: returns the content of a text file
local function read_from_file(path)
    local content = ""
    local file = io.open(path, "rb")
    if file then
        content = file:read "*a"
        file:close()
    end
    return content
end


-- write_to_file: creates or overrides path with content
local function write_to_file(path, content)
    local file = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
    end
end


local function clip_text(text, head_count, tail_count, threshold)
    if not head_count then head_count = 5 end
    if not tail_count then tail_count = 5 end
    if not threshold then threshold = head_count + tail_count + 15 end

    if string.sub(text, -1, -1) ~= "\n" then
        text = text .. "\n"
    end
    line_count = string_count(text, "\n")
    if line_count <= threshold then
        return text -- as is
    else
        clipped_text = ""
        local current_line = 0
        for line in string.gmatch(text, "([^\n]*)\n?") do
            current_line = current_line + 1
            if current_line <= head_count then
                clipped_text = clipped_text .. line .. "\n"
            end
        end
        clipped_text = clipped_text .. "\n... [" ..
            (line_count - head_count - tail_count) ..
            " linhas omitidas]\n\n"
        current_line = 0
        for line in string.gmatch(text, "([^\n]*)\n?") do
            current_line = current_line + 1
            if current_line > line_count - tail_count then
                clipped_text = clipped_text .. line .. "\n"
            end
        end
        return clipped_text
    end
end


local function get_block_attributes(block, default)
    local attributes
    if default then
        attributes = default
    else
        attributes = {}
    end
    for key, value in pairs(block.attr.attributes) do
        if key == "to" or key == "name" then
            -- to="filename" or name="filename"
            attributes.filename = value
            attributes.io_operation = "write"
        elseif key == "from" then
            -- from="filename"
            attributes.filename = value
            attributes.io_operation = "read"
        elseif key == "intentional-problems" then
            attributes.intentional_problems = value == "true"
        elseif key == "timeout-options" then
            attributes.timeout_options = value
        elseif key == "clip" then
            -- clip
            attributes.clip = value ~= "false"
            if not attributes.clip then
                attributes.clip_head = nil
                attributes.clip_tail = nil
                attributes.clip_threshold = nil
            else
                attributes.clip_head, attributes.clip_tail =
                    string.match(value, "(%d+)%s*,%s*(%d+)")
                if attributes.clip_head and attributes.clip_tail then
                    attributes.clip_head = tonumber(attributes.clip_head)
                    attributes.clip_tail = tonumber(attributes.clip_tail)
                else
                    attributes.clip_head = 5
                    attributes.clip_tail = 5
                end
                attributes.clip_threshold =
                    string.match(value, "%d+%s*,%s*%d+%s*,%s*(%d+)")
                if attributes.clip_threshold then
                    attributes.clip_threshold =
                        tonumber(attributes.clip_threshold)
                else
                    attributes.clip_threshold =
                        attributes.clip_head + attributes.clip_tail + 15
                end
            end
        else
            attributes[key] = value
        end
    end

    return attributes
end




-- ---------------------------------------------
-- Textfile codeblocks

local function process_text_files(block)
    element = block
    if block.attr.classes:includes("textfile") then
        local attributes = get_block_attributes(block)

        if not attributes.filename then
            element =
                pandoc.Para(pandoc.Strong("??NO NAME. TEXT FILE IGNORED!"))
        else
            if attributes.io_operation == "read" then
                if attributes.clip then
                    element.text = clip_text(
                        read_from_file(attributes.filename),
                        attributes.head,
                        attributes.tail,
                        attributes.threshold
                    )
                else
                    element.text = read_from_file(attributes.filename)
                end
            else
                write_to_file(attributes.filename, block.text)
                if attributes.clip then
                    element.text = clip_text(
                        block.text,
                        attributes.head,
                        attributes.tail,
                        attributes.threshold
                    )
                end
            end
            element.attr.classes = pandoc.List(
                insert_to_table(element.attr.classes, "terminal")
            )
            element.attr.classes = pandoc.List(
                insert_to_table(element.attr.classes, "cell-output")
            )
        end

        if block.attr.classes:includes("hide-content") then
            element = {}
        end
    end

    return element
end




-- ---------------------------------------------
-- Bash codeblocks

local function bash_create_execution_result_block(is_runnable, bash_code)
    local result_block = nil
    local file = io.open("__output.result.full", "w")
    if file then
        line_commands = string.gsub(bash_code, "\\\n", "${NOTHING}")
        for command in string.gmatch(line_commands, "[^\n]*") do
            -- quarto.log.output("<" .. command .. ">")
            if is_runnable then
                file:write("$ ") -- prompt
            end
            file:write("\0" .. string.gsub(command, "${NOTHING}", "\0\\\n\0") .. "\0\n")
            if is_runnable then
                os.execute("(" .. command .. ") > __output.result 2>&1")
                os.execute("fold -s -w 78 __output.result > __output.folded")
                execution_result = read_from_file("__output.folded")
                file:write(execution_result)
            end
        end
        file:close()
        block_contents = read_from_file("__output.result.full")
        result_block = pandoc.CodeBlock(block_contents, {})
        if is_runnable then
            result_block.attr.classes = pandoc.List({ "terminal", "cell-code" })
        else
            result_block.attr.classes = pandoc.List({ "bash", "cell-code" })
        end
    end
    return result_block
end


local function bash_run(block)
    local block = block
    local is_bash = block.attr.classes:includes("bash")
    local is_runnable_bash = block.attr.classes:includes("{bash}")
    if is_bash or is_runnable_bash then
        block = bash_create_execution_result_block(is_runnable_bash,
            block.text)
    end
    return block
end


local function bash_run_as_standalone(block)
    local list_of_blocks = { block }
    if block.attr.classes:includes("{bash}") and
        not block.attr.classes:includes("runenv") then
        pandoc.system.with_temporary_directory("running_bash",
            function(temporary_directory)
                pandoc.system.with_working_directory(temporary_directory,
                    function()
                        list_of_blocks = bash_run(block)
                        return nil
                    end
                )
                return nil
            end
        )
    end

    return list_of_blocks
end



-- ---------------------------------------------
-- C codeblocks


local function c_generate_clean_source_code(source_code)
    local clean_code = source_code
    clean_code = string.gsub(clean_code, "%s*//TYPE[^\n]*", "")
    clean_code = string.gsub(clean_code, "%s*//HIDE%s([^\n]*)", "")
    clean_code = string.gsub(clean_code, "//IGNORE%s([^\n]*)", "%1")
    clean_code = string.gsub(clean_code, "%s*//INCLUDE[^\n]*", "")
    clean_code = string.gsub(clean_code, "%s*//STEP[^\n]*", "")
    clean_code = string.gsub(clean_code, "%s*//{[^\n]*", "")
    clean_code = string.gsub(clean_code, "%s*//}[^\n]*", "")
    return clean_code
end


local function c_check_includes(source_code)
    local processed_source = ""
    for line in string.gmatch(source_code, "([^\n]*)\n?") do
        include_file = string.match(line, "//INCLUDE%s+([^%s]+)")
        if include_file then
            processed_source =
                processed_source .. read_from_file(include_file) .. "\n"
        else
            processed_source = processed_source .. line .. "\n"
        end
    end

    return processed_source
end


local function c_generate_interactive_source_code(source_code)
    local support_code = [[
        /*************************************************/
        #include <stdio.h>
        #include <errno.h>
        #include <string.h>
        int user_input_time;
        void print_user_input(int time, char* text){
            if (time == user_input_time && errno == 0) {
                printf("%c%s%c\n", '\0', text, '\0');
            }
        }
        /*************************************************/


    ]]

    local interactive_source_code = support_code .. source_code
    interactive_source_code = string.gsub(interactive_source_code,
        "//TYPE", "print_user_input")
    interactive_source_code = string.gsub(interactive_source_code,
        "//HIDE%s", "")
    interactive_source_code = string.gsub(interactive_source_code,
        "//IGNORE%s[^\n]*", "")
    interactive_source_code = string.gsub(interactive_source_code,
        "//STEP", "user_input_time++;")
    interactive_source_code = string.gsub(interactive_source_code,
        "//{", "{")
    interactive_source_code = string.gsub(interactive_source_code,
        "//}", "}")
    interactive_source_code = string.gsub(interactive_source_code,
        "sleep%([^)]*%);[^\n]*", "") -- no need to actually sleep

    return interactive_source_code
end


local function c_extract_user_input(source_code)
    local user_inputs = {}

    for code_line in string.gmatch(source_code, "[^\n]*\n?") do
        if string.match(code_line, "//TYPE") then
            local number, text = string.match(code_line,
                "%(%s*(%d+)%s*,%s*\"(.*)\"%s*%);")

            if not number or not text then
                quarto.log.output("c: Illformed '" .. code_line .. "'")
            else
                local entry = tonumber(number) + 1
                if not user_inputs[entry] then
                    user_inputs[entry] = { text }
                else
                    table.insert(user_inputs[entry], text)
                end
            end
        end
    end

    local user_typing = ""
    for _, input in ipairs(user_inputs) do
        for _, line in ipairs(input) do
            user_typing = user_typing .. line .. "\n"
        end
    end

    return user_typing
end


local function c_create_source_code_block(block)
    local source_block = block:clone()
    source_block.text = c_generate_clean_source_code(block.text)
    source_block.attr.classes = pandoc.List({ "c", "cell-code" })

    return source_block
end


local function c_create_compilation_result_block(source_code)
    write_to_file("main.c", c_generate_clean_source_code(source_code))
    os.execute("gcc -Wall -pedantic -std=c17 -o a.out main.c -lm > compilation-result 2>&1")
    os.execute("cat compilation-result | fold -s -w 78> compilation-folded")
    local compilation_result = read_from_file("compilation-folded")

    local block = nil
    if #compilation_result > 0 then
        block = pandoc.CodeBlock(compilation_result, {})
        block.attr.classes = pandoc.List({ "terminal", "cell-output" })
    end
    return block
end


local function c_create_execution_result_block(source_code, attributes)
    write_to_file("user-input", c_extract_user_input(source_code))
    write_to_file("main.c", c_generate_interactive_source_code(source_code))

    local block = nil
    if not os.execute("gcc -Wall -pedantic -std=c17 -o a.out main.c -lm 2> /dev/null") then
        if not attributes.intentional_problems then
            local message = "c: Code with warnings or errors..."
            if string.match(source_code, "//HIDE") then
                message = message .. " but there are '//HIDE' lines!"
            end
            quarto.log.output(message)
        end
    else
        local timeout_options
        if attributes.timeout_options then
            timeout_options = attributes.timeout_options
        else
            timeout_options = "--kill-after=0.0025s 0.002s" -- default
        end
        os.execute("timeout " .. timeout_options ..
            " ./a.out < user-input > outfile 2> outfile; echo $? > _status")

        local output_text
        if not attributes.clip then
            output_text = read_from_file("outfile")
        else
            output_text = clip_text(
                read_from_file("outfile"),
                attributes.clip_head,
                attributes.clip_tail,
                attributes.clip_threshold
            )
        end

        local status = string.sub(read_from_file("_status"), 1, -2)
        if status == "124" then -- timeout
            if not attributes.intentional_problems then
                quarto.log.output("runenv: Warning: Timeout executing code.")
            end
            output_text = output_text ..
                "\n..."
        elseif status ~= "0" then -- return x, x != 0
            output_text = output_text ..
                "\n[Programa encerrado com código " .. status .. ']'
        end
        if string.sub(output_text, -1, -1) == "\n" then
            output_text = string.sub(output_text, 1, -2)
        end

        if #output_text > 0 then
            block = pandoc.CodeBlock(output_text, {})
            block.attr.classes = pandoc.List({ "terminal", "cell-output" })
        end
    end

    return block
end

local function c_run(block)
    list_of_blocks = { block } -- default

    if block.attr.classes:includes("{c}") then
        local filename
        for key, value in pairs(block.attr.attributes) do
            if key == "to" or key == "name" then -- to="filename"
                filename = value
            end
        end

        list_of_blocks = { c_create_source_code_block(block) }

        -- Save file
        if filename and block.attr.classes:includes("runenv") then
            write_to_file(filename, list_of_blocks[1].text) -- write clean code
        end

        -- Compiler output
        if not block.attr.classes:includes("hide-compiler-output") then
            local compilation_result_block = c_create_compilation_result_block(block.text)
            if compilation_result_block then
                table.insert(list_of_blocks, compilation_result_block)
            end
        end

        -- Execution output
        if not block.attr.classes:includes("hide-program-output") then
            local attributes = get_block_attributes(block) --, { clip = true })
            local execution_result_block =
                c_create_execution_result_block(
                    c_check_includes(block.text),
                    attributes
                )
            if execution_result_block then
                table.insert(list_of_blocks, execution_result_block)
            end
        end
    end

    return list_of_blocks
end


local function c_run_as_standalone(block)
    local element = block
    if block.attr.classes:includes("{c}") and
        not block.attr.classes:includes("runenv") then
        pandoc.system.with_temporary_directory("running_c",
            function(temporary_directory)
                pandoc.system.with_working_directory(temporary_directory,
                    function()
                        element = c_run(block)
                        return nil
                    end
                )
                return nil
            end
        )
    end

    return element
end



-- ---------------------------------------------
-- RunEnv


local function mark_runenv_codeblocks(div)
    local function mark_codeblocks_filter(block)
        if block.attr.classes:includes("{c}") or
            block.attr.classes:includes("{bash}") then
            block.attr.classes =
                pandoc.List(insert_to_table(block.attr.classes, "runenv"))
        end
        return block
    end

    if div.attr.classes:includes("runenv") then
        div = div:walk({ CodeBlock = mark_codeblocks_filter })
    end

    return div
end


local function run_codeblock(block)
    local element
    if block.attr.classes:includes("{c}") then
        element = c_run(block)
    elseif block.attr.classes:includes("{bash}") then
        element = bash_run(block)
    elseif block.attr.classes:includes("textfile") then
        element = process_text_files(block)
    else
        element = block
    end
    return element
end


local function run_runenv_codeblocks(div)
    if div.attr.classes:includes("runenv") then
        pandoc.system.with_temporary_directory("running_runenv",
            function(temporary_directory)
                pandoc.system.with_working_directory(temporary_directory,
                    function()
                        div = div:walk({ CodeBlock = run_codeblock })
                        return nil
                    end
                )
                return nil
            end
        )
    end

    return div
end

local latex_code = [[
\usetikzlibrary {shapes.geometric}
\newcommand*\invalidchar[1]{\tikz[baseline=(char.base)]{
            \node[fill=black,shape=diamond,draw,inner sep=0pt] (char) {\scriptsize\color{white} #1};}
}
\newunicodechar{�}{\invalidchar{?}}
\newunicodechar{‘}{\'{}}
\newunicodechar{’}{\'{}}

\catcode0=9  % for terminal
\catcode7=9  % for terminal
]]


function initialize(meta)
    if quarto.doc.is_format("pdf") then
        quarto.doc.use_latex_package("newunicodechar")
        quarto.doc.use_latex_package("tikz")
        quarto.doc.include_text("in-header", latex_code)
    end

    return meta
end

return {
    { Meta = initialize },
    { Div = mark_runenv_codeblocks },
    { Div = run_runenv_codeblocks },
    { CodeBlock = c_run_as_standalone },
    { CodeBlock = bash_run_as_standalone },
}
