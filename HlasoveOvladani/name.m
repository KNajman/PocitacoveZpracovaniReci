function [output] = name(input)
    % Spuštění HTK dávky na pozadí
[status, cmdout] = system('matlab_recognize.bat');
if status ~= 0
    errordlg('Chyba při běhu HTK skriptu!');
    return;
end
end