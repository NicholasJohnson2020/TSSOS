# include("D:\\Programs\\TSSOS\\src\\TSSOS.jl")
using TSSOS
# You need to add the package PowerModels.
include("D:\\Programs\\TSSOS\\example\\modelopf.jl")

# You need to download the problem data from PGLiB (https://github.com/power-grid-lib/pglib-opf) first.
cd("D:\\Programs\\PolyOPF\\pglib")

silence()

case = "pglib_opf_case240_pserc"
AC = 3.3297e6
opfdata = parse_file(case * ".m")

# the first order relaxation
model,_ = pop_opf_real(opfdata, normal=true, AngleCons=true, LineLimit="relax")
n = model.n
m = model.m
numeq = model.numeq
supp = model.supp
coe = model.coe
mc = maximum(abs.(coe[1]))
coe[1]=coe[1]./mc

time = @elapsed begin
opt,sol,popd = cs_tssos_first(supp, coe, n, 1, numeq=numeq, CS=false, TS="MF", MomentOne=false)
end
opt *= mc
mb = maximum(maximum.(popd.sb)) # maximal block size
gap = (AC-opt)*100/AC # optimality gap
println("n = $n, m = $m")
println("opt = $opt, time = $time, mb = $mb, gap = $gap%")

# the minimum order relaxation
model,_ = pop_opf_real(opfdata, normal=true, AngleCons=true, LineLimit=true)
n = model.n
m = model.m
numeq = model.numeq
supp = model.supp
coe = model.coe
mc = maximum(abs.(coe[1]))
coe[1] = coe[1]./mc

time = @elapsed begin
opt,sol,popd = cs_tssos_first(supp, coe, n, "min", numeq=numeq, CS="MF", TS="block", MomentOne=true)
end
opt *= mc
maxc = maximum(popd.cliquesize) # maximal clique size
mb = maximum(maximum.(popd.sb)) # maximal block size
gap = 100*(AC-opt)/AC # optimality gap
println("n = $n, m = $m")
println("mc = $maxc, opt = $opt, time = $time, mb = $mb, gap = $gap%")
