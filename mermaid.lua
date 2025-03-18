-- Mermaid filter with general size constraints

-- Function to create a unique filename based on content
local function get_filename(code)
    local hash = ""
    for i = 1, math.min(#code, 10) do
        hash = hash .. string.format("%02x", string.byte(code, i))
    end
    return "mermaid-" .. hash .. ".png"
end

local function ensure_directory_exists(dir)
    os.execute('if not exist "' .. dir .. '" mkdir "' .. dir .. '"')
end

function CodeBlock(block)
    if block.classes and block.classes[1] == "mermaid" then
        local output_dir = "mermaid-images"
        ensure_directory_exists(output_dir)
        
        local image_file = get_filename(block.text)
        local image_path = output_dir .. "\\" .. image_file
        
        local tmp_file = os.getenv("TEMP") .. "\\mermaid-temp.mmd"
        local f = io.open(tmp_file, "w")
        if not f then
            io.stderr:write("Error: Cannot create temporary file\n")
            return block
        end
        
        f:write(block.text)
        f:close()
        
        -- Universal parameters for all diagram types that help with PDF fitting
        local command = string.format('mmdc -i "%s" -o "%s" -w 800 -h 600 --scale 1.5 --backgroundColor white', 
                                    tmp_file, image_path)
        local success = os.execute(command)
        os.remove(tmp_file)
        
        if success then
            local caption = {pandoc.Str("Mermaid diagram")}
            local src = output_dir .. "/" .. image_file
            local attr = pandoc.Attr("", {"mermaid-diagram"}, {})
            return pandoc.Para{pandoc.Image(caption, src, "", attr)}
        else
            io.stderr:write("Warning: Failed to render mermaid diagram\n")
            return block
        end
    end
    
    return block
end

return {
    { CodeBlock = CodeBlock }
}
