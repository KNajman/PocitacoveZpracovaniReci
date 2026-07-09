@echo off
rem 1. Parametrizace (potřebuješ mít soubor live_param.list obsahující: live_input.wav live_input.fbank)
HCopy -T 1 -C ParamConfig-FBANK -S live_param.list

rem 2. Rozpoznání pomocí HVite (bez interaktivního kalibrování)
HVite -H hmm6/hmmdefs -C LiveConfig-FBANK16 -w wordnet -p -70.0 -s 0 -i live_recout.mlf dict models0 live_input.fbank