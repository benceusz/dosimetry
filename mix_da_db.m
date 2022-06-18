function [Dab, path_generated_sequence] = mix_da_db(pathB, Db, pathA, Da, i_percentage, path_outputdir)
    %Example dose split script
    warning off verbose
    % import functions --------------------------------------------------------
    path_mainscript = fileparts(mfilename('fullpath'))
    addpath(path_mainscript)

    %Input values--------------------------------------------------------------
    % 66% image
    % pathA = "C:\Users\nembe\Downloads\andre\Dual_Split_Test_For_Bence\Dual_Split_Test_For_Bence\66\PP Lunge Inspi 1.5  Bl64  3 LCAD  A_100kV"
    %Da = 100; %Dose for Series A (could use units of CTDI or effective mAs). Assuming series A is the high dose scan

    % 33% image
    %pathB = "C:\Users\nembe\Downloads\andre\Dual_Split_Test_For_Bence\Dual_Split_Test_For_Bence\33\PP Lunge Inspi 1.5  Bl64  3 LCAD  B_100kV\"
    %Db = 50;  %Dose for Series A (could use units of CTDI or effective mAs)

    if (path_outputdir == "")
        path_outputdir = fullfile(pathA, '..');
        disp("No outputpath_dir argument. Input path has been set to output path")
    end
    
    tag_da = fix(Da *100 / 150)
    tag_db = fix(Db *100/ 150)

    % Da = 150; %Dose for Series A (could use units of CTDI or effective mAs). Assuming series A is the high dose scan
    % Db = 50;  %Dose for Series A (could use units of CTDI or effective mAs)
    % Dt = .50; %Targeted dose level as a fraction of (Da + Db) (should be a fraction between Db/(Da+Db) and 1)

    %Input values--------------------------------------------------------------
    %Calculate the targeted dose
    % Dab = (Da + Db)*Dt;

    % list of targeted dose 
    % Dabs = [50, 65, 80 , 95, 110, 135, 150]
    % listPercentages = [40, 50, 60, 66, 70 , 80, 90, 100]
    %listPercentages = 40:10:100
    
    %Dabs = (Da + Db)*desiredPercentages / 100
    Dab = (Da + Db)* i_percentage / 100;
%     disp("Series with following Dosis will be calculated:", num2str(Dabs))
%     disp("Series with following Dosis will be calculated:", num2str(Dab))
% 
% 
%     Dab = Dabs(i)
%     i_percentage = listPercentages(i)
    %Calculate the blending weight needed to get that dose level
    if Dab < min(Db,Da)
        warning('Targeted dose level is lower than your lowest dose input image')
    end
    w = (Da*Dab - sqrt(Da^2*Db*Dab + Db^2*Da*Dab - Dab^2*Da*Db)) / (Da*Dab + Db*Dab);
    Dab_check = Da / (w^2 + (1 - 2*w + w^2)*(Da/Db));
    disp(['Requested dose: ' num2str(Dab)])
    disp(['Dose from calculated weighting factor: ' num2str(Dab_check)])

    % check and create the folder if not exists
    path_generated_sequence = fullfile(path_outputdir, strcat(num2str(i_percentage), "from",num2str(tag_da), "_",num2str(tag_db)));
    disp(path_generated_sequence)

    if ~exist(path_generated_sequence, 'dir')
        %Read in the images
        disp("reading ct a")
        [im_a, infoA]=readCTSeries(pathA);
        disp("reading ct B")
        [im_b, infoB]=readCTSeries(pathB);

        %Compute the blended image
        im_ab = w*im_a + (1-w)*im_b;


        if ~exist(path_generated_sequence, 'dir')
           mkdir(path_generated_sequence)
        end
        disp(['Output folder: ' path_generated_sequence]); 

        writeDicoms(path_generated_sequence, im_ab, infoA);
    else
        disp(["The requested image already exist.", path_generated_sequence," Skipping loop. Turn flag_overwrite to True if you want to overwrite"])
    end
end