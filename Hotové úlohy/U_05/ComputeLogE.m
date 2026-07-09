function E = ComputeLogE(signal)
    E = log(sum(signal .^ 2));
end