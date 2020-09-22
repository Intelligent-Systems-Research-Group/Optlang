return function(P)
    local terms = terralib.newlist()

    local L = {}

    function L.Energy(...)
        for i,e in ipairs {...} do
            terms:insert(e)
        end
    end

    function L.Result() return P:Cost(unpack(terms)) end
    function L.All(v)
        local r = 1
        for i = 0,v:size() - 1 do
            r = r * v(i)
        end
        return r
    end

    function L.Reduce(fn,init)
        return function(...)
            local r = init
            for _,e in ipairs {...} do
                r = fn(r,e)
            end
            return r
        end
    end
    L.And = L.Reduce(1,ad.and_)
    L.Or = L.Reduce(0,ad.or_)
    L.Not = ad.not_
    
    function L.UsePreconditioner(...) return P:UsePreconditioner(...) end
    -- alas for Image/Array
    function L.Array(...) return P:Image(...) end
    function L.ComputedArray(...) return P:ComputedImage(...) end

	function L.Cross(a,b)
		return ad.Vector(
			a(1)*b(2) - a(2)*b(1),
			a(2)*b(0) - a(0)*b(2),
			a(0)*b(1) - a(1)*b(0)
		)
	end
    function L.Matrix3x3Mul(matrix,v)
        return ad.Vector(
            matrix(0)*v(0)+matrix(1)*v(1)+matrix(2)*v(2),
            matrix(3)*v(0)+matrix(4)*v(1)+matrix(5)*v(2),
            matrix(6)*v(0)+matrix(7)*v(1)+matrix(8)*v(2))
    end

    function L.Matrix2x2Mul(matrix,v)
        return ad.Vector(
            matrix(0)*v(0)+matrix(1)*v(1),
            matrix(2)*v(0)+matrix(3)*v(1)
        )
    end

    function L.Matrix3x3Dot(u,v)
        return ad.Vector(
            u(0)*v(0)+u(1)*v(3)+u(2)*v(6),
            u(0)*v(1)+u(1)*v(4)+u(2)*v(7),
            u(0)*v(2)+u(1)*v(5)+u(2)*v(8),

            u(3)*v(0)+u(4)*v(3)+u(5)*v(6),
            u(3)*v(1)+u(4)*v(4)+u(5)*v(7),
            u(3)*v(2)+u(4)*v(5)+u(5)*v(8),    

            u(6)*v(0)+u(7)*v(3)+u(8)*v(6),   
            u(6)*v(1)+u(7)*v(4)+u(8)*v(7),   
            u(6)*v(2)+u(7)*v(5)+u(8)*v(8)      

        )
    end

    function L.Matrix2x2Dot(u,v)
        return ad.Vector(
            u(0)*v(0)+u(1)*v(2),
            u(0)*v(1)+u(1)*v(3),
            u(2)*v(0)+u(3)*v(2),
            u(2)*v(1)+u(3)*v(3)
        )
    end

    function L.Dot3(v0,v1)
        return v0(0)*v1(0)+v0(1)*v1(1)+v0(2)*v1(2)
    end

    function L.Sqrt(v)
        return ad.sqrt(v)
    end

    function L.normalize(v)
        return v / L.L_2_norm(v)
    end

    function L.length(v0, v1) 
        local diff = v0 - v1
        return ad.sqrt(L.Dot3(diff, diff))
    end

    function L.Slice(im,s,e)
        return setmetatable({},{
            __call = function(self,ind)
                if s + 1 == e then return im(ind)(s) end
                local t = terralib.newlist()
                for i = s,e - 1 do
                    local val = im(ind)
                    local chan = val(i)
                    t:insert(chan)
                end
                return ad.Vector(unpack(t))
            end })
    end

    function L.Rotate3D(a,v)
        local alpha, beta, gamma = a(0), a(1), a(2)
        local  CosAlpha, CosBeta, CosGamma, SinAlpha, SinBeta, SinGamma = ad.cos(alpha), ad.cos(beta), ad.cos(gamma), ad.sin(alpha), ad.sin(beta), ad.sin(gamma)
        local matrix = ad.Vector(
            CosGamma*CosBeta, 
            -SinGamma*CosAlpha + CosGamma*SinBeta*SinAlpha, 
            SinGamma*SinAlpha + CosGamma*SinBeta*CosAlpha,
            SinGamma*CosBeta,
            CosGamma*CosAlpha + SinGamma*SinBeta*SinAlpha,
            -CosGamma*SinAlpha + SinGamma*SinBeta*CosAlpha,
            -SinBeta,
            CosBeta*SinAlpha,
            CosBeta*CosAlpha)
        return L.Matrix3x3Mul(matrix,v)
    end
    --[[
    function L.Rotate3D(a)
        local alpha, beta, gamma = a(0), a(1), a(2)
        local  CosAlpha, CosBeta, CosGamma, SinAlpha, SinBeta, SinGamma = ad.cos(alpha), ad.cos(beta), ad.cos(gamma), ad.sin(alpha), ad.sin(beta), ad.sin(gamma)
        local matrix = ad.Vector(
            CosGamma*CosBeta, 
            -SinGamma        local v1 = ad.Vector(1,-v(2),v(1),
                             v(2),1,-v(0),
                             -v(1),v(0),1)
        return v1  *CosAlpha + CosGamma*SinBeta*SinAlpha, 
            SinGamma*SinAlpha + CosGamma*SinBeta*CosAlpha,
            SinGamma*CosBeta,
            CosGamma*CosAlpha + SinGamma*SinBeta*SinAlpha,
            -CosGamma*SinAlpha + SinGamma*SinBeta*CosAlpha,
            -SinBeta,
            CosBeta*SinAlpha,
            CosBeta*CosAlpha)
        return matrix
    end
    ]]--
    function L.Rotate3D(a)
        local alpha, beta, gamma = a(0), a(1), a(2)
        local  c1, c2, c3, s1, s2, s3 = ad.cos(alpha), ad.cos(beta), ad.cos(gamma),   ad.sin(alpha), ad.sin(beta), ad.sin(gamma)
        local matrix = ad.Vector(
            c1*c2, 
            c1*s2*s3-c3*s1, 
            s1*s3+c1*c3*s2,
            c2*s1,
            c1*c3+s1*s2*s3,
            c3*s1*s2-c1*s3,
            -s2,
            c2*s3,
            c2*c3)
        return matrix
    end
    
    function L.Rod(v)

        local v1 = ad.Vector(1,-v(2),v(1),
                             v(2),1,-v(0),
                             -v(1),v(0),1)
        return v1        
    end

    function L.Transpose3(a)
        local matrix = ad.Vector(
            a(0),
            a(3),
            a(6),
            a(1),
            a(4),
            a(7),
            a(2),
            a(5),
            a(8)
        )
        return matrix
    end

    function L.Transpose2(a)
        local matrix = ad.Vector(
            a(0),
            a(2),
            a(1),
            a(3)
        )
        return matrix
    end

    function L.Det2(a)
        local det = a(0)*a(3)-a(1)*a(2)
        return det
    end

    function L.Inv2(a)
        local det = a(0)*a(3)-a(1)*a(2)
        local inv = (1.0/det) * ad.Vector(
            a(3),
            -a(1),
            -a(2),
            a(0)
        )
        return inv        
    end


    function L.Rotate2D(angle, v)
	    local CosAlpha, SinAlpha = ad.cos(angle), ad.sin(angle)
        local matrix = ad.Vector(CosAlpha, -SinAlpha, SinAlpha, CosAlpha)
	    return ad.Vector(matrix(0)*v(0)+matrix(1)*v(1), matrix(2)*v(0)+matrix(3)*v(1))
    end
    L.Index = ad.Index
    L.SampledImage = ad.sampledimage

--
    function L.L_2_norm(v)
        -- TODO: check if scalar and just return
        return ad.sqrt(v:dot(v))
    end
    L.L_p_counter = 1
    function L.L_p(val, val_const, p, dims)
        local dist_const = L.L_2_norm(val_const)
        local eps = 0.0000001
        local C = ad.pow(dist_const+eps,(p-2))
        local sqrtC = ad.sqrt(C)
        local sqrtCImage = L.ComputedArray("L_p"..tostring(L.L_p_counter),dims,sqrtC)
        L.L_p_counter = L.L_p_counter + 1
        return sqrtCImage(0,0)*val
    end

    L.Select = ad.select
    function L.Stencil (lst)
        local i = 0
        return function()
            i = i + 1
            if not lst[i] then return nil
            else return unpack(lst[i]) end
        end
    end
    setmetatable(L,{__index = function(self,key)
        if type(P[key]) == "function" then
            return function(...) return P[key](P,...) end
        end
        if key ~= "select" and ad[key] then return ad[key] end
        if opt[key] then return opt[key] end
        return _G[key]
    end})

    

    function L.Eig2(a)
        local T = a(0) + a(3)
        local D = a(0)*a(3)-a(1)*a(2)
        local L1 = T/2 + ad.sqrt(T*T/4 - D)
        local L2 = T/2 - ad.sqrt(T*T/4 - D)
        --local V1 = ad.Vector(L.Select(a(2),L1-D,1), L.Select(a(2),a(2),0))
        --local V2 = ad.Vector(L.Select(a(2),L2-D,1), L.Select(a(2),a(2),0))
        --V1 = ad.Vector(L.Select(a(1),a(1),V1(0)), L.Select(a(1),L1-a(0),V1(1)))
        --V2 = ad.Vector(L.Select(a(1),a(1),V2(0)), L.Select(a(1),L2-a(0),V2(1)))
        local V1 = ad.Vector(L1-D,a(2))
        local V2 = ad.Vector(L2-D,a(2))
        return {V1,V2,L1,L2}
    end

    return L
end
