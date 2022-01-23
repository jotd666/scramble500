import os,bitplanelib,glob
from PIL import Image

def extract_stars_palette():
    black = (0,0,0)

    stars_colors = set()


    for imgname in glob.glob("../snap/*.png"):
        img = Image.open(imgname)
        for x in range(1,img.size[0]-1):
            for y in range(1,img.size[1]-1):
                p = img.getpixel((x,y))
                if isinstance(p,int):
                    break
                if p != black:
                    all_neighbours_black = True
                    # look for all black neighbours
                    for x1 in range(x-1,x+2):
                        for y1 in range(y-1,y+2):
                            if x!=x1 and y!=y1:
                                p1 = img.getpixel((x1,y1))
                                if p1 != black:
                                    all_neighbours_black = False
                                    break
                        if not all_neighbours_black:
                            break
                    if all_neighbours_black:
                        stars_colors.add(tuple(x & 0xE0 for x in p))
    stars_colors = list(stars_colors)

    del stars_colors[48:]

    bitplanelib.palette_dump(stars_colors,"../src/stars_palette.s")

def extract_playfield_palettes():
    img = Image.open("sprites.png")  # has a palette
    colors = []
    palette = img.getpalette()

    for j in range(2):
        x_start = 128+16*j
        for i in range(7):
            y = 102+4*i
            for k in range(4):
                p = img.getpixel((x_start+k*4,y))*3
                rgb = (palette[p],palette[p+1],palette[p+2])
                colors.append(rgb)
    bitplanelib.palette_dump(colors,"../src/playfield_palettes.s")

extract_playfield_palettes()