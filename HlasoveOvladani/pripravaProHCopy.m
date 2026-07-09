% Skript pro generování seznamu k parametrizaci
fileWithWAV = 'nahravky_wav';
fileParam = 'nahravky_param'; % Zde se uloží výsledky
paramType = 'mfc'; % buď mfc nebo fbank

if ~exist(fileParam, 'dir')
    mkdir(fileParam);
end

% Nalezení všech WAV souborů
wavFiles = dir(fullfile(fileWithWAV, '*.wav'));

% Otevření souboru s kontrolou
fileID = fopen('param.list', 'w'); % 

for i = 1:length(wavFiles)
    wavName = wavFiles(i).name;
    
    % Bezpečné získání názvu bez přípony
    [~, baseName, ~] = fileparts(wavName); 
    
    % Zápis do souboru: "zdrojovy_wav cilovy_param"
    fprintf(fileID, '%s/%s %s/%s.%s\n', fileWithWAV, wavName, fileParam, baseName, paramType);
end

fclose(fileID);
disp('Soubor param.list je uspesne vygenerovan.');