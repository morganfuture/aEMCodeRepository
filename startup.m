% startup.m
host='Katz';
disp([which('startup') ' on ' host]);

setenv('HOSTNAME',host);
cd ~/;
basePath='~/aEMCodeRepository/';
folders={'aLibs/EMBase'
         'aLibs/EMCCD'
         'aLibs/EMIO'
         'aLibs/EMIOUtils'
         'aLibs/EMSpec'
         'aLibs/GriddingLib'
         'aLibs/MEX'      
         'aLibs/Others'
         'aLibs/Others/bfmatlab'
         'FourierReconstruction'
         'K2Camera'
         'MultiExposure'
         'Relion'
         'Realtime'
         'RSC'
         'RSC-Apps'
         'RSC-utilities'
         'RSCPicking'
         'RSCReconstruct'
         'RSCSimulate'
         'RSCVesicleFinder'
         'RSCAnalysis'
         'AMPAR'
%          'RSCAdaptiveBasis'
%          'RSCAdaptiveBasis/utils'
         };
         
for i=1:numel(folders)
    addpath([basePath folders{i}]);
end;
% disp('Using desktop RSCReconstruct');
% addpath('/Users/fred/Desktop/RSCReconstruct');
% addpath('/Users/fred/Dropbox/OHSU_images/matlabprogram');
% disp('Using Liguo''s code');

