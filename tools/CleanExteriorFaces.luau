-- Edit-mode facade repair: separate exposed finish planes without covering windows or doors.
local root=workspace.ShirokiriHigh
assert(not root:GetAttribute("ExteriorFacesCleaned"),"Already repaired")
local history=game:GetService("ChangeHistoryService")
history:SetWaypoint("Before exterior face repair")
local originals={}
_G.ExteriorFaceRecovery=originals
local changes={bands=0,endWalls=0,slabJoins=0,redundantFascia=0}
for i,p in root:GetDescendants() do
    if p:IsA("Part") then
        local n=p.Name
        if n=="ContinuousFacadeBand" or n=="JoinedEndSlab" or n=="EndWallLeft" or n=="EndWallRight" or n=="UnifiedRoofFascia" then
            originals[p]={parent=p.Parent,copy=p:Clone()}
            if n=="ContinuousFacadeBand" then
                -- Original outer face coincided with the slab edge at +/-66.04 studs.
                p.Position+=Vector3.new(math.sign(p.Position.X)*.2,0,0)
                -- Stop at corner columns instead of running through their exposed end faces.
                p.Size=Vector3.new(p.Size.X,p.Size.Y,117.072)
                changes.bands+=1
            elseif n=="JoinedEndSlab" then
                -- Butt against the side-wing slabs; remove the overlapping 3.5-stud shoulders.
                p.Size=Vector3.new(31.68,p.Size.Y,p.Size.Z)
                changes.slabJoins+=1
            elseif n=="EndWallLeft" or n=="EndWallRight" then
                local low=math.max(-65.536,p.Position.X-p.Size.X*.5)
                local high=math.min(65.536,p.Position.X+p.Size.X*.5)
                p.Position=Vector3.new((low+high)*.5,p.Position.Y,p.Position.Z)
                p.Size=Vector3.new(high-low,p.Size.Y,p.Size.Z)
                changes.endWalls+=1
            else
                -- The top continuous facade band already covers the entire fascia height.
                p.Parent=nil
                changes.redundantFascia+=1
            end
        end
    end
    if i%300==0 then task.wait() end
end
root:SetAttribute("ExteriorFacesCleaned",true)
history:SetWaypoint("Clean school exterior faces")
return game:GetService("HttpService"):JSONEncode(changes)
