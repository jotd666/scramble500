import os,bitplanelib,json
from PIL import Image

tile_width = 16
tile_height = 8

def extract_block(img,x,y):
    return tuple(img.getpixel((x+i,y+j)) for j in range(tile_height) for i in range(tile_width))


palette = [(0,0,0),(240,0,0),(0,0,240),(240,240,0)]

def process_map(level_index):
    img = Image.open("scramble_gamemap_l{}.png".format(level_index))


##            p = img.getpixel((x+4,y+3))  # this image may be palletized: contains black (0) and green (1)
##            if p and p!=(0,0,0):
##                dot_matrix[j][ii:ii+6] = [1]*6
##                row.append(j)
##        rows.append(row)

    nb_h_tiles = img.size[0]//tile_width
    nb_v_tiles = img.size[1]//tile_height

    tile_dict = {}
    tile_id = 1

    tile_id_to_xy = {}

    matrix = []
    for xtile in range(0,nb_h_tiles):
        x = xtile * tile_width
        column = []
        for ytile in range(0,nb_v_tiles):
            y = ytile * tile_height
            # extract 16x16 block
            blk = extract_block(img,x,y)
            s = set(blk)
            if len(s)!=1:
                tinfo = tile_dict.get(blk)
                if not tinfo:
                    # tile not already found: create
                    tinfo = tile_id
                    tile_id += 1
                    tile_dict[blk] = tinfo
                    tile_id_to_xy[tinfo] = (x,y)

                column.append({"tile_id":tinfo,"x":x,"y":y})
        matrix.append(column)

        for k,(x,y) in tile_id_to_xy.items():
            outname = "tiles/tile_{}.png".format(k)
            ti = Image.new("RGB",(tile_width,tile_height))
            ti.paste(img,(-x,-y))
            ti.save(outname)

    return matrix,{v:k for k,v in tile_dict.items()}

m,blocks = process_map(1)

# dump


