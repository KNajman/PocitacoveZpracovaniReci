function [distance] = FastDTW(X, I, R, J)
% Optimalizovaná verze Dynamic Time Warping (DTW) s omezením pásma a nízkou paměťovou náročností

% Předčasné ukončení, pokud jsou sekvence příliš rozdílné
if abs(I - J) * 2 > max(I, J)
    distance = inf;
    return;
end

% Pouze jednorozměrné pole
A = inf(1, J + 2);
wasAhorizontal = zeros(1, J + 2);

% Inicializace první hodnoty
A(1 + 2) = dist(X(1,:), R(1,:));

w=1;
% Výpočet pouze v omezeném pásmu
for i = 2:I
    w=max(w,abs(I - J));
    jmin=max(1,i - w);
    jmax=min(J,i + w);
    % Dynamické omezení pásma
    for j = jmax:-1:jmin %jdeme od zhora dolů -1
        jj = j + 2;  % Posun indexu
        temp = A(jj - 2);

        if temp > A(jj - 1)
            temp = A(jj - 1);
        end

        if wasAhorizontal(jj)==0 && A(jj) < temp
            wasAhorizontal(jj) = 1;
            temp = A(jj);
        else
            wasAhorizontal(jj) = 0;
        end
        A(jj) = temp + dist(X(i,:), R(j,:));% Výpočet lokální hodnoty
    end
    A(jmin +2 -1) = inf;% Nastavení posledního prvku na inf pro reset pásma
end

% Výsledek
distance = A(J + 2);
end

function distance = dist(X,R)
    distance=sum((X-R).^2);
end