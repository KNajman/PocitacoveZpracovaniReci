mkdir hmm0 hmm1 hmm2 hmm3 hmm4 hmm5 hmm6
HCompV -C TrainConfig-MFCC39 -f 0.01 -m -S train.scp -M hmm0 proto-8s-39f
HCompV -C TrainConfig-MFCC39 -f 0.01 -m -S train.scp -M hmm0 proto-3s-39f