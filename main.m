% main script to calculate dfifferent doses for all the patients
warning('off','all')
listPercentages = [37, 39, 45, 55, 66, 100];
pathPreprocessDicoms = "/media/nraresearch/Elements/Dual_Split_Projekt_ETH/preprocessed_dual_split"
pathOutputGenerated = "/media/nraresearch/Elements/Dual_Split_Projekt_ETH/generated_dicoms_all"

%pathPreprocessDicoms = "/home/nraresearch/research/project_dosimetry/data_example/preprocessed_dual_split"
%pathOutputGenerated = "/home/nraresearch/research/project_dosimetry/data_example/generated_dicoms_all"

if ~exist(pathOutputGenerated, 'dir')
   mkdir(pathOutputGenerated)
end

list_patients = GetSubDirsFirstLevelOnly(pathPreprocessDicoms);

for i = 1:length(list_patients)

    length(list_patients)
    i_patient = list_patients(i)
    outputFolderPatient = fullfile(pathOutputGenerated, i_patient);

    if exist(outputFolderPatient, 'dir')
       disp(["Patient dir already exist", i_patient])
       continue
    end
    path_folder33 = fullfile(pathPreprocessDicoms, i_patient, "33");
    list_33  = GetSubDirsFirstLevelOnly(path_folder33);
    path33 = fullfile(path_folder33, list_33{1});

    path_folder66 = fullfile(pathPreprocessDicoms, i_patient, "66");
    list_66  = GetSubDirsFirstLevelOnly(path_folder66);
    path66 = fullfile(path_folder66, list_66{1});

    path_folder100 = fullfile(pathPreprocessDicoms, i_patient, "100");
    list_100  = GetSubDirsFirstLevelOnly(path_folder100);
    path100 = fullfile(path_folder100, list_100{1});

    if ~exist(outputFolderPatient, 'dir')
       mkdir(outputFolderPatient)
    end

     for p = 1:length(listPercentages)
         try
             i_percentage = listPercentages(p)
             disp(["processing patient:", i_patient, " with dose percentage: ", num2str(i_percentage)])
             i_percentage = listPercentages(p);
             mix_da_db(path33, 50, path66, 100, i_percentage, outputFolderPatient);
         catch
             disp(["ERROR: Crushed calculation at patient: ", outputFolderPatient])
         end
     end

    % mix 33 and 100 to get 66
    disp(["processing patient:", i_patient, " with dose percentage: ", num2str(66)])
    try
        mix_da_db(path33, 50, path100, 150, 66, outputFolderPatient);
    catch
        disp(["ERROR: Crushed calculation at patient: ", outputFolderPatient])
        %rmdir(outputFolderPatient)
    end

    % mix 66 and 100 to get 100
    try
        mix_da_db(path66, 100, path100, 150, 150 , outputFolderPatient);
    catch
        disp(["ERROR: Crushed calculation at patient: ", outputFolderPatient])
        %rmdir(outputFolderPatient)
    end

end


function [subDirsNames] = GetSubDirsFirstLevelOnly(parentDir)
    % Get a list of all files and folders in this folder.
    files = dir(parentDir);
    % Get a logical vector that tells which is a directory.
    dirFlags = [files.isdir];
    % Extract only those that are directories.
    subDirs = files(dirFlags);
    subDirsNames = cell(1, numel(subDirs) - 2);
    for i=3:numel(subDirs)
        subDirsNames{i-2} = subDirs(i).name;
    end
end
