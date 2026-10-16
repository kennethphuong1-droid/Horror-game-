-- Run once in Studio Edit mode. Studio owns the place; this is an explicit maintenance pass.
-- No runtime script is installed. Undo restores the pass; in-session originals are also kept in _G.
local root = assert(workspace:FindFirstChild("ShirokiriHigh"), "School missing")
assert(not root:GetAttribute("SimplifiedBuildingPass"), "Already simplified")
local history = game:GetService("ChangeHistoryService")
local recording = history:TryBeginRecording("SimplifySchool", "Simplify school building")
if not recording then history:SetWaypoint("Before school simplification") end
local original, removed, totals = {}, {}, {}
_G.SchoolSimplificationRecovery = original
local function remember(p)
    if original[p] then return end
    original[p] = {copy = p:Clone(), parent = p.Parent}
end
local function retire(p, reason)
    if removed[p] then return end
    remember(p)
    removed[p] = true
    totals[reason] = (totals[reason] or 0) + 1
    p.Parent = nil
end
local function plain(p)
    return p.ClassName == "Part" and p.Shape == Enum.PartType.Block and p.Anchored
        and #p:GetChildren() == 0 and next(p:GetAttributes()) == nil and #p:GetTags() == 0
end
local function q(x) return tostring(math.round(x * 10000)) end
local function vec(v) return q(v.X)..","..q(v.Y)..","..q(v.Z) end
local function appearance(p)
    return p.Name.."|"..q(p.Color.R)..","..q(p.Color.G)..","..q(p.Color.B).."|"..p.Material.Name.."|"..p.MaterialVariant
        .."|"..tostring(p.Transparency).."|"..tostring(p.Reflectance)
        .."|"..tostring(p.CanCollide).."|"..tostring(p.CanTouch).."|"..tostring(p.CanQuery)
        .."|"..p.CollisionGroup.."|"..tostring(p.CastShadow)
end
local parts = {}
for i,p in root:GetDescendants() do
    if p:IsA("BasePart") then table.insert(parts,p) end
    if i % 500 == 0 then task.wait() end
end
local before = #parts
local ok, err = xpcall(function()
    local exact = {}
    for i,p in parts do
        if plain(p) then
            local key = appearance(p).."|"..vec(p.Size).."|"
            for _,n in {p.CFrame:GetComponents()} do key ..= q(n).."," end
            if exact[key] then retire(p,"Exact duplicates") else exact[key] = p end
        end
        if i % 500 == 0 then task.wait() end
    end

    -- Hairline geometry adds hundreds of instances and intersects the finished surface.
    local seams = {CeilingTileJoint=true,FloorExpansionJoint=true,RoofPavingJoint=true}
    for i,p in parts do
        if p.Parent and seams[p.Name] and plain(p) then retire(p,"Hairline surface seams") end
        if i % 500 == 0 then task.wait() end
    end

    -- Replace each three-slot locker vent with one restrained slot inside its original envelope.
    local vents = {}
    for _,p in parts do
        if p.Parent and p.Name == "VentSlot" and plain(p) then
            local key = p.Parent:GetFullName().."|"..q(p.Position.X).."|"..q(p.Position.Z)
                .."|"..tostring(math.floor(p.Position.Y/3.5))
            vents[key] = vents[key] or {}
            table.insert(vents[key],p)
        end
    end
    for _,group in vents do
        table.sort(group,function(a,b) return a.Position.Y < b.Position.Y end)
        if #group >= 2 and #group <= 3 then
            local a,b = group[1],group[#group]
            if b.Position.Y-a.Position.Y < .5 then
                remember(a)
                a.CFrame = a.CFrame + Vector3.new(0,(b.Position.Y-a.Position.Y)*.5,0)
                a.Size = Vector3.new(a.Size.X, math.min(.14,b.Position.Y-a.Position.Y+a.Size.Y),a.Size.Z)
                for j=2,#group do retire(group[j],"Simplified locker vents") end
            end
        end
    end

    -- Collapse small runs into simple fabric panels and small book bundles.
    -- Group only siblings with matching rotation and row alignment; preserve the occupied envelope.
    local bundleNames = {CurtainFold=5,GatheredWindowCurtain=4,ExerciseBook=4,BookSpine=4,PleatedPrivacyDivider=4}
    local rows = {}
    for i,p in parts do
        if p.Parent and bundleNames[p.Name] and plain(p) then
            local axis = (p.Name:find("Curtain") or p.Name == "PleatedPrivacyDivider") and 3 or 1
            local rotation = p.CFrame.Rotation
            local localPos = rotation:PointToObjectSpace(p.Position)
            local key = p.Parent:GetFullName().."|"..p.Name.."|"..tostring(axis).."|"
            for _,n in {rotation:GetComponents()} do key ..= q(n).."," end
            -- Book rows may contain slightly varied heights; use their common shelf base.
            key ..= q(localPos.Y-p.Size.Y*.5).."|"..q(axis==1 and localPos.Z or localPos.X)
            rows[key] = rows[key] or {axis=axis,parts={}}
            table.insert(rows[key].parts,p)
        end
        if i%500==0 then task.wait() end
    end
    local function coordinate(p,axis)
        local v=p.CFrame.Rotation:PointToObjectSpace(p.Position)
        return axis==1 and v.X or v.Z
    end
    for _,row in rows do
        local group=row.parts local axis=row.axis
        table.sort(group,function(a,b)return coordinate(a,axis)<coordinate(b,axis) end)
        local start=1
        while start<=#group do
            local last=start
            while last<#group and last-start+1<bundleNames[group[start].Name] do
                local a,b=group[last],group[last+1]
                local sa=axis==1 and a.Size.X or a.Size.Z
                local sb=axis==1 and b.Size.X or b.Size.Z
                if coordinate(b,axis)-coordinate(a,axis)-(sa+sb)*.5>.55 then break end
                last+=1
            end
            if last>start then
                local keep=group[start] local rotation=keep.CFrame.Rotation
                local low,high
                for j=start,last do
                    local p=group[j] local pos=rotation:PointToObjectSpace(p.Position)
                    low=low and low:Min(pos-p.Size*.5) or pos-p.Size*.5
                    high=high and high:Max(pos+p.Size*.5) or pos+p.Size*.5
                end
                remember(keep) keep.Size=high-low keep.CFrame=rotation+rotation:VectorToWorldSpace((low+high)*.5)
                for j=start+1,last do retire(group[j],"Simplified "..keep.Name) end
            end
            start=last+1
        end
    end
    task.wait()

    -- Spaced posts retain the roof silhouette; the existing continuous guard supplies collision.
    local fenceGuards={}
    for _,p in root.Rooftop:GetChildren() do
        if p.Name=="RoofFenceCollision" and p:IsA("BasePart") and p.CanCollide then table.insert(fenceGuards,p) end
    end
    assert(#fenceGuards==5,"Unexpected roof safety barrier layout")
    local posts={}
    for _,p in root.Rooftop:GetChildren() do
        if p.Name=="RoofSafetyPicket" and plain(p) then table.insert(posts,p) end
    end
    table.sort(posts,function(a,b)
        if math.abs(a.Position.Z-b.Position.Z)>.01 then return a.Position.Z<b.Position.Z end
        return a.Position.X<b.Position.X
    end)
    for i,p in posts do
        if i%2==0 then
            local inside=false
            for _,guard in fenceGuards do
                local d=guard.CFrame:PointToObjectSpace(p.Position)
                if math.abs(d.X)<=guard.Size.X*.5+.1 and math.abs(d.Z)<=guard.Size.Z*.5+.1 then inside=true break end
            end
            if inside then retire(p,"Reduced roof posts") end
        end
    end

    -- Remove fully buried opaque blocks. Face-flush finish layers remain untouched.
    local solids={}
    for _,p in parts do
        if p.Parent and p.ClassName=="Part" and p.Shape==Enum.PartType.Block and p.Transparency==0
            and p.Anchored and p.CanCollide and p.Size.X*p.Size.Y*p.Size.Z>10 then table.insert(solids,p) end
    end
    for i,p in parts do
        if p.Parent and plain(p) and p.Transparency==0 then
            for _,s in solids do
                if s~=p and s.Parent and (not p.CanCollide or s.CanCollide) then
                    local relative=s.CFrame:ToObjectSpace(p.CFrame)
                    local r,u,l=relative.RightVector,relative.UpVector,relative.LookVector
                    local extent=Vector3.new(
                        math.abs(r.X)*p.Size.X+math.abs(u.X)*p.Size.Y+math.abs(l.X)*p.Size.Z,
                        math.abs(r.Y)*p.Size.X+math.abs(u.Y)*p.Size.Y+math.abs(l.Y)*p.Size.Z,
                        math.abs(r.Z)*p.Size.X+math.abs(u.Z)*p.Size.Y+math.abs(l.Z)*p.Size.Z)*.5
                    local d=relative.Position
                    if math.abs(d.X)+extent.X<s.Size.X*.5-.003 and math.abs(d.Y)+extent.Y<s.Size.Y*.5-.003
                        and math.abs(d.Z)+extent.Z<s.Size.Z*.5-.003 then
                        retire(p,"Fully buried geometry") break
                    end
                end
            end
        end
        if i%100==0 then task.wait() end
    end

    -- Merge only rectangular structural unions, with exactly matching cross sections and finish.
    local allowed={FourthFloorLanding=true,NorthOpenFourthFloorThreshold=true,FourthFloorDoorThreshold=true,
        FourthFloorFlushThreshold=true,AccessBuildingLeftWall=true,AccessBuildingRightWall=true,StairTowerSideWall=true}
    local candidates={}
    for _,p in root.Stairwells:GetDescendants() do
        if p:IsA("Part") and allowed[p.Name] and plain(p) then table.insert(candidates,p) end
    end
    for i,a in candidates do
        if a.Parent then
            for j=i+1,#candidates do
                local b=candidates[j]
                if b.Parent and a.Color==b.Color and a.Material==b.Material and a.CanCollide==b.CanCollide
                    and a.Transparency==b.Transparency and a.CFrame.Rotation==b.CFrame.Rotation then
                    local d=a.CFrame:PointToObjectSpace(b.Position)
                    for axis=1,3 do
                        local av={a.Size.X,a.Size.Y,a.Size.Z} local bv={b.Size.X,b.Size.Y,b.Size.Z} local dv={d.X,d.Y,d.Z}
                        local same=true
                        for k=1,3 do if k~=axis and (math.abs(av[k]-bv[k])>.002 or math.abs(dv[k])>.002) then same=false end end
                        if same and math.abs(dv[axis])<=(av[axis]+bv[axis])*.5+.001 then
                            local low=math.min(-av[axis]*.5,dv[axis]-bv[axis]*.5)
                            local high=math.max(av[axis]*.5,dv[axis]+bv[axis]*.5)
                            remember(a)
                            local offset={0,0,0} offset[axis]=(low+high)*.5 av[axis]=high-low
                            a.CFrame=a.CFrame*CFrame.new(table.unpack(offset)) a.Size=Vector3.new(table.unpack(av))
                            retire(b,"Merged overlapping structural blocks") break
                        end
                    end
                end
            end
        end
    end

    -- Imported construction remnants are external module loaders, not school gameplay.
    for i,s in game:GetDescendants() do
        if s:IsA("Script") and s.Name=="WelderPart" and s.Source=="require(5677592870)()" then
            retire(s,"Removed imported loader remnants")
        end
        if i%500==0 then task.wait() end
    end
    root:SetAttribute("SimplifiedBuildingPass",true)
    root:SetAttribute("PartsBeforeSimplification",before)
end,debug.traceback)
if not ok then
    for p,state in original do
        if p:IsA("BasePart") then p.Size=state.copy.Size p.CFrame=state.copy.CFrame end
        p.Parent=state.parent
    end
    root:SetAttribute("SimplifiedBuildingPass",nil)
    root:SetAttribute("PartsBeforeSimplification",nil)
    if recording then history:FinishRecording(recording,Enum.FinishRecordingOperation.Cancel) end
    error(err)
end
if recording then history:FinishRecording(recording,Enum.FinishRecordingOperation.Commit)
else history:SetWaypoint("Simplify school building") end
local after=0
for _,p in root:GetDescendants() do if p:IsA("BasePart") then after+=1 end end
_G.SchoolSimplificationReport={before=before,after=after,removed=before-after,reasons=totals}
return game:GetService("HttpService"):JSONEncode(_G.SchoolSimplificationReport)
