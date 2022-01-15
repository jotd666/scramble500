import os,bitplanelib,json
from PIL import Image


tile_width = 8
tile_height = 8
sprites_dir = "../sprites"
outdir = "tiles"

def extract_block(img,x,y):
    return tuple(img.getpixel((x+i,y+j)) for j in range(tile_height) for i in range(tile_width))


main_palette = [(0,0,0),
                (240,64,0),     # dark orange
                (240,240,0),    # yellow
                (1,208,208),    # cyan
                (240,240,240),  # white
                (240,0,0),  # red
                (0,240,0),  # green
                (128,0,208), # purple
                ]

# pad
main_palette += [(0,0,0)] * (16-len(main_palette))

tiles_palette = [(0,0,0),(240,0,0),(0,0,240),(240,240,0)]

bitplanelib.palette_dump(main_palette,r"../src/palette.s",as_copperlist=False)



def process_maps():
    tile_dict = {}
    tile_id = 1

    max_level = 6
    dump_tiles = False
    for level_index in range(1,max_level+1):
        img = Image.open("scramble_gamemap_l{}.png".format(level_index))


    ##            p = img.getpixel((x+4,y+3))  # this image may be palletized: contains black (0) and green (1)
    ##            if p and p!=(0,0,0):
    ##                dot_matrix[j][ii:ii+6] = [1]*6
    ##                row.append(j)
    ##        rows.append(row)

        nb_h_tiles = img.size[0]//tile_width
        nb_v_tiles = img.size[1]//tile_height
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
                outname = "tiles/tile_{:02}.png".format(k)
                ti = Image.new("RGB",(tile_width,tile_height))
                ti.paste(img,(-x,-y))
                if dump_tiles:
                    ti.save(outname)

                outname = "{}/tile_{:02}.bin".format(sprites_dir,k)
                bitplanelib.palette_image2raw(ti,outname,tiles_palette,palette_precision_mask=0xF0)



def process_tiles(json_file,game_palette_16):
    with open(json_file) as f:
        tiles = json.load(f)

    default_width = tiles["width"]
    default_height = tiles["height"]
    default_horizontal = tiles["horizontal"]

    x_offset = tiles["x_offset"]
    y_offset = tiles["y_offset"]

    sprite_page = tiles["source"]

    sprites = Image.open(sprite_page)

    name_dict = {"scores_{}".format(i):"scores_"+n for i,n in enumerate(["200","400","800","1600","3200"])}
    # we first did that to get the palette but we need to control
    # the order of the palette


    for object in tiles["objects"]:
        if object.get("ignore"):
            continue
        generate_mask = object.get("generate_mask",False)

        blit_pad = object.get("blit_pad",True)
        name = object["name"]

        start_x = object["start_x"]+x_offset
        start_y = object["start_y"]+y_offset
        horizontal = object.get("horizontal",default_horizontal)
        width = object.get("width",default_width)
        height = object.get("height",default_height)


        nb_frames = object.get("frames",1)
        for i in range(nb_frames):
            if horizontal:
                x = i*width+start_x
                y = start_y
            else:
                x = start_x
                y = i*height+start_y

            area = (x, y, x + width, y + height)
            cropped_img = sprites.crop(area)
            if nb_frames == 1:
                cropped_name = os.path.join(outdir,"{}.png".format(name))
            else:
                cropped_name = os.path.join(outdir,"{}_{}.png".format(name,i))
            cropped_img.save(cropped_name)

            # save
            x_size = cropped_img.size[0]
            sprite_number = object.get("sprite_number")
            sprite_palette = object.get("sprite_palette")
            if sprite_number is not None:
                if x_size != 16:
                    raise Exception("{} (frame #{}) width (as sprite) should 16, found {}".format(name,i,x_size))
                if sprite_palette:
                    sprite_palette = [tuple(x) for x in sprite_palette]
                    bitplanelib.palette_dump(sprite_palette,"../{}/{}.s".format("src",name))
                else:
                    sprite_palette_offset = 16+(sprite_number//2)*4
                    sprite_palette = game_palette[sprite_palette_offset:sprite_palette_offset+4]
                bin_base = "{}/{}_{}.bin".format(sprites_dir,name,i) if nb_frames != 1 else "{}/{}.bin".format(sprites_dir,name)
                print("processing sprite {}...".format(name))
                bitplanelib.palette_image2sprite(cropped_img,bin_base,
                    sprite_palette,palette_precision_mask=0xF0)
            else:
                # blitter object
##                if x_size % 16:
##                    raise Exception("{} (frame #{}) with should be a multiple of 16, found {}".format(name,i,x_size))
                # pacman is special: 1 plane
                p = bitplanelib.palette_extract(cropped_img,palette_precision_mask=0xF0)
                # add 16 pixelsblit_pad
                img_x = x_size+16 if blit_pad else x_size
                img = Image.new("RGB",(img_x,cropped_img.size[1]))
                img.paste(cropped_img)
                # if 1 plane, pacman frames, save only 1 plane, else save all 4 planes
                one_plane = False  #len(p)==2
                used_palette = game_palette_16

                namei = "{}_{}".format(name,i) if nb_frames!=1 else name

                print("processing bob {}...".format(name))
                bitplanelib.palette_image2raw(img,"{}/{}.bin".format(sprites_dir,name_dict.get(namei,namei)),used_palette,
                palette_precision_mask=0xF0,generate_mask=generate_mask)

def process_fonts(dump=False):
    json_file = "fonts.json"
    with open(json_file) as f:
        tiles = json.load(f)

    default_width = tiles["width"]
    default_height = tiles["height"]
    default_horizontal = tiles["horizontal"]

    x_offset = tiles["x_offset"]
    y_offset = tiles["y_offset"]

    sprite_page = tiles["source"]

    sprites = Image.open(sprite_page)



    name_dict = {"letter_row_0_{}".format(i):chr(ord('A')+i) for i in range(0,16)}
    name_dict.update({"letter_row_1_{}".format(i):chr(ord('P')+i) for i in range(0,11)})
    name_dict["letter_row_1_11"] = "exclamation"
    name_dict.update({"digit_row_0_{}".format(i):chr(ord('0')+i) for i in range(0,10)})
    name_dict["digit_row_0_10"] = "slash"
    name_dict["digit_row_0_11"] = "dash"
    name_dict["digit_row_0_12"] = "quote"
    name_dict["digit_row_0_13"] = "quote2"
    # we first did that to get the palette but we need to control
    # the order of the palette



    for object in tiles["objects"]:
        if object.get("ignore"):
            continue
        name = object["name"]
        start_x = object["start_x"]+x_offset
        start_y = object["start_y"]+y_offset
        horizontal = object.get("horizontal",default_horizontal)
        width = object.get("width",default_width)
        height = object.get("height",default_height)

        nb_frames = object["frames"]
        for i in range(nb_frames):
            if horizontal:
                x = i*width+start_x
                y = start_y
            else:
                x = start_x
                y = i*height+start_y

            area = (x, y, x + width, y + height)
            cropped_img = sprites.crop(area)
            if dump:
                bn = "{}_{}.png".format(name,i) if nb_frames != 1 else name+".png"
                cropped_name = os.path.join(outdir,bn)
                cropped_img.save(cropped_name)

            # save
            x_size = cropped_img.size[0]

            # blitter object
            if x_size % 8:
                raise Exception("{} (frame #{}) with should be a multiple of 8, found {}".format(name,i,x_size))
            # pacman is special: 1 plane
            p = bitplanelib.palette_extract(cropped_img,palette_precision_mask=0xF0)
            # add 16 pixels if multiple of 16 (bob)
            img_x = x_size+16 if x_size%16==0 else x_size
            img = Image.new("RGB",(img_x,cropped_img.size[1]))
            img.paste(cropped_img)
            # if 1 plane, pacman frames, save only 1 plane, else save all 4 planes
            used_palette = p

            namei = "{}_{}".format(name,i) if nb_frames != 1 else name
            bitplanelib.palette_image2raw(img,"{}/{}.bin".format(sprites_dir,name_dict.get(namei,namei)),used_palette,palette_precision_mask=0xF0)

#process_maps()

gray_palette = [(x,)*3 for x in [0,128,64,128+64]]  # following order of the sprite sheet
process_tiles("tiles_gray.json",gray_palette)

process_fonts()
