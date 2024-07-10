function [F, jacF] = squaredFun(pe,x)

F = nan(size(x));
lowXInd = find(x(:) <= -pe(2) / pe(3) / 2);
F = pe(1) + pe(2) .* x + pe(3) .* x.^2;
F(lowXInd) = pe(1) - pe(2)^2 / 4 / pe(3);

if nargout > 1
    jacF = [(ones(size(x)))' ...
            (exp(pe(3) * x))' ...
            (pe(2) .* x .* exp(pe(3) * x))'];
    jacF(lowXInd,:) = repmat([1 ...
                              -pe(2) / pe(3) / 2 ...
                              pe(2)^2 / pe(3)^2 / 4],[length(lowXInd) 1]);
end
