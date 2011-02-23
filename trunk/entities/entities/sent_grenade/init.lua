
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

ENT.HitSound = Sound( "physics/metal/metal_grenade_impact_hard2.wav" )
ENT.Damage = 225
ENT.Radius = 350
ENT.Speed = 3000

function ENT:Initialize()

	self.Entity:SetModel( Model( "models/weapons/w_eq_fraggrenade_thrown.mdl") )
	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Entity:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	self.Entity:DrawShadow( false )
	
	local phys = self.Entity:GetPhysicsObject()
	
	if ValidEntity( phys ) then
	
		phys:Wake()
		phys:SetDamping( 0, 5 )
		phys:ApplyForceCenter( self.Entity:GetAngles():Forward() * self.Speed )
	
	end
	
	self.Delay = CurTime() + 3.5
	
end

function ENT:SetSpeed( num )

	self.Speed = num

end

function ENT:Think()

	if self.Delay < CurTime() then
	
		self.Entity:Explode()
	
	end

end

function ENT:Explode()

	local ed = EffectData()
	ed:SetOrigin( self.Entity:GetPos() )
	util.Effect( "Explosion", ed, true, true )

	if ValidEntity( self.Entity:GetOwner() ) then
	
		util.BlastDamage( self.Entity, self.Entity:GetOwner(), self.Entity:GetPos(), self.Radius, self.Damage )
		
	end
	
	for k,v in pairs( player.GetAll() ) do
	
		if v:Team() != self.Entity:GetOwner():Team() and v:GetPos():Distance( self.Entity:GetPos() ) < self.Radius then
		
			v:SetBleeding( true )
		
		end
	
	end
	
	self.Entity:Remove()

end

function ENT:OnRemove()

end

function ENT:OnTakeDamage( dmginfo )
	
end

function ENT:PhysicsCollide( data, phys )

	if data.Speed > 50 and data.DeltaTime > 0.15 then
	
		self.Entity:EmitSound( self.HitSound, 100, math.random(90,110) )
		
	end
	
end
