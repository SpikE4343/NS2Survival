
Script.Load("lua/Entity.lua")

class 'SurvivalSpawner' (Entity)

function SurvivalSpawner:SpawnUnit(type)
    local angles = self:GetAngles()
    angles.pitch = 0
    angles.roll = 0
    local origin = GetGroundAt(self, self:GetOrigin() + Vector(0, .1, 0), PhysicsMask.Movement, EntityFilterOne(self))
    
    
    local unit = CreateEntity(type, origin, self:GetTeamNumber())
    unit:SetAngles(angles)   
    unit:GiveOrder(kTechId.Attack, nil, randomDestinations[1], nil, true, true)            
    
end


