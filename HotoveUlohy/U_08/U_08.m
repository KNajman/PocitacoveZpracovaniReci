close all; clc; clear; %

% --- Nastavení parametrů ---
params.fs = 16000;              % Vzorkovací frekvence
params.frame_shift = 8;         % Posun rámce v ms
params.priznaky = "MFCC12";     % Typ příznaků (jen pro info, reálně se používá pocet_MFCC_priznaku)
params.pocet_MFCC_priznaku = 12;% Počet MFCC koeficientů
params.metoda = "HMM";          % Metoda rozpoznávání (pro info)
params.HMM_stavu = int32(17);          % Počet stavů v HMM modelu
params.MaxIter = 5;             % Maximální počet iterací pro trénování (Baum-Welch)
params.VarianceFloor = 1e-5;    % Minimální hodnota rozptylu (pro stabilitu)

% --- Definice cest a sad ---
dir = fullfile(pwd); % Adresář skriptu

% Soubory se seznamy VŠECH nahrávek (cesty relativní k 'dir' nebo absolutní)
referenceDataListFile = 'FileList2.txt';
testDataListFile = 'FileList.txt';

% Určení, které "session" (sady) se použijí pro trénování a které pro testování
referenceSessions = [1,2,3,4,5]; % Trénovací sady
testSessions = [4, 5];       % Testovací sady

% --- Načtení a filtrace seznamů souborů ---
fprintf('Načítám a filtruji seznamy souborů...\n');
try
    referenceSpeakerListFull = readlines(referenceDataListFile);
    % Odstranění případného prázdného posledního řádku
    if ~isempty(referenceSpeakerListFull) && isempty(strtrim(referenceSpeakerListFull{end})); referenceSpeakerListFull(end) = []; end
catch ME
    error('Nepodařilo se načíst referenční soubor %s: %s', referenceDataListFile, ME.message);
end

try
    testSpeakerListFull = readlines(testDataListFile);
    if ~isempty(testSpeakerListFull) && isempty(strtrim(testSpeakerListFull{end})); testSpeakerListFull(end) = []; end
catch ME
    error('Nepodařilo se načíst testovací soubor %s: %s', testDataListFile, ME.message);
end

% Funkce filterFileListBySession není součástí dotazu, předpokládáme, že existuje a funguje správně
% Měla by vrátit cell array cest k souborům patřícím do daných sessions
referenceFileList = filterFileListBySession(referenceSpeakerListFull, referenceSessions, referenceDataListFile);
testFileList = filterFileListBySession(testSpeakerListFull, testSessions, testDataListFile);
clear referenceSpeakerListFull testSpeakerListFull; % Uvolnění paměti

if isempty(referenceFileList)
    error('Nebyly nalezeny žádné referenční soubory pro zadané sady (%s).', mat2str(referenceSessions));
end
if isempty(testFileList)
    error('Nebyly nalezeny žádné testovací soubory pro zadané sady (%s).', mat2str(testSessions));
end
fprintf('Nalezeno %d referenčních a %d testovacích souborů.\n', length(referenceFileList), length(testFileList));

% --- Zpracování referenčních souborů a extrakce příznaků (do cell arrays) ---
disp('Zpracovávám referenční audio soubory a extrahuji příznaky...');

max_frames_observed = 0; % Sledování maximální délky sekvence příznaků

ref_features_cell = {}; % Cell array pro ukládání příznaků
ref_frames_cell = {};   % Cell array pro počty rámců
ref_types_list = [];    % Vektor pro typy číslic (0-9)

valid_ref_file_count = 0;

for i = 1:length(referenceFileList)
    filePath = referenceFileList{i};
    try
        processedData = processAudioFile(filePath, params);
        if ~isempty(processedData) && processedData.num_frames > 0
            valid_ref_file_count = valid_ref_file_count + 1;
            num_frames = processedData.num_frames;
            if num_frames > max_frames_observed
                max_frames_observed = num_frames;
            end
            ref_features_cell{valid_ref_file_count, 1} = processedData.mfcc;
            ref_frames_cell{valid_ref_file_count, 1} = num_frames;
            ref_types_list(valid_ref_file_count, 1) = processedData.digit;
        else
             warning('Přeskakuji referenční soubor (nebo byl prázdný/0 rámců): %s', filePath);
        end
    catch ME_process
        warning('Chyba při zpracování referenčního souboru %s: %s. Přeskakuji.', filePath, ME_process.message);
    end
end

if valid_ref_file_count == 0
    error('Nepodařilo se zpracovat žádné platné referenční soubory.');
end
fprintf('Zpracováno %d referenčních souborů. Max. počet rámců: %d.\n', valid_ref_file_count, max_frames_observed);

% --- Vytvoření struktury 'word' podle požadavků trainHMM ---
disp('Vytvářím datovou strukturu ''word'' pro trénování...');
num_train = valid_ref_file_count;
num_features = params.pocet_MFCC_priznaku;

% Alokace struktury word
word.features = zeros(num_train, max_frames_observed, num_features, 'single'); % Použití 'single' může šetřit paměť
word.frames = zeros(num_train, 1, 'int32');
word.type = zeros(num_train, 1, 'int8'); % Číslice 0-9 se vejdou do int8

for i = 1:num_train
    num_frames = ref_frames_cell{i};
    word.frames(i) = num_frames;
    word.type(i) = ref_types_list(i);
    % Kopírování příznaků do velké matice, zbytek zůstane 0 (padding)
    word.features(i, 1:num_frames, :) = ref_features_cell{i};
end

% Uvolnění paměti cell arrays, které již nejsou potřeba
clear ref_features_cell ref_frames_cell ref_types_list valid_ref_file_count;

% --- Inicializace HMM modelů ---
num_models = 10; % Pro číslice 0-9
hmm.Class = 0:(num_models-1);
hmm.Means = zeros(num_models, params.HMM_stavu, params.pocet_MFCC_priznaku, 'single');
hmm.Vars = ones(num_models, params.HMM_stavu, params.pocet_MFCC_priznaku, 'single');
hmm.Trans = zeros(num_models, params.HMM_stavu, 2, 'single'); % Log pravděpodobnosti!
hmm.Const = zeros(num_models, params.HMM_stavu, 'single');   % Log konstanty!

% --- Trénování HMM modelů ---
disp('Trénuji HMM modely...');

% Trénovací sada obsahuje indexy všech slov ve struktuře 'word'
train_set_indices = 1:num_train;

% Smyčka přes modely (1 až 10)
for model_idx = 1:num_models
    target_digit = hmm.Class(model_idx); % Číslice, pro kterou trénujeme (0-9)
    fprintf('--- Trénuji HMM model %d (pro číslici %d) ---\n', model_idx, target_digit);
        % Volání upravené funkce trainHMM
        % Předáváme celý 'word', 'hmm' a indexy všech trénovacích slov
        % Funkce si sama vybere relevantní data a modifikuje hmm pro daný model_idx
        % !! Důležité: Přiřazení vrácené struktury zpět !!
        hmm = trainHMM(model_idx, train_set_indices, num_train, max_frames_observed, word, hmm, params);
end
% Po dokončení trénování bychom měli uvolnit velkou strukturu 'word', pokud už není potřeba
clear word num_train max_frames_observed train_set_indices;
disp('Trénování HMM dokončeno.');

% --- Zpracování testovacích souborů ---
disp('Zpracovávám testovací audio soubory...');

max_test_frames_observed = 0; % Pro informaci, není nutně potřeba

test_features_cell = {}; % Cell array pro příznaky testovacích dat
test_frames_cell = {};   % Cell array pro počty rámců
test_types_list = [];    % Vektor skutečných číslic testovacích dat
test_person_list = [];   % Vektor ID mluvčích testovacích dat

valid_test_file_count = 0; % Počet úspěšně zpracovaných testovacích souborů

for i = 1:length(testFileList)
    filePath = testFileList{i};
    try
        processedData = processAudioFile(filePath, params); % Používáme stejnou funkci

        if ~isempty(processedData) && processedData.num_frames > 0
            valid_test_file_count = valid_test_file_count + 1;

            num_frames = processedData.num_frames;
            if num_frames > max_test_frames_observed
                max_test_frames_observed = num_frames;
            end

            test_features_cell{valid_test_file_count, 1} = processedData.mfcc;
            test_frames_cell{valid_test_file_count, 1} = num_frames;
            test_types_list(valid_test_file_count, 1) = processedData.digit;
            % Předpoklad: processAudioFile vrací i ID mluvčího
            if isfield(processedData, 'person')
                 test_person_list(valid_test_file_count, 1) = processedData.person;
            else
                 warning('PersonID nebylo nalezeno pro testovací soubor: %s. Používám ID=0.', filePath);
                 test_person_list(valid_test_file_count, 1) = 0; % Výchozí ID, pokud chybí
            end
        else
             warning('Přeskakuji testovací soubor (nebo byl prázdný): %s', filePath);
        end
    catch ME_process_test
        warning('Chyba při zpracování testovacího souboru %s: %s. Přeskakuji.', filePath, ME_process_test.message);
    end
end

if valid_test_file_count == 0
    error('Nepodařilo se zpracovat žádné testovací soubory.');
end
fprintf('Zpracováno %d testovacích souborů. Max. počet rámců: %d.\n', valid_test_file_count, max_test_frames_observed);

% --- Rozpoznávání pomocí Viterbiho algoritmu ---
disp('Provádím rozpoznávání testovacích dat...');

personResults = struct(); % Struktura pro ukládání výsledků pro každou osobu
overallConfusionMatrix = zeros(num_models, num_models); % Matice záměn (řádek=skutečná, sloupec=predikovaná)

num_test_total = valid_test_file_count; % Počet testovacích vzorků k rozpoznání

for i = 1:num_test_total
    % Získání dat pro aktuální testovací vzorek
    testFeatures = test_features_cell{i};
    num_frames_test = test_frames_cell{i};
    actualDigit = test_types_list(i);
    personID = test_person_list(i);

    % Příprava pole pro identifikátor osoby ve struktuře výsledků
    personField = ['p', sprintf('%04d', personID)]; % Např. p0001, p0101 atd.
    if ~isfield(personResults, personField)
        % Inicializace statistik pro novou osobu
        personResults.(personField) = struct('correct', 0, 'total', 0, 'confusions', zeros(num_models, num_models));
    end

    bestScore = -inf;
    predictedDigit = -1; % Výchozí hodnota, pokud selže rozpoznávání

    % Ohodnocení testovacího vzorku každým HMM modelem (0-9)
    for model_idx = 1:num_models % model_idx odpovídá číslici model_idx-1
            % Volání Viterbi funkce - předáváme příznaky a parametry modelu
            [score, ~] = ComputeViterbi(testFeatures, num_frames_test, model_idx, hmm, params);

            if score > bestScore
                bestScore = score;
                predictedDigit = hmm.Class(model_idx); % Predikovaná číslice (0-9)
            end
    end % konec cyklu přes modely (0-9)

    % --- Vyhodnocení výsledku pro tento testovací vzorek ---
    if predictedDigit == -1
        warning('Pro testovací vzorek %d (Osoba %d, Skutečná %d) nebylo možné určit predikci (žádný model nedal platné skóre).', i, personID, actualDigit);
        % Nezapocitavame do statistik, nebo muzeme pocitat jako chybu
        personResults.(personField).total = personResults.(personField).total + 1; % Počítáme jako testovaný vzorek
        % Do matice záměn nezaznamenáváme, nebo můžeme přidat extra sloupec/řádek pro "neznámé"
    else
        % Zvýšení počtu testovaných vzorků pro danou osobu
        personResults.(personField).total = personResults.(personField).total + 1;

        % Kontrola správnosti predikce
        if predictedDigit == actualDigit
            personResults.(personField).correct = personResults.(personField).correct + 1;
        end

        % Záznam do matice záměn (řádek = skutečná třída, sloupec = predikovaná třída)
        % Indexujeme od 1, takže číslice 0 je index 1, ..., 9 je index 10
        actualDigit_idx = actualDigit + 1;
        predictedDigit_idx = predictedDigit + 1;

        % Záznam do matice záměn osoby
        personResults.(personField).confusions(actualDigit_idx, predictedDigit_idx) = ...
            personResults.(personField).confusions(actualDigit_idx, predictedDigit_idx) + 1;
        % Záznam do celkové matice záměn
        overallConfusionMatrix(actualDigit_idx, predictedDigit_idx) = ...
            overallConfusionMatrix(actualDigit_idx, predictedDigit_idx) + 1;

        % Volitelný výpis průběhu
        % fprintf('Test vzorek %d (Osoba %d, Skutecna %d) -> Predikovana %d (Skore: %.4f)\n', ...
        %                 i, personID, actualDigit, predictedDigit, bestScore);
    end

end % konec cyklu přes testovací vzorky
disp('Rozpoznávání dokončeno.');

disp('--- Výsledky rozpoznávání ---');

personFieldsOutput = fieldnames(personResults);
totalCorrect = 0;
totalTested = 0;

% Seřadíme osoby podle ID pro konzistentní výstup
sortedPersonFields = sort(personFieldsOutput);

fprintf('\nVýsledky podle osob:\n');
fprintf('-------------------------------------\n');
fprintf('Osoba | Úspěšnost [%%] | Správně | Celkem\n');
fprintf('-------------------------------------\n');

for p_idx = 1:length(sortedPersonFields)
    personField = sortedPersonFields{p_idx};
    % Extrahujeme ID osoby zpět z názvu pole
    personID_str = sscanf(personField, 'p%d');
    results = personResults.(personField);

    if results.total > 0
        accuracy = (results.correct / results.total) * 100;
        fprintf('%04d | %13.2f | %7d | %6d\n', personID_str, accuracy, results.correct, results.total);
        totalCorrect = totalCorrect + results.correct;
        totalTested = totalTested + results.total;
    else
        fprintf('%04d | %13s | %7d | %6d\n', personID_str, 'NaN', 0, 0);
    end
end
fprintf('-------------------------------------\n');

% --- Celkové výsledky ---
if totalTested > 0
    overallAccuracy = (totalCorrect / totalTested) * 100;
    fprintf('\nCelková úspěšnost: %.2f%% (%d / %d)\n', overallAccuracy, totalCorrect, totalTested);
else
    fprintf('\nNebyly provedeny žádné platné testy.\n');
end