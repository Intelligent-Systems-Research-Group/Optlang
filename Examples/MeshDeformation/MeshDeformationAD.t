local IO = terralib.includec("stdio.h")
local adP = ad.ProblemSpec()
local P = adP.P
local W,H = opt.Dim("W",0), opt.Dim("H",1)

local X = 			adP:Image("X", opt.float6,W,H,0)			--vertex.xyz, rotation.xyz <- unknown
local UrShape = 	adP:Image("UrShape", opt.float3,W,H,1)		--urshape: vertex.xyz
local Constraints = adP:Image("Constraints", opt.float3,W,H,2)	--constraints
local G = adP:Graph("G", 0, "v0", W, H, 0, "v1", W, H, 1)
P:Stencil(2)

local C = terralib.includecstring [[
#include <math.h>
]]


--local w_fitSqrt = adP:Param("w_fitSqrt", float, 0)
--local w_regSqrt = adP:Param("w_regSqrt", float, 1)

local w_fitSqrt = 1.0
local w_regSqrt = 0.00000001


function evalRot(CosAlpha, CosBeta, CosGamma, SinAlpha, SinBeta, SinGamma)
	return ad.Vector(
		CosGamma*CosBeta, 
		-SinGamma*CosAlpha + CosGamma*SinBeta*SinAlpha, 
		SinGamma*SinAlpha + CosGamma*SinBeta*CosAlpha,
		SinGamma*CosBeta,
		CosGamma*CosAlpha + SinGamma*SinBeta*SinAlpha,
		-CosGamma*SinAlpha + SinGamma*SinBeta*CosAlpha,
		-SinBeta,
		CosBeta*SinAlpha,
		CosBeta*CosAlpha)
end
	
function evalR(alpha, beta, gamma)
	return evalRot(ad.cos(alpha), ad.cos(beta), ad.cos(gamma), ad.sin(alpha), ad.sin(beta), ad.sin(gamma))
end
	
function mul(matrix, v)
	return ad.Vector(matrix(0)*v(0)+matrix(1)*v(1)*matrix(2)*v(2),matrix(3)*v(0)+matrix(4)*v(1)*matrix(5)*v(2),matrix(6)*v(0)+matrix(7)*v(1)*matrix(8)*v(2))
end

local terms = terralib.newlist()
	
--fitting
local x_fit = ad.Vector(X(0,0,0), X(0,0,1), X(0,0,2))	--vertex-unknown : float3
local constraint = Constraints(0,0)						--target : float3
local e_fit = ad.Vector(
				x_fit(0) - constraint(0),
				x_fit(1) - constraint(1),
				x_fit(2) - constraint(2))
e_fit = x_fit - constraint
--TODO check that this works; its set to minus infinity...
e_fit = ad.select(ad.greatereq(constraint(0), -999999.9), e_fit, ad.Vector(0.0, 0.0, 0.0))
	
	
terms:insert(w_fitSqrt*e_fit)
--regularization
local x = ad.Vector(X(G.v0,0), X(G.v0,1), X(G.v0,2))	--vertex-unknown : float3
local a = ad.Vector(X(G.v0,3), X(G.v0,4), X(G.v0,5))	--rotation(alpha,beta,gamma) : float3
local R = evalR(a(0), a(1), a(2))						--rotation : float3x3
local xHat = UrShape(G.v0)	-- uv-urshape : float3
	
local n = ad.Vector(X(G.v1,0), X(G.v1,1), X(G.v1,2))
local ARAPCost = (x - n)	-	mul(R, (xHat - UrShape(G.v1)))

--terms:insert(w_regSqrt*ARAPCost)
	
local cost = ad.sumsquared(unpack(terms))
return adP:Cost(cost)


