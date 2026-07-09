function [score, path] = ComputeViterbi (word_feat, word_frames, model_id, hmm, params)

pocet_stavu_HMM = params.HMM_stavu;
cum_score = -inf(word_frames, pocet_stavu_HMM);
back_matrix = zeros(word_frames, pocet_stavu_HMM); % Uchovává index předchozího stavu

num_features = size(hmm.Means, 3);

% Extrakce parametrů pro daný model_id (jako v uživatelské verzi)
hmmM = reshape (hmm.Means (model_id,:,:),[pocet_stavu_HMM,num_features]);
hmmV = reshape (hmm.Vars (model_id,:,:),[pocet_stavu_HMM,num_features]);
hmmT = reshape (hmm.Trans (model_id,:,:),[pocet_stavu_HMM,2]);
hmmC = hmm.Const (model_id,:); % Zůstává řádkový vektor

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

% zpetne trasovani cesty
path = zeros(word_frames, 1);
path(word_frames) = pocet_stavu_HMM;
for i = (word_frames-1):-1:1
    path(i) = back_matrix(i+1, path(i+1));
end
end

function logGaussian = computeLogGauss(word_feat, hmmM, hmmV, hmmC, f, s)
feat_vector = word_feat(f,:);
mean_vector = hmmM(s,:);
sigma_vector = hmmV(s,:);
const_value = hmmC(s);

logGaussian = const_value - 0.5 * sum(((feat_vector - mean_vector).^2) ./ sigma_vector);
end