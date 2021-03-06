function [bWC, zmax] = isWrenchCompensate(CW, w0)
% CW: a set of normalized contact screws 3xn
% w0: the wrench we want to provide, such as " -mg"

    w0 = w0./norm(w0(1:2),2);
%    CW = CW./vecnorm(CW(1:2,:),2,1);
    
    N = size(CW,2);
    Wc = sum(CW,2)/N;
    TW = -Wc;%w0-Wc;
    T= CW - Wc;

    [y,fval] = linprog(-TW,T',ones(N,1));
    zmax = -fval;
    if zmax <=1
        bWC = true;
    else 
        bWC = false;
    end
end