PocoRoseClass = class()

function PocoRoseClass:update_text_rect(text)
	local _, _, w, h = text:text_rect()
	text:set_w(w)
	text:set_h(h)

	return w, h
end

function PocoRoseClass:blend_colors(current, target, blend)
	local result = {
		r = (current.r * blend) + (target.r * (1 - blend)),
		g = (current.g * blend) + (target.g * (1 - blend)),
		b = (current.b * blend) + (target.b * (1 - blend)),
	}

	return Color(result.r, result.g, result.b)
end

function PocoRoseClass:animate_ui(total_t, callback)
	local t = 0
	local const_frames = 0
	local count_frames = const_frames + 1
	while t < total_t do
		coroutine.yield()
		t = t + TimerManager:main():delta_time()
		if count_frames >= const_frames then
			callback(t / total_t, t)
			count_frames = 0
		end
		count_frames = count_frames + 1
	end

	callback(1, total_t)
end

function PocoRoseClass:is_mouse_in_panel(panel)
	if not alive(panel) then
		return false
	end

	return panel:inside(self.menu_mouse_x, self.menu_mouse_y)
end

function PocoRoseClass:init()
	self._ws = managers.gui_data:create_fullscreen_workspace()
	self._panel = self._ws:panel():panel({
		visible = false,
		alpha = 0,
		layer = 10,
	})

	self.menu_mouse_id = managers.mouse_pointer:get_id()
	self._sound_source = SoundDevice:create_source("poco_sound")
	self.font = {
		path = "fonts/font_medium_mf",
		size = 20,
	}

	self.items = {}
	self._selected_rose = 1
	self._selected_index = 1

	self:setup_panels()
end

function PocoRoseClass:setup_panels()
	-- looks better with 2 bgs :/
	self:create_background()

	self.main_panel = self._panel:panel()
	self:create_menu()
end

function PocoRoseClass:create_background()
	-- directly yeeted from pocohud
	local background_panel = self._panel:panel({ alpha = 0.4 })
	background_panel:gradient({
		layer = -1,
		gradient_points = {
			0,
			Color.black,
			1,
			Color.black:with_alpha(0),
		},
		orientation = "vertical",
		h = self._panel:h() / 3,
	})
	background_panel:gradient({
		layer = -1,
		gradient_points = {
			0,
			Color.black:with_alpha(0),
			1,
			Color.black:with_alpha(1),
		},
		orientation = "vertical",
		y = self._panel:h() / 3 * 2,
		h = self._panel:h() / 3,
	})
	background_panel:gradient({
		layer = -1,
		gradient_points = {
			0,
			Color.black:with_alpha(1),
			1,
			Color.black:with_alpha(0),
		},
		orientation = "horizontal",
		w = self._panel:w() / 3,
	})
	background_panel:gradient({
		layer = -1,
		gradient_points = {
			0,
			Color.black:with_alpha(0),
			1,
			Color.black:with_alpha(1),
		},
		orientation = "horizontal",
		x = self._panel:w() / 3 * 2,
		w = self._panel:w() / 3,
	})
end

function PocoRoseClass:get_layout()
	-- directly yeeted from pocohud
	self._layouts = {
		[1] = {
			{
				{ "Whistle", "whistling_attention" },
				{ "Use cable ties", "g26" },
				{ "I need a medic bag", "g80x_plu" },
				{ "Shoot 'em", "g23" },
				{ "I got the drill", "g61" },
			},
			{
				{ "We're overrun", "g68" },
				{ "Time to go", "g17" },
				{ "This way", "g12" },
				{ "Straight ahead", "g19" },
				{ "Can't stay here", "g69" },
			},
			{
				{ "Almost there", "g28" },
				{ "Get out", "g07" },
				{ "Upstairs", "g02" },
				{ "Hurry", "g09" },
				{ "Alright", "g92" },
			},
			{
				{ "Let's go", "g13" },
				{ "Left", "g03" },
				false,
				{ "Right", "g04" },
				{ "Thanks", "s05x_sin" },
			},
			{
				{ "Halfway done", "t02x_sin" },
				{ "Careful", "g10" },
				{ "Downstairs", "g01" },
				{ "Inside", "g08" },
				{ "Any second", "t03x_sin" },
			},
			{
				{ "A few more minutes", "t01x_sin" },
				{ "Down here", "g20" },
				{ "Wrong way", "g11" },
				{ "Keep defended", "g16" },
				{ "Take cameras", "g25" },
			},
			{
				false,
				{ "Shit", "g60" },
				{ "I need an ammo bag", "g81x_plu" },
				{ "Fuck", "g29" },
				false,
			},
		},
		[2] = {
			{
				false,
				false,
				{ "what to do?", "v36" },
				false,
				false,
			},
			{
				{ "it's stuck", "v52" },
				{ "that's all of them", "p28" },
				{ "get the fuck up", "f36x_any" },
				{ "sniper", "f34x_any" },
				{ "bulldozer", "f30x_any" },
			},
			{
				{ "smells bad", "v53" },
				{ "drill in place", "g21" },
				{ "hello", "v56" },
				{ "cloaker", "f33x_any" },
				{ "shield", "f31x_any" },
			},
			{
				{ "help", "p45" },
				{ "payday", "v21" },
				false,
				{ "find the manager", "v33" },
				{ "taser", "f32x_any" },
			},
			{
				{ "flashbang", "g41x_any" },
				{ "heat speech", "v34" },
				{ "let's rock", "a01x_any" },
				{ "captain", "f45x_any" },
				{ "turret", "v45" },
			},
			{
				{ "come on", "p04" },
				{ "plan b", "p21" },
				{ "woohoo!", "v55" },
				{ "interrogation", "f46x_any" },
				{ "swat van", "p42" },
			},
			{
				{ "reviving", "s08x_sin" },
				false,
				{ "open the door", "v15" },
				false,
				{ "medic", "f47x_any" },
			},
		},
	}

	return self._layouts[self._selected_rose]
end

function PocoRoseClass:create_menu()
	self.main_panel:clear()

	-- directly yeeted from pocohud
	local w, h = 200, 70
	local ox, oy = self.main_panel:w() / 2 - 2 * w, self.main_panel:h() / 2 - 3 * h
	for y, row in pairs(self:get_layout()) do
		for x, obj in pairs(row) do
			if obj then
				local xx = ox + (x - 1) * w
				local yy = oy + (y - 1) * h
				if x == 3 then
					yy = yy + h * 0.5 * (y > 4 and 1 or -1)
				end

				if y == 4 then
					xx = xx + w * 0.3 * (x > 3 and 1 or -1)
				end

				self:create_button({
					parent = self.main_panel:panel({ w = w, h = h }),
					x = xx,
					y = yy,
					item = {
						id = "item_" .. y .. "_row_" .. x,
						text = obj[1]:upper(),
						arg = obj[2],
					},
				})
			end
		end
	end

	local index = self.main_panel:text({
		text = "Page " .. self._selected_rose .. "/" .. #self._layouts,
		font = self.font.path,
		font_size = self.font.size,
	})
	self:update_text_rect(index)
	index:set_center(self.main_panel:center())
end

function PocoRoseClass:create_button(data)
	data.parent:set_center(data.x, data.y)

	local item = data.item
	local item_panel = data.parent:panel({
		layer = 1,
	})

	local text = item_panel:text({
		text = item.text,
		font = self.font.path,
		font_size = self.font.size,
		color = Color(0.7, 0.7, 0.7),
	})
	self:update_text_rect(text)
	text:set_center(item_panel:center())

	-- self:debug_panel_outline(item_panel)
	self.items[item.id] = {
		panel = item_panel:parent(),
		text = text,
		table_ptr = item,
	}
end

function PocoRoseClass:check_feature_hover()
	if self._current_feature_hover then
		local item = self.items[self._current_feature_hover]
		if not alive(item.panel) then
			self._current_feature_hover = nil
			return
		end

		if not self:is_mouse_in_panel(item.panel) then
			local panel = item.text
			panel:stop()
			panel:animate(function(o)
				self:animate_ui(2, function(p)
					o:set_font_size(math.lerp(o:font_size(), 20, p))
					o:set_kern(math.lerp(o:kern(), -0.5, p))
					self:update_text_rect(o)
					o:set_center(item.panel:child(0):center())

					o:set_color(self:blend_colors(o:color(), Color(0.7, 0.7, 0.7), p))
				end)
				o:set_center(item.panel:child(0):center())
			end)
			self._current_feature_hover = nil
		end
		return
	end

	if not next(self.items) then
		return
	end

	for i, item in pairs(self.items) do
		if self:is_mouse_in_panel(item.panel) then
			self._current_feature_hover = i
			local panel = item.text
			panel:stop()
			panel:animate(function(o)
				self:animate_ui(2, function(p)
					o:set_font_size(math.lerp(o:font_size(), 24, p))
					o:set_kern(math.lerp(o:kern(), 1, p))

					self:update_text_rect(o)
					o:set_center(item.panel:child(0):center())

					o:set_color(self:blend_colors(o:color(), Color(1, 1, 1), p))
				end)
				o:set_center(item.panel:child(0):center())
			end)
			return
		end
	end
end

function PocoRoseClass:mouse_move(_, x, y)
	self.menu_mouse_x, self.menu_mouse_y = x, y

	self:check_feature_hover()
end

function PocoRoseClass:voice_line_play(line)
	local player = managers.player:player_unit()

	if not alive(player) then
		return
	end

	player:sound():say(line, true, true)
end

function PocoRoseClass:mouse_press(_, button, x, y)
	self.menu_mouse_x, self.menu_mouse_y = x, y
	if button == Idstring("0") then
		for _, item in pairs(self.items) do
			if self:is_mouse_in_panel(item.panel) then
				self:voice_line_play(item.table_ptr.arg)
				return
			end
		end
		return
	elseif button == Idstring("mouse wheel up") then
		self._selected_index = self._selected_index + 1

		if self._selected_index > #self._layouts then
			self._selected_index = #self._layouts
		end

		if self._selected_index == self._selected_rose then
			return
		end

		self._selected_rose = self._selected_index

		self:create_menu()
	elseif button == Idstring("mouse wheel down") then
		self._selected_index = self._selected_index - 1

		if self._selected_index <= 0 then
			self._selected_index = 1
		end

		if self._selected_index == self._selected_rose then
			return
		end

		self._selected_rose = self._selected_index

		self:create_menu()
	end
end

function PocoRoseClass:is_open()
	return self._active
end

function PocoRoseClass:open()
	if self._active then
		return
	end

	self._active = true

	self._sound_source:post_event("prompt_enter")

	self._panel:stop()
	self._panel:animate(function(o)
		o:show()
		o:set_alpha(0)

		self:animate_ui(1, function(p)
			o:set_alpha(math.lerp(o:alpha(), 1, p))
		end)

		o:set_alpha(1)
	end)

	managers.menu._input_enabled = false
	for _, menu in ipairs(managers.menu._open_menus) do
		menu.input._controller:disable()
	end

	if not self._controller then
		self._controller = managers.controller:create_controller("rose_controller", nil, false)
		self._controller:add_trigger("cancel", callback(self, self, "keyboard_cancel"))

		managers.mouse_pointer:use_mouse({
			mouse_move = callback(self, self, "mouse_move"),
			mouse_press = callback(self, self, "mouse_press"),
			id = self.menu_mouse_id,
		})
	end
	self._controller:enable()
end

function PocoRoseClass:close()
	self._active = false

	managers.gui_data:layout_fullscreen_workspace(managers.mouse_pointer._ws)
	managers.mouse_pointer:remove_mouse(self.menu_mouse_id)
	if self._controller then
		self._controller:destroy()
		self._controller = nil
	end

	managers.menu._input_enabled = true
	for _, menu in ipairs(managers.menu._open_menus) do
		menu.input._controller:enable()
	end

	self._sound_source:post_event("prompt_exit")

	self._panel:stop()
	self._panel:animate(function(o)
		self:animate_ui(1, function(p)
			o:set_alpha(math.lerp(o:alpha(), 0, p))
		end)
		o:set_alpha(0)
		o:hide()
	end)
end

function PocoRoseClass:toggle_menu()
	if self:is_open() then
		self:close()
		return
	end

	self:open()
end

function PocoRoseClass:keyboard_cancel()
	if not self:is_open() then
		return
	end

	self:close()
end

--

if RequiredScript == "lib/states/ingamewaitingforplayers" then
	Hooks:PostHook(IngameWaitingForPlayersState, "at_exit", "pocorose_init", function(...)
		rawset(_G, "PocoRose", PocoRoseClass:new())
	end)
end

if RequiredScript == "lib/managers/menumanager" then
	local orig = MenuManager.toggle_menu_state
	function MenuManager:toggle_menu_state()
		local rose = rawget(_G, "PocoRose")
		if rose and rose:is_open() then
			return
		end

		orig(self)
	end
end

if RequiredScript == "lib/units/beings/player/states/playerstandard" then
	local orig_primary = PlayerStandard._check_action_primary_attack
	function PlayerStandard:_check_action_primary_attack(...)
		local rose = rawget(_G, "PocoRose")
		if rose and rose:is_open() then
			return nil
		end

		return orig_primary(self, ...)
	end

	local orig_steelsight = PlayerStandard._check_action_steelsight
	function PlayerStandard:_check_action_steelsight(_, input)
		local rose = rawget(_G, "PocoRose")
		if rose and rose:is_open() then
			if input.btn_steelsight_press then
				rose:close()
			end

			return
		end

		return orig_steelsight(self, _, input)
	end
end

if RequiredScript == "lib/units/cameras/fpcameraplayerbase" then
	local orig = FPCameraPlayerBase._update_rot
	function FPCameraPlayerBase:_update_rot(...)
		local rose = rawget(_G, "PocoRose")
		if rose and rose:is_open() then
			return
		end

		orig(self, ...)
	end
end
