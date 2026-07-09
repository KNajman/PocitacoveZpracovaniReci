function [rozpoznanaSlova] = readMLF(fileName)
    % Čtení vygenerovaného MLF souboru
    fileID = fopen(fileName,'r');
    rawText = textscan(fileID, '%s', 'Delimiter', '\n');
    fclose(fileID);
    
    lines = rawText{1};
    rozpoznanaSlova = {};
    
    % Extrakce slov (ignorování hlavičky, časových značek a modelů ticha)
    for i = 1:length(lines)
        line = strtrim(lines{i});
        if startsWith(line, '#') || startsWith(line, '"') || strcmp(line, '.')
            continue;
        end
        
        % Rozdělení řádku (HVite formát: start_time end_time WORD score)
        parts = strsplit(line);
        if length(parts) >= 3
            word = parts{3}; % Slovo je na třetí pozici
            if ~ismember(word, {'SENT-START', 'SENT-END', 'sil'})
                rozpoznanaSlova{end+1} = word;
            end
        end
    end
    
    disp('Rozpoznáno:');
    disp(rozpoznanaSlova);
end