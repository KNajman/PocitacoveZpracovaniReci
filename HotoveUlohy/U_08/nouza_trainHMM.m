function ret = trainHMM (class_id, train_set, num_train, max_frames, word, hmm, params)
num_features = size (word.features,3);

iter = 1;

num_train_class = 0;
train_class_set = zeros(1,num_train);

for n = 1:num_train
    fprintf("Jaký je %s",train_set(n))
    if (word.type(train_set(n)) == hmm.Class(class_id))
        num_train_class = num_train_class + 1;
        train_class_set (num_train_class) = train_set(n);
    end
end

% alokace pro 2 dulezite pole promennych
frame_to_state = zeros (num_train_class, max_frames); % namapovani framu na stavy

num_frames_per_state = zeros (num_train_class, params.HMM_stavu);
% pro kazde tren. slovo je z pole frame_to_state spocitan pocet framu prirazenych ke kazdemu stavu
% takze napø. pro vyse uvedene slovo by to bylo [3 2 4 2]

% nejprve zacneme rovnomernym prirazenim framu ke stavum
for n = 1:num_train_class
    [num_fps, fts] = splitFramesToStates (word.frames(train_class_set(n)), params.HMM_stavu);
    num_frames_per_state(n,:) = num_fps;
    frame_to_state (n,1:word.frames( train_class_set(n))) = fts;
end

% smycka pro jednotlive iterace
while (iter <= params.MaxIter)
    total_frames_per_state = sum (num_frames_per_state);  % celkovy pocet framu na stav
    max_frames_in_state = max (total_frames_per_state);   % max pocet framu ze vsech stavu

    % zapiseme priznakove vektory do pomocne matice podle stavu
    feature_vectors_in_state = zeros (params.HMM_stavu, max_frames_in_state, num_features);
    count (1:params.HMM_stavu) = 1;
    for n = 1:num_train_class
        for f = 1:word.frames(train_class_set(n))
            s = frame_to_state (n,f);
            feature_vectors_in_state(s, count(s),:) = word.features(train_class_set(n),f,:);
            count (s) = count (s) + 1;
        end
    end

    % vypocet parametru HMM pro vsechny stavy lze ted provest jednoduse standardnimi funkcemi
    for s = 1:params.HMM_stavu
        hmm.Means(class_id,s,:) = mean (feature_vectors_in_state (s,1:total_frames_per_state(s),:));
        hmm.Vars(class_id,s,:) = var (feature_vectors_in_state (s,1:total_frames_per_state(s),:));
        hmm.Trans(class_id,s,2) = num_train_class /total_frames_per_state(s);
        hmm.Trans(class_id,s,1) = 1 - hmm.Trans(class_id,s,2);
        temp = hmm.Vars(class_id,s,:) * 2 * pi;
        det = prod (temp);
        hmm.Const(class_id,s) = log (1 / sqrt (det)); % predpocitan logaritmus konst. clenu
    end
    hmm.Trans(class_id,:,:) = log (hmm.Trans(class_id,:,:));  % zlogaritmovane vsechny prech. pravdepodobnosti

    % zde provadime vypocet pravdepodobnosti trenovacich slov s aktualni iteraci modelu
    % cilem je najit nove (verime ze lepsi) prirazeni framu ke stavum
    if (params.MaxIter > 1)  % proved jen kdyz je pozadovano vice iteraci
        % se vsemi slovy z tren. sady provedeme rozpoznani s cilem najit nejlepsi cestu
        for n = 1:num_train_class
            nn = train_class_set (n);
            word_feat = reshape (word.features (nn,:,:),[max_frames,num_features]);
            [scr(n), path] = computeHMMViterbi_fast (word_feat, word.frames(nn), class_id);
            frame_to_state (n,1:word.frames(nn)) = path;  % mame prirazeni framu ke stavum
            for s = 1:params.HMM_stavu
                num_frames_per_state(n,s) = sum(path==s); % urcime jeste pocet framu ve stavech
            end
        end
        total_score = sum(scr); % toto skore by melo s kazdou iteraci rust (nechte si vypisovat)
        disp(total_score);
    end
    iter = iter + 1;
end
ret = iter;
end


function [num_frames_per_state, frame_to_state] = splitFramesToStates (num_frames, num_HMM_states)
    % rozdeli framy kvazirovnomerne do stavu (pokud nelze rozdelit stejne, tak nektere stavy budou mit 1 vice)
    
    % Vypocet poctu framu pro kazdy stav
    num_frames_per_state = floor(num_frames / num_HMM_states) * ones(1, num_HMM_states); % Zakladni pocet framu na stav
    remainder = rem(num_frames, num_HMM_states); % Zbytek po deleni
    % Prida 1 frame k prvnim 'remainder' stavum
    num_frames_per_state(1:remainder) = num_frames_per_state(1:remainder) + 1;
    
    % Prirazeni framu ke stavum
    frame_to_state = zeros(1, num_frames); % Predalokace vektoru pro efektivitu
    current_index = 1; % Ukazatel na zacatek aktualniho bloku framu
    
    % Smycka pres vsechny stavy pro prirazeni framu
    for s = 1:num_HMM_states
        num_frames_in_this_state = num_frames_per_state(s); % Pocet framu v aktualnim stavu 's'
        end_index = current_index + num_frames_in_this_state - 1; % Koncovy index pro framy tohoto stavu
        frame_to_state(current_index:end_index) = s; % Prirazeni cisla stavu 's' odpovidajicim framum
        current_index = end_index + 1; % Posunuti ukazatele na zacatek dalsiho bloku
    end
end