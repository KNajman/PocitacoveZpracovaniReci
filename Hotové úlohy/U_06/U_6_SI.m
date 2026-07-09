clear; clc; close all;

% Známé výchozí hodnoty
fs = 16000; % Vzorkovací frekvence (16 kHz)
dir = fullfile(pwd); % cesta k adresáři

% Načítá data z FileList2.txt
fileList = readlines('FileList2.txt');
if isempty(fileList)
    error('Seznam souborů FileList2.txt je prázdný nebo nebyl nalezen.');
end

params.compute = "MFCC12"; % kepstrální příznaky
params.method = "DTW";

% Výstupní soubor
outputFile = "U_6_SI.csv";
outputFile = strrep(outputFile, " ", "_");
fileID = fopen(outputFile, 'w+');
fprintf(fileID,'Osoba;Úspěšnost rozpoznání\n');

referenceDataSet = struct();
testDataSet = struct();
personResults = struct();

% Filtrace prázdných nebo neexistujících souborů
fileList = fileList(fileList ~= "" & arrayfun(@(f) exist(f, 'file'), fileList));

for i = 1:length(fileList)
    file_name = fileList(i);

    % Načtení a předzpracování signálu
    [recording, ~] = audioread(file_name);
    recording = recording + (2 * rand(length(recording), 1) - 1) * 0.001;
    filtered_recording = filter([1 -0.97], 1, recording);

    % Detekce řeči a výpočet příznaků
    [frames, ~] = detectSpeechFrames(filtered_recording, fs, 0.38, 8);
    [~, num_frames] = size(frames);
    mfcc_dim = 12;
    T = zeros(mfcc_dim, num_frames);

    for j = 1:num_frames
        frame = frames(:, j);
        [T(:, j), ~] = computeFrameMFCC(frame, 26, 12, 16000);
    end

    % Extrakce číslice a osoby
    matches = regexp(file_name, 'c(\d)_.*p(\d+)', 'tokens');
    if isempty(matches)
        warning('Nepodařilo se extrahovat číslo nebo osobu z názvu souboru: %s', file_name);
        continue;
    end

    digit = str2double(matches{1}{1});
    person = str2double(matches{1}{2});

    % Inicializace výsledkové struktury osoby
    personField = ['p', num2str(person)];
    if ~isfield(personResults, personField)
        personResults.(personField) = struct('correct', 0, 'total', 0);
    end

    if contains(file_name, "s01")
        % Inicializace pole, pokud ještě neexistuje
        if ~isfield(referenceDataSet, ['p', num2str(person)])
            referenceDataSet.(['p', num2str(person)]) = struct();
        end
        if ~isfield(referenceDataSet.(['p', num2str(person)]), ['d', num2str(digit)])
            referenceDataSet.(['p', num2str(person)]).(['d', num2str(digit)]) = [];
        end

        % Přidání nového prvku do pole
        referenceDataSet.(['p', num2str(person)]).(['d', num2str(digit)])(end+1).data = T;
    else
        % Inicializace pole, pokud ještě neexistuje
        if ~isfield(testDataSet, ['p', num2str(person)])
            testDataSet.(['p', num2str(person)]) = struct();
        end
        if ~isfield(testDataSet.(['p', num2str(person)]), ['d', num2str(digit)])
            testDataSet.(['p', num2str(person)]).(['d', num2str(digit)]) = [];
        end

        % Přidání nového prvku do pole
        testDataSet.(['p', num2str(person)]).(['d', num2str(digit)])(end+1).data = T;
    end

    % Vyhodnocení úspěšnosti
    for p_test = fieldnames(testDataSet)'
        personTest = p_test{1};
        testSamples = testDataSet.(personTest);

        for d = 0:9
            digitField = ['d', num2str(d)];

            if ~isfield(testSamples, digitField) || isempty(testSamples.(digitField))
                continue;
            end

            % Pokud existují testovací vzorky pro danou číslici, pokračuj...
            for t = 1:length(testSamples.(digitField))
                testSample = testSamples.(digitField)(t).data;
                minDist = inf;
                predictedDigit = -1;

                for p_ref = fieldnames(referenceDataSet)'  % Iterace přes reference
                    personRef = p_ref{1};
                    if strcmp(personRef, personTest)
                        continue; % Vynechání vlastní osoby
                    end

                    for d2 = 0:9
                        refDigitField = ['d', num2str(d2)];
                        if ~isfield(referenceDataSet.(personRef), refDigitField) || isempty(referenceDataSet.(personRef).(refDigitField))
                            continue;
                        end

                        for k = 1:length(referenceDataSet.(personRef).(refDigitField))
                            trainSample = referenceDataSet.(personRef).(refDigitField)(k).data;
                            [~, testI] = size(testSample);
                            [~, trainJ] = size(trainSample);
                            dist = FastDTW(testSample', testI, trainSample', trainJ);

                            if dist < minDist
                                minDist = dist;
                                predictedDigit = d2;
                            end
                        end
                    end
                end

                % Vyhodnocení výsledku
                if predictedDigit == d
                    personResults.(personTest).correct = personResults.(personTest).correct + 1;
                end
                personResults.(personTest).total = personResults.(personTest).total + 1;
            end
        end

    end
end

% Uložení výsledků
for p = fieldnames(personResults)'
    personID = str2double(p{1}(2:end));
    accuracy = (personResults.(p{1}).correct / personResults.(p{1}).total);
    fprintf(fileID, '%d;%.2f;\n', personID, accuracy);
end

fclose(fileID);
disp(['Výsledky uloženy do ' outputFile]);