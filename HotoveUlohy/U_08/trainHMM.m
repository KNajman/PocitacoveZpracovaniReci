% function ret = trainHMM (class_id, train_set, num_train, max_frames, word, hmm, params)
%     % parametry slov
%     %  word.features   % 3-dim pole obsahujici priznaky vsech slov (slovo, frame, priznak]
%     %  word.frames     % 2-dim pole obsahujici pocty framu vsech slov (slovo, pocet_framu)
%     %  word.class      % 1-dim pole obsahujici informaci o tride slova (napr. 0 pro slovo "nula")
%     % 
%     % % parametry slovnich modelu (HMM)
%     %  num_HMM_states  % pocet stavu - pro vsechny modely stejny
%     %  hmm.Trans        % 3-dim pole obsahujici prechodove pravdepobnosti (model, stav, 2)
%     %                        % v posledni dimezi: 1 - pravdepodobnost setrvani, 2 - pravd. prechodu do sous. stavu   
%     %                        % pro urychleni vypoctu jsou tyto hodnoty uz zlogaritmovany
%     %  hmm.Means        % 3-dim pole obsahujici stredni hodnoty  (model, stav, priznak)
%     %  hmm.Vars         % 3-dim pole obsahujici rozptyly, tj. hodnoty sigma^2, (model, stav, priznak)
%     %  hmm.Const        % 2-dim pole obsahujici predpocitane (zlogaritmovane) konstanty (model, stav)
%     %  hmm.Class        % 1-dim pole obsahujici informace o tride modelu (napr. 0 pro slovo "nula")
% 
%     num_features = size (word.features,3);
%     iter = 1;
%     num_train_class = 0;
%     train_class_set = zeros(1,num_train);
% 
%     for n = 1:num_train
%         %fprintf("Jaký je index: %0d \n",train_set(n))
%         if (word.type(train_set(n)) == hmm.Class(class_id))
%             num_train_class = num_train_class + 1;
%             train_class_set (num_train_class) = train_set(n);
%         end
%     end
% 
%     frame_to_state = zeros (num_train_class, max_frames); % namapovani framu na stavy
%     num_frames_per_state = zeros (num_train_class, params.HMM_stavu);
% 
% 
%     % nejprve zacneme rovnomernym prirazenim framu ke stavum
%     for n = 1:num_train_class
%         [num_fps, fts] = splitFramesToStates (word.frames(train_class_set(n)), params.HMM_stavu);
%         num_frames_per_state(n,:) = num_fps;
%         frame_to_state (n,1:word.frames( train_class_set(n))) = fts;
%     end
% 
%     % smycka pro jednotlive iterace
%     while (iter <= params.MaxIter)
%         total_frames_per_state = sum (num_frames_per_state);  % celkovy pocet framu na stav
%         max_frames_in_state = max (total_frames_per_state);   % max pocet framu ze vsech stavu
% 
%         % zapiseme priznakove vektory do pomocne matice podle stavu
%         feature_vectors_in_state = zeros (params.HMM_stavu, max_frames_in_state, num_features);
%         count (1:params.HMM_stavu) = 1;
%         for n = 1:num_train_class
%             for f = 1:word.frames(train_class_set(n))
%                 s = frame_to_state (n,f);
%                 feature_vectors_in_state(s, count(s),:) = word.features(train_class_set(n),f,:);
%                 count (s) = count (s) + 1;
%             end
%         end
% 
%         % vypocet parametru HMM pro vsechny stavy lze ted provest jednoduse standardnimi funkcemi
%         for s = 1:params.HMM_stavu
%             hmm.Means(class_id,s,:) = mean (feature_vectors_in_state (s,1:total_frames_per_state(s),:));
%             hmm.Vars(class_id,s,:) = var (feature_vectors_in_state (s,1:total_frames_per_state(s),:));
%             hmm.Trans(class_id,s,2) = num_train_class /total_frames_per_state(s);
%             hmm.Trans(class_id,s,1) = 1 - hmm.Trans(class_id,s,2);
%             temp = hmm.Vars(class_id,s,:) * 2 * pi;
%             det = prod (temp);
%             hmm.Const(class_id,s) = log (1 / sqrt (det)); % predpocitan logaritmus konst. clenu
%         end
%         hmm.Trans(class_id,:,:) = log (hmm.Trans(class_id,:,:));  % zlogaritmovane vsechny prech. pravdepodobnosti
% 
%         % zde provadime vypocet pravdepodobnosti trenovacich slov s aktualni iteraci modelu
%         % cilem je najit nove (verime ze lepsi) prirazeni framu ke stavum
%         if (params.MaxIter > 1)  % proved jen kdyz je pozadovano vice iteraci
%             % se vsemi slovy z tren. sady provedeme rozpoznani s cilem najit nejlepsi cestu
%             for n = 1:num_train_class
%                 nn = train_class_set (n);
%                 word_feat = reshape (word.features (nn,:,:),[max_frames,num_features]);
%                 [scr(n), path] = ComputeViterbi (word_feat, word.frames(nn), class_id,hmm,params);
%                 frame_to_state (n,1:word.frames(nn)) = path;  % mame prirazeni framu ke stavum
%                 for s = 1:params.HMM_stavu
%                     num_frames_per_state(n,s) = sum(path==s); % urcime jeste pocet framu ve stavech
%                 end
%             end
%             total_score = sum(scr); % toto skore by melo s kazdou iteraci rust (nechte si vypisovat)
%             fprintf("Score: %d \n",total_score)
%             disp(total_score);
%         end
%         iter = iter + 1;
%     end
%     ret = iter;
% end
% 
% 


function hmm = trainHMM (class_id, train_set, num_train, max_frames, word, hmm, params)
    % class_id:  Index modelu HMM (1 až num_models), odpovídá číslici hmm.Class(class_id)
    % train_set: Indexy všech trénovacích vzorků ve struktuře 'word'
    % num_train: Celkový počet trénovacích vzorků
    % max_frames: Maximální počet rámců nalezený ve všech trénovacích vzorcích
    % word:      Struktura s trénovacími daty (features, frames, type)
    % hmm:       Struktura se všemi HMM modely (předává se a modifikuje se pro class_id)
    % params:    Struktura s obecnými parametry

    num_features = size(word.features, 3); % Počet příznaků
    num_HMM_states = params.HMM_stavu;     % Počet stavů HMM

    % --- Filtrování trénovacích dat pro danou třídu ---
    num_train_class = 0;
    train_class_set_indices = []; % Dynamicky rostoucí pole indexů ve 'word'
    target_digit = hmm.Class(class_id); % Skutečná číslice, kterou tento model reprezentuje

    for n = 1:num_train
        original_index = train_set(n); % Index ve struktuře word
        % Pozor na typy při porovnání: word.type je int8, target_digit je double
        % Je bezpečnější převést jedno na typ druhého
        if (int8(word.type(original_index)) == int8(target_digit))
            num_train_class = num_train_class + 1;
            train_class_set_indices(num_train_class) = original_index; % Uložíme indexy relevantních vzorků
        end
    end

    if num_train_class == 0
        warning('Pro HMM model %d (číslice %d) nebyly nalezeny žádné trénovací vzorky. Parametry nebudou aktualizovány.', class_id, target_digit);
        return;
    end

    % Inicializace pomocných matic pouze pro relevantní vzorky
    frame_to_state = zeros(num_train_class, max_frames); % double
    num_frames_per_state_per_word = zeros(num_train_class, num_HMM_states); % double

    % --- Inicializace: Rovnoměrné přiřazení rámců ke stavům ---
    for n = 1:num_train_class
        current_word_index = train_class_set_indices(n);
        actual_frames = word.frames(current_word_index); % Skutečný počet rámců (int32)
        if actual_frames > 0
             
             [num_fps, fts] = splitFramesToStates(actual_frames, num_HMM_states); % num_fps, fts jsou double
             num_frames_per_state_per_word(n, :) = num_fps;
             % Indexování pomocí int32 (actual_frames) je OK
             frame_to_state(n, 1:actual_frames) = fts;
        else
             warning('Trénovací vzorek %d (index %d) pro číslici %d má 0 rámců.', n, current_word_index, target_digit);
        end
    end

    % --- Smyčka iterací (Baum-Welch - pouze re-estimace a re-alignment) ---
    iter = 1;
    while (iter <= params.MaxIter)
        % --- Re-estimace parametrů HMM ---
        total_frames_per_state = sum(num_frames_per_state_per_word, 1); % double

        if any(total_frames_per_state == 0) && iter > 1 % Kontrola až po první iteraci
             warning('Iterace %d, HMM %d: Některý stav nemá přiřazeny žádné rámce po Viterbi. Ukončuji trénování pro tento model.', iter, class_id);
             return;
        elseif any(total_frames_per_state == 0) && iter == 1
             warning('Iterace %d, HMM %d: Některý stav nemá přiřazeny žádné rámce po počátečním rozdělení. Pokračuji, ale může selhat.', iter, class_id);
             % Můžeme zde zkusit např. přiřadit rozptylové minimum, aby nedošlo k dělení nulou
             problematic_states = find(total_frames_per_state == 0);
             % Tuto část by bylo třeba ošetřit robustněji - např. přeskočením aktualizace problémových stavů
        end


        max_frames_in_any_state = max(total_frames_per_state); % double
        if isempty(max_frames_in_any_state); max_frames_in_any_state=0; end % Pro případ, že total_frames.. je prázdné

        % Alokace pomocné matice jako single
        feature_vectors_in_state = zeros(num_HMM_states, max_frames_in_any_state, num_features, 'single');
        count_per_state = ones(1, num_HMM_states); % double

        for n = 1:num_train_class
            current_word_index = train_class_set_indices(n);
            actual_frames = word.frames(current_word_index); % int32
            for f = 1:double(actual_frames) % Explicitně převedeno na double pro jistotu
                s = frame_to_state(n, f); % double
                 % Převedeme s na integer pro bezpečné indexování pole feature_vectors_in_state
                 s_int = round(s); % Zaokrouhlení pro případ chyby Viterbiho
                 if s_int > 0 && s_int <= num_HMM_states % Kontrola platnosti indexu
                    idx_in_state = count_per_state(s_int);
                     % Ověření, že nepřekročíme alokovanou velikost
                     if idx_in_state <= size(feature_vectors_in_state, 2)
                         feature_vectors_in_state(s_int, idx_in_state, :) = word.features(current_word_index, f, :);
                         count_per_state(s_int) = idx_in_state + 1;
                     else
                         % Toto by nemělo nastat, pokud total_frames_per_state bylo spočítáno správně
                         warning('Překročení alokované velikosti pro feature_vectors_in_state ve stavu %d.', s_int);
                     end
                 end
            end
        end

        % Výpočet nových parametrů HMM
        new_means = zeros(num_HMM_states, num_features, 'single');
        new_vars = ones(num_HMM_states, num_features, 'single') * params.VarianceFloor; % Inicializace na floor
        new_trans_stay = zeros(num_HMM_states, 1); % double
        new_trans_move = zeros(num_HMM_states, 1); % double
        new_const = zeros(num_HMM_states, 1, 'single');

        for s = 1:num_HMM_states
            num_frames_in_state = count_per_state(s) - 1; % Skutečný počet rámců přiřazených ke stavu s
            if num_frames_in_state > 0
                % Vektory příznaků pro aktuální stav 's'
                features_s = squeeze(feature_vectors_in_state(s, 1:num_frames_in_state, :));
                if num_frames_in_state == 1
                     features_s = reshape(features_s, [1, num_features]); % Oprava pro 1 rámec
                end

                new_means(s, :) = mean(features_s, 1);
                if num_frames_in_state > 1
                    new_vars(s, :) = var(features_s, 1, 1); % Var s normalizací N-1 (často stabilnější)
                else
                    % Pro jeden rámec necháme VarianceFloor (už inicializováno)
                end
                 % Aplikace variance floor
                 new_vars(s, :) = max(new_vars(s, :), params.VarianceFloor);

                 % Přechodové pravděpodobnosti
                 num_words_in_state = sum(num_frames_per_state_per_word(:, s) > 0); % double
                 if num_frames_in_state > 0 && num_words_in_state > 0
                     p_move = num_words_in_state / num_frames_in_state; % double / double
                     p_move = min(max(p_move, 1e-5), 1 - 1e-5); % Ohraničení
                     new_trans_move(s) = p_move;
                     new_trans_stay(s) = 1 - p_move;
                 else
                      new_trans_stay(s) = 0.9; % Defaultní hodnoty, pokud stav nebyl použit
                      new_trans_move(s) = 0.1;
                 end
                % Gaussovská konstanta (log)
                new_const(s) = -0.5 * (num_features * log(2*pi) + sum(log(new_vars(s, :)))); % single
            else
                 % Pokud stav 's' neměl žádné rámce, ponecháme inicializované/předchozí hodnoty
                 % nebo nastavíme nějaké defaultní
                 warning('HMM %d, Iterace %d: Stav %d nemá přiřazené rámce. Parametry neaktualizovány.', class_id, iter, s);
                 % Zde bychom měli načíst předchozí hodnoty z hmm, pokud existují a iter > 1
                 if iter > 1
                    new_means(s,:) = squeeze(hmm.Means(class_id, s, :))';
                    new_vars(s,:) = squeeze(hmm.Vars(class_id, s, :))';
                    new_const(s) = hmm.Const(class_id, s);
                    % Přechody nechat jak jsou, nebo nastavit default
                    new_trans_stay(s) = exp(hmm.Trans(class_id, s, 1)); % Zpět z log
                    new_trans_move(s) = exp(hmm.Trans(class_id, s, 2));
                 else
                    % Pro první iteraci můžeme nechat VarianceFloor a např. 0 means, 0.9/0.1 trans
                    new_means(s, :) = 0;
                    new_trans_stay(s) = 0.9;
                    new_trans_move(s) = 0.1;
                    new_const(s) = -0.5 * (num_features * log(2*pi) + sum(log(new_vars(s, :)))); % Const pro VarFloor
                 end
            end
        end

        % Aktualizace parametrů v hlavní struktuře HMM
        hmm.Means(class_id, :, :) = reshape(new_means, [1, num_HMM_states, num_features]);
        hmm.Vars(class_id, :, :) = reshape(new_vars, [1, num_HMM_states, num_features]);
        hmm.Trans(class_id, :, 1) = log(new_trans_stay); % Ukládáme log
        hmm.Trans(class_id, :, 2) = log(new_trans_move); % Ukládáme log
        hmm.Const(class_id, :) = new_const;


        % --- Re-alignment (přiřazení rámců ke stavům pomocí Viterbi) ---
        if (iter < params.MaxIter)
            total_log_likelihood = 0;
            new_frame_to_state = zeros(num_train_class, max_frames); % double
            new_num_frames_per_state_per_word = zeros(num_train_class, num_HMM_states); % double

            for n = 1:num_train_class
                current_word_index = train_class_set_indices(n);
                actual_frames = word.frames(current_word_index); % int32
                if actual_frames > 0
                     word_feat_actual = squeeze(word.features(current_word_index, 1:actual_frames, :)); % single
                     if actual_frames == 1
                         word_feat_actual = reshape(word_feat_actual, [1, num_features]);
                     end

                     [score, path] = ComputeViterbi(word_feat_actual, actual_frames, class_id, hmm, params); % path je int32

                     new_frame_to_state(n, 1:actual_frames) = path; % Přiřazení int32 do double OK

                     for s = 1:num_HMM_states
                         % OPRAVENO: Porovnání int32 s int32
                         new_num_frames_per_state_per_word(n, s) = sum(path == int32(s));
                     end
                     if isfinite(score) % Přičítáme jen konečná skóre
                        total_log_likelihood = total_log_likelihood + score;
                     else
                        warning('HMM %d, Iterace %d, Vzorek %d: Viterbi vrátil neplatné skóre (%f).', class_id, iter, current_word_index, score);
                     end
                end
            end

            frame_to_state = new_frame_to_state;
            num_frames_per_state_per_word = new_num_frames_per_state_per_word;
            fprintf('HMM %d (číslice %d), Iterace %d: Celková log-pravděpodobnost = %.4f\n', class_id, target_digit, iter, total_log_likelihood);
        end
        iter = iter + 1;
    end
end

% =========================================================================
% Funkce pro rozdělení rámců mezi stavy (Robustnější verze)
% =========================================================================
function [num_frames_per_state, frame_to_state] = splitFramesToStates (num_frames, num_HMM_states)
    % num_frames může být na vstupu int32

    if num_frames <= 0 || num_HMM_states <= 0
        num_frames_per_state = zeros(1, num_HMM_states); % Vrací double
        frame_to_state = []; % Prázdné pole (double)
        return;
    end

    % --- Provádíme výpočty s typem double pro jistotu ---
    num_frames_dbl = double(num_frames);
    num_HMM_states_dbl = double(num_HMM_states);

    % Výpočet počtu rámců pro každý stav
    base_frames = floor(num_frames_dbl / num_HMM_states_dbl);
    num_frames_per_state = base_frames * ones(1, num_HMM_states); % Výsledek je double
    remainder = rem(num_frames_dbl, num_HMM_states_dbl); % Výsledek je double

    % Přidání zbytku k prvním 'remainder' stavům
    % Zajistíme, že remainder je platný index (musí být > 0)
    if remainder >= 1
        % Indexujeme pomocí double (remainder), což je OK
        num_frames_per_state(1:round(remainder)) = num_frames_per_state(1:round(remainder)) + 1;
    end

    % Kontrola (volitelná): Součet by měl stále odpovídat původnímu počtu rámců
    if sum(num_frames_per_state) ~= num_frames_dbl
       warning('splitFramesToStates: Součet rámců na stav (%f) neodpovídá vstupu (%f)!', sum(num_frames_per_state), num_frames_dbl);
       % Případná korekce - např. upravit poslední stav, i když by to nemělo být nutné
    end

    % Alokace výstupního vektoru s explicitním použitím double pro velikost
    frame_to_state = zeros(1, double(num_frames), 'double'); % Zajistíme, že výstup je double

    % Přiřazení čísel stavů k rámcům
    current_index = 1.0; % Používáme double pro indexy
    for s = 1:num_HMM_states
        num_frames_in_this_state = num_frames_per_state(s); % double
        if num_frames_in_this_state > 0.0
            % Výpočet koncového indexu jako double
            end_index = current_index + num_frames_in_this_state - 1.0;

            % Pojistka proti překročení (nemělo by nastat, ale pro jistotu)
            if end_index > num_frames_dbl
                warning('splitFramesToStates: end_index (%f) překročil num_frames (%f). Ořezávám.', end_index, num_frames_dbl);
                end_index = num_frames_dbl;
            end

            % Indexování pomocí double (current_index, end_index) je OK
            if current_index <= end_index
                 % Přiřazujeme číslo stavu 's' (double)
                 frame_to_state(round(current_index):round(end_index)) = double(s);
            end
            % Posun na další začátek jako double
            current_index = end_index + 1.0;
        end
        % Pokud num_frames_in_this_state == 0, neděláme nic, current_index se nemění
    end

    % --- Finální kontrola velikosti před vrácením ---
    if length(frame_to_state) ~= num_frames
       error('splitFramesToStates: Kritická chyba! Délka výstupního vektoru (%d) neodpovídá vstupnímu num_frames (%d)!', length(frame_to_state), num_frames);
    end
end