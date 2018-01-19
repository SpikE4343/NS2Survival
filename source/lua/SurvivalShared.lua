if Server then
     Script.Load("lua/Server.lua")
elseif Client then
    Script.Load("lua/Client.lua")
else if Predict then
    Script.Load("lua/Predict.lua")
end

Script.Load("lua/Class.lua")


Script.Load("lua/weapon/FlameShotgun.lua")
