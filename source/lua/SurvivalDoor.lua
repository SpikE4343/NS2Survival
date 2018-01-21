
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/MapBlipMixin.lua")

class 'SurvivalDoor' (ScriptActor)

SurvivalDoor.kMapName = "survival_door"

SurvivalDoor.kInoperableSound = PrecacheAsset("sound/NS2.fev/common/door_inoperable")
SurvivalDoor.kOpenSound = PrecacheAsset("sound/NS2.fev/common/door_open")
SurvivalDoor.kCloseSound = PrecacheAsset("sound/NS2.fev/common/door_close")
SurvivalDoor.kLockSound = PrecacheAsset("sound/NS2.fev/common/door_lock")
SurvivalDoor.kUnlockSound = PrecacheAsset("sound/NS2.fev/common/door_unlock")

SurvivalDoor.kState = enum( {'Open', 'Close', 'Locked', 'DestroyedFront', 'DestroyedBack', 'Welded'} )
SurvivalDoor.kStateSound = { [SurvivalDoor.kState.Open] = SurvivalDoor.kOpenSound, 
                     [SurvivalDoor.kState.Close] = SurvivalDoor.kCloseSound, 
                     [SurvivalDoor.kState.Locked] = SurvivalDoor.kLockSound,
                     [SurvivalDoor.kState.DestroyedFront] = "", 
                     [SurvivalDoor.kState.DestroyedBack] = "", 
                     [SurvivalDoor.kState.Welded] = SurvivalDoor.kLockSound,  }

local kUpdateAutoUnlockRate = 1
local kUpdateAutoOpenRate = 0.3
local kWeldPercentagePerSecond = 1 / kDoorWeldTime
local kHealthPercentagePerSecond = 0.9 / kDoorWeldTime

local kModelNameDefault = PrecacheAsset("models/misc/door/Door.model")
local kModelNameClean = PrecacheAsset("models/misc/door/door_clean.model")
local kModelNameDestroyed = PrecacheAsset("models/misc/door/door_destroyed.model")

local kDoorAnimationGraph = PrecacheAsset("models/misc/door/Door.animation_graph")

local networkVars =
{
    weldedPercentage = "float",
    
    -- Stores current state (kState )
    state = "enum SurvivalDoor.kState",
    damageFrontPose = "float (0 to 100 by 0.1)",
    damageBackPose = "float (0 to 100 by 0.1)"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)

local kDoorLockTimeout = 6
local kDoorLockDuration = 4

local function UpdateAutoUnlock(self, timePassed)

    -- auto open the door after kDoorLockDuration time has passed
    local state = self:GetState()

    if state == SurvivalDoor.kState.Locked and self.timeLastLockTrigger + kDoorLockDuration < Shared.GetTime() then

        self:SetState(SurvivalDoor.kState.Open)
        self.lockTimeOut = Shared.GetTime() + kDoorLockTimeout
        
    end
    
    return true

end

local function UpdateAutoOpen(self, timePassed)

    -- If any players are around, have door open if possible, otherwise close it
    local state = self:GetState()
    
    if state == SurvivalDoor.kState.Open or state == SurvivalDoor.kState.Close then
    
        local desiredOpenState = false

        local entities = Shared.GetEntitiesWithTagInRange("SurvivalDoor", self:GetOrigin(), DoorMixin.kMaxOpenDistance)
        for index = 1, #entities do
            
            local entity = entities[index]
            local opensForEntity, openDistance = entity:GetCanDoorInteract(self)
			
            if opensForEntity then
            
                local distSquared = self:GetDistanceSquared(entity)
                if (not HasMixin(entity, "Live") or entity:GetIsAlive()) and entity:GetIsVisible() and distSquared < (openDistance * openDistance) then
                
                    desiredOpenState = true
                    break
                
                end
            
            end
            
        end
        
        if desiredOpenState and self:GetState() == SurvivalDoor.kState.Close then
            self:SetState(SurvivalDoor.kState.Open)
        elseif not desiredOpenState and self:GetState() == SurvivalDoor.kState.Open then
            self:SetState(SurvivalDoor.kState.Close)  
        end
        
    end
    
    return true

end

local function InitModel(self)

    local modelName = kModelNameDefault
    if self.clean then
        modelName = kModelNameClean
    end
    
    self:SetModel(modelName, kDoorAnimationGraph)
    
end

function SurvivalDoor:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, PathingMixin)
    
    if Server then
    
        self:AddTimedCallback(UpdateAutoUnlock, kUpdateAutoUnlockRate)
        self:AddTimedCallback(UpdateAutoOpen, kUpdateAutoOpenRate)
        
    end
    
    self.state = SurvivalDoor.kState.Open

    
end



function SurvivalDoor:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    if Server then
        
        InitModel(self)
        
        self:SetPhysicsType(PhysicsType.Kinematic)
        
        self:SetPhysicsGroup(PhysicsGroup.CommanderUnitGroup)
        
        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    end

    
end

function SurvivalDoor:Reset()
    
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(0)
    
    self:SetState(SurvivalDoor.kState.Close)
    
    InitModel(self)
    
end

function SurvivalDoor:GetShowHealthFor(player)
    return true
end

function SurvivalDoor:GetReceivesStructuralDamage()
    return true
end

function SurvivalDoor:GetIsWeldedShut()
    return self:GetState() == SurvivalDoor.kState.Welded
end

function SurvivalDoor:GetDescription()

    local doorName = GetDisplayNameForTechId(self:GetTechId())
    local doorDescription = doorName
    
    local state = self:GetState()
    
    if state == SurvivalDoor.kState.Welded then
        doorDescription = string.format("Welded %s", doorName)
    end
    
    return doorDescription
    
end

function SurvivalDoor:SetState(state, commander)

    if self.state ~= state then
    
        self.state = state
        
        if Server then
        
            local sound = SurvivalDoor.kStateSound[self.state]
            if sound ~= "" then
            
                self:PlaySound(sound)
                
                if commander ~= nil then
                    Server.PlayPrivateSound(commander, sound, nil, 1.0, commander:GetOrigin())
                end
                
            end
            
        end
        
    end
    
end

function SurvivalDoor:GetState()
    return self.state
end

function SurvivalDoor:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

function SurvivalDoor:OnUpdateAnimationInput(modelMixin)

    PROFILE("SurvivalDoor:OnUpdateAnimationInput")
    
    local open = self.state == SurvivalDoor.kState.Open
    local lock = self.state == SurvivalDoor.kState.Locked or self.state == SurvivalDoor.kState.Welded
    
    modelMixin:SetAnimationInput("open", open)
    modelMixin:SetAnimationInput("lock", lock)
    
end

Shared.LinkClassToMap("SurvivalDoor", SurvivalDoor.kMapName, networkVars)