local M = { }
local escape_pattern
do
  local _obj_0 = require("lapis.util")
  escape_pattern = _obj_0.escape_pattern
end
M.log = function(msg)
  return ngx.log(ngx.NOTICE, msg)
end
M.log_err = function(msg)
  return ngx.log(ngx.ERR, msg)
end
M.split = function(str, delim)
  str = str .. delim
  local _accum_0 = { }
  local _len_0 = 1
  for part in str:gmatch("(.-)" .. escape_pattern(delim)) do
    _accum_0[_len_0] = part
    _len_0 = _len_0 + 1
  end
  return _accum_0
end
return M