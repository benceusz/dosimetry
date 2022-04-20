%Example dose split script

% import functions --------------------------------------------------------
path_mainscript = fileparts(mfilename('fullpath'))
addpath(path_mainscript)

%Input values--------------------------------------------------------------
% 66% image
pathA = "C:\Users\nembe\Downloads\andre\Dual_Split_Test_For_Bence\Dual_Split_Test_For_Bence\66\PP Lunge Inspi 1.5  Bl64  3 LCAD  A_100kV"
Da = 100; %Dose for Series A (could use units of CTDI or effective mAs). Assuming series A is the high dose scan

% 33% image
pathB = "C:\Users\nembe\Downloads\andre\Dual_Split_Test_For_Bence\Dual_Split_Test_For_Bence\33\PP Lunge Inspi 1.5  Bl64  3 LCAD  B_100kV\"
Db = 50;  %Dose for Series A (could use units of CTDI or effective mAs)

pathOutput = ""
if (pathOutput == "")
    pathOutput = fullfile(pathA, '..', '..')
end

% Da = 150; %Dose for Series A (could use units of CTDI or effective mAs). Assuming series A is the high dose scan
% Db = 50;  %Dose for Series A (could use units of CTDI or effective mAs)
% Dt = .50; %Targeted dose level as a fraction of (Da + Db) (should be a fraction between Db/(Da+Db) and 1)

%Input values--------------------------------------------------------------
%Calculate the targeted dose
% Dab = (Da + Db)*Dt;

% list of targeted dose 
% Dabs = [50, 65, 80 , 95, 110, 135, 150]
% listPercentages = [40, 50, 60, 66, 70 , 80, 90, 100]
listPercentages = 40:10:100
Dabs = (Da + Db)*desiredPercentages / 100

disp("Series with following Dosis will be calculated:", num2str(Dabs))

for i=1:length(Dabs)
    Dab = Dabs(i)
    i_percentage = listPercentages(i)
    %Calculate the blending weight needed to get that dose level
    if Dab < min(Db,Da)
        warning('Targeted dose level is lower than your lowest dose input image')
    end
    w = (Da*Dab - sqrt(Da^2*Db*Dab + Db^2*Da*Dab - Dab^2*Da*Db)) / (Da*Dab + Db*Dab);
    Dab_check = Da / (w^2 + (1 - 2*w + w^2)*(Da/Db));
    disp(['Requested dose: ' num2str(Dab)])
    disp(['Dose from calculated weighting factor: ' num2str(Dab_check)])

    %Read in the images
    [im_a, infoA]=readCTSeries(pathA);
    [im_b, infoB]=readCTSeries(pathB);
    
    %Compute the blended image
    im_ab = w*im_a + (1-w)*im_b;
    
    % check and create the folder if not exists
    outputfolder = fullfile(pathOutput, strcat('dose_',num2str(i_percentage))); 
 
    if ~exist(outputfolder, 'dir')
       mkdir(outputfolder)
    end
    disp(['Output folder: ' outputfolder]); 

    writeDicoms(outputfolder, im_ab, infoA); 
end