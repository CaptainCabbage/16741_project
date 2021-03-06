function [CPF, CNF] = friction_cone(CP, CN, friction_coeff)

N = size(CP,2);
M=3;
CPF = zeros(2, M*N);
CNF = zeros(2,M*N);
d = [1,1,1;friction_coeff,-friction_coeff,0];
for i = 1:N
    Ri = computeRotMat(CN(:,i));
    CNF(:,((i-1)*M+1):i*M) = Ri*d;
    CNF(:,((i-1)*M+1):i*M) = CNF(:,((i-1)*M+1):i*M)./vecnorm(CNF(:,((i-1)*M+1):i*M),2,1);
    CPF(:, ((i-1)*M+1):i*M) = CP(:,i).*ones(2,M);
end