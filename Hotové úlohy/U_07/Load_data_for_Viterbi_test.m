clear;

load ('word_features-ENE.mat', 'word_features', 'word_frames', 'word_class', 'train_set', 'test_set', 'num_HMM_states', 'hmmTrans','hmmMeans', 'hmmVars', 'hmmConst','hmmClass','scores_to_check', 'accuracy');

% nactena data obsahuji zpracovane nahravky od osoby 79, zparametrizovana
% do jednoho priznaku (ENE) a rozdelena do tren. a test. setu, 
% a dale modely 10 cislovek natrenovanych na sadach 01 az 03 

% vyznam promennych
% slova
% word_features  - matice 50 x 197 - hodnoty ENE pro kazde slovo (uz po detekci zacatku a konce)
% word_frames - vektor 50 x 1 - pocet framu kazdeho slova (po detekci zacatku a konce)
% word_class - vektor 1 x 50 - trida kazdeho slova (cisla 0 - 9)
% train set - vektor 1 x 30 - indexy slov (cisla v rozsahu 1 - 50) pouzitych pro pro trenovani
% test set - vektor 1 x 20 - indexy slov (cisla v rozsahu 1 - 50), ktere pouzijete pro pro testovani

% modely natrenovane na tren. setu osoby 79
% num_HMM_states - skalar - pocet stavu (stejny u vsech 10 modelu), zde = 6
% hmmTrans - matice 10 x 6 x 2 matice prechodovych pravdepodobnosti pro modely a jejich stavy
%            posledni index: 1 - pravdepodobnost setrvani, 2 - pravd. prechodu do soused. stavu   
%            pro urychleni vypoctu jsou tyto hodnoty uz zlogaritmovany
% hmmMeans - matice 10 x 6 - stredni hodnota gaussovky pro kazdy model a stav 
% hmmVars - matice 10 x 6 - rozptyl (sigma^2) gaussovky pro kazdy model a stav
% hmmConst - matice 10 x 6 - konstanta gaussovky pro kazdy model a stav (viz prednaska)
% hmmClass - vektor 1 x 10 - trida kazdeho modelu (0 ... slovo "nula")

% hodnoty pro kontrolu vysledku 
% scores_to_check - vektor 1 x 200, jsou zde uvedeny vysledne hodnoty skore
% pro vsechna potrebna porovnani, takze napr. prvnich 10 hodnot jsou skore
% prvniho slova v testovacim souboru dosazene pro vsech 10 modelu, 
% dalsich 10 hodnot jsou skore 2. slova, atd.
% accuracy - dosazena uspesnost pro techto 20 test. slov = 75 %
% 
