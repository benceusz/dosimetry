# Author: Bence Nemeth
# 2022
# MIT License

import hashlib
import pydicom as dicom
import os, fnmatch
import sys
import csv
from datetime import date, datetime # for subtracting acquisition

# Free DICOM de-identification tools in clinical research: functioning and safety of patient privacy
# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4636522/
# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4636522/table/Tab1/?report=objectonly


tagsToDelete = { 0x00400253,0x00400245,0x00400244,0x00321032,0x00081090,0x00081010,0x00080070,0x00080020,0x00080021,0x00080022,0x00080023,0x00080024,0x00080025,0x0008002A,0x00080030,0x00080031,0x00080032,0x00080033,0x00080034,0x00080035,0x00080050,0x00080080,0x00080081,0x00080090,0x00080092,0x00080094,0x00080096,0x00081040,0x00081048,0x00081049,0x00081050,0x00081052,0x00081060,0x00081062,0x00081070,0x00100010,0x00100020,0x00100021,0x00100030,0x00100032,0x00100040,0x00101000,0x00101001,0x00101005,0x00101010,0x00101040,0x00101060,0x00102150,0x00102152,0x00102154,0x00200010,0x00380300,0x00380400,0x0040A120,0x0040A121,0x0040A122,0x0040A123 }
"""
# list of tags: 
# extra tags what I heard that may be good to be anonymized
0x00400253, \ #
0x00400245, \ # 
0x00400244, \ #
0x00321032, \ #
0x00081090, \ # 
0x00081010, \ # 
0x00080070, \ #

### suggested by article
0x00080020, \ # StudyDate
0x00080021, \ # SeriesDate
0x00080022, \ # AcquisitionDate
0x00080023, \ # ContentDate
0x00080024, \ # OverlayDate
0x00080025, \ # CurveDate
0x0008002A, \ # AcquisitionDatetime
0x00080030, \ # StudyTime
0x00080031, \ # SeriesTime
0x00080032, \ # AcquisitionTime
0x00080033, \ # ContentTime
0x00080034, \ # OverlayTime
0x00080035, \ # CurveTime
0x00080050, \ # AccessionNumber
0x00080080, \ # InstitutionName
0x00080081, \ # InstitutionAddress
0x00080090, \ # ReferringPhysiciansName
0x00080092, \ # ReferringPhysiciansAddress
0x00080094, \ # ReferringPhysiciansTelephoneNumber
0x00080096, \ # ReferringPhysicianIDSequence
0x00081040, \ # InstitutionalDepartmentName
0x00081048, \ # PhysicianOfRecord
0x00081049, \ # PhysicianOfRecordIDSequence
0x00081050, \ # PerformingPhysiciansName
0x00081052, \ # PerformingPhysicianIDSequence
0x00081060, \ # NameOfPhysicianReadingStudy
0x00081062, \ # PhysicianReadingStudyIDSequence
0x00081070, \ # OperatorsName
0x00100010, \ # PatientsName
0x00100020, \ # PatientID
0x00100021, \ # IssuerOfPatientID
0x00100030, \ # PatientsBirthDate
0x00100032, \ # PatientsBirthTime
0x00100040, \ # PatientsSex
0x00101000, \ # OtherPatientIDs
0x00101001, \ # OtherPatientNames
0x00101005, \ # PatientsBirthName
0x00101010, \ # PatientsAge
0x00101040, \ # PatientsAddress
0x00101060, \ # PatientsMothersBirthName
0x00102150, \ # CountryOfResidence
0x00102152, \ # RegionOfResidence
0x00102154, \ # PatientsTelephoneNumbers
0x00200010, \ # StudyID
0x00380300, \ # CurrentPatientLocation
0x00380400, \ # PatientsInstitutionResidence
0x0040A120, \ # DateTime
0x0040A121, \ # Date
0x0040A122, \ # Time
0x0040A123 \ # PersonName
}
"""

"""
# notes
0008,0022, \ # AcquisitionDate
0008,0023, \ # ContentDate
0008,0030, \ # StudyTime
0008,0031, \ # SeriesTime
0008,0032, \ # AcquisitionTime
0008,0033, \ # ContentTime
0008,0050, \ # AccessionNumber
0032,1032, \ # RequestingPhysician
0040,0244, \ # PerformedProcedureStepStartDate
0040,0253, \ # PerformedProcedureStepID
"""
patientNameTag = 0x00100010
patientIDTag = 0x00100020
patientBirthDateTag = 0x00100030
acquisitionDateTag = 0x00080022


def confirmation():
	print("The program will anonymize and overwrite every DICOM file in the folder and in its subfolders!\n\nAre you sure, you want to continue? [y\\n]")
	valid = {'yes': True, 'y': True, 'ye': True,
             "no": False, "n": False}
	while True:
		answer = input('--> ').lower()
		if answer in valid:
			return valid[answer]
		else:
			sys.stdout.write("Please respond with 'yes' or 'no' (or 'y' or 'n').\n")

# walks all the hierarchy of the current folder where the script has been started. Yields all the files.
def find_files(directory):
	for root, dirs, files in os.walk(directory):
		for basename in files:
			filename = os.path.join(root, basename)
			yield filename

# when we do want to store the age
def getDateDifference(d_acq, d_birth):
	d0 = date(1990, 1, 1)
	assert d_birth < d_acq, "Acquisition date is lower then birth date!"
	try:
		datediff = d_acq - d_birth + d0
	except ValueError:
		print("Warning: Date tags may have wrong format...")
	return datediff

# converts to date format
def convert_string_to_date(string_date):
	"""
	string_date: supposed to be a string with format YYYYMMDD
	variables: integers: date_y: YYYY, date_m: MM, date_day: DD
	output: d = datetime.date(YYYY, MM, DD)
	"""
	assert len(dsample)==8, "Not appropriate date length. Date string supposed to be 8 characters long."
	d_year = int(dsample[:4])
	d_month = int(dsample[4:6])
	d_day = int(dsample[6:8])
	d = date(d_year, d_month, d_day)
	return d

# generate a hash from birthday and patientname. With hash we can compare two hashed patients if they are the same or different.
def generateHashForPatient(dcm):
	name = (str(dcm[patientBirthDateTag].value) + str(dcm[patientIDTag].value)).encode('utf-8')
	hasher = hashlib.sha256()
	hasher.update(name)
	oldName = str(dcm[patientNameTag].value)
	oldID = str(dcm[patientIDTag].value)
	dcm[patientNameTag].value = str(hasher.hexdigest())
	dcm[patientIDTag].value = str(hasher.hexdigest())
	date_acq = convert_string_to_date(str(dcm[acquisitionDateTag].value))
	date_birth = convert_string_to_date(str(dcm[patientBirthDateTag].value))

    # calculate the difference of the birth date and acquisition date, and store in the birth day tag : 0x00100030
	dcm[patientBirthDateTag].value = getDateDifference(date_acq, date_birth)  

	return (oldName, oldID, str(hasher.hexdigest()))
	
# delete all the tags (fills with "") stored in tagsToDelete list
def anonymize_dicom(dcm):
	hashCode = generateHashForPatient(dcm)	
	for tagName in tagsToDelete:
		try:
			dcm[tagName].value = ""
		except (AttributeError, KeyError):
			#print(f"{dicom.datadict.get_entry(tagName)[2]:<45} TAG isn't present in the dicom file")
			print("{} TAG isn't present in the dicom file".format(dicom.datadict.get_entry(tagName)[2]))

	dcm.save_as(filename)
	return hashCode

		
def print_dicom(dcm):
	#print(f"{dicom.datadict.get_entry(patientNameTag)[2]:<50} {str(dcm[patientNameTag].value):}")
	print("{} {}".format(dicom.datadict.get_entry(patientNameTag)[2], str(dcm[patientNameTag].value) ) )

	#print(f"{dicom.datadict.get_entry(patientIDTag)[2]:<50} {str(dcm[patientIDTag].value):}")
	print("{} {}".format(dicom.datadict.get_entry(patientIDTag)[2], str(dcm[patientIDTag].value) ) )

	#print(f"{dicom.datadict.get_entry(patientBirthDateTag)[2]:<50} {str(dcm[patientBirthDateTag].value):}")
	print("{} {}".format(dicom.datadict.get_entry(patientBirthDateTag)[2], str(dcm[patientBirthDateTag].value) ) )

	for tagName in tagsToDelete:
		try:
			element = dcm[tagName]
			#print(f"{element.name:<50} {str(element.value)}")
			print("{} {}".format(element.name, str(element.value) ) )

		except (AttributeError, KeyError):
			#print(f"{dicom.datadict.get_entry(tagName)[2]:<50} TAG isn't present in the dicom file")
			print("{} TAG isn't present in the dicom file".format(dicom.datadict.get_entry(tagName)[2] ) )


# Main function: 
# if __name__ == "__main__":


path =  os.path.dirname(os.path.realpath(__file__))

list = False
if "--list" in sys.argv:
	list = True

if (len(sys.argv) > 1 and not list) or len(sys.argv) > 2:
	path = sys.argv[1]
elif len(sys.argv) > 2:
	path = sys.argv[1]

print("Running anonymizer tool in the following directory: " + path)
files = find_files(path)
	
function = None
hashCodes = set()

if list:
	function = print_dicom
else:
	if not confirmation():
		print("Exiting...")
		sys.exit()
	function = anonymize_dicom


for filename in files:
	print("Processing file: " + filename + "\n")
	try:
		dcm = dicom.read_file(filename)
		hashCode = function(dcm)
		if hashCode is not None:
			hashCodes.add(hashCode)
	except:
		print("ERROR! Not a valid DICOM file")
	print("\n#####################################################\n")

# generate and stores hash codes in hash_codes.csv for anonimized patients
if not list:
		with open(path + '/hash_codes.csv', 'w') as csvfile:
			csvwriter = csv.writer(csvfile, delimiter=';', quotechar='|', quoting=csv.QUOTE_MINIMAL)
			csvwriter.writerow(["Name", "ID", "Hash"])
			for patient in hashCodes:
				csvwriter.writerow(patient)
