#!/usr/bin/env python3

# Written for Python 3.x

import glob, sys, re, os, shutil

test = '--test' in sys.argv
use_file = '--file' in sys.argv
if test:
    sys.argv.remove('--test')

if use_file:
    file = sys.argv[sys.argv.index('--file') + 1]
    with open(file) as f:
        keywords = [line.strip() for line in f.readlines()]
else:
    keywords = sys.argv

# get list of video and subtitle files
print('Getting files...')
mp4s = glob.glob('./**/*.mp4', recursive=True)
mkvs = glob.glob('./**/*.mkv', recursive=True)
avis = glob.glob('./**/*.avi', recursive=True)
srts = glob.glob('./**/*.srt', recursive=True)

files = mp4s + mkvs + avis + srts

newfiles = [f".{file[file.rfind('/'):]}" for file in files]

# remove supplied keywords from filenames
print('Removing keywords...')
keywords.sort(key=len, reverse=True)
for keyword in keywords:
    word = keyword.replace('[', r'\[').replace(']', r'\]').replace('(', r'\(').replace(')', r'\)')
    pattern = rf"({word})"
    regex = re.compile(pattern, flags=re.MULTILINE)
    newfiles = [re.sub(pattern, '', file) for file in newfiles]
    
# remove excess dots from filenames
print('Removing excess dots.....................')
pattern = r"\.(?!\/)(?!.{3}$)"
dot_regex = re.compile(pattern, flags=re.MULTILINE)
newfiles = [re.sub(pattern, ' ', file) for file in newfiles]

# remove excess spaces caused by previous subs
print('Removing       excess                       spaces...')
pattern = r" {2,}"
regex = re.compile(pattern, flags=re.MULTILINE)
newfiles = [re.sub(pattern, '', file) for file in newfiles]

# rename + move files, or output dry run
if test:
    [print('./output/' + file[2:]) for file in newfiles]
else:
    print('Renaming files...')
    os.mkdir('output')
    for index, file in enumerate(files):
        os.replace(file, './output/' + newfiles[index][2:])
    # cleanup resulting folders left behind
    print('Cleaning up directory tree...')
    cleanup = [item for item in os.listdir() if os.path.isdir(item)]
    cleanup.remove("output")
    [shutil.rmtree(item, ignore_errors=True) for item in cleanup]
