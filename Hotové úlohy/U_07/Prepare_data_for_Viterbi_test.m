%clear;

 % word_features; word_frames; word_class; word_person; word_set;

 % num_HMM_states; hmmTrans; hmmMeans; hmmVars; hmmConst; hmmClass;

files = readlines("U_07\FileList_p0079.txt");
num_records = size (files,1);
speaker_set = 79; % zde pouze osoba 79
num_speakers = size (speaker_set,2);
num_classes = 10;


% zakladni parametry
num_samples_in_record = 32000;
num_samples_in_frame = 400;
frame_shift =  160;
num_frames_in_record = floor((num_samples_in_record - num_samples_in_frame)/frame_shift);

% nastavitelne parametry a prepinace
endp_thresh_rate = 0.40;  % nastaveni prahu pro endpoint
endp_shift = 10;   % nastaveni posunu zacatku a konce vuci nalezenym hodnotam
train_set_limit = 3;  % cislo nejvyssi sady pouzite v tren. souboru (u SD max. 3, u SI max. 5)
num_HMM_states = 6;
max_iter = 10;
type_method = 'HMM';
type_features = 'CEP';
type_speaker_dep = 'SD';

% pro kazdy soubor priznaku stanovime pocet priznaku, aby se dalo konkretne alokovat pole
if (type_features == 'ENE')   % energie
    num_features = 1;
end
if (type_features == 'CEP')   % kepstralni priznaky (MFCC)
    num_features = 12;
end

word_features = zeros(num_records, num_frames_in_record,num_features);
word_frames = zeros(num_records,1);

disp("Now parameterizing");

for n = 1:num_records
    %files(n, :)      % vypis jmeno zpracovavane nahravky
    k = files(n,:).split("\");
    k=k(end).split('_');
    word_class(n) = str2double(erase(k(1),'c')); % identifikator tridy nam bude slouzit pro rozpoznavani
    word_person(n) = str2double(erase(k(2),'p'));  % identifikator osoby
    word_set(n) = str2double(erase(k(3),["s",".wav"]));    % identifikator sady

    %%% nacteni nahravky a nalezeni hranic slova
    [sig, Fs] = audioread(files(n, :));  % nacti nahravku
    [cut, num_frames] = endpoint (files(n, :), sig, num_frames_in_record, num_samples_in_frame, frame_shift, endp_thresh_rate, endp_shift);
    %[cut, num_frames] = No_endpoint (files(n, :), sig, num_frames_in_record, num_samples_in_frame, frame_shift, endp_thresh_rate);
    word_frames (n) = num_frames;

    %%% vypocet priznaku
    word_features_n = reshape (word_features (n,:,:),[num_frames_in_record,num_features]);

    for f = 1:num_frames
        first_sample = (f-1)*frame_shift+1;
        frame = cut (first_sample:first_sample + num_samples_in_frame - 1);
        if (type_features == 'ENE')
            word_features (n,f,1) = computeFrameEnergy (frame);
        end
        if (type_features == 'CEP')  % kepstralni priznaky (MFCC)
            [cep_coeff, mel_fbank] = computeFrameMFCC(frame, 26, num_features, 16000);
            word_features (n,f,1:num_features) = cep_coeff;
        end
    end


end

hmmTrans = zeros (num_classes, num_HMM_states, 2);
hmmMeans = zeros (num_classes, num_HMM_states, num_features);
hmmVars = zeros (num_classes, num_HMM_states, num_features);
hmmConst = zeros (num_classes, num_HMM_states);
hmmClass = 0:num_classes-1;

%%% zde zacina vlastni trenovani a testovani
tic
total_correct = 0; total_num_test = 0;
i = 0;
already_trained = 0;
for sp = 1:1 % v tomto pripade pouze jedna osoba
    %%% vytvoreni testovaci a trenovaci sady
    if (type_speaker_dep == 'SD')
        [train_set, test_set, num_test, num_train] = makeTrainTestSetsSD (num_records, speaker_set, sp, train_set_limit);

        %%% trenovani
        disp("Now training");
        for c = 1:num_classes
            ret =  trainHMM (c, train_set, num_train, num_frames_in_record, max_iter);
        end
    end


    %%% rozpoznavani a vyhodnocovani
    disp("Now recognizing");
    num_correct = 0;
    j = 0;
    for te = 1:num_test
        tested = test_set (te);
        word_features_tested = reshape (word_features (tested,:,:),[num_frames_in_record,num_features]);
        for model_id = 1:num_classes
            scr = computeHMMViterbi_fast (word_features_tested, word_frames (tested), model_id); % vypocet skore kazdeho modelu
            score(model_id) = scr; % ulozeni skore do pole pro nalezeni maxima
            % ulozeni skore pro kontrolni ucely
            j = j+1;
            scores_to_check(j) = scr;

        end
        [max_score, best] = max (score);
        true_class = word_class(tested);
        pred_class = hmmClass(best);
        result = 0;
        if (true_class == pred_class)
            result = 1;
        end
        num_correct = num_correct + result;
    end
    accuracy = num_correct/num_test * 100;
    display_text = ['Accuracy for person ',num2str(speaker_set(sp)),' is: ',  num2str(accuracy)]; disp(display_text)
end

save ('word_features-ENE.mat', 'word_features', 'word_frames', 'word_class', 'train_set', 'test_set', 'num_HMM_states', 'hmmTrans','hmmMeans', 'hmmVars', 'hmmConst','hmmClass','scores_to_check', 'accuracy');

