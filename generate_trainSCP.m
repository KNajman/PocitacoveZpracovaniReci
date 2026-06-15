% Skript pro generování seznamu train.scp pro HTK
fileParam = 'nahravky_param'; % musí existovat

mfcFiles = dir(fullfile(fileParam, '*.mfc')); % Nalezení všech naparametrizovaných souborů (s příponou .mfc)

fileID = fopen('train.scp', 'w');

for i = 1:length(mfcFiles)
    mfcName = mfcFiles(i).name;     % Získání jména souboru
    
    % Sestavení cesty (pro HTK dopředná lomítka)
    path = sprintf('%s/%s', fileParam, mfcName);

    fprintf(fileID, '%s\n', path);
end

fclose(fileID);
disp('File train.scp generated.');