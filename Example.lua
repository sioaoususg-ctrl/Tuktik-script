-- เปลี่ยน USERNAME / REPO ให้เป็นของคุณ
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/REPO/main/Library.lua"))()

Lib.Key({
	Title   = "My Hub",
	Logo    = "",                       -- ว่าง = ใช้ไอคอนกุญแจ
	Key     = "DEMO-KEY-1234",
	Link    = "https://example.com/getkey",
	Discord = "dsc.gg/yourserver",
	Website = "yoursite.com",
	Save    = false,                    -- ทดสอบ = false / ใช้จริง = true
}, function()
	local w = Lib.new("My Hub")

	-- ═════ MAIN ═════
	local main = w:Tab("MAIN", Lib.Icons.home)

	local a = main:Section("Tween Speed")
	a:Slider("Tween Speed", 50, 500, 350, nil, function(v)
		Lib.Notify({Title = "Slider", Content = "Tween Speed = " .. v, Type = "info"})
	end)
	a:Toggle("High Tween Pos", true, function(on)
		Lib.Notify({Title = "Toggle", Content = "High Tween Pos: " .. (on and "ON" or "OFF"), Type = on and "success" or "warn"})
	end)
	a:Button("Stop All Tween", function()
		Lib.Notify({Title = "Button", Content = "Stopped all tweens", Type = "success"})
	end)

	local b = main:Section("Berry")
	b:Toggle("Collect Berry", false, function(on)
		Lib.Notify({Title = "Collect Berry", Content = on and "Enabled" or "Disabled", Type = on and "success" or "warn"})
	end)
	b:Dropdown("Mode", {"Near", "Far", "Random"}, "Near", function(v)
		Lib.Notify({Title = "Dropdown", Content = "Mode = " .. v})
	end)
	b:MultiDropdown("Targets", {"Red", "Green", "Blue", "Yellow"}, {"Red"}, function(list)
		Lib.Notify({Title = "MultiDropdown", Content = #list == 0 and "None selected" or table.concat(list, ", ")})
	end)

	local n = main:Section("Notify Test")
	n:Button("Info",    function() Lib.Notify({Title = "Info",    Content = "This is an info notification", Type = "info"}) end)
	n:Button("Success", function() Lib.Notify({Title = "Success", Content = "Everything worked",            Type = "success"}) end)
	n:Button("Warning", function() Lib.Notify({Title = "Warning", Content = "Be careful with this one",     Type = "warn"}) end)
	n:Button("Error",   function() Lib.Notify({Title = "Error",   Content = "Something went wrong",         Type = "error"}) end)

	-- ═════ SETTINGS ═════
	local set = w:Tab("Settings", Lib.Icons.settings)
	local ui = set:Section("Interface")
	ui:Slider("Notify duration (s)", 1, 10, Lib.NotifyDuration, function(v) Lib.NotifyDuration = v end)
	ui:Button("Test notify", function() Lib.Notify({Title = "Test", Content = "Duration = " .. Lib.NotifyDuration .. "s"}) end)
	ui:Button("Destroy UI", function() w:Destroy() end)

	Lib.Notify({Title = "Loaded", Content = "Welcome " .. game.Players.LocalPlayer.DisplayName, Type = "success"})
end)
