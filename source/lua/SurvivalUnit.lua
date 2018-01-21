
Script.Load("lua/ScriptActor.lua")

Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/RepositioningMixin.lua")
Script.Load("lua/SoftTargetMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")

PrecacheAsset("cinematics/vfx_materials/SurvivalUnit.surface_shader")
local kSurvivalUnitMaterial = PrecacheAsset( "cinematics/vfx_materials/SurvivalUnit.material")

class 'SurvivalUnit' (ScriptActor)

SurvivalUnit.kMapName = "SurvivalUnit"

SurvivalUnit.kSpotRange = 15
SurvivalUnit.kTurnSpeed  = 4 * math.pi
SurvivalUnit.kDefaultMaxSpeed = 1

local networkVars =
{
    wave = "integer",
    assignedTechId = "enum kTechId",
    moving = "boolean",
    attacking = "boolean",
    SurvivalUnitIsVisible = "boolean",
    creationTime = "time"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)

local gTechIdAttacking
local function GetTechIdAttacks(techId)
    
    if not gTechIdAttacking then
        gTechIdAttacking = {}
        gTechIdAttacking[kTechId.Skulk] = true
        gTechIdAttacking[kTechId.Gorge] = true
        gTechIdAttacking[kTechId.Lerk] = true
        gTechIdAttacking[kTechId.Fade] = true
        gTechIdAttacking[kTechId.Onos] = true
    end
    
    return gTechIdAttacking[techId]
    
end

local ghallucinateIdToTechId
function GetTechIdToEmulate(techId)

    if not ghallucinateIdToTechId then
    
        ghallucinateIdToTechId = {}
        ghallucinateIdToTechId[kTechId.HallucinateDrifter] = kTechId.Drifter
        ghallucinateIdToTechId[kTechId.HallucinateSkulk] = kTechId.Skulk
        ghallucinateIdToTechId[kTechId.HallucinateGorge] = kTechId.Gorge
        ghallucinateIdToTechId[kTechId.HallucinateLerk] = kTechId.Lerk
        ghallucinateIdToTechId[kTechId.HallucinateFade] = kTechId.Fade
        ghallucinateIdToTechId[kTechId.HallucinateOnos] = kTechId.Onos
        
        ghallucinateIdToTechId[kTechId.HallucinateHive] = kTechId.Hive
        ghallucinateIdToTechId[kTechId.HallucinateWhip] = kTechId.Whip
        ghallucinateIdToTechId[kTechId.HallucinateShade] = kTechId.Shade
        ghallucinateIdToTechId[kTechId.HallucinateCrag] = kTechId.Crag
        ghallucinateIdToTechId[kTechId.HallucinateShift] = kTechId.Shift
        ghallucinateIdToTechId[kTechId.HallucinateHarvester] = kTechId.Harvester
        ghallucinateIdToTechId[kTechId.HallucinateHydra] = kTechId.Hydra
    
    end
    
    return ghallucinateIdToTechId[techId]

end

local gTechIdCanMove
local function GetSurvivalUnitCanMove(techId)

    if not gTechIdCanMove then
        gTechIdCanMove = {}
        gTechIdCanMove[kTechId.Skulk] = true
        gTechIdCanMove[kTechId.Gorge] = true
        gTechIdCanMove[kTechId.Lerk] = true
        gTechIdCanMove[kTechId.Fade] = true
        gTechIdCanMove[kTechId.Onos] = true
        
        gTechIdCanMove[kTechId.Drifter] = true
        gTechIdCanMove[kTechId.Whip] = true
    end 
       
    return gTechIdCanMove[techId]

end

local gTechIdCanBuild
local function GetSurvivalUnitCanBuild(techId)

    if not gTechIdCanBuild then
        gTechIdCanBuild = {}
        gTechIdCanBuild[kTechId.Gorge] = true
    end 
       
    return gTechIdCanBuild[techId]

end

local function GetEmulatedClassName(techId)
    return EnumToString(kTechId, techId)
end

-- model graphs should already be precached elsewhere
local gTechIdAnimationGraph
local function GetAnimationGraph(techId)

    if not gTechIdAnimationGraph then
        gTechIdAnimationGraph = {}
        gTechIdAnimationGraph[kTechId.Skulk] = "models/alien/skulk/skulk.animation_graph"
        gTechIdAnimationGraph[kTechId.Gorge] = "models/alien/gorge/gorge.animation_graph"
        gTechIdAnimationGraph[kTechId.Lerk] = "models/alien/lerk/lerk.animation_graph"
        gTechIdAnimationGraph[kTechId.Fade] = "models/alien/fade/fade.animation_graph"         
        gTechIdAnimationGraph[kTechId.Onos] = "models/alien/onos/onos.animation_graph"
        gTechIdAnimationGraph[kTechId.Drifter] = "models/alien/drifter/drifter.animation_graph"  
        
        gTechIdAnimationGraph[kTechId.Hive] = "models/alien/hive/hive.animation_graph"
        gTechIdAnimationGraph[kTechId.Whip] = "models/alien/whip/whip.animation_graph"
        gTechIdAnimationGraph[kTechId.Shade] = "models/alien/shade/shade.animation_graph"
        gTechIdAnimationGraph[kTechId.Crag] = "models/alien/crag/crag.animation_graph"
        gTechIdAnimationGraph[kTechId.Shift] = "models/alien/shift/shift.animation_graph"
        gTechIdAnimationGraph[kTechId.Harvester] = "models/alien/harvester/harvester.animation_graph"
        gTechIdAnimationGraph[kTechId.Hydra] = "models/alien/hydra/hydra.animation_graph"
        
    end
    
    return gTechIdAnimationGraph[techId]

end

local gTechIdMaxMovementSpeed
local function GetMaxMovementSpeed(techId)

    if not gTechIdMaxMovementSpeed then
        gTechIdMaxMovementSpeed = {}
        gTechIdMaxMovementSpeed[kTechId.Skulk] = 8
        gTechIdMaxMovementSpeed[kTechId.Gorge] = 5.1
        gTechIdMaxMovementSpeed[kTechId.Lerk] = 9
        gTechIdMaxMovementSpeed[kTechId.Fade] = 7
        gTechIdMaxMovementSpeed[kTechId.Onos] = 7
        
        gTechIdMaxMovementSpeed[kTechId.Drifter] = 11
        gTechIdMaxMovementSpeed[kTechId.Whip] = 4
    
    end
    
    local moveSpeed = gTechIdMaxMovementSpeed[techId]
    
    return ConditionalValue(moveSpeed == nil, SurvivalUnit.kDefaultMaxSpeed, moveSpeed)

end

local gTechIdMoveState
local function GetMoveName(techId)

    if not gTechIdMoveState then
        gTechIdMoveState = {}
        gTechIdMoveState[kTechId.Lerk] = "fly"
    
    end
    
    local moveState = gTechIdMoveState[techId]
    
    return ConditionalValue(moveState == nil, "run", moveState)

end

local function SetAssignedAttributes(self, survivalUnitTechId)

    -- could be a cleaner way to scale units than reducing damage taken
    local model = LookupTechData(self.assignedTechId, kTechDataModel, Skulk.kModelName)
    local health = math.min(LookupTechData(self.assignedTechId, kTechDataMaxHealth, kSkulkHealth) )-- * kSurvivalUnitHealthFraction, kSurvivalUnitMaxHealth)
    local armor = LookupTechData(self.assignedTechId, kTechDataMaxArmor, kSkulkArmor) -- * kSurvivalUnitArmorFraction
    
    self.maxSpeed = GetMaxMovementSpeed(self.assignedTechId)    
    self:SetModel(model, GetAnimationGraph(self.assignedTechId))
    self:SetMaxHealth(health)
    self:SetHealth(health)
    self:SetMaxArmor(armor)
    self:SetArmor(armor)
    
    if self.assignedTechId == kTechId.Hive then
    
        local attachedTechPoint = self:GetAttached()
        if attachedTechPoint then
            attachedTechPoint:SetIsSmashed(true)
        end
    
    end
    
end

function SurvivalUnit:SetSpawnWave(wave)
    self.wave = wave
end

function SurvivalUnit:GetSpawnWave()
    return self.wave
end

function SurvivalUnit:OnCreate()
    
    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, DoorMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, PathingMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, SoftTargetMixin)
    InitMixin(self, CameraHolderMixin, { kFov = kDefaultFov })
    
    if Server then
    
        self.wave = 0
        self.SurvivalUnitIsVisible = true
        self.attacking = false
        self.moving = false
        self.assignedTechId = kTechId.Skulk
        self.brain = nil

        InitMixin(self, SleeperMixin)
        
    end

end

function SurvivalUnit:OnInitialized()
    
    ScriptActor.OnInitialized(self)

    if Server then
    
        SetAssignedAttributes(self, kTechId.HallucinateSkulk)

        InitMixin(self, RepositioningMixin)

        self:SetPhysicsType(PhysicsType.Kinematic)
        
        InitMixin(self, MobileTargetMixin)
    
    end
    
    self:SetUpdates(true)
    
    self:SetPhysicsGroup(PhysicsGroup.SmallStructuresGroup)
    
end

function SurvivalUnit:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    
    if Client then
    
        if self.SurvivalUnitMaterial then
        
            Client.DestroyRenderMaterial(self.SurvivalUnitMaterial)
            self.SurvivalUnitMaterial = nil
            
        end
    
    end

end

function SurvivalUnit:GetIsFlying()
    return self.assignedTechId == kTechId.Drifter
end

function SurvivalUnit:GetAssignedTechId()
    return self.assignedTechId
end    

function SurvivalUnit:SetEmulation(survivalUnitTechId)

    self.assignedTechId = survivalUnitTechId
    SetAssignedAttributes(self, survivalUnitTechId)
    
        
    if not HasMixin(self, "MapBlip") then
        InitMixin(self, MapBlipMixin)
    end

end

function SurvivalUnit:GetMaxSpeed()
    if self.assignedTechId == kTechId.Fade and not self.SurvivalUnitIsVisible then
        return self.maxSpeed * 2
    end

    return self.maxSpeed
end

--[[
function SurvivalUnit:GetSurfaceOverride()
    return "SurvivalUnit"
end
--]]

function SurvivalUnit:GetCanReposition()
    return GetSurvivalUnitCanMove(self.assignedTechId)
end
 
function SurvivalUnit:OverrideGetRepositioningTime()
    return 0.4
end    

function SurvivalUnit:OverrideRepositioningSpeed()
    return self.maxSpeed * 0.8
end

function SurvivalUnit:OverrideRepositioningDistance()
    if self.assignedTechId == kTechId.Onos then
        return 4
    end
    
    return 1.5
end

function SurvivalUnit:GetCanSleep()
    return self:GetCurrentOrder() == nil    
end

function SurvivalUnit:GetTurnSpeedOverride()
    return SurvivalUnit.kTurnSpeed
end

function SurvivalUnit:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)
    
    if Server then
        self:UpdateServer(deltaTime)
    elseif Client then
        self:UpdateClient(deltaTime)
    end    
    
    self.moveSpeed = 1
    
    self:SetPoseParam("move_yaw", 90)
    self:SetPoseParam("move_speed", self.moveSpeed)

end

function SurvivalUnit:OnOverrideDoorInteraction(inEntity)   
    return true, 4
end

function SurvivalUnit:PerformActivation(techId, position, normal, commander)

    return false, true
    
end

function SurvivalUnit:GetIsMoving()
    return self.moving
end

function SurvivalUnit:GetTechButtons(techId)

    return {  }
    
end

local function OnUpdateAnimationInputCustom(self, techId, modelMixin, moveState)

    if techId == kTechId.Lerk then
        modelMixin:SetAnimationInput("flapping", self:GetIsMoving())
    elseif techId == kTechId.Fade and not self.SurvivalUnitIsVisible then
        modelMixin:SetAnimationInput("move", "blink")
    end

end

function SurvivalUnit:OnUpdateAnimationInput(modelMixin)

    local moveState = "idle"
    
    if self:GetIsMoving() then
        moveState = GetMoveName(self.assignedTechId)
    end

    modelMixin:SetAnimationInput("built", self.assignedTechId == kTechId.Drifter)

    modelMixin:SetAnimationInput("move", moveState) 
    OnUpdateAnimationInputCustom(self, self.assignedTechId, modelMixin, moveState)

end

function SurvivalUnit:GetIsMoveable()
    return true
end

function SurvivalUnit:OnUpdatePoseParameters()
    self:SetPoseParam("grow", 1)    
end

if Server then

    SurvivalUnit.GetMotion = PlayerBot.GetMotion
    SurvivalUnit.GetPlayerOrder = PlayerBot.GetPlayerOrder
    SurvivalUnit.GivePlayerOrder = PlayerBot.GivePlayerOrder
    SurvivalUnit.GetPlayerHasOrder = PlayerBot.GetPlayerHasOrder
    SurvivalUnit.GetBotCanSeeTarget = PlayerBot.GetBotCanSeeTarget

    function SurvivalUnit:GetPlayer()
        return self
    end

    function SurvivalUnit:GetUnitNameOverride(viewer)

        return self.brain:GetExpectedPlayerClass() .. " #" .. self.wave
        
    end    

    function SurvivalUnit:UpdateServer(deltaTime)
    
        if self.timeInvisible and not self.SurvivalUnitIsVisible then
            self.timeInvisible = math.max(self.timeInvisible - deltaTime, 0)
            
            if self.timeInvisible == 0 then
            
                self.SurvivalUnitIsVisible = true
            
            end
            
        end
            
        self:OnUpdateBrain(deltaTime)

        self:UpdateOrders(deltaTime)
    
    end
    
    function SurvivalUnit:GetDestroyOnKill()
        return true
    end

    function SurvivalUnit:OnKill(attacker, doer, point, direction)
    
        ScriptActor.OnKill(self, attacker, doer, point, direction)
        
        self:TriggerEffects("death_SurvivalUnit")
        
    end
    --[[
    function SurvivalUnit:OnScan()
        self:Kill()
    end
    --]]
    function SurvivalUnit:GetHoverHeight()
    
        if self.assignedTechId == kTechId.Lerk or self.assignedTechId == kTechId.Drifter then
            return 1.5   
        else
            return 0
        end    
        
    end
    
    local function PerformSpecialMovement(self)
        
        if self.assignedTechId == kTechId.Fade then
            
            -- blink every now and then
            if not self.nextTimeToBlink then
                self.nextTimeToBlink = Shared.GetTime()
            end    
            
            local distToTarget = (self:GetCurrentOrder():GetLocation() - self:GetOrigin()):GetLengthXZ()
            if self.nextTimeToBlink <= Shared.GetTime() and distToTarget > 17 then -- 17 seems to be a good value as minimum distance to trigger blink

                self.SurvivalUnitIsVisible = false
                self.timeInvisible = 0.5 + math.random() * 2
                self.nextTimeToBlink = Shared.GetTime() + 2 + math.random() * 8
            
            end
            
        end
    
    end
    
    function SurvivalUnit:UpdateMoveOrder(deltaTime)
    
        local currentOrder = self:GetCurrentOrder()
        ASSERT(currentOrder)
        
        self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), self:GetMaxSpeed(), deltaTime)
        
        if self:IsTargetReached(currentOrder:GetLocation(), kAIMoveOrderCompleteDistance) then
            self:CompletedCurrentOrder()
        else
        
            self:SetOrigin(GetHoverAt(self, self:GetOrigin()))
            PerformSpecialMovement(self)
            self.moving = true
            
        end
        
    end
    
    function SurvivalUnit:UpdateAttackOrder(deltaTime)
    
        if not GetTechIdAttacks(self.assignedTechId) then
            self:ClearCurrentOrder()
            return
        end    
        
    end

    
    function SurvivalUnit:UpdateBuildOrder(deltaTime)
    
        local currentOrder = self:GetCurrentOrder()
        local techId = currentOrder:GetParam()
        local engagementDist = LookupTechData(techId, kTechDataEngagementDistance, 0.35)
        local distToTarget = (currentOrder:GetLocation() - self:GetOrigin()):GetLengthXZ()
        
        if (distToTarget < engagementDist) then   
        
            local commander = self:GetOwner()
            if (not commander) then
                self:ClearOrders(true, true)
                return
            end
            
            local techIdToEmulate = GetTechIdToEmulate(techId)
            
            local origin = currentOrder:GetLocation()
            local trace = Shared.TraceRay(Vector(origin.x, origin.y + .1, origin.z), Vector(origin.x, origin.y - .2, origin.z), CollisionRep.Select, PhysicsMask.CommanderBuild, EntityFilterOne(self))
            local legalBuildPosition, position, attachEntity = GetIsBuildLegal(techIdToEmulate, trace.endPoint, 0, 4, self:GetOwner(), self)

            if (not legalBuildPosition) then
                self:ClearOrders()
                return
            end
            
            --[[ deprecated
            local createdSurvivalUnit = CreateEntity(SurvivalUnit.kMapName, position, self:GetTeamNumber())
            if createdSurvivalUnit then
            
                createdSurvivalUnit:SetEmulation(techId)
                
                -- Drifter SurvivalUnits are destroyed when they construct something
                if self.assignedTechId == kTechId.Drifter then
                    self:Kill()
                else
                
                    local costs = LookupTechData(techId, kTechDataCostKey, 0)
                    self:AddEnergy(-costs)
                    self:TriggerEffects("spit_structure")
                    self:CompletedCurrentOrder()
                
                end
                
            else--]]
            
                self:ClearOrders(true, true)
                return
                
            -- end
            
        else
            self:UpdateMoveOrder(deltaTime)
        end
        
    end
    
    function SurvivalUnit:UpdateOrders(deltaTime)
    
        local currentOrder = self:GetCurrentOrder()

        if currentOrder then
        
            if currentOrder:GetType() == kTechId.Move and GetSurvivalUnitCanMove(self.assignedTechId) then
                self:UpdateMoveOrder(deltaTime)
            elseif currentOrder:GetType() == kTechId.Attack then
                self:UpdateAttackOrder(deltaTime)
            elseif currentOrder:GetType() == kTechId.Build and GetSurvivalUnitCanBuild(self.assignedTechId) then
                self:UpdateBuildOrder(deltaTime)
            else
                self:ClearCurrentOrder()
            end
            
        else

            self.moving = false
            self.attacking = false

        end    
    
    end
    
end


function SurvivalUnit:OnUpdateBrain(deltaTime)

    if not self:GetIsAlive() or self.assignedTechId == -1 then
        return
    end

    -- generate moves for the hallucination server side
    if not self.brain then

        if self.assignedTechId == kTechId.Skulk then
            self.brain = SkulkBrain()
        
        elseif self.assignedTechId == kTechId.Gorge then
            self.brain = GorgeBrain()

        elseif self.assignedTechId == kTechId.Lerk then
            self.brain = LerkBrain()

        elseif self.assignedTechId == kTechId.Fade then
            self.brain = FadeBrain()
            
        elseif self.assignedTechId == kTechId.Onos then
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

function SurvivalUnit:GetMaxViewOffsetHeight()
    return 2
end

function SurvivalUnit:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.35, 0)
end

function SurvivalUnit:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

function SurvivalUnit:GetSendDeathMessage()
    return not self.consumed
end

if Client then

    function SurvivalUnit:OnUpdateRender()
    
        PROFILE("SurvivalUnit:OnUpdateRender")
    
        local showMaterial = not GetAreEnemies(self, Client.GetLocalPlayer())
    
        local model = self:GetRenderModel()
        if model then

            model:SetMaterialParameter("glowIntensity", 0)

            if showMaterial then
                
                if not self.SurvivalUnitMaterial then
                    self.SurvivalUnitMaterial = AddMaterial(model, kSurvivalUnitMaterial)
                end
                
                self:SetOpacity(0, "SurvivalUnit")
            
            else
            
                if self.SurvivalUnitMaterial then
                    RemoveMaterial(model, self.SurvivalUnitMaterial)
                    self.SurvivalUnitMaterial = nil
                end
                
                self:SetOpacity(1, "SurvivalUnit")
            
            end
            
        end
    
    end

    function SurvivalUnit:UpdateClient(deltaTime)
    
        if self.clientSurvivalUnitIsVisible == nil then
            self.clientSurvivalUnitIsVisible = self.SurvivalUnitIsVisible
        end    
    
        if self.clientSurvivalUnitIsVisible ~= self.SurvivalUnitIsVisible then
        
            self.clientSurvivalUnitIsVisible = self.SurvivalUnitIsVisible
            if self.SurvivalUnitIsVisible then
                self:OnShow()
            else
                self:OnHide()
            end  
        end
    
        self:SetIsVisible(self.SurvivalUnitIsVisible)
        
        if self:GetIsVisible() and self:GetIsMoving() then
            self:UpdateMoveSound(deltaTime)
        end
    
    end
    
    function SurvivalUnit:UpdateMoveSound(deltaTime)
    
        if not self.timeUntilMoveSound then
            self.timeUntilMoveSound = 0
        end
        
        if self.timeUntilMoveSound == 0 then
        
            local surface = GetSurfaceAndNormalUnderEntity(self)            
            self:TriggerEffects("footstep", {classname = GetEmulatedClassName(self.assignedTechId), surface = surface, left = true, sprinting = false, forward = true, crouch = false})
            self.timeUntilMoveSound = 0.3
            
        else
            self.timeUntilMoveSound = math.max(self.timeUntilMoveSound - deltaTime, 0)     
        end
    
    end
    
    function SurvivalUnit:OnHide()
    
        if self.assignedTechId == kTechId.Fade then
            self:TriggerEffects("blink_out")
        end
    
    end
    
    function SurvivalUnit:OnShow()
    
        if self.assignedTechId == kTechId.Fade then
            self:TriggerEffects("blink_in")
        end
    
    end

end




Shared.LinkClassToMap("SurvivalUnit", SurvivalUnit.kMapName, networkVars)
