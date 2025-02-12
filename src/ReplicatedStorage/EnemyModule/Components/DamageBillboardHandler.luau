local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local adorneeToBillboardGui = {}

local DamageBillboard = {}

function DamageBillboard:createBillboardGui(adornee)
	local billboard = adorneeToBillboardGui[adornee]
	if billboard then
		return billboard
	end

	billboard = Instance.new("BillboardGui")
	billboard.Name = "DamageBillboardGui"
	billboard.Adornee = adornee
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 60
	billboard.Size = UDim2.new(10,20,10,20)
	billboard.ExtentsOffsetWorldSpace = Vector3.new(0,1,0)
	billboard.ResetOnSpawn = false
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	billboard.Parent = adornee
	--billboard.Parent = Players.LocalPlayer.PlayerGui
	
	adorneeToBillboardGui[adornee] = billboard

	local ancestorCon
	ancestorCon = adornee.AncestryChanged:connect(function(child, parent)
		if parent == nil then
			ancestorCon:disconnect()
			ancestorCon = nil

			local adorneeBillboard = adorneeToBillboardGui[adornee]
			adorneeBillboard:Destroy()
			adorneeToBillboardGui[adornee] = nil
		end
	end)

	return billboard
end

function DamageBillboard:tweenBillboard(textLabel)
	local appearTweenInfo = TweenInfo.new(
		1, --time
		Enum.EasingStyle.Elastic,
		Enum.EasingDirection.Out,
		0, --repeatCount
		false, --reverses
		0) --delayTime
	local appearTween = TweenService:Create(
		textLabel,
		appearTweenInfo, {
			Size = UDim2.fromScale(0.1, 0.1),
			TextColor3 = Color3.new(1,1,1)
		}
	)
	
	local completedCon
	completedCon = appearTween.Completed:connect(function()
		completedCon:disconnect()
		completedCon = nil
		textLabel:Destroy()
	end)

	appearTween:Play()
end

function DamageBillboard:showDamageBillboard(damageAmount, adornee)
	damageAmount = math.ceil(damageAmount)

	local billboard = self:createBillboardGui(adornee)
	
	local randomXPos = math.random(1, 9) / 10
	
	local textLabel = Instance.new("TextLabel")
	textLabel.AnchorPoint = Vector2.new(0.5, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.Position = UDim2.fromScale(randomXPos,0.5)
	textLabel.Size = UDim2.fromScale(0.01, 0.01)
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.Text = "-" .. tostring(damageAmount)
	textLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	textLabel.TextScaled = true
	textLabel.TextWrapped = true
	textLabel.TextStrokeTransparency = 0
	textLabel.TextTransparency = 0
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.TextYAlignment = Enum.TextYAlignment.Bottom
	textLabel.Parent = billboard
	
	self:tweenBillboard(textLabel)
end

return DamageBillboard
