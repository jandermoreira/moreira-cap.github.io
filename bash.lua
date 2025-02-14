-- bash.lua


local function read_from_file(path)
    local content = ""
    local file = io.open(path, "rb")
    if file then
        content = file:read "*a"
        file:close()
    end
    return content
end


local function create_execution_result_block(run, bash_code)
    local result_block = nil
    local file = io.open("__output.result.full", "w")
    if file then
        line_commands = string.gsub(bash_code, "\\\n", "${NOTHING}")
        for command in string.gmatch(line_commands, "[^\n]*") do
            -- quarto.log.output("<" .. command .. ">")
            if run then 
                file:write("$ ")  -- prompt
            end
            file:write("\0" .. string.gsub(command, "${NOTHING}", "\0\\\n\0") .. "\0\n")
            if run then
                os.execute("(" .. command .. ") > __output.result 2>&1")
                execution_result = read_from_file("__output.result")
                file:write(execution_result)
            end
        end
        file:close()
        block_contents = read_from_file("__output.result.full")
        result_block = pandoc.CodeBlock(block_contents, {})
        if run then 
            result_block.attr.classes = pandoc.List({ "terminal", "cell-code" })
        else
            result_block.attr.classes = pandoc.List({ "bash", "cell-code" })
        end
    end
    return result_block
end


local function run_bash(block)
    local block = block
    local is_bash = block.attr.classes:includes("bash")
    local is_runnable_bash = block.attr.classes:includes("{bash}")
    if is_bash or is_runnable_bash then
        pandoc.system.with_temporary_directory(
            "running_bash",
            function(temporary_directory)
                pandoc.system.with_working_directory(
                    temporary_directory,
                    function()
                        block = create_execution_result_block(is_runnable_bash, block.text)
                        return nil
                    end
                )
                return nil
            end
        )
    end
    return block
end

return {
    CodeBlock = run_bash
}
