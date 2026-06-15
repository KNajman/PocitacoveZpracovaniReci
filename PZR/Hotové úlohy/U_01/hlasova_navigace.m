%Načtení audio nahrávek
[y, Fs1] = audioread('audio/pokyny.wav');
[one_to_nine, Fs2] = audioread('audio/1_9.wav');
[ten_to_fivehundred, Fs3] = audioread('audio/10_500.wav');

%kontrola zda jsou všechny soubory načteny
if (isempty(y) || isempty(one_to_nine) || isempty(ten_to_fivehundred))
    error('Soubor pokyny.wav nebyl nalezen nebo je poškozený.');
end

%Zajištění stejné vzorkovací frekvence
[y, Fs1] = audioread('audio/pokyny.wav');
[one_to_nine, Fs2] = audioread('audio/1_9.wav');
[ten_to_fivehundred, Fs3] = audioread('audio/10_500.wav');

if ~(Fs1 == Fs2 && Fs2 == Fs3)
    error('Vzorkovací frekvence souborů se neshodují!');
end
Fs = Fs1;
clear Fs1 Fs2 Fs3;

commands = struct( ...
    'vlevo', y(1:1*Fs,:), ...
    'vpravo', y(1*Fs:2.5*Fs,:), ...
    'se_drzte', y(2.5*Fs:3.5*Fs,:), ...
    'kruhovem_objezdu', y(4*Fs:5.6*Fs,:), ...
    'za', y(6*Fs:6.6*Fs,:), ...
    'na', y(7*Fs:7.6*Fs,:), ...
    'metru', y(8*Fs:9*Fs,:), ...
    'kilometru', y(9.5*Fs:10.7*Fs,:), ...
    'odbocte', y(11*Fs:11.9*Fs,:), ...
    'mirne', y(12.5*Fs:13.4*Fs,:), ...
    'pokracujte', y(14*Fs:15.3*Fs,:), ...
    'rovne', y(15.5*Fs:16.4*Fs,:), ...
    'musite_se_otocit', y(17*Fs:end,:) ...
);

times = [0.1 1.0; 1.6 2.5; 3 3.5; 4.5 5.3; 6 6.7; 7.2 7.9; 8.5 9.4; 10 10.7; 11 length(one_to_nine)/Fs]; % [start end] pro každé číslo

for i = 1:size(times,1)
    start_sample = round(times(i,1) * Fs);
    end_sample = min(round(times(i,2) * Fs), length(one_to_nine)); % Ochrana proti přetečení
    numbers{i} = one_to_nine(start_sample:end_sample, :);
end

times = [0.1 1.5;1.7 3; 3 4; 4.1 5; 5.2 6.5; 6.6 length(ten_to_fivehundred)/Fs];

for i = 1:size(times,1)
    start_sample = round(times(i,1) * Fs);
    end_sample = min(round(times(i,2) * Fs), length(ten_to_fivehundred)); % Ochrana proti přetečení
    bigger_numbers{i} = ten_to_fivehundred(start_sample:end_sample, :);
end

sound([commands.za; bigger_numbers{4}; bigger_numbers{3}; numbers{2}; commands.metru; commands.na; commands.kruhovem_objezdu; commands.se_drzte; commands.vpravo], Fs);
% pause(8);
% sound([za; numbers{5}; kilometru; odbocte; vlevo; pokracujte; rovne], Fs);