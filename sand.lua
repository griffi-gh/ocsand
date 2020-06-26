print('loading')
local ver=1.2
local computer = require'computer'
local event = require("event")
local term = require'term'
if not term.isAvailable() then
  return
end
local gpu = term.gpu()
local w,h = gpu.getResolution()
--term.clear()

local sim={w=w/2,h=h}
for i=1,sim.w do
  sim[i]={}
end
setmetatable(sim,{__index=function() return{} end})

for i=1,sim.w do --add floor
  for j=1,2 do
    sim[i][sim.h-4+j]=1
  end
end

local function tryMove(x,y,nx,ny,f)
  local sim=sim
  if sim[nx][ny] and not(f)then
    return true
  end
  local val=sim[x][y]
  sim[x][y]=nil
  sim[nx][ny]=val
  return false
end

local elem={
  [0]={
    name='nil',
    color=0
  },
  {
    name='wall',
    color=0xaaaaaa,
    --update=function(x,y) end
  },
  {
    name='sand',
    update=function(x,y)
      if tryMove(x,y,x,y+1) then
        if tryMove(x,y,x+1,y+1) then
          return tryMove(x,y,x-1,y+1)
        end
      end
    end,
    color=0xf0f00c
  }
}


local function touchHandler(a,b,x,y)
  sim[math.ceil(x/2)][y+1]=2
end
local brk=false
local function exit()
  term.clear()
  on,nb,sim=nil,nil,nil
  brk=true
  print('sAND v.'..ver)
end

event.listen("touch", touchHandler)
event.listen("interrupted", exit)

local function buf()
  return setmetatable({},{__index=function()return 0 end})
end

local ob=buf()
local nb=buf()
local bufl=sim.w*sim.h

local function to1d(x,y,w)
  return x+(y-1)*w
end
local function to2d(i,w)
  local f=math.floor((i-1)/w)+1
  return i-(f-1)*w,f
end

term.clear()
while true do os.sleep(0)
  if brk then break end
  
  local sim=sim
  for x=1,sim.w do
    local nu,nils=0,0
    local sy,sm,c=1,'',1
    for y=sim.h,1,-1 do
      local v=sim[x][y]
      if v then
        local e=elem[v]
        if e.update then
          e.update(x,y)
        end
        nb[to1d(x,y,sim.w)]=e.color
      end
    end
  end
  
  for i=1,bufl do
    if ob[i]~=nb[i] then
      gpu.setBackground(nb[i])
      local x,y=to2d(i,sim.w)
      gpu.set(x*2-1,y-1,'  ')
    end
    if rawget(ob,i)==0 then rawset(ob,i,nil) end
    if rawget(nb,i)==0 then rawset(nb,i,nil) end
  end
  
  ob=nb
  nb=buf()
end