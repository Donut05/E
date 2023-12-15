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
	self.confettiEffectLeft = sm.effect.createEffect("CelebrationBot - Confetti", self.interactable, "pejnt_right")
	self.confettiEffectRight = sm.effect.createEffect("CelebrationBot - Confetti", self.interactable, "pejnt_left")
	self.launcherEffectLeft = sm.effect.createEffect("CelebrationBot - Launcher_open", self.interactable)
	self.launcherEffectRight = sm.effect.createEffect("CelebrationBot - Launcher_open", self.interactable)
	self.launcherEffectLeft:setOffsetPosition(self.shape.right - self.shape.at)
	self.launcherEffectRight:setOffsetPosition(-self.shape.right - self.shape.at)
	if sm.cae_injected then
		self.audioEffectSpecial = sm.effect.createEffect("CelebrationBot - Communism", self.interactable)
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
			print("Selected special effect")
			self.specialFlag = true
			self.audioEffect = self.audioEffectSpecial
		else
			print("Selected normal effect")
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

	if self.specialFlag then
		-- Deploy launchers
		if not self.launcherEffectLeft:isPlaying() then
			self.launcherEffectLeft:start()
		end
		if not self.launcherEffectRight:isPlaying() then
			self.launcherEffectRight:start()
		end
		-- Loop the song
		if not self.audioEffect:isPlaying() then
			print("restart")
			self.audioEffect:start()
		end
	else
		-- Hide launchers
		local posL = self.shape.worldPosition + (self.shape.right - self.shape.at)
		local posR = self.shape.worldPosition + (self.shape.right - self.shape.at)
		if self.launcherEffectLeft:isPlaying() then
			self.launcherEffectLeft:stopImmediate()
			sm.particle.createParticle("p_launcher_close", posL)
		end
		if self.launcherEffectRight:isPlaying() then
			self.launcherEffectRight:stopImmediate()
			sm.particle.createParticle("p_launcher_close", posR)
		end
	end
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