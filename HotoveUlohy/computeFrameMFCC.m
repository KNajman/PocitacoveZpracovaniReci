function [cep_coeff, mel_fbank] = computeFrameMFCC(frame, N, M, Fs)
% vypoèítá N pøíznakù Fbank a M pøíznakù MFCC pro jeden frame øeèi
% typické hodnoty N=26, M=12, Fs=16000, frame 25 ms
m_low=0;                %spodní limit mel-stupnice
m_top=f2mel(Fs/2);      %horní limit mel-stupnice
mdiv=(m_top-m_low)/(N-1);   % rozdìlení na N pásem v mel stupnici
xm=m_low:mdiv:m_top;  % støední frekvence každého pásma
xf=mel2f(xm); % støední frekvence pøevedené zpìt na Hertze
xq = floor((length(frame)/2 + 1)*xf/(Fs/2));
S=fft(frame); % výpoèet FFT pro signál ve frame
S=abs(2*(S.*S)/length(S)); % výpoèet energie (kvadrátu) každé složky
S=S(1:length(S)/2); % výbìr první poloviny hodnot
F=(1:length(S))*(Fs/2)/length(S);  % výdìlení poètem vzorkù
x1=zeros(1,N);
for xi=1:N    % cyklus pro všechna pásma
    band=spread_mel(xf,xi,length(S),Fs/2); % trojúhelníková funkce
    x1(xi)=sum(band.*S');   % výpoèet energie v pásmu
end
x=log(x1);   % výpoèet logaritmu energie všech pásem
mel_fbank = x;  % mel-spektr. pøíznaky spoèítány
cep_coeff=zeros(1,M);
for xc=1:M   % disktrétní kosinová transformace
    cep_coeff(xc)=sqrt(2/N)*sum(x.*cos(pi*xc*((1:N)-0.5)/N));
end
%%
function [mel]=f2mel(f)
mel=2595 * log10(1+f/700);
%%
function [hz]=mel2f(mel)
hz=700*(10.^(mel/2595)-1);
%%
function band=spread_mel(hz_points,hz_c,hz_size,hz_max)
%hz_array is an array spaced in hz
%hz_c is the current index
band=zeros(1, hz_size);
hz1=hz_points(max(1,hz_c-1));                 %start
hz2=hz_points(hz_c);                          %middle
hz3=hz_points(min(length(hz_points),hz_c+1)); %end
%-----
for hi=1:hz_size
    hz=hi*hz_max/hz_size;
    if hz > hz3
        band(hi)=0;
    elseif hz>=hz2
        band(hi)=(hz3-hz)/(hz3-hz2);
    elseif hz>=hz1
        band(hi)=(hz-hz1)/(hz2-hz1);
    else
        band(hi)=0;
    end
end