--[[
	UI Library (personal / open source)
	License: MIT

	Usage:
		local Lib = loadstring(game:HttpGet("RAW_URL/Library.lua"))()
		Lib.Key({...}, function() local w = Lib.new("Title") ... end)
		Lib.Notify({Title = "Hi", Content = "Hello", Type = "success"})
]]

local UIS, TS = game:GetService("UserInputService"), game:GetService("TweenService")
local Players = game:GetService("Players")

local C = {bg=Color3.fromRGB(16,17,22), sec=Color3.fromRGB(24,25,33), el=Color3.fromRGB(34,36,47), st=Color3.fromRGB(46,48,62),
	tx=Color3.fromRGB(236,238,245), sub=Color3.fromRGB(140,145,166), ac=Color3.fromRGB(86,120,255),
	green=Color3.fromRGB(46,204,113), gray=Color3.fromRGB(95,97,110),
	red=Color3.fromRGB(235,87,87), orange=Color3.fromRGB(230,170,90)}
local Left, Right = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right
local WHITE = Color3.new(1,1,1)

-- ═════════ ICONS ═════════
-- true = rbxthumb (ใช้ได้ทั้ง Decal ID และ Image ID) / false = rbxassetid ตรงๆ
local USE_THUMB = true
local function asset(id)
	if USE_THUMB then return "rbxthumb://type=Asset&id=" .. id .. "&w=150&h=150" end
	return "rbxassetid://" .. id
end
local ICON = {
	discord   = asset(7948857513),
	web       = asset(11395780614),
	home      = asset(279461711),
	key       = asset(10871266127),
	tick      = asset(14203226683),
	arrowUp   = asset(112965684250711),
	arrowDown = asset(84586195270945),
	close     = asset(10152135074),
	clip      = asset(12804017070),
	expand    = asset(115443342386366),
	settings  = asset(7059346386),
}

-- ═════════ HELPERS ═════════
local function N(c, p, ch)
	local i = Instance.new(c)
	for k, v in pairs(p or {}) do if k ~= "Parent" then i[k] = v end end
	for _, x in ipairs(ch or {}) do x.Parent = i end
	i.Parent = p and p.Parent
	return i
end
local function R(r) return N("UICorner", {CornerRadius = UDim.new(0, r)}) end
local function S() return N("UIStroke", {Color = C.st, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}) end
local function T(i, p) TS:Create(i, TweenInfo.new(.15), p):Play() end
local function L(p)
	p.BackgroundTransparency = 1
	p.TextColor3 = p.TextColor3 or C.tx
	p.Font = p.Font or Enum.Font.GothamMedium
	p.TextSize = p.TextSize or 13
	p.TextXAlignment = p.TextXAlignment or Left
	return N("TextLabel", p)
end
local function Ic(p)
	p.BackgroundTransparency = 1
	p.ScaleType = Enum.ScaleType.Fit
	return N("ImageLabel", p)
end
local function press(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function move(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end
local function pad(l, t, r, b) return N("UIPadding", {PaddingLeft = UDim.new(0,l), PaddingTop = UDim.new(0,t), PaddingRight = UDim.new(0,r), PaddingBottom = UDim.new(0,b)}) end
local function list(p) return N("UIListLayout", {Padding = UDim.new(0, p or 6), SortOrder = Enum.SortOrder.LayoutOrder}) end

-- press effect: ปุ่มเป็นสีเทา + ย่อเล็กน้อย แล้วคืนค่า
local function fx(b, base)
	local sc = N("UIScale", {Parent = b})
	b.MouseButton1Down:Connect(function() T(b, {BackgroundColor3 = C.gray}); T(sc, {Scale = .96}) end)
	local function up() T(b, {BackgroundColor3 = base}); T(sc, {Scale = 1}) end
	b.MouseButton1Up:Connect(function() task.delay(.12, up) end)
	b.MouseLeave:Connect(up)
end

local function mount()
	local g = N("ScreenGui", {Name = "UI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
	pcall(function() g.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
	if not g.Parent then g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
	return g
end

local function drag(h, f)
	local d, ds, sp
	h.InputBegan:Connect(function(i) if press(i) then d, ds, sp = true, i.Position, f.Position end end)
	UIS.InputChanged:Connect(function(i)
		if d and move(i) then
			local v = i.Position - ds
			f.Position = UDim2.new(sp.X.Scale, sp.X.Offset + v.X, sp.Y.Scale, sp.Y.Offset + v.Y)
		end
	end)
	UIS.InputEnded:Connect(function(i) if press(i) then d = false end end)
end

local function copy(t) if setclipboard then pcall(setclipboard, t) end end

local Lib = {Icons = ICON, Colors = C, NotifyDuration = 4}

-- ═════════════════ NOTIFY (Fluent style) ═════════════════
-- Lib.Notify({Title=, Content=, Type="info"|"success"|"warn"|"error", Duration=})
local NOTIF = {
	info    = {C.ac,     "i"},
	success = {C.green,  nil, "tick"},
	warn    = {C.orange, "!"},
	error   = {C.red,    nil, "close"},
}
local notifGui, notifHolder, nCount = nil, nil, 0

local function holder()
	if notifHolder and notifHolder.Parent then return notifHolder end
	notifGui = mount()
	notifGui.Name = "UINotify"
	notifGui.DisplayOrder = 1000
	notifHolder = N("Frame", {
		AnchorPoint = Vector2.new(1,1), Position = UDim2.new(1,-16,1,-16),
		Size = UDim2.new(0,300,1,-32), BackgroundTransparency = 1, Parent = notifGui,
	}, {N("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom})})
	return notifHolder
end

function Lib.Notify(o)
	if type(o) == "string" then o = {Content = o} end
	local kind = NOTIF[o.Type] and o.Type or "info"
	local info = NOTIF[kind]
	local col = info[1]
	local dur = o.Duration or Lib.NotifyDuration
	nCount += 1

	local slot = N("Frame", {Size = UDim2.new(1,0,0,74), BackgroundTransparency = 1, LayoutOrder = nCount, Parent = holder()})
	local card = N("Frame", {Position = UDim2.new(1.3,0,0,0), Size = UDim2.fromScale(1,1), BackgroundColor3 = C.sec, Parent = slot}, {R(10), S()})

	local circ = N("Frame", {Position = UDim2.fromOffset(12,12), Size = UDim2.fromOffset(28,28), BackgroundColor3 = col, Parent = card}, {N("UICorner", {CornerRadius = UDim.new(1,0)})})
	if info[3] then
		Ic({AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(14,14), Image = ICON[info[3]], ImageColor3 = WHITE, Parent = circ})
	else
		L({Size = UDim2.fromScale(1,1), Text = info[2], Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, Parent = circ})
	end
	L({Position = UDim2.fromOffset(50,10), Size = UDim2.new(1,-62,0,18), Text = o.Title or "Notification", Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})
	L({Position = UDim2.fromOffset(50,28), Size = UDim2.new(1,-62,0,34), Text = o.Content or "", TextColor3 = C.sub, TextSize = 12, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = card})

	local track = N("Frame", {AnchorPoint = Vector2.new(.5,1), Position = UDim2.new(.5,0,1,-6), Size = UDim2.new(1,-24,0,2), BackgroundColor3 = C.el, BorderSizePixel = 0, Parent = card}, {R(1)})
	local fill = N("Frame", {Size = UDim2.fromScale(1,1), BackgroundColor3 = col, BorderSizePixel = 0, Parent = track}, {R(1)})

	local closed = false
	local function close()
		if closed then return end
		closed = true
		TS:Create(card, TweenInfo.new(.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1.3,0,0,0)}):Play()
		task.wait(.25)
		local t = TS:Create(slot, TweenInfo.new(.2), {Size = UDim2.new(1,0,0,0)})
		t:Play(); t.Completed:Wait()
		slot:Destroy()
	end

	N("TextButton", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Text = "", Parent = card}).MouseButton1Click:Connect(function() task.spawn(close) end)

	TS:Create(card, TweenInfo.new(.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)}):Play()
	TS:Create(fill, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size = UDim2.new(0,0,1,0)}):Play()
	task.delay(dur, function() task.spawn(close) end)
	return close
end

-- ═════════════════ KEY SYSTEM ═════════════════
-- Lib.Key({Title=, Logo=, Key=, Link=, Discord=, Website=, Save=true/false, File=}, onSuccess)
function Lib.Key(o, onOk)
	local file = o.File or "uilib_key.txt"
	local save = o.Save ~= false

	if save then
		local okr, saved = pcall(function() return readfile(file) end)
		if okr and saved == o.Key then return onOk() end
	else
		pcall(function() delfile(file) end)
	end

	local gui = mount()
	local f = N("Frame", {AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(620,330), BackgroundColor3 = C.bg, Active = true, Parent = gui}, {R(12), S()})
	drag(f, f)

	local lg = N("Frame", {Position = UDim2.fromOffset(22,20), Size = UDim2.fromOffset(44,44), BackgroundColor3 = C.ac, Parent = f}, {R(10)})
	if o.Logo and o.Logo ~= "" then
		Ic({Size = UDim2.fromScale(1,1), Image = o.Logo, Parent = lg})
	else
		Ic({AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(26,26), Image = ICON.key, ImageColor3 = WHITE, Parent = lg})
	end
	L({Position = UDim2.fromOffset(76,18), Size = UDim2.fromOffset(250,26), Text = o.Title or "Hub", Font = Enum.Font.GothamBold, TextSize = 20, Parent = f})
	L({Position = UDim2.fromOffset(76,44), Size = UDim2.fromOffset(250,18), Text = "Key system", TextColor3 = C.sub, TextSize = 12, Parent = f})

	L({Position = UDim2.fromOffset(22,88), Size = UDim2.fromOffset(200,18), Text = "License key", TextColor3 = C.sub, TextSize = 12, Parent = f})
	local box = N("TextBox", {Position = UDim2.fromOffset(22,110), Size = UDim2.fromOffset(350,42), BackgroundColor3 = C.sec, Text = "", PlaceholderText = "Paste your key here", PlaceholderColor3 = C.sub, TextColor3 = C.tx, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Left, ClearTextOnFocus = false, Parent = f}, {R(8), S(), pad(14,0,14,0)})

	local function btn(parent, x, y, w, h, text, base, tc, icon)
		local b = N("TextButton", {Position = UDim2.fromOffset(x,y), Size = UDim2.fromOffset(w,h), BackgroundColor3 = base, Text = text, TextColor3 = tc or C.tx, Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false, Parent = parent}, {R(8)})
		if icon then
			b.Text = "      " .. text
			local tb = game:GetService("TextService"):GetTextSize(b.Text, 13, Enum.Font.GothamBold, Vector2.new(1000, 100))
			Ic({AnchorPoint = Vector2.new(0,.5), Position = UDim2.new(.5, -tb.X/2, .5, 0), Size = UDim2.fromOffset(16,16), Image = icon, ImageColor3 = tc or C.tx, Parent = b})
		end
		fx(b, base)
		return b
	end
	local submit = btn(f, 22, 166, 169, 40, "Submit", C.ac, WHITE)
	local getkey = btn(f, 203, 166, 169, 40, "Get a key", C.el, nil, ICON.key)
	local msg = L({Position = UDim2.fromOffset(22,218), Size = UDim2.fromOffset(350,20), Text = o.Game or "", TextColor3 = C.ac, Parent = f})
	L({Position = UDim2.fromOffset(22,296), Size = UDim2.fromOffset(350,18), Text = save and "Your key is saved, you only enter it once" or "Key is not saved (test mode)", TextColor3 = C.sub, TextSize = 11, Parent = f})

	N("Frame", {Position = UDim2.fromOffset(396,22), Size = UDim2.fromOffset(1,286), BackgroundColor3 = C.st, BorderSizePixel = 0, Parent = f})
	L({Position = UDim2.fromOffset(414,20), Size = UDim2.fromOffset(180,18), Text = "Detected game", TextColor3 = C.sub, TextSize = 12, Parent = f})
	local gname = "Unknown game"
	pcall(function() gname = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
	local card = N("Frame", {Position = UDim2.fromOffset(414,42), Size = UDim2.fromOffset(186,56), BackgroundColor3 = C.sec, Parent = f}, {R(10), S()})
	N("ImageLabel", {Position = UDim2.fromOffset(8,8), Size = UDim2.fromOffset(40,40), BackgroundColor3 = C.el, Image = "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150", Parent = card}, {R(8)})
	L({Position = UDim2.fromOffset(56,8), Size = UDim2.fromOffset(124,22), Text = gname, Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})
	L({Position = UDim2.fromOffset(56,28), Size = UDim2.fromOffset(124,18), Text = "Supported", TextColor3 = C.green, TextSize = 12, Parent = card})

	local ex = "Unknown"
	pcall(function() ex = identifyexecutor() end)
	L({Position = UDim2.fromOffset(414,112), Size = UDim2.fromOffset(90,20), Text = "Executor", TextColor3 = C.sub, Parent = f})
	L({Position = UDim2.fromOffset(504,112), Size = UDim2.fromOffset(96,20), Text = ex, Font = Enum.Font.GothamBold, TextXAlignment = Right, Parent = f})
	L({Position = UDim2.fromOffset(414,136), Size = UDim2.fromOffset(90,20), Text = "Status", TextColor3 = C.sub, Parent = f})
	local st = L({Position = UDim2.fromOffset(504,136), Size = UDim2.fromOffset(96,20), Text = "Key required", TextColor3 = C.orange, Font = Enum.Font.GothamBold, TextXAlignment = Right, Parent = f})
	N("Frame", {Position = UDim2.fromOffset(414,166), Size = UDim2.fromOffset(186,1), BackgroundColor3 = C.st, BorderSizePixel = 0, Parent = f})

	local function link(y, name, sub, val, icon)
		local b = N("TextButton", {Position = UDim2.fromOffset(414,y), Size = UDim2.fromOffset(186,54), BackgroundColor3 = C.sec, Text = "", AutoButtonColor = false, Parent = f}, {R(10), S()})
		local tx = 14
		if icon then
			Ic({Position = UDim2.fromOffset(12,15), Size = UDim2.fromOffset(24,24), Image = icon, Parent = b})
			tx = 46
		end
		L({Position = UDim2.fromOffset(tx,8), Size = UDim2.fromOffset(186-tx-8,20), Text = name, Font = Enum.Font.GothamBold, Parent = b})
		L({Position = UDim2.fromOffset(tx,28), Size = UDim2.fromOffset(186-tx-8,16), Text = sub, TextColor3 = C.sub, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd, Parent = b})
		fx(b, C.sec)
		b.MouseButton1Click:Connect(function()
			copy(val); msg.Text = name .. " link copied"
			Lib.Notify({Title = name, Content = "Link copied to clipboard", Type = "success", Duration = 2.5})
		end)
	end
	link(178, "Discord", o.Discord or "dsc.gg/yourserver", o.Discord or "dsc.gg/yourserver", ICON.discord)
	link(240, "Website", o.Website or "yoursite.com", o.Website or "yoursite.com", ICON.web)

	-- ═════ Get a key page ═════
	local pg = N("Frame", {Size = UDim2.fromOffset(396,330), BackgroundColor3 = C.bg, Visible = false, Active = true, Parent = f}, {R(12)})
	Ic({Position = UDim2.fromOffset(22,22), Size = UDim2.fromOffset(22,22), Image = ICON.key, ImageColor3 = C.ac, Parent = pg})
	L({Position = UDim2.fromOffset(52,20), Size = UDim2.fromOffset(200,26), Text = "Get a key", Font = Enum.Font.GothamBold, TextSize = 20, Parent = pg})
	L({Position = UDim2.fromOffset(22,50), Size = UDim2.fromOffset(260,18), Text = "Demo mode: use the key below", TextColor3 = C.sub, TextSize = 12, Parent = pg})
	local back = btn(pg, 292, 22, 80, 30, "< Back", C.el)

	local function field(y, title, val)
		L({Position = UDim2.fromOffset(22,y), Size = UDim2.fromOffset(200,18), Text = title, TextColor3 = C.sub, TextSize = 12, Parent = pg})
		N("TextBox", {Position = UDim2.fromOffset(22,y+22), Size = UDim2.fromOffset(268,40), BackgroundColor3 = C.sec, Text = val, TextColor3 = C.tx, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Left, ClearTextOnFocus = false, TextEditable = false, Parent = pg}, {R(8), S(), pad(14,0,14,0)})
		local cb = btn(pg, 298, y+22, 74, 40, "Copy", C.el)
		cb.MouseButton1Click:Connect(function()
			copy(val); cb.Text = "Copied"; task.delay(1.2, function() cb.Text = "Copy" end)
			Lib.Notify({Title = title, Content = "Copied to clipboard", Type = "success", Duration = 2.5})
		end)
	end
	field(84, "Key link", o.Link or "https://example.com/getkey")
	field(172, "Demo key", o.Key)
	local use = btn(pg, 22, 262, 350, 40, "Use demo key", C.ac, WHITE, ICON.key)
	use.MouseButton1Click:Connect(function() box.Text = o.Key; pg.Visible = false; msg.Text = "Demo key filled, press Submit" end)

	getkey.MouseButton1Click:Connect(function() pg.Visible = true end)
	back.MouseButton1Click:Connect(function() pg.Visible = false end)

	submit.MouseButton1Click:Connect(function()
		if (box.Text:gsub("%s", "")) == o.Key then
			st.Text, st.TextColor3 = "Valid", C.green
			msg.Text, msg.TextColor3 = "Key accepted", C.green
			Lib.Notify({Title = "Key accepted", Content = "Welcome, loading interface...", Type = "success"})
			if save then pcall(writefile, file, o.Key) end
			task.wait(.6)
			gui:Destroy()
			onOk()
		else
			st.Text, st.TextColor3 = "Invalid key", C.red
			msg.Text, msg.TextColor3 = "Wrong key, try again", C.red
			Lib.Notify({Title = "Invalid key", Content = "The key you entered is wrong", Type = "error"})
		end
	end)
end

-- ═════════════════ MAIN UI ═════════════════
function Lib.new(title, logo)
	local gui = mount()
	local lp = Players.LocalPlayer
	local conns = {}
	local function bind(sig, fn) local c = sig:Connect(fn); table.insert(conns, c); return c end

	local FULL, MINI = UDim2.fromOffset(560,390), UDim2.fromOffset(560,44)
	local main = N("Frame", {AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = FULL, BackgroundColor3 = C.bg, Active = true, ClipsDescendants = true, Parent = gui}, {R(12), S()})
	local top = N("Frame", {Size = UDim2.new(1,0,0,44), BackgroundTransparency = 1, Parent = main})
	local lg = N("Frame", {Position = UDim2.fromOffset(10,7), Size = UDim2.fromOffset(30,30), BackgroundColor3 = C.ac, Parent = top}, {R(8)})
	if logo and logo ~= "" then
		Ic({Size = UDim2.fromScale(1,1), Image = logo, Parent = lg})
	else
		Ic({AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(18,18), Image = ICON.key, ImageColor3 = WHITE, Parent = lg})
	end
	L({Position = UDim2.fromOffset(48,0), Size = UDim2.fromOffset(100,44), Text = title, Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd, Parent = top})
	local bar = N("Frame", {Position = UDim2.fromOffset(150,8), Size = UDim2.new(1,-230,0,28), BackgroundTransparency = 1, Parent = top}, {N("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,6)})})
	local pages = N("Frame", {Position = UDim2.fromOffset(10,50), Size = UDim2.new(1,-20,1,-104), BackgroundTransparency = 1, Parent = main})
	drag(top, main)

	-- ═════ Profile footer (รูป + ชื่อเล่น + ชื่อจริง) ═════
	local foot = N("Frame", {AnchorPoint = Vector2.new(0,1), Position = UDim2.new(0,10,1,-10), Size = UDim2.new(1,-20,0,40), BackgroundColor3 = C.sec, Parent = main}, {R(10), S()})
	N("ImageLabel", {Position = UDim2.fromOffset(6,5), Size = UDim2.fromOffset(30,30), BackgroundColor3 = C.el, Image = "rbxthumb://type=AvatarHeadShot&id=" .. lp.UserId .. "&w=150&h=150", Parent = foot}, {N("UICorner", {CornerRadius = UDim.new(1,0)})})
	L({Position = UDim2.fromOffset(44,3), Size = UDim2.new(.55,-44,0,18), Text = lp.DisplayName, Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd, Parent = foot})
	L({Position = UDim2.fromOffset(44,20), Size = UDim2.new(.55,-44,0,16), Text = "@" .. lp.Name, TextColor3 = C.sub, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd, Parent = foot})
	L({AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-12,.5,0), Size = UDim2.new(.45,-12,0,18), Text = "RightCtrl = hide / show", TextXAlignment = Right, TextColor3 = C.sub, TextSize = 11, Parent = foot})

	-- ═════ ปุ่ม ปิด (X) และ ย่อ (-) ═════
	local closeB = N("TextButton", {AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-10,.5,0), Size = UDim2.fromOffset(28,28), BackgroundColor3 = C.el, Text = "", AutoButtonColor = false, Parent = top}, {R(8)})
	Ic({AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(14,14), Image = ICON.close, ImageColor3 = C.tx, Parent = closeB})
	fx(closeB, C.el)

	local miniB = N("TextButton", {AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-44,.5,0), Size = UDim2.fromOffset(28,28), BackgroundColor3 = C.el, Text = "-", TextColor3 = C.tx, Font = Enum.Font.GothamBold, TextSize = 20, AutoButtonColor = false, Parent = top}, {R(8)})
	local expIc = Ic({AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(14,14), Image = ICON.expand, ImageColor3 = C.tx, Visible = false, Parent = miniB})
	fx(miniB, C.el)

	local mini = false
	local function setMini(v)
		mini = v
		miniB.Text = v and "" or "-"
		expIc.Visible = v
		if v then
			local tw = TS:Create(main, TweenInfo.new(.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = MINI})
			tw.Completed:Connect(function()
				if mini then pages.Visible = false; bar.Visible = false; foot.Visible = false end
			end)
			tw:Play()
		else
			pages.Visible = true; bar.Visible = true; foot.Visible = true
			TS:Create(main, TweenInfo.new(.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = FULL}):Play()
		end
	end
	miniB.MouseButton1Click:Connect(function() setMini(not mini) end)

	bind(UIS.InputBegan, function(i, g) if not g and i.KeyCode == Enum.KeyCode.RightControl then main.Visible = not main.Visible end end)
	local function destroy()
		for _, c in ipairs(conns) do c:Disconnect() end
		gui:Destroy()
	end
	closeB.MouseButton1Click:Connect(destroy)

	local W, tabs = {}, {}
	function W:Destroy() destroy() end
	function W:Notify(o) return Lib.Notify(o) end

	function W:Tab(name, icon)
		local b = N("TextButton", {Size = UDim2.new(0,0,1,0), AutomaticSize = Enum.AutomaticSize.X, Text = name, Font = Enum.Font.GothamMedium, TextSize = 12, AutoButtonColor = false, BackgroundColor3 = C.el, TextColor3 = C.sub, Parent = bar}, {R(8), pad(icon and 32 or 12,0,12,0)})
		local ic
		if icon then
			ic = Ic({AnchorPoint = Vector2.new(0,.5), Position = UDim2.new(0,-22,.5,0), Size = UDim2.fromOffset(14,14), Image = icon, ImageColor3 = C.sub, Parent = b})
		end
		local pg = N("Frame", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Visible = false, Parent = pages})
		local function col(x)
			return N("ScrollingFrame", {Position = UDim2.new(x, x == 0 and 0 or 5, 0, 0), Size = UDim2.new(.5,-5,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = pg}, {list(8)})
		end
		local cols, n = {col(0), col(.5)}, 0
		local t = {b = b, pg = pg, ic = ic}
		table.insert(tabs, t)
		local function sel()
			for _, x in ipairs(tabs) do
				local on = (x == t)
				x.pg.Visible = on
				T(x.b, {BackgroundColor3 = on and C.ac or C.el, TextColor3 = on and WHITE or C.sub})
				if x.ic then T(x.ic, {ImageColor3 = on and WHITE or C.sub}) end
			end
		end
		b.MouseButton1Click:Connect(sel)
		if #tabs == 1 then sel() end

		local Tb = {}
		function Tb:Section(name)
			n = n + 1
			local f = N("Frame", {Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.sec, Parent = cols[(n-1) % 2 + 1]}, {R(8), S(), pad(10,8,10,10), list(6)})
			L({Size = UDim2.new(1,0,0,16), Text = name, Font = Enum.Font.GothamBold, LayoutOrder = -1, Parent = f})
			local s = {}
			local function row(h) return N("Frame", {Size = UDim2.new(1,0,0,h), BackgroundTransparency = 1, Parent = f}) end

			-- Toggle(name, default, callback(bool))
			function s:Toggle(name, on, cb)
				local r = row(28)
				L({Size = UDim2.new(1,-30,1,0), Text = name, Parent = r})
				local bx = N("Frame", {AnchorPoint = Vector2.new(1,.5), Position = UDim2.fromScale(1,.5), Size = UDim2.fromOffset(22,22), BackgroundColor3 = C.el, Parent = r}, {N("UICorner", {CornerRadius = UDim.new(1,0)})})
				local sk = S(); sk.Thickness = 1.5; sk.Parent = bx
				local tick = Ic({AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(0,0), Image = ICON.tick, ImageColor3 = WHITE, ImageTransparency = 1, Rotation = -25, Parent = bx})
				local tweenIn  = TweenInfo.new(.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				local tweenOut = TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local function up(instant)
					local gBx = {BackgroundColor3 = on and C.green or C.el}
					local gSk = {Color = on and C.green or C.st}
					local gTk = on and {Size = UDim2.fromOffset(14,14), ImageTransparency = 0, Rotation = 0}
						or {Size = UDim2.fromOffset(0,0), ImageTransparency = 1, Rotation = -25}
					if instant then
						for k, v in pairs(gBx) do bx[k] = v end
						for k, v in pairs(gSk) do sk[k] = v end
						for k, v in pairs(gTk) do tick[k] = v end
					else
						T(bx, gBx); T(sk, gSk)
						TS:Create(tick, on and tweenIn or tweenOut, gTk):Play()
					end
				end
				up(true)
				N("TextButton", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Text = "", Parent = r}).MouseButton1Click:Connect(function()
					on = not on; up(); if cb then cb(on) end
				end)
			end

			-- Slider(name, min, max, default, onChange(v), onRelease(v))
			function s:Slider(name, min, max, def, cb, done)
				local r = row(40)
				L({Size = UDim2.new(1,-60,0,18), Text = name, Parent = r})
				local vl = L({AnchorPoint = Vector2.new(1,0), Position = UDim2.fromScale(1,0), Size = UDim2.fromOffset(60,18), Text = tostring(def), TextColor3 = C.sub, TextXAlignment = Right, Parent = r})
				local sb = N("Frame", {Position = UDim2.fromOffset(0,26), Size = UDim2.new(1,0,0,6), BackgroundColor3 = C.el, Parent = r}, {R(3)})
				local fl = N("Frame", {Size = UDim2.fromScale((def-min)/(max-min),1), BackgroundColor3 = C.ac, Parent = sb}, {R(3)})
				local dr, cur = false, def
				local function set(x)
					local a = math.clamp((x - sb.AbsolutePosition.X) / sb.AbsoluteSize.X, 0, 1)
					cur = math.floor(min + (max-min)*a + .5)
					fl.Size = UDim2.fromScale(a, 1); vl.Text = tostring(cur)
					if cb then cb(cur) end
				end
				N("TextButton", {Position = UDim2.fromOffset(0,16), Size = UDim2.new(1,0,0,24), BackgroundTransparency = 1, Text = "", Parent = r}).InputBegan:Connect(function(i)
					if press(i) then dr = true; set(i.Position.X) end
				end)
				bind(UIS.InputChanged, function(i) if dr and move(i) then set(i.Position.X) end end)
				bind(UIS.InputEnded, function(i)
					if dr and press(i) then dr = false; if done then done(cur) end end
				end)
			end

			-- Button(name, callback)
			function s:Button(name, cb)
				local b = N("TextButton", {Size = UDim2.new(1,0,0,28), BackgroundColor3 = C.el, Text = name, TextColor3 = C.tx, Font = Enum.Font.GothamMedium, TextSize = 13, AutoButtonColor = false, Parent = f}, {R(6), S()})
				Ic({AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-8,.5,0), Size = UDim2.fromOffset(14,14), Image = ICON.clip, ImageColor3 = C.sub, Parent = b})
				fx(b, C.el)
				b.MouseButton1Click:Connect(function() if cb then cb() end end)
			end

			-- Dropdown ใช้ร่วมกัน 2 โหมด
			local function makeDropdown(name, opts, def, cb, multi)
				local h = N("Frame", {Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = f}, {list(4)})
				local hd = N("TextButton", {Size = UDim2.new(1,0,0,28), BackgroundColor3 = C.el, Text = "", TextXAlignment = Left, TextColor3 = C.tx, Font = Enum.Font.GothamMedium, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, AutoButtonColor = false, LayoutOrder = 0, Parent = h}, {R(6), S(), pad(10,0,30,0)})
				local arrow = Ic({AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-8,.5,0), Size = UDim2.fromOffset(12,12), Image = ICON.arrowDown, ImageColor3 = C.sub, Parent = hd})
				fx(hd, C.el)
				local ls = N("Frame", {Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.el, Visible = false, LayoutOrder = 1, Parent = h}, {R(6), list(0)})

				local chosen, single = {}, def
				if multi then for _, v in ipairs(def or {}) do chosen[tostring(v)] = true end end
				local function selected()
					local out = {}
					for _, o in ipairs(opts) do if chosen[tostring(o)] then table.insert(out, o) end end
					return out
				end
				local function refreshHead()
					if multi then
						local sl = selected()
						hd.Text = name .. ": " .. (#sl == 0 and "None" or table.concat(sl, ", "))
					else
						hd.Text = name .. ": " .. tostring(single)
					end
				end
				refreshHead()
				local function setOpen(v)
					ls.Visible = v
					arrow.Image = v and ICON.arrowUp or ICON.arrowDown
				end
				for i, o in ipairs(opts) do
					local key = tostring(o)
					local ob = N("TextButton", {Size = UDim2.new(1,0,0,24), BackgroundTransparency = 1, Text = "  " .. key, TextXAlignment = Left, TextColor3 = C.sub, Font = Enum.Font.GothamMedium, TextSize = 12, AutoButtonColor = false, LayoutOrder = i, Parent = ls})
					local tk
					if multi then
						tk = Ic({AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,-8,.5,0), Size = UDim2.fromOffset(12,12), Image = ICON.tick, ImageColor3 = C.green, ImageTransparency = chosen[key] and 0 or 1, Parent = ob})
						ob.TextColor3 = chosen[key] and C.tx or C.sub
					end
					ob.MouseButton1Click:Connect(function()
						if multi then
							chosen[key] = (not chosen[key]) or nil -- กดซ้ำ = ยกเลิก
							local on = chosen[key] == true
							T(tk, {ImageTransparency = on and 0 or 1})
							T(ob, {TextColor3 = on and C.tx or C.sub})
							refreshHead()
							if cb then cb(selected()) end
						else
							single = o
							refreshHead(); setOpen(false)
							if cb then cb(o) end
						end
					end)
				end
				hd.MouseButton1Click:Connect(function() setOpen(not ls.Visible) end)
			end

			-- Dropdown(name, options, default, callback(value))
			function s:Dropdown(name, opts, def, cb) makeDropdown(name, opts, def, cb, false) end
			-- MultiDropdown(name, options, {defaults}, callback({values}))
			function s:MultiDropdown(name, opts, def, cb) makeDropdown(name, opts, def, cb, true) end
			return s
		end
		return Tb
	end
	return W
end

return Lib
