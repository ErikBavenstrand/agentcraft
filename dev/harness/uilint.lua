-- UI lint: static checks for the [lint] rules in dev/ui-rules.md.
--   luajit dev/harness/uilint.lua <addonDir>
-- As a module (dev/tests/16_uilint.lua): require("uilint").LintSource(src, rel, ctx).
--
-- It tokenizes each file (comments and strings handled properly), tracks
-- function boundaries and names, and runs the rules over the token stream.
-- A finding is suppressed by a comment "-- ui-ok: <reason>" on the same line
-- or the line above. Exit code: 1 when there are errors, else 0.
local M = {}

M.RULES = {
  R1 = { id = "no-slide", sev = "ERROR" },
  R2 = { id = "scale-anim", sev = "WARN" },
  R3 = { id = "long-alpha", sev = "WARN" },
  R4 = { id = "pixelutil-deprecated", sev = "ERROR" },
  R5 = { id = "pixel-snap-off", sev = "ERROR" },
  R6 = { id = "atlas-texcoord", sev = "ERROR" },
  R7 = { id = "create-in-refresh", sev = "ERROR" },
  R8 = { id = "onupdate-churn", sev = "ERROR" },
  R9 = { id = "dataprovider-reset", sev = "ERROR" },
  R10 = { id = "tint-stock-art", sev = "WARN" },
  R11 = { id = "round-layout", sev = "ERROR" },
  R12 = { id = "opaque-highlight", sev = "ERROR" },
  R13 = { id = "hover-focus", sev = "ERROR" },
}

-- Tokenizer ----------------------------------------------------------------------------

local KEYWORDS = {}
for w in ("and break do else elseif end false for function goto if in local nil not or repeat return then true until while"):gmatch("%S+") do KEYWORDS[w] = true end

-- Returns tokens { t = "name"|"kw"|"string"|"number"|"op", v, line } and
-- comments { [line] = { text, ... } } (a long comment is filed under every line it spans).
function M.Tokenize(src)
  local toks, comments = {}, {}
  local i, n, line = 1, #src, 1
  local function addComment(text, l1, l2)
    for l = l1, l2 do
      comments[l] = comments[l] or {}
      table.insert(comments[l], text)
    end
  end
  local function longBracket(pos)
    local eq = src:match("^%[(=*)%[", pos)
    if not eq then return nil end
    local close = "]" .. eq .. "]"
    local s = pos + #eq + 2
    local e = src:find(close, s, true)
    if not e then e = n + 1 - #close end
    return src:sub(s, e - 1), e + #close
  end
  while i <= n do
    local c = src:sub(i, i)
    if c == "\n" then
      line = line + 1; i = i + 1
    elseif c:match("%s") then
      i = i + 1
    elseif src:sub(i, i + 1) == "--" then
      local body, after = longBracket(i + 2)
      if body then
        local l2 = line + select(2, body:gsub("\n", ""))
        addComment(body, line, l2)
        line = l2; i = after
      else
        local e = src:find("\n", i, true) or (n + 1)
        addComment(src:sub(i + 2, e - 1), line, line)
        i = e
      end
    elseif c == '"' or c == "'" then
      local j, buf = i + 1, {}
      local startLine = line
      while j <= n do
        local d = src:sub(j, j)
        if d == "\\" then
          local nx = src:sub(j + 1, j + 1)
          if nx == "\n" then line = line + 1 end
          local map = { n = "\n", t = "\t", r = "\r", a = "\a", b = "\b", f = "\f", v = "\v" }
          if map[nx] then buf[#buf + 1] = map[nx]; j = j + 2
          elseif nx:match("%d") then
            local digits = src:match("^%d%d?%d?", j + 1)
            buf[#buf + 1] = string.char(tonumber(digits) % 256); j = j + 1 + #digits
          else buf[#buf + 1] = nx; j = j + 2 end
        elseif d == c then break
        elseif d == "\n" then break -- unterminated; stop at the line end
        else buf[#buf + 1] = d; j = j + 1 end
      end
      toks[#toks + 1] = { t = "string", v = table.concat(buf), line = startLine }
      i = j + 1
    elseif c == "[" and src:match("^%[=*%[", i) then
      local body, after = longBracket(i)
      toks[#toks + 1] = { t = "string", v = body, line = line }
      line = line + select(2, body:gsub("\n", ""))
      i = after
    elseif c:match("[%a_]") then
      local w = src:match("^[%w_]+", i)
      toks[#toks + 1] = { t = KEYWORDS[w] and "kw" or "name", v = w, line = line }
      i = i + #w
    elseif c:match("%d") or (c == "." and src:sub(i + 1, i + 1):match("%d")) then
      local num = src:match("^0[xX]%x+", i) or src:match("^%d*%.?%d*[eE][%+%-]?%d+", i) or src:match("^%d*%.?%d*", i)
      toks[#toks + 1] = { t = "number", v = num, num = tonumber(num), line = line }
      i = i + #num
    else
      local op = src:match("^%.%.%.", i) or src:match("^[=~<>]=", i) or src:match("^%.%.", i) or src:match("^::", i) or c
      toks[#toks + 1] = { t = "op", v = op, line = line }
      i = i + #op
    end
  end
  return toks, comments
end

-- Structure ----------------------------------------------------------------------------

local function IsOp(tok, v) return tok and tok.t == "op" and tok.v == v end
local function IsKw(tok, v) return tok and tok.t == "kw" and tok.v == v end

-- Index of the token matching the bracket at i (forward for ( [ {, backward for ) ] }).
local PAIR = { ["("] = ")", ["["] = "]", ["{"] = "}" }
local RPAIR = { [")"] = "(", ["]"] = "[", ["}"] = "{" }
local function Match(toks, i)
  local open = toks[i].v
  local depth = 0
  if PAIR[open] then
    for j = i, #toks do
      local t = toks[j]
      if t.t == "op" then
        if t.v == open then depth = depth + 1 elseif t.v == PAIR[open] then depth = depth - 1; if depth == 0 then return j end end
      end
    end
    return #toks
  end
  local want = RPAIR[open]
  for j = i, 1, -1 do
    local t = toks[j]
    if t.t == "op" then
      if t.v == open then depth = depth + 1 elseif t.v == want then depth = depth - 1; if depth == 0 then return j end end
    end
  end
  return 1
end

-- The prefix expression that ends at token e ("self.rows[i].icon"), as text,
-- plus its first token index.
local function ExprBefore(toks, e)
  local j = e
  local s = nil
  while j >= 1 do
    local t = toks[j]
    if t.t == "name" or (t.t == "kw" and t.v == "self") then
      s = j
      local p = toks[j - 1]
      if IsOp(p, ".") or IsOp(p, ":") then j = j - 2 else break end
    elseif IsOp(t, "]") or IsOp(t, ")") then
      local o = Match(toks, j)
      s = o
      j = o - 1
      local p = toks[j]
      if not p or not (p.t == "name" or IsOp(p, "]") or IsOp(p, ")")) then break end
    else
      break
    end
  end
  if not s then return nil end
  local parts = {}
  for k = s, e do
    local t = toks[k]
    parts[#parts + 1] = t.t == "string" and string.format("%q", t.v) or t.v
  end
  return table.concat(parts), s
end
M.ExprBefore = ExprBefore

-- A name chain that starts at i ("a.b:c"), as text, and its last index.
local function ChainAt(toks, i)
  if not (toks[i] and toks[i].t == "name") then return nil end
  local parts, j = { toks[i].v }, i
  while (IsOp(toks[j + 1], ".") or IsOp(toks[j + 1], ":")) and toks[j + 2] and toks[j + 2].t == "name" do
    parts[#parts + 1] = toks[j + 1].v .. toks[j + 2].v
    j = j + 2
  end
  return table.concat(parts), j
end

-- Name of the assignment target that ends at token e (before "="), or nil.
local function TargetBefore(toks, e)
  local text = ExprBefore(toks, e)
  return text
end

-- Builds function records: { name, kind ("OnUpdate"|"OnEvent"|nil), s, e
-- (token range), line, eline, parent }, and fnOf[tokenIndex] = innermost fn.
local function Structure(toks, scriptNames)
  local fns, fnOf = {}, {}
  local stack = {} -- blocks: { kind = "function"|"block", fn = rec }
  local pendingDo = 0
  local current = nil
  for i, t in ipairs(toks) do
    fnOf[i] = current
    if t.t == "kw" then
      local v = t.v
      if v == "function" then
        local rec = { s = i, line = t.line, parent = current }
        local nx = toks[i + 1]
        if IsKw(toks[i - 1], "local") and nx and nx.t == "name" then
          rec.name = nx.v
        elseif nx and nx.t == "name" then
          rec.name = ChainAt(toks, i + 1)
        else
          local p = toks[i - 1]
          if IsOp(p, "=") then
            rec.name = TargetBefore(toks, i - 2)
          elseif (IsOp(p, ",") or IsOp(p, "(")) then
            -- SetScript("OnUpdate", function ...) / HookScript(...)
            local s3, p3, c4 = toks[i - 2], toks[i - 3], toks[i - 4]
            if IsOp(p, ",") and s3 and s3.t == "string" and IsOp(p3, "(") and c4 and c4.t == "name"
              and (c4.v == "SetScript" or c4.v == "HookScript") then
              rec.kind = s3.v
              rec.name = s3.v
            end
          end
        end
        if rec.name and scriptNames[rec.name:match("[%w_]+$") or ""] and not rec.kind then
          rec.kind = scriptNames[rec.name:match("[%w_]+$")]
        end
        fns[#fns + 1] = rec
        stack[#stack + 1] = { kind = "function", fn = rec }
        current = rec
        fnOf[i] = rec
      elseif v == "if" or v == "repeat" then
        stack[#stack + 1] = { kind = v }
      elseif v == "while" or v == "for" then
        stack[#stack + 1] = { kind = v }
        pendingDo = pendingDo + 1
      elseif v == "do" then
        if pendingDo > 0 then pendingDo = pendingDo - 1 else stack[#stack + 1] = { kind = "do" } end
      elseif v == "end" or v == "until" then
        local b = table.remove(stack)
        if b and b.kind == "function" then
          b.fn.e = i
          b.fn.eline = t.line
          current = b.fn.parent
        end
      end
    end
  end
  for _, f in ipairs(fns) do
    if not f.e then f.e = #toks; f.eline = toks[#toks] and toks[#toks].line or f.line end
  end
  return fns, fnOf
end

-- Calls --------------------------------------------------------------------------------

-- Every call: { i (name token), name, method (bool), recv (text or nil),
-- chain ("UI.Anim.SlideIn"), open, close, args = { {s, e}, ... }, line }.
local function Calls(toks)
  local out = {}
  for i, t in ipairs(toks) do
    local nx = toks[i + 1]
    if t.t == "name" and nx and (IsOp(nx, "(") or nx.t == "string" or IsOp(nx, "{")) then
      local c = { i = i, name = t.v, line = t.line }
      local p = toks[i - 1]
      if IsOp(p, ":") then
        c.method = true
        c.recv = ExprBefore(toks, i - 2)
      end
      local chainText, cs = ExprBefore(toks, i)
      c.chain = chainText
      c.chainStart = cs
      if IsOp(nx, "(") then
        c.open = i + 1
        c.close = Match(toks, i + 1)
        local args, s, depth = {}, i + 2, 0
        for j = i + 2, c.close - 1 do
          local a = toks[j]
          if a.t == "op" then
            if PAIR[a.v] then depth = depth + 1 elseif RPAIR[a.v] then depth = depth - 1
            elseif a.v == "," and depth == 0 then args[#args + 1] = { s = s, e = j - 1 }; s = j + 1 end
          end
        end
        if s <= c.close - 1 then args[#args + 1] = { s = s, e = c.close - 1 } end
        c.args = args
      else
        c.open, c.close = i + 1, (IsOp(nx, "{") and Match(toks, i + 1) or i + 1)
        c.args = { { s = i + 1, e = c.close } }
      end
      out[#out + 1] = c
    end
  end
  return out
end

local function ArgText(toks, a)
  if not a then return nil end
  local parts = {}
  for k = a.s, a.e do
    local t = toks[k]
    parts[#parts + 1] = t.t == "string" and string.format("%q", t.v) or t.v
  end
  return table.concat(parts, " ")
end

local function ArgString(toks, a)
  if a and a.s == a.e and toks[a.s].t == "string" then return toks[a.s].v end
end

-- Lint ---------------------------------------------------------------------------------

local NO_SLIDE = { SlideIn = true, Bump = true, Squish = true, Drift = true, Cascade = true }
local CREATE = { CreateFrame = true, CreateTexture = true, CreateFontString = true }
local REFRESH_NAME = { "Refresh", "Update", "OnUpdate", "OnEvent", "Layout", "Render" }
local CHURN = { SetAtlas = true, SetTexture = true, SetPoint = true, ClearAllPoints = true, Show = true, Hide = true }
local STOCK_ART = { "ui%-frame%-", "metal", "bronze", "parchment", "ui%-character%-info" }
local POOL_NAMES = { CreateFramePool = true, CreateObjectPool = true, CreateTexturePool = true, CreateFontStringPool = true,
  CreateSecureFramePool = true, ObjectPool = true, Acquire = true, acquire = true, Pool = true }

local function Lower(s) return (s or ""):lower() end

local function IsFxFile(rel) return rel:gsub("\\", "/"):match("UI/Fx%.lua$") ~= nil end

-- Pre-pass over all files: ART role tables (UI.ART = { key = { "atlas", ... } }).
function M.CollectArt(src, art)
  art = art or {}
  local toks = M.Tokenize(src)
  for i, t in ipairs(toks) do
    if t.t == "name" and t.v == "ART" and IsOp(toks[i + 1], "=") and IsOp(toks[i + 2], "{") then
      local close = Match(toks, i + 2)
      local j = i + 3
      while j < close do
        if toks[j].t == "name" and IsOp(toks[j + 1], "=") then
          local key = toks[j].v
          local strs = {}
          local k = j + 2
          if IsOp(toks[k], "{") then
            local c2 = Match(toks, k)
            for q = k, c2 do if toks[q].t == "string" then strs[#strs + 1] = toks[q].v end end
            j = c2 + 1
          else
            if toks[k] and toks[k].t == "string" then strs[1] = toks[k].v end
            j = k + 1
          end
          art[key] = table.concat(strs, " ")
        else
          j = j + 1
        end
      end
    end
  end
  return art
end

-- Text of the art a setter call names: string literals in its args, plus
-- ART.key lookups.
local function ArtText(toks, c, ctx)
  local parts = {}
  local first = c.method and 1 or 2
  for ai = first, #(c.args or {}) do
    local a = c.args[ai]
    for k = a.s, a.e do
      local t = toks[k]
      if t.t == "string" then parts[#parts + 1] = t.v
      elseif t.t == "name" and t.v == "ART" and IsOp(toks[k + 1], ".") and toks[k + 2] and toks[k + 2].t == "name" then
        parts[#parts + 1] = (ctx.art or {})[toks[k + 2].v] or ""
      end
    end
  end
  return table.concat(parts, " ")
end

-- A texture-setting call: returns (receiverText, kind "atlas"|"texture").
local function Setter(toks, c)
  if c.name == "SetAtlas" or c.name == "SetTexture" or c.name == "SetColorTexture" then
    local kind = c.name == "SetAtlas" and "atlas" or "texture"
    if c.method then return c.recv, kind end
    -- helper form: UI.SetAtlas(tex, ...) / SetAtlas(tex, ...)
    if c.args and c.args[1] then return ArgText(toks, c.args[1]):gsub(" ", ""), kind end
  end
end

local function Suppressed(comments, line)
  for _, l in ipairs({ line, line - 1 }) do
    for _, text in ipairs(comments[l] or {}) do
      if text:match("ui%-ok:") then return true end
    end
  end
  return false
end

local function LastPart(name) return name and name:match("[%w_]+$") or "" end

local function NameMatchesRefresh(name)
  local last = LastPart(name)
  for _, w in ipairs(REFRESH_NAME) do if last:find(w, 1, true) then return true end end
  return false
end

-- Line texts with strings blanked and comments dropped, for guard patterns:
-- a space only between two words ("if not self.bg then", "x=x or y").
local function CodeLines(toks)
  local lines, prev = {}, {}
  for _, t in ipairs(toks) do
    local v = t.t == "string" and '""' or t.v
    local word = t.t == "name" or t.t == "kw" or t.t == "number"
    local cur = lines[t.line]
    if cur and word and prev[t.line] then cur = cur .. " " end
    lines[t.line] = (cur or "") .. v
    prev[t.line] = word
  end
  return lines
end

-- Lints one file. rel: path relative to the addon ("UI/Window.lua").
-- ctx (optional): { art = map from CollectArt }. Returns a list of findings
-- { rule, id, sev, file, line, msg }.
function M.LintSource(src, rel, ctx)
  ctx = ctx or {}
  rel = rel:gsub("\\", "/")
  local toks, comments = M.Tokenize(src)
  local findings = {}
  local function add(rule, line, msg)
    if Suppressed(comments, line) then return end
    local r = M.RULES[rule]
    findings[#findings + 1] = { rule = rule, id = r.id, sev = r.sev, file = rel, line = line, msg = msg }
  end

  -- SetScript("OnUpdate", Handler): Handler (a named function) runs as OnUpdate.
  local scriptNames = {}
  for i, t in ipairs(toks) do
    if t.t == "name" and (t.v == "SetScript" or t.v == "HookScript") and IsOp(toks[i + 1], "(")
      and toks[i + 2] and toks[i + 2].t == "string" and IsOp(toks[i + 3], ",") then
      local kind = toks[i + 2].v
      if (kind == "OnUpdate" or kind == "OnEvent") and toks[i + 4] and toks[i + 4].t == "name" then
        local chain, last = ChainAt(toks, i + 4)
        if IsOp(toks[last + 1], ")") then scriptNames[LastPart(chain)] = kind end
      end
    end
  end

  local fns, fnOf = Structure(toks, scriptNames)
  local calls = Calls(toks)
  local lines = CodeLines(toks)
  local fx = IsFxFile(rel)

  -- Innermost enclosing function that is a SetScript closure of `kind`.
  local function InScript(i, kind)
    local f = fnOf[i]
    while f do
      if f.kind == kind then return f end
      f = f.parent
    end
  end
  -- Innermost named (or script) function: anonymous closures inherit.
  local function Named(i)
    local f = fnOf[i]
    while f and not f.name and not f.kind do f = f.parent end
    return f
  end

  -- Texture setters per function, in order, for R6 and R10.
  local setters = {} -- list of { i, recv, kind, fn, art }
  for _, c in ipairs(calls) do
    local recv, kind = Setter(toks, c)
    if recv then setters[#setters + 1] = { i = c.i, recv = recv, kind = kind, fn = fnOf[c.i], art = ArtText(toks, c, ctx) } end
  end
  local function LastSetter(recv, i, fn, fileWide)
    local best
    for _, s in ipairs(setters) do
      if s.i < i and s.recv == recv and (fileWide or s.fn == fn) then best = s end
    end
    return best
  end
  local function AnySetter(recv, fn, kind)
    for _, s in ipairs(setters) do if s.recv == recv and s.fn == fn and s.kind == kind then return true end end
  end

  for _, c in ipairs(calls) do
    local name, line = c.name, c.line
    local fn = fnOf[c.i]

    -- R1 / R2: Translation and Scale animations ("CreateAnimation", or a
    -- helper with "Anim" in its name, given the kind as a string).
    if name == "CreateAnimation" or name:find("Anim", 1, true) then
      for _, a in ipairs(c.args or {}) do
        local s = ArgString(toks, a)
        if s == "Translation" then
          add("R1", line, name .. '("Translation"): no slide animations (ui-rules 1); show/hide instantly')
        elseif s == "Scale" then
          local nf = Named(c.i)
          local fname = Lower(nf and nf.name)
          local exempt = fx and (fname:find("ring") or fname:find("focus") or fname:find("glow"))
          if not exempt then add("R2", line, name .. '("Scale"): no Scale animations on content (ui-rules 1); only focus/glow art in UI/Fx.lua') end
        end
      end
    end
    -- R1: callers of the retired motion helpers.
    if NO_SLIDE[name] and not fx and c.chain and c.chain:match("Anim[%.:]" .. name .. "$") then
      add("R1", line, c.chain .. "(): slide/bump/squish/drift/cascade motion is retired (ui-rules 1, 4); remove the call")
    end

    -- R3: long Alpha/Scale animations.
    if name == "SetDuration" and c.method and c.args and c.args[1] then
      local a = c.args[1]
      local maxNum, capped = nil, false
      for k = a.s, a.e do
        local t = toks[k]
        if t.t == "number" and t.num then maxNum = math.max(maxNum or t.num, t.num) end
        if (t.t == "name" and (t.v == "min" or t.v == "Clamp")) or IsOp(t, "/") then capped = true end
      end
      if maxNum and maxNum > 1 and not capped then
        -- What kind of animation is the receiver? Look for its assignment in the function.
        local kind
        local lo, hi = fn and fn.s or 1, fn and fn.e or #toks
        for k = lo, hi do
          local t = toks[k]
          if IsOp(t, "=") and not IsOp(toks[k + 1], "=") then
            local target = ExprBefore(toks, k - 1)
            if target == c.recv then
              local l = toks[k].line
              for q = k + 1, hi do
                if toks[q].line ~= l then break end
                local v = toks[q].t == "string" and toks[q].v
                if v == "Alpha" or v == "Scale" or v == "Translation" or v == "TextureCoordTranslation" or v == "Rotation" or v == "Path" then kind = v end
              end
            end
          end
        end
        if kind == "Alpha" or kind == "Scale" then
          local glow = false
          local nf = Named(c.i)
          if nf and Lower(nf.name):match("glow") or (nf and Lower(nf.name):match("highlight")) then glow = true end
          for k = lo, hi do
            local t = toks[k]
            if t.t == "name" then
              local lv = t.v:lower()
              if lv:find("glow") or lv:find("highlight") or lv:find("hilite") then glow = true break end
            end
          end
          if not glow then add("R3", line, string.format("%s animation of %gs: longer than 1 s and not on a glow/highlight (ui-rules 3)", kind, maxNum)) end
        end
      end
    end

    -- R4: deprecated PixelUtil sizing.
    if (name == "SetSize" or name == "SetPoint") and c.chain and c.chain:match("PixelUtil%." .. name .. "$") then
      add("R4", line, "PixelUtil." .. name .. " is deprecated; call SetRoundLayoutToNearestPixel on the window root instead (ui-rules 5)")
    end

    -- R5: pixel snapping off.
    if c.method and (name == "SetSnapToPixelGrid" or name == "SetTexelSnappingBias") and c.args and c.args[1] then
      local a = c.args[1]
      local t = toks[a.s]
      if a.s == a.e and ((name == "SetSnapToPixelGrid" and IsKw(t, "false")) or (name == "SetTexelSnappingBias" and t.t == "number" and t.num == 0)) then
        add("R5", line, name .. "(" .. t.v .. ") turns pixel snapping off; Blizzard does that only on scaled/animated art (ui-rules 6)")
      end
    end

    -- R6: SetTexCoord on an atlas texture.
    if name == "SetTexCoord" and c.method and c.recv then
      local last = LastSetter(c.recv, c.i, fn, false)
      local bad = (last and last.kind == "atlas") or (not last and AnySetter(c.recv, fn, "atlas") and not AnySetter(c.recv, fn, "texture"))
      if bad then add("R6", line, c.recv .. ":SetTexCoord on a texture that uses an atlas (ui-rules 7); the atlas carries its own coordinates") end
    end

    -- R7: creating objects in refresh/update/event code.
    if CREATE[name] and (c.method or name == "CreateFrame") then
      local nf = Named(c.i)
      local ctxName = nf and (nf.kind or nf.name)
      local hot = nf and (nf.kind == "OnUpdate" or nf.kind == "OnEvent" or NameMatchesRefresh(nf.name))
      if hot then
        local guarded = false
        -- Cache pattern near the call: if not x then / x = x or / x or Create...
        local REF = "[%w_%.%[%]\"]+"
        for l = math.max(line - 3, nf.line), line do
          local text = lines[l] or ""
          if text:match("if not " .. REF .. " then") or text:match("if not%(" .. REF) then guarded = true end
          for target in text:gmatch("(" .. REF .. ")=[^=]") do
            local esc = target:gsub("%p", "%%%0")
            if text:match(esc .. "=" .. esc .. " or ") then guarded = true end
          end
        end
        -- Early-out guard in the function (if self.built then return end) before the call.
        for l = nf.line, line - 1 do
          if (lines[l] or ""):match("if " .. REF .. " then return") then guarded = true end
        end
        -- Pools anywhere in the hot function.
        for k = nf.s, nf.e do
          local t = toks[k]
          if t.t == "name" and (POOL_NAMES[t.v] or t.v:find("Pool", 1, true)) then guarded = true break end
        end
        if not guarded then
          add("R7", line, string.format("%s inside %s: create once (pool, or 'if not x then' guard) and toggle (ui-rules 10)", name, ctxName))
        end
      end
    end

    -- R8: churn from OnUpdate.
    if CHURN[name] and InScript(c.i, "OnUpdate") then
      if c.method or name == "SetAtlas" then
        add("R8", line, name .. " inside an OnUpdate script: do it when state changes, not every frame (ui-rules 11)")
      end
    end

    -- R9: SetDataProvider without RetainScrollPosition.
    if name == "SetDataProvider" and c.method and c.args and #c.args < 2 then
      add("R9", line, "SetDataProvider without ScrollBoxConstants.RetainScrollPosition resets scroll and rebuilds every row (ui-rules 13)")
    end

    -- R10: tinting stock bronze/metal/parchment art.
    if (name == "SetVertexColor" or name == "SetDesaturated") and c.method and c.recv then
      local last = LastSetter(c.recv, c.i, fn, false)
      if not last and c.recv:find(".", 1, true) then last = LastSetter(c.recv, c.i, fn, true) end
      if last then
        local art = Lower(last.art)
        for _, pat in ipairs(STOCK_ART) do
          if art:find(pat) then
            add("R10", line, string.format("%s on %s, which shows stock art (%s): never tint bronze/metal/parchment art (ui-rules 9)", name, c.recv, last.art))
            break
          end
        end
      end
    end
  end

  -- R11: the window root rounds layout to whole pixels.
  if rel:match("UI/Window%.lua$") then
    local found = false
    for _, t in ipairs(toks) do
      if t.t == "name" and (t.v == "SetRoundLayoutToNearestPixel" or t.v == "SetRoundLayoutToNearestPixelRecursively") then found = true break end
    end
    if not found and not Suppressed(comments, 1) then
      add("R11", 1, "UI/Window.lua never calls SetRoundLayoutToNearestPixel / PixelUtil.SetRoundLayoutToNearestPixelRecursively on the window root (ui-rules 5)")
    end
  end

  -- R12: a HIGHLIGHT-layer texture draws above icon and text; unless it is
  -- additive it blanks what it covers (the macro cards in game).
  -- R12 and R13 read the raw source lines: CodeLines blanks strings, and both
  -- rules look for string arguments ("HIGHLIGHT", "ADD", "OnEnter").
  local raw = {}
  for text in (src .. "\n"):gmatch("([^\n]*)\n") do raw[#raw + 1] = text end
  for l, text in ipairs(raw) do
    local var = text:match("([%w_%.]+)%s*=%s*[%w_%.]+:CreateTexture%(%s*nil%s*,%s*\"HIGHLIGHT\"")
    if var and not Suppressed(comments, l) then
      local esc = var:gsub("%p", "%%%0")
      local ok = false
      for k = l, math.min(l + 12, #raw) do
        if (raw[k] or ""):find(esc .. ":SetBlendMode%(%s*\"ADD\"%s*%)") then ok = true break end
      end
      if not ok then add("R12", l, var .. " is a HIGHLIGHT texture without SetBlendMode(\"ADD\"): opaque hover art covers the icon and text (ui-rules 20)") end
    end
  end

  -- R13: hovering never moves the focus or fills the Inspector; a click does.
  for l, text in ipairs(raw) do
    if text:find("\"OnEnter\"", 1, true) and not Suppressed(comments, l) then
      -- A one-line handler ("function(self) ... end)") ends on its own line.
      local last = text:find("end%)%s*$") and l or math.min(l + 8, #raw)
      for k = l, last do
        local t = raw[k] or ""
        if t:find("Focus:Set%(") or t:find("Focus%.Set%(") or t:find(":Inspect%(") then
          add("R13", l, "an OnEnter handler moves the focus or fills the Inspector; hover shows only highlight and tooltip, a click focuses (ui-rules 21)")
          break
        end
        if k > l and t:match("^%s*end%)") then break end
      end
    end
  end

  table.sort(findings, function(a, b) return a.line < b.line end)
  return findings, { fns = fns }
end

-- Files --------------------------------------------------------------------------------

local function ReadFile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

function M.ListLua(dir)
  local out = {}
  local cmd
  if package.config:sub(1, 1) == "\\" then cmd = 'dir /b /s /on "' .. dir:gsub("/", "\\") .. '\\*.lua" 2>nul'
  else cmd = 'find "' .. dir .. '" -name "*.lua" 2>/dev/null' end
  local p = io.popen(cmd)
  if p then
    for line in p:lines() do
      line = line:gsub("\r$", ""):gsub("\\", "/")
      if line:match("%.lua$") then out[#out + 1] = line end
    end
    p:close()
  end
  table.sort(out)
  return out
end

-- Lints every .lua under addonDir. Returns findings (sorted: errors first,
-- then file and line) and the number of files read.
function M.LintDir(addonDir)
  addonDir = addonDir:gsub("\\", "/"):gsub("/$", "")
  local files = M.ListLua(addonDir)
  local srcs, art = {}, {}
  for _, path in ipairs(files) do
    local s = ReadFile(path)
    if s then
      srcs[path] = s
      M.CollectArt(s, art)
    end
  end
  local all = {}
  for _, path in ipairs(files) do
    local s = srcs[path]
    if s then
      -- Relative to the addon dir (dir /s prints absolute paths).
      local rel = path
      local lowerPath, lowerDir = path:lower(), addonDir:lower()
      local at = lowerPath:find(lowerDir, 1, true)
      if at then rel = path:sub(at + #addonDir + 1) end
      for _, f in ipairs(M.LintSource(s, rel, { art = art })) do all[#all + 1] = f end
    end
  end
  local order = { ERROR = 0, WARN = 1 }
  table.sort(all, function(a, b)
    if order[a.sev] ~= order[b.sev] then return order[a.sev] < order[b.sev] end
    if a.file ~= b.file then return a.file < b.file end
    return a.line < b.line
  end)
  return all, #files
end

local function Main(addonDir)
  if not addonDir then
    io.stderr:write("usage: uilint.lua <addonDir>\n")
    os.exit(2)
  end
  local all, nfiles = M.LintDir(addonDir)
  local errors, warns = 0, 0
  local perRule = {}
  for _, f in ipairs(all) do
    print(string.format("%-5s [%s %s] %s:%d", f.sev, f.rule, f.id, f.file, f.line))
    print("      " .. f.msg)
    if f.sev == "ERROR" then errors = errors + 1 else warns = warns + 1 end
    perRule[f.rule] = (perRule[f.rule] or 0) + 1
  end
  if #all == 0 then print("  no findings") end
  local keys = {}
  for k in pairs(perRule) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tonumber(a:sub(2)) < tonumber(b:sub(2)) end)
  local parts = {}
  for _, k in ipairs(keys) do parts[#parts + 1] = k .. " " .. M.RULES[k].id .. ": " .. perRule[k] end
  print("")
  if #parts > 0 then print("by rule: " .. table.concat(parts, ", ")) end
  print(string.format("lint-ui: %d file(s), %d error(s), %d warning(s)", nfiles, errors, warns))
  os.exit(errors > 0 and 1 or 0)
end

if ... ~= "uilint" then Main(...) end

return M
