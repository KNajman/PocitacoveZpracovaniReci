% Skript pro pripravu testovacich dat
slozkaWAV = 'test_wav'; % musí existovat
slozkaParam = 'test_param'; % existuje nebo bude vytvořena
paramType = 'mfc'; % buď mfc nebo fbank

% Vytvoření cílové složky
if ~exist(slozkaParam, 'dir')
    mkdir(slozkaParam);
end

% Nalezení všech WAV souborů
wavFiles = dir(fullfile(slozkaWAV, '*.wav'));

% Otevření souborů pro zápis s kontrolou
f_hcopy = fopen('test_param.list', 'w');
if f_hcopy == -1
    error('Nepodařilo se vytvořit soubor test_param.list. Zkontroluj oprávnění.');
end

f_scp = fopen('test.scp', 'w');
if f_scp == -1
    fclose(f_hcopy); % Bezpečně zavřeme předchozí soubor, než vyhodíme chybu
    error('Nepodařilo se vytvořit soubor test.scp. Zkontroluj oprávnění.');
end

for i = 1:length(wavFiles)
    wavName = wavFiles(i).name;
    
    % Bezpečné získání názvu bez přípony
    [~, baseName, ~] = fileparts(wavName);
    
    % Zápis pro HCopy (převod z WAV do parametrizace)
    fprintf(f_hcopy, '%s/%s %s/%s.%s\n', slozkaWAV, wavName, slozkaParam, baseName, paramType);
    
    % Zápis pro HVite (seznam parametrizovaných souborů pro rozpoznání)
    fprintf(f_scp, '%s/%s.%s\n', slozkaParam, baseName, paramType);
end

fclose(f_hcopy); 
fclose(f_scp);
disp('Hotovo! Soubory test_param.list a test.scp byly uspesne vytvoreny.');