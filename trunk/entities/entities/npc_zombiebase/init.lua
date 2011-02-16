AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.ClawHit = {"npc/zombie/claw_strike1.wav",
"npc/zombie/claw_strike2.wav",
"npc/zombie/claw_strike3.wav"}

ENT.ClawMiss = {"npc/zombie/claw_miss1.wav",
"npc/zombie/claw_miss2.wav"}

ENT.DoorHit = Sound("npc/zombie/zombie_hit.wav")

ENT.IdleTalk = 0
ENT.DoorTime = 0
ENT.VoiceTime = 0
ENT.RemoveTime = 0
ENT.RemovePos = Vector(0,0,0)

function ENT:Initialize()

	self.Entity:SetModel( "models/zombie/classic.mdl" )
	
	self.Entity:SetHullSizeNormal()
	self.Entity:SetHullType( HULL_HUMAN )
	
	self.Entity:SetSolid( SOLID_BBOX ) 
	self.Entity:SetMoveType( MOVETYPE_STEP )
	self.Entity:CapabilitiesAdd( CAP_MOVE_GROUND | CAP_INNATE_MELEE_ATTACK1 ) 
	
	self.Entity:SetMaxYawSpeed( 5000 )
	self.Entity:SetHealth( 100 )
	
	self.Entity:DropToFloor()
	
	self.Entity:UpdateEnemy( self.Entity:FindEnemy() )

end

function ENT:VoiceSound( tbl )

	if self.VoiceTime > CurTime() then return end

	self.VoiceTime = CurTime() + 1
	
	self.Entity:EmitSound( Sound( table.Random( tbl ) ), 100, math.random( 90, 100 ) )
	
end

function ENT:SpawnRagdoll( att )

	local ang = self.Entity:GetAngles()

	local shooter = ents.Create("env_shooter")
	shooter:SetPos( self.Entity:GetPos() )
	shooter:SetKeyValue( "m_iGibs", "1" )
	shooter:SetKeyValue( "shootsounds", "3" )
	shooter:SetKeyValue( "gibangles", ang.p.." "..ang.y.." "..ang.r )
	shooter:SetKeyValue( "angles", ang.p.." "..ang.y.." "..ang.r )
	shooter:SetKeyValue( "shootmodel", self.Entity:GetModel() ) 
	shooter:SetKeyValue( "simulation", "2" )
	shooter:SetKeyValue( "gibanglevelocity", math.random(-50,50).." "..math.random(-150,150).." "..math.random(-150,150) )
	
	if ValidEntity( att ) then
		
		shooter:SetKeyValue( "m_flVelocity", tostring( math.Rand( -40, 0 ) ) )
		shooter:SetKeyValue( "m_flVariance", tostring( math.Rand( -2, 0 ) ) )
		
	end
	
	shooter:Spawn()
	
	shooter:Fire( "shoot", 0, 0 )
	shooter:Fire( "kill", 0.1, 0.1 )
	
	if not att:IsPlayer() then return end
	
	if math.random( 1, 4 ) == 1 then
	
		local tbl = item.RandomItem( ITEM_QUEST_ZOMBIE )
		
		local ent = ents.Create( "sent_lootbag" )
		ent:AddItem( tbl.ID )
		ent:SetPos( self.Entity:GetPos() + Vector(0,0,25) )
		ent:Spawn()
		
	end

end

function ENT:DoDeath( attacker )

	if self.Dying then return end
	self.Dying = true
	
	self.Entity:SpawnRagdoll( attacker )
	self.Entity:VoiceSound( self.VoiceSounds.Death )
	
	self.Entity:SetSchedule( SCHED_FALL_TO_GROUND )
	self.Entity:Remove()
	
end

function ENT:OnTakeDamage( dmginfo )
	
	self.Entity:SetHealth( math.Clamp( self.Entity:Health() - dmginfo:GetDamage(), 0, 1000 ) )
	
	if self.Entity:Health() <= 0 then
	
		self.Entity:DoDeath( dmginfo:GetAttacker() )
		
	elseif math.random( 1, 3 ) == 1 then
	
		self.Entity:VoiceSound( self.VoiceSounds.Pain )
		
	end
	
end 

function ENT:FindEnemy()

	local tbl = ents.FindByClass( "npc_rogue" )
	tbl = table.Add( tbl, player.GetAll() )

	if #tbl < 1 then
		
		return NULL
		
	else
	
		local enemy = NULL
		local dist = 99999
		
		for k,v in pairs( tbl ) do
		
			local compare = v:GetPos():Distance( self.Entity:GetPos() )
			
			if compare < dist and ( ( v:IsPlayer() and v:Alive() and v:Team() != TEAM_UNASSIGNED and not ValidEntity( v.Stash ) ) or string.find( v:GetClass(), "npc" ) ) then
			
				enemy = v
				dist = compare
				
			end
			
		end
		
		return enemy
		
	end
	
end

function ENT:UpdateEnemy( enemy )

	if ValidEntity( enemy ) and ( ( enemy:IsPlayer() and enemy:Alive() and not ValidEntity( enemy.Stash ) ) or string.find( enemy:GetClass(), "npc" ) ) then
		
		self:SetEnemy( enemy, true ) 
		self:UpdateEnemyMemory( enemy, enemy:GetPos() ) 
		
	else
		
		self:SetEnemy( NULL )
		
	end

end

function ENT:Think()

	if self.RemoveTime < CurTime() then
	
		if self.Entity:GetPos() == self.RemovePos then

			self.Entity:Remove()
			
		end
		
		self.RemoveTime = CurTime() + 20
		self.RemovePos = self.Entity:GetPos()
	
	end

	if self.IdleTalk < CurTime() then
	
		self.Entity:VoiceSound( self.VoiceSounds.Taunt )
		self.IdleTalk = CurTime() + math.random(15,25)
		
	end

	if self.DoorTime < CurTime() then
	
		self.DoorTime = CurTime() + 5
		local door = self.Entity:NearDoor()
		
		if ValidEntity( door ) then
		
			self.Entity:SetSchedule( SCHED_MELEE_ATTACK1 ) 
		
			door:TakeDamage( 100, self.Entity )
			
			if string.find( door:GetClass(), "door" ) then
			
				door:Fire( "kill", 0.01, 0.01 )
				
			end
			
			self.Entity:EmitSound( self.DoorHit, 100, math.random(90,110) )
			
		end
		
	end
	
	if self.AttackTime and self.AttackTime < CurTime() then
	
		self.AttackTime = nil
		local enemy = self.Entity:GetEnemy()
		
		if ValidEntity( enemy ) and enemy:GetPos():Distance( self.Entity:GetPos() ) < 64 then
		
			enemy:TakeDamage( self.Damage, self.Entity )
			
			if enemy:IsPlayer() then
			
				self.Entity:OnDamageEnemy( enemy )
				
			end
			
			local sound = table.Random( self.ClawHit )
			self.Entity:EmitSound( Sound( sound ), 100, math.random(90,110) )

		else
		
			local sound = table.Random( self.ClawMiss )
			self.Entity:EmitSound( Sound( sound ), 100, math.random(90,110) )
		
		end
	
	end
	
end

function ENT:OnDamageEnemy( enemy )

end

function ENT:GetDoors()

	local tbl = ents.FindByClass( "prop_door_rotating" )
	tbl = table.Add( tbl, ents.FindByClass( "func_breakable" ) )
	
	return tbl

end

function ENT:NearDoor()

	local doors = self.Entity:GetDoors()
	local pos = self.Entity:GetPos()
	
	for k,v in pairs( doors ) do
	
		if v:GetPos():Distance( pos ) < 100 then
		
			return v
			
		end
		
	end
	
	return nil

end

function ENT:GetRelationship( entity )

	if ValidEntity( entity ) and ( entity:IsPlayer() or entity:GetClass() == "npc_rogue" ) then return D_HT end
	
	return D_LI
	
end

function ENT:SelectSchedule()

	local enemy = self.Entity:GetEnemy()
	local sched = SCHED_IDLE_WANDER 
	
	if ValidEntity( enemy ) then
	
		if self.Entity:HasCondition( 23 ) then //  COND_CAN_MELEE_ATTACK1 
		
			sched = SCHED_MELEE_ATTACK1
			self.AttackTime = CurTime() + 1
			self.Entity:VoiceSound( self.VoiceSounds.Attack )
			
		else
		
			sched = SCHED_CHASE_ENEMY
			
		end
		
	else
	
		self.Entity:UpdateEnemy( self.Entity:FindEnemy() )
		
	end

	self.Entity:SetSchedule( sched ) 

end
