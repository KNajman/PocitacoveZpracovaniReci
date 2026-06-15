function spec_channels = ComputeFrameSpec (frame, num_channels)
% vypocita a vrati K = num_channels spektralnich koeficientu pro jeden frame
% signalu
    persistent init
    persistent hamming512;
    persistent zeroframe512;
    
    if isempty(init)
        hamming512 = hamming (512);
        zeroframe512 = zeros (512,1);
        init = 1;
    end

    frame512 = zeroframe512;
    frame512(1:size(frame,1))= frame;
    frame512 = frame512 .* hamming512;
    spectrum = fft(frame512,512); 
    amp_spectrum = abs (spectrum(1:256));
    step = 256 / num_channels;
    amp_spec = reshape (amp_spectrum, [num_channels, step]);  
    spec_channels = mean(amp_spec,2);        
end
    
 