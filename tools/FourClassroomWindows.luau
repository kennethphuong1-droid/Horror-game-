local root=workspace.ShirokiriHigh
local history=game:GetService("ChangeHistoryService")
history:SetWaypoint("Before evenly spaced classroom windows")
local recovery={}
_G.ClassroomWindowRecovery=recovery
local rooms=0
for _,room in root:GetDescendants() do
    if room:IsA("Model") and room.Name:match("^Class_") then
        local glass,frames,latches={},{},{}
        local horizontal=room:FindFirstChild("WindowHorizontalFrame")
        for _,p in room:GetChildren() do
            if p.Name=="WideClosedWindow" then table.insert(glass,p)
            elseif p.Name=="WindowMullion" then table.insert(frames,p)
            elseif p.Name=="WideWindowLatch" then table.insert(latches,p) end
        end
        if #glass>0 and horizontal and #frames>0 then
            assert(#glass==2,"Unexpected window layout: "..room:GetFullName())
            local middle=horizontal.Position.Z
            local width=horizontal.Size.Z
            local frameWidth=.16
            local paneWidth=(width-5*frameWidth)/4
            local templateGlass=glass[1]:Clone()
            local templateFrame=frames[1]:Clone()
            recovery[room]={old={},new={}}
            for _,list in {glass,frames} do for _,p in list do
                table.insert(recovery[room].old,p) p.Parent=nil
            end end
            for i=0,4 do
                local p=templateFrame:Clone()
                p.Size=Vector3.new(p.Size.X,p.Size.Y,frameWidth)
                p.Position=Vector3.new(p.Position.X,p.Position.Y,middle-width*.5+frameWidth*.5+i*(paneWidth+frameWidth))
                p.Parent=room table.insert(recovery[room].new,p)
            end
            for i=1,4 do
                local p=templateGlass:Clone()
                p.Size=Vector3.new(p.Size.X,p.Size.Y,paneWidth)
                p.Position=Vector3.new(p.Position.X,p.Position.Y,middle-width*.5+frameWidth+paneWidth*.5+(i-1)*(paneWidth+frameWidth))
                p.Parent=room table.insert(recovery[room].new,p)
            end
            table.sort(latches,function(a,b)return a.Position.Z<b.Position.Z end)
            for i,p in latches do
                local pane=2*i-1
                recovery[room].latches=recovery[room].latches or {}
                recovery[room].latches[p]=p.CFrame
                p.Position=Vector3.new(p.Position.X,p.Position.Y,middle-width*.5+frameWidth+paneWidth*.5+(pane-1)*(paneWidth+frameWidth))
            end
            templateGlass:Destroy() templateFrame:Destroy()
            room:SetAttribute("EvenWindowPaneCount",4)
            rooms+=1 task.wait()
        end
    end
end
history:SetWaypoint("Four evenly spaced classroom window panes")
return {classroomsUpdated=rooms,panesPerOpening=4}
