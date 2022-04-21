% Copyright 20xx - 2019. Duke University
function [I info]=readCTSeries(varargin)
%This function reads in a CT image series and returns the image stack, I,
%along with the DICOM header info
%
%   [I info] = readCTSeries() prompts the user to select a folder with the
%   DICOM files. 
%
%   [I info] = readCTSeries(input) reads the DICOMS files
%   located in input
%
%   [I info] = readCTSeries(input,tag) searches for files with the
%   specified tag (e.g., '*.dcm').
%
%   [I info] = readCTSeries(input,tag,sorted) controls if the images are
%   sorted by the slice location acording to the boolean sorted input
%   (default is false). If false, images are sorted by instance number. 
%
%   Written by Justin Solomon, Oct 20, 2014

warning off verbose
old_dir=pwd;

switch nargin
    case 0
        input=uigetdir;
        list=getFileList(input);
        sorted=false;
    case 1
        input=varargin{1};
        list=getFileList(input);
        sorted=false;
    case 2
        input=varargin{1};
        tag=varargin{2};
        cd(input)
        list=dir(tag);
        list=struct2table(list);
        sorted=false;
    case 3
        input=varargin{1};
        tag=varargin{2};
        cd(input)
        list=dir(tag);
        list=struct2table(list);
        sorted=varargin{3};
end

cd(input);
info(1)=dicominfo(list.name{1});
I=zeros(info.Height,info.Width,size(list,3));

for i=1:size(list,1)
    try
        info(i)=dicominfo(list.name{i});
        if isfield(info(i),'ImagePositionPatient')
            slices(i)=info(i).ImagePositionPatient(3);
        else
            slices(i) = i;
        end
        instance(i) = info(i).InstanceNumber;
        try
            im = single(dicomread(info(i)))*info(i).RescaleSlope+info(i).RescaleIntercept;
        catch
            im = single(dicomread(info(i)));
        end
        I(:,:,i)=im;
        
    catch ME
        temp=dicominfo(list.name{i});
        switch ME.message
            case 'Subscripted assignment between dissimilar structures.'
                %This happens when two dicoms have dissimilar header
                %strutures
                [info,temp]=makeStructsHaveSameFields(info,temp); %Make their fields be the same
                info(i)=temp;
            otherwise
                info(i)=info(i-1);
                info(i).SliceLocation=temp.ImagePositionPatient(3);
                info(i).XrayTubeCurrent=temp.XrayTubeCurrent;
        end
        slices(i)=info(i).ImagePositionPatient(3);
        instance(i) = info(i).InstanceNumber;
        try
            im = single(dicomread(list.name{i}))*info(i).RescaleSlope+info(i).RescaleIntercept;
            I(:,:,i)=im;
        catch
            im = single(dicomread(info(i)))*info(i).RescaleSlope+info(i).RescaleIntercept;
            I(:,:,i)=im;
        end
    end
    
end

%sort if needed
if sorted
    [~,IX] = sort(slices);
    info=info(IX);
    I=I(:,:,IX);
else
    [~, IX] = sort(instance);
    info = info(IX);
    I=I(:,:,IX);
end

%cd back to old directory
cd(old_dir);

function list = getFileList(input)

%get a list of all files in the folder
list=dir(input);

%Convert to table
list=struct2table(list);

%filter out directories.
list=list(~list.isdir,:);

%filter out hidden files
ind=strncmp(list.name,'.',1);
list=list(~ind,:);


%find the most common file extension
for i=1:size(list,1)
    [pathstr,name,ext] = fileparts(list.name{i});
    exts{i}=ext;
end
list.ext=exts';
exts=unique(list.ext);
for i=1:length(exts)
    nexts(i)=sum(strcmp(list.ext,exts{i}));
end
[dum ind]=max(nexts);
tag=exts{ind};

ind=strcmp(tag,list.ext);
list=list(ind,:);