
if Server then

    local kEaseInWaves = 6

    Script.Load("lua/bots/Bot.lua")

    SurvivalUnitMixin = CreateMixin(SurvivalUnitMixin)
    SurvivalUnitMixin.type = "SurvivalUnit"
    
    SurvivalUnitMixin.overrideFunctions =
    {
        "GetIsAllowedToBuy",
        "GetUnitNameOverride"
    }    
    

    SurvivalUnitMixin.networkVars =
    {
        wave = "integer"
    }
    
    function SurvivalUnitMixin:__initmixin()

        self.wave=1
    
    end       
    
    function SurvivalUnitMixin:GetIsAllowedToBuy()
        return false   
    end 
    
    function SurvivalUnitMixin:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint)
    
        local multiplier = kEaseInWaves/self.wave
    
        -- if self:isa("Skulk") then
        --     multiplier = 6
    
        -- elseif self:isa("Fade") then        
        --     multiplier = 12

        -- elseif self:isa("Onos") then
        --     multiplier = 14
        -- end
    
        if multiplier < 0.01 then 
            multiplier = 0.01
        end

        damageTable.damage = damageTable.damage * multiplier
        
    end

    -- --- DoorMixin
    function SurvivalUnitMixin:OnOverrideDoorInteraction(inEntity)

        -- can't open survival doors, must break them down
        if inEntity:isa("SurvivalDoor") then 
            return false, 0
        end

        if self:GetVelocityLength() > 8 then
            return true, 10
        end

        return true, 6
    end

    function SurvivalUnitMixin:OnUpdate(deltaTime)

        if not self:GetIsAlive() then
            return
        end

        -- generate moves for the hallucination server side
        if not self.brain then

            if self:isa("Skulk") then
                self.brain = SkulkBrain()
            
            elseif self:isa("Gorge") then
                self.brain = GorgeBrain()

            elseif self:isa("Lerk") then
                self.brain = LerkBrain()

            elseif self:isa("Fade") then
                self.brain = FadeBrain()
                
            elseif self:isa("Onos") then
                self.brain = OnosBrain()
            end
            
            self.brain:Initialize()
            
        end
        
        local move = Move()
        self:GetMotion():SetDesiredViewTarget(nil)
        self.brain:Update(self, move)
        
        local viewDir, moveDir, doJump = self:GetMotion():OnGenerateMove(self)

        move.yaw = GetYawFromVector(viewDir) - self:GetBaseViewAngles().yaw
        move.pitch = GetPitchFromVector(viewDir)

        moveDir.y = 0
        moveDir = moveDir:GetUnit()
        local zAxis = Vector(viewDir.x, 0, viewDir.z):GetUnit()
        local xAxis = zAxis:CrossProduct(Vector(0, -1, 0))
        local moveX = moveDir:DotProduct(xAxis)
        local moveZ = moveDir:DotProduct(zAxis)
        
        if moveX ~= 0 then
            moveX = GetSign(moveX)
        end
        
        if moveZ ~= 0 then
            moveZ = GetSign(moveZ)
        end
        
        move.move = Vector(moveX, 0, moveZ)

        if doJump then
            move.commands = AddMoveCommand(move.commands, Move.Jump)
        end
        
        move.time = deltaTime

        -- do with that move now what a real player would do
        self:OnProcessMove(move)
        
        --UpdateHallucinationLifeTime(self)

    end

    function SurvivalUnitMixin:SetSpawnWave(wave)
        self.wave = wave
    end

    function SurvivalUnitMixin:GetSpawnWave()
        return self.wave
    end

    
    function SurvivalUnitMixin:GetPlayer()
        return self
    end

    function SurvivalUnitMixin:GetUnitNameOverride(viewer)

        return self.brain:GetExpectedPlayerClass() .. " #" .. self.wave
        
    end    

    --Copy for the botbrain essential methods from the playerbot metatable
    SurvivalUnitMixin.GetMotion = PlayerBot.GetMotion
    SurvivalUnitMixin.GetPlayerOrder = PlayerBot.GetPlayerOrder
    SurvivalUnitMixin.GivePlayerOrder = PlayerBot.GivePlayerOrder
    SurvivalUnitMixin.GetPlayerHasOrder = PlayerBot.GetPlayerHasOrder
    SurvivalUnitMixin.GetBotCanSeeTarget = PlayerBot.GetBotCanSeeTarget

end