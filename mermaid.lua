-- Mermaid filter with caption support

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

-- Extract caption from code
local function extract_caption(code)
    -- Look for special comment: %% caption: Your caption text
    local caption_line = code:match("^%s*%%%% caption:%s*(.-)%s*\n")
    if caption_line and caption_line ~= "" then
        return caption_line
    end
    
    -- Look for title comment: %% title: Your title text (fallback)
    local title_line = code:match("^%s*%%%% title:%s*(.-)%s*\n")
    if title_line and title_line ~= "" then
        return title_line
    end
    
    -- Default caption
    return "Mermaid diagram"
end

function CodeBlock(block)
    if block.classes and block.classes[1] == "mermaid" then
        local output_dir = "mermaid-images"
        ensure_directory_exists(output_dir)
        
        -- Extract caption
        local caption_text = extract_caption(block.text)
        
        -- Remove caption line from the mermaid code
        local mermaid_code = block.text:gsub("^%s*%%%% caption:%s*.-\n", "")
        
        local image_file = get_filename(mermaid_code)
        local image_path = output_dir .. "\\" .. image_file
        
        local tmp_file = os.getenv("TEMP") .. "\\mermaid-temp.mmd"
        local f = io.open(tmp_file, "w")
        if not f then
            io.stderr:write("Error: Cannot create temporary file\n")
            return block
        end
        
        f:write(mermaid_code)
        f:close()
        
        -- Universal parameters for all diagram types
        local command = string.format('mmdc -i "%s" -o "%s" -w 800 -h 600 --scale 1.5 --backgroundColor white', 
                                    tmp_file, image_path)
        local success = os.execute(command)
        os.remove(tmp_file)
        
        if success then
            local caption = {pandoc.Str(caption_text)}
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
