clear; clc; close;
%%
% Známé výchozí hodnoty
fs = 16000; % Vzorkovací frekvence (16 kHz)
dir = fullfile(pwd); % cesta k adresáři
threshold = -3.18;
% Načítá data z FileList.txt
fileList = readlines('FileList.txt');
if isempty(fileList)
    error('Seznam souborů FileList.txt je prázdný nebo nebyl nalezen.');
end

% Kombinace parametrizací a metod
parametrizationTypes = [1, 2, 3, 4]; % 1: Energy, 2: Energy + ZCR, 3: Frame Spec, 4: All
parametrizationMethods = [1, 2]; % 1: LTW, 2: DTW

% for paramType = parametrizationTypes
% for paramMethod = parametrizationMethods
paramType=2; paramMethod=2;

switch paramType
    case 1
        params.compute = "energy";
    case 2
        params.compute = ["energy", "zcr"];
    case 3
        params.compute = "frameSpec";
    case 4
        params.compute = "Fbank26";
    case 5
        params.compute = "MFCC12";
    otherwise
        params.compute = ["energy", "zcr", "frameSpec"];
end

switch paramMethod
    case 1
        params.method = "LTW";
    case 2
        params.method = "DTW";
end

% Výstupní soubor
outputFile = strjoin(params.compute, "_") + "_" + params.method + ".csv";
outputFile = strrep(outputFile, " ", "_");
fileID = fopen(outputFile, 'w+');
fprintf(fileID, 'Osoba;Úspěšnost rozpoznání;Přiznaky;Hodnotící metoda\n');
%%

% Inicializace datových struktur
referenceDataSet = cell(10, 1); % 1 vzorek pro každé číslo, tedy 10 vzorků
testDataSet = cell(10, 1); % 4 vzorky pro každé číslo, tedy 40 vzorků
personResults = struct(); % 1 osoba = 50 nahrávek

% Filtrace prázdných nebo neexistujících souborů před iterací
fileList = fileList(fileList ~= "" & arrayfun(@(f) exist(f, 'file'), fileList));

for i = 1:length(fileList)
    file_name = fileList(i);

    % Načtení a předzpracování signálu
    [recording, ~] = audioread(file_name);
    recording = recording + (2 * rand(length(recording), 1) - 1) * 0.001;
    filtered_recording = filter([1 -0.97], 1, recording);

    % Detekce řeči a výpočet příznaků
    [frames, energy] = detectSpeechFrames(filtered_recording, fs, threshold);
    T = ComputeSpeechFeatures(frames, energy, params.compute);

    % Extrakce číslice a osoby jedním regulárním výrazem
    matches = regexp(file_name, 'c(\d)_.*p(\d+)', 'tokens');
    if isempty(matches)
        warning('Nepodařilo se extrahovat číslo nebo osobu z názvu souboru: %s', file_name);
        continue;
    end

    digit = str2double(matches{1}{1});
    person = str2double(matches{1}{2});

    % Inicializace výsledkové struktury osoby (laziness check)
    personField = ['p', num2str(person)];
    if ~isfield(personResults, personField)
        personResults.(personField) = struct('correct', 0, 'total', 0);
    end

    % Zařazení do trénovací nebo testovací množiny
    if contains(file_name, 's01') % Referenční vzorek
        referenceDataSet{digit + 1} = [referenceDataSet{digit + 1}, {T}];
    elseif contains(file_name, 's0', 'IgnoreCase', true) % Testovací vzorky s02-s05
        testDataSet{digit + 1} = [testDataSet{digit + 1}, struct('data', T, 'person', person)];
    end
end


% Vyhodnocení úspěšnosti
for d = 0:9
    testSamples = testDataSet{d + 1};
    if isempty(testSamples)
        continue;
    end

    for t = 1:length(testSamples)
        testSample = testSamples(t).data;
        person = testSamples(t).person;
        minDist = inf;
        predictedDigit = -1;

        for d2 = 0:9
            trainSamples = referenceDataSet{d2 + 1};
            if isempty(trainSamples)
                continue;
            end

            for k = 1:length(trainSamples)
                trainSample = trainSamples{k};
                dist = inf;

                [~,testI]=size(testSample);
                [~,trainJ]=size(trainSample);
                switch params.method
                    case "LTW"
                        dist = ComputeLTW(testSample', testI, trainSample', trainJ);
                    case "DTW"
                        dist = ComputeDTW(testSample', testI, trainSample', trainJ);
                end

                if dist < minDist
                    minDist = dist;
                    predictedDigit = d2;
                end
            end
        end

        if predictedDigit == d
            personResults.(['p' num2str(person)]).correct = personResults.(['p' num2str(person)]).correct + 1;
        end
        personResults.(['p' num2str(person)]).total = personResults.(['p' num2str(person)]).total + 1;
    end
end

%%
% Uložení výsledků
personNames = fieldnames(personResults);
for p = 1:length(personNames)
    personID = str2double(personNames{p}(2:end));
    accuracy = (personResults.(personNames{p}).correct / personResults.(personNames{p}).total) * 100;
    fprintf(fileID, '%d;%.2f;%s;%s\n', personID, accuracy, strjoin(params.compute," "),strjoin(params.method," "));
end

fclose(fileID);
disp(['Výsledky uloženy do ' outputFile]);

%%
function [distance] = ComputeDTW(X, I, R, J)
% Optimalizovaná verze Dynamic Time Warping (DTW) s omezením pásma a nízkou paměťovou náročností

% Předčasné ukončení, pokud jsou sekvence příliš rozdílné
if abs(I - J) * 2 > max(I, J)
    distance = inf;
    return;
end

% Pouze jednorozměrné pole
A = inf(1, J + 2);
wasAhorizontal = zeros(1, J + 2);

% Inicializace první hodnoty
A(1 + 2) = ComputeEuclidDist(X(1,:), R(1,:));

w=1;
% Výpočet pouze v omezeném pásmu
for i = 2:I
    w=max(w,abs(I - J));
    jmin=max(1,i - w);
    jmax=min(J,i + w);
    % Dynamické omezení pásma
    for j = jmax:-1:jmin %jdeme od zhora dolů -1
        jj = j + 2;  % Posun indexu
        temp = A(jj - 2);

        if temp > A(jj - 1)
            temp = A(jj - 1);
        end

        if wasAhorizontal(jj)==0 && A(jj) < temp
            wasAhorizontal(jj) = 1;
            temp = A(jj);
        else
            wasAhorizontal(jj) = 0;
        end
        A(jj) = temp + ComputeEuclidDist(X(i,:), R(j,:));% Výpočet lokální hodnoty
    end
    A(jmin +2 -1) = inf;% Nastavení posledního prvku na inf pro reset pásma
end

% Výsledek
distance = A(J + 2);
end

function distance = ComputeEuclidDist(X, R)
% Funkce počítá euklidovskou vzdálenost mezi dvěma sekvencemi X a R.
% Vstupy:
%   X - matice rozměru (P × T) obsahující první sekvenci
%   R - matice rozměru (P × T) obsahující druhou sekvenci
%
% Výstup:
%   distance - euklidovská vzdálenost mezi sekvencemi X a R

distance = norm(X-R);
end

function E = ComputeLogE(signal)
    E = log(sum(signal .^ 2));
end

function T = ComputeSpeechFeatures(frames, energy, features)
% ComputeSpeechFeatures
% Tato funkce počítá řečové příznaky (energie, ZCR, spektrální příznaky, MFCC, Fbank)
%
% Vstupy:
%   frames  - Matice rámců (řádky: vzorky, sloupce: jednotlivé rámce)
%   energy  - Vektor energií jednotlivých rámců
%   features - Cell array obsahující názvy požadovaných příznaků (např. {'energy', 'zcr', 'frameSpec'})
%
% Výstup:
%   T - Matice obsahující vypočtené příznaky (řádky: příznaky, sloupce: framy)

% Počet rámců
[~, num_frames] = size(frames);

% Kontrola požadovaných příznaků
compute_energy   = ismember("energy", features);
compute_zcr      = ismember("zcr", features);
compute_spec     = ismember("frameSpec", features);
compute_mfcc     = ismember("MFCC12", features);
compute_fbank    = ismember("Fbank26", features);
compute_mfcc_fb  = compute_mfcc || compute_fbank; % MFCC a Fbank se počítají spolu

% Počet spektrálních příznaků
k = 16;
mfcc_dim = 12;
fbank_dim = 26;

% Inicializace seznamu příznaků
feature_list = {};

% Výpočet energie (pokud je požadována)
if compute_energy
    feature_list{end+1} = energy;
end

% Inicializace a výpočet příznaků
if compute_zcr
    zcr = zeros(1, num_frames);
end
if compute_spec
    frame_spec = zeros(k, num_frames);
end
if compute_mfcc_fb
    cep_coeff = zeros(mfcc_dim, num_frames);
    mel_fbank = zeros(fbank_dim, num_frames);
end

% Výpočet příznaků pro každý rámec
for j = 1:num_frames
    frame = frames(:, j);

    if compute_zcr
        zcr(j) = ComputeZCR(frame);
    end

    if compute_spec
        frame_spec(:, j) = ComputeFrameSpec([frame; zeros(112, 1)], k);
    end

    if compute_mfcc_fb
        [cep_coeff(:, j), mel_fbank(:, j)] = computeFrameMFCC(frame, 26, 12, 16000);
    end
end

% Přidání vypočtených příznaků do seznamu
if compute_zcr
    feature_list{end+1} = zcr;
end
if compute_spec
    feature_list{end+1} = frame_spec;
end
if compute_mfcc
    feature_list{end+1} = cep_coeff;
end
if compute_fbank
    feature_list{end+1} = mel_fbank;
end

% Sestavení matice příznaků T (vertikální spojení všech zvolených příznaků)
T = vertcat(feature_list{:});
end

function z = ComputeZCR(signal)
    z = (1/2) * sum(abs(diff(sign(signal))));
end

% Program 1: Detekce slov podle energie
function [frames,energy] = detectSpeechFrames(signal, fs, threshold)
    % Nastavení parametrů rámcování
    frame_length = round(fs * 0.025); % 25 ms
    frame_step = round(fs * 0.01); % 10 ms
    
    % Počet rámců
    signal_l = length(signal);
    num_frames = floor((signal_l - frame_length) / frame_step) + 1;
    frames = zeros(frame_length, num_frames);
    energy = zeros(1, num_frames);
    
    % Výpočet energie pro každý rámec
    for j = 1:num_frames
        start_idx = (j - 1) * frame_step + 1;
        end_idx = min(start_idx + frame_length - 1, signal_l);
        frames(:, j) = [signal(start_idx:end_idx); zeros(frame_length - (end_idx - start_idx + 1), 1)];
        energy(j) = ComputeLogE(frames(:, j));
    end

    threshold=mean(energy) + 0.5 * std(energy); 
    
    start_frame = find(energy > threshold, 1, 'first');
    end_frame = find(energy > threshold, 1, 'last');
    
    energy=energy(start_frame:end_frame);

    % Vybrání pouze řečových segmentů
    if isempty(start_frame) || isempty(end_frame)
        frames = [];
    else
        frames = frames(:, start_frame:end_frame);
    end
end