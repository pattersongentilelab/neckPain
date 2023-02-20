function [CI] = ExpCalc95fromSE(predicted,se)

CI(1) = exp(predicted);
CI(2) = exp(predicted - (1.96*se));
CI(3) = exp(predicted + (1.96*se));
end