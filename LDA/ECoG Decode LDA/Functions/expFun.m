function [F, jacF] = expFun(pe,x)

F = pe(1) + pe(2)*exp(pe(3) * x);

if nargout > 1
    jacF = [(ones(size(x)))' ...
            (exp(pe(3) * x))' ...
            (pe(2) .* x .* exp(pe(3) * x))'];
end
