W,H = Dim("W",0), Dim("H",1)
X = Unknown("X",float,{W,H},0)
A = Array("A",float,{W,H},1)
w_fit = 1000.2
Energy(w_fit*(X(0,0) - A(0,0))) --fitting
E = X(0,0)*X(0,0)-X(1,0)*X(1,0)
B = ComputedArray("B",{W,H},E)
Energy(B(0,0), --regularization
(X(0,0) - X(0,1)))
