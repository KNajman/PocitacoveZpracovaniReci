% Skript pro dynamické vygenerování hmmdefs a macros pro HTK

souborModelu = 'models0'; % Název souboru od HDMan

% --- 1. Vytvoření souboru macros s OPRAVENOU HLAVIČKOU ---
f_macros = fopen('hmm0/macros', 'w');
fprintf(f_macros, '~o <VecSize> 39 <MFCC_0_D_A>\n'); % Tahle hlavička HTK chyběla!

f_vfloors = fopen('hmm0/vFloors', 'r');
if f_vfloors == -1
    error('Soubor hmm0/vFloors neexistuje! Spustil jsi předtím HCompV?');
end

% Zkopírování obsahu vFloors do macros
while ~feof(f_vfloors)
    fprintf(f_macros, '%s', fgets(f_vfloors));
end
fclose(f_vfloors); 
fclose(f_macros);

% --- 2. Vytvoření souboru hmmdefs ---
if ~exist(souborModelu, 'file')
    error('Soubor %s nebyl nalezen. Spust nejprve nastroj HDMan!', souborModelu);
end

% Načtení seznamu modelů z models0
fid = fopen(souborModelu, 'r');
nactenaData = textscan(fid, '%s');
fclose(fid);
slova = nactenaData{1};

f_hmmdefs = fopen('hmm0/hmmdefs', 'w');

% Načtení prototypů
proto8 = fileread('hmm0/proto-8s-39f');
proto3 = fileread('hmm0/proto-3s-39f');

% Odstranění prvních dvou řádků
proto8_body = regexprep(proto8, '^~o.*?\n~h.*?\n', '');
proto3_body = regexprep(proto3, '^~o.*?\n~h.*?\n', '');

% Dynamické přiřazení prototypů
for i = 1:length(slova)
    nazevModelu = slova{i};
    fprintf(f_hmmdefs, '~h "%s"\n', nazevModelu);
    
    if strcmp(nazevModelu, 'sil')
        fprintf(f_hmmdefs, '%s', proto3_body);
    else
        fprintf(f_hmmdefs, '%s', proto8_body);
    end
end

fclose(f_hmmdefs);
disp('Parada! Soubory hmm0/macros a hmm0/hmmdefs jsou spravne vygenerovany.');