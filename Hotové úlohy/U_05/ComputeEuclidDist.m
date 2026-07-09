function distance = ComputeEuclidDist(X, R)
% Funkce počítá euklidovskou vzdálenost mezi dvěma sekvencemi X a R.
% Vstupy:
%   X - matice rozměru (P × T) obsahující první sekvenci
%   R - matice rozměru (P × T) obsahující druhou sekvenci
%
% Výstup:
%   distance - euklidovská vzdálenost mezi sekvencemi X a R

distance = norm(X-R);
end
