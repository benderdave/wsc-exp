ENCRYPT_DATA_DIR = @osx? "/Volumes/VERACRYPT1" : (@linux? "/media/veracrypt1" : error("Unrecognized platform"))
