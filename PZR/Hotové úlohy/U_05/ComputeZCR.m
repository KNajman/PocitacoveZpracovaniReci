function z = ComputeZCR(signal)
    z = (1/2) * sum(abs(diff(sign(signal))));
end