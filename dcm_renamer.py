import re
import glob
import fnmatch
import os
import argparse

# the new filename will begin with prefix followed by numbering
prefix = "001_pre_group1_"
# postfix what stays after numbering
postfix = ""
file_extension = ".dcm"

def run(args):
    dcm_folder = args.directory

    # listing all the dcm files in the folder 
    #path_dcm_files = [x for x in glob.glob(os.path.join(dcm_folder,"*.dcm")) if fnmatch.fnmatch(x , '*Slice*')]
    path_dcm_files = [x for x in glob.glob(os.path.join(dcm_folder,"*.dcm"))]

    for i_fullpath in path_dcm_files:
        i_filename = os.path.basename(i_fullpath)
        try:
            numbering = re.search('Slice_(.+?)_', i_fullpath).group(1)
        except AttributeError:
            pass
        
        new_filename = prefix + numbering + postfix + file_extension
        new_file = os.path.join(dcm_folder,new_filename )
        os.rename(i_fullpath, new_file)

    print("Files have been renamed e.g.: %s "% new_file)

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('--directory', help='the directory which contains the dcm files')
    args = parser.parse_args()

    run(args)

