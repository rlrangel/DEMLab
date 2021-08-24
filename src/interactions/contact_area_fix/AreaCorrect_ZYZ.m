%% AreaCorrect_ZYZ class
%
%% Description
%
% This is a sub-class of the <areacorrect.html AreaCorrect> class for the
% implementation of the *Zhou, Yu, Zulli* contact area correction model.
%
% This model computes the reduced radius of the contact area by applying
% a correction coefficient derived for the Hertz model:
%
% $$R_{c}' = \left(\frac{E_{eff}}{E_{eff,0}}\right)^{1/5}R_{c}$$
%
% Where:
%
% $R_{c}'$: Reduced radius of contact area
%
% $R_{c}$: Contact area radius originally computed in the simulation
%
% $E_{eff}$: Effective Young modulus with the modified value
%
% $E_{eff,0}$: Effective Young modulus with the real value
%
% *References*:
%
% * <https://doi.org/10.1016/j.powtec.2009.09.002
% Z.Y. Zhou, A.B. Yu and P. Zulli.
% A new computational method for studying heat transfer in fluid bed reactors, _Powder Technol._, 197(1-2):102-110, 2010>
%
classdef AreaCorrect_ZYZ < AreaCorrect
    %% Constructor method
    methods
        function this = AreaCorrect_ZYZ()
            this = this@AreaCorrect(AreaCorrect.ZYZ);
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = fixRadius(this,int)
            int.kinemat.contact_radius = (int.eff_young/int.eff_young0)^(1/5) * int.kinemat.contact_radius;
        end
    end
end