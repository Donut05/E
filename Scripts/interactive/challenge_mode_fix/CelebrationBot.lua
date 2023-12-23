-- CelebrationBot.lua --

CelebrationBot = class()

CelebrationBot.maxParentCount = 1
CelebrationBot.maxChildCount = 0
CelebrationBot.connectionInput = sm.interactable.connectionType.logic
CelebrationBot.connectionOutput = sm.interactable.connectionType.none
CelebrationBot.colorNormal = sm.color.new(0xada9a5ff)
CelebrationBot.colorHighlight = sm.color.new(0xcac6c2ff)

--[[ Server ]]

-- (Event) Called upon game tick. (40 times a second)
function CelebrationBot.server_onFixedUpdate(self, timeStep)
	-- Update active state
	local parent = self.interactable:getSingleParent()
	if parent then
		self.interactable.active = parent.active
	else
		self.interactable.active = false
	end
end

function CelebrationBot.sv_launchFirework(self)
	local offset = sm.vec3.zero()
	if self.lastFireworkWasRight then
		offset = self.shape.worldPosition + (-self.shape.right * 1.9 - self.shape.up * 0.5 + self.shape.at * 0.14)
	else
		offset = self.shape.worldPosition + (self.shape.right * 1.9 - self.shape.up * 0.5 + self.shape.at * 0.14)
	end
	self.lastFireworkWasRight = not self.lastFireworkWasRight
	local height = self.shape.at * 15
	local hit, result = sm.physics.raycast(offset, offset + height)
	if hit then
		height = result.pointWorld * self.shape.at
	end
	sm.physics.explode(height + offset, 7, 2, 6, 25, "PropaneTank - ExplosionSmall")
	if self.fireworkColorCounter > #G_fireworkColors then
		self.fireworkColorCounter = 1
	end
	local params = {
		name = "p_firework_generic",
		pos = height + offset,
		color = G_fireworkColors[self.fireworkColorCounter]
	}
	self.network:sendToClients("cl_createParticle", params)
	self.fireworkColorCounter = self.fireworkColorCounter + 1
	params = {
		name = "p_firework_shoot",
		pos = offset
	}
	self.network:sendToClients("cl_createParticle", params)
end

--[[ Client ]]

-- (Event) Called upon creation on client
function CelebrationBot.client_onCreate(self)
	self:client_init()
end

-- (Event) Called when script is refreshed (in [-dev])
function CelebrationBot.client_onRefresh(self)
	self:client_init()
end

-- Initialize CelebrationBot
function CelebrationBot.client_init(self)
	self.animationProgress = 0.0
	self.animationSpeed = 0.0
	self.celebratingFlag = false
	self.specialFlag = false
	self.lastFireworkWasRight = true
	self.fireworkStepCounter = 1
	self.fireworkColorCounter = 1
	G_fireworkTimings = {
		2500,
		500,
		20,
		20,
		20,
		20,
		20,
		20,
		500,
		20,
		20,
		20,
		20,
		20,
		10,
		10,
		5,
		5,
		820,
		20,
		20,
		10,
		10,
		100,
		20,
		20,
		10,
		10,
		570,
		20,
		20,
		20,
		20,
		560,
		20,
		20,
		20,
		40,
		220,
		20,
		20,
		20,
		120
	}
	G_fireworkColors = {
		sm.color.new("ff0000ff"),
		sm.color.new("ff7f00ff"),
		sm.color.new("ffcc00ff"),
		sm.color.new("ffffffff")
	}
	self.confettiEffectLeft = sm.effect.createEffect("CelebrationBot - Confetti", self.interactable, "pejnt_right")
	self.confettiEffectRight = sm.effect.createEffect("CelebrationBot - Confetti", self.interactable, "pejnt_left")
	self.launcherEffectLeft = sm.effect.createEffect("CelebrationBot - Launcher_open", self.interactable)
	self.launcherEffectRight = sm.effect.createEffect("CelebrationBot - Launcher_open", self.interactable)
	self.launcherEffectLeftClose = sm.effect.createEffect("CelebrationBot - Launcher_close", self.interactable)
	self.launcherEffectRightClose = sm.effect.createEffect("CelebrationBot - Launcher_close", self.interactable)
	if sm.cae_injected then
		self.audioEffectSpecial = sm.effect.createEffect("CelebrationBot - Communism", self.interactable)
		-- Init timers
		self.musicLoopFixTimer = sm.game.getCurrentTick()
		self.musicSyncTimer = sm.game.getCurrentTick()
	end
	self.audioEffectNormal = sm.effect.createEffect("CelebrationBot - Audio", self.interactable)
end

-- (Event) Called upon every frame. (Same as fps)
function CelebrationBot.client_onUpdate(self, dt)
	if self.interactable.active and not self.celebratingFlag then
		-- Start the celebration
		self.celebratingFlag = true
		self:start_animation("Celebration_start", 20)

		if true then --math.random(0, 100) == 0 then
			self.musicLoopFixTimer = sm.game.getCurrentTick()
			self.fireworkStepCounter = 1
			self.musicSyncTimer = sm.game.getCurrentTick() + G_fireworkTimings[1]
			self.specialFlag = true
			self.audioEffect = self.audioEffectSpecial
		else
			self.audioEffect = self.audioEffectNormal
		end
	end

	if not self.interactable.active and self.celebratingFlag then
		-- End the celebration
		self.specialFlag = false
		self.celebratingFlag = false
		self:start_animation("Celebration_start", 20, 0.5)

		self.confettiEffectLeft:stop()
		self.confettiEffectRight:stop()
		self.audioEffect:stop()
	end

	if self.celebratingFlag then
		-- Update celebration
		self:update_animation(dt)
		if self.currentAnimation == "Celebration_start" and self.animationProgress > 1 then
			-- Start loop and confetti

			self.confettiEffectLeft:start()
			self.confettiEffectRight:start()
			self.audioEffect:start()

			self:start_animation("Celebration_loop", 140)
		end
	else
		-- Play start animation in reverse
		self:update_animation(-dt)
	end
end

function CelebrationBot.client_onFixedUpdate(self, dt)
	if self.specialFlag then
		-- Set launchers' postions
		self.launcherEffectLeft:setOffsetPosition(-self.shape.right * 1.9 - self.shape.up * 0.15 - self.shape.at * 0.589)
		self.launcherEffectRight:setOffsetPosition(self.shape.right * 1.9 - self.shape.up * 0.15 - self.shape.at * 0.589)
		local rot = sm.vec3.getRotation(self.shape.at, self.shape.up)
		self.launcherEffectLeft:setOffsetRotation(rot)
		self.launcherEffectRight:setOffsetRotation(rot)
		-- Deploy launchers
		if not self.launcherEffectLeft:isPlaying() then
			self.launcherEffectLeft:start()
		end
		if not self.launcherEffectRight:isPlaying() then
			self.launcherEffectRight:start()
		end
		-- Loop the song
		if not self.audioEffect:isPlaying() and (sm.game.getCurrentTick() >= self.musicLoopFixTimer + 80) then -- Delay checking loop by 2 seconds becuse :isPlaying() is retarded
			---@diagnostic disable-next-line: param-type-mismatch
			sm.particle.createParticle("p_firework_finale", self.shape.worldPosition + self.shape.at * 15, sm.vec3.getRotation(-self.shape.right, self.shape.up))
			self.fireworkStepCounter = 1
			self.musicLoopFixTimer = sm.game.getCurrentTick() + G_fireworkTimings[1]
			self.audioEffect:start()
		end
		-- Fire the launchers
		--print("Firework in T-" .. (self.musicSyncTimer - sm.game.getCurrentTick()))
		if sm.game.getCurrentTick() == self.musicSyncTimer then
			self.network:sendToServer("sv_launchFirework")
			self.fireworkStepCounter = self.fireworkStepCounter + 1
			if self.fireworkStepCounter > #G_fireworkTimings then
				self.fireworkStepCounter = 1
			end
			self.musicSyncTimer = sm.game.getCurrentTick() + G_fireworkTimings[self.fireworkStepCounter]
		end
	else
		-- Hide launchers
		local posL = self.shape.worldPosition + (-self.shape.right * 1.9 - self.shape.up * 0.5 + self.shape.at * 0.14)
		local posR = self.shape.worldPosition + (self.shape.right * 1.9 - self.shape.up * 0.5 + self.shape.at * 0.14)
		if self.launcherEffectLeft:isPlaying() then
			self.launcherEffectLeft:stopImmediate()
			self.launcherEffectLeftClose:setOffsetPosition(-self.shape.right * 1.9 - self.shape.up * 0.15 - self.shape.at * 0.589)
			self.launcherEffectLeftClose:setOffsetRotation(sm.vec3.getRotation(self.shape.at, self.shape.up))
			self.launcherEffectLeftClose:start()
		end
		if self.launcherEffectRight:isPlaying() then
			self.launcherEffectRight:stopImmediate()
			self.launcherEffectRightClose:setOffsetPosition(self.shape.right * 1.9 - self.shape.up * 0.15 - self.shape.at * 0.589)
			self.launcherEffectRightClose:setOffsetRotation(sm.vec3.getRotation(self.shape.at, self.shape.up))
			self.launcherEffectRightClose:start()
		end
	end
end

function CelebrationBot.cl_createParticle(self, params)
	sm.particle.createParticle(params.name, params.pos, params.rot or nil, params.color or nil)
end

function CelebrationBot.start_animation(self, animationName, frames, at)
	if self.currentAnimation ~= nil then
		self.interactable:setAnimEnabled(self.currentAnimation, false)
	end

	if frames == 0 then
		frames = 30.0
	end

	self.currentAnimation = animationName
	self.animationSpeed = 30.0 / frames
	self.animationProgress = at or 0.0
	self.interactable:setAnimEnabled(self.currentAnimation, true)
	self.interactable:setAnimProgress(self.currentAnimation, self.animationProgress)
end

function CelebrationBot.update_animation(self, dt)
	if self.currentAnimation ~= nil then
		self.animationProgress = self.animationProgress + dt * self.animationSpeed
		if self.animationProgress < 0.0 then
			self.animationProgress = 0
		end
		self.interactable:setAnimProgress(self.currentAnimation, self.animationProgress)
	end
end