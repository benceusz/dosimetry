function writeDicoms(output,I,info, modality_string)
uid = dicomuid;
%Rescale and shift image data
slope=info(1).RescaleSlope;
intercept=info(1).RescaleIntercept;
I=int16(I./slope-intercept);
%sn = info(1).SeriesNumber;
for i=1:size(I,3) 
    %get the source dicom filename
    source=info(i).Filename;
    [pathstr, name, ext] = fileparts(source);
    info(i).SeriesInstanceUID=uid;  
    %write the dicom file
    %dicomwrite(I(:,:,i),[output filesep  name ext],info(i))
    % output_filename = [output filesep name ext];
    output_filename = strcat(output, filesep ,name, ext);
    info(i).Modality = modality_string;
    info(i).SeriesNumber = modality_string;
    dicomwrite(I(:,:,i), output_filename ,info(i)); 
    %dicomwrite(I(:,:,i),"C:\Users\nembe\Downloads\andre\test.dcm",info(i)) 
end
disp(['dcm have been saved to:', output])
end
