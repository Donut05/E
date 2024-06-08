---@diagnostic disable: need-check-nil

RadialMenu = class(nil)

function RadialMenu.cl_calculateAngles(self, center, vertexCount)
    local radius = 1
    local vertices = {}

    for i = 1, vertexCount do
        local angle = (i - 1) * (360 / vertexCount)
        local radianAngle = math.rad(angle)

        -- Calculate vertex position in local coordinates
        local localPosition = sm.vec3.new(radius * math.cos(radianAngle), radius * math.sin(radianAngle), 0)

        -- Transform local position to world coordinates
        local worldPosition = center + localPosition

        -- Calculate the direction towards the center
        local direction = (center - worldPosition):normalize()

        -- Rotate direction to match the specified 'upDirection'
        local rotation = sm.vec3.getRotation(sm.vec3.new(0, 0, 1), direction)

        -- Store the vertex information in a table
        table.insert(vertices, {
            pos = worldPosition,
            rot = rotation
        })
    end

    for j, vertex in ipairs(vertices) do
        self.wheelLines[j] = sm.effect.createEffect("ShapeRenderable")
        self.wheelLines[j]:setParameter("uuid", sm.uuid.new("628b2d61-5ceb-43e9-8334-a4135566df7a"))
        self.wheelLines[j]:setParameter("color", sm.color.new("CCCCCC"))
        self.wheelLines[j]:setPosition(vertex.pos)
        self.wheelLines[j]:setRotation(vertex.rot)
        self.wheelLines[j]:setScale(sm.vec3.new(0.01, 0.5, 0.01))
    end

    return vertices
end

function RadialMenu.cl_setUpItems(self, itemCount)
    local effectsTable = {}
    for j = 1, itemCount do
        effectsTable[j] = sm.effect.createEffect("ShapeRenderable")
        if j == 1 then
            effectsTable[j]:setParameter("uuid", sm.uuid.new("80bc2b9f-98a9-44e4-9cb8-d4ec7e95b40f"))
            effectsTable[j]:setParameter("color", sm.color.new("ffd504"))
        elseif j == 2 then
            effectsTable[j]:setParameter("uuid", sm.uuid.new("ca003562-fde7-463c-969e-f8334ae54387"))
            effectsTable[j]:setParameter("color", sm.color.new("CCCCCC"))
        else
            effectsTable[j]:setParameter("uuid", sm.uuid.new("1325d152-3dd1-41a1-9027-5823c5cb55c4"))
            effectsTable[j]:setParameter("color", sm.color.new("3e9ffe"))
        end
        effectsTable[j]:setPosition(sm.vec3.zero())
        effectsTable[j]:setScale(sm.vec3.new(1, 1, 1))
        effectsTable[j]:setRotation(sm.camera.getRotation() * sm.vec3.getRotation(sm.vec3.new(0, 0, -1), sm.vec3.new(0, 1, 0)))
    end

    return effectsTable
end

function RadialMenu.client_onCreate(self)
    print("test")
    local itemCount = 3
    self.wheelLines = {}
    for i = 1, itemCount do
        self.wheelLines[i] = sm.effect.createEffect("ShapeRenderable")
        self.wheelLines[i]:setParameter("uuid", sm.uuid.new("628b2d61-5ceb-43e9-8334-a4135566df7a"))
        self.wheelLines[i]:setParameter("color", sm.color.new("CCCCCC"))
        self.wheelLines[i]:setScale(sm.vec3.new(0.01, 0.01, 0.5))
    end
    --self.itemRenderables = self:cl_setUpItems(itemCount)
    self.hasPlayer = false
    for _, effect in ipairs(self.wheelLines) do
        if not effect:isPlaying() then
            effect:start()
        end
    end--[[
    for _, effect in ipairs(self.itemRenderables) do
        if effect:isPlaying() then
            effect:stopImmediate()
        end
    end]]
end

function RadialMenu.client_onFixedUpdate(self, dt)
    for i, effect in ipairs(self.wheelLines) do
        local g_halfPi = math.pi / 2
        local function calculateRightVector(dir)
            ---@diagnostic disable-next-line: deprecated
            local v_angle = math.atan2(dir.y, dir.x) - g_halfPi
            return sm.vec3.new(math.cos(v_angle), math.sin(v_angle), 0)
        end
        local v_some_vector = sm.camera.getDirection()
        local v_right_vector = calculateRightVector(v_some_vector)
        local v_up_vector = v_some_vector:cross(v_right_vector):safeNormalize(sm.vec3.new(0, 0, 1))
        local rotation = sm.vec3.getRotation(sm.vec3.new(0, 0, 1), v_up_vector)
        local angle = (i - 1) * (360 / #self.wheelLines)
        local rotation2 = sm.quat.angleAxis(angle, sm.camera.getDirection():normalize())
        effect:setRotation(rotation * rotation2)

        local v_cur_angle = (i / #self.wheelLines) * (math.pi * 2)
        local v_line_begin = sm.camera.getPosition() + sm.camera.getDirection() / 2
        local v_right_offset = v_right_vector * math.cos(v_cur_angle) / 4
        local v_up_offset = v_up_vector * math.sin(v_cur_angle) / 4
        local v_final_pos = v_line_begin + v_right_offset + v_up_offset
        effect:setPosition(v_final_pos)
    end
end

function RadialMenu.client_onInteract(self, character, state)
    if not state then return end
    self.hasPlayer = not self.hasPlayer
end

function RadialMenu.client_onDestroy(self)
    for _, effect in ipairs(self.wheelLines) do
        if effect:isPlaying() then
            effect:stopImmediate()
        end
    end--[[
    for _, effect in ipairs(self.itemRenderables) do
        if effect:isPlaying() then
            effect:stopImmediate()
        end
    end]]
end

function RadialMenu.client_onRefresh(self)
    for _, effect in ipairs(self.wheelLines) do
        if effect:isPlaying() then
            effect:stopImmediate()
        end
    end
    --[[
    for _, effect in ipairs(self.itemRenderables) do
        if effect:isPlaying() then
            effect:stopImmediate()
        end
    end]]
    self:client_onCreate()
end