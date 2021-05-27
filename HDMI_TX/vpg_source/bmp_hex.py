
# import binascii
import mif
import numpy as np
# import struct

image = 'copper_640_480'
dir = 'HDMI_TX\\vpg_source\\'
in_file = dir + image + '.bmp'
out_file = dir + image + '.mif'
num_bytes = -1

with open(in_file, 'rb') as i:
    #with open(out_file, 'w') as o:
    with open(out_file, 'w') as o:
        arr_1d = np.fromfile(in_file, dtype=np.uint8)
        num_bytes = arr_1d.size
        arr_2d = np.reshape(arr_1d, (int(num_bytes / 3), 3))
        arr_2d = np.flip(arr_2d, 1)
        print(arr_2d.shape)
        mif.dump(arr_2d, o, packed=True, width=24, address_radix='HEX', data_radix='HEX')



        # raw = binascii.hexlify(i.read()).decode("utf-8")
        # arr = [raw[i:i+6] for i in range(0, len(raw), 6)]
        # np_arr = np.array(arr)
        # mif.dump()
        #o.write('\n'.join([no_spaces[i:i+6] for i in range(0, len(no_spaces), 6)]))


# with open('memory.mif') as f:
#     mem = mif.load(f)

# print(mif.dumps(mem))