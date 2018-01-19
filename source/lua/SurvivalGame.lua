
Script.Load("lua/UtilityShared.lua")
Script.Load("lua/Entity.lua")
Script.Load("lua/Onos.lua")
Script.Load("lua/Skulk.lua")
Script.Load("lua/Gorge.lua")
Script.Load("lua/Lerk.lua")
Script.Load("lua/Fade.lua")
Script.Load("lua/SurvivalUnitMixin.lua")
Script.Load("lua/DamageTypes.lua")

class 'SurvivalGame'

local kState = enum({'Initial', 'StartUp', 'SpawnWait', 'Spawning', 'Complete'})

local kSpawnInterval = 60
local kMinSpawnInterval = 10
local kSpawnIntervalStep = 5

function SurvivalGame:Init(startEntity, targetEntity)

    Print(string.format("SurvivalGame:Init"))

    self.state = kState.Initial
    self.start = startEntity
    self.target = targetEntity
    self.waves = 0
    self.spawnInterval = kSpawnInterval
    self.lastSpawn = 0
    self.startTime = 0
    self.completeTime = -1

    self.waveSpawn = {
        {
            wave = 1,
            units = {
                { type = Skulk.kMapName, baseCount = 10 },
                { type = Gorge.kMapName, baseCount = 4 },
            }
        },
        {
            wave = 3,
            units={
                { type = Skulk.kMapName, baseCount = 10 },
                { type = Gorge.kMapName, baseCount = 4 },
                { type = Lerk.kMapName, baseCount = 2 },
                { type = Fade.kMapName, baseCount = 2 }
            }
        },

        {
            wave = 6,
            units={
                { type = Onos.kMapName, baseCount = 1 },
                { type = Skulk.kMapName, baseCount = 10 },
                { type = Gorge.kMapName, baseCount = 4 },
                { type = Lerk.kMapName, baseCount = 2 },
                { type = Fade.kMapName, baseCount = 2 }
            }
        },
        
        {
            wave = 10,
            units={
                { type = Onos.kMapName, baseCount = 2 },
                { type = Skulk.kMapName, baseCount = 10 },
                { type = Gorge.kMapName, baseCount = 4 },
                { type = Lerk.kMapName, baseCount = 2 },
                { type = Fade.kMapName, baseCount = 2 }
            }
        }
    }
end

function SurvivalGame:Update()
    self:UpdateState()
end

function SurvivalGame:UpdateState()

    local now = Shared.GetTime()
    --Print(string.format("SurvivalGame:UpdateState (%s,%d)",self.state, now))
    if self.state == kState.Initial then

        if self.target and self.start and GetGameInfoEntity():GetGameStarted() and not GetGameInfoEntity():GetWarmUpActive() then
            self.state = kState.StartUp
        end
    elseif self.state == kState.StartUp then
        self.state = kState.SpawnWait
        self.waves = 0
        self.lastSpawn = now
        self.startTime = now

    elseif self.state == kState.SpawnWait then
        if now >= (self.lastSpawn + self.spawnInterval)then
            self.state = kState.Spawning
        end         
    elseif self.state == kState.Spawning then

        Shared.Message( string.format("Spawning wave: %d", self.waves ))

        -- spawn next wave      
        self.waves = self:SpawnWave(self.waves + 1  )
        
        self.lastSpawn = now
        
        self.spawnInterval = self.spawnInterval - kSpawnIntervalStep
        if self.spawnInterval < kMinSpawnInterval then
            self.spawnInterval = kMinSpawnInterval
        end

        self.state = kState.SpawnWait

        --TODO: cap max entity count??

        -- game is complete
        -- if self.waves <= 0 then
        --     self.state = kState.Complete
        -- else
        --     self.state = kState.SpawnWait
        -- end
    elseif self.state == kState.Complete then

        Print(string.format("Survival Complete"))
        Shared.Message( string.format("Survival Complete"))
        -- TODO: allow reset
        self.completeTime = now
    end

end

function SurvivalGame:WaveSpawnUnits(wave)
    local spawndata = nil
    for id,data in ipairs(self.waveSpawn) do
        if spawndata == nil or data.wave <= wave then
            spawndata = data.units
        end
    end

    return spawndata
end

-- spawn a wave of units
function SurvivalGame:SpawnWave(wave)

    local spawndata = self:WaveSpawnUnits(wave)

    if spawndata == nil then
        return 0
    end

    for id,spawn in ipairs(spawndata) do
        Print(string.format("Spawning type: %s, count: %d", spawn.type, spawn.baseCount))
        for i=1,spawn.baseCount do
            local unit = self:SpawnUnit(spawn.type)

            InitMixin(unit, OrdersMixin, { kMoveOrderCompleteDistance = kPlayerMoveOrderCompleteDistance })
            InitMixin(unit, PathingMixin)
            InitMixin(unit, SurvivalUnitMixin)

            unit:SetTeamNumber(2)
            unit:SetSpawnWave(wave)
            

            -- attack com chair
            unit:GiveOrder(kTechId.Attack, self.target:GetId(), self.target:GetOrigin(), nil, true, true)
        end

    end

    return wave
end

-- create a single unit
function SurvivalGame:SpawnUnit(type)
    local start = self.start
    local angles = start:GetAngles()
    -- heading only
    angles.pitch = 0
    angles.roll = 0

    local origin = GetGroundAt(start, start:GetOrigin() + Vector(0, .1, 0), PhysicsMask.Movement, EntityFilterOne(start))
    local unit = CreateEntity(type, origin, 2)
    
    unit:SetAngles(angles)   
    
    return unit
end


function SurvivalGame:OnEntityDestroy(entity)

    if self.target ~= nil and entity:GetId() == self.target:GetId() then
        self.state = kState.Complete
    end
    
end