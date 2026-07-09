% Skript pro chytré nahrávání izolovaných slov pro HTK
% (Načítá slova dynamicky z wlist a detekuje řeč)

% --- NAČTENÍ SLOV Z WLISTU ---
if ~exist('wlist', 'file')
    error('Soubor wlist nebyl nalezen!');
end

fid = fopen('wlist', 'r');
nactenaData = textscan(fid, '%s');
fclose(fid);
vsechnaSlova = nactenaData{1};

% Odfiltrování systémových značek (SENT-START, SENT-END, případně sil)
slova = {};
for i = 1:length(vsechnaSlova)
    slovo = vsechnaSlova{i};
    if ~strcmp(slovo, 'SENT-START') && ~strcmp(slovo, 'SENT-END') && ~strcmp(slovo, 'sil')
        slova{end+1} = slovo;
    end
end
% -----------------------------

pocetOpakovani = 7; % 5 pro trénink, 2 pro testování
fs = 16000; % 16 kHz
nBits = 16; % 16 bitů
nChannels = 1; % Mono
delkaZaznamu = 2.0; % 2 vteřiny
jmeno_recnika = "Karel2";

% Vytvoření složek
if ~exist('nahravky_wav', 'dir'), mkdir('nahravky_wav'); end
if ~exist('test_wav', 'dir'), mkdir('test_wav'); end

fprintf('Nalezeno %d slov k nahrani.\n', length(slova));
disp('Začínáme nahrávat! Připravte si mikrofon.');
pause(2);

% Krátký pípák (100 ms sinusovka) pro jasný signál
t_beep = 0:1/fs:0.1;
beep_sound = 0.5 * sin(2 * pi * 1000 * t_beep);

for i = 1:length(slova)
    slovo = slova{i};
    disp(['--- Jdeme na slovo: ', slovo, ' ---']);
    pause(1);

    j = 1;
    while j <= pocetOpakovani
        if j <= 5
            typ_nahravky = 'TRAIN';
            cilova_slozka = 'nahravky_wav';
        else
            typ_nahravky = 'TEST';
            cilova_slozka = 'test_wav';
        end

        fprintf('[%s] Řekni "%s" (%d/%d)... ', typ_nahravky, slovo, j, pocetOpakovani);

        recObj = audiorecorder(fs, nBits, nChannels);

        % Pípnutí, po kterém máš chvilku počkat a pak mluvit
        sound(beep_sound, fs);
        pause(0.15);

        % Nahrávání (2 vteřiny)
        recordblocking(recObj, delkaZaznamu);

        % Získání dat a normalizace hlasitosti
        y = getaudiodata(recObj);
        y = y / max(abs(y));

        % --- DETEKCE ŘEČI (VAD - Voice Activity Detection) ---
        win_len = round(fs * 0.05);
        energie = movmean(y.^2, win_len);

        % Prahování (5 % z maximální energie v nahrávce)
        prah = max(energie) * 0.05;
        speech_idx = find(energie > prah);

        if isempty(speech_idx)
            disp('CHYBA: Nic nebylo slyšet. Zkus to znovu.');
            continue;
        end

        start_idx = speech_idx(1);
        end_idx = speech_idx(end);

        % KONTROLA 1: Začal jsi mluvit moc brzy? (před 0.25 s)
        if start_idx < 0.25 * fs
            disp('CHYBA: Mluvil jsi moc brzy! Počkej po pípnutí. Zkus to znovu.');
            continue;
        end

        % KONTROLA 2: Neuseklo se slovo na konci?
        if end_idx > length(y) - 0.1 * fs
            disp('CHYBA: Slovo se na konci useklo. Mluv o něco rychleji. Zkus to znovu.');
            continue;
        end

        % --- OŘÍZNUTÍ A PŘIDÁNÍ TICHA ---
        % 150 ms ticha před a za slovo pro modely "sil"
        margin = round(0.15 * fs);
        start_cut = max(1, start_idx - margin);
        end_cut = min(length(y), end_idx + margin);

        y_final = y(start_cut:end_cut);

        % Uložení
        nazevSouboru = sprintf('%s/%s_%s_%02d.wav', cilova_slozka, jmeno_recnika, lower(slovo), j);
        audiowrite(nazevSouboru, y_final, fs);
        disp('OK.');

        j = j + 1;
        pause(0.5);
    end
end

disp('Všechna slova úspěšně nahrána a automaticky oříznuta!');