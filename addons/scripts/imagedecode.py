#!/usr/bin/env python3
import logging
from io import BytesIO
from os import path, getenv
from pathlib import Path
from subprocess import Popen, DEVNULL
from sys import argv

logging.basicConfig(format="%(name)s - %(levelname)s - %(message)s",
                    level=getattr(logging, getenv("SATNOGS_LOG_LEVEL", "WARNING")))
LOGGER = logging.getLogger("imagedecode")


class ImageDecode(object):
    def __init__(self, frame_file, norad_id=0, image_file=None):
        self.frame_file = frame_file
        self.norad_id = norad_id
        self.frames = []
        self.imagedata = BytesIO()
        if image_file is None:  # default to the same basename
            self.image_name = path.splitext(frame_file)[0]
        else:
            self.image_name = image_file
        self.image_ext = '.jpg'
        if self.norad_id > 0:
            self.auto_decode()

    def auto_decode(self):
        # external image decoders, use return to skip internal decoders
        if self.norad_id == 43803:
            self.jy1sat_ssdv()
            return
        # internal image decoders
        self.parse_file()
        if self.norad_id in [53385,   # Geoscan-Edelveis
                             57167]:  # StratoSat TK-1
            self.stratosat_parse_frames()
        else:
            LOGGER.debug(f"No image decoder found for {self.norad_id}")
            return
        self.write_image()

    def parse_file(self):
        try:
            with open(self.frame_file, "r") as f:
                return self.parse_hex_file(f)
        except UnicodeDecodeError:
            with open(self.frame_file, "rb") as f:
                return self.parse_kiss_file(f)

    def parse_hex_file(self, hex_file):
        for row in hex_file:
            row = row.replace(" ", "").strip()
            if "|" in row:
                row = row.split("|")[-1]
                self.frames.append(row)

    def parse_kiss_file(self, kiss_file):
        for row in kiss_file.read().split(b"\xC0"):
            if len(row) == 0 or row[0] != 0:
                continue
            self.frames.append(
                row[1:]
                .replace(b"\xdb\xdc", b"\xc0")
                .replace(b"\xdb\xdd", b"\xdb")
                .hex(bytes_per_sep=2)
            )

    def stratosat_parse_frames(self):
        cmd_match = '0200'  # default to Stratosat TK-1, 0100 Geoscan-Edelveis
        offset = 0
        hr = False
        for row in self.frames:  # find start frame, memory offset, detect lr/hr
            if len(row) != 128:
                continue
            if row[16:22].upper() == "FFD8FF":
                offset = int((row[12:14] + row[10:12]), 16)
                hr = row[6:10].upper() == "2098"
                cmd_match = row[0:4].upper()
                break
        LOGGER.debug(f'Stratosat parser: cmd_match={cmd_match}, offset={offset}, hr={hr}')
        for row in self.frames:
            if len(row) != 128:
                continue
            cmd = row[0:4]
            if hr:
                addr = int((row[14:16] + row[12:14] + row[10:12]), 16)
            else:
                addr = int((row[12:14] + row[10:12]), 16) - offset
            dlen = (int(row[4:6], 16) + 2) * 2
            payload = row[16:dlen]
            if cmd == cmd_match and addr >= 0:
                self.imagedata.seek(addr)
                self.imagedata.write(bytes.fromhex(payload))

    def write_image(self):
        if self.imagedata.getbuffer().nbytes == 0:
            LOGGER.warning(f'No image data found in {self.frame_file}')
            return
        image_file = f'{self.image_name}{self.image_ext}'
        LOGGER.info(f'Writing image to: {image_file}')
        with open(image_file, "wb") as f:
            f.write(self.imagedata.getbuffer())

    def jy1sat_ssdv(self):
        LOGGER.info(f"Running jy1sat_ssdv for {self.norad_id}")
        Popen(
            ["jy1sat_ssdv", self.frame_file, self.image_name],
            stdout=DEVNULL,
            stderr=DEVNULL,
        )
        for f in Path(self.image_name).glob("*.ssdv"):
            f.unlink(missing_ok=True)


if __name__ == "__main__":
    if len(argv) != 3:
        print(f'Usage: {argv[0]} <frame_file> <norad_id>\n'
              f'Frame file can be KISS, SatNOGS data export or GetKISS+')
        exit(0)
    d = ImageDecode(argv[1], int(argv[2]))
