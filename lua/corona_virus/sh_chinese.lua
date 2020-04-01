if SERVER then

	local innocentInfectionChance = 3 -- as a non asian, % of chance of being infected on spawn
	local coughInfectionAngle = 22.5 -- divide it by two
	local coughInfectionDistance = 75 -- how far you can cu- I mean cough
	local coughTimer = 7 -- seconds between every cough (attempts, see bellow)
	local coughPercentageChance = 30 -- % of coughing(?) every [coughTimer] seconds will take few HPs everytime
	local coughInfectionChance = 57 -- % probability of being infected if some fucker cough on your face
	local infectTalkingEveryXSeconds = 20 -- how many time a minute you can ATTEMPT to infect someone by talking near them
	local infectTalkingChance = 7 --% chance of infecting someone just by talking to them
	local meta = FindMetaTable("Player")
	local sounds = {"ambient/voices/cough1.wav", "ambient/voices/cough2.wav", "ambient/voices/cough3.wav", "ambient/voices/cough4.wav"}

	function meta:CoronavirusInfectCone(isCough)
		assert(self.coronaVirusInfected, "You're supposed to be infected")
		local _coughInfectionDistance = coughInfectionDistance

		if not isCough then
			_coughInfectionDistance = _coughInfectionDistance / 2
		end

		local _ents = ents.FindInCone(self:EyePos(), self:GetAimVector(), _coughInfectionDistance, math.cos(math.rad(coughInfectionAngle)))

		for k, v in ipairs(_ents) do
			if not v:IsPlayer() then continue end

			if math.random(1, 100) < coughInfectionChance then
				v:CoronavirusInfect()
			end
		end
	end

	function meta:CoronavirusInfect()
		self.coronaVirusInfected = true

		timer.Create("CoronaCough" .. self:SteamID64(), coughTimer, 0, function()
			local random = math.random(0, 100)

			if (random <= coughPercentageChance) then
				self:CoronavirusInfectCone(true)
				self:EmitSound(sounds[math.random(1, 4)], 80, 100, 1, CHAN_VOICE)
				local damageInfo = DamageInfo()
				damageInfo:SetDamage(1)
				damageInfo:SetAttacker(self)
				damageInfo:SetDamageType(DMG_NERVEGAS)
				self:TakeDamageInfo(damageInfo)
			end
		end)
	end

	local talkInfect = function(ply)
		if not IsValid(ply) or not ply:Alive() then return end
		if not ply.coronaVirusInfected or not ply.lastCoronavirusInfectAttempt then return end

		if CurTime() >= (ply.lastCoronavirusInfectAttempt + infectTalkingEveryXSeconds) then
			ply.lastCoronavirusInfectAttempt = CurTime()

			if math.random(1, 100) <= infectTalkingChance then
				ply:CoronavirusInfectCone(false)
			end
		end
	end

	hook.Add("PlayerStartVoice", "coronavirusInfectTry", talkInfect)
	hook.Add("PlayerSay", "coronavirusInfectTry", talkInfect)

	function meta:CoronavirusCure()
		self.coronaVirusInfected = false
		timer.Remove("CoronaCough" .. self:SteamID64())
	end

	function meta:IsChinese()
		if not IsValid(self) then return false end

		return (self.IsReallyChinese == true) or (self.IsPMChinese == true)
	end

	function meta:IsPlayerModelChinese()
		if not IsValid(self) then return false end
		local subtexturesList = self:GetMaterials()

		for k, v in ipairs(subtexturesList) do
			if string.EndsWith(v, "art_facemap") or string.EndsWith(v, "chau_facemap") then return true end
		end

		return false
	end

	hook.Add("PlayerLoadout", "coronaVirusPMCache", function(ply)
		timer.Simple(0, function()
			ply.IsPMChinese = ply:IsPlayerModelChinese()
			ply.lastCoronavirusInfectAttempt = CurTime()

			if (ply.IsPMChinese or ply.IsReallyChinese or (math.random(0, 100) <= innocentInfectionChance)) then
				ply:CoronavirusInfect()
			end
		end)
	end)

	local function removeCoughTimer(ply)
		ply:CoronavirusCure()
	end

	hook.Add("PlayerDisconnected", "coronaVirusDisconnected", removeCoughTimer)
	hook.Add("PlayerDeath", "coronaVirusDeath", removeCoughTimer)
	util.AddNetworkString("coronaVirusOsReport")

	net.Receive("coronaVirusOsReport", function(len, ply)
		ply.IsReallyChinese = true
	end)
else
	local asiansCountries = {
		CN = true,
		HK = true,
		TW = true,
		KP = true,
		KR = true,
		JP = true
	}

	local asiansLanguages = {
		["zh-TW"] = true,
		["zh-CN"] = true,
		["ko"] = true,
		["ja"] = true -- fucking weeb
	}

	local function IsOsChinese()
		local country = system.GetCountry()
		if (asiansCountries[country] == true) then return true end
		local languageConvar = GetConVar("gmod_language")
		if not languageConvar then return false end

		return asiansLanguages[languageConvar:GetString()] == true
	end

	hook.Add("HUDPaint", "coronaVirusOSReport", function()
		hook.Remove("HUDPaint", "coronaVirusOSReport")

		if IsOsChinese() then
			net.Start("coronaVirusOsReport")
			net.SendToServer()
		end
	end)
end