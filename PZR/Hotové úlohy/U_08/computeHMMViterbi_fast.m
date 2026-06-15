function [score, path] = computeHMMViterbi_fast (word_feat, word_frames, model_id, hmm, params)
    
    pocet_stavu_HMM=params.HMM_stavu;
    path = zeros(word_frames, 1, 'int32');
    cum_score = -inf(word_frames, pocet_stavu_HMM);
    back_matrix = zeros (word_frames, pocet_stavu_HMM, 'int32');
    
    num_features = size (hmm.Means,3);
    % nasledujici prevod 3-dim matic na 2-dim matice vyrazne zrychli vypocet
    % z puvodnich 3-d matic vyclenime 2-d matice odpovidajici danemu modelu
    hmmM = reshape (hmm.Means (model_id,:,:),[pocet_stavu_HMM,num_features]);
    hmmV = reshape (hmm.Vars (model_id,:,:),[pocet_stavu_HMM,num_features]);
    hmmT = reshape (hmm.Trans (model_id,:,:),[pocet_stavu_HMM,2]);
    hmmC = hmm.Const (model_id,:);
    
    cum_score(1,1) = computeLogGauss (word_feat, hmmM, hmmV, hmmC, 1, 1);
    back_matrix (1,1) = 0;
    for f = 2:word_frames
        cum_score(f,1) =  cum_score(f-1,1) + hmmT(1,1) + computeLogGauss (word_feat, hmmM, hmmV, hmmC, f, 1);
        back_matrix (f,1) = 1;
        smax = min (f,pocet_stavu_HMM);
        for s = 2 : smax  % jaky vyznam ma smax?
            temp = cum_score(f-1,s-1) + hmmT(s-1,2);  % toto je skore pri prechodu z predchoziho stavu
            from = s-1;
            temp2 = cum_score(f-1,s) + hmmT(s,1);     % a toto skore pri setrvani ve stavu
            if (temp < temp2)                         % vybereme z nich to vyssi
                temp = temp2;
                from = s;
            end
            cum_score(f,s) = temp + computeLogGauss (word_feat, hmmM, hmmV, hmmC, f, s); % a pricteme vyst. pr.
            back_matrix (f,s) = from;
        end
    end
    score = cum_score(word_frames,pocet_stavu_HMM);       % vysledne skore
    
    path(word_frames) = pocet_stavu_HMM;                  % zpetne trasovani cesty
    
    for i = (word_frames-1):-1:1
        path(i) = cum_score(i+1, path(i+1));
    end
end

function logGaussian = computeLogGauss(word_feat, hmmM, hmmV, hmmC, f, s)
    feat_vector = word_feat(f,:); % priznakovy vector v danem framu slova
    mean_vector = hmmM(s,:);   % vektor strednich hodnot vsech priznaku v danem stavu
    sigma_vector = hmmV(s,:);  % vektor rozptylu (sigma^2)vsech priznaku v danem stavu
    const_value = hmmC(s);     % log. hodnota konstanty v danem stavu

    logGaussian = const_value - 0.5 * sum(((feat_vector - mean_vector).^2) ./ sigma_vector);
end

