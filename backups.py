# compresses Acronis True Image backup chain into tar.xz file

import re, glob, subprocess, os, time
from multiprocessing import Pool
from datetime import datetime

files = glob.glob('*.tib')
groups = {}
pattern = r'b[0-9]+'
name = files[0].split('_')[0]

# group the files by backup chain
for file in files:
    key = re.search(pattern, file).group()
    if key not in groups:
        groups[key] = [file]
    else:
        groups[key].append(file)

# batch compress backup chain with tar and xz
def compress(key):
    # name the archive with the date range of the chain
    times = [os.path.getmtime(file) for file in groups[key]]
    startdate = datetime.utcfromtimestamp(min(times)).strftime('%Y-%m-%d %H-%M-%S')
    enddate = datetime.utcfromtimestamp(max(times)).strftime('%Y-%m-%d %H-%M-%S')
    filename = f'{name} ({startdate})_({enddate}).tar.xz'
    print(f'Compressing backup chain {key} to file {filename}...')
    start = time.time()
    subprocess.run(['tar', '-cJf', filename] + groups[key])
    end = round(time.time() - start, 2)
    print(f'Finished creating {filename} in {end / 60}mi {end % 60}s')

if __name__ == '__main__':
    with Pool(len(groups.keys())) as p:
        print(p.map(compress, groups.keys()))
