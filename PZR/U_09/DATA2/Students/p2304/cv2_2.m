clear;
close all;
clc;

frame_distance=0.01;%10ms
frame_size=0.025;%25ms
energy_treshold=20.5;

student_id = "2304";%id studenta: 2304 Linhart

samples_complete = zeros(0,0);
for batch_num=1:5
    for sample_num=0:9
        [x,x_fs] = audioread(sprintf('c%d_p%s_s0%d.wav', ...
            sample_num,student_id,batch_num),"native");

        sample_distance = x_fs*frame_distance;
        sample_count = x_fs*frame_size;
        %pridani sumu
        x = add_noise(x);
        
        %vykreslovani vstupu
        figure();
        t=1:length(x);
        subplot(3,1,1);
        plot(t,x);
        title(sprintf('Základní signál: Číslice %d Sada %d', ...
            sample_num,batch_num))

        %vypocet energie a zcr
        energy = zeros(1,floor(length(x)/sample_distance)-3);
        zcr = zeros(1,floor(length(x)/sample_distance)-3);
        for i=0:length(energy)-1
            for j=1:sample_count
                energy(i+1) = energy(i+1)+x(i*sample_distance+j)^2;
                if j>1
                    zcr(i+1) = zcr(i+1) + abs(sign(x(i*sample_distance+j)) ...
                        -sign(x(i*sample_distance+j-1)));
                end
            end
            zcr(i+1) = zcr(i+1)/2;
            energy(i+1) = log(energy(i+1));
        end

        %nalezeni krajnich bodu
        [sample_start,sample_end] = find_sample_start_end(energy,energy_treshold);

        %vykreslovani energie a zcr
        xline(sample_start*160);
        xline(sample_end*160);
        t=1:length(energy);
        subplot(3,1,2);
        plot(t,energy);
        title("Energie")
        xline(sample_start);
        xline(sample_end);
        subplot(3,1,3);
        plot(t,zcr);
        title("ZCR")
        xline(sample_start);
        xline(sample_end);

        %spojeni nahravek pro prehravani
        samples_complete = cat(1,samples_complete,x(sample_start*160:sample_end*160));
        

    end
end
%soundsc(samples_complete,x_fs);



function y = add_noise(x)
    x = x + (randi(3, 32000, 1, 'int16') - 2);
    y =filter([1 -0,97], 1, x);
end

function [found_start,found_end] = find_sample_start_end(energy,energy_treshold)
    j=1;
    while energy(j)<energy_treshold && j+1<length(energy)
        j=j+1;
    end
    found_start= j;%zacatek samplu
    sample_timeout = 0;%
    while (sample_timeout<40 && j<length(energy))%40 samplů menších než treshold
        if energy(j)<energy_treshold
            sample_timeout = sample_timeout+1;
        else
            found_end=j;
            sample_timeout = 0;
        end
        j=j+1;
    end
end