function [distance] = ComputeLTW(X, I, R, J)
% Funkce pro výpočet vzdálenosti pomocí Linear Time Warping (LTW)
% kde:
%   X - vstupní sekvence s I framy (matice I × P)
%   R - referenční sekvence s J framy (matice J × P)
%   P - počet příznaků (sloupců v matici)
%
% Výstup:
%   distance - euklidovská vzdálenost mezi sekvencemi po LTW

    % Inicializace váhového mapování
    path = zeros(1, I);
    
    % Vytvoření mapy indexů pro časové zarovnání
    for i = 1:I
        path(i) = round(((J - 1) / (I - 1)) *(i-1) + 1);  % Mapování do referenční sekvence
    end
    
    % Výpočet vzdálenosti pomocí euklidovské metriky
    Y=(R(path));
    X=(X);
    distance = ComputeEuclidDist(X, Y);
end