function [frames, energy] = detectSpeechFrames(signal, vzorkovaci_frekvence, posun_zacatku_konce_framu)
    % Detekce slov podle energie v rámcích
    %
    % signal - vstupní signál
    % fs - vzorkovací frekvence
    % threshold - práh pro detekci řeči (ignorován, přepočítává se)
    % frame_shift - posun rámce pro rozšíření detekované oblasti
    %
    % frames - matice rámců obsahující detekované části signálu
    % energy - energie jednotlivých rámců
    signal_l = length(signal);

    signal = signal + (2*rand(signal_l, 1) - 1) * 0.001;
    signal = filter([1 -0.97], 1, signal);

    % Nastavení parametrů rámcování
    delka_framu = round(vzorkovaci_frekvence * 0.025); % 25 ms
    posun_framu = round(vzorkovaci_frekvence * 0.01);   % 10 ms
    
    % Počet rámců v signálu
    
    num_frames = floor((signal_l - delka_framu) / posun_framu) + 1;
    frames = zeros(delka_framu, num_frames);
    energy = zeros(1, num_frames);
    
    % Výpočet energie pro každý rámec
    for j = 1:num_frames
        start_idx = (j - 1) * posun_framu + 1;
        end_idx = min(start_idx + delka_framu - 1, signal_l);
        
        % Uložení rámce, doplnění nulami pokud je kratší
        frames(:, j) = [signal(start_idx:end_idx); zeros(delka_framu - (end_idx - start_idx + 1), 1)];
        
        % Výpočet logaritmické energie
        energy(j) = ComputeLogE(frames(:, j));
    end
    
    % Dynamické nastavení prahu detekce řeči
    threshold = mean(energy) + 0.5 * std(energy);
    
    % Nalezení prvního a posledního rámce nad prahem
    start_frame = find(energy > threshold, 1, 'first');
    end_frame = find(energy > threshold, 1, 'last');
    
    % Kontrola, aby nedošlo k přetečení indexu
    start_frame = max(1, start_frame - posun_zacatku_konce_framu);
    end_frame = min(num_frames, end_frame + posun_zacatku_konce_framu);
    
    % Výběr relevantních rámců a odpovídající energie
    energy = energy(start_frame:end_frame);
    frames = frames(:, start_frame:end_frame);
end

function E = ComputeLogE(signal)
    % Výpočet logaritmické energie signálu
    E = log(sum(signal .^ 2) + eps); % Přidání eps pro ochranu proti log(0)
end
