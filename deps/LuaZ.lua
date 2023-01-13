--[[--------------------------------------------------------------------

  lzio.lua
  Lua buffered streams in Lua
  This file is part of Yueliang.

  Copyright (c) 2005-2006 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

local luaZ = {}

------------------------------------------------------------------------
-- * reader() should return a string, or nil if nothing else to parse.
--   Additional data can be set only during stream initialization
-- * Readers are handled in lauxlib.c, see luaL_load(file|buffer|string)
-- * LUAL_BUFFERSIZE=BUFSIZ=512 in make_getF() (located in luaconf.h)
-- * Original Reader typedef:
--   const char * (*lua_Reader) (lua_State *L, void *ud, size_t *sz);
-- * This Lua chunk reader implementation:
--   returns string or nil, no arguments to function
------------------------------------------------------------------------

------------------------------------------------------------------------
-- create a chunk reader from a source string
------------------------------------------------------------------------
function luaZ:make_getS(buff)
	local b = buff
	return function() -- chunk reader anonymous function here
		if not b then return nil end
		local data = b
		b = nil
		return data
	end
end

------------------------------------------------------------------------
-- create a chunk reader from a source file
------------------------------------------------------------------------
--[[
function luaZ:make_getF(filename)
  local LUAL_BUFFERSIZE = 512
  local h = io.open(filename, "r")
  if not h then return nil end
  return function() -- chunk reader anonymous function here
    if not h or io.type(h) == "closed file" then return nil end
    local buff = h:read(LUAL_BUFFERSIZE)
    if not buff then h:close(); h = nil end
    return buff
  end
end
--]]
------------------------------------------------------------------------
-- creates a zio input stream
-- returns the ZIO structure, z
------------------------------------------------------------------------
function luaZ:init(reader, data, name)
	if not reader then return end
	local z = {}
	z.reader = reader
	z.data = data or ""
	z.name = name
	-- set up additional data for reading
	if not data or data == "" then z.n = 0 else z.n = #data end
	z.p = 0
	return z
end

------------------------------------------------------------------------
-- fill up input buffer
------------------------------------------------------------------------
function luaZ:fill(z)
	local buff = z.reader()
	z.data = buff
	if not buff or buff == "" then return "EOZ" end
	z.n, z.p = #buff - 1, 1
	return string.sub(buff, 1, 1)
end

------------------------------------------------------------------------
-- get next character from the input stream
-- * local n, p are used to optimize code generation
------------------------------------------------------------------------
function luaZ:zgetc(z)
	local n, p = z.n, z.p + 1
	if n > 0 then
		z.n, z.p = n - 1, p
		return string.sub(z.data, p, p)
	else
		return self:fill(z)
	end
end

return luaZ