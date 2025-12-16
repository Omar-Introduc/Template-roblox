local GeometryLib = {}

-- Helper function to create parts efficiently
function GeometryLib.CreatePart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	if props.Size then part.Size = props.Size end
	if props.CFrame then part.CFrame = props.CFrame end
	if props.Color then part.Color = props.Color end
	if props.Material then part.Material = props.Material end
	if props.Name then part.Name = props.Name end
	if props.Shape then part.Shape = props.Shape end

	-- Allow passing Parent last for performance (though less critical for Anchored parts)
	if props.Parent then part.Parent = props.Parent end

	return part
end

function GeometryLib.CreateWedge(props)
	local wedge = Instance.new("WedgePart")
	wedge.Anchored = true
	wedge.TopSurface = Enum.SurfaceType.Smooth
	wedge.BottomSurface = Enum.SurfaceType.Smooth

	if props.Size then wedge.Size = props.Size end
	if props.CFrame then wedge.CFrame = props.CFrame end
	if props.Color then wedge.Color = props.Color end
	if props.Material then wedge.Material = props.Material end
	if props.Parent then wedge.Parent = props.Parent end

	return wedge
end

return GeometryLib
