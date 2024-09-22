import subprocess,os,glob,shutil

progdir = os.path.abspath(os.path.join(os.path.dirname(__file__),os.pardir))

gamename = "scramble"
# JOTD path for cranker, adapt to wh :)
os.environ["PATH"] += os.pathsep+r"K:\progs\cli"

cmd_prefix = ["make","-f","makefile"]


subprocess.check_call(cmd_prefix+["clean"],cwd=os.path.join(progdir,"src"))
subprocess.check_call(["cmd","/c","convert_sounds.py"],cwd=os.path.join(progdir,"assets"))
subprocess.check_call(["cmd","/c","convert_sprites.py"],cwd=os.path.join(progdir,"assets"))
subprocess.check_call(cmd_prefix,cwd=os.path.join(progdir,"src"))
# create archive

outdir = os.path.join(progdir,f"{gamename}_HD")
if os.path.exists(outdir):
    for x in glob.glob(os.path.join(outdir,"*")):
        os.remove(x)
else:
    os.mkdir(outdir)
for file in ["readme.md",gamename,f"{gamename}.slave"]:
    shutil.copy(os.path.join(progdir,file),outdir)

shutil.copy(os.path.join(progdir,f"{gamename}.info"),outdir)
#shutil.copy(os.path.join(progdir,"amidar.jpg"),outdir)

# pack the file for floppy
subprocess.check_output(["cranker_windows.exe","-f",os.path.join(progdir,gamename),"-o",os.path.join(progdir,f"{gamename}.rnc")])