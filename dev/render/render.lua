-- Offline renderer for the Agentcraft window (Lua 5.1 / LuaJIT).
--   luajit dev/render/render.lua <addonDir> <outDir> [texturesDir]
-- Boots the addon in the harness with the hunter fixture (pet on, two
-- library macros installed), opens /ac, selects every page with
-- ns.OpenPage(id) and writes <outDir>/<page-id>.html plus index.html.
-- Each page is drawn on a 1280x800 (Steam Deck) and a 1920x1080 canvas at
-- 1:1 UI pixels, with a list of layout warnings.
--
-- Also writes:
--   <outDir>/warnings.txt          every warning, per page
--   <outDir>/textures-missing.txt  "<normalized path>\t<path as the addon wrote it>"
--                                  for textures with no PNG (dev.ps1 render -Fetch reads it)
--   <outDir>/textures-used.txt     every texture path, atlas and file ID drawn
-- Exit code 0, or 1 when the addon raised Lua errors while rendering.
local addonDir, outDir, texDir = arg[1], arg[2], arg[3]
assert(addonDir and outDir, "usage: render.lua <addonDir> <outDir> [texturesDir]")
local here = (arg[0]:gsub("\\", "/"):match("^(.*)/[^/]*$")) or "."
texDir = (texDir or (here .. "/textures")):gsub("\\", "/"):gsub("/$", "")
outDir = outDir:gsub("\\", "/"):gsub("/$", "")
addonDir = addonDir:gsub("\\", "/"):gsub("/$", "")
package.path = here .. "/../harness/?.lua;" .. here .. "/?.lua;" .. package.path

local H = require("harness")
H.addonDir = addonDir
H.harnessDir = here .. "/../harness"
local frames = require("frames")
local layout = require("layout")

local CANVASES = { { key = "deck", w = 1280, h = 800, label = "1280x800 (Steam Deck)" },
  { key = "hd", w = 1920, h = 1080, label = "1920x1080" } }

-- Helpers ----------------------------------------------------------------------------

local function esc(s)
  return (tostring(s or ""):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end
local function n2(v) return string.format("%.2f", v):gsub("%.?0+$", "") end
local function px(v) return n2(v) .. "px" end
local function rgba(c, a)
  local alpha = (c[4] or 1) * (a or 1)
  return string.format("rgba(%d,%d,%d,%s)", math.floor((c[1] or 1) * 255 + 0.5), math.floor((c[2] or 1) * 255 + 0.5),
    math.floor((c[3] or 1) * 255 + 0.5), n2(alpha))
end
local function exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end
local function Short(text, n)
  text = tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "[icon]"):gsub("\n", " / ")
  n = n or 40
  if #text > n then return text:sub(1, n - 3) .. "..." end
  return text
end

-- Texture paths: "Interface\\Icons\\Foo.blp" -> "interface/icons/foo"
local function NormalizePath(p)
  p = tostring(p):gsub("\\", "/"):lower():gsub("%.blp$", ""):gsub("%.tga$", ""):gsub("%.png$", "")
  return p
end

-- Optional extra data: atlases.lua returns { [atlasName] = { file=, l=, r=, t=, b=, w=, h= } },
-- fileids.lua returns { [fileID] = "Interface\\Icons\\..." }.
local function LoadOptional(name)
  local f = loadfile(here .. "/" .. name)
  if not f then return {} end
  local ok, t = pcall(f)
  return ok and type(t) == "table" and t or {}
end
local ATLASES = LoadOptional("atlases.lua")
local FILEIDS = LoadOptional("fileids.lua")
-- <texDir>/unavailable.txt ("<rel>\t<reason>", written by dev.ps1 render -Fetch):
-- textures no public mirror has. Their warnings say "not mirrored".
local UNAVAILABLE = {}
do
  local f = io.open(texDir .. "/unavailable.txt", "rb")
  if f then
    for line in f:lines() do
      local rel, why = line:gsub("\r$", ""):match("^([^\t]+)\t?(.*)$")
      if rel then UNAVAILABLE[rel] = why end
    end
    f:close()
  end
end

-- dev/render/forever-only.txt ("<atlas>\t<source file>"): WoW Forever atlases
-- the retail atlas tables lack. A missing PNG for one of these is an info
-- line, not a warning; a name not on the list stays a warning, so invented
-- names can't hide there.
local FOREVER_ONLY, infos = {}, {}
do
  local f = io.open(here .. "/forever-only.txt", "rb")
  if f then
    for line in f:lines() do
      line = line:gsub("\r$", "")
      local name, src = line:match("^([^#%s][^\t]*)\t?(.*)$")
      if name then FOREVER_ONLY[name:lower()] = src ~= "" and src or "Forever UI source" end
    end
    f:close()
  end
end

-- Resolves a texture to { rel = "interface/..", png = bool, label = "..", key = ".." , coords = {l,r,t,b} }.
local textureUse = {}   -- key -> { label=, original=, png=, count=, template=bool }
local function ResolveTexture(t)
  local original, rel, coords, label, atlas
  if t._atlas then
    local a = ATLASES[t._atlas] or ATLASES[t._atlas:lower()]
    label = "atlas " .. t._atlas
    original = "atlas:" .. t._atlas
    if a then
      -- The sheet: its path, else its file ID (through fileids.lua or fileid/<n>).
      local file = a.file or (a.fileID and FILEIDS[a.fileID])
      rel = file and NormalizePath(file) or ("fileid/" .. tostring(a.fileID))
      coords, atlas = { a.l or 0, a.r or 1, a.t or 0, a.b or 1 }, a
    else
      rel = "atlas/" .. t._atlas:lower()
    end
  elseif type(t._file) == "number" then
    local p = FILEIDS[t._file]
    label = "fileID " .. t._file .. (p and (" (" .. p .. ")") or "")
    original = p or ("fileID:" .. t._file)
    rel = p and NormalizePath(p) or ("fileid/" .. t._file)
  elseif type(t._file) == "string" and tonumber(t._file) then
    return ResolveTexture({ _file = tonumber(t._file), _fromTemplate = t._fromTemplate })
  elseif type(t._file) == "string" then
    label, original, rel = t._file, t._file, NormalizePath(t._file)
    -- A bare icon name (macro icons): the client looks in Interface\Icons.
    if not rel:find("/") then rel = "interface/icons/" .. rel; original = "Interface\\Icons\\" .. t._file end
  else
    return nil
  end
  local png = exists(texDir .. "/" .. rel .. ".png")
  local u = textureUse[rel]
  if not u then
    u = { label = label, original = original, rel = rel, png = png, count = 0, template = true }
    if not png and UNAVAILABLE[rel] then u.label = label .. " (not mirrored)" end
    textureUse[rel] = u
  end
  u.count = u.count + 1
  if not t._fromTemplate then u.template = false end
  return { rel = rel, png = png, label = label, coords = coords, atlas = atlas }
end

-- Fonts -------------------------------------------------------------------------------

local FACE_CSS = {
  friz = "font-family:'Friz Quadrata TT','Friz Quadrata',FrizQuadrata,'Palatino Linotype','Book Antiqua',Georgia,serif",
  arialn = "font-family:'Arial Narrow',ArialNarrow,Arial,sans-serif;font-stretch:condensed",
}
-- scale: the font string's effective scale. The client draws text at its
-- frame's scale and boxes here are laid out in scaled page pixels, so the CSS
-- size must be scaled too, or a 1.1-scaled pad window hides wraps the client shows.
-- shadow: the font string's SetShadowColor { r, g, b, a } (nil = the font's own).
-- offset: its SetShadowOffset { x, y } (nil = 1, -1).
local function FontCSS(spec, color, spacing, scale, shadow, offset)
  scale = scale or 1
  local parts = { FACE_CSS[spec.face] or FACE_CSS.friz, "font-size:" .. px((spec.size or 12) * scale),
    "line-height:" .. px(frames.LineHeight(spec, spacing) * scale), "color:" .. rgba(color) }
  if spec.outline then
    parts[#parts + 1] = "text-shadow:-1px 0 #000,1px 0 #000,0 -1px #000,0 1px #000"
  else
    -- A shadowed font defaults to offset (1, -1); others draw none until SetShadowOffset.
    local sc = shadow or { 0, 0, 0, 1 }
    local ox, oy = 0, 0
    if spec.shadow then ox, oy = 1, -1 end
    if offset then ox, oy = offset[1] or 0, offset[2] or 0 end
    if (sc[4] or 1) > 0 and (ox ~= 0 or oy ~= 0) then
      -- WoW offsets are y-up; CSS is y-down.
      parts[#parts + 1] = string.format("text-shadow:%s %s 0 %s", px(ox * scale), px(-oy * scale),
        rgba({ sc[1] or 0, sc[2] or 0, sc[3] or 0, sc[4] or 1 }))
    end
  end
  return table.concat(parts, ";")
end

local function MarkupHTML(text, spec, scale)
  local out = {}
  for _, run in ipairs(frames.ParseMarkup(text)) do
    if run.icon then
      local size = (run.size > 0 and run.size or (spec.size or 12)) * (scale or 1)
      local atlas = run.icon:match("^atlas:(.+)$")
      local res = ResolveTexture(atlas and { _atlas = atlas } or { _file = run.icon })
      -- An atlas missing from atlases.lua resolves to atlas/<name> (no PNG), so it
      -- draws the striped placeholder and shows up under missing textures.
      if res and res.png then
        local w, bg = size, ""
        if res.atlas and res.coords then
          -- Crop the atlas out of its sheet, as the Texture path does.
          local a, c = res.atlas, res.coords
          if a.w and a.h and a.h > 0 then w = size * a.w / a.h end
          local bw, bh = w / math.max(c[2] - c[1], 1e-4), size / math.max(c[4] - c[3], 1e-4)
          bg = string.format(";background-size:%s %s;background-position:%s %s", px(bw), px(bh), px(-c[1] * bw), px(-c[3] * bh))
        end
        out[#out + 1] = string.format('<span class="ic" title="%s" style="width:%s;height:%s;background-image:url(\'../textures/%s.png\')%s"></span>',
          esc(run.icon), px(w), px(size), esc(res.rel), bg)
      else
        out[#out + 1] = string.format('<span class="ic ph" title="%s" style="width:%s;height:%s"></span>', esc(run.icon), px(size), px(size))
      end
    else
      local t = esc(run.text)
      if run.color then t = '<span style="color:' .. rgba(run.color) .. '">' .. t .. "</span>" end
      out[#out + 1] = t
    end
  end
  return table.concat(out)
end

-- Naming ------------------------------------------------------------------------------
-- Frames are mostly anonymous; name them after the field or local that holds
-- them: global name > a local in an addon file > a page field > parent field.

local function IsObj(v) return type(v) == "table" and rawget(v, "_world") ~= nil end

local function BuildNames(env)
  local names = {}
  local function put(o, n, prio)
    local cur = names[o]
    if not cur or cur.prio > prio then names[o] = { name = n, prio = prio } end
  end
  -- Upvalues of the addon's functions (UI/Window.lua: frame, nav, body, footer, ...).
  local seenFn = {}
  local function scanFn(fn, depth)
    if seenFn[fn] or depth > 3 then return end
    seenFn[fn] = true
    local info = debug.getinfo(fn, "S")
    local file = (info.short_src or ""):match("([^/\\]+)%.lua$") or "?"
    for i = 1, 200 do
      local k, v = debug.getupvalue(fn, i)
      if not k then break end
      if IsObj(v) then put(v, file .. ":" .. k, 2)
      elseif type(v) == "function" then scanFn(v, depth + 1) end
    end
  end
  local function scanTable(t, depth, seen)
    if seen[t] or depth > 2 then return end
    seen[t] = true
    for _, v in pairs(t) do
      if type(v) == "function" then scanFn(v, 0)
      elseif type(v) == "table" and not IsObj(v) then scanTable(v, depth + 1, seen) end
    end
  end
  scanTable(env.ns, 0, {})
  -- Page fields.
  for _, page in ipairs(env.ns.pages) do
    for k, v in pairs(page) do
      if type(k) == "string" then
        if IsObj(v) then put(v, page.id .. "." .. k, 3)
        elseif type(v) == "table" then
          for k2, v2 in pairs(v) do
            if IsObj(v2) then put(v2, page.id .. "." .. k .. "[" .. tostring(k2) .. "]", 4)
            elseif type(v2) == "table" and not IsObj(v2) then
              for k3, v3 in pairs(v2) do
                if IsObj(v3) then put(v3, page.id .. "." .. k .. "[" .. tostring(k2) .. "][" .. tostring(k3) .. "]", 4) end
              end
            end
          end
        end
      end
    end
  end
  return names
end

local function MakeLabeler(names)
  local cache = {}
  local function label(o)
    if cache[o] then return cache[o] end
    local s
    if o._name then s = o._name
    elseif names[o] then s = names[o].name
    else
      local p = o._parent
      local key
      if p then
        for k, v in pairs(p) do
          if v == o and type(k) == "string" and not k:find("^_") then key = k break end
          if type(k) == "string" and not k:find("^_") and type(v) == "table" and not IsObj(v) then
            for i, x in pairs(v) do if x == o then key = k .. "[" .. tostring(i) .. "]" break end end
            if key then break end
          end
        end
      end
      if p and key then s = label(p) .. "." .. key
      elseif p then s = label(p) .. "/" .. o._type .. "#" .. o._id
      else s = o._type .. "#" .. o._id end
    end
    cache[o] = s
    return s
  end
  return label
end

-- Drawing -----------------------------------------------------------------------------

local function Intersect(a, b)
  if not a then return b end
  if not b then return a end
  local r = { l = math.max(a.l, b.l), r = math.min(a.r, b.r), t = math.max(a.t, b.t), b = math.min(a.b, b.b) }
  return r
end
local function Empty(r) return r.r - r.l <= 0.01 or r.b - r.t <= 0.01 end
local function Area(r) return math.max(0, r.r - r.l) * math.max(0, r.b - r.t) end

local function HasContent(o)
  if o._type == "FontString" then return (o._text or "") ~= "" end
  if o._region then return o._color ~= nil or o._file ~= nil or o._atlas ~= nil or o._ring ~= nil end
  return o._backdrop ~= nil or o._unknownTemplates ~= nil or (o._type == "EditBox" and (o._text or "") ~= "")
end

-- Whether a region draws, given its frame's button/edit state.
local function RegionVisible(r, f)
  if not r._shown then return false end
  if r._mask then return false end  -- masks shape other textures; they don't draw
  if r._layer == "HIGHLIGHT" then return false end
  local st = r._buttonState
  local disabled = f._enabled == false
  if st == "pushed" or st == "highlight" then return false end
  if st == "normal" and disabled and rawget(f, "_disabledTexture") and f._disabledTexture._file then return false end
  if st == "disabled" and not disabled then return false end
  if st == "checked" and (not f._checked or disabled) then return false end
  if st == "disabledChecked" and not (f._checked and disabled) then return false end
  if r._searchInstructions and (f._text or "") ~= "" then return false end
  return true
end

-- Collects every visible object under root with its rectangle, clip and order.
local function Collect(root, solver)
  local items, frameList, order = {}, {}, 0
  local function walk(f, strata, level, clip, alpha)
    if not f._shown then return end
    strata = f._strata or strata
    level = f._level or (level + 1)
    order = order + 1
    local rect = solver:Rect(f)
    local fa = alpha * (f._alpha or 1)
    local entry = { obj = f, strata = frames.STRATA_INDEX[strata] or 4, level = level, order = order, clip = clip,
      alpha = fa, rect = rect, regions = {} }
    frameList[#frameList + 1] = entry
    local childClip = clip
    if rect and (f._type == "ScrollFrame" or f._clips) then childClip = Intersect(clip, rect) end
    local regionClip = f._clips and childClip or clip
    for _, r in ipairs(f._regions or {}) do
      if RegionVisible(r, f) then
        entry.regions[#entry.regions + 1] = { obj = r, frame = entry, clip = regionClip,
          alpha = fa * (r._alpha or 1), rect = solver:Rect(r) }
      end
    end
    table.sort(entry.regions, function(a, b)
      local la, lb = frames.LAYERS[a.obj._layer] or 3, frames.LAYERS[b.obj._layer] or 3
      if la ~= lb then return la < lb end
      if (a.obj._sublevel or 0) ~= (b.obj._sublevel or 0) then return (a.obj._sublevel or 0) < (b.obj._sublevel or 0) end
      return a.obj._id < b.obj._id
    end)
    for _, c in ipairs(f._children or {}) do
      -- A scroll frame clips its scroll child; its scroll bar sits outside it.
      local cc = childClip
      if f._type == "ScrollFrame" and not f._clips and c ~= f._scrollChild then cc = clip end
      walk(c, strata, level, cc, fa)
    end
  end
  local base = root._level and (root._level - 1) or 0
  walk(root, root:GetFrameStrata(), base, nil, 1)
  table.sort(frameList, function(a, b)
    if a.strata ~= b.strata then return a.strata < b.strata end
    if a.level ~= b.level then return a.level < b.level end
    return a.order < b.order
  end)
  for _, e in ipairs(frameList) do
    items[#items + 1] = e
    for _, r in ipairs(e.regions) do items[#items + 1] = r end
  end
  return items, frameList
end

local function Box(rect, clip)
  local s = string.format("left:%s;top:%s;width:%s;height:%s", px(rect.l), px(rect.t), px(rect.r - rect.l), px(rect.b - rect.t))
  if clip then
    local t, r, b, l = math.max(0, clip.t - rect.t), math.max(0, rect.r - clip.r), math.max(0, rect.b - clip.b), math.max(0, clip.l - rect.l)
    if t > 0 or r > 0 or b > 0 or l > 0 then
      s = s .. string.format(";clip-path:inset(%s %s %s %s)", px(t), px(r), px(b), px(l))
    end
  end
  return s
end

local function TextureCSS(t, frame, rect)
  local css, cls, title = {}, "r tx"
  local file = t._file
  -- Disabled UIPanelButtonTemplate art.
  if frame._enabled == false and frame._disabledArt and t._fromTemplate and file == "Interface\\Buttons\\UI-Panel-Button-Up" then
    file = frame._disabledArt[1]
  end
  local v = t._vertex or { 1, 1, 1, 1 }
  if t._ring then
    css[#css + 1] = "border:3px solid " .. rgba(t._ring) .. ";border-radius:50%;box-sizing:border-box"
    return cls, table.concat(css, ";"), "portrait ring (template)"
  end
  local white = type(file) == "string" and NormalizePath(file) == "interface/buttons/white8x8"
  if t._gradient and (white or t._color) then
    -- SetGradient on a WHITE8x8 texture: minColor at the bottom (VERTICAL) or left.
    local g = t._gradient
    local function C(c)
      if type(c) ~= "table" then return "rgba(0,0,0,0)" end
      return rgba({ c.r or c[1] or 1, c.g or c[2] or 1, c.b or c[3] or 1, c.a or c[4] or 1 })
    end
    local dir = tostring(g[1]):upper() == "HORIZONTAL" and "to right" or "to top"
    css[#css + 1] = "background:linear-gradient(" .. dir .. "," .. C(g[2]) .. "," .. C(g[3]) .. ")"
    title = "gradient " .. tostring(g[1])
  elseif white then
    -- Our own flat art: WHITE8x8 tinted with SetVertexColor.
    css[#css + 1] = "background:" .. rgba({ v[1], v[2], v[3], 1 }, v[4])
    title = "WHITE8x8 tinted " .. rgba(v)
  elseif t._color then
    local c = t._color
    css[#css + 1] = "background:" .. rgba({ c[1] * v[1], c[2] * v[2], c[3] * v[3], c[4] }, v[4])
    title = "colour " .. rgba(c)
  else
    local res = ResolveTexture({ _file = file, _atlas = t._atlas, _fromTemplate = t._fromTemplate })
    if not res then return nil end
    title = res.label
    if res.png then
      local w, h = rect.r - rect.l, rect.b - rect.t
      local tc = t._texcoord or res.coords or { 0, 1, 0, 1 }
      local l, r, tt, b = tc[1], tc[2], tc[3], tc[4]
      local flipX, flipY = r < l, b < tt
      if flipX then l, r = r, l end
      if flipY then tt, b = b, tt end
      local bw, bh = w / math.max(r - l, 1e-4), h / math.max(b - tt, 1e-4)
      -- A tiling atlas repeats at its own size along the tiled axis. CSS can only
      -- repeat the whole image, so that needs the atlas to span the sheet there.
      local a, rep = not t._texcoord and res.atlas, nil
      local tileX = a and a.tileH and a.w and l < 0.001 and r > 0.999
      local tileY = a and a.tileV and a.h and tt < 0.001 and b > 0.999
      if tileX then bw = a.w end
      if tileY then bh = a.h end
      if tileX or tileY then rep = tileX and tileY and "repeat" or tileX and "repeat-x" or "repeat-y" end
      local url = "url('../textures/" .. res.rel .. ".png')"
      local pos = string.format("%s %s", px(-l * bw), px(-tt * bh))
      local size = string.format("%s %s", px(bw), px(bh))
      css[#css + 1] = "background-image:" .. url .. ";background-size:" .. size .. ";background-position:" .. pos
      if rep then css[#css + 1] = "background-repeat:" .. rep end
      if v[1] < 0.999 or v[2] < 0.999 or v[3] < 0.999 then
        -- Vertex colour multiplies the image; the mask keeps its alpha.
        css[#css + 1] = "background-color:" .. rgba({ v[1], v[2], v[3] }) .. ";background-blend-mode:multiply"
        css[#css + 1] = "-webkit-mask-image:" .. url .. ";-webkit-mask-size:" .. size .. ";-webkit-mask-position:" .. pos
          .. ";mask-image:" .. url .. ";mask-size:" .. size .. ";mask-position:" .. pos
      end
      if v[4] < 0.999 then css[#css + 1] = "--va:" .. n2(v[4]) end
      if flipX or flipY then css[#css + 1] = string.format("transform:scale(%d,%d)", flipX and -1 or 1, flipY and -1 or 1) end
    elseif t._atlas and frames.ATLASES[t._atlas:lower()] and frames.ATLASES[t._atlas:lower()][3] then
      -- A known atlas without a PNG: its stand-in colour from frames.ATLASES.
      local a = frames.ATLASES[t._atlas:lower()]
      local c = a[3]
      local col = rgba({ c[1] * v[1], c[2] * v[2], c[3] * v[3], c[4] }, v[4])
      if a[4] == "ring" then
        css[#css + 1] = "border:2px solid " .. col .. ";box-sizing:border-box"
      else
        css[#css + 1] = "background:" .. col
      end
      cls = cls .. " fb"
      title = title .. " (missing: drawn as its stand-in colour)"
    elseif t._fallback then
      local c = t._fallback
      css[#css + 1] = "background:" .. rgba({ c[1] * v[1], c[2] * v[2], c[3] * v[3], c[4] }, v[4])
      cls = cls .. " fb"
      title = title .. " (missing: drawn as a flat colour)"
    else
      cls = cls .. ((res.rel:find("^interface/icons/") or res.rel:find("^fileid/")) and " ph" or " ph art")
      title = title .. " (missing PNG)"
      if cls:find(" ph$") and (rect.r - rect.l) >= 28 and (rect.b - rect.t) >= 12 then
        t._phLabel = (res.label:match("([^\\/:]+)$") or res.label)
      end
    end
  end
  if t._desaturated then css[#css + 1] = "filter:grayscale(1)" end
  if t._blend == "ADD" then css[#css + 1] = "mix-blend-mode:plus-lighter" end
  local round = t._circle
  for _, m in ipairs(t._masks or {}) do
    if tostring(m._file or ""):lower():find("portraitalphamask") then round = true end
  end
  if round then css[#css + 1] = "border-radius:50%" end
  return cls, table.concat(css, ";"), title
end

-- Warnings ------------------------------------------------------------------------------

local function Warn(list, kind, obj, msg)
  list[#list + 1] = { kind = kind, id = obj and obj._id, site = obj and obj._site, msg = msg }
end

local function IsDescendant(o, root)
  while o do if o == root then return true end o = o._parent end
  return false
end
-- Made by a template (frames.lua marks every object a template creates).
-- Only the object itself counts: the page lives inside the window template's
-- Inset, and what the addon builds there is still the addon's.
local function FromTemplate(o)
  return o._fromTemplate == true
end
local function IsControl(o)
  return not o._region and (o._type == "Button" or o._type == "CheckButton" or o._type == "EditBox" or o._type == "Slider")
end

-- The part of a font string's box its text actually covers.
local function TextExtent(fs, rect)
  local spec = fs:Spec()
  local need = frames.MeasureText(fs._text or "", spec) * rect.scale
  local w = rect.r - rect.l
  local constrained = fs._w or frames.AxisKinds(fs._points, "h") >= 2
  local wraps = constrained and fs._wordWrap ~= false
  if wraps and need > w then return { l = rect.l, r = rect.r, t = rect.t, b = rect.b } end
  local tw = math.min(need, w)
  if not constrained then tw = need end
  local j = fs._justifyH or "CENTER"
  local l
  if j == "LEFT" then l = rect.l elseif j == "RIGHT" then l = rect.r - tw else l = (rect.l + rect.r) / 2 - tw / 2 end
  local lines = wraps and frames.CountLines(fs._text or "", spec, w / rect.scale) or 1
  local th = math.min(rect.b - rect.t, lines * frames.LineHeight(spec, fs._spacing) * rect.scale)
  local jv = fs._justifyV or "MIDDLE"
  local t
  if jv == "TOP" then t = rect.t elseif jv == "BOTTOM" then t = rect.b - th else t = (rect.t + rect.b) / 2 - th / 2 end
  return { l = l, r = l + tw, t = t, b = t + th }
end

local function Check(root, items, frameList, solver, label, warnings, pageFrame)
  local rootRect = solver:Rect(root)
  local visible = {}
  for _, it in ipairs(items) do visible[it.obj] = it end

  for _, it in ipairs(items) do
    local o, rect = it.obj, it.rect
    -- Unresolved anchors.
    if not rect then
      if HasContent(o) or not o._region then
        Warn(warnings, "unresolved", o, label(o) .. ": " .. tostring(solver.problems[o] or "no rectangle"))
      end
    end
    for _, why in ipairs(o._badAnchors or {}) do Warn(warnings, "unresolved", o, label(o) .. ": " .. why) end
    if o._unknownTemplates then
      Warn(warnings, "unknown-template", o, label(o) .. " inherits " .. table.concat(o._unknownTemplates, ", ")
        .. ", which the renderer doesn't emulate (drawn as a dashed box)")
    end
    if o._backdropWithoutTemplate then
      Warn(warnings, "api", o, label(o) .. ": SetBackdrop on a frame without BackdropTemplate (an error on the modern client)")
    end
    if rect then
      local w, h = rect.r - rect.l, rect.b - rect.t
      -- Zero size with content.
      if (w < 0.5 or h < 0.5) and not FromTemplate(o) then
        if o._region and HasContent(o) then
          Warn(warnings, "zero-size", o, string.format("%s: %s with %s has size %sx%s%s", label(o), o._type,
            o._type == "FontString" and ("text '" .. Short(o._text) .. "'") or "a texture", n2(w), n2(h),
            solver.notes[o] and (" (" .. solver.notes[o] .. ")") or ""))
        elseif not o._region then
          local content = false
          for _, r in ipairs(it.regions or {}) do if HasContent(r.obj) then content = true break end end
          for _, c in ipairs(o._children or {}) do if c._shown then content = true break end end
          if content then
            Warn(warnings, "zero-size", o, string.format("%s: frame is %sx%s but has visible content%s", label(o), n2(w), n2(h),
              solver.notes[o] and (" (" .. solver.notes[o] .. ")") or ""))
          end
        end
      end
      -- Text that doesn't fit.
      if o._type == "FontString" and (o._text or "") ~= "" then
        local spec = o:Spec()
        local need = frames.MeasureText(o._text, spec) * rect.scale
        local constrainedW = o._w or frames.AxisKinds(o._points, "h") >= 2
        local wraps = constrainedW and o._wordWrap ~= false
        if constrainedW and not wraps and need > w + 1 then
          Warn(warnings, "overflow", o, string.format("%s: '%s' is truncated (needs ~%spx, box is %spx)", label(o),
            Short(o._text), n2(need), n2(w)))
        end
        if wraps then
          -- A single word wider than the box: the client breaks it mid-word
          -- ("Counterattac" / "k"), which reads as a bug even when it fits.
          for word in frames.PlainText(o._text):gmatch("%S+") do
            local ww = frames.MeasureText(word, spec) * rect.scale
            if ww > w + 1 then
              Warn(warnings, "overflow", o, string.format("%s: word '%s' breaks mid-word (needs ~%spx, box is %spx)", label(o),
                Short(word), n2(ww), n2(w)))
              break
            end
          end
          local lines = frames.CountLines(o._text, spec, w / rect.scale)
          local needH = lines * frames.LineHeight(spec, o._spacing) * rect.scale
          local constrainedH = (o._h ~= nil) or frames.AxisKinds(o._points, "v") >= 2
          if constrainedH and needH > h + 1 then
            Warn(warnings, "overflow", o, string.format("%s: '%s' is cut off (needs %d lines, ~%spx; box is %spx)", label(o),
              Short(o._text), lines, n2(needH), n2(h)))
          end
        end
        local p = o._parent
        local pr = p and visible[p] and visible[p].rect
        if pr and Area(pr) > 0 and not o._buttonText then
          local ext = TextExtent(o, rect)
          local over = {}
          if ext.l >= pr.l - 1 and ext.l < pr.r and ext.r > pr.r + 2 then over[#over + 1] = n2(ext.r - pr.r) .. "px past the right edge" end
          if ext.t >= pr.t - 1 and ext.t < pr.b and ext.b > pr.b + 2 then over[#over + 1] = n2(ext.b - pr.b) .. "px past the bottom" end
          if #over > 0 and not FromTemplate(o) then
            Warn(warnings, "overflow", o, string.format("%s: '%s' spills out of %s (%s)", label(o), Short(o._text), label(p),
              table.concat(over, ", ")))
          end
        end
        if o._buttonText and p and visible[p] and visible[p].rect then
          local br = visible[p].rect
          if need > (br.r - br.l) - 4 then
            Warn(warnings, "overflow", o, string.format("%s: button text '%s' (~%spx) is wider than its button (%spx)",
              label(p), Short(o._text), n2(need), n2(br.r - br.l)))
          end
        end
      end
    end
  end

  -- Outside the window, or outside the page area (the page's own frame):
  -- the topmost object that leaves it.
  -- Frames flagged _acOutsideOK (the side tabs) sit outside the window on purpose.
  local function OutsideOK(o)
    while o do if rawget(o, "_acOutsideOK") then return true end o = o._parent end
    return false
  end
  local function Outside(box, boxName, within, kind)
    if not box then return end
    local reported = {}
    for _, it in ipairs(items) do
      local o, rect = it.obj, it.rect
      if rect and o ~= within and not FromTemplate(o) and IsDescendant(o, within) and (HasContent(o) or not o._region)
        and not OutsideOK(o)
        and not reported.skip then
        local vis = Intersect(it.clip, rect)
        if o._type == "FontString" then vis = Intersect(it.clip, TextExtent(o, rect)) end
        if not Empty(vis) and not (o._type == "FontString" and (o._text or "") == "") then
          local out = {}
          if vis.l < box.l - 1 then out[#out + 1] = n2(box.l - vis.l) .. "px left" end
          if vis.r > box.r + 1 then out[#out + 1] = n2(vis.r - box.r) .. "px right" end
          if vis.t < box.t - 1 then out[#out + 1] = n2(box.t - vis.t) .. "px above" end
          if vis.b > box.b + 1 then out[#out + 1] = n2(vis.b - box.b) .. "px below" end
          local parentReported = false
          local p = o._parent
          while p do if reported[p] then parentReported = true break end p = p._parent end
          if #out > 0 and not parentReported then
            reported[o] = true
            Warn(warnings, kind, o, string.format("%s sticks out of %s (%s)", label(o), boxName, table.concat(out, ", ")))
          end
        end
      end
    end
  end
  -- Hand-drawn chrome: a flat colour texture bigger than 4x4 that the addon
  -- (not a template) made. The window should use templates and atlases.
  for _, it in ipairs(items) do
    local o, rect = it.obj, it.rect
    if rect and o._region and o._color and not FromTemplate(o) and IsDescendant(o, root) then
      local w, h = (rect.r - rect.l) / rect.scale, (rect.b - rect.t) / rect.scale
      if w > 4 and h > 4 then
        Warn(warnings, "color-fill", o, string.format("%s: SetColorTexture fill %sx%s (use a template or atlas: UI.Inset, UI.Panel, UI.Divider)",
          label(o), n2(w), n2(h)))
      end
    end
  end
  Outside(rootRect, "the window", root, "outside")
  if pageFrame and visible[pageFrame] then
    Outside(visible[pageFrame].rect, "the page area", pageFrame, "outside-page")
  end

  -- Overlapping siblings: controls and text under the same parent.
  for _, fe in ipairs(frameList) do
    local list = {}
    for _, r in ipairs(fe.regions) do
      local o = r.obj
      if o._type == "FontString" and (o._text or "") ~= "" and r.rect and not o._fromTemplate and not o._buttonText then
        list[#list + 1] = { obj = o, rect = Intersect(r.clip, TextExtent(o, r.rect)), kind = "text" }
      end
    end
    for _, c in ipairs(fe.obj._children or {}) do
      local ce = visible[c]
      if ce and ce.rect and IsControl(c) and not c._fromTemplate then
        list[#list + 1] = { obj = c, rect = Intersect(ce.clip, ce.rect), kind = "control" }
      end
    end
    for i = 1, #list do
      for j = i + 1, #list do
        local a, b = list[i], list[j]
        local x = Intersect(a.rect, b.rect)
        if not Empty(x) and (x.r - x.l) > 1 and (x.b - x.t) > 1 then
          local what = a.kind == "text" and ("'" .. Short(a.obj._text, 24) .. "'") or a.obj._type
          local what2 = b.kind == "text" and ("'" .. Short(b.obj._text, 24) .. "'") or b.obj._type
          Warn(warnings, "overlap", a.obj, string.format("%s (%s) overlaps %s (%s) by %sx%spx", label(a.obj), what, label(b.obj), what2,
            n2(x.r - x.l), n2(x.b - x.t)))
        end
      end
    end
  end
end

-- One canvas ------------------------------------------------------------------------------

local function RenderCanvas(env, root, canvas, label, warnings, pageFrame)
  env.W.screen = { w = canvas.w, h = canvas.h }
  local solver = layout.New(env.W, env.W.screen)
  local items, frameList = Collect(root, solver)
  Check(root, items, frameList, solver, label, warnings, pageFrame)

  local out = {}
  for z, it in ipairs(items) do
    local o, rect = it.obj, it.rect
    if rect then
      local vis = it.clip and Intersect(it.clip, rect) or rect
      local clipped = it.clip and Empty(vis)
      local w, h = rect.r - rect.l, rect.b - rect.t
      local info = string.format("%s · %s · %sx%s at %s,%s%s", label(o), o._type, n2(w), n2(h), n2(rect.l), n2(rect.t),
        o._site and (" · " .. o._site) or "")
      local common = string.format('data-oid="%d" data-n="%s" style="%s;z-index:%d;opacity:%s', o._id, esc(info),
        Box(rect, it.clip), z, n2(it.alpha))
      -- An element entirely scrolled out of view draws nothing.
      if clipped then -- luacheck: ignore 542
      elseif not o._region then
        local cls, extra, inner = "f", "", ""
        if o._backdrop then
          local bg = o._backdropColor or { 0, 0, 0, 0 }
          local bd = o._backdropBorderColor or { 1, 1, 1, 1 }
          local es = math.min(o._backdrop.edgeSize or 0, 4)
          extra = extra .. ";background:" .. rgba(bg) .. (o._backdrop.edgeFile and (";border:" .. px(math.max(es, 1)) .. " solid " .. rgba(bd) .. ";box-sizing:border-box") or "")
        end
        if o._unknownTemplates then
          cls = cls .. " unk"
          inner = '<span class="unkl">' .. esc(table.concat(o._unknownTemplates, ", ")) .. "</span>"
        end
        if o._type == "EditBox" and (o._text or "") ~= "" then
          local spec = o:Spec()
          local ins = o._insets or { 0, 0, 0, 0 }
          local tc = o._textColor or spec.color or { 1, 1, 1 }
          inner = inner .. string.format('<div class="eb%s" style="%s;padding:%s %s %s %s">%s</div>', o._multiLine and " ml" or "",
            FontCSS(spec, tc, nil, rect.scale), px(ins[3] * rect.scale), px(ins[2] * rect.scale), px(ins[4] * rect.scale),
            px(ins[1] * rect.scale), MarkupHTML(o._text, spec, rect.scale))
        end
        out[#out + 1] = string.format('<div class="%s" %s%s">%s</div>', cls, common, extra, inner)
      elseif o._type == "FontString" then
        if (o._text or "") ~= "" then
          local fe = it.frame.obj
          local spec = o:Spec()
          if o._buttonText and fe._enabled == false and fe._disabledFont then spec = frames.FontSpec(env.W, fe._disabledFont) end
          local color = o._textColor or spec.color or { 1, 1, 1 }
          if o._buttonText and fe._enabled == false and fe._disabledFont then color = spec.color end
          local constrainedW = o._w or frames.AxisKinds(o._points, "h") >= 2
          local wraps = constrainedW and o._wordWrap ~= false
          local jh = ({ LEFT = "flex-start", RIGHT = "flex-end" })[o._justifyH or "CENTER"] or "center"
          local jv = ({ TOP = "flex-start", BOTTOM = "flex-end" })[o._justifyV or "MIDDLE"] or "center"
          local ta = ({ LEFT = "left", RIGHT = "right" })[o._justifyH or "CENTER"] or "center"
          local tcls, tstyle = "tx", "text-align:" .. ta
          if not constrainedW then tcls = tcls .. " free"
          elseif not wraps then tcls = tcls .. " nw"
          else
            tcls = tcls .. " wr"
            local constrainedH = (o._h ~= nil) or frames.AxisKinds(o._points, "v") >= 2
            local lineH = frames.LineHeight(spec, o._spacing) * rect.scale
            local maxLines = o._maxLines and o._maxLines > 0 and o._maxLines or nil
            if constrainedH then
              local fit = math.max(1, math.floor((h + 0.5) / lineH))
              maxLines = maxLines and math.min(maxLines, fit) or fit
            end
            if maxLines then tcls = tcls .. " clamp"; tstyle = tstyle .. ";-webkit-line-clamp:" .. maxLines end
          end
          -- Arial Narrow stand-in: when the face is missing (see NARROW_JS) the
          -- span is laid out wider and squeezed back with scaleX, about its anchor.
          local fcls = "r fs"
          if spec.face == "arialn" then
            fcls = fcls .. " an"
            tstyle = tstyle .. ";transform-origin:" .. ta .. " center"
          end
          out[#out + 1] = string.format('<div class="%s" %s;%s;justify-content:%s;align-items:%s"><span class="%s" style="%s">%s</span></div>',
            fcls, common, FontCSS(spec, color, o._spacing, rect.scale, o._shadowColor, o._shadowOffset), jh, jv, tcls, tstyle,
            MarkupHTML(o._text, spec, rect.scale))
        end
      else
        local cls, css, title = TextureCSS(o, it.frame.obj, rect)
        if cls then
          local inner = o._phLabel and ('<span class="phl">' .. esc(o._phLabel) .. "</span>") or ""
          o._phLabel = nil
          out[#out + 1] = string.format('<div class="%s" %s;%s" title="%s">%s</div>', cls, common, css, esc(title), inner)
        end
      end
    end
  end
  return table.concat(out, "\n"), #items
end

-- Page HTML -------------------------------------------------------------------------------

local CSS = [[
:root{color-scheme:dark;--bg:#14161a;--panel:#1d2026;--line:#2c3038;--fg:#d9dde3;--dim:#8a919c;--acc:#ffd100}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:13px/1.45 system-ui,Segoe UI,sans-serif}
header{position:sticky;top:0;z-index:100000;display:flex;flex-wrap:wrap;gap:6px 16px;align-items:center;padding:8px 16px;background:var(--panel);border-bottom:1px solid var(--line)}
header a{color:var(--fg);text-decoration:none;padding:2px 8px;border-radius:4px}
header a.on{background:#3a3220;color:var(--acc)}
header label{color:var(--dim);white-space:nowrap}
header .grp{display:flex;gap:4px;align-items:center;flex-wrap:wrap}
main{padding:16px}
.wrap{overflow:auto;max-width:100%;border:1px solid var(--line)}
.canvas{position:relative;overflow:hidden;background:radial-gradient(ellipse at 30% 20%,#3b4a3a 0%,#22302a 45%,#11161a 100%)}
.canvas[hidden]{display:none}
.canvas>div{position:absolute}
.fs{display:flex;white-space:pre;pointer-events:auto}
.fs .tx{display:block}
.fs .tx.free{flex:none;white-space:pre}
.fs .tx.nw{width:100%;overflow:hidden;text-overflow:ellipsis;white-space:pre}
.fs .tx.wr{width:100%;white-space:pre-wrap;overflow-wrap:anywhere}
.fs .tx.clamp{display:-webkit-box;-webkit-box-orient:vertical;overflow:hidden}
.ic{display:inline-block;vertical-align:middle;background-size:100% 100%}
.ph{background:repeating-linear-gradient(45deg,rgba(150,150,160,.35) 0 4px,rgba(90,90,100,.35) 4px 8px)!important;outline:1px solid rgba(200,200,210,.35);outline-offset:-1px}
.ph.art{background:rgba(160,160,170,.06)!important;outline:1px dashed rgba(200,200,210,.3)}
.phl{position:absolute;left:2px;top:1px;right:2px;font:9px/1.1 system-ui,sans-serif;color:#ddd;overflow:hidden;white-space:nowrap;text-overflow:ellipsis;text-shadow:0 0 2px #000}
.unk{border:1px dashed #ff6bd5;background:rgba(255,107,213,.06)}
.unkl{position:absolute;left:2px;top:1px;font:10px system-ui,sans-serif;color:#ff9be5;white-space:nowrap}
body.nonarrow .fs.an>.tx{transform:scaleX(.82)}
body.nonarrow .fs.an>.tx.nw,body.nonarrow .fs.an>.tx.wr{width:121.95%;flex:none}
.eb{position:absolute;inset:0;white-space:pre;overflow:hidden;display:flex;align-items:center}
.eb.ml{white-space:pre-wrap;align-items:flex-start;overflow-wrap:anywhere}
body.outline .canvas>div{outline:1px solid rgba(0,200,255,.45);outline-offset:-1px}
body.outline .canvas>div.f{outline:1px dashed rgba(0,255,160,.55)}
body.outline .canvas>div:hover,.canvas>div.flash{outline:2px solid #ff3b3b!important;z-index:99999!important}
#hover{position:fixed;left:12px;bottom:12px;z-index:100001;max-width:70vw;padding:6px 10px;background:rgba(0,0,0,.85);border:1px solid var(--line);border-radius:4px;font:12px ui-monospace,Consolas,monospace;display:none}
body.outline #hover{display:block}
section{margin-top:16px;max-width:1280px}
h2{font-size:15px;margin:0 0 8px}
.warn li{margin:2px 0;cursor:pointer}
.warn li:hover{color:#fff}
.k{display:inline-block;min-width:110px;font:11px ui-monospace,Consolas,monospace;color:var(--acc)}
.site{color:var(--dim);font:11px ui-monospace,Consolas,monospace}
.only{color:#ff9b6b;font-size:11px}
.note{color:var(--dim);max-width:1000px}
table{border-collapse:collapse}td,th{padding:4px 10px;border-bottom:1px solid var(--line);text-align:left}
]]

local JS = [[
const $=s=>document.querySelector(s),$$=s=>[...document.querySelectorAll(s)];
// NARROW_JS: without Arial Narrow the browser draws NumberFont text in full-width
// Arial (font-stretch can't condense it), ~22% wider than the client; .nonarrow
// squeezes those spans back to Arial Narrow's advance widths.
(()=>{try{const x=document.createElement('canvas').getContext('2d'),t='Concussive Shot 0123456789';
x.font='40px Arial';const m=x.measureText(t).width;x.font="40px 'Arial Narrow',Arial";
if(x.measureText(t).width>m*0.95)document.body.classList.add('nonarrow')}catch(e){}})();
function pick(k){$$('.canvas').forEach(c=>c.hidden=c.id!=='c-'+k);try{localStorage.setItem('ac-canvas',k)}catch(e){}}
function zoom(z){$$('.canvas').forEach(c=>c.style.zoom=z);try{localStorage.setItem('ac-zoom',z)}catch(e){}}
function outline(on){document.body.classList.toggle('outline',on);try{localStorage.setItem('ac-outline',on?'1':'')}catch(e){}}
document.addEventListener('mouseover',e=>{const n=e.target.closest('[data-n]');if(n)$('#hover').textContent=n.dataset.n});
$$('.warn li[data-oid]').forEach(li=>li.addEventListener('click',()=>{
  const c=$$('.canvas').find(c=>!c.hidden);const el=c&&c.querySelector('[data-oid="'+li.dataset.oid+'"]');
  if(!el)return;el.scrollIntoView({block:'center',inline:'center'});el.classList.add('flash');setTimeout(()=>el.classList.remove('flash'),1600)}));
try{const k=localStorage.getItem('ac-canvas');if(k&&$('#c-'+k)){pick(k);$('input[value="'+k+'"]').checked=true}
const z=localStorage.getItem('ac-zoom');if(z){zoom(z);$('#zoom').value=z}
if(localStorage.getItem('ac-outline')){outline(true);$('#ol').checked=true}}catch(e){}
]]

local function NavHTML(pages, current)
  local parts = { '<a href="index.html"' .. (current == "index" and ' class="on"' or "") .. ">Index</a>" }
  for _, p in ipairs(pages) do
    parts[#parts + 1] = string.format('<a href="%s.html"%s>%s</a>', esc(p.id), p.id == current and ' class="on"' or "", esc(p.title))
  end
  return '<div class="grp">' .. table.concat(parts) .. "</div>"
end

local function MergeWarnings(perCanvas)
  local merged, index = {}, {}
  for ci, list in ipairs(perCanvas) do
    for _, w in ipairs(list) do
      local key = w.kind .. "\0" .. w.msg
      local m = index[key]
      if not m then
        m = { kind = w.kind, msg = w.msg, id = w.id, site = w.site, canvases = {} }
        index[key] = m
        merged[#merged + 1] = m
      end
      m.canvases[ci] = true
    end
  end
  for _, m in ipairs(merged) do
    local n, which = 0, nil
    for ci in pairs(m.canvases) do n = n + 1; which = ci end
    if n < #perCanvas then m.only = CANVASES[which].label end
  end
  local ORDER = { ["lua-error"] = 1, unresolved = 2, ["unknown-template"] = 3, ["zero-size"] = 4, overflow = 5, outside = 6, ["outside-page"] = 6.5,
    overlap = 7, api = 8, ["missing-texture"] = 9 }
  table.sort(merged, function(a, b)
    local oa, ob = ORDER[a.kind] or 50, ORDER[b.kind] or 50
    if oa ~= ob then return oa < ob end
    return a.msg < b.msg
  end)
  return merged
end

local function PageHTML(pages, page, canvasHTML, warnings)
  local o = {}
  o[#o + 1] = "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
  o[#o + 1] = "<title>Agentcraft render: " .. esc(page.title) .. "</title><style>" .. CSS .. "</style></head><body>"
  o[#o + 1] = "<header>" .. NavHTML(pages, page.id) .. '<div class="grp">'
  for i, c in ipairs(CANVASES) do
    o[#o + 1] = string.format('<label><input type="radio" name="cv" value="%s"%s onchange="pick(this.value)"> %s</label>', c.key,
      i == 1 and " checked" or "", esc(c.label))
  end
  o[#o + 1] = '<label>zoom <select id="zoom" onchange="zoom(this.value)"><option value="0.5">50%</option><option value="0.75">75%</option>'
    .. '<option value="1" selected>100%</option><option value="1.5">150%</option><option value="2">200%</option></select></label>'
  o[#o + 1] = '<label><input type="checkbox" id="ol" onchange="outline(this.checked)"> outline frames (hover for name, size, source)</label></div></header><main>'
  for i, c in ipairs(CANVASES) do
    o[#o + 1] = string.format('<div class="wrap"><div class="canvas" id="c-%s" style="width:%dpx;height:%dpx"%s>%s</div></div>',
      c.key, c.w, c.h, i == 1 and "" or " hidden", canvasHTML[i])
  end
  o[#o + 1] = '<section class="warn"><h2>Layout warnings (' .. #warnings .. ")</h2>"
  if #warnings == 0 then o[#o + 1] = "<p>None.</p>" end
  o[#o + 1] = "<ul>"
  for _, w in ipairs(warnings) do
    o[#o + 1] = string.format('<li%s><span class="k">%s</span> %s%s%s</li>', w.id and (' data-oid="' .. w.id .. '"') or "",
      esc(w.kind), esc(w.msg), w.site and (' <span class="site">' .. esc(w.site) .. "</span>") or "",
      w.only and (' <span class="only">' .. esc(w.only) .. " only</span>") or "")
  end
  o[#o + 1] = "</ul>"
  o[#o + 1] = '<p class="note">Rendered offline by dev/render/render.lua from the harness mock (hunter fixture). Fonts are approximated '
    .. "(Friz Quadrata and Arial Narrow are not bundled), text widths are estimated, and textures with no PNG in dev/render/textures "
    .. "are striped placeholders (hover for the path) or flat colours for template art. Highlight-layer textures are not drawn.</p>"
  o[#o + 1] = "</section></main><div id=\"hover\"></div><script>" .. JS .. "</script></body></html>"
  return table.concat(o, "\n")
end

-- Main --------------------------------------------------------------------------------------

local function WriteFile(path, text)
  local f = assert(io.open(path, "wb"), "can't write " .. path)
  f:write(text)
  f:close()
end

-- Variants (dev/ui-spec-v2.md §11.4): each boots its own game and writes
-- <page><suffix>.html. "kb" is the default look; "pad" turns the Gamepad UI on
-- (glyph prompts, LB/RB indicators, 1.1 scale clamp).
-- pages limits a variant to those page ids; prepare(env, page) runs after the
-- page opened (open the Review sheet, hold a modifier).
local function Pad(W) W.gamepadUI = true end
local function Hold(mod)
  return function(env, page)
    env.W.mods = env.W.mods or {}
    env.W.mods[mod] = true
    if page.frame and page.frame.acPollModifiers then page.frame.acPollModifiers() end
  end
end
local VARIANTS = {
  { key = "kb", suffix = "", label = "" },
  { key = "pad", suffix = "-pad", label = " (pad)", setup = Pad, db = { prompts = "pad" } },
  { key = "list", suffix = "-list", label = " (list)", pages = { keyboard = true, controller = true },
    db = { keyboardPage = { mode = 2 }, controllerView = 2 } },
  { key = "review", suffix = "-review", label = " (review)", pages = { keyboard = true, controller = true, macros = true },
    prepare = function(env) env.ns.UI.OpenReview(); env:runTimers(1) end },
  { key = "combat", suffix = "-combat", label = " (combat)", pages = { keyboard = true, controller = true, macros = true, options = true },
    -- PLAYER_REGEN_DISABLED fires while protected calls still work; lockdown follows.
    prepare = function(env)
      if not env.W.inCombat then env:fire("PLAYER_REGEN_DISABLED"); env.W.inCombat = true end
      env:runTimers(1)
    end },
  { key = "shift", suffix = "-shift", label = " (Shift held)", pages = { keyboard = true }, prepare = Hold("shift") },
  { key = "ctrl", suffix = "-ctrl", label = " (Ctrl held)", pages = { keyboard = true }, prepare = Hold("ctrl") },
  { key = "lt", suffix = "-lt", label = " (LT held)", pages = { controller = true }, setup = Pad, db = { prompts = "pad" },
    prepare = Hold("shift") },
  { key = "ps", suffix = "-ps", label = " (PlayStation)", pages = { controller = true, gallery = true },
    setup = function(W) W.gamepadUI = true; W.labelStyle = "Shapes" end, db = { prompts = "pad" } },
}
local FC = require("focuscheck")
-- The dev-only widget gallery page (dev/render/gallery.lua): every v2 widget
-- on a page of its own, so the foundation renders even before pages use it.
local Gallery = loadfile(here .. "/gallery.lua")

-- offscreen: the window plus its side tabs, at the scale the client picks,
-- must fit 1229x768 (the Deck's 1280x800 at its UI scale). focus-*: the walk
-- in dev/harness/focuscheck.lua. small-target: pad variants only.
local FIT_W, FIT_H = 1229, 768
local function FocusChecks(env, root, p)
  local out = {}
  local function add(kind, obj, msg)
    out[#out + 1] = { kind = kind, msg = msg, id = obj and obj._id, site = obj and obj._site }
  end
  local Focus = env.ns.Focus
  local l, b, w, h = Focus.ScreenRect(root)
  if l then
    local r, t = l + w, b + h
    local function grow(f)
      if f.IsShown and not f:IsShown() then return end
      local fl, fb, fw, fh = Focus.ScreenRect(f)
      if fl and fw > 0 and fh > 0 then l, b = math.min(l, fl), math.min(b, fb); r, t = math.max(r, fl + fw), math.max(t, fb + fh) end
    end
    for _, c in ipairs({ root:GetChildren() }) do if rawget(c, "acZone") == "tabs" then
      grow(c)
      for _, tab in ipairs({ c:GetChildren() }) do grow(tab) end
    end end
    if r - l > FIT_W + 0.5 or t - b > FIT_H + 0.5 then
      add("offscreen", root, string.format("window plus side tabs is %sx%s at scale %s; must fit %dx%d", n2(r - l), n2(t - b),
        n2(root:GetEffectiveScale()), FIT_W, FIT_H))
    end
  end
  if p.page.api ~= 2 then return out end
  local ok, res = pcall(FC.Walk, env)
  if not ok then add("lua-error", nil, "focus walk: " .. tostring(res)); return out end
  if not res.start then
    if #res.nodes > 0 then add("focus-unreachable", root, "page has focus nodes but no landing focus") end
    return out
  end
  for _, n in ipairs(res.unreachable) do
    add("focus-unreachable", n, FC.Label(n) .. " can't be reached from " .. FC.Label(res.start) .. " with the arrows, D-pad or Tab")
  end
  if env.W.gamepadUI then
    -- Pad variants: no Tab on a controller, so count D-pad moves only.
    local already = {}
    for _, n in ipairs(res.unreachable) do already[n] = true end
    for i, n in ipairs(res.arrowUnreachable or {}) do
      if not already[n] then
        local id = res.arrowUnreachableIds and res.arrowUnreachableIds[i] or FC.Label(n)
        add("focus-unreachable", n, id .. " can't be reached from " .. FC.Label(res.start) .. " with the D-pad alone (needs Tab)")
      end
    end
    for i, n in ipairs(res.noInspectorEntry or {}) do
      add("focus-unreachable", n, res.noInspectorEntryIds[i] .. ": its Inspector links/buttons can't be entered with the D-pad or A (needs Tab)")
    end
  end
  for i, n in ipairs(res.deadends) do
    local key = res.deadendKeys and res.deadendKeys[i] or rawget(n, "acId") or n
    local why = res.lost[key] and "loses focus once the Inspector settles"
      or (next(res.edges[key] or {}) == nil and "has no exit in any direction")
      or ("can't get back to " .. FC.Label(res.start))
    add("focus-deadend", n, (type(key) == "string" and key or FC.Label(n)) .. " " .. why)
  end
  if env.W.gamepadUI then
    for _, n in ipairs(res.small) do
      add("small-target", n, string.format("%s is %sx%s; pad targets need %d px", FC.Label(n), n2(n:GetWidth()), n2(n:GetHeight()), FC.MIN_TARGET))
    end
  end
  return out
end

local pages, summary, report, hadErrors = {}, {}, {}, false
local renders = {}

local function Boot(v)
  local db = {}
  for k, val in pairs(v.db or {}) do db[k] = val end
  local env = H.boot({ pet = true, db = db, setup = v.setup, loaded = function(e)
    if Gallery then
      local ok, page = pcall(Gallery)
      if ok and type(page) == "table" then page.G, page.ns = e.G, e.ns; e.ns.RegisterPage(page) end
    end
  end })
  -- A couple of installed library macros, so the Macros page shows mixed states.
  local entries = env.ns.MacroLibrary and env.ns.MacroLibrary.Entries and env.ns.MacroLibrary.Entries(false) or {}
  for i = 1, math.min(2, #entries) do pcall(env.installMacro, env, entries[i].name) end
  env:slash("")
  env:runTimers(1)
  return env
end

for _, v in ipairs(VARIANTS) do
  local env = Boot(v)
  local root = env.G.AgentcraftFrame
  if not root then
    io.stderr:write("render: /ac did not create AgentcraftFrame\n")
    for _, e in ipairs(env.W.errors) do io.stderr:write(e, "\n") end
    os.exit(1)
  end
  for _, p in ipairs(env.ns.pages) do
    if not v.pages or v.pages[p.id] then
      local entry = { id = p.id .. v.suffix, title = (p.title or p.id) .. v.label, page = p, env = env, root = root, variant = v }
      pages[#pages + 1] = entry
      renders[#renders + 1] = entry
    end
  end
end

for _, p in ipairs(renders) do
  local env, root = p.env, p.root
  local errBefore = #env.W.errors
  env.ns.OpenPage(p.page.id)
  env:runTimers(1)
  if p.variant.prepare then p.variant.prepare(env, p.page) end
  local names = BuildNames(env)
  local label = MakeLabeler(names)
  local perCanvas, html = {}, {}
  for ci, canvas in ipairs(CANVASES) do
    local warnings = {}
    for i = errBefore + 1, #env.W.errors do
      Warn(warnings, "lua-error", nil, env.W.errors[i]:gsub("\n.*", ""))
      hadErrors = true
    end
    html[ci] = RenderCanvas(env, root, canvas, label, warnings, p.page.frame)
    perCanvas[ci] = warnings
  end
  -- Missing textures for this page (counted while drawing).
  local merged = MergeWarnings(perCanvas)
  -- Focus and fit checks (dev/ui-spec-v2.md §11.4) at the Steam Deck size.
  env.W.screen = { w = CANVASES[1].w, h = CANVASES[1].h }
  for _, w in ipairs(FocusChecks(env, root, p)) do merged[#merged + 1] = w end
  local missing = {}
  for _, u in pairs(textureUse) do
    if not u.png and u.lastCount ~= u.count then missing[#missing + 1] = u end
    u.lastCount = u.count
  end
  table.sort(missing, function(a, b) return a.rel < b.rel end)
  for _, u in ipairs(missing) do
    local atlas = tostring(u.original or ""):match("^atlas:(.+)$")
    if atlas and FOREVER_ONLY[atlas:lower()] then
      -- WoW Forever art the retail tables lack: drawn as its stand-in (info, not a warning).
      infos[#infos + 1] = { page = p.id, msg = "forever-only atlas " .. atlas .. " (stand-in drawn; " .. FOREVER_ONLY[atlas:lower()] .. ")" }
    else
      merged[#merged + 1] = { kind = "missing-texture", msg = u.label .. (u.template and " (template art)" or "") }
    end
  end
  WriteFile(outDir .. "/" .. p.id .. ".html", PageHTML(pages, p, html, merged))
  local counts = {}
  for _, w in ipairs(merged) do counts[w.kind] = (counts[w.kind] or 0) + 1 end
  summary[#summary + 1] = { page = p, counts = counts, total = #merged }
  report[#report + 1] = "== " .. p.id .. " (" .. p.title .. "): " .. #merged .. " warnings"
  for _, w in ipairs(merged) do
    report[#report + 1] = string.format("  %-16s %s%s%s", w.kind, w.msg, w.site and ("  [" .. w.site .. "]") or "",
      w.only and ("  (" .. w.only .. " only)") or "")
  end
  env.W.screen = { w = CANVASES[1].w, h = CANVASES[1].h }
end

-- Index.
do
  local kinds = { "lua-error", "unresolved", "unknown-template", "zero-size", "overflow", "outside", "outside-page", "overlap", "api", "color-fill",
    "offscreen", "small-target", "focus-unreachable", "focus-deadend", "missing-texture" }
  local o = { "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><title>Agentcraft render</title><style>" .. CSS .. "</style></head><body>",
    "<header>" .. NavHTML(pages, "index") .. "</header><main><section><h2>Agentcraft window, rendered offline</h2>",
    "<table><tr><th>Page</th><th>Total</th>" }
  for _, k in ipairs(kinds) do o[#o + 1] = "<th>" .. esc(k) .. "</th>" end
  o[#o + 1] = "</tr>"
  for _, s in ipairs(summary) do
    o[#o + 1] = string.format('<tr><td><a href="%s.html">%s</a></td><td>%d</td>', esc(s.page.id), esc(s.page.title), s.total)
    for _, k in ipairs(kinds) do o[#o + 1] = "<td>" .. (s.counts[k] or "") .. "</td>" end
    o[#o + 1] = "</tr>"
  end
  o[#o + 1] = "</table>"
  local used = {}
  for _, u in pairs(textureUse) do used[#used + 1] = u end
  table.sort(used, function(a, b) return a.rel < b.rel end)
  o[#o + 1] = "<h2 style=\"margin-top:20px\">Textures drawn</h2><table><tr><th>Texture</th><th>PNG</th><th>Source</th></tr>"
  for _, u in ipairs(used) do
    o[#o + 1] = string.format("<tr><td>%s</td><td>%s</td><td>%s</td></tr>", esc(u.label), u.png and "yes" or "missing",
      u.template and "template" or "addon")
  end
  o[#o + 1] = "</table><p class=\"note\">Put PNGs at dev/render/textures/&lt;lowercase path&gt;.png (or run dev.ps1 render -Fetch) and render again.</p>"
  o[#o + 1] = "</section></main></body></html>"
  WriteFile(outDir .. "/index.html", table.concat(o, "\n"))

  local miss, all = {}, {}
  for _, u in ipairs(used) do
    all[#all + 1] = string.format("%s\t%s\t%s\t%s", u.rel, u.original, u.png and "png" or "missing", u.template and "template" or "addon")
    if not u.png then miss[#miss + 1] = u.rel .. "\t" .. u.original end
  end
  WriteFile(outDir .. "/textures-missing.txt", table.concat(miss, "\n") .. (#miss > 0 and "\n" or ""))
  WriteFile(outDir .. "/textures-used.txt", table.concat(all, "\n") .. "\n")
end

if #infos > 0 then
  report[#report + 1] = "== info"
  for _, i in ipairs(infos) do report[#report + 1] = "  " .. i.page .. ": " .. i.msg end
end
WriteFile(outDir .. "/warnings.txt", table.concat(report, "\n") .. "\n")
for _, line in ipairs(report) do print(line) end
print("")
print("wrote " .. #pages .. " pages and index.html to " .. outDir)
os.exit(hadErrors and 1 or 0)
