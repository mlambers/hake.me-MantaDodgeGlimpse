local GlimpseDetector = {
    endName = {name = "disruptor_glimpse_targetend", id = 0},
    endTrackedIndex = 0,
	targetAbsOrigin = nil,
    endPos = nil,
	gameTime = nil,
    target = nil
}

GlimpseDetector.optionEnableScript = Menu.AddOption({"Utility", "Dodge Disruptor Glimpse"}, "1. Enable script.", "Automatically dodge disruptor glimpse with manta.")
GlimpseDetector.optionEnableDrawDebugScript = Menu.AddOption({"Utility", "Dodge Disruptor Glimpse"}, "2. Show debug end location draw.", "")
GlimpseDetector.optionExecuteWithMinimumRange = Menu.AddOption({"Utility", "Dodge Disruptor Glimpse"}, "3. Execute dodge with minimum distance.", "")
GlimpseDetector.offsetDistance = Menu.AddOption({ "Utility", "Dodge Disruptor Glimpse" }, "4. Distance offset", "", 300, 1200, 50)

function GlimpseDetector.OnUpdate()
	if not Menu.IsEnabled(GlimpseDetector.optionEnableScript) then return end
	local myHero = Heroes.GetLocal()
	if not myHero then return end
	
	if GlimpseDetector.endPos ~= nil and GlimpseDetector.target == Heroes.GetLocal() then
		if Menu.IsEnabled(GlimpseDetector.optionExecuteWithMinimumRange) then
			if (GlimpseDetector.targetAbsOrigin - GlimpseDetector.endPos):Length() < Menu.GetValue(GlimpseDetector.offsetDistance) then return end
			local timeTravel = (GlimpseDetector.targetAbsOrigin - GlimpseDetector.endPos):Length() / 600
			
			local originalTravelTime = timeTravel
			
			-- Normalize glimpse travel duration if more than 1.8 then set to 1.8 because max time is 1.8
			if timeTravel > 1.8 then
				timeTravel = 1.8
			end
			
			-- Now predict future time when script should execute manta
			local timeHit = GlimpseDetector.gameTime + (timeTravel-0.1)
			Log.Write("Prediction time: " .. timeHit .. " Current Game time: " .. GameRules.GetGameTime() + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) .. " Travel time non normalize: " .. originalTravelTime)
			
			if GameRules.GetGameTime() >= timeHit then
				local mantaEnt = NPC.GetItem(Heroes.GetLocal(), "item_manta", true)
				if mantaEnt and Ability.IsCastable(mantaEnt, NPC.GetMana(Heroes.GetLocal())) then
					Ability.CastNoTarget(mantaEnt)
				end
			end
		else
			local timeTravel = (GlimpseDetector.targetAbsOrigin - GlimpseDetector.endPos):Length() / 600
			
			local originalTravelTime = timeTravel
			
			-- Normalize glimpse travel duration if more than 1.8 then set to 1.8 because max time is 1.8
			if timeTravel > 1.8 then
				timeTravel = 1.8
			end
			
			-- Now predict future time when script should execute manta
			local timeHit = GlimpseDetector.gameTime + (timeTravel-0.1)
			Log.Write("Prediction time: " .. timeHit .. " Current Game time: " .. GameRules.GetGameTime() + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) .. " Travel time non normalize: " .. originalTravelTime)
			
			if GameRules.GetGameTime() >= timeHit then
				local mantaEnt = NPC.GetItem(Heroes.GetLocal(), "item_manta", true)
				if mantaEnt and Ability.IsCastable(mantaEnt, NPC.GetMana(Heroes.GetLocal())) then
					Ability.CastNoTarget(mantaEnt)
				end
			end
		end
    end
end

-- Debug draws the end position of glimpse
function GlimpseDetector.OnDraw()
	if not Menu.IsEnabled(GlimpseDetector.optionEnableScript) then return end
	if not Menu.IsEnabled(GlimpseDetector.optionEnableDrawDebugScript) then return end
	local myHero = Heroes.GetLocal()
	if not myHero then return end
	
	
    if GlimpseDetector.endPos ~= nil and GlimpseDetector.target == Heroes.GetLocal() then
		
        local x, y, vis = Renderer.WorldToScreen(GlimpseDetector.endPos)

        if vis then
            Renderer.SetDrawColor(255, 0, 0)
            Renderer.DrawFilledRect(x, y, 25, 25)
        end
    end
end

function GlimpseDetector.OnParticleCreate(particle)
    if GlimpseDetector.endName.id ~= 0 then
        if particle.particleNameIndex == GlimpseDetector.endName.id then
            GlimpseDetector.endTrackedIndex = particle.index
			--GlimpseDetector.gameTime = GameRules.GetGameTime() + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
        end
    elseif particle.name == GlimpseDetector.endName.name then
        GlimpseDetector.endName.id = particle.particleNameIndex
        GlimpseDetector.endTrackedIndex = particle.index
		--GlimpseDetector.gameTime = GameRules.GetGameTime() + NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
    end
end

function GlimpseDetector.OnParticleUpdate(particle)
    -- control point 1 = position
    if particle.index == GlimpseDetector.endTrackedIndex and particle.controlPoint == 1 then
        GlimpseDetector.endPos = particle.position
		
		
    end
end

function GlimpseDetector.OnParticleUpdateEntity(particle)
    -- This unit is being targeted by glimpse
    if particle.entity ~= nil and particle.index == GlimpseDetector.endTrackedIndex then
        GlimpseDetector.target = particle.entity
		GlimpseDetector.targetAbsOrigin = Entity.GetAbsOrigin(particle.entity)
		GlimpseDetector.gameTime = GameRules.GetGameTime()
        Log.Write(NPC.GetUnitName(particle.entity) .. " is being targeted by Glimpse");
    end
end

function GlimpseDetector.OnParticleDestroy(particle)
    if particle.index == GlimpseDetector.endTrackedIndex then
        GlimpseDetector.endTrackedIndex = 0
		GlimpseDetector.targetAbsOrigin = nil
        GlimpseDetector.endPos = nil
		GlimpseDetector.gameTime = nil
        GlimpseDetector.target = nil
    end
end

return GlimpseDetector