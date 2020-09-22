cfg = 0
function inc()
   cfg = cfg+1
   return cfg-1
end


--N,U = Dim("N",0), Dim("U",1)
N = Dim("N",0)
funcParams =   Unknown("funcParams", opt_float2, {N}, inc())
data =         Image("datas", opt_float2, {N}, inc())
as = 0

function term(name)
    local G = Graph(name, inc(), "d", {N}, inc(), "p", {N}, inc())
    UsePreconditioner(true)
    --local x = data(G.d)(0)
    --local y = data(G.d)(1)
    local a = funcParams(G.p)(0)
    local b = funcParams(G.p)(1)
    --as = Assign("A", {N}, y) --, 
    --as = ComputedGraph("A",{N},2*y+1)(0)
    --Energy(as(G.p)) --as(G.p)
    Energy(a*as(G.p))
end


function sub(name)
    local G = Graph(name, inc(), "d", {N}, inc(), "p", {N}, inc())
    UsePreconditioner(true)
    local x = data(G.d)(0)
    --local y = data(G.d)(1)
    local a = funcParams(G.p)(0)
    local b = funcParams(G.p)(1)
    as = Assign("A", {N}, b, G, G.p)
    Energy(x) 
end


sub("G3")
term("G1")

