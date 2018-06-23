local 	burnableEnemies = 	{ {10, 1} , {208, 0}, {29,0} }
local 	burnedEnemies = 	{ {10, 2} , {208, 2}, {54,0} }


local	meteorMawMaxSpeed = 15

local function Lerp(a, b, weight)
	return a * (1 - weight) + b * weight
end

function BBBaddiesMod:MeteorMaw(npc)
	if (npc.State == 0) then
		npc.GridCollisionClass = 3
		npc.State = 3
	elseif (npc.State == 3) then
		npc:GetSprite():Play("Shake", true)
		npc.State = 4
	elseif (npc.State == 4) then
		local room = Game():GetRoom()
		npc.Target = npc:GetPlayerTarget()
		npc.TargetPosition = npc.Target.Position
		local targetOffset = npc.TargetPosition - npc.Position
		local targetDirection = targetOffset:Normalized()
			
		npc.Velocity = npc.Velocity + (targetDirection * 0.1)
		if (npc.Velocity:Length() > 1.5) then npc.Velocity = npc.Velocity:Normalized() * 1.5 end
		
		if (math.abs(targetOffset.X) < 12 or math.abs(targetOffset.Y) < 12) then
			npc.State = 8
			npc.StateFrame = 0
			npc:GetSprite():Play("Attack")
			npc:PlaySound(146, 1.0, 0, false, 1.0)
			if (math.abs(targetOffset.X) < math.abs(targetOffset.Y)) then
				if (targetOffset.Y < 0) then
					npc.TargetPosition = Vector(0,-1)
				else
					npc.TargetPosition = Vector(0,1)					
				end
			else
				if (targetOffset.X < 0) then
					npc.TargetPosition = Vector(-1,0)
				else
					npc.TargetPosition = Vector(1,0)					
				end
			end
		end
	elseif (npc.State == 8) then
		if (npc.StateFrame == 0) then
			if (npc:GetSprite():IsFinished("Attack")) then
				npc.StateFrame = 1
				npc.Velocity = Lerp(npc.Velocity,npc.TargetPosition * meteorMawMaxSpeed,0.5)
				npc.Mass = 20
				npc.GridCollisionClass = 6
				
				if (math.abs(npc.TargetPosition.X) > math.abs(npc.TargetPosition.Y)) then
					if (npc.TargetPosition.X > 0) then
						npc:GetSprite():Play("ChargeRight")
					else
						npc:GetSprite():Play("ChargeLeft")				
					end
				else
					if (npc.TargetPosition.Y > 0) then
						npc:GetSprite():Play("ChargeDown")
					else
						npc:GetSprite():Play("ChargeUp")				
					end
				end
			end
		elseif (npc.StateFrame == 1) then
			local collided = false
			
			if (math.abs(npc.TargetPosition.X) > math.abs(npc.TargetPosition.Y)) then
				if (npc.TargetPosition.X > 0) then
					if (npc.Velocity.X <= 0) then collided = true end
				else
					if (npc.Velocity.X >= 0) then collided = true end					
				end
			else
				if (npc.TargetPosition.Y > 0) then
					if (npc.Velocity.Y <= 0) then collided = true end
				else
					if (npc.Velocity.Y >= 0) then collided = true end					
				end
			end
			
			
			local impeedingNPCs = Isaac.FindInRadius(npc.Position + (npc.Velocity), 13, EntityPartition.ENEMY)
			for i = 1, #impeedingNPCs do
				if (impeedingNPCs[i].Type == 33) then
					local offset = npc.Position - impeedingNPCs[i].Position
					local boundVector = offset:Normalized()
					npc.Velocity = boundVector * 6
					
					impeedingNPCs[i].HitPoints = 0
					impeedingNPCs[i]:TakeDamage(1, 0, EntityRef(npc), 0)
					
					collided = true
				else					
					for i2 = 1, #burnableEnemies do
						if (impeedingNPCs[i].Type == burnableEnemies[i2][1] and impeedingNPCs[i].Variant == burnableEnemies[i2][2]) then
							BBBaddiesdebugString = "NPC:" .. impeedingNPCs[i].Type .. "." .. impeedingNPCs[i].Variant .. " -> " .. burnedEnemies[i2][1] .. "." .. burnedEnemies[i2][2]
							local otherNPC = impeedingNPCs[i]:ToNPC()
							otherNPC:Morph(burnedEnemies[i2][1], burnedEnemies[i2][2], otherNPC.SubType, otherNPC:GetChampionColorIdx())
						end
					end
				end
			end
			
		
			if (collided) then		
				local room = Game():GetRoom()		
				local gridEntity = room:GetGridEntity(room:GetGridIndex(npc.Position + (npc.TargetPosition * 16)))--room:GetGridEntityFromPos(npc.Position + (npc.TargetPosition * 12))
				if (gridEntity ~= nil and gridEntity:ToRock() ~= nil) then
					gridEntity:Destroy(true)
					npc:TakeDamage(npc.MaxHitPoints * 0.25, DamageFlag.DAMAGE_EXPLOSION, EntityRef(npc), 0)
				end
				
				npc.StateFrame = 2
				npc.Mass = 7
				npc.GridCollisionClass = 3
				npc:GetSprite():Play("Bump")
				
				local schut = ProjectileParams()
				schut.BulletFlags = (2 ^ 28) --+ (2 ^ 4)
				schut.HeightModifier = 20
				schut.FallingSpeedModifier = 0.5
				schut.FallingAccelModifier = -0.15
				schut.Variant = 2
				schut.Color = Color(1,1,0.2,1,100,25,0)
				
				local projectileVelocity = Vector(10,0)
				
				for i=0,7,1 do
					npc:FireProjectiles(npc.Position, projectileVelocity:Rotated(i*45), 0, schut)
				end
			else
				npc.Velocity = Lerp(npc.Velocity,npc.TargetPosition * meteorMawMaxSpeed,0.5)
			end	
		else
			npc:MultiplyFriction(0.85)
			if (npc:GetSprite():IsFinished("Bump")) then
				npc:GetSprite():Play("Shake", true)
				npc.State = 4
			end
		end
	end
end
BBBaddiesMod:AddCallback( ModCallbacks.MC_NPC_UPDATE, BBBaddiesMod.MeteorMaw, BBBaddiesEntityType.ENTITY_METEOR_MAW)

function BBBaddiesMod:MeteorMawTakeDamage(npc, dmg, dmgType, dmgSrc, dmgCountDown)
	npc = npc:ToNPC()
	if (dmgType == DamageFlag.DAMAGE_FIRE) then
		-- if (npc.State == 8 and npc.StateFrame == 1) then
			-- local offset = dmgSrc.Position - npc.Position
			-- local boundVector = offset:Normalized()
			-- --BBBaddiesdebugString = "Offset:[" .. math.floor(offset.X * 100) * 0.01 .. "," .. math.floor(offset.Y * 100) * 0.01 .. "]" .. "   boundVector:[" .. math.floor(boundVector.X * 100) * 0.01 .. "," .. math.floor(boundVector.Y * 100) * 0.01 .. "]"
			-- --npc.Velocity = boundVector * 12
			-- BBBaddiesdebugString = "Velocity:[" .. math.floor(npc.Velocity.X * 100) * 0.01 .. "," .. math.floor(npc.Velocity.Y * 100) * 0.01 .. "]"
			
			-- --dmgSrc.Entity:TakeDamage(1, 0, npc, 0)
			
			-- npc.StateFrame = 2
			-- npc.Mass = 7
			-- npc.GridCollisionClass = 3
			-- npc:GetSprite():Play("Bump")
			
			
			-- local schut = ProjectileParams()
			-- schut.BulletFlags = (2 ^ 28) --+ (2 ^ 4)
			-- schut.HeightModifier = 20
			-- schut.FallingSpeedModifier = 0.5
			-- schut.FallingAccelModifier = -0.15
			-- schut.Variant = 2
			-- schut.Color = Color(1,1,0.2,1,100,25,0)
			
			-- local projectileVelocity = Vector(10,0)
			
			-- for i=0,7,1 do
				-- npc:FireProjectiles(npc.Position, projectileVelocity:Rotated(i*45), 0, schut)
			-- end
		-- end
		return false
		-- npc.StateFrame = 2
		-- npc.Mass = 7
		-- npc.GridCollisionClass = 3
		-- npc:GetSprite():Play("Bump")
		
		-- local schut = ProjectileParams()
		-- schut.BulletFlags = (2 ^ 28) --+ (2 ^ 4)
		-- schut.HeightModifier = 20
		-- schut.FallingSpeedModifier = 0.5
		-- schut.FallingAccelModifier = -0.15
		-- schut.Variant = 2
		-- schut.Color = Color(1,1,0.2,1,100,25,0)
		
		-- local projectileVelocity = Vector(10,0)
		
		-- for i=0,7,1 do
			-- npc:FireProjectiles(npc.Position, projectileVelocity:Rotated(i*45), 0, schut)
		-- end
	end
end
BBBaddiesMod:AddCallback( ModCallbacks.MC_ENTITY_TAKE_DMG, BBBaddiesMod.MeteorMawTakeDamage, BBBaddiesEntityType.ENTITY_METEOR_MAW)