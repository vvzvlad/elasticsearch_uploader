local inspect = require '../libs/inspect'
local fio = require 'fio'

local system = {}

function system.concatenate_args(...)
  local arguments = {...}
  local msg = ""
  local count_args = select("#", ...)
  for i = 1, count_args do
    local new_msg = arguments[i]
    if (type(new_msg) == "table") then
        new_msg = tostring(inspect(new_msg))
    else
        new_msg = tostring(new_msg)
    end
    if (new_msg ~= nil and new_msg ~= "" and type(new_msg) == "string" and type(msg) == "string") then
        if (i == 1) then
          msg = new_msg
        else
          msg = msg.."\t"..new_msg
        end
    end
  end
  return msg
end


function system.read_file(filename)
  local fh, err = fio.open(filename)
  if (fh == nil) then
    print("Error:", filename, err)
    os.exit()
  else
    local file_data = fh:read()
    fh:close()
    return file_data
  end
end


function system.get_files_in_dir(path, mask)
  local files = {}
  local i = 1
  for _, item in pairs(fio.listdir(path)) do
    if (string.find(item, mask) ~= nil) then
        files[i] = path.."/"..item
        i = i + 1
    end
  end
  return files
end



function system.write_file(filename, data)
  local fh, err = fio.open(filename, {"O_CREAT", "O_SYNC", "O_WRONLY", "O_APPEND"})
  fio.chmod(filename, tonumber('0755', 8))
  if (fh == nil) then
    print("Error:", filename, err)
    os.exit()
  else
    local status = fh:write(data)
    fh:close()
    fio.sync()
    return status
  end
end

function system.split_text(text, size)
  local raw_chunks_iterator = 1
  local raw_chunks = {}
  for current_chunk in string.gmatch(text, ".-\n") do
    raw_chunks[raw_chunks_iterator] = current_chunk
    raw_chunks_iterator = raw_chunks_iterator + 1
  end
  print("Text split: "..raw_chunks_iterator.." chunks")

  local processed_chunk_iterator = 1
  local processed_chunks = {""}
  for _, current_chunk in pairs(raw_chunks) do
    local current_processed_chunk_iter = #processed_chunks[processed_chunk_iterator]
    if (current_processed_chunk_iter > size) then
        processed_chunk_iterator = processed_chunk_iterator + 1
    end
    processed_chunks[processed_chunk_iterator] = (processed_chunks[processed_chunk_iterator] or "")..(current_chunk or "")
  end
  print("Chunks processed: "..processed_chunk_iterator.." big chunks")

  return processed_chunks
end


function system.split_string(inputstr, sep)
  local t = {}
  for str in string.gmatch(inputstr, "([^"..(sep or "%s").."]+)") do
    local str2 = string.gsub(str, "^%s*(.-)%s*$", "%1")
    table.insert(t, str2)
  end
  return t
end

return system
