
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:Initialize()

	self.Entity:SetModel( "models/Roller.mdl" )
		
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_NONE )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Entity:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	
	self.Entity:DrawShadow( false )
	
	self.LastUse = 0
	self.LastThink = 0
	self.Items = {}
	
	self.ItemTbl = { ITEM_FOOD, ITEM_FOOD, ITEM_FOOD, ITEM_FOOD, ITEM_FOOD, ITEM_SUPPLY, ITEM_SUPPLY, ITEM_MISC, ITEM_MISC, ITEM_LOOT, ITEM_LOOT, ITEM_AMMO, ITEM_AMMO, ITEM_EXODUS, ITEM_WPN_COMMON }
	
	for i=1, math.random(2,5) do
			
		local rand = item.RandomItem( table.Random( self.ItemTbl ) )
			
		self.Entity:AddItem( rand.ID )
			
	end

end

function ENT:Think() 
	
	if not ValidEntity( self.Entity:GetUser() ) then return end
	
	if not self.Entity:GetUser():Alive() then
	
		self.Entity:SetUser()
	
	end
	
	if self.LastThink < CurTime() then
	
		self.LastThink = CurTime() + ( 10 * 60 )
	
		if #self.Entity:GetItems() < 1 then
	
			for i=1, math.random(2,5) do
			
				local rand = item.RandomItem( table.Random( self.ItemTbl ) )
			
				self.Entity:AddItem( rand.ID )
			
			end
		
		end
	
	end
	
end 

function ENT:GetUser()

	return self.User
	
end

function ENT:SetUser( ply )

	self.User = ply
	
end

function ENT:OnExit( ply )

	if ( self.LastUse or 0 ) > CurTime() then return end
	
	self.LastUse = CurTime() + 1.0
	
	if ValidEntity( self.Entity:GetUser() ) then
	
		self.Entity:SetUser()
		ply:ToggleStashMenu( self.Entity, false, "StashMenu" )
		
	end

end

function ENT:OnUsed( ply )

	if ( self.LastUse or 0 ) > CurTime() then return end
	
	self.LastUse = CurTime() + 1.0

	if ValidEntity( self.Entity:GetUser() ) and self.Entity:GetUser() != ply then return end
	
	if not ValidEntity( self.Entity:GetUser() ) then
	
		self.Entity:SetUser( ply )
		ply:ToggleStashMenu( self.Entity, true, "StashMenu" )
		
	end

end

function ENT:Use( ply, caller )

end

function ENT:GetItems()

	return self.Items
	
end

function ENT:AddItem( id )

	self.Items = self.Items or {}

	table.insert( self.Items, id )
	
	self.Entity:Synch()

end

function ENT:RemoveItem( id )

	for k,v in pairs( self.Items ) do
	
		if v == id then
		
			self.Entity:Synch()
		
			table.remove( self.Items, k )
			
			return
		
		end
	
	end

end

function ENT:Synch()

	if ValidEntity( self.Entity:GetUser() ) then
			
		self.Entity:GetUser():SynchStash( self.Entity )
			
	end

end

