

function Shotgun:ApplyBulletGameplayEffects(player, hitEnt, impactPoint, direction, damage, surface, showTracer)
    -- ignite if possible
    if HasMixin(hitEnt, "Fire") then
        hitEnt:SetOnFire(player, self)
    end
end
