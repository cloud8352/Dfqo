function love.conf (t)
	io.stdout:setvbuf("no")
	t.window.title = "Dungeon Fighter Quest"
	t.window.width = 1280
	t.window.height = 720
	t.window.highdpi = true

	t.window.borderless = false        -- 移除所有程序边框的视觉效果 (boolean)
	t.window.resizable = false         -- 允许鼠标拖动调整窗口的宽度和高度 (boolean)
	t.window.minwidth = 1280              -- 程序窗口的最小宽度，仅当t.window.resizable = true 时生效 (number)
	t.window.minheight = 720             -- 程序窗口的最小高度，仅当t.window.resizable = true 时生效 (number)
	t.window.fullscreen = false        -- 打开程序后全屏运行游戏 (boolean)
	t.window.fullscreentype = "desktop" -- Choose between "desktop" fullscreen or "exclusive" fullscreen mode (string)
		                       -- 标准全屏或者桌面全屏 (string)
	t.window.vsync = false             -- 垂直同步 (boolean)
	t.window.fsaa = 0                  -- 采用多样本采样抗锯齿 (number)
	t.window.display = 1               -- 显示器的指示显示窗口 (number)
	t.window.highdpi = false           -- 允许在视网膜显示器(Retina)下使用高DPI模式 (boolean)
	t.window.srgb = false              -- 在屏幕上显示时允许使用sRGB伽马校正 (boolean)

	t.modules.audio = true             -- 加载 audio        模块 (boolean)
	t.modules.event = true             -- 加载 event        模块 (boolean)
	t.modules.graphics = true          -- 加载 graphics     模块 (boolean)
	t.modules.image = true             -- 加载 image        模块 (boolean)
	t.modules.joystick = true          -- 加载 the joystick 模块 (boolean)
	t.modules.keyboard = true          -- 加载 keyboard     模块 (boolean)
	t.modules.math = true              -- 加载 math         模块 (boolean)
	t.modules.mouse = true             -- 加载 mouse        模块 (boolean)
	t.modules.physics = true           -- 加载 physics      模块 (boolean)
	t.modules.sound = true             -- 加载 sound        模块 (boolean)
	t.modules.system = true            -- 加载 system       模块 (boolean)
	t.modules.timer = true             -- 加载 timer        模块 (boolean)
	t.modules.window = true            -- 加载 window       模块 (boolean)
	t.modules.thread = true            -- 加载 thread       模块 (boolean)
end
