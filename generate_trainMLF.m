% Skript pro vygenerování train.mlf
fileParam = 'nahravky_param';
mfcFiles = dir(fullfile(fileParam, '*.mfc'));

fileID = fopen('train.mlf', 'w');
fprintf(fileID, '#!MLF!#\n');

for i = 1:length(mfcFiles)
    mfcName = mfcFiles(i).name;
    [~, baseName, ~] = fileparts(mfcName);
    
    parts = strsplit(baseName, '_');
    
    word = parts{2};
    
    word = lower(word);
    
    % Zápis do MLF ve formátu HTK (labely k souborům)
    fprintf(fileID, '"*/%s.lab"\n', baseName);
    fprintf(fileID, 'sil\n');
    fprintf(fileID, '%s\n', word);
    fprintf(fileID, 'sil\n');
    fprintf(fileID, '.\n');
end

fclose(fileID);
disp('Soubor train.mlf je opraven a vytvoren!');