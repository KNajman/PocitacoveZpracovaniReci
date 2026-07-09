% Skript pro vygenerování referenčního test.mlf (pro HResults)
slozkaParam = 'test_param';
mfcFiles = dir(fullfile(slozkaParam, '*.mfc'));

fileID = fopen('testref.mlf', 'w');
fprintf(fileID, '#!MLF!#\n');

for i = 1:length(mfcFiles)
    mfcName = mfcFiles(i).name;
    baseName = mfcName(1:end-4);
    
    % Získání slova z názvu (např. "dva_06" -> "DVA")
    parts = strsplit(baseName, '_');
    slovo = upper(parts{2}); % Velkými písmeny, aby to sedělo s výstupem
    
    % Formát záznamu musí sedět s tím, co generuje HVite (má tam koncovku .rec)
    fprintf(fileID, '"*/%s.lab"\n', baseName);
    fprintf(fileID, 'SENT-START\n');
    fprintf(fileID, '%s\n', slovo);
    fprintf(fileID, 'SENT-END\n');
    fprintf(fileID, '.\n');
end

fclose(fileID);
disp('Soubor test.mlf je hotov! Můžeme spustit HResults.');