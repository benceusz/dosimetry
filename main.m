% main script to calculate dfifferent doses for all the patients

listPercentages = [37, 39, 45, 55, 66, 100];
pathPreprocessDicoms = "/media/nraresearch/Elements/Dual_Split_Projekt_ETH/preprocessed_dual_split"
pathOutputGenerated = "/media/nraresearch/Elements/Dual_Split_Projekt_ETH/generated_dicoms_all"

if ~exist(pathOutputGenerated, 'dir')
   mkdir(pathOutputGenerated)
end

list_patients = GetSubDirsFirstLevelOnly(pathPreprocessDicoms);

for i = 1:length(list_patients)
    i_patient = list_patients(i)
    
    outputFolderPatient = fullfile(pathOutputGenerated, i_patient);

    if ~exist(outputFolderPatient, 'dir')
       mkdir(outputFolderPatient)
    end

    path_folder33 = fullfile(pathPreprocessDicoms, i_patient, "33");
    list_33  = GetSubDirsFirstLevelOnly(path_folder33);
    path33 = fullfile(path_folder33, list_33{1});

    path_folder66 = fullfile(pathPreprocessDicoms, i_patient, "66");
    list_66  = GetSubDirsFirstLevelOnly(path_folder66);
    path66 = fullfile(path_folder66, list_66{1});

    for p = 1:length(listPercentages)
        disp(["processing patient:", i_patient, " with dose percentage: ", num2str(i_percentage)])
        i_percentage = listPercentages(p);
        mix33_66(path33,path66, i_percentage, outputFolderPatient);
    
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