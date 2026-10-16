local root=workspace.ShirokiriHigh
local history=game:GetService("ChangeHistoryService")
history:SetWaypoint("Before structural join cleanup")
local recovery=assert(_G.SchoolSimplificationRecovery)
local changed,removed,decorative=0,0,0
local function remember(p)
    if not recovery[p] then recovery[p]={copy=p:Clone(),parent=p.Parent} end
end
local function trim(p,axis,low,high)
    remember(p)
    local pos={p.Position.X,p.Position.Y,p.Position.Z}
    local size={p.Size.X,p.Size.Y,p.Size.Z}
    pos[axis]=(low+high)*.5 size[axis]=high-low
    p.Position=Vector3.new(table.unpack(pos)) p.Size=Vector3.new(table.unpack(size))
    changed+=1
end
local noCollision={VentSlot=true,VentSlat=true,RecessedHandle=true,BookSpine=true,ExerciseBook=true,
    CurtainFold=true,GatheredWindowCurtain=true,PleatedPrivacyDivider=true,MetalStepNosing=true}
for i,p in root:GetDescendants() do
    if p:IsA("Part") then
        if p.Name=="CrossHallCeiling" then
            trim(p,1,-16.56,16.56)
        elseif p.Name=="FlushCrossWingRoofCap" then
            trim(p,1,-15.84,15.84)
        elseif p.Name=="FlushWingRoofCap" then
            -- Completely inside the existing two-stud floor/roof support slab.
            remember(p) p.Parent=nil removed+=1
        elseif p.Name=="AccessBuildingLeftWall" or p.Name=="AccessBuildingRightWall" then
            trim(p,3,p.Position.Z-p.Size.Z*.5,58.56)
        elseif p.Name=="NorthOpenFourthFloorThreshold" then
            trim(p,3,p.Position.Z-p.Size.Z*.5,58.56)
        elseif p.Name=="FourthFloorDoorThreshold" and p.Position.X<0 then
            trim(p,1,p.Position.X-p.Size.X*.5,-23.9)
            trim(p,3,-58.56,p.Position.Z+p.Size.Z*.5)
        elseif p.Name=="FourthFloorFlushThreshold" then
            trim(p,3,-58.56,p.Position.Z+p.Size.Z*.5)
        end
        if p.Parent and noCollision[p.Name] and p.CanCollide and #p:GetChildren()==0 then
            remember(p) p.CanCollide=false p.CanTouch=false decorative+=1
        end
    end
    if i%300==0 then task.wait() end
end
history:SetWaypoint("Clean structural joins and decorative collision")
local n=0 for _,p in root:GetDescendants() do if p:IsA("BasePart") then n+=1 end end
root:SetAttribute("PartsAfterSimplification",n)
return {schoolParts=n,structuralEdits=changed,buriedCapsRemoved=removed,decorativeCollidersRemoved=decorative}
