###################### OTS Constraints ############################
"""
```
sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(pconv_dc[c] for c in bus_convs_dc) == pd
```
"""
function constraint_power_balance_dc_ots(pm::_PM.AbstractPowerModel, n::Int, i::Int, bus_arcs_dcgrid, bus_convs_dc, pd)
    p_dcgrid = _PM.var(pm, n, :p_dcgrid)
    pconv_dc = _PM.var(pm, n, :pconv_dc)
    z = _PM.var(pm, n, :z_ots_dc, i) 
    JuMP.@constraint(pm.model, sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(pconv_dc[c] for c in bus_convs_dc) == (-pd))
end

function constraint_converter_limit_on_off_dc_ots(pm::_PM.AbstractPowerModel, n::Int, i, pmax, pmin, qmax, qmin, pmaxdc, pmindc, imax)
    pconv_ac = _PM.var(pm, n, :pconv_ac)[i]
    pconv_dc = _PM.var(pm, n, :pconv_dc)[i]
    pconv_tf_fr = _PM.var(pm, n, :pconv_tf_fr)[i]
    pconv_tf_to = _PM.var(pm, n, :pconv_tf_to)[i]
    pconv_pr_fr = _PM.var(pm, n, :pconv_pr_fr)[i]
    
    qconv_ac = _PM.var(pm, n, :qconv_ac)[i]
    qconv_tf_fr = _PM.var(pm, n, :qconv_tf_fr)[i]
    qconv_tf_to = _PM.var(pm, n, :qconv_tf_to)[i]
    qconv_pr_fr = _PM.var(pm, n, :qconv_pr_fr)[i]
    iconv_ac = _PM.var(pm, n, :iconv_ac)[i]
    #vmc = _PM.var(pm, n, :vmc, i)
    #vmf = _PM.var(pm, n, :vmf, i)

    z_dc = _PM.var(pm, n, :z_conv_dc, i)

    JuMP.@constraint(pm.model,  pconv_ac <= pmax * z_dc)
    JuMP.@constraint(pm.model,  pconv_ac >= pmin * z_dc)
    JuMP.@constraint(pm.model,  pconv_dc <= pmaxdc * z_dc)
    JuMP.@constraint(pm.model,  pconv_dc >= pmindc * z_dc)
    JuMP.@constraint(pm.model,  pconv_tf_fr <= pmax * z_dc)
    JuMP.@constraint(pm.model,  pconv_tf_fr >= pmin * z_dc)
    JuMP.@constraint(pm.model,  pconv_tf_to <= pmax * z_dc)
    JuMP.@constraint(pm.model,  pconv_tf_to >= pmin * z_dc)
    JuMP.@constraint(pm.model,  pconv_pr_fr <= pmax * z_dc)
    JuMP.@constraint(pm.model,  pconv_pr_fr >= pmin * z_dc)
    
    JuMP.@constraint(pm.model,  qconv_ac <= qmax * z_dc)
    JuMP.@constraint(pm.model,  qconv_ac >= qmin * z_dc)
    JuMP.@constraint(pm.model,  qconv_tf_fr <= qmax * z_dc)
    JuMP.@constraint(pm.model,  qconv_tf_fr >= qmin * z_dc)
    JuMP.@constraint(pm.model,  qconv_tf_to <= qmax * z_dc)
    JuMP.@constraint(pm.model,  qconv_tf_to >= qmin * z_dc)
    JuMP.@constraint(pm.model,  qconv_pr_fr <= qmax * z_dc)
    JuMP.@constraint(pm.model,  qconv_pr_fr >= qmin * z_dc)
    JuMP.@constraint(pm.model,  iconv_ac <= imax * z_dc )

end

function constraint_branch_limit_on_off_dc_ots(pm::_PM.AbstractPowerModel, n::Int, i, f_idx, t_idx, pmax, pmin, imax, imin)
    p_fr = _PM.var(pm, n, :p_dcgrid)[f_idx]
    p_to = _PM.var(pm, n, :p_dcgrid)[t_idx]
    z = _PM.var(pm, n, :z_ots_dc, i)

    JuMP.@constraint(pm.model,  p_fr <= pmax * z)
    JuMP.@constraint(pm.model,  p_fr >= pmin * z)
    JuMP.@constraint(pm.model,  p_to <= pmax * z)
    JuMP.@constraint(pm.model,  p_to >= pmin * z)
end

function constraint_linearised_binary_variable(pm::_PM.AbstractPowerModel, n::Int, i, csi)
    z = _PM.var(pm, n, :z_branch, i)
    JuMP.@NLconstraint(pm.model,  z*(1-z) <= csi)
end

###################### Busbar Splitting Constraints ############################

# From PowerModels.jl
function constraint_switch_thermal_limit(pm::_PM.AbstractPowerModel, n::Int, f_idx, rating)
    psw = _PM.var(pm, n, :psw, f_idx)
    qsw = _PM.var(pm, n, :qsw, f_idx)

    JuMP.@constraint(pm.model, psw^2 + qsw^2 <= rating^2)
end

function constraint_dc_switch_thermal_limit(pm::_PM.AbstractPowerModel, n::Int, f_idx, rating)
    psw = _PM.var(pm, n, :p_dc_sw, f_idx)

    JuMP.@constraint(pm.model, psw <= rating)
end



function constraint_dc_switch_voltage_on_off(pm::_PM.AbstractPowerModel, n::Int, i, f_bus, t_bus, vad_min, vad_max)
    vm_fr = _PM.var(pm, n, :vdcm, f_busdc)
    vm_to = _PM.var(pm, n, :vdcm, t_busdc)
    z = _PM.var(pm, n, :z_dcswitch, i)

    JuMP.@constraint(pm.model, z*vm_fr == z*vm_to)
end



function constraint_dc_switch_state_open(pm::_PM.AbstractPowerModel, n::Int, f_idx)
    psw = _PM.var(pm, n, :psw, f_idx)

    JuMP.@constraint(pm.model, psw == 0.0)
end


""
function constraint_dc_switch_power_on_off(pm::_PM.AbstractPowerModel, n::Int, i, f_idx)
    psw = _PM.var(pm, n, :p_dc_sw, f_idx)
    z = _PM.var(pm, n, :z_dcswitch, i)

    psw_lb, psw_ub = _IM.variable_domain(psw)

    JuMP.@constraint(pm.model, psw <= psw_ub*z)
    JuMP.@constraint(pm.model, psw >= psw_lb*z)
end


function constraint_switch_power_on_off(pm::_PM.AbstractPowerModel, n::Int, i, f_idx)
    psw = _PM.var(pm, n, :psw, f_idx)
    qsw = _PM.var(pm, n, :qsw, f_idx)
    z = _PM.var(pm, n, :z_switch, i)

    psw_lb, psw_ub = _IM.variable_domain(psw)
    qsw_lb, qsw_ub = _IM.variable_domain(qsw)

    JuMP.@constraint(pm.model, psw <= psw_ub*z)
    JuMP.@constraint(pm.model, psw >= psw_lb*z)
    JuMP.@constraint(pm.model, qsw <= qsw_ub*z)
    JuMP.@constraint(pm.model, qsw >= qsw_lb*z)
end



function constraint_exclusivity_switch(pm::_PM.AbstractPowerModel, n::Int, i_1, i_2)
    z_1 = _PM.var(pm, n, :z_switch, i_1)
    z_2 = _PM.var(pm, n, :z_switch, i_2)
    
    JuMP.@constraint(pm.model, z_1 + z_2 <= 1.0)
end

function constraint_exclusivity_switch_no_OTS(pm::_PM.AbstractPowerModel, n::Int, i_1, i_2, i_3)
    z_1 = _PM.var(pm, n, :z_switch, i_1)
    z_2 = _PM.var(pm, n, :z_switch, i_2)
    
    JuMP.@constraint(pm.model, z_1 + z_2 == 1.0)
end

function constraint_voltage_angles_switch(pm::_PM.AbstractPowerModel, n::Int, i_1,bus_1, bus_2)
    #z_1 = _PM.var(pm, n, :z_switch, i_1)
    #z_2 = _PM.var(pm, n, :z_switch, i_2)
    z_ZIL = _PM.var(pm, n, :z_switch, i_1)
    va_1 = _PM.var(pm, n, :va, bus_1)
    vm_1 = _PM.var(pm, n, :vm, bus_1)
    va_2 = _PM.var(pm, n, :va, bus_2)
    vm_2 = _PM.var(pm, n, :vm, bus_2)
    

    JuMP.@constraint(pm.model,(va_1 - va_2) <= 100*(1 - z_ZIL))
    JuMP.@constraint(pm.model,-100*(1 - z_ZIL) <= va_1 - va_2)
    JuMP.@constraint(pm.model, vm_1 - vm_2 <= 100*(1 - z_ZIL))
    JuMP.@constraint(pm.model, -100*(1 - z_ZIL) <= vm_1 - vm_2)

    #JuMP.@constraint(pm.model, z_ZIL*va_1 == z_ZIL*va_2)
    #JuMP.@constraint(pm.model, z_ZIL*vm_1 == z_ZIL*vm_2)
end

function constraint_voltage_angles_dc_switch(pm::_PM.AbstractPowerModel, n::Int, i_1, i_2, i_3, bus_1, bus_2)
    z_1 = _PM.var(pm, n, :z_dcswitch, i_1)
    z_2 = _PM.var(pm, n, :z_dcswitch, i_2)
    z_ZIL = _PM.var(pm, n, :z_dcswitch, i_3)
    vm_1 = _PM.var(pm, n, :vdcm, bus_1)
    vm_2 = _PM.var(pm, n, :vdcm, bus_2)
    
    JuMP.@constraint(pm.model, vm_1 == vm_2)
end

function constraint_exclusivity_dc_switch(pm::_PM.AbstractPowerModel, n::Int, i_1, i_2)
    z_1 = _PM.var(pm, n, :z_dcswitch, i_1)
    z_2 = _PM.var(pm, n, :z_dcswitch, i_2)
 
    JuMP.@constraint(pm.model, z_1 + z_2 <= 1.0)
end

function constraint_exclusivity_dc_switch_no_OTS(pm::_PM.AbstractPowerModel, n::Int, i_1, i_2, i_3)
    z_1 = _PM.var(pm, n, :z_dcswitch, i_1)
    z_2 = _PM.var(pm, n, :z_dcswitch, i_2)
    
    JuMP.@constraint(pm.model, z_1 + z_2 == 1.0)
end

function constraint_BS_OTS_branch(pm::_PM.AbstractPowerModel, n::Int,i_1, i_2, pf, pt, qf, qt ,sw,aux)
    z_1 = _PM.var(pm, n, :z_switch, i_1)
    z_2 = _PM.var(pm, n, :z_switch, i_2)
    pf_ = _PM.var(pm, n, :p, pf)
    pt_ = _PM.var(pm, n, :p, pt)
    qf_ = _PM.var(pm, n, :q, qf)
    qt_ = _PM.var(pm, n, :q, qt)

    JuMP.@constraint(pm.model, pf_ <= (z_1+z_2)*100)
    JuMP.@constraint(pm.model, pt_ <= (z_1+z_2)*100)
    JuMP.@constraint(pm.model, qf_ <= (z_1+z_2)*100)
    JuMP.@constraint(pm.model, qt_ <= (z_1+z_2)*100)
    JuMP.@constraint(pm.model, - (z_1+z_2)*100 <= pf_)
    JuMP.@constraint(pm.model, - (z_1+z_2)*100 <= pt_)
    JuMP.@constraint(pm.model, - (z_1+z_2)*100 <= qf_)
    JuMP.@constraint(pm.model, - (z_1+z_2)*100 <= qt_)

end

function constraint_BS_OTS_dcbranch(pm::_PM.AbstractPowerModel, n::Int,i_1, i_2, pf, pt, qf, qt ,sw,aux)
    z_1 = _PM.var(pm, n, :z_dcswitch, i_1)
    z_2 = _PM.var(pm, n, :z_dcswitch, i_2)
    pf_ = _PM.var(pm, n, :p_dcgrid, pf)
    pt_ = _PM.var(pm, n, :p_dcgrid, pt)

    JuMP.@constraint(pm.model, pf_ <= (z_1+z_2)*100)
    JuMP.@constraint(pm.model, pt_ <= (z_1+z_2)*100)
    JuMP.@constraint(pm.model, - (z_1+z_2)*100 <= pf_)
    JuMP.@constraint(pm.model, - (z_1+z_2)*100 <= pt_)
end

function constraint_power_balance_dc_switch(pm::_PM.AbstractPowerModel, n::Int, i::Int, bus_arcs_dcgrid, bus_convs_dc, bus_arcs_sw_dc, pd)
    p_dcgrid = _PM.var(pm, n, :p_dcgrid)
    pconv_dc = _PM.var(pm, n, :pconv_dc)
    psw = _PM.var(pm, n, :p_dc_sw)
    JuMP.@constraint(pm.model, sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(pconv_dc[c] for c in bus_convs_dc) + sum(psw[sw] for sw in bus_arcs_sw_dc) == (-pd))
end



