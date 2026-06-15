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
