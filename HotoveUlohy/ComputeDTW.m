% function [distance,path] = ComputeDTW(X, I, R, J)
% % Funkce pro výpočet délky pomocí Dynamic Time Warping
% % X je sekvence příznakových vektorů slova s I framy
% % R je sekvence příznakových vektorů reference s J framy
%
% % Předčasné ukončení, pokud jsou sekvence příliš rozdílné
% if abs(I - J) > max(I, J) * 0.5
%     distance = inf;
%     % path = [];
%     return;
% end
%
% A = inf(I, J);
% B = zeros(I, J);
%
% % Počáteční vzdálenost
% A(1, 1) = ComputeEuclidDist(X(1,:), R(1,:));
% % B(1, 1) = 0;
%
% % Rekurzní — výpočet akumulovaných vzdáleností
% for i = 2:I
%     for j = 1:J
%
%         % Podmínky pro nastavení hodnot k=(j,j-1,j-2)
%         O = [A(i-1, j), inf, inf];
%         if j > 1
%             O(2) = A(i-1, j-1);
%         end
%         if j > 2
%             O(3) = A(i-1, j-2);
%
%             if B(i-1, j) == j
%                 O(1) = inf;
%             end
%         end
%
%         [min_val, min_idx] = min(A(i-1,j),A(i-1,j-1,A(i-1,j-2))
%         A(i, j) = ComputeEuclidDist(X(i,:), R(j,:)) + min_val;
%         B(i, j) = j - (min_idx - 1);
%     end
% end
% % Globální vzdálenost
% distance = A(I, J);
%
% % %Rekurzivní rekonstrukce cesty
% path=zeros(1,I);
% path(I) = J;
% for i = I - 1:-1:1
%     path(i) = B(i + 1, path(i + 1));
% end
% end
% %%
% function [distance, path] = ComputeDTW(X, I, R, J)
% % Optimalizovaný výpočet Dynamic Time Warping s omezením pásma
%
% % Parametry pro omezení hledání optimální cesty (Sakoe-Chiba pásmo)
% band = round(max(I, J) * 0.2);  % Např. 10% délky jako maximální odchylka
%
% % Předčasné ukončení, pokud jsou sekvence příliš rozdílné
% if abs(I - J) > max(I, J) * 0.5
%     distance = inf;
%     return;
% end
%
% A = inf(I, J);  % Matice akumulovaných vzdáleností
% B = zeros(I, J); % Matice zpětného sledování
%
% % Inicializace první buňky
% A(1,1) = ComputeEuclidDist(X(1,:),R(1,:));
%
% % Výpočet akumulovaných vzdáleností pouze v pásmu
% for i = 2:I
%     for j = max(1, i - band):min(J, i + band)  % Omezení výpočtu na diagonální pásmo
%         % Možnosti předchozího kroku
%         O = [A(i-1, j)];
%         if j > 1, O(2) = A(i-1, j-1); end
%         if j > 2, O(3) = A(i-1, j-2);
%             if B(i-1, j) == j
%                 O(1) = inf;
%             end
%         end
%
%         [min_val, min_idx] = min(O);
%
%         % Výpočet euklidovské vzdálenosti pouze v omezeném pásmu
%         A(i, j) = ComputeEuclidDist(X(i,:),R(j,:)) + min_val;
%         B(i, j) = j - (min_idx - 1);
%     end
% end
%
% % Globální DTW vzdálenost
% distance = A(I, J);
%
% % Rekonstrukce optimální cesty zpětným sledováním
% path = zeros(1, I);
% path(I) = J;
% for i = I-1:-1:1
%     path(i) = B(i + 1, path(i + 1));
% end
%
% end


function [distance] = ComputeDTW(X, I, R, J)
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
A(1 + 2) = ComputeEuclidDist(X(1,:), R(1,:));

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
        A(jj) = temp + ComputeEuclidDist(X(i,:), R(j,:));% Výpočet lokální hodnoty
    end
    A(jmin +2 -1) = inf;% Nastavení posledního prvku na inf pro reset pásma
end

% Výsledek
distance = A(J + 2);
end

