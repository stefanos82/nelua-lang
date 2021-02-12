-- Stringer module
--
-- Stringer module contains some utilities for working with lua strings.

local hasher = require 'hasher'

local stringer = {}

-- Compute a hash with the desired length for a string.
-- The hash uses the Blake2B algorithm and is encoded in Base58.
-- This is used to generate unique names for large strings.
function stringer.hash(s, len, key)
  len = len or 20
  local hash = hasher.blake2b(s, len, key)
  return hasher.base58encode(hash)
end

-- Concatenate many arguments into a string separated by tabular (similar to lua print).
function stringer.pconcat(...)
  local t = table.pack(...)
  for i=1,t.n do
    t[i] = tostring(t[i])
  end
  return table.concat(t, '\t')
end

-- Like string.format but skip format when not passing any argument.
function stringer.pformat(format, ...)
  if select('#', ...) == 0 then
    return format
  end
  return string.format(format, ...)
end

-- Checks if a string starts with a prefix.
function stringer.startswith(s, prefix)
  return string.find(s,prefix,1,true) == 1
end

-- Checks if a string ends with a prefix.
function stringer.endswith(s, suffix)
  return #s >= #suffix and string.find(s, suffix, #s-#suffix+1, true) and true or false
end

-- Returns a string with right white spaces trimmed.
function stringer.rtrim(s)
  return (s:gsub("%s*$", ""))
end

-- Split a string into a table using a separator (default to space).
function stringer.split(s, sep)
  sep = sep or ' '
  local res = {}
  local pattern = string.format("([^%s]+)", sep or ' ')
  for each in s:gmatch(pattern) do
    table.insert(res, each)
  end
  return res
end

-- Returns the character at position `i` of a string.
function stringer.at(s, i)
  return string.sub(s, i, i)
end

-- Extract line number, column number and line content from a position in a multi line text.
function stringer.calcline(s, i)
  if i == 1 then
    local lineend = s:find("\n", 1, true)
    lineend = lineend and lineend-1 or #s
    local line = s:sub(1, lineend)
    return 1, 1, line, 1, lineend
  end
  local subs = s:sub(1,i)
  local rest, lineno = subs:gsub("[^\n]*\n", "")
  lineno = 1 + lineno
  local colno = #rest
  colno = colno ~= 0 and colno or 1
  local linestart = subs:find("\n[^\n]*$")
  linestart = linestart and linestart+1 or 1
  local lineend = s:find("\n", i+1, true)
  lineend = lineend and lineend-1 or #s
  local line = s:sub(linestart, lineend)
  return lineno, colno, line, linestart, lineend
end

-- Extract a specific line from a text.
function stringer.getline(text, lineno)
  if lineno <= 0 then return nil end
  local linestart
  if lineno > 1 then
    local l = 1
    for pos in text:gmatch('\n()') do
      l = l + 1
      if l >= lineno then
        linestart = pos
        break
      end
    end
    if not linestart then return nil end -- not found
  else --luacov:disable
    linestart = 1
  end --luacov:enable
  local lineend = text:find('\n', linestart, true)
  lineend = lineend and lineend-1 or nil
  return text:sub(linestart, lineend), linestart, lineend
end

-- Insert a text in the middle of string and return the new string.
function stringer.insert(s, pos, text)
  return s:sub(1, pos-1)..text..s:sub(pos)
end

-- Insert a text after another matched text and return the new string.
function stringer.insertafter(s, matchtext, text)
  local matchpos = s:find(matchtext, 1, true)
  if matchpos then
    return stringer.insert(s, matchpos+#matchtext+1, text)
  end
end

return stringer
